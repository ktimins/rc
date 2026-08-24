# Troubleshooting

Mostly about **silent** failures. Nearly everything that goes wrong in this setup fails by simply not happening, with no error to search for.

## First moves

```
:checkhealth              " the broad sweep
:LspInfo                  " which servers attached here
:Lazy                     " plugin states and errors
:Mason                    " which binaries are installed
:messages                 " errors you may have missed
```

Run the spec suite; it covers most of what silently breaks:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/run.lua" +qa!
```

## Typing comes out wrong

See [colemak.md](colemak.md), which has the full decision tree. Quickly: check the statusline for `CMK` or `QWE`, and press `CTRL-^` in Insert mode to toggle.

## C# navigation is wrong or missing

**`gd` does not go to the definition.** It is only mapped where a language server is attached, so check `:LspInfo`. Without one it falls back to Vim's lexical "local declaration", which only searches the current function.

**`grr` finds too few references.** Roslyn has not finished loading. Watch the progress indicator; on a large solution this takes a while. Nothing errors, it just under-reports until it is ready.

**No language server at all in a `.cs` file.** `:LspInfo` to confirm. Usually one of:
- Neovim was not started from within the solution directory
- Several `.sln` files exist and the wrong one loaded. `:Roslyn target`
- The projects are not children of the `.sln` directory. Set `broad_search = true` in `lua/plugins/csharp.lua`

**Every completion appears twice.** Two Roslyn clients are attached. Check `:LspInfo`; only `roslyn` should be there. easy-dotnet ships its own LSP layer that is disabled in this config precisely to avoid this.

## Building

**`:make` produces nothing.** Check `:set makeprg?` shows `dotnet build --nologo`. It is set for `cs` buffers only.

**The build ran but the quickfix is empty.** If you used `,or` (overseer), this is the known unverified integration. Use `:make` instead. If `:make` also gives nothing, the errorformat is not matching; `:copen` and look at the raw lines.

**Every error appears twice.** MSBuild reports each diagnostic once per build pass. Expected, not a bug.

## Debugging

**A breakpoint never binds.** In order of likelihood:
1. The DLL is stale. Rebuild
2. `:set shellslash?` must report `noshellslash`. With it on, netcoredbg silently rejects the paths
3. It is a .NET Framework project. Those stay in Visual Studio
4. It is a Release build

## Formatting

**`,cf` does nothing.** `:ConformInfo` shows what applies here and whether the binary was found. Missing tools install through `:Mason`.

## Markdown behaves oddly

**No highlighting, no preview, no grammar checking.** Check `:set filetype?`. If it says `vimwiki` for a file outside `~/vimwiki`, the wiki plugin has reclaimed it and `vim.g.vimwiki_global_ext = 0` is not taking effect. Files under `~/vimwiki` being `vimwiki` is correct.

## Indentation is wrong for a filetype

Three things set indentation, in this order of precedence:

1. **EditorConfig**, built into Neovim and on by default
2. **vim-sleuth**, which guesses from file content
3. The **FileType autocmds** in `lua/autocmds.lua`

`verbose set shiftwidth?` names whichever one won, and is the fastest way to end the argument.

The trap: an `.editorconfig` containing `root = true` but **no indent properties** still changes behavior. It stops the upward search, after which vim-sleuth supplies its own values and overrides the per-filetype defaults this config sets. Symptom seen in practice, from a `~/.editorconfig` holding only `csharp_*` style rules:

| Filetype | Config wants | Got instead |
|---|---|---|
| `xml` | 2 | 4 |
| `ps1` | 3 | 4 |
| `json` | 4 | 2 |

Nothing errors. Indentation is simply not what the config says.

If you keep an `.editorconfig`, **state the indent properties explicitly** rather than relying on the fallback, so it is the single source of truth:

```ini
root = true

[*.xml]
indent_style = space
indent_size = 2
```

Note that `csharp_*` and `dotnet_*` entries are Roslyn analyzer rules, not EditorConfig core properties. Neovim handles ten core properties and none of those; Roslyn reads them itself for diagnostics and its own formatting. csharpier, which `,cf` uses for C#, ignores them entirely.

## Treesitter

**A language has no highlighting.** `:checkhealth nvim-treesitter`, then `:TSInstall <language>`.

**Parsers fail to install** with an error mentioning `ENOENT` after downloading successfully. The tree-sitter CLI is not spawnable. On Windows, npm installs an extension-less shim that Neovim cannot execute, and the real binary must be copied next to it. See the requirements section of the config README. This error names the download step, so it reads like a network problem when it is not.

**Indentation broke in one language.** Treesitter indent is only enabled where the language ships an indent query. If you add a language, check it has one; without it `indentexpr` returns 0 for every line, which overrules `cindent` and `smartindent` and leaves the file with no indentation at all.

## Plugins

**Clone output on every startup.** A plugin failed to clone and left a `.cloning` marker, so it retries forever. Check `%LOCALAPPDATA%\nvim-data\lazy\` for `*.cloning`, delete the plugin's directory and marker, and `:Lazy sync`. If it is a submodule failing, add `submodules = false` to that plugin's spec: rainbow-delimiters needed exactly this, because its gitlab-hosted test submodule returns 403 on some networks.

**A plugin update broke something.** `:Lazy restore` rolls everything back to the committed lockfile.

## Searching from the wrong place

`,ff` and `,fg` search from the **current file's directory**, because the config follows each buffer with `lcd`. After opening something deep in a tree, the search root moves with it.

```
:cd C:/path/to/solution               " move the whole session
:Telescope find_files cwd=C:/path     " one-off
```

If this proves more annoying than useful, the `BufEnter` autocmd in `lua/autocmds.lua` is the thing to remove. It is worth knowing that this behavior never actually worked in gVim: the original had a bug that silently disabled it, so it is new to you despite being in the config for years.

## Known gaps

Things that are missing or unverified, recorded so they are not rediscovered:

| Gap | Detail |
|---|---|
| `<F2>` / `<F12>` not mapped | Doc 04 specced these as VS-style LSP shortcuts. Entangled with the F-key decision, so not done. `gd`, `grn` and `gra` cover the same ground |
| Overseer quickfix unverified | The task runs; whether its output reaches the quickfix was never proven. `:make` is the verified path |
| Debug keys provisional | On `<leader>D` pending the F5/F9/F10 decision against undotree and aerial |
| PowerShell `param()` indent | The treesitter query does not indent `param` blocks |
| MSBuild duplicate errors | Each diagnostic appears once per build pass |
| No multi-cursor | The Visual Studio Ctrl+D equivalent is not installed |
| Terminal mode is untranslated | Colemak translation does not apply in `:terminal`. Flip the hardware layer |

## When you change the config

Re-run the suite, and especially the Colemak spec:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/run.lua" +qa!
```

A new plugin that claims `:` or one of the 17 translated letters breaks the keyboard contract with no error at all. That is the failure mode the suite exists to catch.
