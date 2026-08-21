-- The C# stack: language server, completion, IDE glue, debugging.
--
-- Targets modern .NET (8/9/10+). .NET Framework debugging stays in Visual
-- Studio: netcoredbg does not handle Framework processes reliably, and vsdbg is
-- license-restricted to VS and VS Code. Everything else here (navigation,
-- completion, rename, references, tests) still works on Framework projects.

return {
   -- The C# language server: Microsoft's Roslyn, the same analysis engine
   -- Visual Studio uses. OmniSharp is in maintenance mode and is not used.
   {
      "seblyng/roslyn.nvim",
      ft = "cs",
      opts = {},
   },

   -- Completion. Replaces the asyncomplete stack from _vimrc.plug.
   -- friendly-snippets replaces honza/vim-snippets, which sat inert for years
   -- because no snippet engine was ever installed alongside it.
   {
      "saghen/blink.cmp",
      version = "1.*",
      event = { "InsertEnter", "CmdlineEnter" },
      dependencies = { "rafamadriz/friendly-snippets" },
      opts = {
         keymap = { preset = "default" }, -- <C-y> accept, <C-n>/<C-p> cycle
         sources = { default = { "lsp", "path", "snippets", "buffer" } },
         completion = {
            documentation = { auto_show = true, auto_show_delay_ms = 200 },
         },
      },
   },

   -- Breadcrumbs: the "where am I" context line Visual Studio shows above the
   -- editor. CodeNav's other half is aerial (<F10>), already wired in nav.lua.
   {
      "SmiteshP/nvim-navic",
      lazy = true,
      init = function()
         vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("rc_navic", { clear = true }),
            callback = function(args)
               local client = vim.lsp.get_client_by_id(args.data.client_id)
               if client and client:supports_method("textDocument/documentSymbol") then
                  require("nvim-navic").attach(client, args.buf)
               end
            end,
         })
      end,
   },

   -- TODO/FIXME/HACK highlighting, plus project-wide pickers that Visual
   -- Studio's TODO highlighter cannot do.
   {
      "folke/todo-comments.nvim",
      dependencies = { "nvim-lua/plenary.nvim" },
      event = { "BufReadPost", "BufNewFile" },
      opts = {},
      keys = {
         { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "All TODOs in project" },
      },
   },

   -- The IDE glue: solution/csproj awareness, build/run/test, a Rider-style
   -- test runner, launchSettings.json profile support, user-secrets, EF helpers.
   -- This is the single plugin that most closes the "IDE feel" gap.
   {
      "GustavEikaas/easy-dotnet.nvim",
      dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
      ft = { "cs", "fsharp", "sln", "csproj" },
      cmd = { "Dotnet", "DotnetUI" },
      opts = {
         test_runner = { viewmode = "float" },

         -- easy-dotnet has grown its own Roslyn LSP layer, enabled by default.
         -- Leaving it on attaches a SECOND Roslyn client alongside roslyn.nvim,
         -- and both answer textDocument/completion with identical results, so
         -- every C# completion appears twice. Measured on a two-project
         -- solution: roslyn returned 5 items, easy_dotnet returned the same 5.
         --
         -- roslyn.nvim owns the language server (it handles multi-solution
         -- selection via :Roslyn target and source-generated files); this plugin
         -- stays what doc 04 wanted it for: build, run, test, launch profiles.
         lsp = { enabled = false },

         -- projx_lsp is a different thing and stays on: it serves .csproj/.sln
         -- files (package completion), which roslyn.nvim does not cover.
         projx_lsp = { enabled = true },
      },
   },

   -- Debugging.
   --
   -- KEY ASSIGNMENT IS PROVISIONAL. 04-csharp-ide-nvim.md specs VS-style
   -- function keys (<F5> continue, <F9> breakpoint, <F10> step over, <F11> step
   -- into), which collide head-on with <F9> undotree and <F10> aerial from doc
   -- 03. That collision is a real muscle-memory conflict in both directions, so
   -- it is deliberately left unresolved: these are on <leader>D... for now,
   -- which conflicts with nothing. <leader>d is NOT used because vim-jsonpath
   -- binds it buffer-locally in json files.
   {
      "mfussenegger/nvim-dap",
      dependencies = {
         "rcarriga/nvim-dap-ui",
         "nvim-neotest/nvim-nio",
         -- variable values inline next to the code while stopped at a
         -- breakpoint, the way Visual Studio shows them
         { "theHamsta/nvim-dap-virtual-text", opts = {} },
      },
      keys = {
         { "<leader>Dc", function() require("dap").continue() end, desc = "Debug: continue / start" },
         { "<leader>Db", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
         { "<leader>Do", function() require("dap").step_over() end, desc = "Debug: step over" },
         { "<leader>Di", function() require("dap").step_into() end, desc = "Debug: step into" },
         { "<leader>DO", function() require("dap").step_out() end, desc = "Debug: step out" },
         { "<leader>Dr", function() require("dap").repl.toggle() end, desc = "Debug: REPL" },
         { "<leader>Du", function() require("dapui").toggle() end, desc = "Debug: toggle UI" },
         { "<leader>Dt", function() require("dap").terminate() end, desc = "Debug: terminate" },
      },
      config = function()
         local dap, dapui = require("dap"), require("dapui")
         dapui.setup()

         dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
         dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
         dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

         dap.adapters.coreclr = {
            type = "executable",
            command = vim.fn.exepath("netcoredbg"),
            args = { "--interpreter=vscode" },
            -- required on Windows; without it the debuggee console detaches
            options = { detached = false },
         }

         dap.configurations.cs = {
            {
               type = "coreclr",
               name = "Launch DLL",
               request = "launch",
               program = function()
                  return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "\\bin\\Debug\\", "file")
               end,
            },
            {
               type = "coreclr",
               name = "Attach (pick process)",
               request = "attach",
               processId = function() return require("dap.utils").pick_process() end,
            },
         }
         -- Per-project .vscode/launch.json is read AUTOMATICALLY on
         -- dap.continue() (:h dap-providers). The old dap.ext.vscode.load_launchjs
         -- API is deprecated and deliberately not called.
      end,
   },

   -- csharpier formatting, on demand rather than on save (mirrors the old
   -- OmniSharp <leader>cf intent). Roslyn also honours .editorconfig analyzers.
   {
      "stevearc/conform.nvim",
      opts = function(_, opts)
         opts.formatters_by_ft = opts.formatters_by_ft or {}
         opts.formatters_by_ft.cs = { "csharpier" }
         return opts
      end,
      keys = {
         { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
            mode = { "n", "x" }, desc = "Format buffer / selection" },
      },
   },
}
