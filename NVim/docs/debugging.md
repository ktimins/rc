# Debugging

Modern .NET only (8, 9, 10 and later), through netcoredbg.

**.NET Framework debugging stays in Visual Studio.** netcoredbg does not handle Framework processes reliably, and Microsoft's vsdbg is license-restricted to VS and VS Code. Everything else about Framework projects still works here: editing, navigation, completion, references, rename.

## Keys

These bindings are **provisional**. The Visual Studio muscle memory (F5 continue, F9 breakpoint, F10 step over, F11 step into) collides head-on with `<F9>` undotree and `<F10>` aerial from the editor side. That decision is deliberately unmade, so debugging sits on `<leader>D` where it conflicts with nothing.

| Key | Does |
|---|---|
| `,Db` | Toggle a breakpoint on this line |
| `,Dc` | Start debugging, or continue |
| `,Do` | Step over |
| `,Di` | Step into |
| `,DO` | Step out |
| `,Du` | Toggle the debugger UI |
| `,Dr` | Toggle the REPL |
| `,Dt` | Terminate the session |

## A session, start to finish

1. **Build first.** The debugger runs the compiled DLL, so it must be current. `:make` or `,or` then `dotnet build`
2. Put the cursor on the line you care about and press `,Db`. A breakpoint marker appears in the gutter
3. `,Dc` to start. You will be asked which configuration:
   - **Launch DLL** prompts for the DLL path, defaulting to `bin\Debug\`
   - **Attach** lets you pick a running process
   - **easy-dotnet** resolves the DLL from the project automatically, which is usually the one you want
4. Execution stops at the breakpoint and the UI opens: scopes, watches, call stack, breakpoints
5. Step with `,Do` / `,Di` / `,DO`, continue with `,Dc`
6. `,Dt` to stop

While stopped, variable values appear **inline next to the code**, the way Visual Studio shows them.

## The UI panels

`,Du` toggles them.

| Panel | Shows |
|---|---|
| Scopes | Locals and arguments in the current frame |
| Watches | Expressions you add |
| Stack | The call stack; click a frame to jump there |
| Breakpoints | Everything set, across files |
| Console | Program output, and the REPL |

In the scopes panel, `<CR>` expands an object. In the REPL you can evaluate expressions against the stopped process.

## Per-project configurations

nvim-dap reads `.vscode/launch.json` automatically when you start a session. That means launch configurations are shared with anyone on the team using VS Code, and stay out of this config.

`launchSettings.json` profiles are the other route, and Visual Studio reads those too, so a profile per argument set is the one source of truth both editors honour.

## When breakpoints do not bind

A breakpoint that shows as hollow and never hits, rather than erroring, has a short list of causes:

1. **The DLL is stale.** Rebuild. This is by far the most common cause
2. **`'shellslash'` is on.** It must be off, or Neovim hands forward-slash paths to netcoredbg and it silently rejects them. Check with `:set shellslash?`, expect `noshellslash`. This config sets it off and a test asserts it
3. **It is a .NET Framework project.** See the top of this page
4. **The build is Release.** Optimized builds do not map cleanly to source lines. Build Debug

## Verifying the setup

Confirm the pieces are wired without starting a real session:

```sh
nvim --headless -c "luafile $LOCALAPPDATA/nvim/tests/csharp_spec.lua" +qa!
```

That checks netcoredbg is installed and resolvable, the adapter carries the Windows-specific `detached = false` setting, and both launch and attach configurations exist.

A real breakpoint was verified during setup: it bound and stopped at the expected line with `reason=breakpoint`.
