return {
  -- File explorer that you edit like a buffer. Replaces netrw, which is
  -- disabled in lazy-bootstrap.lua.
  {
    "stevearc/oil.nvim",
    lazy = false, -- needed so `nvim <dir>` opens oil
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      default_file_explorer = true,
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      view_options = { show_hidden = true },
      float = { border = "rounded" },
      keymaps = {
        ["<C-h>"] = false, -- keep window navigation working inside oil
        ["<C-l>"] = false,
        ["q"] = "actions.close",
      },
    },
    keys = {
      { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
      { "<leader>-", "<cmd>Oil --float<CR>", desc = "Open parent directory (float)" },
    },
  },

  -- Auto-close and auto-rename HTML/JSX tags.
  {
    "windwp/nvim-ts-autotag",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  -- Insert matching brackets/quotes, aware of treesitter context.
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
      fast_wrap = {},
    },
  },

  -- Add/change/delete surrounding pairs: ysiw" , cs"' , ds"
  {
    "kylechui/nvim-surround",
    event = { "BufReadPost", "BufNewFile" },
    version = "*",
    opts = {},
  },

  -- Highlight and list TODO/FIXME/HACK comments.
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = false },
    keys = {
      { "<leader>xt", "<cmd>TodoTelescope<CR>", desc = "Todo comments" },
    },
  },

  -- Jump anywhere with s/S.
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = { modes = { char = { enabled = false } } },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote flash" },
    },
  },

  -- Better quickfix window.
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    opts = {},
  },
}
