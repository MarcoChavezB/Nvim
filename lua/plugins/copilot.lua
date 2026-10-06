-- El plan de Copilot de esta máquina no da acceso a los modelos de Google (la API solo
-- ofrece claude-haiku-4.5, gpt-5-mini, gpt-5.4-mini, gpt-5.3-codex y mai-code-1.1-flash),
-- así que se añade un provider propio contra Google AI Studio para poder usar Gemini.
-- La key NO se guarda en el repo: se lee de la variable GEMINI_API_KEY o del archivo
-- %LOCALAPPDATA%\nvim-data\gemini_api_key (una línea con la key).
-- Se resuelve una sola vez al arrancar porque las peticiones HTTP corren en un
-- fast event context donde no se puede llamar a vim.fn.readfile.
local GEMINI_KEY = vim.env.GEMINI_API_KEY
if not GEMINI_KEY or GEMINI_KEY == "" then
  local ok, lines = pcall(vim.fn.readfile, vim.fn.stdpath("data") .. "/gemini_api_key")
  if ok and lines and lines[1] and vim.trim(lines[1]) ~= "" then
    GEMINI_KEY = vim.trim(lines[1])
  else
    GEMINI_KEY = nil
  end
end

-- Interruptor: ponlo en true cuando el proyecto de Google AI Studio tenga crédito.
-- Con la key puesta pero sin crédito, Google responde 402 y el chat se queda sinCopilot.
local USAR_GEMINI = false

return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          enabled = true,
          auto_trigger = true, -- ¡Esto es clave para que aparezcan solas!
          keymap = {
            accept = "<Tab>", -- Aceptas sugerencias con Tab
            next = "<M-]>",
            prev = "<M-[>",
            dismiss = "<C-]>",
          },
        },
        panel = { enabled = false },
      })
    end,
  },

  -- Chat de Copilot (v2): reemplaza al ir a Gemini por el navegador
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = function(_, opts)
      local copilot = require("CopilotChat.config.providers").copilot
      return vim.tbl_deep_extend("force", opts, {
        model = (GEMINI_KEY and USAR_GEMINI) and "gemini-pro-latest" or "auto", -- Sin Gemini activo usa Copilot
        language = "Spanish", -- Que responda siempre en español
        -- Solo herramientas de lectura: bash y edit siguen pidiendo confirmación
        trusted_tools = { "file", "glob", "grep" },
        headers = {
          user = "  Tú ",
          assistant = "  Copilot ",
          tool = "  Herramienta ",
        },
        window = {
          layout = "vertical",
          width = 0.45,
          title = "Copilot Chat",
        },
        providers = {
          gemini = {
            -- Provider apagado si falta la key o si aún no hay crédito en Google
            disabled = not (GEMINI_KEY and USAR_GEMINI),
            get_headers = function()
              -- Solo x-goog-api-key: si se manda también un Bearer, Google rechaza por credenciales
              return { ["x-goog-api-key"] = GEMINI_KEY or "" }
            end,
            get_url = function()
              return "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
            end,
            get_info = function()
              return { "Google AI Studio (API key propia, no consume cuota de Copilot)" }
            end,
            get_models = function(headers)
              local curl = require("CopilotChat.utils.curl")
              local res, err = curl.get("https://generativelanguage.googleapis.com/v1beta/models", {
                headers = headers,
                json_response = true,
              })
              if err then
                error("Fallo de red al listar los modelos de Gemini: " .. tostring(err))
              end
              if not res or res.status ~= 200 or not res.body or not res.body.models then
                local msg = res and res.body and res.body.error and res.body.error.message or "respuesta inesperada"
                error("La API key de Gemini fue rechazada (HTTP " .. tostring(res and res.status) .. "): " .. tostring(msg))
              end
              local out = {}
              for _, m in ipairs(res.body.models or {}) do
                local supports = m.supportedGenerationMethods or {}
                if vim.tbl_contains(supports, "generateContent") and not m.name:match("embedding") then
                  local id = m.name:gsub("^models/", "")
                  out[#out + 1] = {
                    id = id,
                    name = m.displayName or id,
                    tokenizer = "o200k_base",
                    max_input_tokens = 1048576,
                    max_output_tokens = 65536,
                    streaming = true,
                    tools = true,
                  }
                end
              end
              return out
            end,
            -- El endpoint compatible con OpenAI exige Authorization, pero /models rechaza el
            -- Bearer y solo acepta x-goog-api-key, así que se manda cada uno donde toca.
            prepare_input = function(inputs, provider_opts)
              local body = copilot.prepare_input(inputs, provider_opts)
              return body, { Authorization = "Bearer " .. (GEMINI_KEY or "") }
            end,
            prepare_output = copilot.prepare_output,
          },
        },
      })
    end,
    keys = {
      -- Atajos sobre la selección visual (el resource "selection" ya va por defecto)
      {
        "<leader>ae",
        function()
          require("CopilotChat").ask("/Explain")
        end,
        mode = "x",
        desc = "Explicar selección",
      },
      {
        "<leader>af",
        function()
          require("CopilotChat").ask("/Fix")
        end,
        mode = "x",
        desc = "Arreglar selección",
      },
      {
        "<leader>ad",
        function()
          require("CopilotChat").ask("/Docs")
        end,
        mode = "x",
        desc = "Documentar selección",
      },
      {
        "<leader>ar",
        function()
          require("CopilotChat").ask("/Review")
        end,
        mode = "x",
        desc = "Revisar selección",
      },
      {
        "<leader>at",
        function()
          require("CopilotChat").ask("/Tests")
        end,
        mode = "x",
        desc = "Generar tests",
      },
      {
        "<leader>as",
        function()
          require("CopilotChat").ask("/Optimize")
        end,
        mode = "x",
        desc = "Optimizar selección",
      },
      {
        "<leader>ac",
        function()
          require("CopilotChat").ask("/Commit")
        end,
        mode = "n",
        desc = "Mensaje de commit (staged)",
      },
      {
        "<leader>am",
        function()
          require("CopilotChat").select_model()
        end,
        mode = "n",
        desc = "Elegir modelo",
      },
    },
  },
}
