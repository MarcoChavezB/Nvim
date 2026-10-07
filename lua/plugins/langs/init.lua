return {
  -- lazy.nvim NO recorre subcarpetas en `import = "plugins"` (solo *.lua del
  -- nivel superior y el init.lua de cada subdirectorio). Aquí se declaran
  -- explícitamente los specs de langs/ para que sí se carguen.
  { import = "plugins.langs.flutter" },
}
