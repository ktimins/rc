-- Runs every *_spec.lua in this folder, each in its own Neovim process.
--
-- Separate processes on purpose: specs mutate buffers, options and mappings,
-- and sharing one instance lets state from one spec silently corrupt the next.
--
--   nvim --headless -c "luafile <config>/tests/run.lua" +qa!
--
-- Exits non-zero if any spec fails.

local dir = vim.fn.stdpath("config") .. "/tests"
local specs = vim.fn.glob(dir .. "/*_spec.lua", false, true)
table.sort(specs)

if #specs == 0 then
   io.stderr:write("no specs found in " .. dir .. "\n")
   vim.cmd("cquit 1")
end

local failed = {}

for _, spec in ipairs(specs) do
   local name = vim.fn.fnamemodify(spec, ":t:r")
   io.stdout:write(string.rep("-", 60) .. "\n" .. name .. "\n" .. string.rep("-", 60) .. "\n")

   local res = vim
      .system({ "nvim", "--headless", "-c", "luafile " .. spec, "+qa!" }, { text = true })
      :wait()

   -- headless Neovim writes messages to stderr, so both streams matter
   local out = (res.stdout or "") .. (res.stderr or "")
   io.stdout:write(out)
   io.stdout:write("\n")

   -- A spec that fails to PARSE exits 0 and prints a Lua error, so a non-zero
   -- exit code alone is not enough: that combination silently reported a
   -- broken spec as passing. Require the summary line that finish() emits.
   local reported = out:match("%d+ passed, %d+ failed") ~= nil

   if res.code ~= 0 then
      table.insert(failed, name)
   elseif not reported then
      io.stdout:write(("!! %s produced no result summary (did it fail to load?)\n\n"):format(name))
      table.insert(failed, name)
   end
end

io.stdout:write(string.rep("=", 60) .. "\n")
if #failed == 0 then
   io.stdout:write(string.format("all %d spec(s) passed\n", #specs))
else
   io.stdout:write(string.format("%d of %d spec(s) FAILED: %s\n",
      #failed, #specs, table.concat(failed, ", ")))
   vim.cmd("cquit 1")
end
