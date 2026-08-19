-- Leader has to be set before plugins register their mappings.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.undofile = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0

-- Indentation
vim.opt.smartindent = true
vim.opt.breakindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- UI
vim.opt.termguicolors = true
vim.opt.signcolumn = "yes"
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.showmode = false
vim.opt.pumheight = 12
vim.opt.winborder = "rounded"
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Splits open predictably without shifting the current view.
vim.opt.splitkeep = "screen"

-- Timing
vim.opt.updatetime = 250
vim.opt.timeoutlen = 400

-- Files
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.confirm = true

-- Share the system clipboard. Scheduled so it does not slow down startup
-- while Neovim probes for a clipboard provider.
vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)

-- Completion behaviour: never auto-insert, always show the menu.
vim.opt.completeopt = { "menuone", "noselect", "noinsert" }

-- Diagnostics
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = { border = "rounded", source = true },
})

-- Briefly highlight text on yank so you can see what was copied.
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Return to the last cursor position when reopening a file.
vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Restore last cursor position",
  group = vim.api.nvim_create_augroup("restore-cursor", { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Two-space indent for languages where that is the norm.
vim.api.nvim_create_autocmd("FileType", {
  desc = "Two-space indent for web/config filetypes",
  group = vim.api.nvim_create_augroup("two-space-indent", { clear = true }),
  pattern = {
    "lua", "javascript", "javascriptreact", "typescript", "typescriptreact",
    "json", "jsonc", "yaml", "html", "css", "scss", "markdown",
  },
  callback = function()
    vim.opt_local.tabstop = 2
  end,
})
