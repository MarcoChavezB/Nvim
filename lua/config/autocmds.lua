-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Formateo de C#: autoformato al guardar y formato en vivo al teclear ; o }
local csharp_augroup = vim.api.nvim_create_augroup("LazyVimCSharpFormat", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = csharp_augroup,
  pattern = "cs",
  callback = function()
    -- Activa el autoformato al guardar (conform/csharpier) solo para C#
    vim.b.autoformat = true

    -- Formato en vivo: al teclear ";" o "}" OmniSharp reformatea la línea al momento
    vim.api.nvim_create_autocmd("InsertCharPre", {
      group = csharp_augroup,
      buffer = 0,
      callback = function()
        local ch = vim.v.char
        if ch == ";" or ch == "}" then
          vim.schedule(function()
            vim.lsp.buf.format({
              bufnr = 0,
              async = true,
              filter = function(client)
                return client.name == "omnisharp"
              end,
            })
          end)
        end
      end,
    })
  end,
})
