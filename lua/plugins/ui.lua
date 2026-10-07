return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Necesarios para nvim-ts-autotag y el indentado de web; se instalan
        -- pero el highlighting sigue desactivado (está abajo).
        "html",
        "css",
        "php",
      },
      auto_install = false,
      sync_install = false,
      highlight = {
        enable = false, -- Desactiva el motor de highlighting por C-parser de Treesitter
      },
    },
  },
}
