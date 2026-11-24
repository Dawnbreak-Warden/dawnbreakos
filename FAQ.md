# DawnbreakOS FAQ

This FAQ describes the configuration in the current repository. Paths are relative to `~/dawnbreakos` unless stated otherwise. Commands and file paths below refer to the current DawnbreakOS layout.

## Hosts and hardware

### What is the difference between a host and a profile?

- A **host** identifies the machine-specific configuration directory under `hosts/`.
- A **profile** selects the hardware configuration exported by `flake.nix`.

The `host`, `profile`, and `username` values are defined near the top of `flake.nix`. The current flake exports these profile names:

- `amd`
- `intel`
- `nvidia`
- `nvidia-laptop`
- `amd-nvidia-hybrid`
- `vm`

Use the exact spelling from `nixosConfigurations`. The host name must match a directory under `hosts/`.

### How do I add another host?

1. Copy the default host template:

   ```bash
   cp -r hosts/default hosts/<HOSTNAME>
   ```

2. Generate the hardware configuration for the target machine:

   ```bash
   sudo nixos-generate-config --show-hardware-config > hosts/<HOSTNAME>/hardware.nix
   ```

3. Edit `flake.nix` and set `host` to `<HOSTNAME>`. Select a valid `profile` from the list above and set `username` to the account name used on the machine.
4. Review `hosts/<HOSTNAME>/variables.nix`, especially the GPU PCI IDs, keyboard settings, and `stylixImage`.
5. Add the new files to Git before building:

   ```bash
   git add flake.nix hosts/<HOSTNAME>
   ```

6. Rebuild the selected configuration:

   ```bash
   ncli rebuild
   ```

A Git-based flake does not include untracked files, so the new host directory must be added to Git before building.

### How do I configure hybrid graphics?

Hybrid graphics requires the correct PCI bus IDs in `hosts/<HOSTNAME>/variables.nix` and the matching profile in `flake.nix`.

1. Find the graphics devices and their PCI addresses:

   ```bash
   lspci -Dnn | grep -E 'VGA|3D|Display'
   ```

   Identify the integrated GPU (Intel or AMD) and the NVIDIA GPU. The `pciutils` package, which provides `lspci`, is included in the system packages.

2. Convert each PCI address to the format used by NixOS. For example, `lspci` may show `0000:00:02.0`. The NixOS ID format is `PCI:device@domain:bus:function`, with the hexadecimal PCI fields converted to decimal. That example becomes `PCI:0@0:2:0`.

3. Edit the relevant values in `hosts/<HOSTNAME>/variables.nix`:

   ```nix
   intelID = "PCI:0@0:2:0";
   amdgpuID = "PCI:5:0:0";
   nvidiaID = "PCI:2@0:0:0";
   ```

   These are template examples, not values to copy blindly. Set the IDs to the addresses reported by your own machine. You only need the integrated-GPU variable used by your chosen profile, plus `nvidiaID`.

4. Choose the matching profile in `flake.nix`:
   - Intel + NVIDIA: `profile = "nvidia-laptop";`
   - AMD + NVIDIA: `profile = "amd-nvidia-hybrid";`

5. Add changed or new files to Git and rebuild:

   ```bash
   git add flake.nix hosts/<HOSTNAME>
   ncli rebuild
   ```

The Intel/NVIDIA profile reads `intelID` and `nvidiaID`. The AMD/NVIDIA profile reads `amdgpuID` and `nvidiaID`. The GPU bus IDs are configured by the selected profile; do not add the old `AQ_DRM_DEVICES` instruction from earlier versions of the FAQ, because that setting is not present in the current Hyprland environment module.

### How do I change the hostname?

The host name used by DawnbreakOS must match the host directory and the system hostname.

1. Copy the existing host directory to the new name:

   ```bash
   cp -rpv hosts/OLD-HOSTNAME hosts/NEW-HOSTNAME
   ```

2. Edit `flake.nix` and change the `host` value:

   ```nix
   host = "NEW-HOSTNAME";
   ```

3. Add the new directory and flake change to Git:

   ```bash
   git add flake.nix hosts/NEW-HOSTNAME
   ```

4. Rebuild:

   ```bash
   ncli rebuild
   ```

5. Reboot so the new system hostname takes effect.

NCLI checks that the running system hostname matches the `host` value in `flake.nix` and that the corresponding `hosts/<HOSTNAME>/` directory exists. A mismatch stops `ncli rebuild`, `ncli rebuild-boot`, and `ncli update`.

### How do I choose a different GPU profile?

Edit the `profile` value near the top of `flake.nix` and use one of the exact names listed under `nixosConfigurations`. Make sure the host's `variables.nix` contains the PCI IDs required by that profile. Add the changed file to Git and run `ncli rebuild`.

## Host settings and applications

### Where do I change the keyboard layout?

Edit these values in `hosts/<HOSTNAME>/variables.nix`:

```nix
keyboardLayout = "us";
keyboardVariant = "";
consoleKeyMap = "us";
```

Set `keyboardLayout` and `keyboardVariant` for the graphical keyboard layout, and `consoleKeyMap` for the Linux console. Save the file and run `ncli rebuild`.

### Where do I change the timezone?

The timezone is currently set in `modules/core/system.nix`:

```nix
time.timeZone = "Asia/Beirut";
```

Change the value to a valid time-zone name, save the file, and run `ncli rebuild`.

### How do I change the default applications for file types?

1. Edit `mimeDefaultApps` in `hosts/<HOSTNAME>/variables.nix`.
2. Set each MIME type or URL scheme to the `.desktop` application ID you want to use. For example:

   ```nix
   mimeDefaultApps = {
     "application/pdf" = [ "org.kde.okular.desktop" ];
     "x-scheme-handler/http" = [ "zen-beta.desktop" ];
     "x-scheme-handler/https" = [ "zen-beta.desktop" ];
     "inode/directory" = [ "nemo.desktop" ];
     "text/plain" = [ "org.kde.kate.desktop" ];
   };
   ```

3. Confirm the application ID matches an installed desktop file, then run `ncli rebuild`.

Home Manager applies the values through `modules/home/xdg.nix`. Changing a default does not install the application; install it separately through the system package or Flatpak configuration.

### How do I add or remove system packages?

There are two package lists:

- **All hosts:** edit `modules/core/packages.nix`, in `environment.systemPackages`.
- **One host:** edit `hosts/<HOSTNAME>/host-packages.nix`, in that file's `environment.systemPackages` list.

Add the Nixpkgs package attribute to the relevant list, or remove its entry to stop declaring it. Then run:

```bash
ncli rebuild
```

### How do I add or remove Flatpaks?

The shared Flatpak list is in `modules/core/flatpak.nix`, under `services.flatpak.packages`.

To add a Flatpak for every host, add its official application ID to that list. To add one only for a particular host, edit `hosts/<HOSTNAME>/host-packages.nix` and uncomment or extend the optional Flatpak block already provided in the host template. For example:

```nix
services = {
  flatpak = {
    packages = [
      "org.mozilla.firefox"
    ];
  };
};
```

Use the application ID shown by Flathub or `flatpak search`. Remove an entry from the corresponding list to stop declaring it in this configuration. Run `ncli rebuild` after editing. You can check installed Flatpaks with:

```bash
flatpak list
```

The shared Flatpak module has `update.onActivation = true`, so declared Flatpaks are configured to update during system activation.

### How do I enable or disable the bundled applications?

The host's `variables.nix` contains application toggles, including:

```nix
vscodeEnable = true;
obsEnable = false;
```

Change the relevant value to `true` or `false`, then run `ncli rebuild`. These toggles control whether the corresponding Home Manager application configuration is imported; they are not a general-purpose package list.

### How do I enable printing or NFS?

Edit the relevant toggle in `hosts/<HOSTNAME>/variables.nix`:

```nix
printEnable = false;
enableNFS = false;
```

Set `printEnable = true;` to enable the printing, Avahi, and IPP-over-USB services configured by `modules/core/printing.nix`. Set `enableNFS = true;` to enable the NFS server and `rpcbind` services configured by `modules/core/nfs.nix`. Run `ncli rebuild` after changing either value.

## Hyprland and Quickshell

### Where are the Hyprland keybindings?

They are defined in `modules/home/hyprland/binds.nix`.

Inside Hyprland, press **Super + /** to open the Quickshell cheatsheet. The keybinding file also contains descriptions for the Quickshell actions and application shortcuts.

Some useful current bindings include:

| Binding | Action |
| --- | --- |
| Super + / | Quickshell keybinding cheatsheet |
| Super + D | Quickshell search |
| Super + Tab | Overview |
| Super + M | Dawnbreak dashboard |
| Super + Shift + K | Keybindings search tool |
| Super + Shift + W | Apply wallpaper |
| Super + Ctrl + T | Wallpaper selector |
| Super + Ctrl + Alt + T | Select a random wallpaper |
| Super + Return | Terminal |
| Super + W | Browser |
| Super + E | File manager |

To change a binding, edit its `hl.bind(...)` entry in `binds.nix`, save the file, and run `ncli rebuild`. Log out and back in if the changed binding does not become active immediately.

### How do I switch between the Dwindle and Master layouts?

Use the built-in layout shortcuts:

- **Super + Alt + 1:** Dwindle
- **Super + Alt + 2:** Master
- **Super + Alt + 3:** Scrolling
- **Super + Alt + 4:** Monocle

Dwindle splits the available area into a sequence of tiled regions. Master keeps a primary window in a larger area and arranges the remaining windows in a secondary area. Scrolling and Monocle are also available through the shortcuts above.

To check the active layout, run:

```bash
hyprctl getoption general:layout
```

The default layout is `dwindle`, set in `modules/home/hyprland/hyprland.nix`. The shortcuts are defined in `modules/home/hyprland/binds.nix`.

### Where are the Quickshell files?

The Quickshell configuration is maintained in `modules/home/ii/`. The Home Manager activation in `modules/home/ii.nix` copies this directory to:

```text
~/.config/quickshell/ii
```

Edit the repository files, not only the deployed copy, if you want your changes to persist through a rebuild.

The local Dawnbreak plugin is packaged from `vendor/dawnbreak-plugin` by `modules/core/quickshell.nix`. The QML import paths are configured there as well.

### How do I change the Stylix wallpaper or color source?

1. Add the image you want to use to the repository's `wallpapers/` directory.
2. Edit `stylixImage` in `hosts/<HOSTNAME>/variables.nix` to point to it. For example:

   ```nix
   stylixImage = ../../wallpapers/Dazai-kun.png;
   ```

3. Add the image and changed configuration to Git, then run `ncli rebuild`.

The image is used by `modules/core/stylix.nix` as Stylix's source image for the generated color scheme.

### How do I add more wallpapers and change the desktop background?

1. Copy the new image files into `wallpapers/`.
2. Add the new files to Git and run `ncli rebuild`. The Hyprland Home Manager module copies the repository wallpapers to `~/Pictures/Wallpapers`.
3. Open the wallpaper selector with **Super + Ctrl + T** and choose an image. To apply a random wallpaper, press **Super + Ctrl + Alt + T**.

**Super + Shift + W** runs the wallpaper-apply action. The wallpaper selector and actions are implemented by the current Quickshell configuration.

### How do I change the Hyprland animation preset?

Edit `animChoice` in `hosts/<HOSTNAME>/variables.nix`. Choose one of the preset paths shown in the comments in that file, and make sure only the intended assignment is active. The current template uses `animations-dynamic.nix`.

Save the file and run `ncli rebuild` to deploy the selected preset.

## NCLI and maintenance

### What is NCLI and how do I use it?

NCLI is the DawnbreakOS command-line utility. Run:

```bash
ncli help
```

The current commands include:

| Command | Purpose |
| --- | --- |
| `cleanup` | Remove older system and user generations, with a keep-count prompt |
| `diag` | Create a hardware and system diagnostic report at `~/diag.txt` |
| `list-gens` | List system and user generations |
| `rebuild` | Build and activate the current configuration |
| `rebuild-boot` | Build the configuration and set it as the boot default for the next restart |
| `trim` | Run filesystem trimming after confirmation |
| `update` | Update flake inputs and rebuild |
| `update-host` | Set or detect the host and profile values in `flake.nix` |
| `add-host` | Create a host configuration from the default template |
| `del-host` | Remove a host configuration after confirmation |
| `fetch` | Display a summary of the current system and repository state |

For command options, examples, and the automatic pre-build cleanup behavior, see [ncli.md](ncli.md).

### How do I rebuild after changing configuration?

Run:

```bash
ncli rebuild
```

If you created a new file, add it to Git first. For example:

```bash
git add path/to/new-file.nix
```

A successful rebuild creates and activates a new system generation. Depending on what changed, you may need to restart a service, log out, or reboot.

Use `ncli rebuild-boot` when you want to build a new generation and set it as the boot default without activating it in the current session. Reboot to start that generation.

### How do I update the flake inputs and installed packages?

Run:

```bash
ncli update
```

This updates the flake inputs and then builds and activates the updated system configuration. Review the changes and make sure your working tree is in the state you want before updating.

### How do I update DawnbreakOS itself from Git?

Updating the repository source and updating the flake inputs are separate operations. To pull changes from the Git remote:

1. Back up the repository or make sure your local changes are committed.
2. From `~/dawnbreakos`, check the working tree:

   ```bash
   git status
   ```

3. Commit or stash local changes before pulling. If you maintain your own fork, push your commits first if you want them preserved remotely.
4. Pull the intended branch from its remote:

   ```bash
   git pull --rebase
   ```

5. Review and resolve any merge or rebase conflicts, then run `ncli rebuild` to build the repository configuration you just pulled.
6. When you also want newer dependency revisions, run `ncli update`.

Do not use `git stash` or overwrite local files without checking whether they contain changes you want to keep. If you have customized the repository, review upstream changes before applying them.

### How do I list system and user generations?

Run:

```bash
ncli list-gens
```

### How do I clean old generations?

Run:

```bash
ncli cleanup
```

The command asks how many generations to keep:

- Press Enter to request cleanup that keeps only the current generation.
- Enter a number to keep that many recent generations.

It asks for confirmation before running the cleanup. Logs are written under `~/ncli-cleanup-logs`; log files older than three days are removed during cleanup. Make sure the currently working system is healthy before removing older rollback options.

### How do I create a diagnostic report?

Run:

```bash
ncli diag
```

NCLI runs `inxi --full` and writes the report to:

```text
~/diag.txt
```

### What does `ncli fetch` show?

It displays a DawnbreakOS system summary, including the configured host, profile, username, kernel, Hyprland version, hardware details, memory, disk usage, uptime, Git working-tree status, branch, commit, and current system generation.

### How do I trim the filesystem?

Run:

```bash
ncli trim
```

NCLI asks for confirmation before running `sudo fstrim -v /`.

### What happens when NCLI runs `hm-find`?

`ncli rebuild`, `ncli rebuild-boot`, and `ncli update` run `hm-find` before the build.

The helper searches the journal for Home Manager backup conflicts from the last 30 minutes. If it finds matching paths, it deletes them automatically; the confirmation prompt in the script is commented out. It writes a log under `~/hm-logs/`.

NCLI also checks its configured backup-file list. The current list includes:

```text
.config/mimeapps.list.backup
```

If that file exists, NCLI removes it. Review these behaviors before running a rebuild or update if you need to preserve any matching files.

## Boot and kernel configuration

### How do I disable or enable the startup Plymouth screen?

Edit `modules/core/boot.nix`. The current setting is:

```nix
plymouth.enable = false;
```

Set it to `true` to enable Plymouth or `false` to disable it. Save the file and run `ncli rebuild`. The change takes effect on the next boot.

### How do I change the kernel for one host?

The shared default is set in `modules/core/boot.nix`:

```nix
kernelPackages = pkgs.linuxPackages_latest;
```

To override it for only one host, create `hosts/<HOSTNAME>/core/kernel.nix`:

```nix
{ pkgs, lib, ... }:
{
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_zen;
}
```

Then add that file to the host's `hosts/<HOSTNAME>/core/default.nix` imports. For example:

```nix
{ username, ... }: {
  imports = [
    ./services.nix
    ./kernel.nix
  ];
}
```

Replace `pkgs.linuxPackages_zen` with the kernel package set you intend to use, if it is available in the Nixpkgs revision pinned by your flake. Common choices include the default `linuxPackages`, `linuxPackages_latest`, `linuxPackages_zen`, and `linuxPackages_hardened`. Then add the new module to Git and run `ncli rebuild`. Reboot to start the new kernel.

To change the kernel for every host instead, edit the `kernelPackages` assignment in `modules/core/boot.nix` directly.

### What are the common NixOS kernel package sets?

The kernel package set determines which Linux kernel build NixOS installs. Common choices include:

- `pkgs.linuxPackages`: the default kernel package set selected by the Nixpkgs revision.
- `pkgs.linuxPackages_latest`: the latest kernel package set provided by that Nixpkgs revision. This is the current DawnbreakOS default.
- `pkgs.linuxPackages_zen`: a kernel package set with desktop-oriented patches.
- `pkgs.linuxPackages_hardened`: a security-hardening-oriented kernel package set.
- `pkgs.linuxPackages_rt`: a real-time kernel package set, where available.

The exact versions and available attributes can change with the flake's Nixpkgs input. Check the pinned revision before choosing a less common kernel package set.

## Fonts and terminals

### Which fonts are installed, and where do I add more?

The system font package list is in `modules/core/fonts.nix`. It currently includes families and packages such as DejaVu, Fira Code, IBM Plex, Inter, JetBrains Mono, Maple Mono NF, Noto, Roboto, Terminus, and several Nerd Fonts.

To add or remove a font, edit the `fonts.packages` list in that file using the corresponding Nixpkgs package attribute. Save the file and run `ncli rebuild`.

Stylix separately selects the fonts used by themed applications in `modules/core/stylix.nix`: JetBrains Mono for monospace and Montserrat for sans-serif and serif text. Changing the installed font list does not automatically change Stylix's selected font; edit the Stylix font settings as well if that is what you want to change.

### My Kitty cursor trail feels distracting. How do I turn it off?

Kitty's cursor trail is configured in `modules/home/kitty.nix`:

```nix
cursor_trail = 1;
```

Change it to `cursor_trail = 0;`, save the file, and run `ncli rebuild`.

### Where are Kitty's keybindings, and how do I change them?

Kitty is configured in `modules/home/kitty.nix`. Its current custom keybindings include:

```text
# Clipboard
ctrl+shift+v        paste_from_clipboard
shift+insert        paste_from_clipboard

# Scrolling
ctrl+shift+up        scroll_line_up
ctrl+shift+down      scroll_line_down
ctrl+shift+k         scroll_line_up
ctrl+shift+j         scroll_line_down
ctrl+shift+page_up   scroll_page_up
ctrl+shift+page_down scroll_page_down
ctrl+shift+home      scroll_home
ctrl+shift+end       scroll_end
ctrl+shift+h         show_scrollback

# Window management
alt+n               new_window_with_cwd
alt+w               close_window
ctrl+shift+enter    launch --location=hsplit
ctrl+shift+s        launch --location=vsplit
ctrl+shift+]        next_window
ctrl+shift+[        previous_window
ctrl+shift+f        move_window_forward
ctrl+shift+b        move_window_backward
ctrl+shift+`        move_window_to_top

# Tabs
ctrl+shift+right    next_tab
ctrl+shift+left     previous_tab
ctrl+shift+t        new_tab
ctrl+shift+q        close_tab
ctrl+shift+l        next_layout
ctrl+shift+.        move_tab_forward
ctrl+shift+,        move_tab_backward
```

Edit the relevant mapping in the `extraConfig` section of `modules/home/kitty.nix`, then run `ncli rebuild`.

## NixOS concepts and learning resources

### What are Nix flakes?

A flake is a standardized way to describe a Nix project and its inputs and outputs. In DawnbreakOS, `flake.nix` declares dependencies such as Nixpkgs and Home Manager and defines the `nixosConfigurations` outputs. `flake.lock` records the exact revisions of those inputs so builds can be reproduced against the locked versions.

DawnbreakOS already enables the required experimental features in `modules/core/system.nix`:

```nix
experimental-features = [ "nix-command" "flakes" ];
```

For more information, see the [NixOS Flakes Wiki](https://wiki.nixos.org/wiki/Flakes) and the [NixOS and Flakes book](https://nixos-and-flakes.thiscute.world/preface).

### What is Home Manager?

Home Manager is the Nix project used here to manage user-level applications and configuration files declaratively. DawnbreakOS imports Home Manager through the flake and uses modules under `modules/home/` and each host's `home/` directory.

- Shared user configuration belongs under `modules/home/`.
- Host-specific user configuration belongs under `hosts/<HOSTNAME>/home/`.
- The Quickshell deployment, for example, is managed by `modules/home/ii.nix`.

After changing a Home Manager module, run `ncli rebuild` so the new user configuration is activated with the system.

### What are NixOS generations and why are builds described as atomic?

A successful NixOS rebuild creates a new system generation and switches the system to it. Existing generations remain available as rollback choices until they are removed by garbage collection or generation cleanup. If a build fails, Nix does not replace the currently active generation with a partially built one.

You can list generations with `ncli list-gens`, clean older generations with `ncli cleanup`, and select an earlier generation from the boot menu when needed. Keep a known-good generation until you have confirmed that the new configuration works.

### I am new to NixOS. Where can I learn more?

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [NixOS Wiki](https://wiki.nixos.org/)
- [NixOS and Flakes book](https://nixos-and-flakes.thiscute.world/preface)
- [Vimjoyer YouTube channel](https://www.youtube.com/@vimjoyer/videos)
- [LibrePhoenix YouTube channel](https://www.youtube.com/@librephoenix)
- [NixOS configuration guide video](https://www.youtube.com/watch?v=AGVXJ-TIv3Y&t=34s)
- [NixOS video series](https://www.youtube.com/watch?v=QKoQ1gKJY5A&list=PL-saUBvIJzOkjAw_vOac75v-x6EzNzZq-)

### Where can I learn Git?

- [Pro Git book](https://git-scm.com/book/en/v2)
- [Git documentation](https://git-scm.com/doc)
- [Managing a NixOS configuration with Git](https://www.youtube.com/watch?v=20BN4gqHwaQ)
- [How Git works](https://www.youtube.com/watch?v=e9lnsKot_SQ)

## Troubleshooting

### NCLI says the hostname does not match

Check that:

- `host` in `flake.nix` matches the output of `hostname`.
- `hosts/<HOSTNAME>/` exists.
- The host directory and `flake.nix` changes have been added to Git.

Then retry the NCLI command.

### A rebuild fails because a file would clobber a Home Manager backup

NCLI runs `hm-find` automatically, but that script may delete the conflict paths it detects. Check `~/hm-logs/` for its log output. If the failure remains, inspect the Home Manager activation messages in the journal and resolve the specific file conflict deliberately.

### A newly created host or file is missing from the build

For Git-based flakes, untracked files are not part of the flake source. Add the relevant files:

```bash
git add flake.nix hosts/<HOSTNAME>
```

Then run the build again.

## Repository map

```text
dawnbreakos/
├── hosts/
│   ├── default/              # Host template
│   └── <HOSTNAME>/           # Machine-specific configuration
├── modules/
│   ├── core/                 # Shared NixOS modules, packages, services, fonts
│   └── home/                 # Home Manager modules and desktop configuration
│       ├── hyprland/         # Hyprland settings, bindings, animations
│       ├── ii/               # Quickshell source
│       └── scripts/          # User scripts
├── profiles/                 # Hardware profile definitions
├── vendor/
│   └── dawnbreak-plugin/     # Local Quickshell plugin source
├── wallpapers/               # Wallpaper images
├── FAQ.md
├── flake.nix
├── install-dawnbreakos.sh
├── ncli.md
└── README.md
```

This is a focused map of the main configuration areas, not an exhaustive listing of every file.
