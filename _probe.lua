-- Sonda: mide si <Space> en modo insert queda "pendiente" (delay de mapping)
local out = {}
local function p(...)
  out[#out + 1] = table.concat({ ... }, " ")
end

local t0 = vim.uv.hrtime()
local log = {}
vim.on_key(function(raw)
  if raw and #raw > 0 then
    log[#log + 1] = { t = (vim.uv.hrtime() - t0) / 1e6, k = vim.fn.keytrans(raw) }
  end
end)

-- Archivo .cs de prueba para disparar ftplugin + copilot (InsertEnter)
local tmp = vim.fn.tempname() .. ".cs"
vim.fn.writefile({ "class A { int x = 1; }" }, tmp)
vim.cmd("edit " .. vim.fn.fnameescape(tmp))
vim.wait(3000, function()
  return vim.bo.filetype == "cs"
end, 50)
p("filetype=" .. tostring(vim.bo.filetype))

local function linea()
  return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
end

local function dump_maps(label)
  p("-- " .. label)
  for _, m in ipairs(vim.api.nvim_get_keymap("i")) do
    p(("   global  lhs=%q desc=%s"):format(m.lhs, tostring(m.desc)))
  end
  for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "i")) do
    p(("   buffer  lhs=%q desc=%s"):format(m.lhs, tostring(m.desc)))
  end
end

-- Entrar en insert y esperar a que carguen plugins de InsertEnter (copilot)
vim.api.nvim_feedkeys("i", "ntx", false)
vim.wait(2500)
p("mode tras feedkeys i = " .. vim.api.nvim_get_mode().mode)
dump_maps("insert con plugins InsertEnter cargados")

-- Limpia log
local function last_key_time(k)
  for i = #log, 1, -1 do
    if log[i].k == k then
      return log[i].t
    end
  end
  return nil
end
local function clear_log()
  for i = #log, 1, -1 do
    log[i] = nil
  end
end

local function medir(tecla, nombre)
  clear_log()
  local antes = linea()
  local t_envio = (vim.uv.hrtime() - t0) / 1e6
  vim.api.nvim_input(tecla)
  local cambiado = vim.wait(2500, function()
    return linea() ~= antes
  end, 5)
  local t_cambio = (vim.uv.hrtime() - t0) / 1e6
  p(("%s: recibida_en_log=%s cambio_buffer=%s delta_input->cambio=%.1fms cambio_ok=%s")
    :format(
      nombre,
      last_key_time(vim.fn.keytrans(tecla)) and string.format("%.1f", last_key_time(vim.fn.keytrans(tecla))) or "n/d",
      string.format("%.1f", t_cambio),
      t_cambio - t_envio,
      tostring(cambiado)
    ))
end

-- baseline: tecla normal
medir("x", "letra 'x' (baseline)")
vim.wait(300)
-- espacio en insert
medir(" ", "ESPACIO en insert")
vim.wait(300)
medir(" ", "ESPACIO en insert (2a vez)")

-- probar tambien tras salir y volver a insert
vim.api.nvim_input("<Esc>")
vim.wait(500)
vim.api.nvim_input("i")
vim.wait(800)
medir(" ", "ESPACIO tras reentrar en insert")

p("-- log final (ultimas 20 teclas)")
for i = math.max(1, #log - 19), #log do
  p(string.format("   %8.1fms %s", log[i].t, log[i].k))
end

print(table.concat(out, "\n"))
