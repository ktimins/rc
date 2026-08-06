# 05: Classic Vim/gVim as a C# IDE

Goal: the best achievable C# experience in Vim 9 / gVim on Windows, using the existing `_vimrc` stack where possible. Researched July 2026. This doc is independent of the Neovim migration: it upgrades the current gVim setup in place.

## 0. Honest ceiling statement

Vim's C# story trails Neovim's by a wide margin now. Microsoft's Roslyn language server (doc 04) speaks LSP with several non-standard extensions, and the plugins that smooth those over (roslyn.nvim, easy-dotnet.nvim) are Neovim-only Lua. Classic Vim gets: a previous-generation language server (OmniSharp-Roslyn or csharp-ls), working but more manual debugging (vimspector), and no Rider-style test runner. Everything below works and is a large upgrade over the current commented-out state of `_vimrc`, but if "C# IDE" becomes the primary goal, the Neovim path (doc 04) is the one with a future. As of the research date, OmniSharp-Roslyn and omnisharp-vim are alive but in slow maintenance mode (commits as recent as late 2025), and the coc.nvim ecosystem's own OmniSharp extension recommends switching to csharp-ls.

## 1. Two routes for the language server

### Route A (recommended): keep the existing vim-lsp stack, add the C# server

`_vimrc` already loads `prabirshrestha/vim-lsp`, `mattn/vim-lsp-settings`, and asyncomplete, and already has an `s:on_lsp_buffer_enabled()` hook. This route is the smallest diff.

1. Open a `.cs` file and run `:LspInstallServer omnisharp-lsp` (vim-lsp-settings manages download and registration; it may prompt to pick between available C# servers, in which case `omnisharp-lsp` is the full-featured choice and `csharp-ls` is the lighter alternative). No manual server path management, which also retires the stale hardcoded `g:OmniSharp_server_path` (doc 02, bug 11).
2. Extend the existing hook so C# gets the full command set (add inside `s:on_lsp_buffer_enabled()` in `_vimrc`):

```vim
nmap <buffer> gd <plug>(lsp-definition)
nmap <buffer> gi <plug>(lsp-implementation)
nmap <buffer> gr <plug>(lsp-references)
nmap <buffer> K  <plug>(lsp-hover)
nmap <buffer> <f2> <plug>(lsp-rename)
nmap <buffer> <leader>ca <plug>(lsp-code-action)
nmap <buffer> <leader>fs <plug>(lsp-workspace-symbol-search)
nmap <buffer> ]d <plug>(lsp-next-diagnostic)
nmap <buffer> [d <plug>(lsp-previous-diagnostic)
```

3. Solution loading: OmniSharp-Roslyn picks the `.sln` nearest the root markers already configured (`g:lsp_settings_root_markers` in `_vimrc`). Large solutions take a while on first load; `:LspStatus` shows progress.

### Route B: omnisharp-vim (richer C#-specific features, more moving parts)

[OmniSharp/omnisharp-vim](https://github.com/OmniSharp/omnisharp-vim) is not LSP; it talks OmniSharp's own protocol and exposes C#-specific niceties vim-lsp cannot: `:OmniSharpFixUsings`, code-action popups with fzf, semantic highlighting, `:OmniSharpGlobalCodeCheck`. The `_vimrc` already contains a fully written, commented-out config block for it (the "OmniSharp" fold), which is 90% reusable. To take this route: uncomment `Plug 'OmniSharp/omnisharp-vim'` in `_vimrc.plug`, uncomment the config fold, DELETE the `g:OmniSharp_server_path` line (let the plugin auto-download the server to `~/.cache/omnisharp-vim/`), and add `nickspoons/vim-sharpenup` for statusline integration and default mappings. Do not run Route A and Route B simultaneously on cs buffers (two servers, duplicate diagnostics); Route A's server can be limited by leaving `omnisharp-lsp` uninstalled.

Recommendation: Route A. It reuses infrastructure already in the vimrc, and the C#-specific extras of Route B are exactly the features whose upstream is in maintenance mode.

## 2. VS extension → Vim mapping (most are already installed)

| Visual Studio piece | Vim answer | Status |
|---|---|---|
| CodeNav (member outline) | vista.vim, already mapped to `<F10>` | Set `let g:vista_executive_for = { 'cs': 'vim_lsp' }` so C# uses the language server instead of ctags. Also note doc 03's finding: the `Plug 'universal-ctags/ctags'` line never installed a ctags binary; for non-LSP filetypes install it properly with `choco install universal-ctags`. |
| Git Diff Margin | vim-gitgutter, already installed | Currently `let gitgutter_map_keys = 0` disables all hunk maps. Add explicit ones: `nmap ]c <Plug>(GitGutterNextHunk)`, `nmap [c <Plug>(GitGutterPrevHunk)`, `nmap <leader>hp <Plug>(GitGutterPreviewHunk)`, `nmap <leader>hs <Plug>(GitGutterStageHunk)`, `nmap <leader>hu <Plug>(GitGutterUndoHunk)`. Also delete the broken `User GitGutter` autocmd (doc 02, bug 3). |
| Indent Guides | indentline, already installed | Nothing to do. |
| Rainbow Braces | luochen1990/rainbow, already installed and active | Nothing to do. |
| TODO highlighter | small autocmd, no plugin needed | See snippet below. |
| MetaOutput | quickfix + vim-dispatch | Section 4. |
| Smart Command Line Arguments | per-project `.vimspector.json` configurations | Section 3. |
| Debugger | vimspector + netcoredbg | Section 3. |
| Test Explorer | vim-test + dispatch | Section 4. |

TODO highlighting (drop into `_vimrc`; widens the highlighted keyword set and styling inside comments, in any filetype whose syntax defines comment groups, which covers all the languages in daily use here):

```vim
augroup todo_highlight
   au!
   au Syntax * syntax match RcTodo /\v<(TODO|FIXME|HACK|XXX|NOTE)(\(.{-}\))?:?/
            \ containedin=.*Comment.* contained
   au ColorScheme * highlight RcTodo guifg=#ff8800 gui=bold ctermfg=208 cterm=bold
augroup END
highlight RcTodo guifg=#ff8800 gui=bold ctermfg=208 cterm=bold
```

## 3. Debugging: vimspector + netcoredbg

[puremourning/vimspector](https://github.com/puremourning/vimspector) is the Vim debugger UI; netcoredbg (Samsung's open .NET debugger) is the adapter, and vimspector knows it as a gadget.

1. `Plug 'puremourning/vimspector'` in `_vimrc.plug`.
2. `let g:vimspector_enable_mappings = 'HUMAN'` in `_vimrc` (F5 continue, F9 breakpoint, F10/F11 step: the VS muscle-memory set).
3. Install the adapter: `:VimspectorInstall netcoredbg`.
4. Per project, create `.vimspector.json` next to the `.sln`:

```json
{
  "configurations": {
    "launch": {
      "adapter": "netcoredbg",
      "configuration": {
        "request": "launch",
        "program": "${workspaceRoot}/MyApp/bin/Debug/net8.0/MyApp.dll",
        "args": [],
        "stopAtEntry": false,
        "cwd": "${workspaceRoot}/MyApp"
      }
    },
    "launch with args": {
      "adapter": "netcoredbg",
      "configuration": {
        "request": "launch",
        "program": "${workspaceRoot}/MyApp/bin/Debug/net8.0/MyApp.dll",
        "args": [ "*${CommandLineArgs}" ],
        "cwd": "${workspaceRoot}/MyApp"
      }
    },
    "attach": {
      "adapter": "netcoredbg",
      "configuration": {
        "request": "attach",
        "processId": "${ProcessId}"
      }
    }
  }
}
```

This file is also the Smart Command Line Arguments answer for Vim: each argument preset is a named configuration (vimspector prompts which one to run on F5), and `${CommandLineArgs}` entries prompt at launch. The JSON lives per project, exactly like the VS extension's JSON.

Caveats (same family as doc 04): netcoredbg does not cover classic .NET Framework debugging, build the Debug DLL before launching, and keep `shellslash` OFF (doc 02, bug 12: the current `_vimrc` line 308 `set shellslash` should be deleted for Vim too; it was already contradicted by `set nossl` at the top and path-breaks external tools).

## 4. Build, run, and test (the MetaOutput/Test Explorer story)

Build via the already-installed vim-dispatch, with output parsed into quickfix:

```vim
augroup cs_build
   au!
   au FileType cs compiler dotnet
   au FileType cs nnoremap <buffer> <F6> :Dispatch dotnet build<CR>
augroup END
```

Vim 9.1+ ships a `dotnet` compiler plugin (`:compiler dotnet` sets `makeprg`/`errorformat`). If the installed Vim predates it, set the errorformat manually:

```vim
setlocal errorformat=%f(%l\\,%c):\ %trror\ %m,%f(%l\\,%c):\ %tarning\ %m,%-G%.%#
setlocal makeprg=dotnet\ build\ /clp:NoSummary
```

After `:Dispatch dotnet build`, errors/warnings are in quickfix: `:copen` to browse, `:packadd cfilter` then `:Cfilter /error/` to filter, which is the practical subset of MetaOutput. Runtime output goes to Vim 8+'s `:terminal` (`:terminal dotnet run`); note gVim terminals are functional but plain.

Tests: `Plug 'janko/vim-test'` (already present, commented out; uncomment it) with:

```vim
let test#strategy = 'dispatch'
nnoremap <leader>tn :TestNearest<CR>
nnoremap <leader>tf :TestFile<CR>
nnoremap <leader>ts :TestSuite<CR>
```

vim-test auto-detects .NET test projects and runs `dotnet test` with a filter for the nearest test. There is no tree-view test explorer for Vim; results land in quickfix via dispatch.

## 5. Implementation order

1. Delete the dead weight this doc obsoletes: the broken `User GitGutter` autocmd, `set shellslash`, the stale `g:OmniSharp_server_path` (doc 02 bug list items 3, 11, 12 apply to Vim as much as Neovim).
2. Route A LSP: install server, add the buffer mappings, verify on the real solution (`gd`, `gr`, rename, diagnostics).
3. Vista LSP executive + gitgutter hunk maps + TODO autocmd (small `_vimrc` edits, big daily payoff).
4. Dispatch build wiring + vim-test.
5. Vimspector last (largest moving part), verified first on a scratch console app.

## Sources

- omnisharp-vim status and architecture: https://github.com/OmniSharp/omnisharp-vim
- csharp-ls as the community-recommended lighter alternative: https://github.com/razzmatazz/csharp-language-server (recommendation noted by coc-omnisharp's maintainer)
- vimspector and netcoredbg configuration: https://github.com/puremourning/vimspector and https://puremourning.github.io/vimspector/configuration.html and https://github.com/puremourning/vimspector/issues/419
- netcoredbg: https://github.com/Samsung/netcoredbg
