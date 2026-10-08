return {
  {
    "saghen/blink.cmp",
    version = "*",
    opts = {
      keymap = {
        preset = "default",
        ["<CR>"] = { "accept", "fallback" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      -- PersonalizaciÃ³n del diseÃ±o y comportamiento visual:
      completion = {
        -- MenÃº flotante de sugerencias
        menu = {
          border = "rounded", -- Bordes redondeados en la ventana de autocompletado
          winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
          draw = {
            columns = {
              { "kind_icon" },
              { "label", "label_description", gap = 1 },
              { "kind" },
            },
          },
        },
        -- Ventana emergente de documentaciÃ³n (Muestra info del cÃ³digo seleccionado)
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 150,
          window = {
            border = "rounded",
            winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,CursorLine:BlinkCmpDocCursorLine,Search:None",
          },
        },
      },
    },
  },
}
