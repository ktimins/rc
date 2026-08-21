-- SQL against SQL Server (and anything else) from inside the editor.
--
-- vim-dadbod was ALREADY sitting commented out in _vimrc.plug, and the SQL
-- augroup plus the SQLUtilities plugin show real SQL work happens here.
-- 03-plugins.md section 8 calls it the most underrated suggestion on the page.
--
-- Connections live in g:dbs or in the UI's saved list; queries are executed
-- with <leader>S in a .sql buffer (dadbod's own mapping) or by :DB.

return {
   { "tpope/vim-dadbod", cmd = { "DB", "DBUI", "DBUIToggle" } },

   {
      "kristijanhusak/vim-dadbod-ui",
      dependencies = { "tpope/vim-dadbod" },
      cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
      init = function()
         -- keep saved queries in the repo-adjacent storage rather than scattering
         -- them next to whatever directory the editor happened to start in
         vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
         vim.g.db_ui_use_nerd_fonts = 1
         vim.g.db_ui_show_database_icon = 1
         -- execute on save is off: too easy to fire a destructive statement by
         -- reflex when :w is muscle memory
         vim.g.db_ui_execute_on_save = 0
      end,
      keys = {
         { "<leader>u", "<cmd>DBUIToggle<cr>", desc = "Database UI" },
      },
      -- NOTE: dadbod-ui installs its own buffer-local mappings in sql buffers:
      -- <leader>S executes the query, <leader>W saves it, <leader>E edits bind
      -- parameters. <leader>S therefore SHADOWS the global sum-numbers mapping
      -- inside sql buffers. That is the plugin's convention and worth keeping;
      -- summing numbers in a query buffer is not a thing anyone needs.
   },

   -- Table and column completion inside SQL buffers, fed by the live
   -- connection. Registered as a blink source rather than an omnifunc so it
   -- appears in the same popup as everything else.
   {
      "kristijanhusak/vim-dadbod-completion",
      dependencies = { "tpope/vim-dadbod" },
      ft = { "sql", "mysql", "plsql" },
   },

   {
      "saghen/blink.cmp",
      optional = true, -- only extends the spec in plugins/csharp.lua
      opts = function(_, opts)
         opts.sources = opts.sources or {}
         opts.sources.per_filetype = opts.sources.per_filetype or {}
         for _, ft in ipairs({ "sql", "mysql", "plsql" }) do
            opts.sources.per_filetype[ft] = { "dadbod", "snippets", "buffer" }
         end
         opts.sources.providers = opts.sources.providers or {}
         opts.sources.providers.dadbod = {
            name = "Dadbod",
            module = "vim_dadbod_completion.blink",
         }
         return opts
      end,
   },
}
