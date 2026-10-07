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

        -- vscode-html-language-server: errores, completado de etiquetas y HTML
        -- embebido (CSS/JS embebidos los analiza él). filetypes con php/blade
        -- para que las vistas con HTML dentro de .php también funcionen.
        html = {
          filetypes = { "html", "htm", "xhtml", "php", "blade" },
          settings = {
            html = { suggest = { html5 = true } },
          },
        },

        -- vscode-css-language-server: valida CSS/SCSS/LESS con diagnósticos ON.
        cssls = {},

        -- dartls NO se configura aquí: lo levanta flutter-tools.nvim con el server
        -- del propio SDK de Flutter (ver lua/plugins/langs/flutter.lua). Dejarlo
        -- activo = dos servers Dart = diagnósticos y completados rotos/duplicados.
        dartls = { enabled = false },

        -- csharp-ls venía autoactivado por mason-lspconfig (estaba instalado en Mason)
        -- y competía con el servidor C# activo. Se mantiene desactivado.
        csharp_ls = { enabled = false },

        -- OmniSharp quedó en "maintenance mode" (Microsoft lo jubiló en favor de Roslyn)
        -- y su EnableImportCompletion no llega a aplicarse en 1.39.x: los tipos de
        -- otros namespaces nunca aparecían en el menú ni se agregaba el using solo.
        omnisharp = { enabled = false },

        -- Roslyn = el servidor que usa el C# Dev Kit de VS Code. Auto-import real:
        -- dotnet_show_completion_items_from_unimported_namespaces=true hace que los
        -- tipos de otros namespaces salgan en el menú y blink.cmp aplica el "using"
        -- automático al aceptar el completado. LazyVim lo instala por Mason solo
        -- (extra lang.dotnet + roslyn_ls). Su root_dir toma el PRIMER .sln que
        -- encuentra hacia arriba (para varios .sln, usar el plugin roslyn.nvim).
        roslyn_ls = {
          settings = {
            ["csharp|completion"] = {
              dotnet_show_completion_items_from_unimported_namespaces = true,
              dotnet_show_name_completion_suggestions = true,
              dotnet_provide_regex_completions = true,
            },
            ["csharp|inlay_hints"] = {
              -- Igual que con dart: sin hints ruidosos de parámetros.
              csharp_enable_inlay_hints_for_implicit_variable_types = true,
              csharp_enable_inlay_hints_for_types = true,
              csharp_enable_inlay_hints_for_implicit_object_creation = false,
              csharp_enable_inlay_hints_for_lambda_parameter_types = false,
              dotnet_enable_inlay_hints_for_indexer_parameters = false,
              dotnet_enable_inlay_hints_for_literal_parameters = false,
              dotnet_enable_inlay_hints_for_object_creation_parameters = false,
              dotnet_enable_inlay_hints_for_other_parameters = false,
              dotnet_enable_inlay_hints_for_parameters = false,
            },
            ["csharp|code_lens"] = {
              -- Contador de referencias arriba de cada símbolo, como en VS Code.
              dotnet_enable_references_code_lens = true,
            },
            ["csharp|background_analysis"] = {
              -- Diagnósticos en toda la solución (no solo archivos abiertos).
              dotnet_analyzer_diagnostics_scope = "fullSolution",
              dotnet_compiler_diagnostics_scope = "fullSolution",
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "intelephense",
        -- "omnisharp" ya no: el server C# lo instala LazyVim automáticamente como
        -- roslyn_ls (paquete "roslyn-language-server") vía el extra lang.dotnet.
      },
    },
  },
}
