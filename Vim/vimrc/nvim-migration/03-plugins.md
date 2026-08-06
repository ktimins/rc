# 03: Plugin Migration (`_vimrc.plug` → lazy.nvim)

Scope: a verdict for every active plugin in `_vimrc.plug`, the lazy.nvim bootstrap, working specs for the replacements, and the GUI (Neovide) setup. C#-specific plugins (LSP, completion, DAP, tests) are in doc 04; wire this doc's plugins first.

## 1. Plugin manager

vim-plug does work in Neovim, but the target is lazy.nvim (the ecosystem standard: lockfile, lazy-loading, per-plugin spec files). Bootstrap:

```lua
-- lua/config/lazy.lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = false },
})
```

Every file in `lua/plugins/` returning a spec table is loaded automatically. Commit `lazy-lock.json` to the rc repo for reproducible machines.

## 2. Verdicts

This section is the quick migration answer (what carries to Neovim and as what). Section 7 is the companion inventory: what every plugin actually DOES day to day, whether it is really in use, and which have been silently inert or broken. Use section 7 as the source of truth for pruning decisions, in gVim today as well as in the new config.

### Replaced (better native/modern equivalent)

| Old plugin | Replacement | Why |
|---|---|---|
| vim-lsp, vim-lsp-settings, async.vim, asyncomplete.vim, asyncomplete-lsp.vim | Native LSP + blink.cmp | Doc 04. This is the main payoff of the migration. |
| vim-polyglot, vim-csharp, html5.vim, vim-json, elzr/vim-json, javascript-libraries-syntax, vim-ps1 | nvim-treesitter | Real parsers instead of regex syntax. VB has no treesitter parser, so vim-vb stays (see keepers). |
| vim-airline + themes | lualine.nvim | Includes the Colemak layer indicator from doc 01 and navic breadcrumbs from doc 04. |
| vim-gitgutter | gitsigns.nvim | Also answers the "Git Diff Margin" VS extension (doc 04). Kills bug 3 from doc 02. |
| nerdtree + nerdtree-git-plugin | neo-tree.nvim | Keep `<F8>` and `<C-n>` toggles. Git status icons built in. |
| vista.vim | aerial.nvim | Keep `<F10>`. LSP/treesitter backends, no ctags binary needed. |
| bufexplorer | telescope.nvim buffers picker | Keep `<F7>`. |
| vim-buftabline | bufferline.nvim | `showtabline=2` already set in doc 02. |
| ctrlp/fzf (were commented out) | telescope.nvim | The single biggest daily-driver gain. |
| vim-startify | snacks.nvim dashboard | Bookmark keys v/b/p/m preserved via `Machine.rc_repo`. |
| yggdroot/indentline | snacks.nvim indent | Treesitter-aware, highlights the current scope (better than VS Indent Guides). |
| comfortable-motion | snacks.nvim scroll | Smooth scrolling for `<C-d>/<C-u>/<C-f>/<C-b>` without custom flick maths. |
| goyo | snacks.nvim zen | |
| (Bclose, undefined) | snacks.nvim bufdelete | `<leader>bc` closes buffer, keeps window layout. |
| (input prompts) | snacks.nvim input | Makes `vim.ui.input` a real insert-mode buffer, so Colemak lmaps apply in prompts (doc 01, section 4 note). |
| luochen1990/rainbow | rainbow-delimiters.nvim | Treesitter-based; also answers VS "Rainbow Braces" (doc 04). |
| jiangmiao/auto-pairs | nvim-autopairs | The custom `g:AutoPairs` dict (triple quotes/backticks) is default behavior + endwise rules. |
| maxbrunsfeld/vim-yankstack | yanky.nvim | Yank-ring with telescope picker. |
| xolox/vim-session + vim-misc | persistence.nvim | Old `g:session_*` settings die. `require("persistence").load()` restores per-cwd sessions; no lock files. |
| scrooloose/nerdcommenter (listed twice) | built-in `gc` operator | Neovim 0.10+ comments natively (`gcc`, `gc` in visual). If the `<leader>c...` NERDCommenter muscle memory matters more, keeping nerdcommenter also works; default verdict is built-in. |
| machakann/vim-highlightedyank | built-in `TextYankPost` autocmd | Done in doc 02. |
| honza/vim-snippets | friendly-snippets | blink.cmp's snippets source (doc 04) consumes the friendly-snippets collection; add `rafamadriz/friendly-snippets` as a blink dependency. |
| myusuf3/numbers.vim | 10-line autocmd | Section 5. |
| chiel92/vim-autoformat, json-formatter.vim, vim-pwsh-formatter | conform.nvim | One formatter framework; jq/xmllint/csharpier wired in docs 02/04. |
| rhysd/vim-healthcheck | built-in `:checkhealth` | That plugin was a backport of Neovim's feature. |
| ap/vim-css-color | nvim-colorizer.lua | |
| vim-scripts/visSum.vim | own `SumNumbers` port | Done in doc 02. |
| chrisbra/vim-diff-enhanced, rickhowe/diffchar.vim | built-in diff options | `diffopt` gets `algorithm:patience` (doc 02); add `linematch:60` for word-level alignment, which is what diffchar was approximating. |
| tpope/vim-dispatch, Shougo/vimproc | overseer.nvim | Doc 04 (build/test/run tasks). |

### Kept as-is (work fine in Neovim, muscle memory preserved)

`tpope/vim-surround`, `tpope/vim-repeat`, `tpope/vim-fugitive`, `tpope/vim-rhubarb`, `junegunn/gv.vim`, `godlygeek/tabular`, `tpope/vim-sleuth`, `andymass/vim-matchup` (gains treesitter integration), `sukima/xmledit`, `tpope/vim-jdaddy`, `chrisbra/csv.vim`, `chrisbra/unicode.vim`, `wellle/visual-split.vim`, `dhruvasagar/vim-zoom`, `mbbill/undotree` (keep `<F9>`), `vimwiki/vimwiki` (dev branch), `aklt/plantuml-syntax`, `tacahiroy/vim-vb` (no treesitter VB parser exists; this stays the vb/cls/bas syntax), `reedes/vim-wordy`, `mogelbrod/vim-jsonpath`, `dpelle/vim-LanguageTool` + `rhysd/vim-grammarous` (port the `g:` vars verbatim; a later optional upgrade is the ltex-ls language server), `aserebryakov/vim-todo-lists`, `iamcco/markdown-preview.nvim` (was configured but commented out in the plug file; it is an nvim-first plugin, enable it and port the `mkdp` vars).

### Dropped (dead weight, superseded, or broken all along)

| Plugin | Reason |
|---|---|
| `universal-ctags/ctags` | This was a bug: it cloned the ctags C SOURCE CODE as a vim plugin; it never provided a binary. Vista's ctags executive needed `choco install universal-ctags` separately. With aerial on LSP/treesitter, ctags is unnecessary. |
| `devjoe/vim-codequery` | Superseded by LSP references/telescope; needed external tools and vimproc. |
| `vim-scripts/align` | tabular covers it. |
| `s3rvac/AutoFenc` | Neovim's default `fileencodings` detection covers the practical cases. |
| `vim-scripts/SQLUtilities` + deps | Only if actually used; `conform.nvim` with `sql-formatter` is the modern path. Reinstate if missed. |
| `nvie/vim-flake8` | Python diagnostics via LSP if ever needed. |
| `actionshrimp/vim-xpath` | Python2-era; broken. `:%!xmllint --xpath ...` or treesitter queries cover it. |
| `skywind3000/vim-preview`, `vim-voom/VOoM`, `bpstahlman/txtfmt` | Niche/stale; aerial covers outline needs including markdown. Reinstate individually if missed. |
| `idanarye/vim-merginal`, `jreybert/vimagit`, `c9s/helper.vim`, `c9s/treemenu.vim`, `c9s/hypergit.vim` | Ancient; fugitive's `:Git` plus telescope `git_branches`/`git_commits` cover all of it. Optional richer TUI: NeogitOrg/neogit. |
| `vim-scripts/utl.vim` | Built-in `gx` opens links. |
| `inkarkat/vim-PatternsOnText` | Note: this always required `inkarkat/vim-ingo-library`, which was never in the plug file, so advanced commands were broken anyway. Reinstate WITH the library if the `:Substitute...` family is actually missed. |
| `uguu-org/vim-matrix-screensaver` | Fun only; works if wanted. |
| All colorscheme packs (fu, Selenitic, vim-colorschemes, Son-of-Obisidian, palofobsidian, vim-one) | Replaced by one treesitter-aware scheme (below); `anderson` kept for continuity. |

## 3. Specs

### `lua/plugins/ui.lua`

```lua
return {
  { "folke/tokyonight.nvim", lazy = false, priority = 1000,
    config = function()
      -- mirror the old try/catch cascade: preferred scheme, then fallbacks
      for _, scheme in ipairs({ "tokyonight-moon", "anderson", "habamax" }) do
        if pcall(vim.cmd.colorscheme, scheme) then break end
      end
    end },
  { "tlhr/anderson.vim" }, -- the old gvim look, available via :colorscheme anderson

  { "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local function layer() return vim.bo.iminsert == 1 and "CMK" or "QWE" end
      return {
        sections = {
          lualine_c = { "filename" }, -- navic breadcrumbs appended in doc 04
          lualine_x = { layer, "encoding", "fileformat", "filetype" },
        },
      }
    end },

  { "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {} },

  { "folke/snacks.nvim", priority = 1000, lazy = false,
    opts = {
      input = {},      -- insert-mode vim.ui.input (Colemak lmaps apply, doc 01)
      indent = {},     -- indent guides with active-scope highlight
      scroll = {},     -- smooth scrolling (comfortable-motion replacement)
      zen = {},        -- goyo replacement
      bufdelete = {},
      dashboard = {
        preset = {
          keys = {
            { icon = "v", key = "v", desc = "vimrc",      action = function() vim.cmd.edit(Machine.rc_repo .. "/Vim/vimrc/_vimrc") end },
            { icon = "b", key = "b", desc = "nvim init",  action = function() vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua") end },
            { icon = "p", key = "p", desc = "PS profile", action = function() vim.cmd.edit(Machine.rc_repo .. "/Windows/Powershell/Microsoft.Powershell_profile.ps1") end },
            { icon = "m", key = "m", desc = "PS profile (machine)", action = function() vim.cmd.edit(Machine.rc_repo .. "/Windows/Microsoft.Powershell_profile.ps1") end },
            { icon = "r", key = "r", desc = "Recent files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
            { icon = "q", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
    keys = {
      { "<leader>bc", function() Snacks.bufdelete() end, desc = "Close buffer, keep window" },
      { "<leader>z",  function() Snacks.zen() end,       desc = "Zen mode (goyo)" },
    } },
}
```

### `lua/plugins/editing.lua`

```lua
return {
  { "nvim-treesitter/nvim-treesitter",
    branch = "master", -- REQUIRED: see the branch note below this spec block
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c_sharp", "lua", "vim", "vimdoc", "json", "xml", "html", "css",
          "markdown", "markdown_inline", "python", "sql", "powershell",
          "javascript", "yaml", "regex", "diff", "gitcommit",
        },
        highlight = { enable = true },
        indent = { enable = true },
        matchup = { enable = true }, -- vim-matchup integration
      })
    end },

  { "windwp/nvim-autopairs", event = "InsertEnter", opts = {} },
  { "HiPhish/rainbow-delimiters.nvim" },
  { "gbprod/yanky.nvim", opts = {},
    keys = {
      { "p", "<Plug>(YankyPutAfter)",  mode = { "n", "x" } },
      { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
      { "<C-p>", "<Plug>(YankyPreviousEntry)" },
    } },
  { "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        json = { "jq" },
        xml = { "xmllint" },
        -- cs = { "csharpier" },  -- enabled in doc 04
      },
    } },
  { "mbbill/undotree", keys = { { "<F9>", "<cmd>UndotreeToggle<cr>" } } },
  { "folke/persistence.nvim", event = "BufReadPre", opts = {},
    keys = {
      { "<leader>qs", function() require("persistence").load() end, desc = "Restore session for cwd" },
      { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    } },
  { "catgoose/nvim-colorizer.lua", opts = {} }, -- development moved here from NvChad

  -- keepers (no config needed unless shown)
  { "tpope/vim-surround" }, { "tpope/vim-repeat" },
  { "godlygeek/tabular" }, { "tpope/vim-sleuth" },
  { "andymass/vim-matchup" }, { "sukima/xmledit" },
  { "tpope/vim-jdaddy", ft = "json" },
  { "chrisbra/csv.vim", ft = "csv" },
  { "chrisbra/unicode.vim" },
  { "wellle/visual-split.vim" }, { "dhruvasagar/vim-zoom" },
  { "tacahiroy/vim-vb", ft = "vb" },
  { "aklt/plantuml-syntax", ft = "plantuml" },
  { "reedes/vim-wordy", cmd = { "Wordy", "WordyWordy" } },
  { "aserebryakov/vim-todo-lists" },
  { "vimwiki/vimwiki", branch = "dev",
    init = function() vim.g.vimwiki_list = { { path = "~/vimwiki/" } } end },
  { "mogelbrod/vim-jsonpath", ft = "json",
    init = function() vim.g.jsonpath_register = "*" end,
    config = function()
      vim.api.nvim_create_autocmd("FileType", { pattern = "json",
        callback = function()
          vim.keymap.set("n", "<leader>d", "<cmd>call jsonpath#echo()<cr>", { buffer = true, silent = true })
          vim.keymap.set("n", "<leader>g", "<cmd>call jsonpath#goto()<cr>", { buffer = true, silent = true })
        end })
    end },
  { "dpelle/vim-LanguageTool", cmd = "LanguageToolCheck",
    init = function()
      vim.g.languagetool_jar = "C:/ProgramData/chocolatey/lib/languagetool/tools/LanguageTool-4.8/languagetool-commandline.jar"
      vim.g.languagetool_lang = "en-US"
    end },
  { "iamcco/markdown-preview.nvim", build = "cd app && npm install", ft = "markdown",
    init = function()
      vim.g.mkdp_page_title = "「${name}」"
      vim.g.mkdp_filetypes = { "markdown" }
    end },
}
```

Windows note for treesitter: parser compilation needs a C compiler on PATH. Easiest: `choco install zig` (treesitter uses it automatically) or `choco install llvm`. Run `:TSUpdate` after install and confirm `:checkhealth nvim-treesitter` is green.

Branch note for treesitter (important): nvim-treesitter's default branch is now `main`, a full incompatible rewrite in which the `nvim-treesitter.configs` module used above does not exist; without `branch = "master"` the spec errors at startup. `master` is feature-frozen and officially guaranteed against Neovim 0.11 (it runs on current stable, but will not receive new parsers forever). When adopting the `main` rewrite later, the config becomes `require("nvim-treesitter").install({ ... })` plus a `FileType` autocmd calling `vim.treesitter.start()`, and the `matchup = { enable = true }` key moves out (configure vim-matchup's treesitter integration per its own docs at that point).

### `lua/plugins/nav.lua`

```lua
return {
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<F7>",       "<cmd>Telescope buffers<cr>",    desc = "Buffers (bufexplorer)" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Grep (needs ripgrep)" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>",   desc = "Recent files" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help" },
    },
    opts = {} },

  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
    keys = {
      { "<F8>",  "<cmd>Neotree toggle<cr>" },
      { "<C-n>", "<cmd>Neotree toggle<cr>" },
    },
    opts = { filesystem = { follow_current_file = { enabled = true } } } },

  { "stevearc/aerial.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = { { "<F10>", "<cmd>AerialToggle!<cr>", desc = "Outline (vista)" } },
    opts = { backends = { "lsp", "treesitter", "markdown" } } },
}
```

### `lua/plugins/git.lua`

```lua
return {
  { "tpope/vim-fugitive" }, { "tpope/vim-rhubarb" },
  { "junegunn/gv.vim", cmd = "GV" },
  { "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false, -- :Gitsigns toggle_current_line_blame
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, l, r) vim.keymap.set(mode, l, r, { buffer = bufnr }) end
        map("n", "]c", function() gs.nav_hunk("next") end)
        map("n", "[c", function() gs.nav_hunk("prev") end)
        map("n", "<leader>hp", gs.preview_hunk)
        map("n", "<leader>hs", gs.stage_hunk)
        map("n", "<leader>hr", gs.reset_hunk)
        map("n", "<leader>hb", gs.blame_line)
      end,
    } },
}
```

## 4. numbers.vim replacement

Add to `lua/autocmds.lua` (doc 02): relative numbers in Normal mode, absolute in Insert or when unfocused, plus the old toggle map.

```lua
local numgrp = vim.api.nvim_create_augroup("rc_numbers", { clear = true })
vim.g.rc_numbers_auto = true
vim.api.nvim_create_autocmd({ "InsertEnter", "FocusLost" }, { group = numgrp,
  callback = function() if vim.g.rc_numbers_auto and vim.wo.number then vim.wo.relativenumber = false end end })
vim.api.nvim_create_autocmd({ "InsertLeave", "FocusGained", "BufEnter" }, { group = numgrp,
  callback = function()
    if vim.g.rc_numbers_auto and vim.wo.number and vim.bo.buftype == "" then vim.wo.relativenumber = true end
  end })
vim.keymap.set("n", "<leader>jf", function() vim.wo.relativenumber = not vim.wo.relativenumber end)
vim.keymap.set("n", "<leader>fj", function() vim.g.rc_numbers_auto = not vim.g.rc_numbers_auto end)
```

The `buftype == ""` guard replaces the old `g:numbers_exclude` list (special buffers like trees, dashboards, and terminals all have a non-empty buftype or their own number settings).

## 5. GUI: Neovide (gvim replacement)

Install: `choco install neovide` (or winget). Launch with `neovide` or `neovide <file>`; it reads the exact same config. Font: install the same Nerd Font used by gvim (`choco install nerd-fonts-cascadiacode` provides CaskaydiaCove). Add to `init.lua`:

```lua
if vim.g.neovide then
  vim.o.guifont = "CaskaydiaCove Nerd Font Mono:h10"
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_scroll_animation_length = 0.2
  -- font size up/down (replaces the old FontSizePlus/Minus functions)
  vim.keymap.set("n", "<C-=>", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1 end)
  vim.keymap.set("n", "<C-->", function() vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1 end)
  vim.keymap.set("n", "<C-0>", function() vim.g.neovide_scale_factor = 1.0 end)
end
```

Not portable from gvim: scrollbars (`guioptions` b/r), menu/toolbar. Neovide has none and that is by design; everything else (mouse, clipboard, mousehide) just works. Terminal Neovim in Windows Terminal is also fully usable with the same config; Neovide is only the gvim-feel option.

## 6. Verification

`:Lazy` shows all plugins installed with no errors; `:checkhealth` green for treesitter, telescope, gitsigns; `<F7>/<F8>/<F9>/<F10>` all open their respective UIs; a `.cs` file shows treesitter highlighting (`:InspectTree`); `<leader>bc` closes a buffer without destroying the split layout; the dashboard shows the v/b/p/m bookmarks on `nvim` with no arguments; `]c`/`[c` jump between hunks in a modified tracked file. Then re-run the doc 01 acceptance checklist to confirm no plugin stole a mapped key (`:verbose lmap e`, `:verbose nmap :`).

## 7. Full plugin inventory: what each one actually does (the pruning list)

The plug file grew organically, and several entries have been dead weight for years without anyone noticing, because a plugin that silently fails costs startup time and memory but never announces itself. This section describes every ACTIVE plugin in `_vimrc.plug`: what it does in daily use, whether it is actually reachable in the current setup, and the migration verdict. Commented-out entries are ignored (they are already pruned).

The "Used today?" column is the pruning signal, with five honest values: **wired** (explicit config or mappings exist in `_vimrc`, so it is deliberately in use), **automatic** (does its job with zero setup the moment it is relevant), **self-serve** (only does anything when you invoke its commands/maps, so only you know if you use it), **inert** (missing a dependency or setup it always needed; it has never worked here), **redundant** (something else in this same config already covers it). The verdict column is the Neovim-migration verdict from section 2; for pruning gVim today, use the "safe to prune now" list at the end instead, because syntax packs and the vim-lsp stack must stay in gVim even though Neovim replaces them.

Editor compatibility marking for this inventory: every plugin below is classic Vimscript and runs in **both** Vim and Neovim, so rows are not marked individually. The exceptions: `rhysd/vim-healthcheck` is Vim-only in purpose (Neovim has `:checkhealth` natively), and the **inert** rows work in neither editor as installed. Wherever a Verdict points at a Lua plugin or a Neovim built-in, that replacement is **Neovim-only** and the original plugin must stay in gVim. The closing "incoming Neovim side" list is **Neovim-only** in its entirety. Section 8 lists suggested NEW plugins with a per-item Vim/Nvim/Both tag, since those genuinely vary.

### Misc / editing

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| godlygeek/tabular | Aligns text on a pattern: `:Tabularize /=` lines up assignments, `/\|` lines up markdown tables. | self-serve | Keep |
| andymass/vim-matchup | Extends `%` to language keywords (`if/endif`, open/close tags) and highlights the matching pair under the cursor. | automatic | Keep |
| maxbrunsfeld/vim-yankstack | After a paste, `<M-p>` cycles back through older yanks. | self-serve | Replace → yanky.nvim |
| devjoe/vim-codequery | Code-search UI (`:CodeQuery`) over ctags/gtags databases. Needs external index tools plus a COMPILED vimproc DLL; neither exists here, so it has never functioned. | inert | Drop |
| sukima/xmledit | XML editing helpers: auto-closes the tag when `>` is typed, jump between and rename matching tags. | automatic (xml) | Keep |
| jiangmiao/auto-pairs | Types the closing bracket/quote for you; the custom `g:AutoPairs` dict added triple quotes and backtick fences. | wired | Replace → nvim-autopairs |
| scrooloose/nerdcommenter | Comment toggling: `<leader>cc` comment, `<leader>cu` uncomment, `<leader>c<space>` toggle. Listed TWICE in the plug file. | self-serve | Replace → built-in `gc` |
| tpope/vim-repeat | Support library that lets `.` repeat surround and other plugin actions. | automatic | Keep (surround dependency) |
| tpope/vim-surround | Surround operators: `cs"'` change quotes, `ds(` delete parens, `ysiw)` wrap a word. | self-serve | Keep |
| honza/vim-snippets | Snippet DEFINITIONS only; it requires a snippet ENGINE (UltiSnips or SnipMate), neither of which was ever installed. Dead weight the entire time. | inert | Drop (friendly-snippets on nvim) |
| vim-scripts/align | `:Align`, an older tabular. Only remaining purpose: it is a DEPENDENCY of SQLUtilities. | redundant (except as dep) | Drop or keep, paired with SQLUtilities |

### Diff

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| rickhowe/diffchar.vim | Word/character-level highlighting inside diff mode instead of whole-line. | automatic (diff mode) | Drop → `diffopt+=linematch:60` |
| chrisbra/vim-diff-enhanced | Gave Vim's OLD external-diff era the patience algorithm. `_vimrc` also sets `diffopt+=internal,algorithm:patience`, which made this redundant on every Vim since 8.1.0360. | redundant | Drop |

### Formatting

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| chiel92/vim-autoformat | `:Autoformat` runs an external formatter for the current filetype (formatter binaries must be installed separately). | self-serve | Replace → conform.nvim |
| XadillaX/json-formatter.vim | A JSON pretty-print command. The `<leader>=` jq mapping in `_vimrc` already does this. | redundant | Drop |
| JayDoubleu/vim-pwsh-formatter | Formats PowerShell buffers through PSScriptAnalyzer's Invoke-Formatter. | self-serve | Drop (conform/LSP formatting) |
| s3rvac/AutoFenc | Detects a file's encoding on open and reloads it correctly. | automatic | Drop |
| vim-scripts/SQLUtilities | `:SQLUFormatter` reformats SQL statements (depends on Align, above). | self-serve | Keep if used, else drop with align |

### Checkers / runners

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| tpope/vim-dispatch | Async build/test runner: `:Dispatch dotnet build` into quickfix without blocking. Doc 05 wires it for C#. | self-serve | Keep in gVim (doc 05); overseer on nvim |
| Shougo/vimproc.vim | Async process library that requires a per-platform COMPILED DLL; never built here, and its only dependent (codequery) is dropped anyway. | inert | Drop |
| reedes/vim-wordy | Prose linter: `:Wordy weak` highlights weak/problematic words while writing. | self-serve | Keep if prose work matters |
| nvie/vim-flake8 | Runs flake8 on Python files; its default `<F7>` map collides with the global `<F7>` BufExplorer map inside Python buffers. | self-serve, conflicted | Drop (LSP covers Python if ever needed) |

### Languages

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| tacahiroy/vim-vb | VB6/VBScript syntax and indent; what makes the `.cls`/`.bas` files readable. Listed TWICE. | automatic | Keep (no treesitter VB parser exists) |
| tpope/vim-jdaddy | JSON text objects and motions: `aj` selects a JSON value, `gqaj` pretty-prints it. | self-serve | Keep |
| elzr/vim-json | JSON syntax with quote concealing. Listed TWICE. | automatic | Drop → treesitter |
| actionshrimp/vim-xpath | Interactive XPath search against the buffer. Python-2 era; broken on modern builds. | inert | Drop |
| tpope/vim-sleuth | Detects an opened file's indent style (shiftwidth/expandtab) from its contents automatically. | automatic | Keep |

### Undo / visual aids

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| mbbill/undotree | Visual tree of undo history (`<F9>`), including branches normal undo loses. | wired | Keep |
| wellle/visual-split.vim | Opens/resizes a split to exactly the visual selection (`:VSSplit`). | self-serve | Keep if used |
| chrisbra/csv.vim | CSV tooling: column highlighting, `:ArrangeColumn`, per-column sums and queries. | automatic (csv) | Keep |
| chrisbra/unicode.vim | `:UnicodeName` identifies the character under the cursor; digraph and Unicode lookup tables. | self-serve | Keep |
| myusuf3/numbers.vim | Relative numbers in Normal mode, absolute in Insert; `<leader>jf`/`<leader>fj` toggles. | wired | Replace → autocmd (section 4) |
| skywind3000/vim-preview | Previews the tag/file under cursor in a popup. Requires you to map its keys; none were ever mapped, so it has likely never been invoked. | self-serve, unwired | Drop |
| vim-scripts/visSum.vim | Sums numbers in a visual selection. `_vimrc` defines its own `SumNumbers()` on `<leader>s` doing the same thing, shadowing this. | redundant | Drop |
| dhruvasagar/vim-zoom | `<C-w>m` maximizes the current window, again restores the layout. | self-serve | Keep |
| machakann/vim-highlightedyank | Briefly flashes the region just yanked. | automatic | Drop → built-in autocmd (doc 02) |
| bpstahlman/txtfmt | Rich-text markup (bold/colors) inside plain text files; needs filetype setup that was never configured. | inert | Drop |
| vim-voom/VOoM | Two-pane outline navigator for markdown/LaTeX (`:Voom markdown`). | self-serve | Drop (aerial covers outlines) |
| junegunn/goyo.vim | Distraction-free writing mode: centers the buffer, hides UI chrome. | self-serve | Replace → snacks zen |
| yggdroot/indentline | Draws vertical indent guides (per-level glyphs configured for the GUI). | wired | Replace → snacks indent |
| luochen1990/rainbow | Colors nested parens/brackets by depth (`rainbow_active=1`). | wired | Replace → rainbow-delimiters |
| mhinz/vim-startify | Start screen with recent files and the v/b/p/m bookmarks. | wired | Replace → snacks dashboard |

### Completion / LSP (the whole stack rises and falls together)

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| prabirshrestha/vim-lsp | The language-server client: powers `gd`, `<f2>` rename, diagnostics; pyls registration wired. | wired | Replace → native LSP (doc 04) |
| mattn/vim-lsp-settings | Auto-installs and registers language servers (`:LspInstallServer`); root markers wired. | wired | Replace → Mason (doc 04) |
| prabirshrestha/async.vim | Job-control compatibility shim; vim-lsp dependency. | automatic | Drop with the stack |
| prabirshrestha/asyncomplete.vim + asyncomplete-lsp.vim | The completion popup fed by vim-lsp. | automatic | Replace → blink.cmp |

### Movement / files / buffers / sessions

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| yuttie/comfortable-motion.vim | Physics-based smooth scrolling; `<C-d>/<C-u>/<C-f>/<C-b>` wired to flick impulses. | wired | Replace → snacks scroll |
| scrooloose/nerdtree + xuyuanp/nerdtree-git-plugin | File explorer sidebar (`<F8>`/`<C-n>`) with custom git status glyphs. | wired | Replace → neo-tree |
| ap/vim-buftabline | Shows open buffers in the tabline (pairs with `<leader>bn`/`bp` cycling). | wired | Replace → bufferline |
| jlanzarotta/bufexplorer | Buffer list picker (`<F7>`). | wired | Replace → telescope buffers |
| xolox/vim-session + xolox/vim-misc | Named sessions (`:SaveSession`/`:OpenSession`) stored under `.vimstorage`; vim-misc exists only as its library. | wired | Replace → persistence.nvim |

### Syntax packs (all must STAY in gVim; the Drop verdicts are Neovim-only, where treesitter takes over)

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| sheerun/vim-polyglot | Bundle of 100+ language syntax/indent packs, loaded on demand (`sln` disabled via `g:polyglot_disabled`). | automatic | Drop → treesitter |
| OrangeT/vim-csharp | C# syntax extras plus csproj/sln/razor highlighting. | automatic | Drop → treesitter |
| PProvost/vim-ps1 | PowerShell syntax, indent, folding. | automatic | Drop → treesitter powershell |
| othree/html5.vim | HTML5 tag/attribute syntax and omni-completion. | automatic | Drop → treesitter |
| othree/javascript-libraries-syntax.vim | Extra highlighting for jQuery/React/Angular API names. | automatic | Drop |
| aklt/plantuml-syntax | PlantUML diagram syntax. | automatic | Keep (no treesitter parser) |

### Coloring

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| ap/vim-css-color | Paints CSS color codes (`#a4c639`) in their actual color inside the buffer. | automatic | Replace → nvim-colorizer |
| uguu-org/vim-matrix-screensaver | `:Matrix` toy screensaver. | self-serve | Your call; dropped by default |
| tlhr/anderson.vim | The primary GUI colorscheme in the `_vimrc` cascade. | wired | Keep (legacy fallback scheme) |
| vim-scripts/Selenitic, flazz/vim-colorschemes | Provide the cascade fallbacks (`selenitic`, and `zenburn`/`molokai_dark` for terminals from the flazz mega-pack). | wired (fallbacks) | Drop (tokyonight + anderson suffice) |
| vim-scripts/fu, vim-scripts/Son-of-Obisidian, psmay/vim-colors-palofobsidian, rakr/vim-one | Colorschemes referenced NOWHERE in `_vimrc`. Pure cargo. | redundant | Drop |

### Search / git / status / tags / tools

| Plugin | What it does | Used today? | Verdict |
|---|---|---|---|
| mogelbrod/vim-jsonpath | Shows the dotted JSON path to the cursor (`<leader>d`), jumps to a path (`<leader>g`), copies it to `*`. | wired | Keep |
| tpope/vim-fugitive | THE git plugin: `:Git blame`, `:Gdiffsplit`, staging, object browsing. | self-serve | Keep |
| tpope/vim-rhubarb | GitHub glue for fugitive: `:GBrowse` opens the current line on github.com. | self-serve | Keep |
| junegunn/gv.vim | Commit history browser: `:GV`, `:GV!` for the current file. | self-serve | Keep |
| idanarye/vim-merginal | Branch-management sidebar over fugitive (checkout/merge from a list). | self-serve | Drop (`:Git branch` / telescope) |
| jreybert/vimagit | Magit-style interactive staging buffer. | self-serve | Drop (gitsigns hunk staging + fugitive) |
| airblade/vim-gitgutter | Diff signs in the gutter. Degraded as wired: `gitgutter_map_keys=0` disabled ALL hunk maps with no replacements mapped, so only the signs were ever reachable (no hunk nav/stage/preview), and its statusline autocmd calls a function that does not exist (doc 02 bug 3). | wired (degraded) | Replace → gitsigns |
| c9s/hypergit.vim + c9s/helper.vim + c9s/treemenu.vim | A 2010-era git menu/commit UI trio (helper and treemenu exist only as hypergit's deps). | inert/stale | Drop |
| bling/vim-airline + vim-airline/vim-airline-themes | The statusline/tabline engine (powerline glyphs wired). | wired | Replace → lualine |
| universal-ctags/ctags | The ctags C SOURCE repo mistakenly listed as a plugin; contributes nothing to Vim. | inert | Drop |
| liuchengxu/vista.vim | Symbol outline sidebar (`<F10>`). Default executive is `ctags`, which needs a ctags.exe on PATH that this setup never provided, so `<F10>` has been failing for most filetypes; only the vim-lsp executive worked where a server was attached. | wired (degraded) | Replace → aerial |
| vimwiki/vimwiki | Personal wiki: `<leader>ww` opens `~/vimwiki`, linking, diary. | wired | Keep |
| aserebryakov/vim-todo-lists | Checkbox/todo management inside `.todo` files (toggle done, reorder). | automatic (.todo) | Keep if used |
| rhysd/vim-healthcheck | Backport of Neovim's `:checkhealth` to Vim. | self-serve | Drop (built into nvim) |
| vim-scripts/utl.vim | "Universal text linking": `:Utl` follows URLs/file references in text. Built-in `gx` covers the URL case. | self-serve | Drop |
| dpelle/vim-LanguageTool | Grammar checking via the LanguageTool jar (`:LanguageToolCheck`); jar path wired. | wired | Keep one grammar plugin |
| rhysd/vim-grammarous | A SECOND frontend to the same LanguageTool jar (auto-check, quickfix listing). Two plugins, one job. | wired, redundant | Keep one grammar plugin |
| inkarkat/vim-PatternsOnText | Advanced `:substitute` variants (`:SubstituteExcept` etc.). Requires ingo-library, never installed, so most of its commands error. | inert | Drop (or add the dependency) |

### Safe to prune from `_vimrc.plug` TODAY (gVim behavior unchanged)

These are the inert, broken, and redundant rows: removing them changes nothing except startup time and disk, because they were never reachable or are already covered. `devjoe/vim-codequery`, `Shougo/vimproc.vim`, `honza/vim-snippets`, `actionshrimp/vim-xpath`, `bpstahlman/txtfmt`, `universal-ctags/ctags`, `inkarkat/vim-PatternsOnText`, `c9s/hypergit.vim` + `c9s/helper.vim` + `c9s/treemenu.vim`, `chrisbra/vim-diff-enhanced`, `XadillaX/json-formatter.vim`, `vim-scripts/visSum.vim`, `skywind3000/vim-preview`, the duplicate `Plug` lines (second `nerdcommenter`, second `elzr/vim-json`, second `tacahiroy/vim-vb`), one of the two LanguageTool frontends, and the four unreferenced colorschemes (`fu`, `Son-of-Obisidian`, `palofobsidian`, `vim-one`). The only coupled pair to decide together: `vim-scripts/align` + `vim-scripts/SQLUtilities` (the latter needs the former; keep both or drop both).

### The incoming Neovim side, same treatment (all Neovim-only)

What each NEW plugin from docs 03/04 does, so this list can be pruned by need too. Core (hard to argue with): **lazy.nvim** (plugin manager: lockfile, lazy loading), **nvim-treesitter** (real parsers; feeds highlighting, folds, rainbow, aerial, matchup), **telescope.nvim** + plenary (fuzzy picker for files/buffers/grep/symbols/diagnostics; replaces bufexplorer and the long-commented ctrlp/fzf itch), **gitsigns.nvim** (gutter signs plus the hunk nav/stage/preview/blame that gitgutter had disabled), **lualine.nvim** (statusline; hosts the Colemak CMK/QWE indicator and code breadcrumbs), **tokyonight.nvim** (treesitter-aware colorscheme). Strong defaults, individually skippable: **snacks.nvim** (six small modules replacing five old plugins: dashboard/indent/input/scroll/zen/bufdelete), **bufferline.nvim** (buffers in the tabline), **neo-tree.nvim** + nui + web-devicons (file tree), **aerial.nvim** (symbol outline on `<F10>`), **rainbow-delimiters.nvim**, **todo-comments.nvim** (TODO highlighting plus project-wide TODO pickers), **nvim-autopairs**, **yanky.nvim** (yank ring), **conform.nvim** (formatter dispatcher: jq/xmllint/csharpier), **persistence.nvim** (per-directory sessions), **nvim-colorizer.lua**, **nvim-navic** (breadcrumbs). C# stack, needed only for the doc 04 goal: **mason.nvim** (installs server/debugger binaries), **roslyn.nvim** (the C# language server integration), **blink.cmp** + friendly-snippets (completion), **easy-dotnet.nvim** (solution/test-runner/launch-profile glue), **nvim-dap** + **nvim-dap-ui** + netcoredbg (debugging), **overseer.nvim** (optional task runner for build output).

## 8. Suggested additions: plugins NOT currently installed, worth reviewing

Curated against the same bar as the Visual Studio extensions in doc 04: things useful enough to cost RAM in a daily-driver editor doing C# work. Nothing here is required; docs 04 and 05 already contain the complete required C# stacks. Editor tags: **Vim** / **Nvim** / **Both**. Colemak note where relevant: plugins that read a character via their own `getchar()` prompt (jump-label motions and similar) receive the RAW QWERTY key, because language mappings only apply where the editor itself reads text; labels are displayed on screen so this is workable, but it is worth knowing before adopting any label-based motion plugin.

### Daily editing power (editor-agnostic)

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| wellle/targets.vim | Both | Many more text objects: `ci,` between commas, `cia` a function argument, `ci'` from anywhere on the line, next/last variants (`cin)`). For C# method calls with long argument lists this is a daily workhorse. Probably the highest value-per-byte suggestion on this page. |
| tpope/vim-unimpaired | Both | Paired bracket mappings: `]q`/`[q` walk the quickfix (build errors), `]b`/`[b` buffers, `]e` exchange lines, `yon` toggle numbers, `yow` toggle wrap. Turns the doc 05 build-to-quickfix workflow into two keystrokes. |
| tpope/vim-abolish | Both | Case-aware substitution (`:%Subvert/facilit{y,ies}/building{,s}/g` handles case variants in one pass) and case coercion: `crs` snake_case, `crc` camelCase, `crp` PascalCase on the word under cursor. Useful for C# naming-convention churn. |
| AndrewRadev/splitjoin.vim | Both | `gS` splits a one-line statement into multiline, `gJ` joins back: argument lists, object initializers, LINQ chains. Pairs naturally with C#'s long constructor signatures. |
| janko/vim-test | Both | Run the nearest test / current file / whole suite from the buffer (`:TestNearest`). ALREADY in `_vimrc.plug` commented out; doc 05 section 4 wires it for `dotnet test`. Listed here because enabling it is effectively an addition. |
| voldikss/vim-floaterm | Both | Floating terminal toggle (`:FloatermToggle`): run the app or a quick `dotnet build` without arranging splits. On Neovim, toggleterm.nvim (doc 04 mention) is the alternative; floaterm works in both. Colemak reminder from doc 01: terminal-mode typing is untranslated in Neovim. |
| tpope/vim-projectionist | Both | Per-project "alternate file" jumping (`:A` flips between `Foo.cs` and `FooTests.cs`) driven by a small `.projections.json`. Small setup cost, big payoff in test-heavy solutions. |
| liuchengxu/vim-which-key / folke/which-key.nvim | Vim / Nvim | Pops up a menu of available continuations after `<leader>` pauses. With the large organically grown `<leader>` map set in this config, this is self-documentation: forgotten mappings (this inventory found several) become discoverable instead of dead. |

### C# / IDE additions for Vim (gVim as the main editor)

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| junegunn/fzf + junegunn/fzf.vim | Vim | Fuzzy finding for files/buffers/ripgrep/history (`:Files`, `:Rg`, `:Buffers`). BOTH were already in `_vimrc.plug` commented out, which suggests the itch existed. This is the single biggest daily-quality gain available to gVim; needs the fzf binary (`choco install fzf`). Neovim answer is telescope (doc 03), so tagged Vim. |
| editorconfig/editorconfig-vim | Vim | Honors `.editorconfig`, which nearly every .NET repo carries (indent, line endings, C# style rules). Also already present commented-out. Neovim 0.9+ has this BUILT IN, so the plugin is Vim-only in purpose. |
| dense-analysis/ale + rhysd/vim-lsp-ale | Vim | Async lint/fix engine; the bridge plugin makes vim-lsp diagnostics render through ALE's signs/loclist UI, giving one consistent diagnostics surface. Was in `_vimrc.plug` commented out, and the airline/ALE glue in `_vimrc` hints it was tried. On Neovim, native diagnostics make this unnecessary. |
| SirVer/ultisnips | Vim | A snippet ENGINE, which is the missing half that would finally activate the `honza/vim-snippets` definitions carried inert for years (section 7). Requires a Vim built with python3. On Neovim, blink.cmp + friendly-snippets covers snippets (doc 04). |
| puremourning/vimspector | Both | The Vim debugger UI wired to netcoredbg in doc 05 section 3: breakpoints, stepping, variable panes with VS-style F-keys. Built for Vim; runs on Neovim with a reduced UI, where nvim-dap (doc 04) is the native choice instead. |
| nickspoons/vim-sharpenup | Vim | Statusline pieces and default mappings for OmniSharp-vim. ONLY relevant if doc 05 route B (omnisharp-vim) is chosen over route A. |
| markonm/traces.vim | Vim | Live preview of `:substitute` (and other range commands) as the pattern is typed. Neovim has this built in as `inccommand`, so Vim-only in purpose. Given how much `:%s/` work this config's history implies, a strong quality-of-life add. |
| (no plugin) cfilter | Both | `:packadd cfilter` ships WITH Vim and Neovim: `:Cfilter /error/` filters the quickfix list after a build. Zero cost, just needs the packadd line; already referenced in docs 04/05. |

### C# / IDE additions for Neovim (beyond the doc 04 stack)

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| folke/trouble.nvim | Nvim | A structured panel for diagnostics, references, and quickfix: all solution warnings/errors in one filterable tree. The closest thing to VS's Error List window, which nothing in doc 04 fully replicates. |
| j-hui/fidget.nvim | Nvim | LSP progress spinner in the corner. Roslyn takes noticeable time to load a large solution; without this the editor just feels dead until it finishes. Small plugin, disproportionate sanity value. |
| theHamsta/nvim-dap-virtual-text | Nvim | Shows variable values INLINE next to the code while stopped at a breakpoint, the way Visual Studio does. Completes the VS-debugging feel on top of nvim-dap. |
| kevinhwang91/nvim-bqf | Nvim | Better quickfix: floating preview of each entry, fuzzy filtering. Directly upgrades the build-errors and find-references workflows. |
| sindrets/diffview.nvim | Nvim | VS-grade diff and merge UI: side-by-side diffs for any revision, file history browser, merge-tool with three panes. The strongest git upgrade beyond gitsigns/fugitive for someone used to Visual Studio's diff viewer. |
| nvim-neotest/neotest + Issafalcon/neotest-dotnet | Nvim | A Test-Explorer-style tree with per-test run/debug and inline pass/fail marks. ALTERNATIVE to easy-dotnet's built-in runner (doc 04); adopt one, not both. Choose this if per-test DAP debugging from the tree matters. |
| folke/flash.nvim | Nvim | Label-based jump motions: type two chars, labels appear, one more key jumps anywhere on screen. Powerful, but read the Colemak note at the top of this section: its labels arrive as raw QWERTY. Try after the doc 01 setup is muscle-memory stable, not before. |
| stevearc/oil.nvim | Nvim | Edit directories like a text buffer: rename/delete/create files with normal editing then `:w`. Some people replace their file tree with it entirely; others hate it. Zero-risk trial. |

### Filetype power-ups: markdown, JSON, XML

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| MeanderingProgrammer/render-markdown.nvim | Nvim | Renders markdown IN the buffer: styled headings, aligned tables, checkboxes, concealed link syntax, highlighted code blocks, while staying fully editable. Complements the already-installed markdown-preview.nvim (browser preview) rather than replacing it. Alternative with the same job: OXY2DEV/markview.nvim; pick one. |
| preservim/vim-markdown (conceal mode) | Vim | The classic-Vim approximation of render-markdown, built on syntax concealing: with `conceallevel=2`, `**bold**` displays bold without the asterisks, `[text](url)` collapses to the text, markup reappears on the line being edited. ALREADY INSTALLED via vim-polyglot's bundle; needs only `au FileType markdown setlocal conceallevel=2` plus `let g:vim_markdown_conceal_code_blocks = 0`. REQUIRED companion fix: indentLine hijacks conceal (`concealcursor`) in every buffer and keeps the current line concealed while editing; exclude markdown with `let g:indentLine_fileTypeExclude = ['markdown']` or concealing will feel broken. Ceiling note: conceal can only hide/restyle existing characters, not draw table borders or heading backgrounds the way extmark-based Neovim renderers can; Vim 9 text properties could support that but no mainstream plugin uses them. Heavier-conceal alternative: vim-pandoc/vim-pandoc-syntax (bullets as `•`, prettiest result, brings the pandoc plugin family with it). |
| bullets.vim (preservim/bullets.vim) | Both | Auto-continues list bullets and numbering on Enter in markdown, renumbers on demand. Small, invisible, constantly useful for notes/vimwiki. |
| dhruvasagar/vim-table-mode | Both | Live markdown/org table formatting: type `\|`-separated cells and the table aligns itself as you go. The classic answer to hand-aligning tables. |
| b0o/SchemaStore.nvim + vscode-json-language-server | Nvim | Schema-aware JSON: completion and validation for `appsettings.json`, `launchSettings.json`, `global.json`, GitHub workflows, and a thousand other known file names, pulled from schemastore.org. Very .NET-relevant. Server installs via Mason; Vim equivalent is `:LspInstallServer json-languageserver` through the existing vim-lsp-settings (without the schema catalog plugin, so weaker). |
| lemminx (XML language server) | Both | XSD-aware XML: validates against referenced schemas, completes tags/attributes FROM the XSD, hover docs. Given the `.xsd` and Billing-XML work visible in `_vimrc`, this is likely the highest-value filetype add here. Install: Mason `lemminx` on Neovim, `:LspInstallServer lemminx` via vim-lsp-settings on Vim. |

### Console / terminal / HTTP

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| akinsho/toggleterm.nvim | Nvim | Persistent toggleable terminals (floating or split) with per-terminal identity: one for `dotnet watch`, one for git, toggled by keymap. The Neovim-native equivalent of the floaterm suggestion above; adopt one of the two. |
| mistweaverco/kulala.nvim | Nvim | An in-editor Postman for the request/response workflow: executes `.http` request files (method + headers + body, `###`-separated), response with body/headers/timing in a split, in-file variables, `http-client.env.json` environment switching (dev/staging/prod), dynamic values (`$uuid` etc.), and request chaining (capture a login token from one response into the next request's header). Runs curl underneath and can copy any request as a curl command. NOT covered vs Postman: GUI collection runner, mock servers, monitors, team workspaces, OAuth wizards. The trade in its favor: `.http` is the same format Visual Studio 2022's built-in editor and VS Code's REST Client use, so collections live diffable in the repo and stay shareable with VS colleagues. Vim-side alternative: diepm/vim-rest-console (works, but its own buffer format: no VS compatibility, no env-file ecosystem). |

### AI / agent integration (Claude Code, Codex)

The direct answer to "does VS Code-style integration exist outside a plain terminal": yes, for Neovim. The Claude Code IDE integration is a WebSocket MCP protocol (the extension starts a localhost server, writes a lock file under `~/.claude/ide/`, and the CLI connects to it, syncing cursor position, selection, and open-file context in real time). `coder/claudecode.nvim` implements that exact protocol in pure Lua, so Claude gets the same "it knows where you are" context as in VS Code.

Billing/auth model, because it matters: every plugin in this table drives the ACTUAL installed CLI (the npm/native `claude` and `@openai/codex` installs), not the APIs directly. The plugin is only the editor-side transport; the CLI does all model calls with whatever auth it already has, so existing subscriptions (Claude Pro/Max login, ChatGPT sign-in via `~/.codex/auth.json`) apply exactly as in a standalone terminal, and API-key pay-per-token is only used if the CLI itself is configured that way. This is NOT true of a different plugin family (avante.nvim, codecompanion.nvim, ChatGPT.nvim): those call provider APIs directly with an API key and bill per token, which is why they are not recommended here. Classic Vim has NO equivalent: these implementations are all Lua, so in gVim the agents stay standalone-terminal tools with no editor context. One Colemak note (doc 01): typing INTO any in-editor agent terminal is Terminal-mode and untranslated, so prompt-typing needs the hardware layer flip exactly like a standalone terminal; selection-sending commands (`:ClaudeCodeSend`) are normal-mode and unaffected.

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| coder/claudecode.nvim | Nvim | The full Claude Code IDE integration: embedded Claude terminal, real-time cursor/selection context, `:ClaudeCodeSend` sends the visual selection as an at-mention, `:ClaudeCodeAdd` adds files to context, and Claude's proposed edits open as native Neovim diffs to accept/reject. Uses snacks.nvim for its terminal if present (already in the doc 03 stack). Needs the Claude Code CLI installed; Neovim 0.8+. This is the recommendation. |
| greggh/claude-code.nvim | Nvim | The simpler alternative: toggles Claude Code in a terminal split, supports `--continue`, auto-reloads files Claude modifies. No context protocol. Choose this only if the full integration feels like too much; not both. |
| anirudhsundar/codex.nvim or eskalVAR/codex.nvim | Nvim | Codex CLI integration beyond a terminal wrapper: both talk to the Codex app-server over JSON-RPC, sending real editor context (buffers, cursor, diagnostics via placeholders like `@this`/`@buffer`), streaming responses into a split and surfacing approval requests in-editor. OpenAI ships no official Neovim plugin; these are the community options with actual context. Simpler terminal-wrapper alternatives exist (johnseth97/codex.nvim, jcarlos7121/codex.nvim). |
| github/copilot.vim | Both | Inline ghost-text completions. Listed for completeness as the only mainstream AI plugin that works in classic Vim; independent of (and combinable with) the agent integrations above. |

### General programmer QoL

| Plugin | Editor | What it adds and why it earns its RAM |
|---|---|---|
| tpope/vim-dadbod + kristijanhusak/vim-dadbod-ui + vim-dadbod-completion | Both | Run SQL against SQL Server (and anything else) from the editor: a connection/saved-query sidebar, execute the paragraph under the cursor, results in a split, table/column completion. `vim-dadbod` was ALREADY in `_vimrc.plug` commented out, and the SQL augroup plus SQLUtilities show real SQL work happens here; this is probably the most underrated suggestion on the page. The completion piece supports both asyncomplete (Vim) and blink/cmp (Neovim). |
| mg979/vim-visual-multi | Both | Multiple cursors: `<C-n>` selects the next occurrence of the word like VS's Ctrl+D, then edit all instances at once. The muscle-memory bridge for the most-missed VS editing feature. |
| MagicDuck/grug-far.nvim | Nvim | Project-wide find-and-replace UI over ripgrep: live preview of every match, edit the replacement, apply across the solution. The VS Ctrl+Shift+H equivalent. Vim-side answer is the built-in workflow `:grep pattern` then `:cfdo s/pattern/new/g \| update`, which works but has no preview. |
| ThePrimeagen/harpoon (branch harpoon2) | Nvim | Pin the 4-5 files of the current task to numbered slots and jump with one chord, independent of buffer order. Complements telescope (search everything) with "the files I am actually working on right now". |
