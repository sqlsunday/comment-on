# WHAT

Postgresql, Oracle, Db2, and other platforms support the `COMMENT ON {TABLE|COLUMN}` statements,
used to add descriptive comments to database objects for documentation purpose.

The SQL Server equivalent is `sys.sp_addextendedproperty` or `sys.sp_updateextendedproperty`, but
these commands are not as intuitive or easy to write in a script. This utility works as a wrapper
to these built-in SQL Server procedures.

COMMENT ON is not ANSI-SQL, but I think it's a really handy feature when used to document database
objects.

## Disclaimer

This is free, unsupported software. If you want guarantees, I'm available for hire.

# HOW

Postgresql/Oracle/Db2 command:

```
COMMENT ON COLUMN dbo.Widgets IS 'Contains a list of widgets in stock';
COMMENT ON COLUMN dbo.Widgets.Name IS 'The name of the widget';
```

The equivalent commands on native SQL Server would look like this:

```
EXECUTE sys.sp_updateextendedproperty
    @name=N'MS_description',
    @value='Contains a list of widgets in stock',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'Widgets';

EXECUTE sys.sp_addextendedproperty
    @name=N'MS_description',
    @value='The name of the widget',
    @level0type=N'SCHEMA', @level0name=N'dbo',
    @level1type=N'TABLE',  @level1name=N'Widgets',
    @level2type=N'COLUMN', @level2name=N'Name';
```

Using this utility procedure, the code looks like this:

```
EXECUTE dbo.Comment_on_table N'dbo.Widgets', 'Contains a list of widgets in stock';
EXECUTE dbo.Comment_on_column N'dbo.Widgets.Name', 'The name of the widget';
```
