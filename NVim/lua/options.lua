-- Options ported from _vimrc.
--
-- Only lines that Neovim does NOT already do by default survive here. The full
-- per-line disposition (port / delete / replace, and why) is the table in
-- Vim/vimrc/nvim-migration/02-core-config.md section 3. Anything absent from
-- this file was deliberately dropped, not overlooked.

vim.g.mapleader = ","

local o, opt = vim.o, vim.opt

o.maxmempattern = 2000000

-- Must stay OFF. The old _vimrc set 'nossl' at the top and then contradicted
-- itself further down; shellslash=on makes Neovim hand forward-slash paths to
-- netcoredbg, which silently rejects the breakpoints. Set exactly once, here.
o.shellslash = false

o.timeoutlen = 500
o.number = true
o.cmdheight = 2
o.hidden = true
o.ignorecase = true
o.smartcase = true
o.lazyredraw = true
o.showmatch = true
o.matchtime = 2
o.foldcolumn = "1" -- a string in Neovim, unlike Vim
o.foldlevelstart = 3
o.wrap = false
o.expandtab = true
o.shiftwidth = 3
o.tabstop = 3
o.softtabstop = 3 -- added so the ChangeTabStops port behaves identically
o.smartindent = true
o.showtabline = 2

-- Persistent undo and backups go to Neovim's own state directory. Deliberately
-- NOT pointed at the .vimstorage tree gVim uses: the two editors disagree on
-- undofile format and would contend over swap files.
o.undofile = true
o.backup = true

-- Keep backups OUT of the edited file's directory.
--
-- Neovim's default 'backupdir' is ".,<state>/backup//" and that leading "."
-- means the file's own folder, so `backup` scatters Program.cs~ next to the
-- source. 'directory' (swap), 'undodir' and 'viewdir' have no such entry and
-- were already contained; this is the only one that leaked.
--
-- Easy to miss when testing: 'backupskip' excludes the temp directory, so a
-- scratch file under AppData\Local\Temp never produces a backup and the
-- problem looks absent.
--
-- The trailing "//" is load-bearing. It encodes the file's full path into the
-- backup's name, so src/Foo/Program.cs and src/Bar/Program.cs do not overwrite
-- each other's backup.
local backupdir = vim.fn.stdpath("state") .. "/backup//"
vim.fn.mkdir(vim.fn.stdpath("state") .. "/backup", "p")
opt.backupdir = { backupdir }

opt.whichwrap:append("<,>,h,l")
opt.switchbuf = { "useopen", "usetab", "newtab" }
opt.fileformats = { "unix", "dos" }

-- patience carries over from _vimrc unconditionally (Neovim always has the
-- internal diff, so the has("patch-...") guards are gone). linematch adds the
-- word-level alignment that the dropped diffchar.vim was approximating.
opt.diffopt:append({ "internal", "algorithm:patience", "linematch:60" })

opt.wildignore = {
   "*.pdf", "*.pyo", "*.pyc", "*.zip", "*.so", "*.swp", "*.dll", "*.o",
   "*.DS_Store", "*.obj", "*.bak", "*.exe", "*.jpg", "*.gif", "*.png", "*.a",
   "*\\.git\\*", "*\\.hg\\*", "*\\.svn\\*", "*\\bin\\*", "*\\pkg\\*",
   "*\\.vs\\*", "*\\.localhistory\\*",
}

-- ripgrep when present, the old grep invocation otherwise
if vim.fn.executable("rg") == 1 then
   o.grepprg = "rg --vimgrep --smart-case"
   o.grepformat = "%f:%l:%c:%m"
else
   o.grepprg = "grep -nH $*"
end
