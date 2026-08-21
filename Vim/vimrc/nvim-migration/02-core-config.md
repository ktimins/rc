# 02: Core Config Migration (`_vimrc` → Lua)

Scope: everything in `_vimrc` that is not the Colemak block (doc 01), not plugin configuration (doc 03), and not C# tooling (doc 04). This doc gives a full disposition for every setting, ports for the custom functions and autocmds, and a list of latent bugs in the current `_vimrc` that must NOT be carried over.

## 1. Target layout

As built, the repo side is `NVim/` at the repo root rather than `Vim/nvim/`, and a `gui.lua` (Neovide settings, doc 03 section 5) and a `tests/` directory were added. Otherwise this layout is what was implemented.

```
%LOCALAPPDATA%\nvim\            (junction to NVim/ in the rc repo, see README)
  init.lua
  lua\
    colemak.lua                 (doc 01)
    options.lua
    keymaps.lua
    autocmds.lua
    functions.lua
    machine.lua                 ($LOCATION handling)
    config\
      lazy.lua                  (doc 03)
    plugins\                    (lazy.nvim specs, doc 03)
```

`init.lua`:

```lua
require("colemak").setup()
require("machine")
require("options")
require("keymaps")
require("autocmds")
require("functions")
require("config.lazy")
```

## 2. Machine / `$LOCATION` logic

The old vimrc hardcodes home, storage, and plug-file paths per machine. In Neovim, `stdpath()` removes most of this. What remains worth keeping is the per-machine bookmark list (used by the dashboard, doc 03) and any per-machine tool paths.

```lua
-- lua/machine.lua
local location = (vim.env.LOCATION or ""):upper()
local users = { WORK = "ktimins", THEIA = "rzite", ARES = "rzitex" }
local user = users[location]

local M = {
  location = location,
  home = user and ("C:/Users/" .. user) or vim.fn.expand("~"),
}
M.rc_repo = M.home .. "/Git/rc"
_G.Machine = M -- convenient global for plugin specs
return M
```

Storage: do NOT point Neovim at the existing `.vimstorage` directories. Vim and Neovim disagree on undofile format details and would fight over swap files. Neovim's defaults under `stdpath("state")` (`%LOCALAPPDATA%\nvim-data\...`) are per-editor and correct; the only thing to add is turning persistent undo on (see options below). Backups are kept on for parity with the old `set backup`, into the default state dir.

## 3. Option disposition table

Every `set`/`let` from the non-plugin parts of `_vimrc`. "Default" means Neovim already does this and the line is deleted with no replacement.

| Old line | Verdict | Notes |
|---|---|---|
| `set maxmempattern=2000000` | Port | Option still exists in Neovim. |
| `set nossl` | Port, and important | `shellslash` must stay OFF. Also delete the later contradicting `set shellslash` (see bug list, item 12); shellslash=on breaks netcoredbg breakpoints (doc 04). |
| `set encoding/fileencoding/termencoding` | Delete | utf-8 is the only encoding in Neovim; `termencoding` no longer exists. |
| `set nocompatible` | Delete | Always the case in Neovim. |
| `let mapleader = ','` | Port | `vim.g.mapleader = ","` before plugins load. |
| `set history=9999` | Delete | Neovim default is 10000. |
| `set timeoutlen=500` (and duplicate `set tm=500`) | Port once | `vim.o.timeoutlen = 500`. `tm` is the same option; keep one line. |
| `set undolevels=1000`, `set undoreload=10000` | Delete | Both are the defaults. |
| BufEnter `lcd` autocmd | Replace | Currently broken (bug 1). Replacement in section 5. |
| `let $LANG='en'`, `set langmenu=en` | Delete | Menu localization concern from gVim; irrelevant. |
| `set wildmenu` | Delete | Default. |
| `set wildignore=...` (+ windows branch) | Port | See options.lua below; keep the backslash variants since shellslash is off. |
| `set number` | Port | |
| `set ruler` | Delete | Default. |
| `set cmdheight=2` | Port | Preference; keep for parity. |
| `set hid` and later `set hidden` | Port once | `vim.o.hidden = true` (default in modern Neovim; explicit set is harmless and self-documenting). |
| `set backspace=indent,eol,start` | Delete | Default. |
| `set whichwrap+=<,>,h,l` | Port | `vim.opt.whichwrap:append("<,>,h,l")`. |
| `set ignorecase`, `set smartcase` | Port | |
| `set hlsearch`, `set incsearch` | Delete | Defaults. |
| `set lazyredraw` | Port | Note: if the UI plugin noice.nvim is ever added, remove this (it conflicts); with the doc 03 plugin set it is fine. |
| `set magic` | Delete | Default. |
| `set showmatch`, `set mat=2` | Port | `vim.o.showmatch = true`, `vim.o.matchtime = 2`. |
| `set noerrorbells`, `novisualbell`, `t_vb=`, `tm=500` | Delete | Neovim default `belloff=all` covers it; `t_vb` does not exist. |
| `set foldcolumn=1` | Port | Value is a STRING in Neovim: `vim.o.foldcolumn = "1"`. |
| `set foldlevelstart=3` | Port | |
| `set nowrap` | Port | |
| `set renderoptions=type:directx` | Delete | Vim/Windows GUI rendering option; does not exist in Neovim. |
| `let g:polyglot_disabled` | Delete | polyglot is replaced by treesitter (doc 03). |
| vim-plug sourcing block | Delete | Replaced by lazy.nvim bootstrap (doc 03). |
| `syntax enable` | Delete | Default (and treesitter supersedes it). |
| `t_Co`, ConEmu block | Delete | Terminal control codes do not exist in Neovim. |
| `has('gui_running')` block (colorscheme cascade, guifont cascade, guioptions, mousehide, guitablabel) | Replace | Colorscheme handling moves to doc 03. `guifont` moves to the Neovide section of doc 03. `guioptions`/`mousehide`/`guitablabel` have no Neovim equivalent; delete. |
| terminal colorscheme cascade (zenburn/molokai) | Replace | Doc 03; one scheme for both terminal and GUI now that both use true color. |
| `set ffs=unix,dos` | Port | `vim.opt.fileformats = { "unix", "dos" }`. |
| backup/undo/swap block with `$storage` | Replace | `vim.o.undofile = true`, `vim.o.backup = true`; let swap/undo/backup live in the `stdpath("state")` defaults (section 2 rationale). Delete the `$storage` machinery. |
| `set expandtab` | Port | |
| `set smarttab` | Delete | Default. |
| `set shiftwidth=3`, `set tabstop=3` | Port | Also set `softtabstop = 3` so the `ChangeTabStops` port behaves identically. |
| `filetype plugin indent on` | Delete | Default. |
| `set shellslash` (inside the autocmd block) | DELETE, do not port | Bug 12. Contradicts `set nossl` at the top and breaks .NET debugging paths. |
| `set grepprg=grep\ -nH\ $*` | Replace | Prefer ripgrep when available (snippet below); fall back to old value otherwise. |
| vimrcEx last-position autocmd | Replace | Section 5 (the current one is duplicated and has mangled quoting, bugs 2). |
| `set si` (smartindent) | Port | |
| diffopt patience block | Port unconditionally | Neovim always has internal diff: `vim.opt.diffopt:append({ "internal", "algorithm:patience" })`. Drop the `has("patch-...")` guards. |
| `command DiffOrig` | Port | Section 6. |
| Visual `*` / `#` mappings calling `VisualSelection(...)` | Replace | `VisualSelection` is never defined anywhere in the vimrc (bug 4); working replacement in section 4. |
| `<leader><cr>` and `<leader>n` nohl, window nav `C-h/j/k/l`, buffer maps, `<leader>cd`, spell maps, `<leader>m`, `<leader>q`, `<leader>x` | Port | Section 4. |
| `nnoremap <C-E> <C-E>` | Delete | Self-map no-op. |
| `<leader>bc :Bclose ...` | Replace | `:Bclose` is never defined (bug 5). Use `snacks.bufdelete` or `famiu/bufdelete.nvim` (doc 03) so the window layout survives; map `<leader>bc` to it. |
| `set switchbuf=useopen,usetab,newtab`, `set stal=2` | Port | `vim.opt.switchbuf = { "useopen", "usetab", "newtab" }`, `vim.o.showtabline = 2`. |
| `set laststatus=2` | Delete | Default (consider `= 3` for a single global statusline; user decision, default keep 2). |
| Airline/Vista statusline glue (`NearestMethodOrFunction`) | Delete | lualine + navic replace this wholesale (docs 03/04). |
| Startify bookmarks per machine | Replace | Dashboard plugin bookmarks built from `Machine.rc_repo` (doc 03). |
| ALE/Syntastic commented blocks | Delete | Diagnostics come from native LSP now. |
| GitGutter settings + `User GitGutter` autocmd | Delete | gitsigns replaces (doc 03); the autocmd calls a function that does not exist (bug 3). |
| vim-lsp / vim-lsp-settings / OmniSharp / asyncomplete sections | Delete | Native LSP + blink.cmp replace these (doc 04). The `sln` signcolumn/diagnostic disabling carries over as a small FileType autocmd if sln files still get an LSP attached; with the doc 04 setup no server attaches to `sln`, so nothing is needed. |
| `let g:markdown_fenced_languages = [...]` | Port (fixed) | The old value contains a literal `$FILETYPE` bug; set `vim.g.markdown_fenced_languages = { "powershell=ps1", "csharp=cs", "json", "xml" }` or drop entirely (treesitter highlights fences natively). Recommended: drop. |
| Indentline / rainbow / auto-pairs / session / numbers / comfortable-motion / vimwiki / LanguageTool / mkdp / jsonpath settings | Move | All plugin config: doc 03. |
| Language augroups (SQL/Python/JSON/XML/PS1/VB/vim) | Replace | Section 7. Several are broken today (bugs 6 through 9). |
| Custom functions (Xml*, wrapping, tabstops, FindAll, SumNumbers, font size) | Replace | Section 6. |

### Resulting `lua/options.lua`

```lua
-- lua/options.lua
vim.g.mapleader = ","

local o, opt = vim.o, vim.opt

o.maxmempattern = 2000000
o.shellslash = false        -- required by netcoredbg path handling, see 04
o.timeoutlen = 500
o.number = true
o.cmdheight = 2
o.hidden = true
o.ignorecase = true
o.smartcase = true
o.lazyredraw = true
o.showmatch = true
o.matchtime = 2
o.foldcolumn = "1"
o.foldlevelstart = 3
o.wrap = false
o.expandtab = true
o.shiftwidth = 3
o.tabstop = 3
o.softtabstop = 3
o.smartindent = true
o.showtabline = 2
o.undofile = true
o.backup = true

opt.whichwrap:append("<,>,h,l")
opt.switchbuf = { "useopen", "usetab", "newtab" }
opt.fileformats = { "unix", "dos" }
opt.diffopt:append({ "internal", "algorithm:patience" })

opt.wildignore = {
  "*.pdf", "*.pyo", "*.pyc", "*.zip", "*.so", "*.swp", "*.dll", "*.o",
  "*.DS_Store", "*.obj", "*.bak", "*.exe", "*.jpg", "*.gif", "*.png", "*.a",
  "*\\.git\\*", "*\\.hg\\*", "*\\.svn\\*", "*\\bin\\*", "*\\pkg\\*",
  "*\\.vs\\*", "*\\.localhistory\\*",
}

if vim.fn.executable("rg") == 1 then
  o.grepprg = "rg --vimgrep --smart-case"
  o.grepformat = "%f:%l:%c:%m"
else
  o.grepprg = "grep -nH $*"
end
```

## 4. `lua/keymaps.lua`

```lua
-- lua/keymaps.lua
local map = vim.keymap.set

-- search highlight off
map("n", "<leader><cr>", "<cmd>nohlsearch<cr>", { silent = true })
map("n", "<leader>n", "<cmd>nohlsearch<cr>")

-- window navigation
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-h>", "<C-w>h")
map("n", "<C-l>", "<C-w>l")

-- buffers ( <leader>bc gets its mapping in the bufdelete plugin spec, doc 03 )
map("n", "<leader>bd", "<cmd>bdelete<cr>")
map("n", "<leader>ba", "<cmd>bufdo bd<cr>")
map("n", "<leader>bn", "<cmd>bnext<cr>")
map("n", "<leader>bp", "<cmd>bprev<cr>")

-- cwd to current file
map("n", "<leader>cd", "<cmd>cd %:p:h<cr><cmd>pwd<cr>")

-- spelling
map("n", "<leader>ss", "<cmd>setlocal spell!<cr>")
map("n", "<leader>sn", "]s")
map("n", "<leader>sp", "[s")
map("n", "<leader>sa", "zg")
map("n", "<leader>s?", "z=")

-- strip Windows ^M when encodings are mangled (verbatim port)
map("n", "<leader>m", "mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm")

-- scribble buffers
map("n", "<leader>q", "<cmd>e ~/buffer<cr>")
map("n", "<leader>x", "<cmd>e ~/buffer.md<cr>")

-- visual * and # search for the selection (replaces the never-defined
-- VisualSelection() from the old vimrc; classic escape-safe idiom)
map("x", "*", [[y/\V<C-R>=escape(@",'/\')<CR><CR>]])
map("x", "#", [[y?\V<C-R>=escape(@",'?\')<CR><CR>]])
```

## 5. `lua/autocmds.lua`

```lua
-- lua/autocmds.lua
local aug = vim.api.nvim_create_augroup("rc_core", { clear = true })
local au = vim.api.nvim_create_autocmd

-- auto-cd to the current buffer's directory (fixed port; the old autocmd had
-- a literal <cr> in the :lcd argument and silently failed)
au("BufEnter", {
  group = aug,
  callback = function()
    local dir = vim.fn.expand("%:p:h")
    if dir ~= "" and vim.fn.isdirectory(dir) == 1 then
      pcall(vim.cmd.lcd, dir)
    end
  end,
})

-- return to last edit position (replaces both mangled copies in the old vimrc)
au("BufReadPost", {
  group = aug,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- brief highlight on yank (replaces vim-highlightedyank)
au("TextYankPost", {
  group = aug,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- never auto-insert comment leaders (port of the formatoptions autocmd)
au("FileType", {
  group = aug,
  callback = function() vim.opt_local.formatoptions:remove({ "c", "r", "o" }) end,
})
```

Note: on Neovim older than 0.11 use `vim.highlight.on_yank`; `vim.hl` is the current name.

## 6. `lua/functions.lua` (custom function ports)

```lua
-- lua/functions.lua

-- DiffOrig: diff the buffer against the file on disk
vim.api.nvim_create_user_command("DiffOrig", function()
  vim.cmd("vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis")
end, {})

-- XML minify / beautify. Intent port, not verbatim: the old Vimscript used
-- double-quoted execute strings where "\s\+" collapses to the literal "s+",
-- so the whitespace-collapsing substitute never matched (bug 15). This port
-- uses the pattern the function always meant to run.
local function xml_minify()
  vim.bo.filetype = "xml"
  vim.cmd([[normal! ggVGJ]])
  vim.cmd([[silent! %s/>\s\+</></e]])
  vim.cmd([[silent! %s/> </></e]])
end
local function xml_beautify()
  xml_minify()
  vim.cmd([[silent! %s/></>\r</e]])
  vim.cmd([[normal! gg=G]])
end
vim.api.nvim_create_user_command("XmlMinify", xml_minify, {})
vim.api.nvim_create_user_command("XmlBeautify", function() xml_beautify() xml_beautify() end, {})

-- display-wrap toggle with gj/gk motion swap
local function enable_wrap()
  vim.opt_local.wrap = true
  vim.opt_local.list = false
  vim.opt_local.linebreak = true
  for _, m in ipairs({ "n", "x" }) do
    vim.keymap.set(m, "j", "gj", { buffer = true })
    vim.keymap.set(m, "k", "gk", { buffer = true })
  end
end
local function disable_wrap()
  vim.opt_local.wrap = false
  vim.opt_local.list = true
  vim.opt_local.linebreak = false
  for _, m in ipairs({ "n", "x" }) do
    pcall(vim.keymap.del, m, "j", { buffer = true })
    pcall(vim.keymap.del, m, "k", { buffer = true })
  end
end
vim.keymap.set("n", "<leader>cw", function()
  if vim.wo.wrap then disable_wrap() print("Disabling display wrapping.")
  else enable_wrap() print("Enabling display wrapping.") end
end)

-- tab stop switching
local function change_tabstops(n)
  local function apply(v)
    v = tonumber(v)
    if v and v > 0 then
      vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = v, v, v
    end
  end
  if n then apply(n)
  else vim.ui.input({ prompt = "Tabstop value: " }, apply) end
end
vim.keymap.set("n", "<leader>ts", function() change_tabstops() end, { silent = true })
for _, n in ipairs({ 2, 3, 4 }) do
  vim.keymap.set("n", "<leader>t" .. n, function() change_tabstops(n) end, { silent = true })
end

-- FindAll: vimgrep a pattern in the current file into the quickfix list
-- (the old mapping line was syntactically broken; command worked, map did not)
vim.api.nvim_create_user_command("FindAll", function()
  vim.ui.input({ prompt = "Enter pattern: " }, function(p)
    if p and p ~= "" then
      vim.cmd(string.format("vimgrep /%s/ %% | copen", p))
    end
  end)
end, {})
vim.keymap.set("n", "<leader>fa", "<cmd>FindAll<cr>")

-- sum numbers line by line (str2float keeps the exact old parsing behavior)
local function sum_lines(first, last)
  local sum = 0
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, first - 1, last, false)) do
    sum = sum + vim.fn.str2float(line)
  end
  print("Sum = " .. sum)
end
vim.keymap.set("x", "<leader>s", function()
  vim.cmd([[execute "normal! \<Esc>"]])
  sum_lines(vim.fn.line("'<"), vim.fn.line("'>"))
end)
vim.keymap.set("n", "<leader>s", function() sum_lines(1, vim.fn.line("$")) end)
```

The commented-out `FontSizePlus/Minus` functions are superseded by Neovide's built-in scale keybinds (doc 03) and are not ported.

## 7. Filetype handling

Replace the `ftdetect/cls.vim` file and the extension-based augroups with `vim.filetype.add` (put at the top of `autocmds.lua`):

```lua
vim.filetype.add({
  extension = {
    cls = "vb",     -- replaces ftdetect/cls.vim (Neovim would guess ST/TeX)
    bas = "vb",
    sln = "sln",
    xsd = "xsd",
    xaml = "xaml",
  },
})
```

Per-filetype settings become FileType autocmds. Note that several of the old augroups never fired (see bug list); this port implements the intent, not the broken text:

```lua
local ft = vim.api.nvim_create_augroup("rc_filetypes", { clear = true })
local function on_ft(pattern, cb)
  vim.api.nvim_create_autocmd("FileType", { group = ft, pattern = pattern, callback = cb })
end

on_ft("python", function()
  vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = 4, 4, 4
  vim.bo.textwidth = 79
  vim.bo.expandtab = true
end)

on_ft("json", function()
  vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = 4, 4, 4
  vim.bo.expandtab = true
  vim.bo.formatoptions = "tcq2l"
  -- treesitter folds: syntax-based folding goes inert once treesitter
  -- highlighting (doc 03) owns the buffer
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  vim.keymap.set("n", "<leader>=", ":%!jq .<CR>", { buffer = true })
  vim.api.nvim_buf_create_user_command(0, "FormatJson", "%!jq .", {})
end)

on_ft({ "html", "xml", "xsd", "xaml" }, function()
  vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = 2, 2, 2
  vim.bo.expandtab = true
  vim.bo.cindent = true
  vim.bo.formatoptions = "tcq2l"
  vim.wo.foldmethod = "indent"
end)
on_ft({ "xml", "xsd", "xaml" }, function()
  vim.keymap.set("n", "<leader>=", ":silent %!xmllint.exe --format --recover - 2>NUL<CR>", { buffer = true })
end)

on_ft("ps1", function()
  vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = 3, 3, 3
  vim.bo.expandtab = true
  vim.bo.cindent = true
  vim.bo.formatoptions = "tcq2l"
  vim.wo.foldmethod = "indent"
end)

on_ft("sql", function()
  -- uppercase SQL keywords in the selection (verbatim port)
  vim.keymap.set("x", "<leader>rp",
    [[:s/\<update\>\|\<select\>\|\<from\>\|\<where\>\|\<join\>\|\<on\>\|\<as\>\|\<left join\>\|\<inner join\>\|\<group by\>\|\<order by\>\|\<distinct\>\|\<top\>\|\<like\>\|\<begin\>\|\<trans\>\|\<transaction\>\|\<commit\>\|\<rollback\>\|\<declare\>\|\<set\>/\U&/ge<cr>]],
    { buffer = true })
end)
```

The old `vim` augroup (fold-close everything when editing vimscript) is intentionally dropped: the Lua config files use normal folding, and `foldlevelstart` already governs the default. The `sln` filetype needs no special autocmd in Neovim because no LSP or linter attaches to it (the old block existed to fight vim-lsp and vim-csharp).

## 8. Latent bugs in the current `_vimrc` (do NOT port these)

Documented so the implementer knows these were found and intentionally fixed or dropped, not overlooked. Line numbers refer to `_vimrc` as of this writing.

1. Line 72: `autocmd BufEnter,BufRead,BufNewFile * silent! lcd %:p:h<cr>` has a literal `<cr>` inside the `:lcd` argument; the path is invalid and `silent!` hides the failure, so auto-cd has silently done nothing. Fixed port in section 5.
2. Lines 312-318 and 391-393: two copies of the "return to last edit position" autocmd, both with mangled quoting (the mark expression should be `line("'\"")`, apostrophe followed by double quote; neither copy has that). Replaced by one Lua autocmd (section 5).
3. Line 877: `autocmd User GitGutter call updateMyStatusLine()` calls a function defined nowhere; errors on every gitgutter update. Dies with gitgutter (doc 03).
4. Lines 353-354: visual `*`/`#` call `VisualSelection('', '')` which is defined nowhere; visual star search has been broken. Replaced in section 4.
5. Line 372: `<leader>bc` uses `:Bclose`, defined nowhere. Replaced via bufdelete plugin (doc 03).
6. Lines 1244, 1254: `au BufRead, BufNewFile ...` with a space after the comma is invalid; `BufNewFile` is parsed as the pattern, so the xaml and ps1 detection autocmds never worked as intended.
7. Line 1164 `au FileType *.py`, line 1211 `au FileType md`, lines 1269/1274 `au FileType vb/bas set filetype=vb`: FileType takes filetype names, not globs (`*.py` never matches; the filetype is `markdown`, not `md`; the vb ones are circular no-ops).
8. Line 1174: `au BufRead,BufNewFile json set filetype=json` matches only files literally named `json`. Neovim detects json natively; dropped.
9. Line 1236: `au FileType *.Billing.XML foldlevelstart=5` is missing `set` and uses a glob; never worked. Dropped (set it per-project if actually needed).
10. Line 1386: `nnoremap <leader>fa execute :Call FindAll()<cr>` is not valid map syntax (`execute` as rhs text, capital `Call`); the mapping never worked, only `:FindAll` did. Fixed in section 6.
11. Line 969: `g:OmniSharp_server_path` points at the ARES user path even on WORK. Moot (plugin commented out, and doc 04 replaces OmniSharp entirely), noted for completeness.
12. Line 308: `set shellslash` contradicts `set nossl` from line 10, and shellslash=on is a known cause of rejected breakpoints with netcoredbg on Windows (doc 04). The Lua config sets `shellslash = false` exactly once.
13. Line 927: `let g:markdown_fenced_languages = ["PowerShell=$FILETYPE"]` contains a literal unexpanded `$FILETYPE`. Dropped (treesitter handles fence highlighting).
14. Line 369: `nnoremap <C-E> <C-E>` is a no-op self-mapping. Dropped.
15. Line 1306 (`XmlMinify()`): `execute "%s/>\s\+</></e"` uses a double-quoted string, in which `\s` and `\+` lose their backslashes, so the executed pattern was the literal `>s+<` and the whitespace-collapsing substitute never matched. The Lua port in section 6 runs the intended pattern.

## 9. Verification

After implementing docs 01 and 02 (no plugins yet): `nvim` starts with no error messages; `:checkhealth vim.health` clean; the acceptance checklist from doc 01 passes; `:set shellslash?` reports `noshellslash`; opening a `.cls` file reports `filetype=vb`; `<leader>cw`, `<leader>ts`, `:DiffOrig`, `:XmlBeautify` on a scratch XML buffer, and visual `*` on a selected word all behave as described above.
