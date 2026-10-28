return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          enabled = true,
          filetypes = { "php", "blade" },
          settings = {
            intelephense = {
              files = { maxSize = 3000000 },
            },
          },
        },
        phpactor = { enabled = false },
        -- Removido "laravel_lsp" porque causaba conflicto / no existe
        tailwindcss = {},
        yamlls = {},
        jsonls = {},
        marksman = {},
        html = {
          filetypes = { "html", "htm", "xhtml", "php", "blade" },
          settings = {
            html = { suggest = { html5 = true } },
          },
        },
      },
    },
  },

  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      -- Removido "laravel-lsp" de aquí
      vim.list_extend(opts.ensure_installed, { "pint", "blade-formatter", "phpstan" })
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.php = { "pint" }
      opts.formatters_by_ft.blade = { "blade-formatter" }
      opts.formatters = opts.formatters or {}
      opts.formatters.pint = {
        cwd = function()
          local util = require("conform.util")
          return util.root_file({ "composer.json", "pint.json" })()
        end,
      }
      opts.formatters["blade-formatter"] = opts.formatters["blade-formatter"] or {}
    end,
  },

  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = {}
      local ok = pcall(require, "lint")
      if ok then
        vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
          group = vim.api.nvim_create_augroup("laravel_phpstan", { clear = true }),
          pattern = "*.php",
          callback = function()
            local root = LazyVim.root()
            if
              vim.uv.fs_stat(root .. "/phpstan.neon")
              or vim.uv.fs_stat(root .. "/phpstan.neon.dist")
              or vim.uv.fs_stat(root .. "/phpstan.dist.neon")
            then
              local lint = require("lint")
              lint.try_lint({ "phpstan" })
            end
          end,
        })
      end
    end,
  },

  {
    "adalessa/laravel.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-neotest/nvim-nio",
    },
    ft = { "php", "blade" },
    event = { "BufEnter composer.json", "BufEnter artisan" },
    keys = {
      {
        "<leader>ll",
        function()
          require("laravel").pickers.laravel()
        end,
        desc = "Laravel: Picker",
      },
      {
        "<leader>la",
        function()
          require("laravel").pickers.artisan()
        end,
        desc = "Laravel: Artisan",
      },
      {
        "<leader>lr",
        function()
          require("laravel").pickers.routes()
        end,
        desc = "Laravel: Rutas",
      },
      {
        "<leader>lm",
        function()
          require("laravel").pickers.make()
        end,
        desc = "Laravel: Make",
      },
      {
        "<leader>lc",
        function()
          require("laravel").pickers.commands()
        end,
        desc = "Laravel: Comandos personalizados",
      },
      {
        "<leader>lo",
        function()
          require("laravel").pickers.resources()
        end,
        desc = "Laravel: Recursos",
      },
      {
        "<leader>lh",
        function()
          require("laravel").run("artisan docs")
        end,
        desc = "Laravel: Documentación",
      },
      {
        "<leader>lt",
        function()
          require("laravel").commands.run("actions")
        end,
        desc = "Laravel: Acciones",
      },
      {
        "<leader>lu",
        function()
          require("laravel").commands.run("hub")
        end,
        desc = "Laravel: Artisan Hub",
      },
      {
        "<leader>lp",
        function()
          require("laravel").commands.run("command_center")
        end,
        desc = "Laravel: Centro de comandos",
      },
      {
        "<c-g>",
        function()
          require("laravel").commands.run("view:finder")
        end,
        desc = "Laravel: Buscar vista/uso",
      },
      {
        "gf",
        function()
          local ok, laravel_gf = pcall(function()
            return require("laravel").app("gf")
          end)
          if ok and laravel_gf and laravel_gf.cursorOnResource and laravel_gf.cursorOnResource() then
            return "<cmd>lua require('laravel').commands.run('gf')<cr>"
          end
          return "gf"
        end,
        expr = true,
        noremap = true,
        desc = "Laravel: Ir al recurso",
      },
    },
    opts = {
      features = {
        pickers = {
          provider = "snacks",
        },
      },
      extensions = {
        diagnostic = { enable = false },
      },
    },
    config = function(_, opts)
      -- Parche Windows 1: nvim-nio tiene dos bugs críticos en Windows:
      -- a) nio.file.open() usa uv_pipe_open sobre descriptores de archivo, lo que en Windows
      --    falla siempre con "ENOTSOCK: socket operation on non-socket".
      -- b) nio.streams._socket_reader() llama a uv.fs_fstat(pipe:fileno()) antes de leer stdout/stderr
      --    de procesos hijos, lo que en Windows falla siempre con "EBADF: bad file descriptor"
      --    y deja vacía la salida de PHP/Artisan.
      local nio = require("nio")
      local nio_file = require("nio.file")
      local streams = require("nio.streams")
      local control = require("nio.control")
      local tasks = require("nio.tasks")
      local uv = vim.uv or vim.loop

      streams._socket_reader = function(input)
        local pipe
        if type(input) == "userdata" then
          pipe = input
        else
          local create_err
          pipe, create_err = uv.new_pipe()
          if not pipe then
            return nil, create_err
          end
          local fd = type(input) == "number" and input or input and input.fd
          if fd then
            local _, open_err = pipe:open(fd)
            if open_err then
              return nil, open_err
            end
          end
        end

        local buffer = ""
        local has_buffer = control.event()
        local complete = control.event()
        local started = false
        local read_err = nil

        local stop_reading = function()
          if not started or complete.is_set() then
            return
          end
          uv.read_stop(pipe)
          complete.set()
          has_buffer.set()
        end

        local start = function()
          started = true
          local _, read_start_err = pipe:read_start(function(err, data)
            if err then
              read_err = err
              has_buffer.set()
              return
            end
            if not data then
              tasks.run(stop_reading)
              return
            end
            buffer = buffer .. data
            has_buffer.set()
          end)
          return read_start_err
        end

        return {
          pipe = pipe,
          close = function()
            stop_reading()
            nio.uv.close(pipe)
          end,
          read = function(n)
            if not started then
              local start_err = start()
              if start_err then
                return "", start_err
              end
            end
            if n == 0 then
              return "", nil
            end
            while not complete.is_set() and (not n or #buffer < n) and not read_err do
              has_buffer.wait()
              has_buffer.clear()
            end
            if read_err then
              return "", read_err
            end
            local data = n and buffer:sub(1, n) or buffer
            buffer = buffer:sub(#data + 1)
            return data
          end,
        }
      end

      local function win_file_open(path, flags, mode)
        local open_err, fd = nio.uv.fs_open(path, flags or "r", mode or 438)
        if not fd then
          return nil, open_err
        end
        local closed = false
        local function close_fd()
          if closed then
            return nil
          end
          closed = true
          return nio.uv.fs_close(fd)
        end
        return {
          fd = fd,
          close = close_fd,
          write = function(data)
            local write_err = nio.uv.fs_write(fd, data)
            if type(path) == "string" and path:match("_model_helpers%.php$") then
              close_fd()
            end
            if type(write_err) == "string" then
              return write_err
            end
            return nil
          end,
          read = function(n, offset)
            if n == 0 then
              return "", nil
            end
            local read_all = (n == nil)
            if not n then
              local stat_err, stat = nio.uv.fs_fstat(fd)
              if stat_err or not stat then
                return nil, stat_err
              end
              n = stat.size
            end
            local read_err, data = nio.uv.fs_read(fd, n, offset)
            if read_all then
              close_fd()
            end
            return data, read_err
          end,
        }
      end
      nio_file.open = win_file_open
      nio.file.open = win_file_open

      -- Parche Windows 2: nvim_get_runtime_file devuelve rutas con "\" en Windows,
      -- pero laravel.nvim hace :match("lua/(.*)%.lua$") esperando "/".
      local orig_get_runtime_file = vim.api.nvim_get_runtime_file
      vim.api.nvim_get_runtime_file = function(name, all)
        local res = orig_get_runtime_file(name, all)
        if type(name) == "string" and name:find("^lua/laravel") then
          for i, p in ipairs(res) do
            res[i] = p:gsub("\\", "/")
          end
        end
        return res
      end

      -- Parche Windows 3: make_php_file en laravel.nvim se ejecuta desde varias
      -- corrutinas al mismo tiempo al abrir un proyecto (laravel_provider + model_info),
      -- causando condición de carrera al crear vendor/nvim-laravel/ y truncar el archivo
      -- bootstrap mientras otro proceso de PHP lo está leyendo. Lo hacemos atómico con vim.uv.
      local code_service = require("laravel.services.code")
      local md5 = require("laravel.utils.md5")
      local app = require("laravel.core.app")
      function code_service:make_php_file(code, template)
        template = template or "tinker"
        local ok, tpl = pcall(require, "laravel.php-templates." .. template)
        if not ok or type(tpl) ~= "string" then
          error("Could not load PHP template: " .. tostring(template))
        end
        local output = tpl:gsub("__NVIM_LARAVEL_OUTPUT__", code)
        local pre_script = app:make("laravel.services.code.pre_script")
        if type(pre_script) == "function" then
          pre_script = pre_script()
        end
        if type(pre_script) ~= "string" then
          pre_script = ""
        end
        output = output:gsub("__NVIM_LARAL_PRE_BOOTSTRAP__", pre_script)

        local vendor_dir = "vendor"
        local dir = vendor_dir .. "/nvim-laravel/"
        local hash = md5.sumhexa(output)
        local fname = hash .. "." .. template .. ".php"
        local full = dir .. fname

        local stat = uv.fs_stat(full)
        if not (stat and stat.size and stat.size > 0) then
          if not uv.fs_stat(vendor_dir) then
            local ok_v, err_v = uv.fs_mkdir(vendor_dir, 493)
            if not ok_v and not tostring(err_v):match("EEXIST") then
              error("Could not create directory " .. vendor_dir)
            end
          end
          if not uv.fs_stat(dir) then
            local ok_d, err_d = uv.fs_mkdir(dir, 493)
            if not ok_d and not tostring(err_d):match("EEXIST") then
              error("Could not create directory for php files: " .. dir)
            end
          end
          local fd, open_err = uv.fs_open(full, "w", 438)
          if not fd then
            error("Could not create php file for " .. fname .. ": " .. tostring(open_err))
          end
          uv.fs_write(fd, "<?php\n" .. output, -1)
          uv.fs_close(fd)
        end

        return full
      end

      require("laravel").setup(opts)
    end,
  },
}
