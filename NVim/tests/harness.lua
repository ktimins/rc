-- Minimal test harness for the config's regression specs.
--
-- Specs load it by absolute path rather than require(), because tests/ is not
-- on the Lua runtimepath:
--   local H = dofile(vim.fn.stdpath("config") .. "/tests/harness.lua")

local M = {}

M.esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
M.ctrl6 = vim.api.nvim_replace_termcodes("<C-^>", true, false, true)

-- The 't' flag means "handle these as if typed", which is what makes language
-- mappings fire. Keep each call to a SINGLE batch: splitting one logical
-- sequence across several feed() calls does not model real keystrokes and
-- produces misleading results.
function M.feed(keys)
   vim.api.nvim_feedkeys(keys, "tx", false)
end

-- A clean scratch buffer. iminsert is reset explicitly because :enew can reuse
-- an existing empty buffer, which would otherwise carry a toggled translation
-- state into the next case.
function M.scratch(lines)
   vim.cmd("enew!")
   vim.bo.buftype = "nofile"
   vim.bo.iminsert = 1
   vim.api.nvim_buf_set_lines(0, 0, -1, false, lines or { "" })
   vim.api.nvim_win_set_cursor(0, { 1, 0 })
end

function M.tempdir()
   local d = vim.fn.tempname()
   vim.fn.mkdir(d, "p")
   return d
end

function M.global_iminsert()
   return vim.api.nvim_get_option_value("iminsert", { scope = "global" })
end

function M.has_map(mode, lhs)
   for _, m in ipairs(vim.fn.maplist()) do
      if m.mode:find(mode, 1, true) and m.lhs == lhs then
         return true
      end
   end
   return false
end

function M.new(name)
   local t = { name = name, pass = 0, fail = 0 }

   function t.section(title)
      print("")
      print("  == " .. title .. " ==")
   end

   -- deep_equal so table comparisons work; a plain == compares identity and
   -- reports two structurally identical tables as different.
   function t.check(label, got, want)
      if vim.deep_equal(got, want) then
         t.pass = t.pass + 1
         print(string.format("  PASS  %s", label))
      else
         t.fail = t.fail + 1
         print(string.format("  FAIL  %s\n          got  %s\n          want %s",
            label, vim.inspect(got), vim.inspect(want)))
      end
   end

   function t.truthy(label, got)
      t.check(label, not not got, true)
   end

   -- Exits non-zero on failure so the runner and any CI can detect it.
   function t.finish()
      print("")
      print(string.format("  %s: %d passed, %d failed", t.name, t.pass, t.fail))
      if t.fail > 0 then
         vim.cmd("cquit 1")
      end
   end

   return t
end

return M
