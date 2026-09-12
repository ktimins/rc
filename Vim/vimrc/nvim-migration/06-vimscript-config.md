# 06: The Vimscript Config Track (init.vim)

Docs 02 and 03 assume the Neovim config is written in Lua. This doc is the alternative: configuring the same Neovim in Vimscript via `init.vim`. It exists because the choice of config language is separate from every other decision in this folder, and both tracks deserve hand-off-level detail. Doc 02's disposition tables and bug lists apply to this track verbatim; only the spelling of the ported lines changes (they stay in their original Vimscript form instead of becoming Lua).

## 0. Why, in plain English: Lua vs Vimscript for the config

What is actually true, stripped of ecosystem hype:

- Neovim runs legacy Vimscript natively and permanently. The existing `_vimrc` is legacy Vimscript, so essentially all of it is valid Neovim config as-is. What Neovim does NOT run is vim9script (the `vim9script` / `def` / `var` dialect Vim 9 introduced); `_vimrc` contains none of it, so this constraint costs nothing here.
- The config language does NOT limit which plugins are usable. Lua plugins load fine under an `init.vim`; you call their setup from Vimscript with `lua` one-liners or `lua <<EOF` heredoc blocks. The reverse is also true (doc 02's Lua config can `vim.cmd.source()` any Vimscript file, which is exactly how variant B of doc 01 works).
- So why did the main line choose Lua? Because the modern plugin ecosystem's configuration surface is Lua tables: every current plugin README, every lazy.nvim spec, every LSP/DAP example is written in Lua, and the C# IDE stack in doc 04 is entirely Lua-native. On the Vimscript track you end up writing those same Lua tables anyway, just wrapped in heredocs inside Vimscript, which is strictly worse ergonomics. Lua is the path of least long-term friction, not a requirement.
- Why choose Vimscript anyway? Three honest reasons. First, zero new language on day one: a 25-year-old vimrc's knowledge transfers directly. Second, maximum reuse: large parts of `_vimrc` can be sourced or pasted unchanged. Third, and this is the strongest one for this setup: **shared files**. Because both gVim and Neovim execute Vimscript, common config (the Colemak block above all) can live in ONE file sourced by both editors, keeping them in behavioral lockstep for as long as both stay in use. A Lua config can also source those shared `.vim` files, so this benefit survives a later switch to Lua.

The recommendation across this folder stays: end state is the Lua track (docs 02/03/04) because of the C# goal, but the Vimscript track is a legitimate first step ("Neovim as a better gVim" this afternoon) and the shared-file idea from this doc is worth adopting in EITHER track. Section 5 lays out the stopping points.

## 1. Ground rules

- File location: `%LOCALAPPDATA%\nvim\init.vim`. Mutually exclusive with `init.lua`: if both exist Neovim raises error E5422 and loads neither cleanly. Pick one entry point per machine.
- Everything else from the README applies unchanged: junction the config dir into the rc repo, keep `_vimrc`/gVim untouched until proven, Neovim state (undo/swap/backup) stays in its own `stdpath("state")` defaults.
- Even under `init.vim`, a `lua/` directory next to it works normally; `lua require("whatever")` from Vimscript loads `lua/whatever.lua`. Lua can creep in gradually without changing the entry point.
- Doc 02 section 8 (the 15 latent bugs) applies with full force: this track must NOT copy those lines over. Section 3 below gives the corrected Vimscript forms of the affected pieces.

## 2. Recommended architecture: shared core

```
repo/Vim/
  vimrc/_vimrc              gVim entry point (existing, stays)
  shared/colemak.vim        doc 01 variant B (the lmap design, works in both editors)
  shared/common.vim         settings/maps/autocmds valid in both editors, grown over time
  nvim/init.vim             Neovim entry point (junctioned to %LOCALAPPDATA%\nvim)
  nvim/lua/                 optional, for Lua that creeps in later
```

Start `common.vim` SMALL: the Colemak source line's companions and the bug-fixed autocmds. Move further settings from `_vimrc` into it only as they get touched; a big-bang dedup of `_vimrc` is not required and not worth the risk. If gVim should keep its current behavior exactly (including the `f`/`t`/`r` layer-flip), then `_vimrc` simply does not source `colemak.vim` and keeps its old `noremap!` block; the lockstep benefit is then limited to `common.vim`.

### init.vim skeleton (complete)

```vim
" %LOCALAPPDATA%\nvim\init.vim  (junctioned from repo Vim/nvim/)

" machine resolution (same logic as doc 02's machine.lua)
let s:users = {'WORK': 'ktimins', 'THEIA': 'rzite', 'ARES': 'rzitex'}
let s:user = get(s:users, toupper($LOCATION), $USERNAME)
let g:rc_repo = 'C:/Users/' . s:user . '/Git/rc'

" the contract (doc 01, variant B) comes first, before anything can fail
execute 'source' g:rc_repo . '/Vim/shared/colemak.vim'
execute 'source' g:rc_repo . '/Vim/shared/common.vim'

" nvim-only settings (options from doc 02's Port column that are not shared)
set number cmdheight=2 foldcolumn=1 foldlevelstart=3 nowrap
set timeoutlen=500 lazyredraw showmatch matchtime=2
set switchbuf=useopen,usetab,newtab showtabline=2
set maxmempattern=2000000
set undofile backup            " nvim's own state dirs; do NOT share .vimstorage
set diffopt+=internal,algorithm:patience

" yank highlight (replaces vim-highlightedyank; nvim-only API)
autocmd TextYankPost * silent! lua vim.hl.on_yank{timeout=150}

" plugins: section 4
execute 'source' g:rc_repo . '/Vim/nvim/plug.vim'
```

`undofile`/`backup` deliberately live here and NOT in `common.vim`: gVim's undo/backup locations depend on its `$storage` machinery in `_vimrc`, while Neovim uses its own state defaults, and sharing those lines would give gVim a bad `undodir`.

## 3. common.vim starter (the doc 02 fixes, in Vimscript)

These are the corrected Vimscript forms of the pieces doc 02 fixed in Lua. Valid in Vim 9 and Neovim.

```vim
" common.vim - sourced by both _vimrc (optional) and init.vim
set noshellslash               " doc 02 bug 12; required for netcoredbg paths
set ignorecase smartcase
set expandtab shiftwidth=3 tabstop=3 softtabstop=3 smartindent
set whichwrap+=<,>,h,l
set fileformats=unix,dos
set hidden

augroup rc_common
   autocmd!
   " auto-cd to the buffer's directory (doc 02 bug 1: the old line had a
   " literal <cr> in the path and never worked)
   autocmd BufEnter * silent! lcd %:p:h
   " return to last edit position (doc 02 bug 2: correct mark quoting is
   " line("'\"") - apostrophe followed by escaped double quote)
   autocmd BufReadPost * if line("'\"") >= 1 && line("'\"") <= line('$') | execute 'normal! g`"' | endif
   " never auto-insert comment leaders
   autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
augroup END

" visual * / # search for the selection (doc 02 bug 4: the old mappings
" called a VisualSelection() that was never defined)
xnoremap * y/\V<C-R>=escape(@",'/\')<CR><CR>
xnoremap # y?\V<C-R>=escape(@",'?\')<CR><CR>
```

The custom functions (`XmlBeautify`, `ChangeTabStops`, `ChooseWrap`, `FindAll`, `SumNumbers`) stay in their existing Vimscript forms on this track and can move into `common.vim` verbatim, with two corrections applied: `XmlMinify`'s substitute patterns must use single-quoted execute strings so `\s\+` survives (doc 02 bug 15: `execute '%s/>\s\+</></e'`), and the `<leader>fa` mapping becomes `nnoremap <leader>fa :FindAll<CR>` (doc 02 bug 10). The filetype augroups from `_vimrc` also come along, with the doc 02 section 8 syntax bugs fixed (no space after commas in event lists, `FileType` patterns use filetype names like `markdown` rather than globs like `*.py`).

## 4. Plugins on this track

vim-plug works in Neovim unchanged. Install its loader for Neovim (PowerShell, from the vim-plug README):

```powershell
iwr -useb https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim |`
    ni "$(($env:LOCALAPPDATA))/nvim-data/site/autoload/plug.vim" -Force
```

### Sub-path (a): reuse the existing plugin set (the conservative start)

Copy `_vimrc.plug` to `Vim/nvim/plug.vim` and change only the preamble so the two editors keep separate plugin directories:

```vim
if has('nvim')
   call plug#begin(stdpath('data') . '/plugged')
else
   call plug#begin('~/.vim/plugged')
endif
```

Then `:PlugInstall`. Nearly everything in `_vimrc.plug` runs on Neovim, including vim-lsp and asyncomplete (pure Vimscript, Neovim-compatible), so the C# route from doc 05 section 1 works IDENTICALLY inside Neovim on this track: same `:LspInstallServer omnisharp-lsp`, same mappings. Worthwhile immediate edits while copying: enable `iamcco/markdown-preview.nvim` (it is Neovim-native and was already configured but commented out), and drop `rhysd/vim-healthcheck` (Neovim has `:checkhealth` built in) plus `machakann/vim-highlightedyank` (the `TextYankPost` autocmd in the skeleton replaces it). Doc 03's drop list (broken `universal-ctags/ctags` line, python2-era vim-xpath, the c9s trio) applies here too and can be applied opportunistically.

### Sub-path (b): modern Lua plugins from init.vim

Lua plugins install through vim-plug like any other repo; their setup call goes in a heredoc after `plug#end()`:

```vim
call plug#begin(stdpath('data') . '/plugged')
   Plug 'lewis6991/gitsigns.nvim'
   Plug 'nvim-lua/plenary.nvim'
   Plug 'nvim-telescope/telescope.nvim'
call plug#end()

lua <<EOF
require("gitsigns").setup({
  on_attach = function(bufnr)
    local gs = require("gitsigns")
    vim.keymap.set("n", "]c", function() gs.nav_hunk("next") end, { buffer = bufnr })
    vim.keymap.set("n", "[c", function() gs.nav_hunk("prev") end, { buffer = bufnr })
  end,
})
EOF
nnoremap <F7> <cmd>Telescope buffers<CR>
```

Any spec from docs 03/04 translates this way: the `Plug` line replaces the lazy spec's repo string, and the spec's `opts`/`config` content becomes the heredoc. What does NOT translate: lazy.nvim itself (bootstrapping it from init.vim is possible but pointless; if you want lazy.nvim you want init.lua), lazy-loading triggers (`ft =`, `keys =`, `cmd =`; vim-plug's `{ 'on': ..., 'for': ... }` covers the common cases), and the treesitter branch caveat from doc 03 carries over verbatim (`Plug 'nvim-treesitter/nvim-treesitter', { 'branch': 'master', 'do': ':TSUpdate' }`).

### C# on this track

Two levels. Level one (recommended here): the doc 05 route A stack (vim-lsp + OmniSharp server + asyncomplete) reused unchanged inside Neovim, since it is all Vimscript. Level two: the full doc 04 stack (roslyn.nvim, easy-dotnet, nvim-dap) driven from init.vim via sub-path (b) heredocs; it works, but at that point most of the config is Lua-in-heredocs, and the honest advice is that reaching for doc 04 is the natural moment to flip the entry point to `init.lua` (docs 02/03), keeping `shared/colemak.vim` and `shared/common.vim` exactly as they are.

## 5. The three stopping points (decision guide)

1. **init.vim + existing plugin set** (sub-path a): "Neovim as a better gVim". An afternoon of work. Gains over gVim: built-in terminal, better defaults, `:checkhealth`, Neovide as the GUI, and the doc 01 variant B Colemak upgrade. C# story equals doc 05. This is the fastest way to answer "can I live in Neovim?" with near-zero relearning.
2. **init.vim shared-core + selective Lua plugins** (sub-path b): add telescope, gitsigns, treesitter as heredocs while the bulk stays Vimscript. A stable place to sit for months.
3. **init.lua full migration** (docs 02/03/04): the recommended end state for the C# IDE goal. Everything learned and every shared `.vim` file from stops 1 and 2 carries forward; only the entry point and the plugin manager change.

The path 1 → 2 → 3 has no wasted work except the vim-plug preamble file, and `shared/colemak.vim` survives the entire journey (and outlives it, if gVim adopts it too).

## 6. Verification

At stop 1: `nvim` starts clean; the full doc 01 acceptance checklist passes with variant B active; `:PlugStatus` shows all plugins OK; `:checkhealth` has no errors beyond optional providers; if gVim also sources `colemak.vim`, rerun the checklist inside gVim (all 13 tests apply there identically, since lmap is a Vim feature). At stop 2: doc 03's verification items for whichever Lua plugins were adopted. Any later flip to stop 3 re-runs doc 02 section 9.
