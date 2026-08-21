# Filetype behavior

What changes depending on what you are editing. `<leader>?` lists the buffer-local mappings wherever you are.

## Indentation by filetype

| Filetype | Width | Indent method |
|---|---|---|
| default | 3 | smartindent |
| `cs` | 3 | Neovim's C# indent |
| `python` | 4 | treesitter |
| `json` | 4 | treesitter |
| `xml` `xsd` `xaml` | 2 | treesitter |
| `html` | 2 | Neovim's HTML indent |
| `ps1` | 3 | treesitter |

Files with their own consistent style are detected and matched automatically, so opening a 4-space project does not fight you.

Treesitter indentation is used only where the language ships an indent query. C# has none, so it uses Neovim's bundled indent script, which handles it correctly.

## JSON

| Key | Does |
|---|---|
| `,=` | Format the buffer through jq |
| `,cf` | Format through conform |
| `,d` | Echo the JSON path to the cursor, and copy it |
| `,g` | Jump to a path you type |
| `aj` / `ij` | Text object: a JSON value, outer or inner |
| `gqaj` | Pretty-print the value under the cursor |

| Command | Does |
|---|---|
| `:FormatJson` | Same as `,=` |

Schema validation is live via schemastore.org, matched by filename. `appsettings.json`, `launchSettings.json`, `global.json`, `package.json` and a thousand others get completion and validation for free, so a wrong type or a misspelled key is flagged as you type.

Folding is treesitter-based. `za` toggles a fold, `zR` opens everything, `zM` closes everything.

## XML, XSD and XAML

| Key | Does |
|---|---|
| `,=` | Format through xmllint |
| `,cf` | Format through conform |

| Command | Does |
|---|---|
| `:XmlBeautify` | Split tags onto separate lines and re-indent |
| `:XmlMinify` | Collapse to a single line |

Typing `>` closes the tag automatically, and matching tags can be jumped between and renamed together.

With lemminx attached, an XML file referencing an XSD gets real validation: wrong element types, disallowed elements and missing required content are all flagged, and completion offers only the elements and attributes the schema permits. Hover shows the schema's own documentation.

`.xsd` and `.xaml` are treated as XML for parsing and validation.

Folding is by indentation here rather than treesitter.

## PowerShell

3-space indent, treesitter parsing and indentation, folding by indentation.

Known gap: the treesitter PowerShell indent query does not indent `param(...)` blocks. Everything else, including nested `if`/`else`, indents correctly. This is still better than the previous behavior, which applied C-style brace rules to PowerShell and mis-indented whole blocks.

## SQL

| Key | Does |
|---|---|
| `,rp` | (visual) Uppercase SQL keywords in the selection |

Completion in a SQL buffer comes from the **live database connection** rather than the language server: real table and column names. See [database.md](database.md).

## Visual Basic

`.cls` and `.bas` files are detected as `vb` and get proper syntax highlighting. This needs a plugin because no treesitter parser for VB exists.

Without the explicit rule Neovim guesses `.cls` is a TeX or Smalltalk file, which is why the rule exists.

## Markdown

See [writing.md](writing.md).

Note that `.md` files anywhere are `markdown`, except under `~/vimwiki` where they are `vimwiki`. That distinction had to be forced: the wiki plugin claims every markdown file on the machine by default, which silently disables treesitter highlighting, the preview and grammar checking.

## CSV

Opening a `.csv` gives column highlighting, plus commands for aligning columns, freezing the header row, summing and sorting a column, and converting to and from a table.

The command set is buffer-local and documented in `:help ft-csv`. Run `<leader>?` in a CSV buffer to see what is actually bound, rather than trusting a list here: the plugin registers its commands when it loads, and the exact names have changed between versions.

## HTTP

`.http` files. See [http.md](http.md).

## PlantUML

`.puml` files get syntax highlighting.

## Everything else

Treesitter parsers are installed for C#, Lua, Vim, JSON, XML, HTML, CSS, Markdown, Python, SQL, PowerShell, JavaScript, YAML, regex, diff and git commits. Those get real parsed highlighting rather than regex approximation.

```
:InspectTree      " see the syntax tree for the current buffer
:Inspect          " what highlight group is under the cursor
```

`:Inspect` is the tool for "why is this the wrong colour".
