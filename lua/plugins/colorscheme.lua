return {
  {
      "slugbyte/lackluster.nvim",
      lazy = false,
      priority = 1000,
      config = function()
          vim.api.nvim_create_autocmd("ColorScheme", {
              pattern = "lackluster", 
              callback = function()
                  -- Fondo general ultra oscuro
                  vim.api.nvim_set_hl(0, "Normal", { fg = "#DEEEED", bg = "#080808" })
                  vim.api.nvim_set_hl(0, "NormalNC", { fg = "#708090", bg = "#080808" })

                  -- =========================================================
                  -- MENÚS FLOTANTES (Pickers / Snacks / Telescope)
                  -- =========================================================
                  -- Fondo del menú flotante más suave/oscuro (#0f0f0f o #121212)
                  vim.api.nvim_set_hl(0, "NormalFloat", { fg = "#CCCCCC", bg = "#101010" })
                  vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#222222", bg = "#101010" })
                  vim.api.nvim_set_hl(0, "FloatTitle", { fg = "#888888", bg = "#101010", bold = true })

                  -- Selección dentro del menú (línea activa)
                  vim.api.nvim_set_hl(0, "PmenuSel", { fg = "#FFFFFF", bg = "#222222", bold = true })
                  vim.api.nvim_set_hl(0, "Pmenu", { fg = "#A0A0A0", bg = "#101010" })
                  vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#333333" })

                  -- Pickers específicos de Snacks.nvim (si usas Snacks)
                  vim.api.nvim_set_hl(0, "SnacksPickerNormal", { fg = "#CCCCCC", bg = "#101010" })
                  vim.api.nvim_set_hl(0, "SnacksPickerBorder", { fg = "#222222", bg = "#101010" })
                  vim.api.nvim_set_hl(0, "SnacksPickerList", { bg = "#101010" })

                  -- =========================================================
                  -- EXPLORADOR LATERAL (Neo-tree / Snacks / NvimTree)
                  -- =========================================================
                  vim.api.nvim_set_hl(0, "NvimTreeNormal", { fg = "#808080", bg = "#0B0B0B" })
                  vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { fg = "#606060", bg = "#0B0B0B" })
                  vim.api.nvim_set_hl(0, "NeoTreeNormal", { fg = "#808080", bg = "#0B0B0B" })
                  vim.api.nvim_set_hl(0, "NeoTreeNormalNC", { fg = "#606060", bg = "#0B0B0B" })
                  vim.api.nvim_set_hl(0, "WinSeparator", { fg = "#1C1C1C", bg = "NONE" })

                  -- =========================================================
                  -- SINTAXIS
                  -- =========================================================
                  vim.api.nvim_set_hl(0, "String", { fg = "#789978" })    
                  vim.api.nvim_set_hl(0, "@string", { link = "String" })    

                  vim.api.nvim_set_hl(0, "Function", { fg = "#7788AA", bold = false }) 
                  vim.api.nvim_set_hl(0, "@function", { link = "Function" }) 
                  vim.api.nvim_set_hl(0, "@function.method", { link = "Function" }) 

                  vim.api.nvim_set_hl(0, "Keyword", { fg = "#DEEEED", bold = true }) 
                  vim.api.nvim_set_hl(0, "@keyword", { link = "Keyword" })
                  vim.api.nvim_set_hl(0, "Statement", { link = "Keyword" })    
                  
                  vim.api.nvim_set_hl(0, "Type", { fg = "#789978", bold = false })     
                  vim.api.nvim_set_hl(0, "@type", { link = "Type" })     
                  vim.api.nvim_set_hl(0, "@class", { link = "Type" })     

                  vim.api.nvim_set_hl(0, "@property", { fg = "#708090" })  
                  
                  vim.api.nvim_set_hl(0, "Number", { fg = "#FFAA88" })    
                  vim.api.nvim_set_hl(0, "@number", { link = "Number" })
                  vim.api.nvim_set_hl(0, "Boolean", { fg = "#FFAA88", bold = false })
                  vim.api.nvim_set_hl(0, "@boolean", { link = "Boolean" })
                  
                  vim.api.nvim_set_hl(0, "Comment", { fg = "#555555", italic = true }) 
                  vim.api.nvim_set_hl(0, "@comment", { link = "Comment" }) 


                  -- =========================================================
                  -- MODO VISUAL Y BÚSQUEDAS (Selección tenue)
                  -- =========================================================
                  -- Selección en modo visual (V, v, Ctrl+v)
                  vim.api.nvim_set_hl(0, "Visual", { bg = "#222222", fg = "NONE" })
                  vim.api.nvim_set_hl(0, "VisualNOS", { bg = "#222222", fg = "NONE" })

                  -- Búsqueda y resaltado bajo el cursor
                  vim.api.nvim_set_hl(0, "Search", { bg = "#2A2A2A", fg = "#DEEEED" })
                  vim.api.nvim_set_hl(0, "CurSearch", { bg = "#333333", fg = "#FFFFFF", bold = true })
                  vim.api.nvim_set_hl(0, "IncSearch", { bg = "#333333", fg = "#FFFFFF" })

                  -- Coincidencias automáticas de LSP al poner el cursor sobre una palabra
                  vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#1F1F1F" })
                  vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#1F1F1F" })
                  vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#1F1F1F" })
              end,
          })
          
          vim.cmd.colorscheme("lackluster")
      end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "lackluster", 
    },
  },
}
