# AGENTS.md

Personal Neovim config built on the [LazyVim](https://lazyvim.org) starter. Not an application — there are no tests, CI, or build steps. Windows-only; in-code comments and UI labels are in Spanish.

## Layout & load order

- `init.lua` — entrypoint. Only `require("config.lazy")` plus `vim.env.CC = "gcc"` (needed on this Windows setup; do not drop).
- `lua/config/` — core overrides auto-loaded by LazyVim: `options.lua`, `keymaps.lua`, `autocmds.lua`.
- `lua/plugins/` — every `.lua` file (recursively, incl. `langs/`) is auto-imported by lazy.nvim as a plugin spec. Adding a file = adding a spec; no registration needed.
- `lua/plugins/example.lua` is a dead stub (`if true then return {} end`) that silently disables its body — don't add real specs there.
- `lazy.lua` spec imports LazyVim + extras `ai.copilot-chat`, `lang.dart` and `lang.dotnet`, then `plugins`. Enable/disable extras here.
- `lazy-lock.json` is the plugin lockfile; commit it. Plugin ops go through `:Lazy`.

## Verification

- Lua formatter is `stylua` (config in `stylua.toml`: 2-space indent, 120 col). Use `stylua --check .` to verify, `stylua .` to format.
- Sanity-check a change by launching nvim and watching for errors; there is no headless test harness in this repo.

## Gotchas

- Custom keymap descriptions are Spanish; custom LSP servers are intelephense, dartls, omnisharp (in `lua/plugins/lsp.lua`). Many LazyVim defaults are deliberately rebound to `Snacks.picker`.
- `restart_dotnet_server` is defined twice in `lua/config/keymaps.lua` — the second definition wins, the first is dead code. Don't fix either in isolation.
- Copilot lives only in `lua/plugins/copilot.lua` (ghost text + Tab). The duplicate `blink-cmp-copilot` provider was removed from `lua/plugins/blink.lua` to halve per-keystroke copilot requests.
- Copilot Chat v2 lives in the same file: the `ai.copilot-chat` extra provides `CopilotC-Nvim/CopilotChat.nvim` (its own default keymaps live under `<leader>a*`), and that file only overrides opts/keys. It reuses the copilot.lua token from `%LOCALAPPDATA%/github-copilot/apps.json`; no second login needed.
- `model = "auto"` is deliberate: this account's Copilot plan only allows `claude-haiku-4.5`, `gpt-5-mini`, `gpt-5.4-mini`, `gpt-5.3-codex` and `mai-code-1.1-flash` — every listed model has `model_picker_enabled = false`, so any hardcoded id silently falls back to auto.
- `lua/plugins/copilot.lua` also defines a `gemini` provider (Google AI Studio, OpenAI-compatible endpoint) because the Copilot plan has no Google models. `USAR_GEMINI` is currently `false`: the key is valid but its project returns 402 "prepayment credits are depleted". Flip `USAR_GEMINI = true` after adding billing at https://ai.studio/projects. The key lives in `%LOCALAPPDATA%/nvim-data/gemini_api_key` (or `GEMINI_API_KEY`), never in the repo.
- Google auth is picky: `/v1beta/models` only accepts `x-goog-api-key`, while `/v1beta/openai/chat/completions` requires `Authorization: Bearer`. That's why `get_headers` and `prepare_input` return different headers.
- `language = "Spanish"` makes answers Spanish. `trusted_tools` only trusts read-only `file`/`glob`/`grep`; `bash` and `edit` still ask for approval.
- `options.lua` appends `popup` to `completeopt`; without it the chat's `#resource` / `@tool` autocomplete silently fails on Neovim 0.11+.
- Hardcoded Windows host specifics: `C:/Users/Dell Precision/Documents/Dev` for the project picker (`<leader>p`), Alacritty external terminals, `taskkill /F /IM dotnet.exe`, and named Android AVDs (`<leader>f`). These assume this exact machine.
- `ftplugin/cs.lua` adds a buffer-local keymap formatted to trigger LSP format on `}`.
- C# formatting: `autocmds.lua` sets `vim.b.autoformat = true` + format-on-type (`;`/`}`) via OmniSharp (InsertCharPre + `vim.lsp.buf.format`); `organize_imports_on_format = false` in `lsp.lua` keeps on-type cheap. Global `autoformat` stays off for the rest.
- OmniSharp must use the lspconfig default `cmd` (it supplies `-z` and `--languageserver`); a custom `cmd = { "omnisharp" }` starts a server that never speaks LSP. Also do not use `util.find_git_ancestor(fname)` as `root_dir`: Neovim 0.12 passes the buffer number, so it errors with `path: expected string, got number`.
- `csharp_ls` was auto-enabled by `mason-lspconfig` purely because `csharp-language-server` was installed in Mason, so it silently took over C# support; `lsp.lua` sets `csharp_ls = { enabled = false }` to keep OmniSharp as the only C# server.
- OmniSharp 1.39.15 does not apply `RoslynExtensionsOptions:EnableImportCompletion` through any channel (LSP `settings`, global or project `omnisharp.json`, or CLI argument), so unimported types never show up in the completion menu. Adding the `using` is done with the `<leader>xu` keymap in `keymaps.lua`, which asks `textDocument/codeAction` for the `using X;` fix.
- OmniSharp returns that code action **without** `edit`; the edit only appears after a `codeAction/resolve` request, which Neovim does not issue on its own. The keymap calls `codeAction/resolve` and applies the result with `vim.lsp.util.apply_workspace_edit`.
- On the first open of a project OmniSharp compiles it in the background for 30-45s; `workspace/symbol` returns ~925 partial symbols during that window and ~6300 once loaded. Empty completions right after opening a file are expected, not a config bug.
- `mapleader` is a space, so `<leader>xu` is `<Space>xu`.
- OmniSharp on this setup logs a stream of `LSP[omnisharp]: Error INVALID_SERVER_MESSAGE: vim.NIL`; it is noisy but does not break requests.
- Colorscheme is `sunbather` (`nikolvs/vim-sunbather` in `lua/plugins/colorscheme.lua`); fallbacks `tokyonight`/`habamax` are pinned for the Lazy install. `autoformat` is globally off in `options.lua`.