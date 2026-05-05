hostname := `hostname`

rebuild:
    hyprctl keyword misc:disable_autoreload true >/dev/null 2>&1 || true
    sudo nixos-rebuild switch --flake .#{{hostname}} --impure

theme name:
    theme-set {{name}}
