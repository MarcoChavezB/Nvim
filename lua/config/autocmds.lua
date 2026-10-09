-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

-- Formateo de C#: autoformato al guardar y formato en vivo al teclear ; o }
local csharp_augroup = vim.api.nvim_create_augroup("LazyVimCSharpFormat", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = csharp_augroup,
  pattern = "cs",
  callback = function()
    vim.b.autoformat = true
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

local lsp_loading = vim.api.nvim_create_augroup("LazyVimLspLoading", { clear = true })
local lsp_avisado = {}

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_loading,
  desc = "Notifica cuando un servidor LSP se adjunta (análisis en curso)",
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name and not lsp_avisado[client.name] then
      lsp_avisado[client.name] = true
      vim.schedule(function()
        vim.notify(string.format("%s: conectado, analizando...", client.name), vim.log.levels.INFO, {
          title = "LSP",
        })
      end)
    end
  end,
})

local dart_indent = vim.api.nvim_create_augroup("DartFixIndent", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = dart_indent,
  pattern = "dart",
  callback = function()
    vim.opt_local.cindent = false
    vim.opt_local.smartindent = false
    vim.opt_local.autoindent = true
    vim.opt_local.indentexpr = ""
    vim.opt_local.indentkeys = ""
    vim.opt_local.formatoptions:remove("o")
    vim.opt_local.formatoptions:remove("r")
    vim.opt_local.formatoptions:remove("t")
  end,
})

-- Registra la línea de cada modificación real del buffer (para <leader>c, volver
-- al cambio anterior). Usa b:changedtick para no registrar visitas sin cambios y
-- guarda la lista por buffer, así solo afecta al archivo actual.
local edit_track = vim.api.nvim_create_augroup("LazyVimEditTrack", { clear = true })
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = edit_track,
  desc = "Registra la posición de cada edición del buffer",
  callback = function()
    local tick = vim.b.changedtick
    if vim.b.edit_last_tick == tick then
      return
    end
    vim.b.edit_last_tick = tick
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local list = vim.b.edit_positions
    if type(list) ~= "table" then
      list = {}
    end
    if list[#list] ~= line then
      list[#list + 1] = line
    end
    vim.b.edit_positions = list
  end,
})
