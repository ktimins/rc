-- Guards the iminsert leak fix in colemak.lua.
--
-- Vim's i_CTRL-^ moves the GLOBAL iminsert as well as the buffer-local one, so
-- without the InsertLeave repair, toggling translation off in one buffer
-- silently disables it in every buffer opened afterwards. This spec fails if
-- that repair is ever removed or stops working.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("iminsert")
local feed, esc, ctrl6, gl = H.feed, H.esc, H.ctrl6, H.global_iminsert

local dir = H.tempdir()
local A, B = dir .. "/a.txt", dir .. "/b.txt"
vim.fn.writefile({ "" }, A)
vim.fn.writefile({ "" }, B)

T.section("baseline")
vim.cmd("edit " .. A)
T.check("buffer A opens translated", vim.bo.iminsert, 1)
T.check("global default is 1", gl(), 1)

T.section("toggling off in one buffer")
feed("i" .. ctrl6 .. "qwert" .. esc)
T.check("A types raw immediately after the toggle", vim.api.nvim_get_current_line(), "qwert")
T.check("A buffer-local is 0", vim.bo.iminsert, 0)
T.check("global repaired to 1 on InsertLeave", gl(), 1)

T.section("the leak that this fixes")
vim.cmd("edit " .. B)
T.check("B opens translated despite A being off", vim.bo.iminsert, 1)
feed("i" .. "qwert" .. esc)
T.check("B translates", vim.api.nvim_get_current_line(), "qwfpg")

T.section("per-buffer state is remembered")
vim.cmd("buffer " .. vim.fn.bufnr(A))
T.check("A still remembers off", vim.bo.iminsert, 0)
vim.cmd("normal! ggdG")
feed("i" .. "qwert" .. esc)
T.check("A still types raw", vim.api.nvim_get_current_line(), "qwert")

T.section("toggling back on")
vim.cmd("normal! ggdG")
feed("i" .. ctrl6 .. "qwert" .. esc)
T.check("A translates again immediately", vim.api.nvim_get_current_line(), "qwfpg")
T.check("A buffer-local back to 1", vim.bo.iminsert, 1)
T.check("global untouched throughout", gl(), 1)

T.section("normal-mode CTRL-^ is not hijacked")
vim.cmd("edit " .. B)
local before = vim.api.nvim_get_current_buf()
feed(ctrl6)
T.check("normal CTRL-^ still edits the alternate file",
   vim.api.nvim_get_current_buf() == vim.fn.bufnr(A) and before ~= vim.api.nvim_get_current_buf(),
   true)

T.finish()
