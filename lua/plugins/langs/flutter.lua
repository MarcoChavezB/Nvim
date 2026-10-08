return {
  {
    "nvim-flutter/flutter-tools.nvim",
    lazy = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    opts = {
      ui = { border = "rounded" },
      decorations = {
        statusline = {
          device = true,
          app_version = true,
        },
      },
      lsp = {
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          enableSnippets = true,
          updateImportsOnRename = true,
          renameFilesWithClasses = "prompt",
        },
      },
      widget_guides = { enabled = true },
    },
    config = function(_, opts)
      require("flutter-tools").setup(opts)
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
