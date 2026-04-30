@define-color base #${base};
@define-color mantle #${mantle};
@define-color crust #${crust};
@define-color surface0 #${surface0};
@define-color surface1 #${surface1};
@define-color text #${text};
@define-color subtext #${subtext};
@define-color blue #${blue};
@define-color mauve #${mauve};
@define-color green #${green};
@define-color red #${red};
@define-color peach #${peach};
@define-color yellow #${yellow};

* {
  border: none;
  border-radius: 0;
  font-family: "JetBrainsMono Nerd Font", sans-serif;
  font-size: 13px;
  font-weight: 500;
  min-height: 0;
}

window#waybar {
  background: transparent;
  color: @text;
}

window#waybar > box {
  background: alpha(@base, 0.85);
  border-radius: 12px;
  border: 1px solid alpha(@surface1, 0.6);
}

#clock {
  margin-left: 6px;
  color: @text;
  font-weight: 600;
}

#network {
  color: @mauve;
}

#pulseaudio {
  color: @blue;
}

#pulseaudio.muted {
  color: @surface1;
}

#battery {
  color: @green;
}

#battery.warning {
  color: @yellow;
}

#battery.critical {
  color: @red;
  animation: blink 1s linear infinite;
}

@keyframes blink {
  to { color: @text; }
}

#clock,
#network,
#pulseaudio,
#battery,
#tray {
  padding: 4px 12px;
  margin: 4px 2px;
}

#tray {
  margin-right: 6px;
}

tooltip {
  background: @base;
  border: 1px solid @surface1;
  border-radius: 8px;
  color: @text;
}
