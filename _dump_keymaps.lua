-- dump de estado de keymaps en modo insert tras cargar plugins
vim.wait(5000, function()
  return package.loaded["which-key"] ~= nil
end, 200)

local out = {}
local function p(...)
  out[#out + 1] = table.concat({ ... }, " ")
end

p("timeout=" .. tostring(vim.o.timeout) .. " timeoutlen=" .. tostring(vim.o.timeoutlen) .. " ttimeoutlen=" .. tostring(vim.o.ttimeoutlen))
p("mapleader=" .. tostring(vim.g.mapleader) .. " maplocalleader=" .. tostring(vim.g.maplocalleader))

local function dump(mode, label)
  local maps = vim.api.nvim_get_keymap(mode)
  p(("--- %s (%d maps) ---"):format(label, #maps))
  for _, m in ipairs(maps) do
    local lhs = m.lhs
    local startsSpace = lhs:sub(1, 1) == " " or lhs:sub(1, 7) == "<Space>"
    if startsSpace then
      p(("  [SPACE] lhs=%q desc=%s buffer=%s"):format(lhs, tostring(m.desc), tostring(m.buffer)))
    end
  end
end

dump("i", "insert")
dump("n", "normal")
dump("t", "terminal")
dump("v", "visual")

-- maparg directo de space en insert
local ma = vim.fn.maparg(" ", "i", false, true)
p("maparg(' ','i') = " .. vim.inspect(ma))

-- listado completo de insert con prefijo potencialmente conflictivo
p("--- ALL insert maps ---")
for _, m in ipairs(vim.api.nvim_get_keymap("i")) do
  p(("  lhs=%q desc=%s"):format(m.lhs, tostring(m.desc)))
end

-- which-key
local ok, wk = pcall(require, "which-key")
p("which-key loaded=" .. tostring(ok))
if ok then
  p("wk version=" .. tostring(wk and (wk.version or "n/a")))
  local ok2, spec = pcall(function()
    return vim.inspect(require("which-key").Boss and "boss" or "noboss")
  end)
  p("wk info=" .. tostring(spec))
end

-- detectar mapeos con prefijo pendiente en insert: simular prefijos
for _, m in ipairs(vim.api.nvim_get_keymap("i")) do
  p("INSERT: " .. string.format("%q", m.lhs) .. " -> " .. string.format("%q", tostring(m.rhs)))
end

print(table.concat(out, "\n"))
