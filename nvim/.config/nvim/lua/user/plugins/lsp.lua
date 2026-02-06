local M = {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "saghen/blink.cmp",
    },

    -- Optional: auto-install these if missing
    opts = {
      ensure_installed = { "lua_ls", "html" },
      -- automatic_enable = true, -- default in v2
    },

    config = function(_, opts)
      local capabilities = require("blink.cmp").get_lsp_capabilities()

      -- Neovim 0.11+ (mason-lspconfig v2 expects this)
      if vim.lsp and vim.lsp.config and vim.lsp.enable then
        -- Apply capabilities to all servers by default
        vim.lsp.config("*", {
          capabilities = capabilities,
        })

        -- gdscript (usually not managed by Mason; enable manually)
        vim.lsp.config("gdscript", {})

        -- HTML (add templ filetype + your settings)
        vim.lsp.config("html", {
          filetypes = { "html", "templ" },
          settings = {
            html = {
              format = {
                templating = true,
                wrapLineLength = 120,
                wrapAttributes = "auto",
              },
              hover = {
                documentation = true,
                references = true,
              },
            },
          },
        })

        -- lua_ls
        local runtime_path = vim.split(package.path, ";")
        table.insert(runtime_path, "lua/?.lua")
        table.insert(runtime_path, "lua/?/init.lua")

        vim.lsp.config("lua_ls", {
          settings = {
            Lua = {
              runtime = {
                version = "LuaJIT",
                path = runtime_path,
              },
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = {
                enable = false,
              },
            },
          },
        })

        -- Set up mason-lspconfig (auto-enables Mason-installed servers by default)
        require("mason-lspconfig").setup(opts)

        -- Enable servers NOT installed via Mason (gdscript typically)
        vim.lsp.enable("gdscript")

        return
      end

      ----------------------------------------------------------------------
      -- Fallback: older Neovim / older flow (keeps you from crashing)
      ----------------------------------------------------------------------
      local mason_lspconfig = require("mason-lspconfig")
      mason_lspconfig.setup(opts)

      local lspconfig = require("lspconfig")

      local function setup(server, server_opts)
        server_opts = server_opts or {}
        server_opts.capabilities = capabilities
        lspconfig[server].setup(server_opts)
      end

      -- Generic setup for Mason-installed servers (skip ones we configure explicitly)
      local special = { lua_ls = true, html = true, gdscript = true }
      for _, server in ipairs(mason_lspconfig.get_installed_servers()) do
        if not special[server] and lspconfig[server] then
          setup(server, {})
        end
      end

      -- Explicit servers
      setup("gdscript", {})
      setup("html", {
        filetypes = { "html", "templ" },
        settings = {
          html = {
            format = {
              templating = true,
              wrapLineLength = 120,
              wrapAttributes = "auto",
            },
            hover = {
              documentation = true,
              references = true,
            },
          },
        },
      })
      setup("lua_ls", {
        settings = {
          Lua = {
            runtime = {
              version = "LuaJIT",
              path = (function()
                local rp = vim.split(package.path, ";")
                table.insert(rp, "lua/?.lua")
                table.insert(rp, "lua/?/init.lua")
                return rp
              end)(),
            },
            diagnostics = { globals = { "vim" } },
            workspace = {
              library = vim.api.nvim_get_runtime_file("", true),
              checkThirdParty = false,
            },
            telemetry = { enable = false },
          },
        },
      })
    end,
  },
}

return { M }
