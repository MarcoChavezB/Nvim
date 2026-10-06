return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {},
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      auto_install = false,
      sync_install = false,
      -- Forzamos a usar únicamente el GCC interno de Debian
      compilers = { "gcc" },
      ensure_installed = {}, -- Lo dejamos completamente vacío
    },
  },
}
