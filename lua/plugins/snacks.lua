return {
  "folke/snacks.nvim",
  opts = {
    cmdline = { enabled = false },
    terminal = { enabled = true },
  },
  config = function(_, opts)
    require("snacks").setup(opts)

    local server_term = nil

    vim.keymap.set("n", "<leader>st", function()
      if server_term and server_term.buf and not vim.api.nvim_buf_is_valid(server_term.buf) then
        server_term = nil
      end

      if not server_term then
        server_term = Snacks.terminal.toggle(nil, {
          cwd = "",
          win = {
            style = "float",
            border = "rounded",
            width = 0.8,
            height = 0.8,
            title = " Servidor / Terminal ",
            title_pos = "center",
          },
        })

        if server_term and server_term.buf then
          vim.api.nvim_create_autocmd("BufUnload", {
            buffer = server_term.buf,
            once = true,
            callback = function()
              server_term = nil
            end,
          })
        end
      else
        server_term:toggle()
      end
    end, { desc = "Togglear terminal de servidor" })
  end,
}
