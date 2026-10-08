return {
  {
      "slugbyte/lackluster.nvim",
      lazy = false,
      priority = 1000,
      config = function()
          vim.api.nvim_create_autocmd("ColorScheme", {
              pattern = "lackluster", 
              callback = function()
                  -- STRINGS
                  vim.api.nvim_set_hl(0, "String", { fg = "#A6E3A1" })   
                  vim.api.nvim_set_hl(0, "@string", { link = "String" })   

                  -- FUNCIONES
                  vim.api.nvim_set_hl(0, "Function", { fg = "#89B4FA", bold = true }) 
                  vim.api.nvim_set_hl(0, "@function", { link = "Function" }) 
                  vim.api.nvim_set_hl(0, "@function.method", { link = "Function" }) 

                  -- PALABRAS CLAVE
                  vim.api.nvim_set_hl(0, "Keyword", { fg = "#F5C2E7", bold = true }) 
                  vim.api.nvim_set_hl(0, "@keyword", { link = "Keyword" }) 
                  vim.api.nvim_set_hl(0, "Statement", { link = "Keyword" }) 
                  
                  -- CLASES Y TIPOS
                  vim.api.nvim_set_hl(0, "Type", { fg = "#F9E2AF", bold = true })     
                  vim.api.nvim_set_hl(0, "@type", { link = "Type" })     
                  vim.api.nvim_set_hl(0, "@class", { link = "Type" })     

                  -- PROPIEDADES
                  vim.api.nvim_set_hl(0, "@property", { fg = "#94E2D5" }) 
                  
                  -- NÚMEROS Y BOOLEANOS
                  vim.api.nvim_set_hl(0, "Number", { fg = "#FAB387" })   
                  vim.api.nvim_set_hl(0, "@number", { link = "Number" })   
                  vim.api.nvim_set_hl(0, "Boolean", { fg = "#FAB387", bold = true })
                  vim.api.nvim_set_hl(0, "@boolean", { link = "Boolean" })
                  
                  -- COMENTARIOS
                  vim.api.nvim_set_hl(0, "Comment", { fg = "#6C7086", italic = true }) 
                  vim.api.nvim_set_hl(0, "@comment", { link = "Comment" }) 

                  -- FORZAR LÍNEA DEL CURSOR Y SELECCIÓN A TONOS OSCUROS Y SUTILES
                  vim.api.nvim_set_hl(0, "CursorLine", { bg = "#181825" }) -- Fondo de la línea actual muy oscuro
                  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#F9E2AF", bold = true }) -- Número de línea actual
                  vim.api.nvim_set_hl(0, "Visual", { bg = "#313244" }) -- Modo selección de texto sutil (no blanco cegador)
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
