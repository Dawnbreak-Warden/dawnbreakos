{
  config,
  pkgs,
  username,
  profile,
  ...
}: {
  home.packages = [
    (import ./hm-find.nix {inherit pkgs;})
    (import ./nvidia-offload.nix {inherit pkgs;})
    (import ./screenshootin.nix {inherit pkgs;})
    (import ./squirtle.nix {inherit pkgs;})
    (import ./ncli.nix {
      inherit pkgs profile;
      backupFiles = [
        ".config/mimeapps.list.backup"
      ];
    })
  ];
}
