-- Git integration.

return {
   { "tpope/vim-fugitive", cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Gclog", "GBrowse" } },
   { "tpope/vim-rhubarb", dependencies = { "tpope/vim-fugitive" } },
   { "junegunn/gv.vim", cmd = "GV", dependencies = { "tpope/vim-fugitive" } },

   -- Side-by-side diffs for any revision, a file history browser, and a
   -- three-pane merge tool. The strongest git upgrade beyond gitsigns and
   -- fugitive for someone used to Visual Studio's diff viewer.
   --
   -- <leader>v for "view"; <leader>d and <leader>g are taken buffer-locally by
   -- vim-jsonpath in json files, and <leader>D is the debugger.
   {
      "sindrets/diffview.nvim",
      cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
      opts = {},
      keys = {
         { "<leader>vo", "<cmd>DiffviewOpen<cr>", desc = "Open diff view" },
         { "<leader>vc", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
         { "<leader>vh", "<cmd>DiffviewFileHistory<cr>", desc = "Repo file history" },
         { "<leader>vf", "<cmd>DiffviewFileHistory %<cr>", desc = "This file's history" },
      },
   },

   -- Replaces vim-gitgutter, which was wired in a degraded state: the old
   -- config set gitgutter_map_keys=0, disabling every hunk mapping without
   -- providing replacements, so only the gutter signs were ever reachable.
   -- Hunk navigation, staging, reset, preview and blame are all mapped here.
   -- Also answers the "Git Diff Margin" Visual Studio extension.
   {
      "lewis6991/gitsigns.nvim",
      event = { "BufReadPre", "BufNewFile" },
      opts = {
         current_line_blame = false, -- toggle with :Gitsigns toggle_current_line_blame
         on_attach = function(bufnr)
            local gs = require("gitsigns")
            local function map(mode, lhs, rhs, desc)
               vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
            end

            map("n", "]c", function() gs.nav_hunk("next") end, "Next hunk")
            map("n", "[c", function() gs.nav_hunk("prev") end, "Previous hunk")
            map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
            map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
            map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
            map("n", "<leader>hb", gs.blame_line, "Blame line")
         end,
      },
   },
}
