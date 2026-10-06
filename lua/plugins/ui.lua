return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {},
      auto_install = false,
      sync_install = false,
      highlight = {
        enable = false, -- Desactiva el motor de highlighting por C-parser de Treesitter
      },
    },
  },
}
