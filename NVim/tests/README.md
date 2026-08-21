# Config regression specs

Headless checks over this Neovim configuration. They exist because most of what they cover fails silently: a plugin quietly claiming a mapped key, an option reverting to a default, a filetype autocmd that stops firing. None of that announces itself.

## Running

Everything, each spec in its own process:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/run.lua" +qa!
```

A single spec:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/colemak_spec.lua" +qa!
```

Both exit non-zero on failure.

## The specs

| Spec | Covers |
|---|---|
| `colemak_spec.lua` | The acceptance checklist from `01-colemak.md` section 5: the 34 language mappings, insert/search/cmdline translation, Normal mode staying raw QWERTY, the `f`/`t`/`r` arguments, macro round-trips, the `CTRL-^` toggle |
| `iminsert_spec.lua` | The `iminsert` leak fix. `i_CTRL-^` moves the global value as well as the buffer-local one, so without the `InsertLeave` repair, toggling translation off in one buffer disables it in every buffer opened afterwards |
| `core_spec.lua` | `02-core-config.md` section 9: option dispositions, ported mappings and commands, filetype detection, per-filetype autocmds, `$LOCATION` resolution |
| `plugins_spec.lua` | `03-plugins.md` section 6: every plugin installed without errors, no stale `.cloning` markers, F-key mappings, treesitter attaching to C#, and that vimwiki has not reclaimed every `.md` file |
| `indent_spec.lua` | Which indent method each filetype resolves to, and that C#, XML and XAML actually indent. See the warning below |
| `csharp_spec.lua` | `04-csharp-ide-nvim.md`: plugins, Mason binaries, the DAP adapter's Windows settings, debug keymaps, csharpier, and that only one Roslyn client owns completion |

## Two failure modes these exist for

**Indentation.** `'indentexpr'` overrules both `'cindent'` and `'smartindent'`. Point it at a treesitter language with no `indents.scm` and it returns 0 for every line, so the buffer silently loses auto-indent and `gg=G` flattens the file. `c_sharp` is exactly that case. The opposite also happened: `xml` sat on the built-in `XmlIndentGet`, which is a no-op here and left files flat. Neither reports an error.

**Duplicate LSP clients.** easy-dotnet ships its own Roslyn layer, on by default. Running it alongside roslyn.nvim gives two clients answering `textDocument/completion` identically, so every C# completion appears twice. `csharp_spec` asserts easy-dotnet's LSP stays off.

## Not covered here: the live C# session

`csharp_spec` deliberately stops at static checks, because loading a real solution takes 20+ seconds. The following were verified by hand against a two-project solution and are worth re-running after any Roslyn or easy-dotnet upgrade:

- Roslyn attaches to a `.cs` buffer and reports hover, definition, references, rename, completion, documentSymbol, formatting and codeAction
- `gd` from a consuming project jumps into the *other* project's source
- `grr` lists references across project boundaries
- Completion after `.` returns the type's members, once each rather than twice
- `:Roslyn target` exists for multi-solution selection
- A breakpoint set with `<leader>Db` binds and stops, reporting `reason=breakpoint`

That last one is the one to actually re-check: `'shellslash'` being on, or the adapter losing `options.detached = false`, both break Windows debugging in ways that look like the debugger simply ignoring breakpoints.

## Re-run `colemak_spec` after touching plugins

This is the one that matters most. The keyboard contract is the piece the whole configuration is built on, and a plugin that maps `:` or one of the 17 translated letters breaks it without any error message. `03-plugins.md` section 6 calls for exactly this check after the plugin set loads.

## Writing a spec

`harness.lua` provides the helpers. Load it by absolute path, since `tests/` is not on the Lua runtimepath:

```lua
local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("my feature")

T.section("some group")
T.check("a label", actual, expected)   -- deep_equal, so tables compare by value
T.truthy("another label", value)

T.finish()                              -- prints the tally, exits non-zero on failure
```

One caveat worth knowing before adding keystroke tests: `H.feed()` uses `nvim_feedkeys` with the "as if typed" flag, which is what makes language mappings fire. Keep each logical sequence in a **single** `feed()` call. Splitting one sequence across several calls does not model real typing and produces results that look like genuine bugs but are not.
