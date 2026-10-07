-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>h", function() LazyVim.pick("live_grep")() end, { desc = "Búsqueda global de palabra" })
vim.keymap.set("n", "<leader>y", function() LazyVim.pick("files")() end, { desc = "Buscar archivo por nombre" })
vim.keymap.set("n", "<leader>n", function() LazyVim.pick("lines")() end, { desc = "Buscar palabra en archivo actual" })
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Seleccionar todo" })

-- Alternar (Toggle) terminal flotante en la raíz del proyecto
vim.keymap.set("n", "<leader>t", function()
  Snacks.terminal.toggle(nil, { cwd = LazyVim.root(), id = "proyecto_term" })
end, { desc = "Toggle Terminal (Raíz)" })

-- 2. Desde Modo Terminal: Permite esconderla usando el mismo atajo sin crear duplicados
vim.keymap.set("t", "<C-t>", [[<C-\><C-n><cmd>lua Snacks.terminal.toggle(nil, { id = "proyecto_term" })<CR>]], { desc = "Ocultar Terminal" })


vim.keymap.set("n", "<leader>m", function() 
  Snacks.picker.recent({ filter = { cwd = true } })() 
end, { desc = "Archivos recientes (Proyecto)" })

-- <leader>/ venía en LazyVim como "grep global", lo reasignamos a duplicar
vim.keymap.del("n", "<leader>/")

-- Duplica la línea actual (o el bloque seleccionado en visual) y deja el cursor
-- donde estaba, con la copia justo debajo. Usa la API en vez de `yyP`/`yA` para
-- que funcione igual coming de insert y entre en el historial de undo.
local function duplicar_linea()
  local bufnr = vim.api.nvim_get_current_buf()
  -- En normal `line("v")` es la línea actual; en visual son los extremos del bloque
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  local inicio, fin = math.min(a, b), math.max(a, b)
  local lineas = vim.api.nvim_buf_get_lines(bufnr, inicio - 1, fin, false)
  vim.api.nvim_buf_set_lines(bufnr, fin, fin, false, lineas)
end

vim.keymap.set({ "n", "v" }, "<leader>/", duplicar_linea, { desc = "Duplicar línea" })

vim.keymap.del("n", "<leader><leader>")

vim.keymap.set("n", "<leader>.", "V", { desc = "Seleccionar línea completa (Visual)" })

vim.keymap.set("n", "o", "w", { desc = "Ir al siguiente espacio/palabra" })
vim.keymap.set("n", "i", "b", { desc = "Ir al espacio/palabra anterior" })


vim.keymap.set("n", "<leader>l", "<cmd>wincmd l<cr>", { desc = "Mover focus al split derecho" })
vim.keymap.set("n", "<leader>k", "<cmd>wincmd h<cr>", { desc = "Mover focus al split izquierdo" })
-- 💡 Toggle inteligente entre ventana de Arriba y Abajo
vim.keymap.set({ "n", "t" }, "<leader>c", function()
  -- Obtiene el número de la ventana actual
  local current_win = vim.api.nvim_get_current_win()
  
  -- Intenta moverse hacia abajo de forma lógica
  vim.cmd("wincmd j")
  
  -- Si después de intentar moverse hacia abajo sigues en la misma ventana,
  -- significa que ya estás hasta abajo, por lo tanto te mueve hacia arriba.
  if vim.api.nvim_get_current_win() == current_win then
    vim.cmd("wincmd k")
  end
  
  -- Si caíste en una ventana de terminal, entra automáticamente en modo insertar
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end, { desc = "Toggle enfoque entre Arriba / Abajo" })


vim.keymap.set("n", "<leader>b", "<cmd>vsplit<cr>", { desc = "Split vertical" })
vim.keymap.set("n", "<leader>v", "<cmd>split<cr>", { desc = "Split horizontal" })

vim.keymap.set("n", "<leader>g", function() LazyVim.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false }) end, { desc = "Abrir LazyGit" })

-- Copiar la selección visual al portapapeles del sistema con <leader>y
vim.keymap.set("v", "<C-c>", '"+y', { desc = "Copiar con Ctrl+C" })


vim.keymap.set("n", "K", function()
  -- Usamos el comando hover del LSP
  vim.lsp.buf.hover()
end, { desc = "Ver documentación (Hover)" })

-- Toggle entre archivo actual y el anterior con Ctrl + Tab
vim.keymap.set("n", "<leader>j", function()
  vim.cmd("buffer #")
end, { desc = "Toggle entre archivos (Anterior/Actual)" })

vim.keymap.set("n", "<leader>u", function()
  -- Abre la definición en un split vertical a la derecha
  local cword = vim.fn.expand("<cword>")
  local params = vim.lsp.util.make_position_params()

  local handler = function(err, locations, ctx)
    local location = locations and locations[1]
    if err or not location then
      -- Fallback a etiqueta (tag) si el LSP no responde
      vim.cmd("silent! tag " .. cword)
      return
    end

    local uri = location.targetUri or location.uri
    local bufnr = vim.uri_to_bufnr(uri)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
      vim.fn.bufload(bufnr)
    end
    vim.bo[bufnr].buflisted = true

    local existing = vim.fn.bufwinid(bufnr)
    local win
    if existing ~= -1 then
      -- Ya está abierta en otra ventana: simplemente enfocarla
      win = existing
      vim.api.nvim_set_current_win(win)
    else
      -- Abrir split vertical nuevo a la derecha con el buffer objetivo
      vim.cmd("rightbelow vsplit")
      win = vim.api.nvim_get_current_win()
      vim.api.nvim_win_set_buf(win, bufnr)
    end

    local range = location.range or location.targetSelectionRange
    if range and win then
      local encoding = ctx.offset_encoding or "utf-16"
      local col = vim.lsp.util._get_line_byte_from_position(bufnr, range.start, encoding)
      vim.api.nvim_win_set_cursor(win, { range.start.line + 1, col })
      vim.cmd("normal! zv")
    end
  end

  vim.lsp.buf_request(0, "textDocument/definition", params, handler)
end, { desc = "Abrir definición en split derecho" })

-- C#: OmniSharp no autocompleta tipos no importados, solo ofrece la code action "using X;".
-- Esa accion llega sin 'edit': hay que pedir 'codeAction/resolve' y aplicar el cambio a mano
-- (Neovim no hace el resolve solo).
vim.keymap.set("n", "<leader>xu", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })[1]
  if not client then
    vim.notify("C#: no hay servidor LSP activo en este buffer", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(0)
  local lnum = cursor[1] - 1
  local palabra = vim.fn.expand("<cword>")
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = lnum, character = cursor[2] },
      ["end"] = { line = lnum, character = cursor[2] + vim.str_utfindex(palabra) },
    },
    context = { triggerKind = 1, diagnostics = {} },
  }

  local ns = vim.lsp.diagnostic.get_namespace(client.id)
  for _, diag in ipairs(vim.diagnostic.get(bufnr, { namespace = ns, lnum = lnum })) do
    if diag.user_data and diag.user_data.lsp then
      table.insert(params.context.diagnostics, diag.user_data.lsp)
    end
  end

  client:request("textDocument/codeAction", params, function(err, result)
    if err or not result then
      vim.notify("C#: OmniSharp no respondió la petición de code actions", vim.log.levels.WARN)
      return
    end

    local accion
    for _, item in ipairs(result) do
      if type(item.title) == "string" and item.title:match("^using%s+[%w%.]+;") then
        accion = item
        break
      end
    end

    if not accion then
      vim.notify(("C#: OmniSharp no sugiere ningún using para '%s'"):format(palabra), vim.log.levels.INFO)
      return
    end

    if accion.edit then
      vim.lsp.util.apply_workspace_edit(accion.edit, client.offset_encoding)
      return
    end

    client:request("codeAction/resolve", accion, function(resolve_err, resuelta)
      if resolve_err or not resuelta or not resuelta.edit then
        vim.notify("C#: no se pudo construir el cambio del using", vim.log.levels.WARN)
        return
      end
      vim.lsp.util.apply_workspace_edit(resuelta.edit, client.offset_encoding)
    end)
  end)
end, { desc = "Agregar el using que falta (C#)" })

vim.keymap.set({ "n", "v", "i" }, "<leader>o", function()
  vim.cmd("normal! $")
  if vim.fn.mode() == "i" then vim.cmd("startinsert") end
end, { desc = "Ir al final de la línea" })


vim.keymap.set({ "n", "v", "i" }, "<leader>i", function()
  vim.cmd("normal! ^")
  if vim.fn.mode() == "i" then vim.cmd("startinsert") end
end, { desc = "Ir al principio de la línea" })


vim.keymap.set({ "n", "v", "i" }, "<C-x>", function()
  if vim.fn.mode() == "i" then
    vim.cmd("normal! dd")
    vim.cmd("startinsert")
  else
    vim.cmd("normal! dd")
  end
end, { desc = "Cortar línea completa (Ctrl+X)" })

vim.keymap.set("n", "<leader>p", function()
  local dev_path = "C:/Users/Dell Precision/Documents/Dev"
  local projects = {}

  -- Función recursiva inteligente
  local function scan_for_projects(current_path, base_name)
    local handle = vim.fn.readdir(current_path)
    if not handle then return end

    local has_files = false
    local sub_dirs = {}

    -- Primera pasada: analizar qué contiene esta carpeta
    for _, name in ipairs(handle) do
      if name ~= ".git" and name ~= "node_modules" and name ~= ".idea" and name ~= ".metadata" then
        local full_path = current_path .. "/" .. name
        if vim.fn.isdirectory(full_path) == 1 then
          table.insert(sub_dirs, { path = full_path, name = name })
        else
          has_files = true -- ¡Encontramos un archivo suelto!
        end
      end
    end

    -- Regla de oro:
    if has_files then
      -- Si tiene archivos, es un proyecto real. Lo guardamos.
      table.insert(projects, { text = base_name, path = current_path, file = current_path })
    else
      -- Si NO tiene archivos pero sí subcarpetas, seguimos explorando más profundo
      for _, dir in ipairs(sub_dirs) do
        local next_base = base_name == "" and dir.name or (base_name .. "/" .. dir.name)
        scan_for_projects(dir.path, next_base)
      end
    end
  end

  -- Iniciar el escaneo desde la raíz de Dev
  scan_for_projects(dev_path, "")

  -- Ordenar la lista alfabéticamente para que se vea impecable
  table.sort(projects, function(a, b) return a.text:lower() < b.text:lower() end)

  -- Invocar Snacks Picker
  Snacks.picker.pick({
    source = "proyectos",
    title = "Mis Proyectos",
    items = projects,
    format = "text",
    layout = "select",
    preview = "none",
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.fn.chdir(item.path)
        Snacks.picker.files({ cwd = item.path })
      end
    end,
  })
end, { desc = "Explorador de proyectos inteligente" })



-----------------------------------------------------------------------------
---======================== LENGUAJES ====================================---
-----------------------------------------------------------------------------
-- Lanza `flutter run` en una ventana externa de Alacritty para ver los logs en vivo
local function flutter_run_external(device_id)
  local project_root = LazyVim.root()
  local alacritty = vim.fn.exepath("alacritty")

  if alacritty == "" then
    print("⚠️ No se encontró alacritty en el PATH. Instálalo con: winget install Alacritty")
    return
  end

  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local job_id = vim.fn.jobstart({
    alacritty,
    "--title",
    "Flutter Logs - " .. project_name,
    "--working-directory",
    project_root,
    "-e",
    "powershell",
    "-NoExit",
    "-Command",
    device_id and ("flutter run -d " .. device_id) or "flutter run",
  })

  if job_id > 0 then
    print(
      "🚀 flutter run iniciado en ventana «"
        .. project_name
        .. "». Logs en vivo ahí. Usa «r» para hot reload en esa ventana."
    )
  else
    print("⚠️ No se pudo abrir Alacritty (código " .. job_id .. ").")
  end
end

-- Detecta los dispositivos disponibles (emuladores, físicos, desktop, web) y lanza
-- `flutter run -d <id>` en la ventana externa de Alacritty sobre el dispositivo elegido
local function flutter_pick_device()
  print("⏳ Detectando dispositivos Flutter...")
  vim.system({ "flutter", "devices", "--machine" }, { cwd = LazyVim.root() }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        print("⚠️ No se pudo listar dispositivos: " .. vim.trim(out.stderr or ""))
        return
      end

      local ok, devices = pcall(vim.json.decode, out.stdout)
      if not ok or type(devices) ~= "table" then
        print("⚠️ No se pudo leer la lista de dispositivos de Flutter.")
        return
      end

      local items = {}
      for _, dev in ipairs(devices) do
        if dev.isSupported then
          table.insert(items, {
            id = dev.id,
            text = dev.name .. " (" .. (dev.targetPlatform or dev.type or "desktop") .. ")",
            detail = dev.id .. (dev.emulator and " — emulador" or "") .. " • " .. (dev.sdk or ""),
          })
        end
      end

      if vim.tbl_isempty(items) then
        print(
          "⚠️ No hay dispositivos conectados. Abre un emulador o conecta tu teléfono (USB debugging activado)."
        )
        return
      end

      Snacks.picker.pick({
        source = "flutter_devices",
        title = "📱 Elige dispositivo",
        items = items,
        format = "text",
        layout = "select",
        confirm = function(picker, item)
          picker:close()
          if item then
            flutter_run_external(item.id)
          end
        end,
      })
    end)
  end)
end

local function smart_dev_menu()
  local root = LazyVim.root()
  local ft = vim.bo.filetype
  local cwd = vim.uv.cwd()

  -- Detectar por archivos marcadores en root
  local function has_marker(pattern)
    local ok, res = pcall(vim.fn.glob, root .. "/" .. pattern)
    if ok and res ~= "" then return true end
    return false
  end

  local is_dotnet = has_marker("*.sln") or has_marker("*.csproj") or ft == "cs" or ft == "csharp" or ft == "vb" or ft == "fsharp"
  local is_flutter = has_marker("pubspec.yaml") or has_marker("flutter.yaml") or has_marker("melos.yaml") or ft == "dart" or ft == "flutter"

  -- Si no detecta por root, también mirar cwd
  if not is_dotnet and not is_flutter then
    local function has_cwd(p)
      local ok, res = pcall(vim.fn.glob, cwd .. "/" .. p)
      if ok and res ~= "" then return true end
      return false
    end
    is_dotnet = has_cwd("*.sln") or has_cwd("*.csproj")
    is_flutter = has_cwd("pubspec.yaml") or has_cwd("flutter.yaml")
  end

  if is_dotnet and not is_flutter then
    -- Mostrar menú .NET
    local dotnet_actions = {
      { text = "▶️  Dotnet Run (Abrir ventana)", run_app = true },
      { text = "🔄 REINICIAR (Reload en la misma ventana)", restart_app = true },
      { text = "🔴  Compilar y mostrar errores", build_errors = true },
      { text = "🛑 Cerrar terminal de dotnet activa", kill_all = true },
    }
    Snacks.picker.pick({
      source = "dotnet_commands",
      title = "󰏗 Comandos .NET",
      items = dotnet_actions,
      format = "text",
      layout = "select",
      confirm = function(picker, item)
        picker:close()
        if item then
          if item.run_app or item.restart_app then
            restart_dotnet_server()
          elseif item.build_errors then
            dotnet_build_errors()
          elseif item.kill_all then
            if _G.dotnet_alacritty_pid then
              vim.fn.jobstart("taskkill /F /T /PID " .. _G.dotnet_alacritty_pid)
              _G.dotnet_alacritty_pid = nil
              print("🛑 Terminal externa destruida de forma segura.")
            else
              print("⚠️ No hay ninguna terminal de .NET registrada activa.")
            end
          end
        end
      end,
    })
    return
  end

  if is_flutter and not is_dotnet then
    local flutter_actions = {
      { text = "📱 Iniciar: Resizable (Experimental)", avd = "Resizable_Experimental" },
      { text = "📱 Iniciar: Resizable (Experimental) (2)", avd = "Resizable_Experimental_2" },
      { text = "▶️  Iniciar App (Elegir dispositivo)", run_app = true },
      { text = "🔄 Hot Restart (Reinicio completo)", cmd = "FlutterRestart" },
      { text = "🔌 Select Device (Cambiar dispositivo activo)", cmd = "FlutterDevices" },
      { text = "🛑 Quit Application (Detener app)", cmd = "FlutterQuit" },
    }
    Snacks.picker.pick({
      source = "flutter_commands",
      title = "⚡ Comandos Flutter",
      items = flutter_actions,
      format = "text",
      layout = "select",
      confirm = function(picker, item)
        picker:close()
        if item then
          if item.avd then
            vim.fn.jobstart("emulator -avd " .. item.avd)
            print("🚀 Levantando emulador nativo: " .. item.avd)
          elseif item.run_app then
            flutter_pick_device()
          elseif item.cmd then
            pcall(function() vim.cmd(item.cmd) end)
          end
        end
      end,
    })
    return
  end

  if is_flutter and is_dotnet then
    -- Doble detección: priorizar por filetype si es claro
    if ft == "cs" or ft == "csharp" then
      smart_dev_menu_dotnet_like()
      return
    end
    if ft == "dart" then
      smart_dev_menu_flutter_like()
      return
    end
    -- Si no claro, preguntar
    Snacks.picker.pick({
      source = "dev_menu_choice",
      title = "¿Qué menú abrir?",
      items = {
        { text = "󰏗 .NET", choice = "dotnet" },
        { text = "⚡ Flutter", choice = "flutter" },
      },
      format = "text",
      layout = "select",
      confirm = function(picker, item)
        picker:close()
        if item.choice == "dotnet" then
          smart_dev_menu_dotnet_like()
        else
          smart_dev_menu_flutter_like()
        end
      end,
    })
    return
  end

  -- Sin detección clara
  vim.notify("No se detectó .NET ni Flutter en este proyecto/buffer", vim.log.levels.WARN)
end

local function smart_dev_menu_dotnet_like()
  local dotnet_actions = {
    { text = "▶️  Dotnet Run (Abrir ventana)", run_app = true },
    { text = "🔄 REINICIAR (Reload en la misma ventana)", restart_app = true },
    { text = "🔴  Compilar y mostrar errores", build_errors = true },
    { text = "🛑 Cerrar terminal de dotnet activa", kill_all = true },
  }
  Snacks.picker.pick({
    source = "dotnet_commands",
    title = "󰏗 Comandos .NET",
    items = dotnet_actions,
    format = "text",
    layout = "select",
    confirm = function(picker, item)
      picker:close()
      if item then
        if item.run_app or item.restart_app then
          restart_dotnet_server()
        elseif item.build_errors then
          dotnet_build_errors()
        elseif item.kill_all then
          if _G.dotnet_alacritty_pid then
            vim.fn.jobstart("taskkill /F /T /PID " .. _G.dotnet_alacritty_pid)
            _G.dotnet_alacritty_pid = nil
            print("🛑 Terminal externa destruida de forma segura.")
          else
            print("⚠️ No hay ninguna terminal de .NET registrada activa.")
          end
        end
      end
    end,
  })
end

local function smart_dev_menu_flutter_like()
  local flutter_actions = {
    { text = "📱 Iniciar: Resizable (Experimental)", avd = "Resizable_Experimental" },
    { text = "📱 Iniciar: Resizable (Experimental) (2)", avd = "Resizable_Experimental_2" },
    { text = "▶️  Iniciar App (Elegir dispositivo)", run_app = true },
    { text = "🔄 Hot Restart (Reinicio completo)", cmd = "FlutterRestart" },
    { text = "🔌 Select Device (Cambiar dispositivo activo)", cmd = "FlutterDevices" },
    { text = "🛑 Quit Application (Detener app)", cmd = "FlutterQuit" },
  }
  Snacks.picker.pick({
    source = "flutter_commands",
    title = "⚡ Comandos Flutter",
    items = flutter_actions,
    format = "text",
    layout = "select",
    confirm = function(picker, item)
      picker:close()
      if item then
        if item.avd then
          vim.fn.jobstart("emulator -avd " .. item.avd)
          print("🚀 Levantando emulador nativo: " .. item.avd)
        elseif item.run_app then
          flutter_pick_device()
        elseif item.cmd then
          pcall(function() vim.cmd(item.cmd) end)
        end
      end
    end,
  })
end

vim.keymap.set("n", "<leader>f", smart_dev_menu, { desc = "Menú por lenguaje detectado" })


-- Función para reiniciar el servidor .NET en Alacritty externa
local function restart_dotnet_server()
  local project_root = LazyVim.root()
  
  print("🔄 Deteniendo servidores activos y reiniciando...")
  
  -- 1. Matamos cualquier proceso de dotnet colgado en Windows para liberar puertos
  vim.fn.jobstart("taskkill /F /IM dotnet.exe", {
    on_exit = function()
      -- 2. Una vez limpio, levantamos la nueva ventana externa inmediatamente
      vim.fn.jobstart({
        "alacritty",
        "--working-directory", project_root,
        "-e", "powershell", "-NoExit", "-Command", "dotnet run"
      })
      print("🚀 ¡Servidor .NET reiniciado con éxito!")
    end
  })
end

_G.dotnet_alacritty_pid = _G.dotnet_alacritty_pid or nil

-- Abre la ventana Alacritty con un bucle que mantiene el servidor corriendo sin cerrarla
local function open_dotnet_window()
  local project_root = LazyVim.root()
  local alacritty = vim.fn.exepath("alacritty")

  if alacritty == "" then
    print("⚠️ No se encontró alacritty en el PATH. Instálalo con: winget install Alacritty")
    return
  end

  local job_id = vim.fn.jobstart({
    alacritty,
    "--title",
    "Dotnet Server - " .. vim.fn.fnamemodify(project_root, ":t"),
    "--working-directory",
    project_root,
    "-e",
    "powershell",
    "-NoExit",
    "-Command",
    "while ($true) { dotnet run; Start-Sleep -Seconds 2 }",
  })

  if job_id > 0 then
    _G.dotnet_alacritty_pid = vim.fn.jobpid(job_id)
  end
end

-- Comprueba si la ventana Alacritty del servidor sigue viva
local function dotnet_window_alive()
  if not _G.dotnet_alacritty_pid then
    return false
  end

  local out = vim.fn.system(
    'powershell -NoProfile -Command "[bool](Get-Process -Id '
      .. _G.dotnet_alacritty_pid
      .. ' -ErrorAction SilentlyContinue)"'
  )
  return vim.trim(out) == "True"
end

-- Reinicia el servidor .NET en la MISMA ventana: mata dotnet.exe y el bucle lo relanza
local function restart_dotnet_server()
  if _G.dotnet_alacritty_pid and dotnet_window_alive() then
    print("🔄 Reiniciando servidor .NET (misma ventana)...")
    vim.fn.jobstart("taskkill /F /IM dotnet.exe")
  else
    _G.dotnet_alacritty_pid = nil
    open_dotnet_window()
  end
end

-- Compila el proyecto y muestra los errores en un picker con salto directo al error
local function dotnet_build_errors()
  local dir = LazyVim.root()
  local chunks = {}

  local function show_errors(code)
    vim.schedule(function()
      local items = {}
      local errors = 0
      local full = table.concat(chunks, "")

      for line in full:gmatch("[^\r\n]+") do
        -- Formato: C:\ruta\archivo.cs(12,5): error CS1002: ; expected
        local path, lnum, col, severity, code_, msg
          = line:match("^(.+)%((%d+)%s*,%s*(%d+)%):%s*(%a+)%s+([^:]+):%s*(.*)$")
        if path and severity == "error" then
          errors = errors + 1
          items[#items + 1] = {
            filename = vim.trim(path),
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = severity .. " " .. code_ .. ": " .. msg,
            type = "E",
          }
        end
      end

      if #items == 0 then
        vim.notify("🎉 Compilación sin errores (dotnet build, código " .. code .. ")", vim.log.levels.INFO)
        return
      end

      vim.fn.setqflist({}, "r", { items = items, title = "dotnet build" })
      Snacks.picker.qflist({
        title = "🔴 Errores dotnet build (" .. errors .. " error/es)",
      })
    end)
  end

  vim.fn.jobstart({ "dotnet", "build", "--nologo", "-v", "q" }, {
    cwd = dir,
    on_stdout = function(_, data)
      vim.list_extend(chunks, data)
    end,
    on_stderr = function(_, data)
      vim.list_extend(chunks, data)
    end,
    on_exit = function(_, code)
      show_errors(code)
    end,
  })
end

vim.keymap.set("n", "<leader>dr", restart_dotnet_server, { desc = "Dotnet: Reiniciar Servidor (misma ventana)" })

vim.keymap.set("n", "<leader>de", dotnet_build_errors, { desc = "Dotnet: Compilar y mostrar errores" })

vim.keymap.set("n", "<leader>d", function()
  local dotnet_actions = {
    { text = "▶️  Dotnet Run (Abrir ventana)", run_app = true },
    { text = "🔄 REINICIAR (Reload en la misma ventana)", restart_app = true },
    { text = "🔴  Compilar y mostrar errores", build_errors = true },
    { text = "🛑 Cerrar terminal de dotnet activa", kill_all = true },
  }

  Snacks.picker.pick({
    source = "dotnet_commands",
    title = "󰏗 Comandos .NET",
    items = dotnet_actions,
    format = "text",
    layout = "select",
    confirm = function(picker, item)
      picker:close()
      if item then
        if item.run_app or item.restart_app then
          restart_dotnet_server()
        elseif item.build_errors then
          dotnet_build_errors()
        elseif item.kill_all then
          if _G.dotnet_alacritty_pid then
            vim.fn.jobstart("taskkill /F /T /PID " .. _G.dotnet_alacritty_pid)
            _G.dotnet_alacritty_pid = nil
            print("🛑 Terminal externa destruida de forma segura.")
          else
            print("⚠️ No hay ninguna terminal de .NET registrada activa.")
          end
        end
      end
    end,
  })
end, { desc = "Menú interactivo de .NET" })
