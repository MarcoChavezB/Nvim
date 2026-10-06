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

    -- Formato en vivo: al teclear ";" o "}" Roslyn reformatea la línea al momento
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
                return client.name == "roslyn_ls"
              end,
            })
          end)
        end
      end,
    })

    -- Codelens de referencias de Roslyn ("N referencias" sobre cada símbolo): se
    -- refrescan al abrir/volver al buffer y al salir de insert, como en VS Code.
    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
      group = csharp_augroup,
      buffer = 0,
      callback = function()
        if vim.lsp.get_clients({ bufnr = 0, name = "roslyn_ls" })[1] then
          vim.schedule(vim.lsp.codelens.refresh)
        end
      end,
    })
  end,
})
