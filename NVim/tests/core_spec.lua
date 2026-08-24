-- Verification for the core config (02-core-config.md section 9), covering the
-- option dispositions, the ported mappings and commands, filetype detection and
-- the per-filetype autocmds.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("core")

T.section("options")
T.check("mapleader", vim.g.mapleader, ",")
T.check("shellslash OFF (netcoredbg needs this)", vim.o.shellslash, false)
T.check("maxmempattern", vim.o.maxmempattern, 2000000)
T.check("timeoutlen", vim.o.timeoutlen, 500)
T.check("shiftwidth", vim.o.shiftwidth, 3)
T.check("tabstop", vim.o.tabstop, 3)
T.check("softtabstop", vim.o.softtabstop, 3)
T.check("foldcolumn is the string '1'", vim.o.foldcolumn, "1")
T.check("foldlevelstart", vim.o.foldlevelstart, 3)
T.check("undofile", vim.o.undofile, true)
T.check("backup", vim.o.backup, true)
T.check("showtabline", vim.o.showtabline, 2)
T.check("wrap off", vim.o.wrap, false)
T.check("number", vim.o.number, true)
T.check("ignorecase", vim.o.ignorecase, true)
T.check("smartcase", vim.o.smartcase, true)
T.check("showmatch", vim.o.showmatch, true)
T.check("matchtime", vim.o.matchtime, 2)
T.check("smartindent", vim.o.smartindent, true)
T.truthy("whichwrap includes h", vim.o.whichwrap:find("h"))
T.truthy("diffopt has algorithm:patience", vim.o.diffopt:find("algorithm:patience"))
T.truthy("diffopt has linematch:60", vim.o.diffopt:find("linematch:60"))
T.truthy("switchbuf has useopen", vim.o.switchbuf:find("useopen"))
T.truthy("fileformats has unix", vim.o.fileformats:find("unix"))
T.truthy("wildignore covers bin", vim.o.wildignore:find("bin"))
T.check("grepprg prefers ripgrep", vim.o.grepprg, "rg --vimgrep --smart-case")

T.section("state lives in Neovim's own dirs, not .vimstorage")
T.truthy("undodir under nvim-data", vim.o.undodir:lower():find("nvim%-data"))
T.check("undodir avoids vimstorage", vim.o.undodir:lower():find("vimstorage") == nil, true)

-- No state file may be written beside the edited file. Neovim's default
-- 'backupdir' begins with ".", meaning the file's own directory, which
-- scatters Program.cs~ through source trees. Easy to miss when testing,
-- because 'backupskip' excludes the temp directory.
for _, opt in ipairs({ "backupdir", "directory", "undodir", "viewdir" }) do
   local value = vim.o[opt]
   local has_dot = value:find("^%.[,\\/]") ~= nil or value:find(",%.[,\\/]?") ~= nil or value == "."
   T.check(opt .. " never writes beside the file", has_dot, false)
   T.truthy(opt .. " points into nvim-data", value:lower():find("nvim%-data"))
end

T.section("mappings")
for _, spec in ipairs({
   { "n", ",<CR>" }, { "n", ",n" },
   { "n", "<C-J>" }, { "n", "<C-K>" }, { "n", "<C-H>" }, { "n", "<C-L>" },
   { "n", ",bd" }, { "n", ",ba" }, { "n", ",bn" }, { "n", ",bp" },
   { "n", ",cd" },
   { "n", ",ss" }, { "n", ",sn" }, { "n", ",sp" }, { "n", ",sa" }, { "n", ",s?" },
   { "n", ",m" }, { "n", ",q" }, { "n", ",x" },
   { "n", ",cw" }, { "n", ",ts" }, { "n", ",t2" }, { "n", ",t3" }, { "n", ",t4" },
   { "n", ",fa" }, { "n", ",jf" }, { "n", ",fj" }, { "n", ",S" },
   { "x", "*" }, { "x", "#" }, { "x", ",S" },
}) do
   T.check(string.format("%s map %q", spec[1], spec[2]), H.has_map(spec[1], spec[2]), true)
end
-- <leader>bc comes from the snacks bufdelete spec, not keymaps.lua; the old
-- _vimrc pointed it at :Bclose, which was never defined anywhere.
T.check("<leader>bc mapped (snacks bufdelete)", H.has_map("n", ",bc"), true)

T.section("commands")
local cmds = vim.api.nvim_get_commands({})
for _, c in ipairs({ "DiffOrig", "XmlMinify", "XmlBeautify", "FindAll" }) do
   T.check("command :" .. c, cmds[c] ~= nil, true)
end

T.section("filetype detection")
local dir = H.tempdir()
for _, case in ipairs({
   { "cls", "vb" }, { "bas", "vb" }, { "xsd", "xsd" }, { "xaml", "xaml" }, { "sln", "sln" },
}) do
   local f = string.format("%s/probe.%s", dir, case[1])
   vim.fn.writefile({ "" }, f)
   vim.cmd("edit " .. f)
   T.check(string.format(".%s detects as %s", case[1], case[2]), vim.bo.filetype, case[2])
end

T.section("per-filetype autocmds")
local function with_ft(ext, ftname, fn)
   local f = string.format("%s/ftprobe.%s", dir, ext)
   vim.fn.writefile({ "" }, f)
   vim.cmd("edit " .. f)
   if vim.bo.filetype ~= ftname then vim.bo.filetype = ftname end
   fn()
end

with_ft("py", "python", function()
   T.check("python indents by 4", vim.bo.shiftwidth, 4)
   T.check("python textwidth 79", vim.bo.textwidth, 79)
end)
with_ft("json", "json", function()
   T.check("json indents by 4", vim.bo.shiftwidth, 4)
   T.check("json folds by treesitter expr", vim.wo.foldexpr, "v:lua.vim.treesitter.foldexpr()")
end)
with_ft("xml", "xml", function()
   T.check("xml indents by 2", vim.bo.shiftwidth, 2)
   T.check("xml folds by indent", vim.wo.foldmethod, "indent")
end)
with_ft("ps1", "ps1", function()
   T.check("ps1 indents by 3", vim.bo.shiftwidth, 3)
end)

T.section("formatoptions autocmd")
vim.cmd("enew!")
vim.bo.filetype = "lua"
T.check("c/r/o removed so comment leaders are not auto-inserted",
   vim.bo.formatoptions:find("[cro]") == nil, true)

T.section("machine resolution")
T.check("Machine.location", Machine.location, "WORK")
T.check("Machine.home", Machine.home, "C:/Users/ktimins")
T.check("Machine.rc_repo", Machine.rc_repo, "C:/Users/ktimins/Git/rc")
T.check("rc_repo exists on disk", vim.fn.isdirectory(Machine.rc_repo), 1)

T.finish()
