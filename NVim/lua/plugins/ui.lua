-- Colorscheme, statusline, tabline, and the snacks module bundle.

return {
   -- Colorscheme. Mirrors the old _vimrc try/catch cascade: preferred scheme
   -- first, fall back if it is missing rather than dying with an error.
   {
      "folke/tokyonight.nvim",
      lazy = false,
      priority = 1000,
      config = function()
         for _, scheme in ipairs({ "anderson", "tokyonight-moon", "habamax" }) do
            if pcall(vim.cmd.colorscheme, scheme) then break end
         end
      end,
   },

   -- The old gVim look, kept reachable via :colorscheme anderson.
   { "tlhr/anderson.vim", lazy = false, priority = 900 },

   {
      "nvim-lualine/lualine.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      opts = function()
         -- Colemak translation indicator. iminsert is per-buffer and CTRL-^
         -- toggles it, so showing the state matters: CMK means typed text is
         -- being translated, QWE means it is passing through raw.
         local function layer()
            return vim.bo.iminsert == 1 and "CMK" or "QWE"
         end

         return {
            options = { globalstatus = false },
            sections = {
               -- navic breadcrumbs get appended to lualine_c in doc 04
               lualine_c = { "filename" },
               lualine_x = { layer, "encoding", "fileformat", "filetype" },
            },
         }
      end,
   },

   {
      "akinsho/bufferline.nvim",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      event = "VeryLazy",
      opts = {},
   },

   -- Six small modules that between them replace five old plugins:
   -- startify, indentline, comfortable-motion, goyo, and the never-defined
   -- :Bclose. The input module also makes vim.ui.input a real insert-mode
   -- buffer, which is what lets the Colemak language mappings apply inside
   -- prompts like <leader>ts and :FindAll.
   {
      "folke/snacks.nvim",
      priority = 1000,
      lazy = false,
      opts = {
         input = {},
         indent = {},
         scroll = {},
         zen = {},
         bufdelete = {},
         dashboard = {
            preset = {
               keys = {
                  { icon = "v", key = "v", desc = "vimrc (gVim)",
                    action = function() vim.cmd.edit(Machine.rc_repo .. "/Vim/vimrc/_vimrc") end },
                  { icon = "b", key = "b", desc = "nvim init",
                    action = function() vim.cmd.edit(vim.fn.stdpath("config") .. "/init.lua") end },
                  { icon = "p", key = "p", desc = "PS profile",
                    action = function() vim.cmd.edit(Machine.rc_repo .. "/Windows/Powershell/Microsoft.PowerShell_profile.ps1") end },
                  { icon = "m", key = "m", desc = "PS profile (machine)",
                    action = function() vim.cmd.edit(Machine.rc_repo .. "/Windows/Microsoft.Powershell_profile.ps1") end },
                  { icon = "r", key = "r", desc = "Recent files",
                    action = ":lua Snacks.dashboard.pick('oldfiles')" },
                  { icon = "q", key = "q", desc = "Quit", action = ":qa" },
               },
            },
         },
      },
      keys = {
         -- the working replacement for the old <leader>bc :Bclose mapping,
         -- which pointed at a command that was never defined
         { "<leader>bc", function() Snacks.bufdelete() end, desc = "Close buffer, keep window layout" },
         { "<leader>z", function() Snacks.zen() end, desc = "Zen mode (goyo replacement)" },
      },
   },
}
