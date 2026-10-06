vim.keymap.set("i", "}", function()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("}", true, true, true), "n", true)
  
  vim.defer_fn(function()
    vim.lsp.buf.format({ async = true })
  end, 10)
end, { buffer = true, desc = "Formatear bloque C# al cerrar llave" })
