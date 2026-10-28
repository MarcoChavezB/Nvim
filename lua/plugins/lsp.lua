return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        exclude = { "vue", "dart" },
      },
      servers = {
        intelephense = {},

        html = {
          filetypes = { "html", "htm", "xhtml", "php", "blade" },
          settings = {
            html = { suggest = { html5 = true } },
          },
        },

        cssls = {},

        dartls = { enabled = false },
        csharp_ls = { enabled = false },
        omnisharp = { enabled = false },
        roslyn_ls = {
          settings = {
            ["csharp|completion"] = {
              dotnet_show_completion_items_from_unimported_namespaces = true,
              dotnet_show_name_completion_suggestions = true,
              dotnet_provide_regex_completions = true,
            },
            ["csharp|inlay_hints"] = {
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
              dotnet_enable_references_code_lens = true,
            },
            ["csharp|background_analysis"] = {
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
      },
    },
  },
}
