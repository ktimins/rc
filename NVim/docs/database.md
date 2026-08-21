# Database

Run SQL against SQL Server (and anything else with a connection string) without leaving the editor. Results in a split, table and column completion from the live connection.

## Opening it

| Key | Does |
|---|---|
| `,u` | Toggle the database UI |

The sidebar lists your connections, each expanding into schemas, tables and saved queries.

| Command | Does |
|---|---|
| `:DBUI` | Open the sidebar |
| `:DBUIToggle` | Toggle it |
| `:DBUIAddConnection` | Add a connection interactively |
| `:DBUIFindBuffer` | Jump to the query buffer for the current connection |
| `:DBUIRenameBuffer` | Name the current query |
| `:DBUILastQueryInfo` | Timing and row count for the last query |

## Connections

Add one interactively with `:DBUIAddConnection`, or define them up front. SQL Server URLs look like:

```
sqlserver://user:password@host:1433?database=MyDatabase
sqlserver://host/MyDatabase                     " trusted connection
```

To have connections always available, set `g:dbs` in your config:

```lua
vim.g.dbs = {
  dev = "sqlserver://host/MyDatabase_Dev",
  qa  = "sqlserver://host/MyDatabase_QA",
}
```

Keep real credentials out of the repo. Point at a file outside it, or rely on trusted connections, or use the interactive prompt which stores them under the plugin's own directory rather than in version control.

## Running queries

In a SQL buffer:

| Key | Does |
|---|---|
| `,S` | Execute the query under the cursor |
| `,S` | (visual) Execute just the selection |
| `,W` | Save the query for reuse |
| `,E` | Edit bind parameters |

These are buffer-local, installed by the plugin. Note `,S` **shadows the global sum-numbers mapping** while you are in a SQL buffer, which is the right trade: summing numbers in a query buffer is not a thing anyone needs.

Results open in a split. Executing on save is deliberately **off**: firing a destructive statement because `:w` is muscle memory is too easy a mistake to leave available.

From anywhere, without the UI:

```
:DB sqlserver://host/db SELECT TOP 10 * FROM Orders
:'<,'>DB                          " run the selected lines
:DB g:dev SELECT 1                " against a connection named in g:dbs
```

## Completion

Inside a SQL buffer, completion switches to the live connection: real table names, real column names, from the database you are actually connected to. That replaces the usual language-server and buffer-word sources, which have nothing useful to say about your schema.

Type a table alias and a dot to get its columns.

`:DBCompletionClearCache` refreshes after a schema change.

## Saved queries

Queries saved from the UI live under the plugin's data directory, not next to whatever folder you happened to start the editor in. They appear per connection in the sidebar, so a query you wrote last month against QA is still there.

Name them with `:DBUIRenameBuffer` while the query buffer is focused.

## Useful in a SQL buffer

| Key | Does |
|---|---|
| `,rp` | (visual) Uppercase the SQL keywords in the selection |
| `,cf` | Format the buffer |
| `gcc` | Comment a line |

## Why this rather than SSMS

Not a replacement for SSMS. It is a replacement for the loop of alt-tabbing to SSMS to check a column name while writing C#. The query lives in a buffer you can diff and commit; the results are text you can yank into code.

Objects, execution plans, agent jobs and the rest stay in SSMS.
