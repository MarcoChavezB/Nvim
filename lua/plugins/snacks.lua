-- Los pickers de Snacks vienen con `hidden = false` e `ignored = false`, asi que
-- los archivos ocultos (.env, .vscode, .github) y los que git ignora (.env
-- normalmente esta en .gitignore) no aparecian nunca en el buscador de archivos.
--
-- `ignored = true` hace que fd corra con `--no-ignore`, asi que sin `exclude`
-- el picker se traga .dart_tool, bin, obj, node_modules, etc. (decenas de miles
-- de archivos y el picker se vuelve lento), por eso se excluyen a mano.
local generados = {
  "node_modules",
  ".dart_tool",
  ".idea",
  ".vs",
  "build",
  "bin",
  "obj",
  ".git",
}

return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          -- <leader><space>, <leader>ff, <leader>fF, <leader>p
          files = { hidden = true, ignored = true, exclude = generados },
          -- <leader>fg: incluye tambien los archivos sin trackear
          git_files = { untracked = true },
          -- <leader>sg / <leader>sw: busca dentro de archivos ocultos
          grep = { hidden = true },
        },
      },
    },
  },
}
