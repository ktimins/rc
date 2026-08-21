-- Autocommands and filetype handling.
--
-- Several of the augroups in _vimrc never fired at all (FileType patterns given
-- as globs, `au BufRead, BufNewFile` with a space after the comma, missing
-- `set`). What follows implements the INTENT of those blocks, not their broken
-- text. See 02-core-config.md section 8 for the full list.

-- Filetype detection, replacing ftdetect/cls.vim and the extension augroups.
vim.filetype.add({
   extension = {
      cls = "vb", -- without this Neovim guesses ST or TeX
      bas = "vb",
      sln = "sln",
      xsd = "xsd",
      xaml = "xaml",
   },
})

local aug = vim.api.nvim_create_augroup("rc_core", { clear = true })
local au = vim.api.nvim_create_autocmd

-- Follow the current buffer's directory.
--
-- NOTE: the _vimrc original had a literal <cr> inside the :lcd argument, and
-- silent! swallowed the resulting error, so this has silently done nothing for
-- years. Fixing it therefore turns ON behavior that was only ever intended, not
-- experienced. If it proves annoying, delete this block rather than re-breaking it.
au("BufEnter", {
   group = aug,
   desc = "lcd to the directory of the current file",
   callback = function()
      local dir = vim.fn.expand("%:p:h")
      if dir ~= "" and vim.fn.isdirectory(dir) == 1 then
         pcall(vim.cmd.lcd, dir)
      end
   end,
})

-- Return to the last edit position. Replaces two copies in _vimrc, both with
-- mangled quoting in the mark expression.
au("BufReadPost", {
   group = aug,
   desc = "restore cursor to last known position",
   callback = function(ev)
      local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
      if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(ev.buf) then
         pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
   end,
})

-- Brief highlight on yank, replacing vim-highlightedyank.
au("TextYankPost", {
   group = aug,
   desc = "flash the yanked region",
   callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Never auto-insert comment leaders on a new line.
au("FileType", {
   group = aug,
   desc = "drop the c/r/o formatoptions flags",
   callback = function() vim.opt_local.formatoptions:remove({ "c", "r", "o" }) end,
})

-- Relative line numbers in Normal mode, absolute in Insert or when the window
-- is unfocused. Replaces numbers.vim, keeping its two toggle mappings.
local numgrp = vim.api.nvim_create_augroup("rc_numbers", { clear = true })
vim.g.rc_numbers_auto = true

au({ "InsertEnter", "FocusLost" }, {
   group = numgrp,
   callback = function()
      if vim.g.rc_numbers_auto and vim.wo.number then
         vim.wo.relativenumber = false
      end
   end,
})
au({ "InsertLeave", "FocusGained", "BufEnter" }, {
   group = numgrp,
   callback = function()
      -- the buftype guard replaces numbers.vim's g:numbers_exclude list: trees,
      -- dashboards and terminals all carry a non-empty buftype
      if vim.g.rc_numbers_auto and vim.wo.number and vim.bo.buftype == "" then
         vim.wo.relativenumber = true
      end
   end,
})

vim.keymap.set("n", "<leader>jf", function()
   vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers here" })
vim.keymap.set("n", "<leader>fj", function()
   vim.g.rc_numbers_auto = not vim.g.rc_numbers_auto
end, { desc = "Toggle automatic number switching" })

-- Per-filetype settings.
local ft = vim.api.nvim_create_augroup("rc_filetypes", { clear = true })
local function on_ft(pattern, cb)
   au("FileType", { group = ft, pattern = pattern, callback = cb })
end

local function indent(n)
   vim.bo.tabstop, vim.bo.softtabstop, vim.bo.shiftwidth = n, n, n
   vim.bo.expandtab = true
end

on_ft("python", function()
   indent(4)
   vim.bo.textwidth = 79
end)

on_ft("json", function()
   indent(4)
   vim.bo.formatoptions = "tcq2l"
   -- syntax-based folding goes inert once treesitter owns the buffer, so fold
   -- by treesitter expression instead
   vim.wo.foldmethod = "expr"
   vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
   vim.keymap.set("n", "<leader>=", ":%!jq .<CR>", { buffer = true })
   vim.api.nvim_buf_create_user_command(0, "FormatJson", "%!jq .", {})
end)

-- cindent here is a FALLBACK only, never the active method: 'indentexpr'
-- overrules it, and html/xml/xsd get Neovim's own indent plugins while xaml
-- gets treesitter. It earns its place by covering the window on a fresh machine
-- where parsers have not finished compiling yet.
on_ft({ "html", "xml", "xsd", "xaml" }, function()
   indent(2)
   vim.bo.cindent = true
   vim.bo.formatoptions = "tcq2l"
   vim.wo.foldmethod = "indent"
end)

on_ft({ "xml", "xsd", "xaml" }, function()
   vim.keymap.set("n", "<leader>=",
      ":silent %!xmllint.exe --format --recover - 2>NUL<CR>", { buffer = true })
end)

-- cindent is a fallback here too; treesitter's powershell indent query takes
-- over once the parser is installed. C-style brace indenting was a poor fit for
-- PowerShell, which is why ps1 is no longer in the treesitter skip list.
on_ft("ps1", function()
   indent(3)
   vim.bo.cindent = true
   vim.bo.formatoptions = "tcq2l"
   vim.wo.foldmethod = "indent"
end)

on_ft("sql", function()
   -- uppercase SQL keywords across the selection (verbatim port)
   vim.keymap.set("x", "<leader>rp",
      [[:s/\<update\>\|\<select\>\|\<from\>\|\<where\>\|\<join\>\|\<on\>\|\<as\>\|\<left join\>\|\<inner join\>\|\<group by\>\|\<order by\>\|\<distinct\>\|\<top\>\|\<like\>\|\<begin\>\|\<trans\>\|\<transaction\>\|\<commit\>\|\<rollback\>\|\<declare\>\|\<set\>/\U&/ge<cr>]],
      { buffer = true })
end)
