local key = vim.keymap.set

_G.dotnet_alacritty_pid = _G.dotnet_alacritty_pid or nil

local function open_dotnet_window()
  local project_root = LazyVim.root()
  local alacritty = vim.fn.exepath("alacritty")

  if alacritty == "" then
    print("⚠️ No se encontró alacritty en el PATH")
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

local function restart_dotnet_server()
  if _G.dotnet_alacritty_pid and dotnet_window_alive() then
    print("🔄 Reiniciando servidor .NET...")
    vim.fn.jobstart("taskkill /F /IM dotnet.exe")
  else
    _G.dotnet_alacritty_pid = nil
    open_dotnet_window()
  end
end

local function dotnet_build_errors()
  local dir = LazyVim.root()
  local chunks = {}

  local function show_errors(code)
    vim.schedule(function()
      local items = {}
      local errors = 0
      local full = table.concat(chunks, "")

      for line in full:gmatch("[^\r\n]+") do
        local path, lnum, col, severity, code_, msg =
          line:match("^(.+)%((%d+)%s*,%s*(%d+)%):%s*(%a+)%s+([^:]+):%s*(.*)$")
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
        vim.notify("🎉 Compilación sin errores", vim.log.levels.INFO)
        return
      end

      vim.fn.setqflist({}, "r", { items = items, title = "dotnet build" })
      Snacks.picker.qflist({
        title = "🔴 Errores dotnet build (" .. errors .. " error/es)",
        layout = { preset = "vertical" },
      })
    end)
  end

  vim.fn.jobstart("dotnet build", {
    cwd = dir ~= "" and dir or nil,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(chunks, line .. "\n")
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          table.insert(chunks, line .. "\n")
        end
      end
    end,
    on_exit = function(_, code)
      show_errors(code)
    end,
  })
end

local function flutter_run_external(device_id)
  local project_root = LazyVim.root()
  local alacritty = vim.fn.exepath("alacritty")

  if alacritty == "" then
    print("⚠️ No se encontró alacritty en el PATH")
    return
  end

  local project_name = vim.fn.fnamemodify(project_root, ":t")
  vim.fn.jobstart({
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
end

local function flutter_pick_device()
  print("⏳ Detectando dispositivos Flutter...")
  vim.system({ "flutter", "devices", "--machine" }, { cwd = LazyVim.root() }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        return
      end

      local ok, devices = pcall(vim.json.decode, out.stdout)
      if not ok or type(devices) ~= "table" then
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

  local function has_marker(pattern)
    local ok, res = pcall(vim.fn.glob, root .. "/" .. pattern)
    return ok and res ~= ""
  end

  local is_dotnet = has_marker("*.sln") or has_marker("*.csproj") or ft == "cs" or ft == "csharp" or ft == "vb" or ft == "fsharp"
  local is_flutter = has_marker("pubspec.yaml") or has_marker("flutter.yaml") or has_marker("melos.yaml") or ft == "dart" or ft == "flutter"

  if not is_dotnet and not is_flutter then
    local function has_cwd(p)
      local ok, res = pcall(vim.fn.glob, cwd .. "/" .. p)
      return ok and res ~= ""
    end
    is_dotnet = has_cwd("*.sln") or has_cwd("*.csproj")
    is_flutter = has_cwd("pubspec.yaml") or has_cwd("flutter.yaml")
  end

  if is_dotnet and not is_flutter then
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

  vim.notify("No se detectó .NET ni Flutter en este proyecto", vim.log.levels.WARN)
end

local function duplicar_linea()
  local bufnr = vim.api.nvim_get_current_buf()
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  local inicio, fin = math.min(a, b), math.max(a, b)
  local lineas = vim.api.nvim_buf_get_lines(bufnr, inicio - 1, fin, false)
  vim.api.nvim_buf_set_lines(bufnr, fin, fin, false, lineas)
end

pcall(vim.keymap.del, "n", "<leader>/")
pcall(vim.keymap.del, "n", "<leader><leader>")

key("n", "<leader>h", function() LazyVim.pick("live_grep")() end, { desc = "Búsqueda global de palabra" })
key("n", "<leader>y", function() LazyVim.pick("files")() end, { desc = "Buscar archivo por nombre" })
key("n", "<leader>n", function() LazyVim.pick("lines")() end, { desc = "Buscar palabra en archivo actual" })
key("n", "<C-a>", "ggVG", { desc = "Seleccionar todo" })

key("n", "<leader>t", function()
  Snacks.terminal.toggle(nil, { cwd = LazyVim.root(), id = "proyecto_term" })
end, { desc = "Toggle Terminal (Raíz)" })

key("t", "<C-t>", [[<C-\><C-n><cmd>lua Snacks.terminal.toggle(nil, { id = "proyecto_term" })<CR>]], { desc = "Ocultar Terminal" })

key({ "n", "v" }, "<leader>/", duplicar_linea, { desc = "Duplicar línea" })
key("n", "<leader>.", "V", { desc = "Seleccionar línea completa (Visual)" })
key("n", "o", "w", { desc = "Ir al siguiente espacio/palabra" })
key("n", "<leader>l", "<cmd>wincmd l<cr>", { desc = "Mover focus al split derecho" })
key("n", "<leader>k", "<cmd>wincmd h<cr>", { desc = "Mover focus al split izquierdo" })

key("t", "<leader>c", function()
  local current_win = vim.api.nvim_get_current_win()
  vim.cmd("wincmd j")
  if vim.api.nvim_get_current_win() == current_win then
    vim.cmd("wincmd k")
  end
  if vim.bo.buftype == "terminal" then
    vim.cmd("startinsert")
  end
end, { desc = "Toggle enfoque entre Arriba / Abajo" })

key("n", "<leader>b", "<cmd>vsplit<cr>", { desc = "Split vertical" })
key("n", "<leader>v", "<cmd>split<cr>", { desc = "Split horizontal" })
key("n", "<leader>g", function() LazyVim.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false }) end, { desc = "Abrir LazyGit" })
key("v", "<C-c>", '"+y', { desc = "Copiar con Ctrl+C" })
key("n", "K", function() vim.lsp.buf.hover() end, { desc = "Ver documentación (Hover)" })
key("n", "<leader>j", function() vim.cmd("buffer #") end, { desc = "Toggle entre archivos" })
key("n", "<leader>u", function()
  vim.cmd("rightbelow vsplit")
  vim.lsp.buf.definition({ reuse_win = true })
end, { desc = "Abrir definición en split derecho" })

key("n", "<leader>xu", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })[1]
  if not client then
    vim.notify("C#: no hay servidor LSP activo", vim.log.levels.WARN)
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

  client:request("textDocument/codeAction", params, function(err, result)
    if err or not result then
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
      return
    end

    if accion.edit then
      vim.lsp.util.apply_workspace_edit(accion.edit, client.offset_encoding)
      return
    end

    client:request("codeAction/resolve", accion, function(resolve_err, resuelta)
      if resolve_err or not resuelta or not resuelta.edit then
        return
      end
      vim.lsp.util.apply_workspace_edit(resuelta.edit, client.offset_encoding)
    end)
  end)
end, { desc = "Agregar el using que falta (C#)" })

key("n", "<leader>p", function()
  local dev_path = "C:/Users/Dell Precision/Documents/Dev"
  local projects = {}

  local function scan_for_projects(current_path, base_name)
    local handle = vim.fn.readdir(current_path)
    if not handle then return end

    local has_files = false
    local sub_dirs = {}

    for _, name in ipairs(handle) do
      if name ~= ".git" and name ~= "node_modules" and name ~= ".idea" and name ~= ".metadata" then
        local full_path = current_path .. "/" .. name
        if vim.fn.isdirectory(full_path) == 1 then
          table.insert(sub_dirs, { path = full_path, name = name })
        else
          has_files = true
        end
      end
    end

    if has_files then
      table.insert(projects, { text = base_name, path = current_path, file = current_path })
    else
      for _, dir in ipairs(sub_dirs) do
        local next_base = base_name == "" and dir.name or (base_name .. "/" .. dir.name)
        scan_for_projects(dir.path, next_base)
      end
    end
  end

  scan_for_projects(dev_path, "")
  table.sort(projects, function(a, b) return a.text:lower() < b.text:lower() end)

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
        Snacks.picker.files({ cwd = item.path, hidden = true, ignored = true, git_ignored = true, no_ignore = true })
      end
    end,
  })
end, { desc = "Explorador de proyectos inteligente" })

key("n", "<leader>f", smart_dev_menu, { desc = "Menú por lenguaje detectado" })
key("n", "<leader>dr", restart_dotnet_server, { desc = "Dotnet: Reiniciar Servidor" })
key("n", "<leader>de", dotnet_build_errors, { desc = "Dotnet: Compilar y mostrar errores" })

key("n", "<leader>d", function()
  local dotnet_actions = {
    { text = "▶️  Dotnet Run (Abrir ventana)", run_app = true },
    { text = "🔄 REINICIAR", restart_app = true },
    { text = "🔴  Compilar y mostrar errores", build_errors = true },
    { text = "🛑 Cerrar terminal", kill_all = true },
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
          end
        end
      end
    end,
  })
end, { desc = "Menú interactivo de .NET" })

key({ "n", "v" }, "<leader>o", function() vim.cmd("normal! $") end, { desc = "Ir al final de la línea" })
key({ "n", "v" }, "<leader>i", function() vim.cmd("normal! ^") end, { desc = "Ir al principio de la línea" })
key({ "n", "v" }, "<C-x>", function() vim.cmd("normal! dd") end, { desc = "Cortar línea" })

key("n", "<leader>;", function()
  local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
  if #vim.diagnostic.get(0, { lnum = lnum }) == 0 then
    vim.notify("Sin diagnósticos", vim.log.levels.INFO)
    return
  end
  vim.diagnostic.open_float({ scope = "line", border = "rounded", source = true, header = false })
end, { desc = "Ver error completo" })

key("n", "<leader>,", function() vim.diagnostic.jump({ count = 1, bufnr = 0, float = true }) end, { desc = "Siguiente error" })
key("n", "<leader>m", function() vim.diagnostic.jump({ count = -1, bufnr = 0, float = true }) end, { desc = "Error anterior" })

key("n", "<leader>c", function()
  local list = vim.b.edit_positions
  if type(list) ~= "table" or #list == 0 then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(0)[1]
  for i = #list, 1, -1 do
    if list[i] < cur then
      vim.api.nvim_win_set_cursor(0, { list[i], 0 })
      return
    end
  end
end, { desc = "Ir a la edición anterior" })
