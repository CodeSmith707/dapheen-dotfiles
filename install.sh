
#!/usr/bin/env bash

set -uo pipefail

# DAPHEEN/dotfiles installer
# Arch-compatible Linux + Hyprland

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO_DIR/.config"
CONFIG_DIR="$HOME/.config"
BACKUP_ROOT="$HOME/.config-backups"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

# Generated at runtime by theme.py
GENERATED_FILES=(
    "kitty/matugen.conf"
    "hypr/hyprlock-colors.conf"
    "gtk-3.0/colors.css"
    "gtk-4.0/colors.css"
    "gtk-3.0/settings.ini"
    "gtk-4.0/settings.ini"
    "rofi/colors.rasi"
    "quickshell/Theme.qml"
)

# --------------------------------------------------
# Output helpers
# --------------------------------------------------

info() {
    printf '\n\033[1;34m[INFO]\033[0m %s\n' "$1"
}

success() {
    printf '\n\033[1;32m[DONE]\033[0m %s\n' "$1"
}

warning() {
    printf '\n\033[1;33m[WARN]\033[0m %s\n' "$1"
}

error() {
    printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$1" >&2
}

# --------------------------------------------------
# System checks
# --------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

if [[ ! -f /etc/os-release ]]; then
    error "Cannot determine the operating system."
    exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release

if [[ "${ID:-}" != "arch" && "${ID_LIKE:-}" != *arch* ]]; then
    error "This installer is intended for Arch-compatible Linux distributions."
    error "Detected: ${PRETTY_NAME:-unknown}"
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    error "sudo is required."
    exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
    error "pacman was not found."
    exit 1
fi

if [[ ! -d "$SRC" ]]; then
    error "No .config directory found at $SRC"
    exit 1
fi

PACKAGE_FILE="$REPO_DIR/packages.txt"

if [[ ! -f "$PACKAGE_FILE" ]]; then
    error "packages.txt not found."
    exit 1
fi

# --------------------------------------------------
# AUR helper detection/bootstrap
# --------------------------------------------------

AUR_HELPER=""

if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
fi

info "Detected distribution: ${PRETTY_NAME:-unknown}"

if [[ -n "$AUR_HELPER" ]]; then
    info "AUR helper available: $AUR_HELPER"
else
    info "No AUR helper found. Bootstrapping yay..."

    if sudo pacman -S --needed --noconfirm git base-devel; then
        YAY_BUILD_DIR="$(mktemp -d)"

        if git clone https://aur.archlinux.org/yay.git "$YAY_BUILD_DIR/yay" \
            && (cd "$YAY_BUILD_DIR/yay" && makepkg -si --noconfirm); then
            AUR_HELPER="yay"
            success "yay installed."
        else
            warning "Failed to build/install yay automatically."
            warning "Install paru or yay manually to enable AUR packages."
        fi

        rm -rf "$YAY_BUILD_DIR"
    else
        warning "Failed to install git/base-devel; cannot bootstrap an AUR helper."
    fi
fi

# --------------------------------------------------
# Install packages from packages.txt
# --------------------------------------------------

mapfile -t PACKAGES < <(
    grep -vE '^[[:space:]]*(#|$)' "$PACKAGE_FILE"
)

OFFICIAL_PACKAGES=()
AUR_PACKAGES=()
UNKNOWN_PACKAGES=()

if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
    warning "packages.txt does not contain any packages."
else
    info "Resolving packages against official repos..."

    for pkg in "${PACKAGES[@]}"; do
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            OFFICIAL_PACKAGES+=("$pkg")
        elif [[ -n "$AUR_HELPER" ]] \
            && "$AUR_HELPER" -Si "$pkg" >/dev/null 2>&1; then
            AUR_PACKAGES+=("$pkg")
        else
            UNKNOWN_PACKAGES+=("$pkg")
        fi
    done

    if [[ "${#OFFICIAL_PACKAGES[@]}" -gt 0 ]]; then
        info "Installing official-repo packages..."

        if sudo pacman -Syu --needed --noconfirm \
            "${OFFICIAL_PACKAGES[@]}"; then
            success "Official-repo packages installed."
        else
            warning "Some official packages failed to install."
        fi
    fi

    if [[ "${#AUR_PACKAGES[@]}" -gt 0 && -n "$AUR_HELPER" ]]; then
        info "Installing AUR packages with $AUR_HELPER..."

        if "$AUR_HELPER" -S --needed --noconfirm "${AUR_PACKAGES[@]}"; then
            success "AUR packages installed."
        else
            warning "Some AUR packages failed to install."
        fi
    fi

    if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
        warning "Unresolved packages: ${UNKNOWN_PACKAGES[*]}"
        warning "Check package names in packages.txt."
    fi
fi

# --------------------------------------------------
# Satty screenshot workflow and plugin build dependencies
# --------------------------------------------------

# cliphist supports clipboard history integration; it is not a Satty
# runtime dependency.
SCREENSHOT_PACKAGES=(satty grim slurp wl-clipboard cliphist)
PLUGIN_BUILD_PACKAGES=(cpio cmake git meson gcc base-devel)

info "Installing screenshot workflow and plugin build dependencies..."

if sudo pacman -S --needed --noconfirm \
    "${SCREENSHOT_PACKAGES[@]}" "${PLUGIN_BUILD_PACKAGES[@]}"; then
    success "Screenshot workflow and plugin build dependencies installed."
else
    warning "Some screenshot/plugin build packages failed to install."
fi

# --------------------------------------------------
# Scroll Overview plugin setup
# --------------------------------------------------

setup_scrolloverview() {
    local repo="https://github.com/yayuuu/hyprland-scroll-overview.git"
    local plugin_list=""

    if ! command -v hyprpm >/dev/null 2>&1; then
        warning "hyprpm unavailable; skipping Scroll Overview."
        return 0
    fi

    if ! command -v Hyprland >/dev/null 2>&1 \
        && ! command -v hyprland >/dev/null 2>&1; then
        warning "Hyprland executable not found; skipping Scroll Overview."
        return 0
    fi

    if ! hyprpm list 2>/dev/null | grep -qi 'scrolloverview'; then
        if pacman -Q hyprland-git >/dev/null 2>&1; then
            hyprpm add "$repo" origin/new-release \
                || warning "Could not add Scroll Overview repository."
        else
            hyprpm add "$repo" \
                || warning "Could not add Scroll Overview repository."
        fi
    fi

    if ! hyprpm update; then
        warning "hyprpm update failed; check plugin compatibility."
        return 0
    fi

    if ! hyprpm enable scrolloverview; then
        warning "Could not enable scrolloverview."
        return 0
    fi

    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if hyprpm reload; then
            success "Scroll Overview reload requested."

            if command -v hyprctl >/dev/null 2>&1; then
                plugin_list="$(hyprctl plugin list 2>/dev/null || true)"

                if ! grep -qi 'scrolloverview' <<< "$plugin_list"; then
                    warning "Plugin not reported as loaded; check for version mismatch."
                fi
            fi
        else
            warning "Run 'hyprpm reload' inside Hyprland to load the plugin."
        fi
    else
        warning "Scroll Overview enabled. Run 'hyprpm reload' after logging into Hyprland."
    fi
}

setup_scrolloverview

# --------------------------------------------------
# Default shell
# --------------------------------------------------

if [[ -x /bin/zsh ]]; then
    if [[ "$SHELL" != "/bin/zsh" ]]; then
        info "Setting Zsh as the default shell..."

        if chsh -s /bin/zsh; then
            success "Default shell changed to Zsh."
            warning "Log out and back in for the change to take effect."
        else
            warning "Failed to change the default shell."
        fi
    else
        info "Zsh is already the default shell."
    fi
else
    warning "Zsh is not installed; skipping default shell configuration."
fi

# --------------------------------------------------
# Link dotfiles and recreate repository directories
# --------------------------------------------------

info "Preparing configuration directories..."

mkdir -p "$CONFIG_DIR"

is_generated() {
    local rel="$1"
    local g

    for g in "${GENERATED_FILES[@]}"; do
        [[ "$rel" == "$g" ]] && return 0
    done

    return 1
}

LINK_FAILED=0
LINKED_COUNT=0
BACKED_UP_COUNT=0
DIRECTORY_COUNT=0

# Create all repository directories first. This includes empty directories.
while IFS= read -r -d '' src_dir; do
    rel_dir="${src_dir#"$SRC"/}"
    [[ "$src_dir" == "$SRC" ]] && continue

    dest_dir="$CONFIG_DIR/$rel_dir"

    if [[ -L "$dest_dir" ]]; then
        if [[ ! -d "$dest_dir" ]]; then
            warning "Broken directory symlink left for review: $dest_dir"
            LINK_FAILED=1
            continue
        fi
    elif [[ -e "$dest_dir" && ! -d "$dest_dir" ]]; then
        mkdir -p "$BACKUP_DIR/config/$(dirname "$rel_dir")"
        mv "$dest_dir" "$BACKUP_DIR/config/$rel_dir"
        BACKED_UP_COUNT=$((BACKED_UP_COUNT + 1))
        mkdir -p "$dest_dir"
    else
        mkdir -p "$dest_dir"
    fi

    DIRECTORY_COUNT=$((DIRECTORY_COUNT + 1))
done < <(
    find "$SRC" -mindepth 1 -type d -not -path '*/.git/*' -print0
)

# Link repository files and symlinks.
while IFS= read -r -d '' src; do
    rel="${src#"$SRC"/}"

    is_generated "$rel" && continue

    dest="$CONFIG_DIR/$rel"
    mkdir -p "$(dirname "$dest")"

    if [[ -L "$dest" ]]; then
        ln -sfn "$src" "$dest"
    elif [[ -e "$dest" ]]; then
        mkdir -p "$BACKUP_DIR/config/$(dirname "$rel")"
        mv "$dest" "$BACKUP_DIR/config/$rel"
        BACKED_UP_COUNT=$((BACKED_UP_COUNT + 1))
        ln -s "$src" "$dest"
    else
        ln -s "$src" "$dest"
    fi

    if [[ -L "$dest" ]] \
        && [[ "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
        LINKED_COUNT=$((LINKED_COUNT + 1))
    else
        LINK_FAILED=1
        error "Failed to link $rel"
    fi
done < <(
    find "$SRC" \( -type f -o -type l \) -not -path '*/.git/*' -print0
)

# Link ~/.zshrc if the repository provides it.
if [[ -f "$SRC/.zshrc" ]]; then
    if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
        mkdir -p "$BACKUP_DIR/home"
        mv "$HOME/.zshrc" "$BACKUP_DIR/home/.zshrc"
        BACKED_UP_COUNT=$((BACKED_UP_COUNT + 1))
    fi

    ln -sfn "$SRC/.zshrc" "$HOME/.zshrc"
    success "Linked ~/.zshrc."
fi

# Copy generated fallback files once, when available in the repository.
for g in "${GENERATED_FILES[@]}"; do
    [[ -f "$SRC/$g" ]] || continue

    dest="$CONFIG_DIR/$g"

    if [[ ! -e "$dest" || -L "$dest" ]]; then
        [[ -L "$dest" ]] && rm -f "$dest"
        mkdir -p "$(dirname "$dest")"
        cp "$SRC/$g" "$dest"
    fi
done

if [[ "$LINK_FAILED" -eq 1 ]]; then
    error "One or more files failed to link."
else
    success "Dotfiles linked ($LINKED_COUNT file(s)); repository directories prepared ($DIRECTORY_COUNT)."
fi

if [[ "$BACKED_UP_COUNT" -gt 0 ]]; then
    info "Backed up $BACKED_UP_COUNT existing item(s) to:"
    printf '  %s\n' "$BACKUP_DIR"
fi

# --------------------------------------------------
# Thunar default file manager
# --------------------------------------------------

info "Configuring Thunar as the default file manager..."

if command -v thunar >/dev/null 2>&1; then
    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime default thunar.desktop inode/directory \
            || warning "Could not set the directory handler."

        xdg-mime default thunar.desktop application/x-directory \
            || warning "Could not set application/x-directory handler."
    else
        warning "xdg-mime unavailable; skipping MIME defaults."
    fi

    if [[ -f /usr/share/dbus-1/services/org.xfce.Thunar.FileManager1.service ]]; then
        success "Thunar D-Bus file-manager service is installed."
    else
        warning "Thunar FileManager1 D-Bus service was not found."
    fi
else
    warning "Thunar is not installed; skipping file-manager configuration."
fi

# --------------------------------------------------
# Papirus folder color
# --------------------------------------------------

if [[ -n "$AUR_HELPER" ]]; then
    info "Installing Papirus folders..."

    if "$AUR_HELPER" -S --needed --noconfirm papirus-folders; then
        if papirus-folders -C white; then
            success "Papirus folders set to white."
        else
            warning "Could not set Papirus folder color."
        fi
    else
        warning "Failed to install papirus-folders."
    fi
else
    warning "No AUR helper available; skipping papirus-folders."
fi

# --------------------------------------------------
# User directories
# --------------------------------------------------

info "Creating user directories..."

mkdir -p "$HOME/Pictures"
mkdir -p "$HOME/Pictures/Wallpapers"

success "Pictures and Wallpapers directories created."

# --------------------------------------------------
# Enable PipeWire user services
# --------------------------------------------------

if command -v systemctl >/dev/null 2>&1; then
    info "Enabling PipeWire..."

    systemctl --user enable --now pipewire.service
    systemctl --user enable --now pipewire-pulse.service
    systemctl --user enable --now wireplumber.service

    success "PipeWire configured."
else
    warning "systemctl unavailable; skipping PipeWire setup."
fi

# --------------------------------------------------
# Enable power profiles daemon
# --------------------------------------------------

if command -v systemctl >/dev/null 2>&1; then
    if pacman -Qi power-profiles-daemon >/dev/null 2>&1; then
        info "Enabling power-profiles-daemon..."

        if sudo systemctl enable --now power-profiles-daemon.service; then
            success "power-profiles-daemon enabled."
        else
            warning "Failed to enable power-profiles-daemon."
        fi
    else
        warning "power-profiles-daemon is not installed."
    fi
fi

# --------------------------------------------------
# Permissions
# --------------------------------------------------

info "Setting executable permissions on shell scripts..."

find "$SRC" -type f \( -name "*.sh" -o -name "*.py" \) -exec chmod +x {} \;

success "Script permissions configured."

# --------------------------------------------------
# Initial theme generation
# --------------------------------------------------

if command -v python3 >/dev/null 2>&1; then
    info "Generating initial theme..."

    python3 "$CONFIG_DIR/dapheen/bin/theme.py" apply \
        || warning "Initial theme generation failed."
else
    warning "python3 not found; skipping initial theme generation."
fi

# --------------------------------------------------
# Finish
# --------------------------------------------------

printf '\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\033[1;32m       DAPHEEN Hyprland Setup Ready       \033[0m\n'
printf '\033[1;32m========================================\033[0m\n'
printf '\n'

printf 'Distribution:  %s\n' "${PRETTY_NAME:-unknown}"
printf 'AUR helper:    %s\n' "${AUR_HELPER:-none}"
printf 'Configuration: %s (linked to %s)\n' "$CONFIG_DIR" "$SRC"

if [[ "$BACKED_UP_COUNT" -gt 0 ]]; then
    printf 'Backup:        %s\n' "$BACKUP_DIR"
fi

if [[ "${#UNKNOWN_PACKAGES[@]}" -gt 0 ]]; then
    printf '\n'
    warning "Unresolved packages: ${UNKNOWN_PACKAGES[*]}"
fi

printf '\n'
warning "Log out and back into Hyprland for changes to take effect."

printf '\n'
info "You can start Hyprland with:"
printf '  Hyprland\n'

printf '\n'
success "Installation complete!"
