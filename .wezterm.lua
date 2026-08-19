-- WezTerm configuration
-- Docs: https://wezfurlong.org/wezterm/config/files.html

local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

--------------------------------------------------------------------------------
-- Appearance
--------------------------------------------------------------------------------

config.color_scheme = "Ayu Dark (Gogh)"

config.font = wezterm.font_with_fallback({
	{ family = "JetBrainsMono Nerd Font", weight = "Medium" },
	{ family = "JetBrains Mono", weight = "Medium" },
	"Menlo",
	-- Emoji / symbol coverage for anything the above miss.
	"Apple Color Emoji",
})
config.font_size = 14.0
config.line_height = 1.1

config.initial_cols = 120
config.initial_rows = 28

-- Native macOS titlebar buttons, but no bulky title bar.
config.window_decorations = "RESIZE | MACOS_FORCE_ENABLE_SHADOW"
config.window_padding = {
	left = 12,
	right = 12,
	top = 10,
	bottom = 6,
}

config.window_background_opacity = 0.97
config.macos_window_background_blur = 20

-- Only show the tab bar when there is more than one tab.
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

config.scrollback_lines = 10000

-- A visual bell reads better than an audible one.
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_duration_ms = 75,
	fade_out_duration_ms = 75,
	target = "CursorColor",
}

config.cursor_blink_rate = 500
config.default_cursor_style = "BlinkingBar"

--------------------------------------------------------------------------------
-- Shell & environment
--------------------------------------------------------------------------------

config.default_prog = { "/bin/zsh", "-l" }

-- Let Neovim distinguish more key combinations (CSI u encoding).
config.enable_kitty_keyboard = true

--------------------------------------------------------------------------------
-- Keys
--------------------------------------------------------------------------------

-- CMD is the natural leader on macOS; use it for panes/tabs so nothing
-- collides with Neovim's own bindings.
config.keys = {
	-- Panes
	{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "CMD", action = act.TogglePaneZoomState },

	-- Pane navigation
	{ key = "LeftArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Left") },
	{ key = "RightArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Right") },
	{ key = "UpArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Up") },
	{ key = "DownArrow", mods = "CMD|ALT", action = act.ActivatePaneDirection("Down") },

	-- Pane resizing
	{ key = "LeftArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Left", 3 }) },
	{ key = "RightArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Right", 3 }) },
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Up", 3 }) },
	{ key = "DownArrow", mods = "CMD|SHIFT", action = act.AdjustPaneSize({ "Down", 3 }) },

	-- Tabs
	{ key = "t", mods = "CMD", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "CMD", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "CMD", action = act.ActivateTabRelative(1) },

	-- Font size
	{ key = "=", mods = "CMD", action = act.IncreaseFontSize },
	{ key = "-", mods = "CMD", action = act.DecreaseFontSize },
	{ key = "0", mods = "CMD", action = act.ResetFontSize },

	-- Scrollback
	{
		key = "k",
		mods = "CMD",
		action = act.Multiple({
			act.ClearScrollback("ScrollbackAndViewport"),
			act.SendKey({ key = "l", mods = "CTRL" }),
		}),
	},

	-- Search and copy mode
	{ key = "f", mods = "CMD", action = act.Search("CurrentSelectionOrEmptyString") },
	{ key = "x", mods = "CMD", action = act.ActivateCopyMode },

	-- Quick-select / open URLs without the mouse.
	{ key = "u", mods = "CMD|SHIFT", action = act.QuickSelect },
}

-- CMD+1..9 jumps straight to a tab.
for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "CMD",
		action = act.ActivateTab(i - 1),
	})
end

--------------------------------------------------------------------------------
-- Tab titles
--------------------------------------------------------------------------------

-- Show the running process rather than the raw argv, and mark unseen output.
wezterm.on("format-tab-title", function(tab, _, _, _, _, max_width)
	local pane = tab.active_pane
	local title = pane.foreground_process_name

	if title and title ~= "" then
		title = title:gsub("(.*[/\\])(.*)", "%2")
	else
		title = pane.title
	end

	if tab.is_active then
		title = "▎" .. title
	else
		title = " " .. title
	end

	if pane.has_unseen_output and not tab.is_active then
		title = title .. " •"
	end

	return wezterm.truncate_right(title, max_width - 2) .. " "
end)

return config
