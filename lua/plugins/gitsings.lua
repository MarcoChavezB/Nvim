return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add          = { text = "│" },
      change       = { text = "│" },
      delete       = { text = "_" },
      topdelete    = { text = "‾" },
      changedelete = { text = "~" },
      untracked    = { text = "┆" },
    },
    current_line_blame = true, -- Esto activa el mensaje de commit en la línea actual
    current_line_blame_opts = {
      virt_text = true,
      virt_text_pos = "eol", -- 'eol' lo muestra al final de la línea
      delay = 500, -- Tiempo en milisegundos antes de mostrarse
      ignore_whitespace = false,
    },
    current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
  },
}
