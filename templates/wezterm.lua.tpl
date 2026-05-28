local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.font = wezterm.font 'JetBrainsMono Nerd Font'
config.font_size = 10.0
config.line_height = 1.0

config.window_padding = { left = 12, right = 12, top = 8, bottom = 8 }
config.window_decorations = 'NONE'
config.window_background_opacity = 0.92
config.enable_tab_bar = false
config.enable_scroll_bar = false
config.audible_bell = 'Disabled'

config.default_cursor_style = 'SteadyBlock'

config.hyperlink_rules = wezterm.default_hyperlink_rules()

config.colors = {
  foreground = '#${text}',
  background = '#${base}',
  cursor_bg = '#${text}',
  cursor_fg = '#${base}',
  cursor_border = '#${text}',
  selection_bg = '#${surface2}',
  selection_fg = '#${text}',

  ansi = {
    '#${ansi_black}',
    '#${ansi_red}',
    '#${ansi_green}',
    '#${ansi_yellow}',
    '#${ansi_blue}',
    '#${ansi_magenta}',
    '#${ansi_cyan}',
    '#${ansi_white}',
  },
  brights = {
    '#${ansi_brblack}',
    '#${ansi_brred}',
    '#${ansi_brgreen}',
    '#${ansi_bryellow}',
    '#${ansi_brblue}',
    '#${ansi_brmagenta}',
    '#${ansi_brcyan}',
    '#${ansi_brwhite}',
  },
}

return config
