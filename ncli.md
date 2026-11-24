# NCLI — DawnbreakOS Command-Line Utility

NCLI is the command-line utility included with DawnbreakOS. It wraps common NixOS maintenance and host-management operations.

## Usage

```bash
ncli <command> [options]
```

To display the built-in help:

```bash
ncli help
```

## Command reference

| Command | Description | Example |
| --- | --- | --- |
| `cleanup` | Interactively clean old system generations. | `ncli cleanup` |
| `diag` | Write a full `inxi` diagnostic report to `~/diag.txt`. | `ncli diag` |
| `list-gens` | List user and system generations. | `ncli list-gens` |
| `rebuild` | Build and activate the selected NixOS configuration. | `ncli rebuild` |
| `rebuild-boot` | Build the selected configuration and set it as the boot default for the next restart. | `ncli rebuild-boot` |
| `trim` | Ask for confirmation, then run `sudo fstrim -v /`. | `ncli trim` |
| `update` | Update flake inputs and rebuild/activate the system. | `ncli update` |
| `update-host` | Set the host and profile values in `flake.nix`, either explicitly or through hardware detection. | `ncli update-host my-host amd` |
| `add-host` | Copy the default host template to a new host directory and configure its profile. | `ncli add-host my-host amd` |
| `del-host` | Delete a host directory after confirmation. | `ncli del-host my-old-host` |
| `fetch` | Display a DawnbreakOS and hardware summary. | `ncli fetch` |
| `help` | Display the built-in help. | `ncli help` |

## Build options

The `rebuild`, `rebuild-boot`, and `update` commands accept these options:

| Option | Alias | Description |
| --- | --- | --- |
| `--dry` | `-n` | Pass a dry-run request to `nh`. |
| `--ask` | `-a` | Ask for confirmation through `nh`. |
| `--cores N` | — | Limit the build to `N` CPU cores. |
| `--verbose` | `-v` | Enable verbose output. |
| `--no-nom` | — | Disable nix-output-monitor output. |

Examples:

```bash
# Preview a rebuild
ncli rebuild --dry

# Ask before an update
ncli update --ask

# Limit a build to four cores
ncli rebuild --cores 4

# Combine options
ncli update --dry --verbose --cores 4
```

## System commands

### `ncli cleanup`

Prompts for the number of generations to keep.

- Press Enter to request cleanup that removes all but the current generation.
- Enter a number to keep that many recent generations.
- The command asks for confirmation before running `nh clean all`.

Cleanup logs are written to `~/ncli-cleanup-logs/`. Log files older than three days are deleted during the cleanup process.

### `ncli diag`

Runs:

```bash
inxi --full
```

The output is saved to `~/diag.txt`.

### `ncli list-gens`

Displays user generations with `nix-env --list-generations`, followed by system profile history from `/nix/var/nix/profiles/system`.

### `ncli rebuild`

Runs the pre-build checks and then:

```bash
nh os switch --diff always --hostname <profile>
```

The command activates the new configuration if the build succeeds.

### `ncli rebuild-boot`

Runs the pre-build checks and then:

```bash
nh os boot --diff always --hostname <profile>
```

The new configuration is set as the boot default and becomes active after restarting.

### `ncli update`

Runs the pre-build checks and then:

```bash
nh os switch --diff always --hostname <profile> --update
```

This updates the flake inputs and rebuilds/activates the system.

### `ncli trim`

Asks for confirmation before running:

```bash
sudo fstrim -v /
```

### `ncli fetch`

Displays a custom DawnbreakOS summary. The displayed information includes:

- Configured host, profile, and username.
- Kernel and Hyprland versions.
- Host model, CPU, and GPU.
- Memory use, root filesystem use, and uptime.
- Git working-tree status, branch, and short commit hash.
- Current system generation.

## Host management

### `ncli update-host`

There are two supported forms:

```bash
# Detect the current hostname and GPU profile
ncli update-host

# Set both values explicitly
ncli update-host <hostname> <profile>
```

The command edits the `host` and `profile` assignments in `~/dawnbreakos/flake.nix`. Automatic detection uses the current system hostname and `lspci`/virtualization information.

### `ncli add-host`

```bash
ncli add-host [hostname] [profile]
```

The command copies `hosts/default` to `hosts/<hostname>`. If the hostname is omitted, it prompts for one. It then attempts to detect the GPU profile, asks for confirmation, and can generate `hardware.nix` using `nixos-generate-config`. Finally, it stages the repository changes with `git add .`.

Choose a profile that is exported by `flake.nix`.

### `ncli del-host`

```bash
ncli del-host [hostname]
```

If the hostname is omitted, the command prompts for it. It asks for confirmation before deleting `hosts/<hostname>` and then stages the repository changes with `git add .`.

## Automatic pre-build cleanup

> **Read this section before running `rebuild`, `rebuild-boot`, or `update`.**

All three commands run `hm-find` before building. In the current repository, `modules/home/scripts/hm-find.nix`:

1. Searches the system journal for Home Manager backup conflicts from the last 30 minutes.
2. Extracts the paths reported as conflicting.
3. Deletes the matching paths automatically.
4. Writes a log under `~/hm-logs/`.

No confirmation is requested before these matching paths are deleted.

After `hm-find`, NCLI runs its configured backup-file cleanup. The current NCLI configuration includes:

```text
.config/mimeapps.list.backup
```

If `~/.config/mimeapps.list.backup` exists, NCLI removes it.

Review the affected paths and preserve anything you need before running a build command, since these files are deleted automatically.

## Hostname validation

Before `rebuild`, `rebuild-boot`, and `update`, NCLI checks that:

- The `host` value in `~/dawnbreakos/flake.nix` is present.
- The current system hostname matches that value.
- `~/dawnbreakos/hosts/<hostname>/` exists.

If one of these checks fails, the command exits before building. Use `ncli update-host` or edit `flake.nix` manually, then verify the host directory.
