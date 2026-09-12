# How this config is put together

What lives where, what loads when, and the rules that hold it together. For "which key does what", see [keymaps.md](keymaps.md); this is the maintenance view.

## Where it lives

The config is `NVim/` in the rc repo. `%LOCALAPPDATA%\nvim` is a **directory junction** pointing at it, so Neovim loads the repo copy directly and edits are immediately live with nothing to sync.

Junctions rather than symlinks because they need no administrator rights or developer mode. Removing one (`rmdir`) never touches the repo contents.

Deliberately separate from the gVim setup in `Vim/`. The two share no files and neither can break the other. That was the point of putting this at the repo root instead of under `Vim/`.

## Layout

```
NVim/
  init.lua              entry point: ordering, nothing else
  lazy-lock.json        exact plugin commits, committed on purpose
  README.md             install and host prerequisites

  lua/
    colemak.lua         the keyboard contract
    machine.lua         $LOCATION -> user, home, rc_repo
    options.lua         every ported 'set'
    keymaps.lua         editor-wide mappings
    autocmds.lua        autocommands, filetype detection, per-filetype settings
    functions.lua       custom commands
    gui.lua             Neovide only; a no-op elsewhere
    config/lazy.lua     plugin manager bootstrap
    plugins/*.lua       plugin specs, one file per area

  docs/                 these documents
  tests/                the regression suite
```

Eight configuration files, about 650 lines. Eight plugin spec files declaring 68 plugins.

## Load order

`init.lua` does nothing but sequence things, and the sequence is load-bearing:

```lua
vim.g.rc_nvim_loaded = true     -- proves THIS init ran, not some other
require("colemak").setup()      -- 1
require("machine")              -- 2
require("options")              -- 3
require("keymaps")              -- 4
require("autocmds")             -- 5
require("functions")            -- 6
require("gui")                  -- 7
require("config.lazy")          -- 8
```

Why this order:

1. **colemak first**, before anything that could throw. If every other line failed, the keyboard would still behave correctly. It is the one thing that makes the editor usable at all
2. **machine** sets `_G.Machine`, which later specs read for repo paths
3. **options** sets `mapleader`, so it must precede anything that defines a leader mapping. A mapping created before `mapleader` is set binds to the wrong key silently
4-6. mappings, autocommands, commands
7. **gui** returns immediately unless running under Neovide
8. **plugins last**, so everything above works without them. If plugin loading breaks entirely you still have a working editor

## What each file owns

| File | Owns | Notes |
|---|---|---|
| `colemak.lua` | 34 language mappings, `iminsert`/`imsearch`, the `:` remap, the `InsertLeave` repair | See [colemak.md](colemak.md). Change nothing here without re-running its spec |
| `machine.lua` | `$LOCATION` to user/home/`rc_repo` | `WORK`=ktimins, `THEIA`=rzite, `ARES`=rzitex. Falls back to `expand("~")` |
| `options.lua` | Options ported from `_vimrc` | Only lines Neovim does not already do by default. Also pins `backupdir` away from the file's directory |
| `keymaps.lua` | Editor-wide mappings | Plugin mappings live with their spec; filetype mappings live in `autocmds.lua` |
| `autocmds.lua` | Core autocommands, `vim.filetype.add`, per-filetype settings, `gd` on `LspAttach`, relative-number switching, `makeprg` for C# | The busiest file, and the one where load-order bugs surface |
| `functions.lua` | `:DiffOrig`, `:XmlMinify`, `:XmlBeautify`, `:FindAll`, wrap toggle, tab stops, sum | Intent ports; several originals never worked |
| `gui.lua` | Neovide font, animation, scale | Guarded by `if not vim.g.neovide then return end` |
| `config/lazy.lua` | Bootstrap, `spec = { import = "plugins" }` | Every file in `lua/plugins/` returning a table is picked up automatically |

## Plugin organisation

One file per area. See [plugins.md](plugins.md) for the full inventory.

| File | Area |
|---|---|
| `ui.lua` | Colorscheme, statusline, tabline, the snacks bundle |
| `editing.lua` | Treesitter, text objects, formatting, filetype plugins carried over from gVim |
| `nav.lua` | Telescope, file tree, symbol outline |
| `git.lua` | Signs, fugitive, diffview, history |
| `lsp.lua` | Mason, and the non-C# language servers |
| `csharp.lua` | Roslyn, completion, easy-dotnet, debugging |
| `sql.lua` | dadbod and its completion source |
| `tools.lua` | Task runner, replace, HTTP, quickfix, keymap menu |

Nothing enforces these boundaries; they exist so that "where does this go" has an obvious answer.

## Lazy loading

Of 68 plugins, **14 load at startup** and the rest wait for a trigger (`event`, `ft`, `cmd`, or `keys`). Startup is around 110ms.

Deliberately eager, because deferring them causes visible problems:

| Plugin | Why |
|---|---|
| `tokyonight.nvim`, `anderson.vim` | A colorscheme applied late flashes |
| `snacks.nvim` | The dashboard has to exist before the first buffer |
| `nvim-treesitter` | Highlighting must be ready for the first file |
| `mason.nvim` | Puts server binaries on PATH; everything downstream assumes that |
| `lualine.nvim` | The statusline should not appear a beat late |
| `vim-matchup` | Neovim's built-in matchit claims `%` at startup and matchup only takes it over on load. See [troubleshooting.md](troubleshooting.md) |

The rest are eager only because their spec has no trigger, which is lazy.nvim's default: `vim-surround`, `vim-repeat`, `vim-sleuth`, `vim-zoom`, `vim-todo-lists`, `vimwiki`, `vim-rhubarb`. Several of those could reasonably be deferred. Nothing depends on them being eager.

## Where state goes

Nothing is written beside the file being edited. See the table in [ui-sessions-gui.md](ui-sessions-gui.md). Everything lives under `%LOCALAPPDATA%\nvim-data\`, and none of it points at the `.vimstorage` tree gVim uses, because the two editors disagree on undofile format and would contend over swap files.

`lazy-lock.json` **is** committed. It pins every plugin to an exact commit, which is what makes a second machine reproducible. `:Lazy restore` walks everything back to it.

What the lockfile does **not** pin: Mason binaries (roslyn, netcoredbg, csharpier, ltex-ls-plus, lemminx, json-lsp) and treesitter parsers. Those are per-machine and unversioned, so two machines can quietly end up on different server builds.

## Invariants

Rules that should not be broken without deliberate thought:

1. **Colemak loads first and its spec passes.** Everything else is built on it, and a plugin claiming `:` or one of the 17 translated letters breaks it with no error at all
2. **`shellslash` stays off.** With it on, Neovim hands forward-slash paths to netcoredbg and breakpoints are silently rejected
3. **Plugins load last.** The editor must be usable with the whole plugin layer broken
4. **Treesitter indentation only where an indent query exists.** `indentexpr` overrules `cindent` and `smartindent`, so pointing it at a language without a query leaves that filetype with no indentation at all. `c_sharp` is exactly that case
5. **One Roslyn client.** easy-dotnet ships its own; running both duplicates every C# completion
6. **Formatting is on demand, never on save**
7. **State never lands beside the edited file**

The test suite asserts every one of these.

## Extending it

**A plugin.** Add a spec to the matching `lua/plugins/*.lua`, give it a lazy trigger unless it genuinely needs to be eager, `:Lazy sync`, then re-run the suite. Commit `lazy-lock.json` with it.

**A language server.** `:MasonInstall <server>`, then a `vim.lsp.config(...)` plus `vim.lsp.enable(...)` block in `lua/plugins/lsp.lua` after `mason.setup()` (which is what puts the binary on PATH). Neovim 0.11+ has this natively; nvim-lspconfig is not used.

**A filetype.** Detection goes in the `vim.filetype.add` call at the top of `autocmds.lua`; behavior goes in an `on_ft(...)` block below it.

**A mapping.** Editor-wide goes in `keymaps.lua`; plugin-specific goes in that plugin's `keys` table so it lazy-loads; filetype-specific goes in the relevant `on_ft` block. Check for collisions first: `,` then pause shows which prefixes are taken.

## The test suite

`tests/` holds a headless regression suite, run with:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/run.lua" +qa!
```

It exists because almost everything that breaks here breaks **silently**: a plugin quietly claiming a mapped key, treesitter indentation returning zero for every line, a language server not attaching, backups reappearing beside source files. None of those produce an error.

Each spec runs in its own Neovim process, because they mutate options and mappings and would otherwise corrupt each other. The runner also treats a spec that fails to load as a failure, having once reported a spec that never ran as passing.

Re-run it after any plugin change, and read the caveats in `tests/README.md` before adding keystroke tests.

## Design record

`Vim/vimrc/nvim-migration/` holds the original design documents plus an index of the corrections found while implementing them. Several places where following those docs literally produces a broken setup are marked inline. Worth reading before making a large change, and worth updating if you find another.
