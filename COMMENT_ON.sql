/*
    Source: https://sqlsunday.com/

    Adds similar functionality to SQL Server as the COMMENT ON TABLE and COMMENT ON TABLE
    statements found on Postgresql, Oracle, Db2, and others.

    The procedure adds or updates the MS_description extended property on the object or column.

    Example:

    EXECUTE dbo.Comment_on_table 'schema_name.table_name', 'Table comment goes here.';
    EXECUTE dbo.Comment_on_table 'table_name', 'Table comment goes here.';

    EXECUTE dbo.Comment_on_column 'schema_name.table_name.column_name', 'Column comment goes here.';
    EXECUTE dbo.Comment_on_column 'table_name.column_name', 'Column comment goes here.';

*/
CREATE OR ALTER PROCEDURE dbo.COMMENT_ON
    @name           nvarchar(400),
    @description    sql_variant
AS

IF (PARSENAME(@name, 4) IS NOT NULL)
    THROW 50001, N'Four-part database referencing is not supported.', 1;

DECLARE @object_id      int,
        @column_id      int,
        @schema_name    sysname,
        @object_name    sysname,
        @column_name    sysname=NULL,
        @existing       bit,
        @object_type    sysname;


--- Parse @name and match it to an object or column:
----------------------------------------------------


SELECT TOP (1) @object_id=o.[object_id],
               @schema_name=s.[name],
               @object_name=o.[name],
               @column_id=ISNULL(c.column_id, 0),
               @column_name=c.[name],
               @object_type=REPLACE(o.[type_desc], N'USER_', N'')
FROM (
    VALUES (PARSENAME(@name, 1), PARSENAME(@name, 2), PARSENAME(@name, 3))
    ) AS p(p1, p2, p3)
CROSS JOIN sys.schemas AS s
INNER JOIN sys.objects AS o ON s.[schema_id]=o.[schema_id]
CROSS APPLY (
    --- schema.object.column
    SELECT p.p1 AS column_name WHERE p.p3=s.[name] AND p.p2=o.[name]
    UNION ALL
    --- schema.object
    SELECT NULL AS column_name WHERE p.p2=s.[name] AND p.p1=o.[name] AND p.p3 IS NULL
    UNION ALL
    --- object.column
    SELECT p.p1 AS column_name WHERE OBJECT_ID(p.p2)=o.[object_id] AND p.p3 IS NULL
    UNION ALL
    --- object
    SELECT NULL AS column_name WHERE OBJECT_ID(p.p1)=o.[object_id] AND p.p2 IS NULL
    ) AS x
LEFT JOIN sys.columns AS c ON c.[object_id]=o.[object_id] AND c.[name]=x.column_name;


--- Verify if there's an existing extended property on that object/column:
--------------------------------------------------------------------------

SELECT @existing=COUNT(*)
FROM sys.extended_properties
WHERE major_id=@object_id
  AND minor_id=@column_id;


--- Apply the MS_description extended property:
-----------------------------------------------




--- Table:
IF (@column_id=0 AND @existing=0)
    EXECUTE sys.sp_addextendedproperty
        @name=N'MS_description',
        @value=@description,
        @level0type=N'SCHEMA', @level0name=@schema_name,
        @level1type=@object_type,  @level1name=@object_name;

IF (@column_id=0 AND @existing=1)
    EXECUTE sys.sp_updateextendedproperty
        @name=N'MS_description',
        @value=@description,
        @level0type=N'SCHEMA', @level0name=@schema_name,
        @level1type=@object_type,  @level1name=@object_name;

--- Column:
IF (@column_id>0 AND @existing=0)
    EXECUTE sys.sp_addextendedproperty
        @name=N'MS_description',
        @value=@description,
        @level0type=N'SCHEMA', @level0name=@schema_name,
        @level1type=@object_type,  @level1name=@object_name,
        @level2type=N'COLUMN', @level2name=@column_name;

IF (@column_id>0 AND @existing=1)
    EXECUTE sys.sp_updateextendedproperty
        @name=N'MS_description',
        @value=@description,
        @level0type=N'SCHEMA', @level0name=@schema_name,
        @level1type=@object_type,  @level1name=@object_name,
        @level2type=N'COLUMN', @level2name=@column_name;

GO
DROP SYNONYM IF EXISTS dbo.Comment_on_table;
GO
DROP SYNONYM IF EXISTS dbo.Comment_on_column;
GO
CREATE SYNONYM dbo.Comment_on_table FOR dbo.COMMENT_ON;
GO
CREATE SYNONYM dbo.Comment_on_column FOR dbo.COMMENT_ON;
GO
