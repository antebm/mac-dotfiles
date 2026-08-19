-- Entry point. Order matters: options and leader must be set before lazy.nvim
-- loads any plugin, since plugin keymaps are registered against <leader>.
require("basic_config")
require("keymaps")
require("lazy-bootstrap")
