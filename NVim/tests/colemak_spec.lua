-- The acceptance checklist from 01-colemak.md section 5, automated.
--
-- "Type X" in that document means pressing the keys that produce X on a plain
-- QWERTY keyboard, which is what feedkeys sends. Re-run this after adding
-- plugins: a plugin that claims ':' or one of the mapped letters breaks the
-- keyboard contract, and doc 03's verification step calls for exactly this.

local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")
local T = H.new("colemak")
local feed, esc, ctrl6 = H.feed, H.esc, H.ctrl6

T.section("1. mapping table")
local lmaps = {}
for _, m in ipairs(vim.fn.maplist()) do
   if m.mode == "l" then lmaps[m.lhs] = m.rhs end
end
local want = require("colemak").table
local n_want, n_got = 0, 0
for _ in pairs(want) do n_want = n_want + 1 end
for _ in pairs(lmaps) do n_got = n_got + 1 end
T.check("34 language mappings are defined", n_got, 34)
T.check("count matches the source table", n_got, n_want)

local mismatches = {}
for k, v in pairs(want) do
   if lmaps[k] ~= v then
      table.insert(mismatches, string.format("%s->%s", k, tostring(lmaps[k])))
   end
end
table.sort(mismatches)
T.check("every mapping matches the source table", mismatches, {})

T.section("2/3. insert mode translates")
H.scratch()
feed("i" .. "qwertyuiop" .. esc)
T.check("top row  qwertyuiop -> qwfpgjluy;", vim.api.nvim_get_current_line(), "qwfpgjluy;")

H.scratch()
feed("i" .. "asdfghjkl;" .. esc)
T.check("home row asdfghjkl; -> arstdhneio", vim.api.nvim_get_current_line(), "arstdhneio")

H.scratch()
feed("i" .. "zxcvbnm" .. esc)
T.check("bottom row zxcvbnm -> zxcvbkm", vim.api.nvim_get_current_line(), "zxcvbkm")

H.scratch()
feed("i" .. "QWERTYUIOP" .. esc)
T.check("shifted QWERTYUIOP -> QWFPGJLUY:", vim.api.nvim_get_current_line(), "QWFPGJLUY:")

T.section("4. normal mode stays raw QWERTY")
H.scratch({ "one", "two", "three" })
feed("j")
T.check("j moves down", vim.api.nvim_win_get_cursor(0)[1], 2)
feed("k")
T.check("k moves up", vim.api.nvim_win_get_cursor(0)[1], 1)

H.scratch({ "delete me", "keep me" })
feed("dd")
T.check("dd deletes a line", vim.api.nvim_get_current_line(), "keep me")

H.scratch({ "alpha beta" })
feed("ciw" .. "x" .. esc)
T.check("ciw changes a word", vim.api.nvim_get_current_line(), "x beta")

T.section("8. Lang-Arg: f/F/t/T/r arguments translate")
H.scratch({ "abc def" })
feed("fk")
T.check("f<k> lands on the e of def", vim.api.nvim_win_get_cursor(0)[2], 5)

H.scratch({ "abc" })
feed("rk")
T.check("r<k> replaces with e", vim.api.nvim_get_current_line(), "ebc")

T.section("5/6/7/12. command line and search")
local seen
local grp = vim.api.nvim_create_augroup("colemak_spec_cmdline", { clear = true })
vim.api.nvim_create_autocmd("CmdlineChanged", {
   group = grp,
   callback = function() seen = vim.fn.getcmdline() end,
})

H.scratch({ "irrelevant" })
seen = nil
feed("/" .. "qwert" .. esc)
T.check("search / translates", seen, "qwfpg")

seen = nil
feed(":" .. "qwert" .. esc)
T.check("cmdline : translates", seen, "qwfpg")

H.scratch({ "line one", "line two" })
seen = nil
feed("V" .. ":" .. "qwert" .. esc)
T.check("visual : keeps the range and translates", seen, "'<,'>qwfpg")

H.scratch({ "a", "b", "c", "d", "e", "f" })
seen = nil
feed("5:" .. esc)
T.check("count 5: still builds a range", seen, ".,.+4")

vim.api.nvim_del_augroup_by_id(grp)

T.section("10. macros round-trip without double translation")
H.scratch({ "", "" })
feed("qa" .. "i" .. "qwert" .. esc .. "q")
T.check("macro records translated text", vim.api.nvim_buf_get_lines(0, 0, 1, false)[1], "qwfpg")
feed("j" .. "@a")
T.check("macro replays identically", vim.api.nvim_buf_get_lines(0, 1, 2, false)[1], "qwfpg")

T.section("11. CTRL-^ toggle")
H.scratch()
feed("i" .. ctrl6 .. "qwert" .. esc)
T.check("toggles off immediately, no lag", vim.api.nvim_get_current_line(), "qwert")

H.scratch()
feed("i" .. ctrl6 .. ctrl6 .. "qwert" .. esc)
T.check("toggling twice restores translation", vim.api.nvim_get_current_line(), "qwfpg")

T.section("13. command grammar is never translated")
H.scratch({ "yankme", "target" })
feed('"ayy')
T.check("register name a is taken literally", vim.fn.getreg("a"), "yankme\n")

T.finish()
