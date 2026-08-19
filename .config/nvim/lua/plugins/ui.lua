return {
  -- Colourscheme. Ayu Dark, matching WezTerm's "Ayu Dark (Gogh)" scheme and
  -- the Claude Code status line so the whole terminal reads as one palette.
  {
    "Shatur/neovim-ayu",
    lazy = false,
    priority = 1000, -- load before everything else so highlights are set
    opts = {
      mirage = false,     -- true would switch the dark variant to Mirage
      terminal = true,
      overrides = function()
        local colors = require("ayu.colors")
        colors.generate()

        -- Make floating windows and the completion menu read as one surface.
        -- Borders use guide_active, not panel_border: the latter is pure black
        -- and disappears against the panel background.
        return {
          NormalFloat = { bg = colors.panel_bg, fg = colors.fg },
          FloatBorder = { bg = colors.panel_bg, fg = colors.guide_active },
          FloatTitle  = { bg = colors.panel_bg, fg = colors.accent, bold = true },
          Pmenu       = { bg = colors.panel_bg, fg = colors.fg },
          PmenuSel    = { bg = colors.selection_bg, fg = "NONE" },
          PmenuSbar   = { bg = colors.guide_normal },
          PmenuThumb  = { bg = colors.guide_active },
        }
      end,
    },
    config = function(_, opts)
      require("ayu").setup(opts)
      vim.cmd.colorscheme("ayu-dark")
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
        theme = "ayu_dark",
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
