-- Finding things: fuzzy picker, file tree, symbol outline.
-- The F-key assignments preserve the old muscle memory exactly.

return {
   -- Replaces bufexplorer (<F7>) and finally scratches the ctrlp/fzf itch that
   -- sat commented out in _vimrc.plug for years.
   {
      "nvim-telescope/telescope.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      cmd = "Telescope",
      keys = {
         { "<F7>", "<cmd>Telescope buffers<cr>", desc = "Buffers (was bufexplorer)" },
         { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
         { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep (ripgrep)" },
         { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
         { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      },
      opts = {},
   },

   -- Replaces nerdtree + nerdtree-git-plugin; git status icons are built in.
   {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
         "nvim-lua/plenary.nvim",
         "nvim-tree/nvim-web-devicons",
         "MunifTanjim/nui.nvim",
      },
      cmd = "Neotree",
      keys = {
         { "<F8>", "<cmd>Neotree toggle<cr>", desc = "File tree" },
         { "<C-n>", "<cmd>Neotree toggle<cr>", desc = "File tree" },
      },
      opts = { filesystem = { follow_current_file = { enabled = true } } },
   },

   -- Replaces vista.vim (<F10>). vista defaulted to a ctags executive with no
   -- ctags.exe ever installed, so <F10> has been failing for most filetypes;
   -- aerial uses LSP and treesitter instead and needs no external binary.
   {
      "stevearc/aerial.nvim",
      dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
      cmd = { "AerialToggle", "AerialOpen" },
      keys = { { "<F10>", "<cmd>AerialToggle!<cr>", desc = "Symbol outline (was vista)" } },
      opts = {
         backends = { "lsp", "treesitter", "markdown" },
         -- Aerial's default filter_kind lists only 8 kinds and omits Property,
         -- Field, Variable, Constant and EnumMember, which hides most of a C#
         -- type's surface. false means "all symbols". Both backends already
         -- produce the data: queries/c_sharp/aerial.scm captures
         -- property_declaration and field_declaration, and Roslyn reports them
         -- too. Only the filter was dropping them.
         filter_kind = false,
      },
   },
}
