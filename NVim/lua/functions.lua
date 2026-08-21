-- Custom commands and functions ported from _vimrc.
--
-- These are intent ports, not transcriptions: two of the originals never worked
-- (see the notes inline and 02-core-config.md section 8).

-- Diff the buffer against the file on disk.
vim.api.nvim_create_user_command("DiffOrig", function()
   vim.cmd("vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis")
end, { desc = "Diff buffer against the file on disk" })

-- XML minify / beautify.
--
-- The _vimrc original built its substitute patterns inside DOUBLE-quoted
-- execute strings, where "\s\+" collapses to the literal "s+". The
-- whitespace-collapsing substitute therefore never matched anything. These run
-- the pattern the function always meant to run.
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

vim.api.nvim_create_user_command("XmlMinify", xml_minify, { desc = "Collapse XML to one line" })
vim.api.nvim_create_user_command("XmlBeautify", function()
   -- twice: the first pass splits tags, the second re-indents the result
   xml_beautify()
   xml_beautify()
end, { desc = "Split and re-indent XML" })

-- Display wrapping, with j/k following screen lines while it is on.
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
   if vim.wo.wrap then
      disable_wrap()
      vim.notify("Disabling display wrapping.")
   else
      enable_wrap()
      vim.notify("Enabling display wrapping.")
   end
end, { desc = "Toggle display wrapping" })

-- Tab stop switching: <leader>ts prompts, <leader>t2/t3/t4 jump straight there.
local function change_tabstops(n)
   local function apply(v)
      v = tonumber(v)
      if v and v > 0 then
         vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = v, v, v
      end
   end
   if n then
      apply(n)
   else
      vim.ui.input({ prompt = "Tabstop value: " }, apply)
   end
end

vim.keymap.set("n", "<leader>ts", function() change_tabstops() end,
   { silent = true, desc = "Set tab stops (prompt)" })
for _, n in ipairs({ 2, 3, 4 }) do
   vim.keymap.set("n", "<leader>t" .. n, function() change_tabstops(n) end,
      { silent = true, desc = "Set tab stops to " .. n })
end

-- FindAll: vimgrep a pattern through the current file into the quickfix list.
-- The _vimrc mapping for this was not valid map syntax, so only the command
-- ever worked; the mapping is restored here.
vim.api.nvim_create_user_command("FindAll", function()
   vim.ui.input({ prompt = "Enter pattern: " }, function(p)
      if p and p ~= "" then
         vim.cmd(string.format("vimgrep /%s/ %% | copen", p))
      end
   end)
end, { desc = "Quickfix every match in this file" })
vim.keymap.set("n", "<leader>fa", "<cmd>FindAll<cr>", { desc = "Find all in this file" })

-- Sum the numbers on each line. str2float preserves the old parsing behavior,
-- including how it treats trailing text.
local function sum_lines(first, last)
   local sum = 0
   for _, line in ipairs(vim.api.nvim_buf_get_lines(0, first - 1, last, false)) do
      sum = sum + vim.fn.str2float(line)
   end
   vim.notify("Sum = " .. sum)
end

vim.keymap.set("x", "<leader>s", function()
   vim.cmd([[execute "normal! \<Esc>"]])
   sum_lines(vim.fn.line("'<"), vim.fn.line("'>"))
end, { desc = "Sum numbers in selection" })
vim.keymap.set("n", "<leader>s", function()
   sum_lines(1, vim.fn.line("$"))
end, { desc = "Sum numbers in buffer" })
