hostname := `hostname`

rebuild:
    sudo nixos-rebuild switch --flake .#{{hostname}} --impure

theme name:
    theme-set {{name}}
