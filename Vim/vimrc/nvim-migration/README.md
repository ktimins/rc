# Vim → Neovim Migration Design Docs

This folder contains the full design and implementation plan for migrating the gVim setup in this repo (`_vimrc`, `_vimrc.plug`) to a Lua-based Neovim configuration, plus research on building both editors into a working C# IDE. These are hand-off quality documents: an implementer (human or model) should be able to execute them without re-deriving any decisions. No code outside this folder has been changed.

## The one non-negotiable constraint

The user types Colemak but runs Vim commands in QWERTY. A Planck keyboard has two hardware layers; the QWERTY layer is active while in Vim. The editor must therefore behave as:

| Context | Layout |
|---|---|
| Normal / Visual / Operator-pending commands | Raw QWERTY (whatever the keyboard sends) |
| Insert and Replace mode typing | Translated QWERTY → Colemak |
| Command line after `:`, `/`, `?` | Translated QWERTY → Colemak |
| Character arguments of `f` `F` `t` `T` `r` | Translated QWERTY → Colemak (NEW: improves on the old setup, see 01) |

Any change that breaks this contract makes Neovim unusable for this user. Implement `01-colemak.md` first and run its acceptance checklist before doing anything else.

## Reading / implementation order

1. `01-colemak.md`: the Colemak keyboard handling. The chosen design uses language mappings (`:lmap`), and section 6 of that doc gives ALL four variants (lmap vs `noremap!` mechanism, crossed with Lua vs Vimscript language) at equal implementation depth, including a shared `colemak.vim` that both gVim and Neovim can source. Implement and verify this before all other work.
2. `02-core-config.md`: options, autocmds, custom functions, and machine-specific logic from `_vimrc`, with a full disposition table (what is a Neovim default, what ports, what is dead) and a list of latent bugs in the current vimrc that must NOT be carried over.
3. `03-plugins.md`: plugin-by-plugin verdicts for everything in `_vimrc.plug` (keep / replace / drop / now built-in), lazy.nvim bootstrap, config snippets for the replacements, and the GUI (Neovide) story. Section 7 of that doc is the full pruning inventory: what every plugin actually does, which are wired vs silently inert or broken, editor-compatibility marking, a "safe to prune from gVim today" list, and the same descriptions for the incoming Neovim plugins. Section 8 is the wishlist: suggested NEW plugins (not currently installed) for daily-driver editing, C# work, markdown/JSON/XML, terminal/HTTP tooling, AI-agent integration (Claude Code / Codex with editor context), and general programmer QoL, each tagged Vim / Nvim / Both.
4. `04-csharp-ide-nvim.md`: turning Neovim into a C# IDE, mapped one-to-one against the Visual Studio extensions the user actually uses (CodeNav, Git Diff Margin, Indent Guides, MetaOutput, Rainbow Braces, TODO highlighter, Smart Command Line Arguments).
5. `05-csharp-ide-vim.md`: the same goal for classic Vim/gVim, using the existing vim-lsp stack, with honest notes on where Vim's ceiling is lower.
6. `06-vimscript-config.md`: the alternative track: configuring Neovim in Vimscript (`init.vim`) instead of Lua. Not a sequel to 02/03 but a swap-in replacement for their language layer; it reuses doc 02's disposition tables and bug list, adds a shared-core architecture that keeps gVim and Neovim in lockstep, and defines three stopping points from "Neovim as a better gVim this afternoon" to the full Lua end state.

## Language choice: Lua or Vimscript (the why)

Neovim runs both. The entry point is either `init.lua` or `init.vim` (never both), and the choice does NOT limit which plugins are usable: Lua plugins work under an `init.vim` via `lua <<EOF` blocks, and a Lua config can `vim.cmd.source()` any Vimscript file. The main line of these docs (02/03/04) is Lua because the modern plugin ecosystem, including the entire C# stack in doc 04, documents and configures itself in Lua; driving it from Vimscript means wrapping the same Lua in heredocs, which is identical work with worse ergonomics. The Vimscript track (doc 06) is legitimate and fully specified anyway, because it is the fastest first step (near copy-paste reuse of `_vimrc`) and because shared `.vim` files, above all the Colemak file, keep gVim and Neovim behaviorally identical during however long both editors stay in use. The two tracks converge: everything built on the Vimscript track except the plugin-manager preamble carries forward to the Lua end state.

## Environment facts the implementer needs

- OS: Windows 11. Shell contexts are cmd/PowerShell; the repo is worked on through Git Bash sometimes.
- Machine selection is done via the `$LOCATION` environment variable: `WORK` (user `ktimins`), `THEIA` (user `rzite`), `ARES` (user `rzitex`). The current machine is WORK.
- Neovim config location on Windows: `%LOCALAPPDATA%\nvim\init.lua` (this is `vim.fn.stdpath("config")`). Data/plugins go to `%LOCALAPPDATA%\nvim-data` (`stdpath("data")`), state (undo/swap/backup by default) to `stdpath("state")`.
- To keep the config in this git repo, create the config as `Vim/nvim/` in the repo and junction it: `cmd /c mklink /J "%LOCALAPPDATA%\nvim" "C:\Users\ktimins\Git\rc\Vim\nvim"` (adjust user per `$LOCATION`).
- Version assumption: Neovim 0.11+ for everything in docs 01 through 03; Neovim 0.12+ is required for the recommended C# LSP plugin (seblyng/roslyn.nvim) in doc 04. Install the latest stable (`choco install neovim` or `winget install Neovim.Neovim`).
- Neovim runs legacy Vimscript natively (it never adopted vim9script), so any block from `_vimrc` can be kept verbatim during transition via `vim.cmd.source(...)`. The target state is Lua, but nothing forces a big-bang rewrite.
- Existing gVim, `_vimrc`, and `_vsvimrc` (VsVim in Visual Studio) must keep working untouched. Neovim's config is fully separate, so the two coexist with zero risk. `_vsvimrc` is out of scope for all of these docs.

## Status

Design complete, researched July 2026. Nothing implemented yet.
