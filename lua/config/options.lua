-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.cmdheight = 1
opt.relativenumber = false
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
vim.opt.swapfile = false
vim.opt.fileformats = { "unix", "dos" }
vim.opt.fileformat = "unix"

opt.completeopt:append("popup")
vim.g.autoformat = false

vim.opt.clipboard = "unnamedplus"

-- Codificacion UTF-8 global: 'enc' es el interno de Neovim (utf-8 siempre),
-- 'fileencoding' fuerza utf-8 al escribir (sinBOM) y 'fileencodings' decide el
-- orden de deteccion al leer. Dejamos solo utf-8 para evitar que una cabecera
-- latin1 Honorifico/ISO Falle al abrirse. Si un archivo viejo sale con signos
-- raros, se re-codifica con :set fileencoding=utf-8 y :write.
opt.encoding = "utf-8"
opt.fileencoding = "utf-8"
opt.fileencodings = "utf-8"
-- Escribe sin BOM: por defecto Neovim no lo anade, lo fijamos explicitamente.
opt.bomb = false

-- Filtro de diagnÃ³sticos: solo mostrar errores en todo el workspace.
-- Se descartan WARN/INFO/HINT para reducir ruido.
local diagnostico_set = vim.diagnostic.set
vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
  local buf = bufnr or vim.api.nvim_get_current_buf()
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if vim.api.nvim_buf_is_loaded(buf) then
    local solo_errores = {}
    for _, d in ipairs(diagnostics or {}) do
      if d.severity == vim.diagnostic.severity.ERROR then
        solo_errores[#solo_errores + 1] = d
      end
    end
    diagnostics = solo_errores
  end
  return diagnostico_set(namespace, bufnr, diagnostics, opts)
end

-- Mantener indentaciÃ³n con tabs (estilo tabs) sin que se autoajuste mal al cerrar parÃ©ntesis
vim.opt.autoindent = true
vim.opt.smartindent = false
vim.opt.cindent = false
vim.opt.indentexpr = ""
vim.opt.copyindent = true
vim.opt.preserveindent = true
vim.opt.formatoptions:remove({ "o", "r" })

-- Forzar a copiar la indentación exacta de la línea anterior
-- Ignora indentexpr de filetype/treesitter que recalcula por bloque
local group = vim.api.nvim_create_augroup("PreservePrevIndent", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function()
    vim.bo.indentexpr = ""
    vim.bo.indentkeys = ""
    vim.bo.autoindent = true
    vim.bo.smartindent = false
    vim.bo.cindent = false
  end,
})
