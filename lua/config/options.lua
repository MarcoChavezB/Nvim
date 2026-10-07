-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.cmdheight = 1
opt.relativenumber = false
opt.tabstop = 4
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

-- Filtro de diagnósticos por filetype:
--  * cs: solo ERROR. Los INFO/WARN/HINT de los analizadores de Roslyn se
--    descartan ANTES de guardarse, asi que tampoco aparecen en el flotante,
--    en los signs, en el statuscolumn ni en <leader>sd (Trouble/Snacks leen
--    de vim.diagnostic). Decision propia para no ahogar con sugerencias C#.
--  * resto (dart/flutter, php, lua...): todas las severidades, experiencia IDE.
-- Se filtra en vim.diagnostic.set porque es el unico punto por el que Neovim
-- guarda diagnosticos: cubre LSP push y pull (0.12 ya no tiene
-- vim.diagnostic.on_publish_diagnostics) y cualquier otro plugin que publique.
local diagnostico_set = vim.diagnostic.set
vim.diagnostic.set = function(namespace, bufnr, diagnostics, opts)
  local buf = bufnr or vim.api.nvim_get_current_buf()
  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end
  if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype == "cs" then
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
