return {
  -- 1. Tema por defecto: JetBrains (JB) para Neovim
  --    Trae tema de lualine y estilos para snacks.nvim, blink.cmp y copilot.
  --    La variante clara es "jb-light".
  {
    "nickkadutskyi/jb.nvim",
    lazy = false,
    priority = 1000, -- Se carga antes que todo lo demás
    config = function()
      -- El setup debe correr ANTES de :colorscheme
      require("jb").setup({
        transparent = false,
      })
    end,
  },

  -- 2. Configurar LazyVim para usarlo
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "jb",
    },
  },
}
