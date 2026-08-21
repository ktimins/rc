-- Task running, search/replace, HTTP requests, quickfix, and keymap discovery.

return {
   -- Build/run/test output as a task list with per-task output windows and
   -- quickfix integration. 04-csharp-ide-nvim.md section 6 names this as the
   -- closest answer to Visual Studio's MetaOutput extension.
   --
   -- <leader>o for "overseer". MSBuild's diagnostic format is not in Neovim's
   -- default 'errorformat', so the template sets it explicitly; without that
   -- the build runs but quickfix stays empty, which looks like a clean build.
   --
   -- CAVEAT, and the reason autocmds.lua also sets a plain makeprg for cs:
   -- the on_output_quickfix component could NOT be verified here. Under
   -- --headless the task runs and exits correctly, but overseer's captured
   -- output is empty apart from "[Process exited 1]", so nothing reaches the
   -- errorformat. That is consistent with a terminal buffer not rendering
   -- without a UI, and it very likely works interactively, but it is unproven.
   -- `:make` uses the same errorformat, depends on no plugin, and IS verified
   -- against real dotnet build output. If <leader>ob leaves quickfix empty,
   -- that is this caveat, and :make is the fallback.
   {
      "stevearc/overseer.nvim",
      cmd = { "OverseerRun", "OverseerToggle", "OverseerQuickAction", "OverseerBuild" },
      keys = {
         { "<leader>oo", "<cmd>OverseerToggle<cr>", desc = "Task list" },
         { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Run a task" },
         { "<leader>oq", "<cmd>OverseerQuickAction<cr>", desc = "Task quick action" },
         { "<leader>ob", "<cmd>OverseerBuild<cr>", desc = "Build a task" },
      },
      opts = {
         task_list = { direction = "bottom", min_height = 12 },
      },
      config = function(_, opts)
         local overseer = require("overseer")
         overseer.setup(opts)

         -- Ships with Vim and Neovim but is not loaded by default. Gives
         -- :Cfilter /pattern/ to narrow a build's errors, which is the closest
         -- thing to MetaOutput's per-source filtering.
         pcall(vim.cmd.packadd, "cfilter")

         -- error CS1002: ; expected  ->  file(line,col): severity CSnnnn: text
         -- The trailing [project.csproj] MSBuild appends is swallowed by %m.
         local msbuild_efm = table.concat({
            [[%f(%l\,%c): %trror %m]],
            [[%f(%l\,%c): %tarning %m]],
            [[%f(%l): %trror %m]],
            [[%f(%l): %tarning %m]],
         }, ",")

         for _, spec in ipairs({
            { name = "dotnet build", args = { "build" } },
            { name = "dotnet test", args = { "test" } },
            { name = "dotnet run", args = { "run" } },
         }) do
            overseer.register_template({
               name = spec.name,
               builder = function()
                  return {
                     cmd = { "dotnet" },
                     args = spec.args,
                     components = {
                        { "on_output_quickfix", errorformat = msbuild_efm, open = false },
                        "default",
                     },
                  }
               end,
               condition = { filetype = { "cs", "sln", "csproj" } },
            })
         end
      end,
   },

   -- Self-documentation for the leader map set. This config grew organically
   -- from a 25-year-old vimrc and the plugin inventory in doc 03 found several
   -- mappings that had been dead for years without anyone noticing; a menu
   -- makes forgotten bindings discoverable instead.
   {
      "folke/which-key.nvim",
      event = "VeryLazy",
      opts = {
         preset = "helix",
         spec = {
            { "<leader>b", group = "buffers" },
            { "<leader>c", group = "cwd / wrap / format" },
            { "<leader>D", group = "debug" },
            { "<leader>f", group = "find" },
            { "<leader>h", group = "git hunks" },
            { "<leader>k", group = "http requests" },
            { "<leader>l", group = "lists (trouble)" },
            { "<leader>o", group = "tasks (overseer)" },
            { "<leader>q", group = "quit / session" },
            { "<leader>r", group = "replace" },
            { "<leader>s", group = "spelling" },
            { "<leader>t", group = "tabstops / todo" },
            { "<leader>v", group = "diff view" },
         },
      },
      keys = {
         { "<leader>?", function() require("which-key").show({ global = false }) end,
            desc = "Buffer-local keymaps" },
      },
   },

   -- Project-wide find and replace over ripgrep, with a live preview of every
   -- match before applying. The Ctrl+Shift+H equivalent; the built-in
   -- alternative (:grep then :cfdo) works but shows you nothing first.
   {
      "MagicDuck/grug-far.nvim",
      cmd = "GrugFar",
      opts = {},
      keys = {
         { "<leader>rr", function() require("grug-far").open() end, desc = "Find and replace" },
         { "<leader>rw", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } }) end,
            desc = "Replace word under cursor" },
         { "<leader>rf", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") } }) end,
            desc = "Replace in current file" },
         { "<leader>rs", function() require("grug-far").with_visual_selection() end,
            mode = "x", desc = "Replace selection" },
      },
   },

   -- An in-editor Postman for the request/response loop. The .http format is
   -- the same one Visual Studio 2022's built-in editor and VS Code's REST
   -- Client use, so collections live diffable in the repo and stay shareable
   -- with colleagues who never leave VS.
   --
   -- <leader>k rather than <leader>r: grug-far owns that, and kulala's mappings
   -- are buffer-local to http files where the two would otherwise collide.
   {
      "mistweaverco/kulala.nvim",
      ft = { "http", "rest" },
      opts = {},
      keys = {
         { "<leader>ks", function() require("kulala").run() end, desc = "Send request" },
         { "<leader>ka", function() require("kulala").run_all() end, desc = "Send all requests" },
         { "<leader>kt", function() require("kulala").toggle_view() end, desc = "Toggle body/headers" },
         { "<leader>kn", function() require("kulala").jump_next() end, desc = "Next request" },
         { "<leader>kp", function() require("kulala").jump_prev() end, desc = "Previous request" },
         { "<leader>kc", function() require("kulala").copy() end, desc = "Copy as curl" },
         { "<leader>ke", function() require("kulala").set_selected_env() end, desc = "Select environment" },
      },
   },

   -- Quickfix with a floating preview of each entry and fuzzy filtering.
   -- Upgrades the build-errors and find-references workflows directly; needs no
   -- mappings, it takes over the quickfix window when one opens.
   { "kevinhwang91/nvim-bqf", ft = "qf", opts = {} },
}
