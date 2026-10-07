return {
  {
    -- flutter-tools levanta él mismo el server Dart (dartls) usando el SDK de
    -- Flutter. Por eso en lua/plugins/lsp.lua el dartls standalone está en
    -- `enabled = false`: si ambos corren, hay diagnósticos/completados rotos.
    -- Requiere `flutter` en el PATH (verificado: Flutter 3.41.6 / Dart 3.11.4).
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim", -- Para que los menús de Flutter se vean estéticos
    },
    opts = {
      ui = {
        border = "rounded",
      },
      decorations = {
        statusline = {
          device = true, -- Muestra el dispositivo actual en la barra de estado
          app_version = true, -- Muestra la versión de la app desde pubspec.yaml
        },
      },
      lsp = {
        settings = {
          showTodos = true,
          completeFunctionCalls = true, -- Autocompleta la llamada completa (con argumentos)
          enableSnippets = true,
          updateImportsOnRename = true, -- Arregla imports al renombrar archivos
          renameFilesWithClasses = "prompt", -- Ofrece renombrar el archivo al renombrar la clase
        },
      },
      widget_guides = {
        enabled = true, -- Guía de columna para abrir/cerrar widgets
      },
    },
    config = function(_, opts)
      require("flutter-tools").setup(opts)

      -- Colores de Material/Cupertino inline (document_color nativo de Nvim 0.12+;
      -- el color_render del plugin quedó deprecado en 0.12+).
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "dartls" then
            vim.lsp.document_color.enable(true, { bufnr = ev.buf })
          end
        end,
      })
    end,
  },
}
