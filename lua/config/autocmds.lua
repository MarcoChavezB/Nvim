vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '*.cshtml', '*.razor' },
  callback = function()
    vim.bo.filetype = 'razor'
  end,
})
defer_fn(function()
      pcall(vim.lsp.enable, 'roslyn_ls', true)
      pcall(vim.lsp.start, { name = 'roslyn_ls', bufnr = ev.buf })
    end, 200)
  end,
})
  end
    if not vim.g._lsp_notified[key] then
      vim.notify(client.name .. ': conectado, analizando...', vim.log.levels.INFO)
      vim.g._lsp_notified[key] = true
    end
  end,
})

vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
  pattern = { '*.cshtml', '*.razor' },
  callback = function()
    vim.bo.filetype = 'razor'
  end,
})
defer_fn(function()
      pcall(vim.lsp.enable, 'roslyn_ls', true)
      pcall(vim.lsp.start, { name = 'roslyn_ls', bufnr = ev.buf })
    end, 300)
  end,
})
nction(client)
                return client.name == "roslyn_ls"
              end,
            })
          end)
        end
      end,
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
      group = csharp_augroup,
      buffer = 0,
      callback = function()
        if vim.lsp.get_clients({ bufnr = 0, name = "roslyn_ls" })[1] then
          vim.schedule(vim.lsp.codelens.refresh)
        end
      end,
    })
  end,
})

local lsp_loading = vim.api.nvim_create_augroup("LazyVimLspLoading", { clear = true })
local lsp_avisado = {}

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_loading,
  desc = "Avisar cuando un LSP se conecta y empieza a analizar",
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client and client.name and not lsp_avisado[client.name] then
      lsp_avisado[client.name] = true
      vim.schedule(function()
        vim.notify(string.format("%s: conectado, analizando...", client.name), vim.log.levels.INFO, {
          title = "LSP",
        })
      end)
    end
  end,
})

local dart_indent = vim.api.nvim_create_augroup("DartFixIndent", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = dart_indent,
  pattern = "dart",
  callback = function()
    vim.opt_local.cindent = false
    vim.opt_local.smartindent = false
    vim.opt_local.autoindent = true
    vim.opt_local.indentexpr = ""
    vim.opt_local.indentkeys = ""
    vim.opt_local.formatoptions:remove("o")
    vim.opt_local.formatoptions:remove("r")
    vim.opt_local.formatoptions:remove("t")
  end,
})

-- .cshtml/.razor: HTML + Razor
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = { "*.cshtml", "*.razor" },
  callback = function()
    vim.bo.filetype = "razor"
  end,
})

-- Razor: permitir snippets HTML/CSS y comportamiento web
vim.api.nvim_create_autocmd("FileType", {
  pattern = "razor",
  callback = function()
    vim.bo.commentstring = "@* %s *@"
  end,
})
-- Emmet tambiÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã‚Â¡ÃƒÆ’Ã†â€™ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â©n en Razor
vim.api.nvim_create_autocmd("FileType", {
  pattern = "razor",
  callback = function()
    vim.g.user_emmet_install_global = 0
    vim.cmd("EmmetInstall")
  end,
})

-- Razor: asegurar snippets HTML/CSS disponibles
vim.api.nvim_create_autocmd("FileType", {
  pattern = "razor",
  callback = function()
    local ok, ls = pcall(require, "luasnip")
    if ok and ls and ls.filetype_extend then
      ls.filetype_extend("razor", { "html", "css" })
    end
  end,
})

-- Forzar Roslyn en Razor si no hay cliente
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "razor", "cshtml" },
  callback = function(ev)
    local clients = vim.lsp.get_clients({ bufnr = ev.buf })
    if #clients == 0 then
      vim.defer_fn(function()
        pcall(vim.lsp.enable, "roslyn_ls", true)
        pcall(vim.lsp.start, { name = "roslyn_ls", bufnr = ev.buf, root_dir = vim.fn.getcwd() })
      end, 500)
    end
  end,
})
