<div align="center">

## Dapheen — My Hyprland Dotfiles

A clean and simple Hyprland setup focused on practical keybinds, productivity, and easy to customize.

This repository is my personal customization of the original [43PR/dotfiles](https://github.com/43PR/dotfiles) project. Credit goes to **43PR** for the original setup. My changes include the Dapheen theme-system migration, custom widgets, keybindings, application styling, and other personal modifications.

![Hyprland](https://img.shields.io/badge/Hyprland-0.56.2-8b9aaf?style=for-the-badge&labelColor=101418)
![GitHub repo size](https://img.shields.io/github/repo-size/CodeSmith707/dapheen-dotfiles?style=for-the-badge&labelColor=101418&color=8b9aaf)
[![Discord](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fdiscord.com%2Fapi%2Finvites%2FHQwU9SzHj%3Fwith_counts%3Dtrue&query=%24.approximate_member_count&style=for-the-badge&logo=discord&logoColor=ffffff&label=discord&labelColor=101418&color=7289a8)](https://discord.gg/HQwU9SzHj)

### **[Features](#features)  -  [Keybinds](#most-used-keybinds)  -  [Installation](#installation) -  [Updating](#updating)**

</div>

**v1.2.0**

<img width="1920" height="1080" alt="v1 2 0" src="https://github.com/user-attachments/assets/3b4857bc-285a-473a-924c-be89dab714b9" />

<img width="1920" height="1080" alt="1791338767" src="https://github.com/user-attachments/assets/d2b9999a-9939-410d-9980-11e97b448d78" />

## Features

- **Top bar** - Customizing options, vertical bar, styles, calendar, controls for volume and media playback.
- **Settings Menu** — System, network, bluetooth, display, audio, storage, themes, and more.
- **Wallpaper picker & Dynamic Colors** — Custom wallpaper selector with automatic wallpaper-based color generation.
- **Preset Themes** — Default Monochrome, Nord, Tokyo Night, etc, and easily create your own. 
- **App Launcher** — **Rofi** Application search, clipboard history, and opacity control.
- **Zsh + Starship** — Customizable shell with autosuggestions and history.
- **Customizable Power Menu** —  Custom power menu. 
- **Notes / To do** —  Custom quick Notes/To-do. 
- **Hyprlock** — Custom lock screen.
- **Spotify + Spicetify** — Custom theme based on **text - darkthemer**, (modified).
- **Custom Scripts** — Scripts for workflow and system management.

> All programs: [packages.txt](packages.txt)

### Wallpaper Selector

Just made some tweaks to it. Give it some love: [hyprquickpaper](https://github.com/iamsurjog/hyprquickpaper)

## Most used keybinds

## ⌨️ Custom Keybindings

These dotfiles use **Super (Windows key)** as the main modifier for most shortcuts. The bindings below reflect my customized Hyprland setup and Quickshell widgets.

### Applications and Launchers

| Shortcut | Action |
|---|---|
| `Super + T` | Open terminal (Kitty) |
| `Super + D` | Toggle application launcher (Rofi) |
| `Super + S` | Toggle wheel launcher |
| `Super + E` | Open file manager |
| `Super + B` | Open browser |
| `Super + Q` | Close active window |
| `Super + Tab` | Lock screen (Hyprlock) |
| `Super + Shift + E` | Exit Hyprland |

### Quickshell Widgets

| Shortcut | Action |
|---|---|
| `Super + Grave (\`)` | Toggle power menu |
| `Super + I` | Toggle settings |
| `Super + ,` | Toggle emoji picker |
| `Super + W` | Open wallpaper picker |
| `Super + N` | Toggle notifications |
| `Super + C` | Toggle TODO widget |
| `Super + Shift + W` | Toggle status bar |
| `Super + /` | Toggle keyboard shortcuts cheat sheet |
| `Alt + Tab` | Toggle Scroll Overview for switching between windows |

### Window Management

| Shortcut | Action |
|---|---|
| `Super + F` | Toggle fullscreen |
| `Super + Space` | Toggle floating mode; center and resize the window when floating |
| `Super + O` | Run window opacity script |
| `Super + Left` | Focus window to the left |
| `Super + Right` | Focus window to the right |
| `Super + Up` | Focus window above |
| `Super + Down` | Focus window below |
| `Super + Shift + Left` | Move active window left |
| `Super + Shift + Right` | Move active window right |
| `Super + Shift + Up` | Move active window up |
| `Super + Shift + Down` | Move active window down |
| `Super + Ctrl + H` | Resize active window horizontally, narrower |
| `Super + Ctrl + L` | Resize active window horizontally, wider |
| `Super + Ctrl + K` | Resize active window vertically, shorter |
| `Super + Ctrl + J` | Resize active window vertically, taller |
| `Super + Left Mouse Button (hold)` | Drag window |
| `Super + Right Mouse Button (hold)` | Resize window |

### Workspaces

| Shortcut | Action |
|---|---|
| `Super + 1–9` | Switch to workspace 1–9 |
| `Super + 0` | Switch to workspace 10 |
| `Super + Shift + 1–9` | Move active window to workspace 1–9 |
| `Super + Shift + 0` | Move active window to workspace 10 |

### Themes and Appearance

| Shortcut | Action |
|---|---|
| `Super + L` | Toggle light/dark theme |
| `Super + O` | Run window opacity script |
| `Super + Mouse Wheel Down` | Decrease cursor zoom |
| `Super + Mouse Wheel Up` | Increase cursor zoom |
| `Super + Keypad Zoom Keys` | Adjust cursor zoom using the configured keypad bindings |

The cursor zoom is clamped between `1.0` and `1.5`.

### Screenshots

Screenshots use **grim, slurp, Satty, and wl-copy**.

| Shortcut | Action |
|---|---|
| `Delete` | Capture fullscreen screenshot and open it in Satty |
| `Shift + Delete` | Select a screen area and open the capture in Satty |

Satty supports annotation and copying the resulting image to the clipboard. Screenshots are configured to save in `~/Pictures/`.

### Clipboard and Keyboard

| Shortcut | Action |
|---|---|
| `Super + V` | Open clipboard history through cliphist and Rofi |
| `Super + X` | Switch to the next keyboard layout |

### Media and Volume

| Shortcut | Action |
|---|---|
| `Volume Up` | Increase volume by 5% |
| `Volume Down` | Decrease volume by 5% |
| `Mute` | Toggle audio mute |
| `Play/Pause` | Toggle media playback |
| `Next Track` | Skip to next track |
| `Previous Track` | Return to previous track |

Volume and media controls use `wpctl` and `playerctl`.

### Screen Recording

| Shortcut | Action |
|---|---|
| `Super + R` | Start or stop GPU screen recording |

Screen recording uses `gpu-screen-recorder`, captures at 60 FPS, and saves recordings in `~/Videos/`. The current command targets `HDMI-A-1`, so this particular binding may need adjustment on other hardware.

### Notes

- `mainMod` is configured as `Super`.
- The application launcher, wallpaper picker, emoji picker, settings, notifications, TODO widget, and other shell components depend on the installed Rofi and Quickshell configuration.
- Some commands reference external utilities such as `cliphist`, `wl-copy`, `grim`, `slurp`, `satty`, `gpu-screen-recorder`, `wpctl`, and `playerctl`.
- Workspace bindings cover workspaces 1 through 10.
- The keypad zoom bindings use raw keycodes in the current configuration; their physical key labels depend on the keyboard.

> [!note]
>
> **Move and resize windows with Super + left/right mouse drag.**
>
> To close most quickshell apps just click outside or Esc key.
>
> All keybinds: [.config/hypr/keybinds.lua](.config/hypr/keybinds.lua)

---
## Installation 

**READ ALL**

Should work for Arch, Manjaro, EndeavourOS, CachyOS, etc. 

This is mainly intended for a clean installation (existing configuration files that are being replaced will be backed up automatically).

**First install git then use the next command and continue the installation until it's finished**

```bash
sudo pacman -S git   
```

```bash
git clone https://github.com/CodeSmith707/dapheen-dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

After the installation finishes log out and back in.

Dowload and move wallpapers to Pictures/Wallpapers

> [!important]
> **Do not move or delete the dotfiles repository after installation.**
>
> This setup uses **symbolic links (symlinks)** that point to files inside the cloned repository. If you move or delete the repository, those symlinks will break.
>
> If you relocate the repository, simply run:
>
> ```bash
> ./install.sh
> ```
>
> The installer will automatically update the existing symlinks to point to the new location.

---
## Updating

Pull the latest changes, then run the updater from inside the repository:

```bash
git pull
./update.sh
```

Other options: `--dry-run` (preview changes), `--skip-packages`, `--skip-theme`.

Dotfiles are symlinked so, `git pull` updates your live configs directly.

You can check the reminders printed at the end of the run.

> [!tip]
> If any Quickshell (`.qml`) files changed in the pull, run:
>
> ```bash
> ./update.sh --restart-shell
> ```
>
> to restart Quickshell automatically.

> [!note]
> 
> Custom-gpu parts are specific to my hardware.
>
> For issues with the wallpaper picker, you can clear the cache from the Storage page in Settings.


