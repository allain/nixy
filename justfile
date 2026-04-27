hostname := `hostname`

rebuild:
    sudo nixos-rebuild switch --flake .#{{hostname}} --impure
