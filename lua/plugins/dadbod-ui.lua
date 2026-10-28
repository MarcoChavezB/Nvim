return {
  'kristijanhusak/vim-dadbod-ui',
  dependencies = {
    { 'tpope/vim-dadbod', lazy = true },
    { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql', 'plsql', 'sqlite' }, lazy = true },
  },
  cmd = {
    'DBUI',
    'DBUIToggle',
    'DBUIAddConnection',
    'DBUIFindBuffer',
  },
  init = function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
    vim.g.db_ui_hide_schemas = { 'information_schema', 'pg_catalog' }

    vim.g.db_ui_auto_execute_table_helpers = 1
  end,
  config = function()
    local function read_file(path)
      local file = io.open(path, "r")
      if not file then return nil end
      local content = file:read("*all")
      file:close()
      return content
    end

    local function auto_setup_db()
      local current_path = vim.fn.getcwd()
      local db_url = nil

      vim.g.db = nil

      local env_path = current_path .. "/.env"
      if vim.fn.filereadable(env_path) == 1 then
        local env_content = read_file(env_path)
        if env_content then
          local db_connection = env_content:match("DB_CONNECTION=([%w_]+)") or "mysql"
          local db_host = env_content:match("DB_HOST=([%w_.-]+)") or "127.0.0.1"
          local db_port = env_content:match("DB_PORT=([%d]+)") or "3306"
          local db_database = env_content:match("DB_DATABASE=([%w_.-]+)") or ""
          local db_username = env_content:match("DB_USERNAME=([%w_.-]+)") or "root"
          local db_password = env_content:match("DB_PASSWORD=([%w_.-]*)") or ""

          db_password = db_password:gsub("['\"]", "")
          db_database = db_database:gsub("['\"]", "")

          if db_database ~= "" then
            if db_connection == "sqlite" then
              db_url = "sqlite://" .. current_path .. "/" .. db_database
            elseif db_connection == "sqlsrv" then
              -- Traducción al adaptador nativo 'sqlserver' de vim-dadbod
              if db_password ~= "" and db_username ~= "" then
                db_url = string.format("sqlserver://%s:%s@%s:%s/%s", db_username, db_password, db_host, db_port, db_database)
              else
                db_url = string.format("sqlserver://%s:%s/%s", db_host, db_port, db_database)
              end
            else
              db_url = string.format("%s://%s:%s@%s:%s/%s", db_connection, db_username, db_password, db_host, db_port, db_database)
            end
          end
        end
      end

      -- B. Intentar leer .NET (appsettings.json) -> SQL Server
      local appsettings_path = current_path .. "/appsettings.json"
      if not db_url and vim.fn.filereadable(appsettings_path) == 1 then
        local json_content = read_file(appsettings_path)
        if json_content then
          local conn_str = json_content:match('"DefaultConnection"%s*:%s*"([^"]+)"')
                        or json_content:match('"Default"%s*:%s*"([^"]+)"')
                        or json_content:match('"ConnectionStrings"%s*:%s*{[^}]*"%w+":%s*"([^"]+)"')
          if conn_str then
            local server = conn_str:match("Server=([^;]+)") or conn_str:match("Data Source=([^;]+)") or "localhost"
            local database = conn_str:match("Database=([^;]+)") or conn_str:match("Initial Catalog=([^;]+)") or ""
            local user = conn_str:match("User Id=([^;]+)") or conn_str:match("UID=([^;]+)") or ""
            local password = conn_str:match("Password=([^;]+)") or conn_str:match("PWD=([^;]+)") or ""

            if user ~= "" and password ~= "" then
              db_url = string.format("sqlserver://%s:%s@%s/%s", user, password, server, database)
            else
              db_url = string.format("sqlserver://%s/%s", server, database)
            end
          end
        end
      end

      if db_url then
        vim.g.db = db_url
        vim.notify("Dadbod: BD cargada para el proyecto actual", vim.log.levels.INFO)
      end
    end

    -- Ejecutar al iniciar y al cambiar de directorio de trabajo con el selector de proyectos
    auto_setup_db()
    vim.api.nvim_create_autocmd("DirChanged", {
      callback = function()
        auto_setup_db()
      end,
    })

    vim.keymap.set("n", "<leader>df", "<cmd>DBUIFindBuffer<CR>", { desc = "Buscar buffer de consulta actual" })
  end,
}
