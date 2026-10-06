return {
  -- Configuración de render-markdown (solo se activa si los parsers existen)
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {},
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
  },

  -- Configuración optimizada de Treesitter para tablets / PRoot
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Evita la instalación automática masiva al iniciar
      opts.auto_install = false
      opts.sync_install = false

      -- Vaciamos ensure_installed o dejamos solo lo mínimo indispensable para que no intente compilar 15 lenguajes de golpe
      opts.ensure_installed = { "lua", "vim", "bash", "c_sharp" }
    end,
  },
}
