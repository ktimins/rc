-- lazy.nvim bootstrap.
--
-- Chosen over Neovim 0.12's built-in vim.pack deliberately: vim.pack covers
-- add/del/get/update and nothing else, while this config leans on lazy's
-- lazy-loading triggers (keys/ft/cmd), dependency resolution, and above all the
-- lockfile, which is what keeps WORK, THEIA and ARES on identical plugin
-- versions. lazy-lock.json belongs in the repo.

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
   local out = vim.fn.system({
      "git", "clone", "--filter=blob:none", "--branch=stable",
      "https://github.com/folke/lazy.nvim.git", lazypath,
   })
   if vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
         { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
         { out, "WarningMsg" },
         { "\nPress any key to exit..." },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
   end
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
   spec = { { import = "plugins" } },
   install = { colorscheme = { "tokyonight", "habamax" } },
   -- no background update checks; updates happen when :Lazy is opened on purpose
   checker = { enabled = false },
   change_detection = { notify = false },
})
