# 04: Neovim as a C# IDE

Goal: replicate the parts of Visual Studio (plus its extensions) that the user actually uses, in Neovim. Researched July 2026. Prerequisites: docs 01 through 03 implemented, .NET SDK on PATH (`dotnet --version` works), Neovim 0.12+ (required by the Roslyn plugin).

## 1. The headline: OmniSharp is over, Roslyn LSP is the way

The user last looked at this space when OmniSharp was the only option. The landscape changed: Microsoft's own Roslyn language server (the one behind VS Code's C# extension, giving the same analysis engine Visual Studio uses) is now the recommended C# LSP for Neovim, and OmniSharp is in maintenance mode. The community-standard integration is [seblyng/roslyn.nvim](https://github.com/seblyng/roslyn.nvim), which handles the server's non-standard LSP behaviors, multi-solution selection (`:Roslyn target` to pick a `.sln`), and source-generated files. Server install is via Mason, two routes: add the community registry `github:Crashdummyy/mason-registry` and install `roslyn` (tracks the VS Code extension's builds), or `:MasonInstall roslyn-language-server` from the official registry (nuget-sourced, can lag behind the VS Code version). The spec below wires the community registry.

On top of the LSP, [GustavEikaas/easy-dotnet.nvim](https://github.com/GustavEikaas/easy-dotnet.nvim) is the "IDE glue" layer, built by a Rider refugee: solution/csproj awareness, build/run/test/restore commands, a Rider-style test runner (VSTest and Microsoft Testing Platform), launch-profile support (`Properties/launchSettings.json`), user-secrets editing, EF helpers, and an `:Dotnet outdated` view. It is the single plugin that most closes the "IDE feel" gap.

## 2. VS extension → Neovim mapping

| Visual Studio piece | Neovim equivalent | Notes |
|---|---|---|
| C# language service (IntelliSense, go-to, rename, find refs, code fixes) | roslyn.nvim + blink.cmp | Same Roslyn analyzers as VS. Code actions via `vim.lsp.buf.code_action`. |
| CodeNav (member outline) | aerial.nvim (`<F10>`, already wired in doc 03) + nvim-navic breadcrumbs in lualine + `<leader>fs` Telescope symbol search | Aerial is the sidebar; navic is the "where am I" breadcrumb VS shows at the top of the editor. |
| Git Diff Margin | gitsigns.nvim (doc 03) | Signs in the gutter, `<leader>hp` inline hunk preview, staging/reset from the buffer, line blame. Strictly more capable than the VS extension. |
| Indent Guides | snacks.nvim indent (doc 03) | Adds current-scope highlighting VS does not have. |
| MetaOutput (structured, filterable build/run output) | overseer.nvim task output + quickfix, plus easy-dotnet build errors into quickfix | Closest match, see section 6. Nothing in the nvim ecosystem replicates MetaOutput's full "log hub" (media, HTML, multi-source filtering); build/run output structuring is well covered, arbitrary log-file dashboards are not. |
| Rainbow Braces | rainbow-delimiters.nvim (doc 03) | Treesitter-based, language-aware. |
| TODO highlighter | todo-comments.nvim | Highlights TODO/FIXME/HACK/etc., plus `:TodoTelescope`/`:TodoQuickFix` to list every TODO across the solution, which VS's highlighter cannot do. |
| Smart Command Line Arguments | launchSettings.json profiles via easy-dotnet, or named nvim-dap configurations | See section 5. Honest gap: no checkbox toggle UI exists; the equivalent workflow is multiple named profiles. |
| Debugger | nvim-dap + nvim-dap-ui + netcoredbg | Section 4, including Windows-specific gotchas. |
| Test Explorer | easy-dotnet test runner (or neotest + neotest-dotnet) | Rider-style tree, run/filter failed, icons per state. |
| Solution Explorer | neo-tree (doc 03) + easy-dotnet project view + `:Roslyn target` for solution switching | |
| Format on save / editorconfig | conform.nvim + csharpier | Roslyn LSP also respects `.editorconfig` analyzers. |

## 3. Plugin specs

`lua/plugins/csharp.lua`:

```lua
return {
  -- Mason for server/debugger binaries, with the community registry that
  -- carries the Roslyn server builds
  { "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    } },

  -- Roslyn LSP
  { "seblyng/roslyn.nvim", ft = { "cs" }, opts = {} },

  -- completion
  { "saghen/blink.cmp", version = "1.*",
    dependencies = { "rafamadriz/friendly-snippets" }, -- vim-snippets replacement (doc 03)
    opts = {
      keymap = { preset = "default" }, -- <C-y> accept, <C-n>/<C-p> navigate
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    } },

  -- breadcrumbs (CodeNav's top-of-editor context line)
  { "SmiteshP/nvim-navic",
    config = function()
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client.server_capabilities.documentSymbolProvider then
            require("nvim-navic").attach(client, args.buf)
          end
        end,
      })
    end },

  -- TODO/FIXME/HACK highlighting and pickers
  { "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
    keys = {
      { "<leader>td", "<cmd>TodoTelescope<cr>", desc = "All TODOs in project" },
    } },

  -- the IDE glue: build/run/test/secrets/outdated/launch profiles
  -- NOTE FOR IMPLEMENTER: this plugin's config API moves quickly (terminal
  -- handling and dap helpers have both been reworked). Treat the opts below
  -- as the stable core and follow the CURRENT README sections "Advanced
  -- configurations" and "Nvim-dap configuration" for anything beyond it.
  { "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
    opts = {
      test_runner = { viewmode = "float" },
    } },

  -- debugging
  { "mfussenegger/nvim-dap",
    dependencies = { "rcarriga/nvim-dap-ui", "nvim-neotest/nvim-nio" },
    keys = {
      { "<F5>",  function() require("dap").continue() end,          desc = "Debug: continue/start" },
      { "<F10>", function() require("dap").step_over() end,         desc = "Debug: step over", mode = "n" },
      { "<F11>", function() require("dap").step_into() end,         desc = "Debug: step into" },
      { "<S-F11>", function() require("dap").step_out() end,        desc = "Debug: step out" },
      { "<F9>",  function() require("dap").toggle_breakpoint() end, desc = "Debug: breakpoint" },
    },
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dapui.setup()
      dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end

      dap.adapters.coreclr = {
        type = "executable",
        command = vim.fn.exepath("netcoredbg"),
        args = { "--interpreter=vscode" },
        options = { detached = false }, -- required on Windows
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
      -- Per-project .vscode/launch.json is read AUTOMATICALLY by nvim-dap on
      -- dap.continue() (:h dap-providers). Do not call the old
      -- dap.ext.vscode.load_launchjs API; it is deprecated.
      -- Optional upgrade: easy-dotnet ships dap helpers (debug-DLL resolution,
      -- rebuild-before-launch) that replace the input() prompt above; wire
      -- them per its current README section "Nvim-dap configuration".
    end },

  -- csharpier formatting
  { "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.cs = { "csharpier" }
      return opts
    end },
}
```

> **Correction (implemented 2026-08-21).** easy-dotnet now ships its own Roslyn LSP layer, `lsp = { enabled = true }` by default, which this doc predates. Left on, it attaches a SECOND Roslyn client alongside roslyn.nvim and both answer `textDocument/completion` with identical results, so every C# completion appears twice. Measured on a two-project solution: `roslyn` returned 5 items, `easy_dotnet` returned the same 5.
>
> The as-built config sets `lsp = { enabled = false }` so roslyn.nvim owns the language server, and keeps `projx_lsp = { enabled = true }`, which is a different feature serving `.csproj`/`.sln` files. The alternative is to flip it and let easy-dotnet own Roslyn, which additionally brings roslynator analyzers, Razor support and codelens refresh; pick one, never both.
>
> Two smaller notes. The **official Mason registry now carries `roslyn-language-server`**, so the community registry is optional, but roslyn.nvim's own README still recommends `github:Crashdummyy/mason-registry` because the nuget-sourced package lags the VS Code build; the as-built config lists both registries. And **`c_sharp` has no treesitter `indents.scm`**, which matters because doc 03's treesitter setup must not hand C# its `indentexpr`; doing so leaves C# with no auto-indent at all. Neovim's bundled `GetCSIndent` handles it correctly.

Note on `<F9>/<F10>`: these collide with the undotree/aerial toggles from doc 03. Decide one owner; the recommendation is to keep `<F9>/<F10>` for undotree/aerial (existing muscle memory) and move DAP stepping to `<leader>d...` mappings instead. The spec above shows the VS-style function keys because that is what VS muscle memory expects; the implementer must pick one and delete the other, not keep both.

LSP keymaps: Neovim has global defaults (`grn` rename, `gra` code action, `grr` references, `gri` implementation, `gO` document symbols, `K` hover, `<C-]>` definition via tagfunc). `gd` is NOT an LSP mapping by default (it stays the lexical "goto local declaration"). Add VS-style extras on LspAttach: `gd` → `vim.lsp.buf.definition`, `<F2>` → `vim.lsp.buf.rename` (matches the old vim-lsp `<f2>` mapping), `<F12>` → definition, `<C-F12>` → implementation.

Install steps after specs are in place: `:Mason` → install `roslyn`, `netcoredbg`, `csharpier`; `:TSInstall c_sharp` (done in doc 03); open a `.cs` file inside a solution, run `:Roslyn target` if multiple `.sln` files exist, wait for the "Roslyn project initialization complete" notification, then verify `gd`/`grr`/`K`.

## 4. Debugging: Windows gotchas (all researched, all real)

- `shellslash` MUST be off. With `shellslash` on, Neovim hands forward-slash paths to netcoredbg and breakpoints get silently rejected. Doc 02 already sets `vim.o.shellslash = false` and doc 02's bug list item 12 removes the old vimrc line that turned it on. If breakpoints ever show as hollow circles that never bind, check `:set shellslash?` first.
- `options = { detached = false }` on the adapter is required on Windows; without it the debuggee console detaches and the session misbehaves.
- netcoredbg comes from Mason (`:MasonInstall netcoredbg`). It debugs .NET Core / modern .NET. It does NOT debug classic .NET Framework 4.x processes reliably (Framework debugging is proprietary vsdbg territory; vsdbg is license-restricted to VS/VS Code). If the work project is .NET Framework, debugging stays in Visual Studio; everything else in this doc (LSP, navigation, tests via `dotnet test` where the project supports it) still works.
- Build before debugging: the `program` must point at the current Debug build DLL. easy-dotnet's dap helpers can resolve the DLL and rebuild automatically before launch (see the spec note); the plain `input()` prompt config does not.

## 5. Smart Command Line Arguments: the honest mapping

What the VS extension does: a tool window with per-project argument lines, each with a checkbox; checked lines are concatenated and applied on F5; stored in JSON next to the project/solution. Nothing in the Neovim ecosystem replicates the checkbox UI. The equivalent workflows, in order of recommendation:

1. **launchSettings.json profiles** (the .NET-native mechanism): define multiple profiles in `Properties/launchSettings.json`, each with its own `commandLineArgs`; easy-dotnet's run/debug integration prompts for profile selection. Different argument combinations = different named profiles. This file is respected by VS too, so both editors share one source of truth.
2. **Named dap configurations**: each preset argument set becomes one entry in `dap.configurations.cs` with an `args = { ... }` list; `<F5>` (dap.continue) presents the list to pick from. Per-project presets live in `.vscode/launch.json`, which nvim-dap reads automatically on `dap.continue()` (`:h dap-providers`), keeping them out of the shared config.
3. **Ad-hoc prompt**: a config entry with `args = function() return vim.split(vim.fn.input("Args: "), " ") end` for one-off runs.

## 6. MetaOutput: build/run output story

What MetaOutput gives VS: a structured, filterable output window that separates build output, warnings, and errors per project. The Neovim equivalents:

- **Build**: `:Dotnet build` (easy-dotnet) surfaces errors; for a general task UI add [stevearc/overseer.nvim](https://github.com/stevearc/overseer.nvim) with `{ "stevearc/overseer.nvim", opts = {} }`, define a `dotnet build` template, and get a task list with per-task output windows and quickfix integration. Errors/warnings land in quickfix (`:copen`), which is filterable (`:Cfilter` ships with Neovim: `:packadd cfilter` then `:Cfilter /error/`).
- **Run output**: easy-dotnet's `terminal` hook above opens runs in a split terminal; toggleterm.nvim is an optional upgrade for persistent toggleable terminals. Remember from doc 01: terminal-mode typing is NOT Colemak-translated; flip the hardware layer when typing into the app's stdin.
- **Gap statement**: MetaOutput's log-file dashboard features (multi-source hubs, media rendering, per-source visibility toggles) have no Neovim equivalent. If that specific capability matters day-to-day, it stays a VS-only convenience.

## 7. Suggested phased adoption

1. LSP only (roslyn.nvim + blink.cmp + Mason): daily-drive navigation/completion/rename on a real solution for a week. This alone is most of "IDE".
2. Add easy-dotnet (build/run/test runner + launch profiles).
3. Add DAP + netcoredbg, verify a breakpoint binds and hits on a console app, then on the real work project (subject to the .NET Framework caveat).
4. Add polish: todo-comments, navic breadcrumbs, overseer, csharpier-on-demand (`:lua require("conform").format()` or a `<leader>cf` map, mirroring the old OmniSharp `<Leader>cf` intent).

## 8. Verification checklist

Open a real solution: `:LspInfo` shows roslyn attached; `gd` jumps into a referenced project's file; `grr` lists references across projects; `grn` renames across the solution; `K` shows XML-doc hover; diagnostics appear as virtual text/signs and `:Telescope diagnostics` lists them solution-wide; `:Dotnet testrunner` discovers and runs tests with pass/fail icons; `<F9>`-equivalent sets a breakpoint that binds (filled circle) and `<F5>` stops on it with dap-ui panels showing locals and stack; `:TodoTelescope` lists TODOs across the solution; aerial (`<F10>`) shows the class/member tree of the current file; the lualine breadcrumb updates as the cursor moves between members.

## Sources

- roslyn.nvim: https://github.com/seblyng/roslyn.nvim and setup discussion https://github.com/neovim/neovim/discussions/36508 and https://gist.github.com/navazjm/de072b46e4a203184dd647551502d6c8
- OmniSharp vs Roslyn state of the world: https://programmingheadache.com/2025/10/17/you-ve-been-using-wrong-lsp/ and https://silvercircle.github.io/LSP/roslyn/
- easy-dotnet.nvim: https://github.com/GustavEikaas/easy-dotnet.nvim
- nvim-dap + netcoredbg Windows issues (shellslash, detached): https://github.com/mfussenegger/nvim-dap/discussions/1156 and https://github.com/mfussenegger/nvim-dap/discussions/1369 and walkthrough https://aaronbos.dev/posts/debugging-csharp-neovim-nvim-dap
- Smart Command Line Arguments (what is being replicated): https://github.com/MBulli/SmartCommandlineArgs
- MetaOutput (what is being replicated): https://github.com/viacheslav-lozinskyi/MetaOutput
