return {
  {
    -- Emmet: expandir abreviaciones HTML/CSS con <C-y>, (también en vistas
    -- .php con HTML embebido, que soporta de serie).
    "mattn/emmet-vim",
    event = "VeryLazy",
    init = function()
      vim.g.user_emmet_mode = "a"
      vim.g.user_emmet_leader_key = "<C-y>"
    end,
  },
}