return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "html",
        "css",
        "scss",
        "php",
        "twig",
        "blade",
        "c_sharp",
      },
      auto_install = false,
      sync_install = false,
      highlight = {
        enable = false,
      },
    },
  },
}
