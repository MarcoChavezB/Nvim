return {
  {
    "mattn/emmet-vim",
    event = "VeryLazy",
    init = function()
      vim.g.user_emmet_mode = "a"
      vim.g.user_emmet_leader_key = "<C-y>"
    end,
  },
}
