return {
  {
    "akinsho/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- Para que los menús de Flutter se vean estéticos
    },
    config = function()
      require("flutter-tools").setup({
        ui = {
          border = "rounded",
        },
        decorations = {
          statusline = {
            device = true, -- Muestra el dispositivo actual en la barra de estado
            version = true,
          },
        },
        lsp = {
          color_render = true, -- Renderiza los colores (ColorProvider) en tu código de Flutter
          settings = {
            showTodos = true,
            completeFunctionCalls = true,
            animationHints = true,
          },
        }
      })
    end,
  },
}
