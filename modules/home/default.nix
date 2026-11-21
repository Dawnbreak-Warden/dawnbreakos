{host, ...}: let
  vars = import ../../hosts/${host}/variables.nix;
  inherit
    (vars)
    vscodeEnable
    obsEnable
    ;
in {
  imports =
    [
      ./amfora.nix
      ./bash.nix
      ./bashrc-personal.nix
      ./ii.nix
      ./python.nix
      ./cli/bat.nix
      ./cli/btop.nix
      ./cli/bottom.nix
      ./cli/cava.nix
      ./cli/fzf.nix
      ./cli/gh.nix
      ./cli/git.nix
      ./cli/htop.nix
      ./cli/lazygit.nix
      ./eza.nix
      ./gtk.nix
      ./hyprland
      ./kitty.nix
      ./editors/nixvim.nix
      ./editors/nano.nix
      ./qt.nix
      ./scripts
      ./stylix.nix
      ./swappy.nix
      ./virtmanager.nix
      ./xdg.nix
      ./zoxide.nix
      ./zsh
      ./vencord.nix
      ./fuzzel.nix
      ./face.nix
    ]
    ++ (
      if vscodeEnable
      then [./editors/vscode.nix]
      else []
    )
    ++ (
      if obsEnable
      then [./obs-studio.nix]
      else []
    );
}
