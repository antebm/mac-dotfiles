return {
  -- Colourscheme. "dragon" is a warm, low-contrast dark variant that sits
  -- comfortably next to WezTerm's Hacktober palette.
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000, -- load before everything else so highlights are set
    opts = {
      theme = "dragon",
      background = { dark = "dragon", light = "lotus" },
      transparent = false,
      dimInactive = true,
      terminalColors = true,
      overrides = function(colors)
        local theme = colors.theme
        return {
          -- Make floating windows and the completion menu read as one surface.
          NormalFloat = { bg = theme.ui.bg_m3, fg = theme.ui.fg },
          FloatBorder = { bg = theme.ui.bg_m3, fg = theme.ui.bg_m1 },
          FloatTitle  = { bg = theme.ui.bg_m3, fg = theme.ui.special, bold = true },
          Pmenu       = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
          PmenuSel    = { bg = theme.ui.bg_p2, fg = "NONE" },
          PmenuSbar   = { bg = theme.ui.bg_m1 },
          PmenuThumb  = { bg = theme.ui.bg_p2 },
        }
      end,
    },
    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },

  -- Icons, used by lualine, telescope and oil.
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- Statusline.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "kanagawa",
        globalstatus = true,
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { "branch", "diff" },
        lualine_c = {
          { "filename", path = 1 },
          {
            "diagnostics",
            symbols = { error = "E", warn = "W", info = "I", hint = "H" },
          },
        },
        lualine_x = {
          -- Show which LSP servers are attached to this buffer.
          {
            function()
              local names = {}
              for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
                table.insert(names, client.name)
              end
              return table.concat(names, ",")
            end,
            icon = "LSP:",
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Discoverable keymaps: press <leader> and wait.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>c", group = "code" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>s", group = "search" },
      },
    },
    keys = {
      {
        "<leader>?",
        function() require("which-key").show({ global = false }) end,
        desc = "Buffer-local keymaps",
      },
    },
  },

  -- Indentation guides.
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = {
        filetypes = { "help", "lazy", "mason", "oil", "checkhealth", "man" },
      },
    },
  },
}
