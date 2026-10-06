return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        -- No mostrar tipos de variables declaradas en Dart (inlay hints)
        exclude = { "vue", "dart" },
      },
      servers = {
        intelephense = {},
        dartls = {},

        -- csharp-ls venía autoactivado por mason-lspconfig (estaba instalado en Mason)
        -- y competía con OmniSharp: dos servidores C# = diagnósticos y completados duplicados
        csharp_ls = { enabled = false },

        -- Servidor C# que usa tu extra "lang.dotnet" (OmniSharp-Roslyn vía Mason)
        omnisharp = {
          settings = {
            FormattingOptions = {
              EnableEditorConfigSupport = true,
            },
            RoslynExtensionsOptions = {
              -- Pide autocompletado de tipos NO importados.
              -- OJO: en OmniSharp 1.39.15 esta opción no llega a aplicarse (probado vía
              -- settings del LSP, omnisharp.json global y del proyecto, y por argumento),
              -- así que no esperes que los tipos de otros namespaces aparezcan en el menú.
              -- La vía que sí funciona es la code action: <leader>xu con el cursor sobre el
              -- tipo desconocido (ver lua/config/keymaps.lua).
              EnableImportCompletion = true,
              -- Diagnósticos de analizadores de Roslyn
              EnableAnalyzersSupport = true,
            },
          },
          -- Evita que OmniSharp reorganice imports en cada formato on-type (lento)
          organize_imports_on_format = false,
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
        "omnisharp", -- Le pedimos a Mason que asegure Omnisharp limpio
      },
    },
  },
}
