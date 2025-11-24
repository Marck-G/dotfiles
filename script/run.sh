#!/usr/bin/env bash
set -e

DEPS_FILE="${1:-deps.pkg}"

declare -A PACKAGE
declare -A ALT_FLAGS
declare -A ALT_REQUIRED

ALT_MANAGERS=("snap" "flatpak" "aur" "brew")

log() { echo -e "👉 $*"; }

detect_pkg_manager() {
    for pm in apt dnf pacman zypper apk; do
        command -v "$pm" &>/dev/null && { echo "$pm"; return; }
    done
    echo "unknown"
}

alt_manager_binary() {
    case "$1" in
        snap) echo snap ;;
        flatpak) echo flatpak ;;
        aur) echo yay ;;
        brew) echo brew ;;
    esac
}

install_alt_manager() {
    local alt="$1" pm="$2"

    log "Instalando gestor alternativo: $alt"
    case "$alt" in
        snap)
            case "$pm" in
                apt) sudo apt install -y snapd ;;
                dnf) sudo dnf install -y snapd ;;
                pacman) sudo pacman -Sy --noconfirm snapd ;;
                zypper) sudo zypper install -y snapd ;;
                apk) sudo apk add snapd ;;
            esac
            ;;
        flatpak)
            case "$pm" in
                apt) sudo apt install -y flatpak ;;
                dnf) sudo dnf install -y flatpak ;;
                pacman) sudo pacman -Sy --noconfirm flatpak ;;
                zypper) sudo zypper install -y flatpak ;;
                apk) sudo apk add flatpak ;;
            esac
            ;;
        aur)
            case "$pm" in
                pacman)
                    sudo pacman -Sy --noconfirm git base-devel
                    tmp=$(mktemp -d)
                    git clone https://aur.archlinux.org/yay.git "$tmp"
                    (cd "$tmp" && makepkg -si --noconfirm)
                    ;;
                *) echo "AUR solo disponible en Arch"; exit 1 ;;
            esac
            ;;
        brew)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
    esac
}

ensure_alt_manager_installed() {
    local alt="$1" pm="$2"
    local bin
    bin="$(alt_manager_binary "$alt")"
    command -v "$bin" &>/dev/null || install_alt_manager "$alt" "$pm"
}

###############################################
# PARSER ARREGLADO — USA LOCAL IFS
###############################################
parse_line() {
    local line="$1"
    [[ -z "$line" ]] && return

    local name="${line%%=*}"
    local rest="${line#*=}"
    name="$(echo "$name" | xargs)"
    rest="$(echo "$rest" | xargs)"

    local entries
    local IFS=','
    read -ra entries <<< "$rest"

    for entry in "${entries[@]}"; do
        entry="$(echo "$entry" | xargs)"

        local IFS=':'
        read -ra parts <<< "$entry"

        local manager="${parts[0]}"
        local pkg="${parts[1]}"
        local flags="${parts[2]:-}"

        PACKAGE["$name,$manager"]="$pkg"
        [[ -n "$flags" ]] && ALT_FLAGS["$name,$manager"]="$flags"

        for alt in "${ALT_MANAGERS[@]}"; do
            [[ "$manager" == "$alt" ]] && ALT_REQUIRED["$name"]=1
        done
    done
}

parse_file() {
	# Leer el archivo línea por línea, manejando comentarios y líneas vacías
    while IFS= read -r line || [[ -n "$line" ]]; do
		line="$(echo "$line" | xargs)"
		[[ -z "$line" || "${line:0:1}" == "#" ]] && continue
		log "Leyendo línea: $line"
        parse_line "$line"
    done < "$DEPS_FILE"
}

install_native() {
    case "$1" in
        apt) sudo apt update -y && sudo apt install -y "$2" ;;
        dnf) sudo dnf install -y "$2" ;;
        pacman) sudo pacman -Sy --noconfirm "$2" ;;
        zypper) sudo zypper install -y "$2" ;;
        apk) sudo apk add "$2" ;;
    esac
}

install_alternative() {
    local name="$1" manager="$2" pkg="$3" pm="$4"
    local flags="${ALT_FLAGS[$name,$manager]}"

    ensure_alt_manager_installed "$manager" "$pm"

    log "Instalando alternativo: $pkg ($manager) flags=[$flags]"

    case "$manager" in
        snap) sudo snap install "$pkg" ${flags:+$flags} ;;
        flatpak) flatpak install -y ${flags:+$flags} "$pkg" ;;
        aur) yay -S --noconfirm ${flags:+$flags} "$pkg" ;;
        brew) brew install ${flags:+$flags} "$pkg" ;;
    esac
}

install_package() {
    local name="$1" pm="$2"

    if [[ -n "${ALT_REQUIRED[$name]}" ]]; then
        for alt in "${ALT_MANAGERS[@]}"; do
            if [[ -n "${PACKAGE[$name,$alt]}" ]]; then
                install_alternative "$name" "$alt" "${PACKAGE[$name,$alt]}" "$pm"
                return
            fi
        done
    fi

    if [[ -n "${PACKAGE[$name,$pm]}" ]]; then
        install_native "$pm" "${PACKAGE[$name,$pm]}"
        return
    fi

    if [[ -n "${PACKAGE[$name,native]}" ]]; then
        install_native "$pm" "${PACKAGE[$name,native]}"
        return
    fi
}

###############################################
# EJECUCIÓN
###############################################
PM=$(detect_pkg_manager)
log "Gestor nativo detectado: $PM"

parse_file

declare -A ALL_NAMES
for key in "${!PACKAGE[@]}"; do
    IFS=',' read -r name _ <<< "$key"
    ALL_NAMES["$name"]=1
done

for name in "${!ALL_NAMES[@]}"; do
    echo ""
    log "▶ Instalando $name"
    install_package "$name" "$PM"
done

echo ""
log "✔ Finalizado"
