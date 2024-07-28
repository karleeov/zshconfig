local wezterm = require 'wezterm'

local wsl_domains = wezterm.default_wsl_domains()

wezterm.on("gui-startup", function(cmd)
  wezterm.mux.spawn_window(cmd or {})
end)

for _, domain in ipairs(wsl_domains) do
  domain.default_cwd = "~"
end

return {
  default_prog = { 'wsl', '--distribution', 'Arch' },
  font = wezterm.font {
    family = 'FiraCode Nerd Font Mono',
    weight = 'Light',
    stretch = 'Normal',
    style = 'Normal',
    harfbuzz_features = { 'cv29', 'cv30', 'ss01', 'ss03', 'ss06', 'ss07', 'ss09' },
  },
  font_size = 12,
  color_schemes = {
    ['Custom Cyberpunk'] = {
      foreground = '#00ff9f',
      background = '#000000',
      cursor_bg = '#00ff9f',
      cursor_border = '#00ff9f',
      cursor_fg = '#000000',
      selection_bg = '#00b8ff',
      selection_fg = '#000000',

      ansi = {'#000000', '#bd00ff', '#00ff9f', '#d600ff', '#00b8ff', '#001eff', '#00ff9f', '#ffffff'},
      brights = {'#000000', '#bd00ff', '#00ff9f', '#d600ff', '#00b8ff', '#001eff', '#00ff9f', '#ffffff'},
    },
  },
  color_scheme = 'Custom Cyberpunk',
  adjust_window_size_when_changing_font_size = false,
  audible_bell = 'Disabled',
  background = {
    {
      source = { File = "/Users/vlad/btsync/agilenet/nodes/common/WezTerm/themes/catpuccin/frappe/background.png" },
    },
    {
      source = { File = "/Users/vlad/btsync/agilenet/nodes/common/WezTerm/backgrounds/devinsideyou/office-1080p.png" },
      horizontal_align = 'Center',
      vertical_align = 'Middle',
      height = 'Contain',
      width = 'Contain',
      repeat_x = 'NoRepeat',
      repeat_y = 'NoRepeat',
      opacity = 0.5
    },
  },
  disable_default_key_bindings = true,
  exit_behavior = 'Close',
  force_reverse_video_cursor = true,
  hide_mouse_cursor_when_typing = true,
  hide_tab_bar_if_only_one_tab = true,
  keys = {
    { action = wezterm.action.ActivateCommandPalette, mods = 'CTRL|SHIFT', key = 'P' },
    { action = wezterm.action.CopyTo 'Clipboard', mods = 'CTRL', key = 'C' },
    { action = wezterm.action.PasteFrom 'Clipboard', mods = 'CTRL', key = 'V' },
    { action = wezterm.action.DecreaseFontSize, mods = 'CTRL', key = '-' },
    { action = wezterm.action.IncreaseFontSize, mods = 'CTRL', key = '=' },
    { action = wezterm.action.Nop, mods = 'ALT', key = 'Enter' },
    { action = wezterm.action.ResetFontSize, mods = 'CTRL', key = '0' },
    { action = wezterm.action.ToggleFullScreen, key = 'F11' },
    { action = wezterm.action_callback(function(window, pane)
        window:perform_action(wezterm.action.SpawnCommandInNewTab {
          args = {'wsl', '--distribution', 'Ubuntu-22.04'}
        }, pane)
      end), mods = 'CTRL|SHIFT', key = 'U' },
    { action = wezterm.action_callback(function(window, pane)
        window:perform_action(wezterm.action.SpawnCommandInNewTab {
          args = {'wsl', '--distribution', 'Arch'}
        }, pane)
      end), mods = 'CTRL|SHIFT', key = 'A' },
  },
  scrollback_lines = 10000,
  show_update_window = true,
  use_dead_keys = false,
  unicode_version = 15,
  macos_window_background_blur = 100,
  window_close_confirmation = 'NeverPrompt',
  window_padding = {
    left = 0,
    right = 0,
    top = '0.6cell',
    bottom = 0,
  },
  wsl_domains = wsl_domains,
}

