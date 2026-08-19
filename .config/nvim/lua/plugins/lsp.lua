-- Servers we want configured. Each entry may carry settings that are merged
-- over whatever nvim-lspconfig ships for that server.
local servers = {
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        workspace = {
          checkThirdParty = false,
          -- Makes vim.* resolve when editing this config.
          library = vim.api.nvim_get_runtime_file("", true),
        },
        diagnostics = { globals = { "vim" } },
        telemetry = { enable = false },
        format = { enable = false }, -- stylua handles formatting
      },
    },
  },

  basedpyright = {
    settings = {
      basedpyright = {
        analysis = {
          typeCheckingMode = "standard",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticSeverityOverrides = {
            -- ruff already reports unused imports/variables.
            reportUnusedImport = "none",
            reportUnusedVariable = "none",
          },
        },
      },
    },
  },

  -- Linting and import sorting for Python.
  ruff = {},

  vtsls = {
    settings = {
      typescript = {
        updateImportsOnFileMove = { enabled = "always" },
        inlayHints = {
          parameterNames = { enabled = "literals" },
          variableTypes = { enabled = false },
        },
      },
      javascript = {
        updateImportsOnFileMove = { enabled = "always" },
      },
    },
  },

  jsonls = {},
  yamlls = {},

  -- Go and Rust: configured here, but only enabled when their toolchain is
  -- present (see `enabled` below), so a missing toolchain is not an error.
  gopls = {
    settings = {
      gopls = {
        gofumpt = true,
        staticcheck = true,
        analyses = { unusedparams = true, shadow = true },
      },
    },
  },
  rust_analyzer = {
    settings = {
      ["rust-analyzer"] = {
        cargo = { allFeatures = true },
        check = { command = "clippy" },
      },
    },
  },
}

-- Mason installs these; gopls/rust_analyzer are deliberately absent because
-- they need a Go/Rust toolchain that is not installed yet. Install Go or
-- Rust, then `:MasonInstall gopls` / use rustup's rust-analyzer.
local mason_ensure = {
  "lua_ls", "basedpyright", "ruff", "vtsls", "jsonls", "yamlls",
}

-- Extra tools (formatters) that are not language servers.
local mason_tools = { "stylua", "prettierd" }

return {
  -- Mason: manages the server/formatter binaries.
  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    keys = { { "<leader>cm", "<cmd>Mason<CR>", desc = "Mason" } },
    opts = {
      ui = { border = "rounded", icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
    },
    config = function(_, opts)
      require("mason").setup(opts)

      -- Install the non-LSP tools on demand rather than blocking startup.
      vim.api.nvim_create_user_command("MasonInstallTools", function()
        local registry = require("mason-registry")
        registry.refresh(function()
          for _, name in ipairs(mason_tools) do
            local ok, pkg = pcall(registry.get_package, name)
            if ok and not pkg:is_installed() then
              pkg:install()
            end
          end
        end)
      end, { desc = "Install configured Mason formatters" })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = mason_ensure,
        -- We enable servers ourselves below so the toolchain checks apply.
        automatic_enable = false,
      })

      -- Push settings into Neovim's native LSP config registry (0.11+).
      -- nvim-lspconfig supplies cmd/filetypes/root_markers via its lsp/ dir.
      for name, cfg in pairs(servers) do
        if next(cfg) ~= nil then
          vim.lsp.config(name, cfg)
        end
      end

      -- Only enable a server whose toolchain actually exists.
      local requires_toolchain = {
        gopls = "go",
        rust_analyzer = "cargo",
      }

      local to_enable = {}
      for name, _ in pairs(servers) do
        local tool = requires_toolchain[name]
        if not tool or vim.fn.executable(tool) == 1 then
          table.insert(to_enable, name)
        end
      end
      vim.lsp.enable(to_enable)

      -- Buffer-local keymaps, bound once a server attaches.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
        callback = function(event)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
          end

          local ok, builtin = pcall(require, "telescope.builtin")

          map("grn", vim.lsp.buf.rename, "Rename symbol")
          map("gra", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("K", vim.lsp.buf.hover, "Hover documentation")
          map("gK", vim.lsp.buf.signature_help, "Signature help")
          map("<C-s>", vim.lsp.buf.signature_help, "Signature help", "i")

          if ok then
            map("grr", builtin.lsp_references, "References")
            map("gri", builtin.lsp_implementations, "Implementations")
            map("grd", builtin.lsp_definitions, "Definitions")
            map("grt", builtin.lsp_type_definitions, "Type definitions")
            map("gO", builtin.lsp_document_symbols, "Document symbols")
            map("gW", builtin.lsp_dynamic_workspace_symbols, "Workspace symbols")
          else
            map("grr", vim.lsp.buf.references, "References")
            map("gri", vim.lsp.buf.implementation, "Implementations")
            map("grd", vim.lsp.buf.definition, "Definitions")
          end

          map("grD", vim.lsp.buf.declaration, "Declaration")

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if not client then return end

          -- Highlight other references to the symbol under the cursor.
          if client:supports_method("textDocument/documentHighlight") then
            local hl_group = vim.api.nvim_create_augroup(
              "lsp-highlight-" .. event.buf, { clear = true }
            )
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = event.buf,
              group = hl_group,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd("LspDetach", {
              group = vim.api.nvim_create_augroup(
                "lsp-highlight-detach-" .. event.buf, { clear = true }
              ),
              buffer = event.buf,
              callback = function()
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds({ group = hl_group, buffer = event.buf })
              end,
            })
          end

          -- Inlay hints, off by default; toggle per buffer.
          if client:supports_method("textDocument/inlayHint") then
            map("<leader>ch", function()
              local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf })
              vim.lsp.inlay_hint.enable(not enabled, { bufnr = event.buf })
            end, "Toggle inlay hints")
          end
        end,
      })
    end,
  },

  -- Formatting, kept separate from the LSP so format-on-save is explicit.
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function() require("conform").format({ async = true, lsp_format = "fallback" }) end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        javascriptreact = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        typescriptreact = { "prettierd", "prettier", stop_after_first = true },
        json = { "prettierd", "prettier", stop_after_first = true },
        jsonc = { "prettierd", "prettier", stop_after_first = true },
        yaml = { "prettierd", "prettier", stop_after_first = true },
        markdown = { "prettierd", "prettier", stop_after_first = true },
        css = { "prettierd", "prettier", stop_after_first = true },
        html = { "prettierd", "prettier", stop_after_first = true },
        go = { "gofumpt", "goimports" },
        rust = { "rustfmt" },
      },
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(bufnr)
        -- Respect an opt-out, per buffer or globally.
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return { timeout_ms = 1000, lsp_format = "fallback" }
      end,
    },
    init = function()
      -- :FormatDisable [!]  /  :FormatEnable
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
      end, { desc = "Disable format-on-save (! for this buffer only)", bang = true })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable format-on-save" })
    end,
  },
}
