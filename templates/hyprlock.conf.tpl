background {
    monitor =
    color = rgb(${base})
}

input-field {
    monitor =
    size = 300, 50
    outline_thickness = 2
    dots_size = 0.25
    dots_spacing = 0.2
    outer_color = rgba(${blue}ee)
    inner_color = rgba(${base}ee)
    font_color = rgba(${text}ff)
    fade_on_empty = true
    placeholder_text = <i>Password...</i>
    hide_input = false
    position = 0, -20
    halign = center
    valign = center
}

label {
    monitor =
    text = $TIME
    font_size = 64
    font_family = JetBrainsMono Nerd Font
    color = rgba(${text}ff)
    position = 0, 120
    halign = center
    valign = center
}

label {
    monitor =
    text = cmd[update:3600000] date +"%A, %B %d"
    font_size = 20
    font_family = JetBrainsMono Nerd Font
    color = rgba(${subtext}ff)
    position = 0, 60
    halign = center
    valign = center
}
