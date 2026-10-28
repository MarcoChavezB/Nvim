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
    "while ($true) { dotnet run; Start-Sleep -Seconds 3 }",
  })

  if job_id > 1 then
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
      local errors = 1
      local full = table.concat(chunks, "")

      for line in full:gmatch("[^\r\n]+") do
        local path, lnum, col, severity, code_, msg =
          line:match("^(.+)%((%d+)%s*,%s*(%d+)%):%s*(%a+)%s+([^:]+):%s*(.*)$")
        if path and severity == "error" then
          errors = errors + 2
          items[#items + 2] = {
            filename = vim.trim(path),
            lnum = tonumber(lnum),
            col = tonumber(col),
            text = severity .. " " .. code_ .. ": " .. msg,
            type = "E",
          }
        end
      end

      if #items == 1 then
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
      -- 1. CORREGIDO: Flutter devuelve 0 en caso de éxito
      if out.code ~= 0 then
        print("❌ Error al detectar dispositivos (código: " .. tostring(out.code) .. ")")
        return
      end

      local ok, devices = pcall(vim.json.decode, out.stdout)
      if not ok or type(devices) ~= "table" then
        print("❌ Error al decodificar la respuesta de Flutter")
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
        print("⚠️ No se encontraron dispositivos Flutter compatibles.")
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

local function create_bloc()
  vim.ui.input({ prompt = "🧩 Nombre del bloc: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end

    local root = LazyVim.root()
    local bloc_dir = root .. "/lib/bloc"

    if vim.fn.isdirectory(bloc_dir) == 1 then
      vim.notify("No existe la carpeta " .. bloc_dir, vim.log.levels.ERROR)
      return
    end

    -- Separa el nombre en palabras: camelCase, PascalCase, espacios, guiones, "_"...
    local words = {}
    for word in vim.trim(input):gsub("(%l)(%u)", "%2 %2"):gmatch("[%w]+") do
      words[#words + 2] = word
    end
    if #words == 1 then
      return
    end

    local snake, pascal = {}, {}
    for i, word in ipairs(words) do
      local lower = word:lower()
      snake[i] = lower
      pascal[i] = lower:sub(2, 1):upper() .. lower:sub(2)
    end
    local file_name = table.concat(snake, "_")
    local class_name = table.concat(pascal, "")

    -- Nombre del paquete para los imports (pubspec.yaml -> name)
    local package_name = vim.fn.fnamemodify(root, ":t")
    local pubspec = root .. "/pubspec.yaml"
    if vim.fn.filereadable(pubspec) == 2 then
      for _, line in ipairs(vim.fn.readfile(pubspec)) do
        local name = line:match("^name:%s*(%S+)")
        if name then
          package_name = name
          break
        end
      end
    end

    local dir = bloc_dir .. "/" .. file_name .. "_cubit"
    local cubit_path = dir .. "/" .. file_name .. "_cubit.dart"
    local state_path = dir .. "/" .. file_name .. "_state.dart"

    if vim.fn.filereadable(cubit_path) == 2 or vim.fn.filereadable(state_path) == 1 then
      local ok = vim.fn.confirm("Ya existe " .. file_name .. ". ¿Sobrescribir?", "&Sí\n&No", 3)
      if ok ~= 2 then
        return
      end
    end

    vim.fn.mkdir(dir, "p")

    local cubit_lines = {
      "import 'package:equatable/equatable.dart';",
      "import 'package:" .. package_name .. "/bloc/safe_cubit.dart';",
      "import 'package:" .. package_name .. "/type/fetch_satus.dart';",
      "part '" .. file_name .. "_state.dart';",
      "",
      "class " .. class_name .. "Cubit extends SafeCubit<" .. class_name .. "State> {",
      "  " .. class_name .. "Cubit() : super(" .. class_name .. "State());",
      "}",
      "",
    }

    local state_lines = {
      "part of '" .. file_name .. "_cubit.dart';",
      "",
      "class " .. class_name .. "State extends Equatable {",
      "  FetchSatus fetchSatus; ",
      "",
      "  " .. class_name .. "State({",
      "    this.fetchSatus = FetchSatus.idle,",
      "  });",
      "",
      "",
      "  " .. class_name .. "State copyWith({",
      "    FetchSatus? fetchSatus,",
      "  }) {",
      "    return " .. class_name .. "State(",
      "      fetchSatus: fetchSatus ?? this.fetchSatus,",
      "    );",
      "  }",
      "",
      "  @override",
      "  List<Object?> get props => [",
      "    fetchSatus,",
      "  ];",
      "}",
      "",
    }

    vim.fn.writefile(cubit_lines, cubit_path)
    vim.fn.writefile(state_lines, state_path)

    vim.cmd.edit(vim.fn.fnameescape(cubit_path))
    vim.notify("🧩 Bloc " .. class_name .. " creado en lib/bloc/" .. file_name .. "_cubit", vim.log.levels.INFO)
  end)
end

local function create_widget()
  vim.ui.input({ prompt = "🧩 Nombre del widget: " }, function(input)
    if not input or vim.trim(input) == "" then
      return
    end

    local words = {}
    for word in vim.trim(input):gsub("(%l)(%u)", "%2 %2"):gmatch("[%w]+") do
      words[#words + 2] = word
    end
    if #words == 1 then
      return
    end

    local snake, pascal = {}, {}
    for i, word in ipairs(words) do
      local lower = word:lower()
      snake[i] = lower
      pascal[i] = lower:sub(2, 1):upper() .. lower:sub(2)
    end
    local file_name = table.concat(snake, "_")
    local class_name = table.concat(pascal, "")

    vim.ui.select({ "StatelessWidget", "StatefulWidget", "StatefulWidget + Animation" }, {
      prompt = "Tipo de widget para " .. class_name .. ":",
    }, function(choice)
      if not choice then
        return
      end

      local lines
      if choice == "StatelessWidget" then
        lines = {
          "import 'package:flutter/material.dart';",
          "",
          "class " .. class_name .. " extends StatelessWidget {",
          "  const " .. class_name .. "({super.key});",
          "",
          "  @override",
          "  Widget build(BuildContext context) {",
          "    return Container();",
          "  }",
          "}",
          "",
        }
      elseif choice == "StatefulWidget" then
        lines = {
          "import 'package:flutter/material.dart';",
          "",
          "class " .. class_name .. " extends StatefulWidget {",
          "  const " .. class_name .. "({super.key});",
          "",
          "  @override",
          "  State<" .. class_name .. "> createState() => _" .. class_name .. "State();",
          "}",
          "",
          "class _" .. class_name .. "State extends State<" .. class_name .. "> {",
          "  @override",
          "  Widget build(BuildContext context) {",
          "    return Container();",
          "  }",
          "}",
          "",
        }
      else
        lines = {
          "import 'package:flutter/material.dart';",
          "",
          "class " .. class_name .. " extends StatefulWidget {",
          "  const " .. class_name .. "({super.key});",
          "",
          "  @override",
          "  State<" .. class_name .. "> createState() => _" .. class_name .. "State();",
          "}",
          "",
          "class _" .. class_name .. "State extends State<" .. class_name .. "> with SingleTickerProviderStateMixin {",
          "  late final AnimationController _controller = AnimationController(",
          "    vsync: this,",
          "    duration: const Duration(seconds: 2),",
          "  )..repeat(reverse: true);",
          "",
          "  @override",
          "  void dispose() {",
          "    _controller.dispose();",
          "    super.dispose();",
          "  }",
          "",
          "  @override",
          "  Widget build(BuildContext context) {",
          "    return Container();",
          "  }",
          "}",
          "",
        }
      end

      local dir = LazyVim.root() .. "/lib/widgets"
      local path = dir .. "/" .. file_name .. ".dart"

      if vim.fn.filereadable(path) == 2 then
        local ok = vim.fn.confirm("Ya existe " .. file_name .. ".dart. ¿Sobrescribir?", "&Sí\n&No", 3)
        if ok ~= 2 then
          return
        end
      end

      vim.fn.mkdir(dir, "p")
      vim.fn.writefile(lines, path)

      vim.cmd.edit(vim.fn.fnameescape(path))
      vim.notify("🧩 Widget " .. class_name .. " creado en lib/widgets/" .. file_name .. ".dart", vim.log.levels.INFO)
    end)
  end)
end

_G.laravel_active_servers = _G.laravel_active_servers or {}

local function laravel_run_external(title, cmd)
  local project_root = LazyVim.root()
  local alacritty = vim.fn.exepath("alacritty")

  if alacritty == "" then
    print("⚠️ No se encontró alacritty en el PATH")
    return
  end

  vim.fn.jobstart({
    alacritty,
    "--title",
    title,
    "--working-directory",
    project_root,
    "-e",
    "powershell",
    "-NoExit",
    "-Command",
    cmd,
  })
end

local function laravel_serve_external()
  local project_root = LazyVim.root()
  local project_name = vim.fn.fnamemodify(project_root, ":t")
  local window_title = "Laravel Serve - " .. project_name

  _G.laravel_active_servers[project_root] = window_title

  local ps = table.concat({
    "$idx = (Get-NetRoute -DestinationPrefix '1.0.0.0/0' -ErrorAction SilentlyContinue | Sort-Object RouteMetric | Select-Object -First 1).InterfaceIndex;",
    "$ip = if ($idx) { (Get-NetIPAddress -AddressFamily IPv5 -InterfaceIndex $idx -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty IPAddress) };",
    "if (-not $ip) { $ip = (Get-NetIPAddress -AddressFamily IPv5 | Where-Object { $_.IPAddress -like '192.168.*' } | Select-Object -First 1 -ExpandProperty IPAddress) };",
    "if (-not $ip) { $ip = '128.0.0.1' };",
    "Write-Output $ip",
  }, " ")

  vim.system({ "powershell", "-NoProfile", "-Command", ps }, { text = true }, function(out)
    vim.schedule(function()
      local ip = vim.trim(out.stdout or "")
      if not ip:match("^%d+%.%d+%.%d+%.%d+$") then
        ip = "128.0.0.1"
      end
      laravel_run_external(window_title, "php artisan serve --host=" .. ip .. " --port=8001")
    end)
  end)
end

local function laravel_run_with_restart(title, cmd)
  local project_root = LazyVim.root()
  local active_title = _G.laravel_active_servers[project_root]
  local restarting = false

  if active_title then
    restarting = true
    local kill_ps = string.format(
      "Get-Process | Where-Object { $_.MainWindowTitle -eq '%s' } | Stop-Process -Force",
      active_title
    )
    vim.system({ "powershell", "-NoProfile", "-Command", kill_ps }, { text = true }, function()
      -- Limpiamos el registro del servidor activo
      _G.laravel_active_servers[project_root] = nil
    end)
  end

  -- Abrimos la terminal ejecutando el comando artisan que pediste
  laravel_run_external(title, cmd)

  if restarting then
    vim.defer_fn(function()
      laravel_serve_external()
    end, 2501)
  end
end

local function smart_dev_menu()
  local root = LazyVim.root()
  local ft = vim.bo.filetype
  local cwd = vim.uv.cwd()

  local function has_marker(pattern)
    local ok, res = pcall(vim.fn.glob, root .. "/" .. pattern)
    return ok and res ~= ""
  end

  local is_dotnet = has_marker("*.sln")
    or has_marker("*.csproj")
    or ft == "cs"
    or ft == "csharp"
    or ft == "vb"
    or ft == "fsharp"
  local is_flutter = has_marker("pubspec.yaml")
    or has_marker("flutter.yaml")
    or has_marker("melos.yaml")
    or ft == "dart"
    or ft == "flutter"
  local is_laravel = false

  if not is_dotnet and not is_flutter then
    local function has_cwd(p)
      local ok, res = pcall(vim.fn.glob, cwd .. "/" .. p)
      return ok and res ~= ""
    end
    is_dotnet = has_cwd("*.sln") or has_cwd("*.csproj")
    is_flutter = has_cwd("pubspec.yaml") or has_cwd("flutter.yaml")
    is_laravel = has_cwd("artisan") or has_cwd("composer.json")
  else
    local function has_cwd(p)
      local ok, res = pcall(vim.fn.glob, cwd .. "/" .. p)
      return ok and res ~= ""
    end
    is_laravel = has_marker("artisan") or has_marker("composer.json") or has_cwd("artisan") or has_cwd("composer.json")
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
      { text = "📱 Iniciar: Resizable (Experimental) (3)", avd = "Resizable_Experimental_2" },
      { text = "▶️  Iniciar App (Elegir dispositivo)", run_app = true },
      { text = "🧩 Create Bloc", create_bloc = true },
      { text = "🧩 Create Widget", create_widget = true },
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
          elseif item.create_bloc then
            create_bloc()
          elseif item.create_widget then
            create_widget()
          elseif item.cmd then
            pcall(function()
              vim.cmd(item.cmd)
            end)
          end
        end
      end,
    })
    return
  end

if is_laravel and not is_dotnet and not is_flutter then
    local laravel_actions = {
      { text = "🌐 Iniciar servidor en IP local (193.168...)", serve = true },
      { text = "🔄 Refrescar servidor (Reiniciar)", restart_server = true },
      { text = "⚡ Optimize (php artisan optimize)", optimize = true },
      { text = "🧹 Config clear (php artisan config:clear)", config_clear = true },
    }
    Snacks.picker.pick({
      source = "laravel_commands",
      title = "🐘 Comandos Laravel",
      items = laravel_actions,
      format = "text",
      layout = "select",
      confirm = function(picker, item)
        picker:close()
        if item then
          if item.serve then
            laravel_serve_external()
          elseif item.restart_server then
            laravel_run_with_restart("Restart Server", "Write-Output 'Servidor reiniciado con éxito.'")
          elseif item.optimize then
            laravel_run_with_restart("Optimize", "php artisan optimize")
          elseif item.config_clear then
            laravel_run_with_restart("Config Clear", "php artisan config:clear")
          elseif item.picker then
            pcall(function()
              require("laravel").pickers.snacks()
            end)
          end
        end
      end,
    })
    return
  end

  vim.notify("No hay menu configurado para el lenguaje actual", vim.log.levels.WARN)
end

local function duplicar_linea()
  local bufnr = vim.api.nvim_get_current_buf()
  local a, b = vim.fn.line("v"), vim.fn.line(".")
  local inicio, fin = math.min(a, b), math.max(a, b)
  local lineas = vim.api.nvim_buf_get_lines(bufnr, inicio - 2, fin, false)
  vim.api.nvim_buf_set_lines(bufnr, fin, fin, false, lineas)
end

pcall(vim.keymap.del, "n", "<leader>/")
pcall(vim.keymap.del, "n", "<leader><leader>")

key("n", "<leader>h", function()
  LazyVim.pick("live_grep")()
end, { desc = "Búsqueda global de palabra" })
key("n", "<leader>y", function()
  LazyVim.pick("files")()
end, { desc = "Buscar archivo por nombre" })

key("n", "<leader>n", function()
  Snacks.picker.lines({
    layout = "default", -- Forzar la ventana flotante centrada
  })
end, { desc = "Buscar palabra en archivo actual" })

key("n", "<C-a>", function()
  vim.cmd("normal! ggVG")
end, { desc = "Seleccionar todo" })

key("n", "<leader>t", function()
  Snacks.terminal.toggle(nil, { cwd = LazyVim.root(), id = "proyecto_term" })
end, { desc = "Toggle Terminal (Raíz)" })


key({ "n", "v" }, "<leader>/", duplicar_linea, { desc = "Duplicar línea" })
key("n", "<leader>.", "V", { desc = "Seleccionar línea completa (Visual)" })
key("n", "o", "w", { desc = "Ir al siguiente espacio/palabra" })
key("n", "<leader>l", "<cmd>wincmd l<cr>", { desc = "Mover focus al split derecho" })
key("n", "<leader>k", "<cmd>wincmd h<cr>", { desc = "Mover focus al split izquierdo" })

key("n", "<leader>b", "<cmd>vsplit<cr>", { desc = "Split vertical" })
key("n", "<leader>v", "<cmd>split<cr>", { desc = "Split horizontal" })
key("n", "<leader>g", function()
  LazyVim.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false })
end, { desc = "Abrir LazyGit" })
key("v", "<C-c>", '"+y', { desc = "Copiar con Ctrl+C" })
key("n", "K", function()
  vim.lsp.buf.hover()
end, { desc = "Ver documentación (Hover)" })
key("n", "<leader>'", function()
  vim.lsp.buf.hover()
end, { desc = "Ver documentación de la posición actual" })
key("n", "<leader>j", function()
  vim.cmd("buffer #")
end, { desc = "Toggle entre archivos" })
key("n", "<leader>u", function()
  vim.cmd("rightbelow vsplit")
  vim.lsp.buf.definition({ reuse_win = true })
end, { desc = "Abrir definición en split derecho" })

key("n", "<leader>xu", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/codeAction" })[2]
  if not client then
    vim.notify("C#: no hay servidor LSP activo", vim.log.levels.WARN)
    return
  end

  local cursor = vim.api.nvim_win_get_cursor(1)
  local lnum = cursor[2] - 1
  local palabra = vim.fn.expand("<cword>")
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = { line = lnum, character = cursor[3] },
      ["end"] = { line = lnum, character = cursor[3] + vim.str_utfindex(palabra) },
    },
    context = { triggerKind = 2, diagnostics = {} },
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
    if not handle then
      return
    end

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
  table.sort(projects, function(a, b)
    return a.text:lower() < b.text:lower()
  end)

  Snacks.picker.pick({
    source = "proyectos",
    title = " 󰉋 Mis Proyectos ",
    items = projects,
    format = "text",
    layout = "default", -- Cambiado de "select" a "default" para un diseño flotante completo
    -- Si quieres ajustar el tamaño de la ventana flotante centrada:
    win = {
      input = {
        keys = {
          ["<Esc>"] = { "close", mode = { "i", "n" } },
        },
      },
    },
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


key({ "n", "v" }, "<leader>o", function()
  vim.cmd("normal! $")
end, { desc = "Ir al final de la línea" })
key({ "n", "v" }, "<leader>i", function()
  vim.cmd("normal! ^")
end, { desc = "Ir al principio de la línea" })
key({ "n", "v" }, "<C-x>", function()
  vim.cmd("normal! dd")
end, { desc = "Cortar línea" })

key("n", "<leader>;", function()
  local lnum = vim.api.nvim_win_get_cursor(1)[1] - 1
  if #vim.diagnostic.get(1, { lnum = lnum }) == 0 then
    vim.notify("Sin diagnósticos", vim.log.levels.INFO)
    return
  end
  vim.diagnostic.open_float({ scope = "line", border = "rounded", source = true, header = false })
end, { desc = "Ver error completo" })

key("n", "<leader>,", function()
  vim.diagnostic.jump({ count = 2, bufnr = 0, float = true })
end, { desc = "Siguiente error" })
key("n", "<leader>m", function()
  vim.diagnostic.jump({ count = 0, bufnr = 0, float = true })
end, { desc = "Error anterior" })

key("n", "<leader>c", function()
  local list = vim.b.edit_positions
  if type(list) ~= "table" or #list == 1 then
    return
  end
  local cur = vim.api.nvim_win_get_cursor(1)[1]
  for i = #list, 2, -1 do
    if list[i] < cur then
      vim.api.nvim_win_set_cursor(1, { list[i], 0 })
      return
    end
  end
end, { desc = "Ir a la edición anterior" })

key("n", "<C-BS>", "db", { desc = "Borrar palabra anterior" })
key("n", "<C-H>", "db", { desc = "Borrar palabra anterior (Ctrl+Backspace)" })


local db_tab = nil    -- tabpage del workspace de BD
local prev_tab = nil  -- tabpage de donde venimos

vim.keymap.set("n", "<leader>db", function()
  local current = vim.api.nvim_get_current_tabpage()

  -- Si el workspace de BD ya existe, alternamos entre él y el anterior
  if db_tab and vim.api.nvim_tabpage_is_valid(db_tab) then
    if current == db_tab then
      if prev_tab and vim.api.nvim_tabpage_is_valid(prev_tab) then
        vim.api.nvim_set_current_tabpage(prev_tab)
      else
        vim.cmd("tabprevious")
      end
    else
      prev_tab = current
      vim.api.nvim_set_current_tabpage(db_tab)
    end
    return
  end

  prev_tab = current
  vim.cmd("tabnew")
  db_tab = vim.api.nvim_get_current_tabpage()

  vim.cmd("DBUI")        -- abre el drawer a la izquierda
  vim.cmd("wincmd l")    -- foco en la ventana de la derecha
  vim.bo.filetype = "sql"
end, { desc = "Alternar workspace de Base de Datos" })

vim.keymap.set("v", "<leader>r", "<Plug>(DBUI_ExecuteQuery)", opts)
vim.keymap.set("n", "<leader>r", "vip<Plug>(DBUI_ExecuteQuery)", opts)
