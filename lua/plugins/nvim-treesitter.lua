return {
  "nvim-tree/nvim-tree.lua",
  opts = {
    on_attach = function(bufnr)
      local api = require("nvim-tree.api")

      local function opts(desc)
        return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
      end

      -- Cargar los atajos estándar del plugin
      api.config.mappings.default_on_attach(bufnr)

      -- ELIMINAR / ANULAR COMPLETAMENTE LA 'X'
      vim.keymap.set('n', 'x', '<Nop>', opts('Deshabilitar x'))

      -- Si prefieres usar otra tecla para cortar (por ejemplo, la 'x' ya no hace nada, 
      -- pero puedes usar 'X' mayúscula o cualquier otra), puedes asignarla así:
      -- vim.keymap.set('n', 'X', api.fs.cut, opts('Cortar archivo'))
    end,
    view = {
      width = 30,
    },
  },
}
