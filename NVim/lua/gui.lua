-- GUI settings. Only Neovide is supported; it is the gVim replacement.
--
-- Terminal Neovim uses the same config and needs nothing here. Things that do
-- NOT port from gVim and are deliberately absent: 'guioptions' scrollbars,
-- the menu bar and the toolbar. Neovide has none of them by design.

if not vim.g.neovide then
   return
end

-- Point size, and the one knob worth turning here.
--
-- gVim used 10. This is 9 because that is where the editor was actually being
-- used: neovide_scale_factor resets to 1.0 on every launch, so a <C--> press
-- never persisted and had to be repeated each session. Baking the size in
-- removes that. Each <C-->/<C-=> press is a factor of 1.1, so 9 here is
-- roughly one press below the old default; drop to 8 for two.
--
-- Changing the size is preferable to shipping a scale factor below 1.0: the
-- font is rendered at its real size rather than resampled, so it stays crisp.
local FONT_SIZE = 9

-- Matches the gVim cascade's first choice. Comma-separated entries are
-- Neovide's fallback chain for glyphs the primary font lacks.
--
-- NOTE: _vimrc's second rung, HackGenNerd_Console, is not installed on this
-- machine, so that fallback has been dead there for some time. Anonymice is
-- the Nerd Font build of Anonymous Pro, which _vimrc listed further down.
-- Consolas keeps the +1 it had in _vimrc; it reads smaller at a given size.
vim.o.guifont = table.concat({
   ("CaskaydiaCove Nerd Font Mono:h%d"):format(FONT_SIZE),
   ("AnonymicePro Nerd Font Mono:h%d"):format(FONT_SIZE),
   ("Consolas:h%d"):format(FONT_SIZE + 1),
}, ",")


vim.g.neovide_cursor_animation_length = 0.05
vim.g.neovide_scroll_animation_length = 0.2
vim.g.neovide_remember_window_size = true
vim.g.neovide_hide_mouse_when_typing = true -- the old 'mousehide' behavior

-- Font size, replacing the commented-out FontSizePlus/FontSizeMinus functions
-- in _vimrc (which manipulated the 'guifont' string with regexes).
--
-- neovide_scale_factor starts unset, so the arithmetic must not assume a
-- number: doc 03's snippet multiplies it directly and errors on first use.
local function rescale(factor)
   vim.g.neovide_scale_factor = (vim.g.neovide_scale_factor or 1.0) * factor
end

vim.keymap.set("n", "<C-=>", function() rescale(1.1) end, { desc = "GUI: larger font" })
vim.keymap.set("n", "<C-->", function() rescale(1 / 1.1) end, { desc = "GUI: smaller font" })
vim.keymap.set("n", "<C-0>", function()
   vim.g.neovide_scale_factor = 1.0
end, { desc = "GUI: reset font size" })
