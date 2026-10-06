-- Silenciar el error cosmético de OmniSharp 1.39.x: "INVALID_SERVER_MESSAGE: vim.NIL".
--
-- Causa: OmniSharp encola sus notificaciones propias (o#/projectdiagnosticstatus,
-- o#/backgrounddiagnosticstatus, o#/projectconfiguration) antes de que termine el
-- "initialize" y al volcarlas escribe un cuerpo JSON vacio (null) que Neovim no
-- puede validar. Es un bug conocido y sin fix upstream:
--   OmniSharp/omnisharp-roslyn#2574 (abierto) y neovim/neovim#29988 (cerrado como
--   "not planned"). No rompe ninguna peticion: el resto de mensajes se leen bien.
--
-- Solo se filtra INVALID_SERVER_MESSAGE de omnisharp. Cualquier otro error de LSP
-- (de este servidor o de los demas) se sigue mostrando con normalidad.
local grupo = vim.api.nvim_create_augroup("LspOmniSharpFiltro", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = grupo,
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "omnisharp" or client.write_error_patched then
      return
    end

    local write_error = client.write_error
    local codigo_invalido = vim.lsp.rpc.client_errors.INVALID_SERVER_MESSAGE
    client.write_error = function(self, code, err)
      if code == codigo_invalido and err == vim.NIL then
        return
      end
      return write_error(self, code, err)
    end
    client.write_error_patched = true
  end,
})
