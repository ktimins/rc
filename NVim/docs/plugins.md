# Plugin inventory

All 68 plugins, grouped by the spec file that declares them, with what each is for and what it replaced from the gVim setup. Versions are pinned in `lazy-lock.json`.

`:Lazy` shows live state. `:Lazy profile` shows what startup actually costs.

## ui.lua

| Plugin | For | Replaces |
|---|---|---|
| tokyonight.nvim | Colorscheme, treesitter-aware | The zenburn/molokai cascade |
| anderson.vim | The old gVim look, kept reachable | Itself, carried over |
| lualine.nvim | Statusline, hosts the Colemak indicator and breadcrumb | vim-airline + themes |
| bufferline.nvim | Open buffers along the top | vim-buftabline |
| snacks.nvim | Six modules: dashboard, indent guides, smooth scroll, zen, buffer delete, input | startify, indentline, comfortable-motion, goyo, the undefined `:Bclose` |
| nvim-web-devicons | Filetype icons | new |

The snacks `input` module matters more than it looks: it makes `vim.ui.input` a real Insert-mode buffer, which is what lets Colemak translation work inside prompts.

## editing.lua

| Plugin | For | Replaces |
|---|---|---|
| nvim-treesitter | Real parsers: highlighting, folds, rainbow, outline | vim-polyglot, vim-csharp, vim-ps1, html5.vim, vim-json |
| targets.vim | Text objects: `ci,`, `cia`, next/last variants | new |
| vim-unimpaired | Paired brackets: `]q`, `]b`, `yow` | new |
| vim-surround, vim-repeat | Surround operators, and `.` repeating them | carried over |
| vim-matchup | `%` across language keywords | carried over |
| nvim-autopairs | Auto-closing brackets and quotes | auto-pairs |
| rainbow-delimiters.nvim | Bracket colouring by depth | luochen1990/rainbow |
| yanky.nvim | Yank ring | vim-yankstack |
| conform.nvim | Formatter dispatch: jq, xmllint, csharpier | vim-autoformat, json-formatter, vim-pwsh-formatter |
| undotree | Undo history as a tree | carried over |
| persistence.nvim | Per-directory sessions | vim-session + vim-misc |
| nvim-colorizer.lua | Paints colour codes | vim-css-color |
| tabular | Align on a pattern | carried over |
| vim-sleuth | Detect indent from file content | carried over |
| render-markdown.nvim | In-buffer markdown rendering | new |
| markdown-preview.nvim | Browser preview | carried over, was never enabled in gVim |
| vimwiki | Personal wiki | carried over |
| vim-jsonpath | JSON path echo and jump | carried over |
| vim-jdaddy | JSON text objects | carried over |
| xmledit | XML tag helpers | carried over |
| csv.vim | CSV column tooling | carried over |
| unicode.vim | Character identification | carried over |
| visual-split.vim | Split to the selection | carried over |
| vim-zoom | Maximize a window | carried over |
| vim-vb | VB6/VBScript syntax for `.cls`/`.bas` | carried over. No treesitter parser for VB exists |
| plantuml-syntax | PlantUML | carried over |
| vim-wordy | Prose style linting | carried over |
| vim-todo-lists | `.todo` checkboxes | carried over |

## nav.lua

| Plugin | For | Replaces |
|---|---|---|
| telescope.nvim | Fuzzy picker: files, grep, buffers, symbols | bufexplorer, and the ctrlp/fzf entries commented out for years |
| neo-tree.nvim | File tree with git status | nerdtree + nerdtree-git-plugin |
| aerial.nvim | Symbol outline from LSP/treesitter | vista.vim, which needed a ctags binary that was never installed |
| plenary.nvim, nui.nvim | Libraries | new |

## git.lua

| Plugin | For | Replaces |
|---|---|---|
| gitsigns.nvim | Gutter signs, hunk stage/reset/preview/blame | vim-gitgutter, which had all its hunk mappings disabled |
| vim-fugitive | `:Git` for everything | carried over |
| vim-rhubarb | `:GBrowse` to GitHub | carried over |
| gv.vim | Commit browser | carried over |
| diffview.nvim | Side-by-side diffs, file history, merge tool | merginal, vimagit, the c9s trio |

## lsp.lua

| Plugin | For |
|---|---|
| mason.nvim | Installs server and tool binaries; puts them on PATH |
| SchemaStore.nvim | JSON schema catalogue for appsettings.json and friends |
| trouble.nvim | Diagnostics panel, the Error List equivalent |
| fidget.nvim | LSP progress, so a loading Roslyn does not look like a hang |

Servers themselves are Mason packages, not plugins: **ltex-ls-plus** (grammar), **lemminx** (XSD-aware XML), **json-lsp**. Configured natively with `vim.lsp.config`; nvim-lspconfig is not used.

This is also where `dpelle/vim-LanguageTool` was **removed**: it drives the LanguageTool CLI with `--api`, which 6.x deleted.

## csharp.lua

| Plugin | For | Replaces |
|---|---|---|
| roslyn.nvim | The C# language server, same engine as Visual Studio | vim-lsp + vim-lsp-settings + OmniSharp |
| blink.cmp | Completion | asyncomplete.vim + asyncomplete-lsp |
| friendly-snippets | Snippet definitions | honza/vim-snippets, inert for years with no engine installed |
| easy-dotnet.nvim | Build, run, test runner, launch profiles, secrets | new |
| nvim-dap, nvim-dap-ui, nvim-nio | Debugging | new |
| nvim-dap-virtual-text | Inline values at a breakpoint | new |
| nvim-navic | Statusline breadcrumb | the airline/vista glue |
| todo-comments.nvim | TODO highlighting plus project-wide pickers | new |

Mason binaries: **roslyn**, **netcoredbg**, **csharpier**.

easy-dotnet's own Roslyn LSP layer is **disabled**; running it alongside roslyn.nvim duplicates every completion.

## sql.lua

| Plugin | For |
|---|---|
| vim-dadbod | Run SQL against a connection |
| vim-dadbod-ui | Connection and saved-query sidebar |
| vim-dadbod-completion | Table and column completion from the live schema |

dadbod was already sitting commented out in `_vimrc.plug`. The completion piece registers as a blink source, so it shares the normal popup.

## tools.lua

| Plugin | For | Replaces |
|---|---|---|
| overseer.nvim | Task list with per-task output | vim-dispatch |
| which-key.nvim | Leader menu | new |
| grug-far.nvim | Project replace with live preview | new |
| kulala.nvim | `.http` request files | new |
| nvim-bqf | Quickfix preview and filtering | new |

## Dropped from gVim

Removed because they were provably inert, broken, or superseded. Recorded so they are not reinstated by reflex:

| Plugin | Why |
|---|---|
| universal-ctags/ctags | Cloned the ctags **source repo** as a plugin; never provided a binary |
| honza/vim-snippets | Definitions with no engine ever installed |
| Shougo/vimproc | Needed a compiled DLL that was never built |
| devjoe/vim-codequery | Depended on vimproc and external index tools |
| actionshrimp/vim-xpath | Python-2 era |
| inkarkat/vim-PatternsOnText | Needed ingo-library, never installed |
| c9s/hypergit + helper + treemenu | 2010-era git UI |
| bpstahlman/txtfmt, vim-preview, VOoM | Never configured or invoked |
| vim-diff-enhanced, visSum, json-formatter | Duplicated something already present |
| dpelle/vim-LanguageTool | Incompatible with LanguageTool 6.x |
| Six colourscheme packs | Unreferenced |

`03-plugins.md` in the migration docs has the full reasoning, including which were merely inert versus actively broken.

## Not adopted

From the migration wishlist, considered and left out: **flash.nvim** (its jump labels arrive as raw QWERTY, so it fights the Colemak setup), **oil.nvim**, **harpoon**, **neotest** (easy-dotnet's runner covers it), **toggleterm**, **vim-visual-multi**, **copilot.vim**, **claudecode.nvim**, **vim-abolish**, **splitjoin**, **projectionist**, **vim-table-mode**, **bullets.vim**.

None were rejected on merit; they simply have not been needed yet.
