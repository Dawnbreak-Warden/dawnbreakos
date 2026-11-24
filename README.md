# DawnbreakOS

DawnbreakOS is a NixOS configuration built around Hyprland, Quickshell, and Home Manager. It brings the system configuration, desktop environment, applications, scripts, and user settings together in one flake-based repository.

The configuration is organized for multiple machines: the host directory contains machine-specific settings, while shared modules and hardware profiles provide the common system configuration.

## What is included

- **NixOS and Home Manager:** declarative system and user configuration.
- **Hyprland:** the Wayland compositor and its window-management configuration.
- **Quickshell:** the desktop shell configuration is maintained in this repository under `modules/home/ii/` and deployed to `~/.config/quickshell/ii`.
- **Dawnbreak Quickshell plugin:** packaged locally from `vendor/dawnbreak-plugin`; it is not fetched as a separate CLI application.
- **Hardware profiles:** AMD, Intel, NVIDIA, hybrid NVIDIA laptop, AMD/NVIDIA hybrid, and virtual-machine configurations.
- **Stylix:** system-wide theming, with the image selected per host.
- **Nixvim:** the Neovim configuration.
- **Flatpak:** declarative Flatpak application management.
- **NCLI:** a command-line utility for rebuilds, updates, host management, diagnostics, and maintenance.

## Requirements and current scope

- A working **NixOS** installation.
- An **x86_64-linux** system. The current `flake.nix` sets `system = "x86_64-linux"`.
- Nix flakes enabled.
- A host configuration matching the machine being configured.
- A supported hardware profile selected in `flake.nix`.

The current flake exposes these configuration names:

| Profile | Intended hardware |
| --- | --- |
| `amd` | AMD graphics |
| `intel` | Intel graphics |
| `nvidia` | NVIDIA graphics |
| `nvidia-laptop` | Intel/NVIDIA hybrid laptop |
| `amd-nvidia-hybrid` | AMD/NVIDIA hybrid graphics |
| `vm` | Virtual machine |

The profile names above are the keys in `flake.nix` under `nixosConfigurations`. Use those exact names when selecting a build target.

## Installation

The installer prepares a host configuration and starts the initial NixOS build.

### 1. Enter a temporary shell with the required tools

```bash
nix-shell -p git curl pciutils
```

### 2. Run the installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Dawnbreak-Warden/dawnbreakos/main/install-dawnbreakos.sh)
```

The installer prompts for the hostname, hardware profile, Git identity, timezone, keyboard layout, and related host settings. Review the configuration summary before confirming the installation.

If `~/dawnbreakos` already exists, the installer asks for explicit confirmation before moving the existing directory into `~/.config/dawnbreakos-backups/`.

### Manual host setup

If you prefer to configure the repository yourself, clone it and create a host from the default template:

```bash
git clone https://github.com/Dawnbreak-Warden/dawnbreakos.git ~/dawnbreakos
cd ~/dawnbreakos
cp -r hosts/default hosts/my-host
sudo nixos-generate-config --show-hardware-config > hosts/my-host/hardware.nix
```

Edit `host`, `profile`, and `username` near the top of `flake.nix`. Then configure `hosts/my-host/variables.nix` and `hosts/my-host/host-packages.nix`.

Add the new host files to Git before building, because Git-based flakes omit untracked files:

```bash
git add flake.nix hosts/my-host
```

For example, build the AMD profile with:

```bash
sudo nixos-rebuild switch --flake ~/dawnbreakos#amd
```

Replace `amd` with the profile selected for the machine.

## Configuration guide

### Host-specific settings

Edit `hosts/<HOSTNAME>/variables.nix` for settings such as:

- Browser and terminal preferences.
- Default MIME application handlers (`mimeDefaultApps`).
- Keyboard layout, keyboard variant, and console keymap.
- Intel, AMD, and NVIDIA PCI IDs for hybrid graphics.
- NFS and printing toggles.
- The Stylix image (`stylixImage`).
- The selected Hyprland animation configuration (`animChoice`).

### Packages

- `modules/core/packages.nix` contains shared system packages.
- `hosts/<HOSTNAME>/host-packages.nix` contains packages for one host.
- `modules/core/flatpak.nix` contains the shared Flatpak package list.
- Host-specific Flatpak packages can be configured in the host's `host-packages.nix`.

### Desktop configuration

- `modules/home/hyprland/` contains the Hyprland configuration and keybindings.
- `modules/home/ii/` contains the Quickshell configuration deployed to `~/.config/quickshell/ii`.
- `modules/home/kitty.nix` contains the Kitty configuration.
- `modules/core/quickshell.nix` defines the Quickshell system packages and QML import paths.

Inside Hyprland, **Super + /** opens the Quickshell keybinding cheatsheet.

## NCLI

NCLI is included in the Home Manager scripts. Start with:

```bash
ncli help
```

The detailed command reference is in [ncli.md](ncli.md). It covers rebuilds, updates, diagnostics, generation cleanup, host management, and the `fetch` system summary.

**Important:** NCLI's rebuild and update paths currently run `hm-find` automatically. The current `hm-find` script deletes Home Manager backup-conflict files found in the journal's recent 30-minute window without asking for confirmation. NCLI also removes the configured `~/.config/mimeapps.list.backup` file when it exists. Read [ncli.md](ncli.md#automatic-pre-build-cleanup) before using these commands.

## Documentation

- [FAQ](FAQ.md) — host setup, hardware, desktop configuration, packages, and troubleshooting.
- [NCLI reference](ncli.md) — command descriptions, options, and examples.
