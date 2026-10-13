#!/usr/bin/env bash
# mido installer for Fedora.
# Installs SDDM + Hyprland, enables the required COPRs, installs all
# dependencies, places the config in ~/.config/mido and wires up the
# `mido` commands. Safe to re-run.
#
#   curl -fsSL https://raw.githubusercontent.com/corzyy/mido/main/install.sh | bash
set -euo pipefail

REPO_URL="https://github.com/corzyy/mido.git"
QUICKSHELL_COPR="errornointernet/quickshell"
MATUGEN_COPR="heus-sueh/packages"
DEST="$HOME/.config/mido"
BIN_DIR="$HOME/.local/bin"

info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m ->\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as your own user, not root (the config lives in your HOME)."
command -v sudo >/dev/null || die "sudo is required."
command -v dnf >/dev/null || die "dnf not found - this installer is Fedora only."
. /etc/os-release
[[ "${ID:-}" == "fedora" ]] || die "This installer is for Fedora (found ${PRETTY_NAME:-unknown})."

SELF="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SELF")" >/dev/null 2>&1 && pwd -P)" || SCRIPT_DIR="$PWD"
if [[ -f "$SCRIPT_DIR/shell.qml" ]]; then SRC="$SCRIPT_DIR"; else SRC=""; fi

backup() {
  local dst
  dst="$1.bak.$(date +%Y%m%d%H%M%S)"
  mv "$1" "$dst"
  warn "Existing $1 moved to $dst"
}

copr_enable() {
  if ! sudo dnf -y copr enable "$1" 2>/dev/null; then
    sudo dnf -y install dnf-plugins-core
    sudo dnf -y copr enable "$1"
  fi
}

info "Enabling the Quickshell COPR ($QUICKSHELL_COPR)"
copr_enable "$QUICKSHELL_COPR"

info "Installing SDDM, Hyprland and dependencies"
sudo dnf -y install \
  sddm hyprland xdg-desktop-portal-hyprland \
  quickshell kitty jq curl brightnessctl \
  bluez NetworkManager libnotify \
  pipewire wireplumber fontconfig util-linux git

info "Installing matugen"
if ! sudo dnf -y install matugen; then
  warn "matugen is not in the official repos, using the $MATUGEN_COPR COPR"
  copr_enable "$MATUGEN_COPR"
  sudo dnf -y install matugen
fi

info "Installing optional extras (best effort)"
for pkg in hyprsunset gpu-screen-recorder; do
  sudo dnf -y install "$pkg" \
    || warn "Optional package '$pkg' not installed; mido just hides its indicator."
done

info "Enabling SDDM and system services (takes effect on the next boot)"
sudo systemctl set-default graphical.target
sudo systemctl enable sddm
sudo systemctl enable --now bluetooth NetworkManager 2>/dev/null \
  || warn "Could not enable bluetooth/NetworkManager services here."

info "Placing the mido files at $DEST"
mkdir -p "$HOME/.config"
if [[ -n "$SRC" && "$SRC" == "$DEST" ]]; then
  [[ -d "$DEST/.git" ]] && git -C "$DEST" pull --ff-only || true
elif [[ -z "$SRC" ]]; then
  if [[ -d "$DEST/.git" ]]; then
    git -C "$DEST" pull --ff-only || warn "Could not update $DEST via git; keeping the current files."
  else
    [[ -e "$DEST" ]] && backup "$DEST"
    git clone "$REPO_URL" "$DEST"
  fi
else
  [[ -e "$DEST" ]] && backup "$DEST"
  mkdir -p "$DEST"
  cp -a "$SRC"/. "$DEST"/
fi

info "Installing the mido commands into $BIN_DIR"
mkdir -p "$BIN_DIR"
for f in "$DEST"/bin/*; do
  ln -sfn "$f" "$BIN_DIR/$(basename "$f")"
done

info "Installing the Omarchy icon font"
mkdir -p "$HOME/.local/share/fonts"
cp -f "$DEST/assets/omarchy.ttf" "$HOME/.local/share/fonts/"
fc-cache -f >/dev/null 2>&1 || warn "fc-cache failed; a re-login will pick the font up."

info "Registering the mido matugen template"
mkdir -p "$HOME/.config/matugen"
MATUGEN_CFG="$HOME/.config/matugen/config.toml"
if ! grep -q '^\[templates\.mido\]' "$MATUGEN_CFG" 2>/dev/null; then
  [[ -s "$MATUGEN_CFG" && -n "$(tail -c 1 "$MATUGEN_CFG")" ]] && echo >> "$MATUGEN_CFG"
  cat >> "$MATUGEN_CFG" <<'EOF'
[templates.mido]
input_path  = '~/.config/mido/matugen/colors.json'
output_path = '~/.config/mido/generated/colors.json'
EOF
fi

info "Wiring mido into Hyprland"
HYPR_CFG="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$HOME/.config/hypr"
if [[ ! -f "$HYPR_CFG" ]]; then
  cat > "$HYPR_CFG" <<'EOF'
monitor = , preferred, auto, 1

layerrule = blur, mido-bar

exec-once = $HOME/.local/bin/mido start
EOF
elif ! grep -q 'mido start' "$HYPR_CFG"; then
  printf '\nexec-once = $HOME/.local/bin/mido start\n' >> "$HYPR_CFG"
fi

printf '\n'
info "Done. Log out and pick the Hyprland session in SDDM; mido starts with it."
warn "If 'mido' is not found in this shell, log out/in (or: export PATH=\"\$HOME/.local/bin:\$PATH\")."
warn "Inside a running Hyprland session you can also start it right away: mido start"
