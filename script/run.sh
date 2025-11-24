#!/usr/bin/env bash
set -e

DEPS_FILE="${1:-deps.pkg}"

declare -A PACKAGE
declare -A ALT_FLAGS
declare -A ALTERNATIVE_MANAGER

ALT_MANAGERS=("snap" "flatpak" "aur" "brew")

is_alternative() {
    local m="$1"
    for alt in "${ALT_MANAGERS[@]}"; do
        [[ "$m" == "$alt" ]] && return 0
    done
    return 1
}

detect_pkg_manager() {
    for pm in apt dnf pacman zypper apk; do
        command -v $pm &>/dev/null && { echo "$pm"; return; }
    done
    echo "unknown"
}

alt_manager_binary() {
    case "$1" in
        snap) echo "snap" ;;
        flatpak) echo "flatpak" ;;
        aur) echo "yay" ;;
        brew) echo "brew" ;;
    esac
}

install_alt_manager() {
    local alt="$1"
    local main_pm="$2"

    case "$alt" in
        snap)
            case "$main_pm" in
                apt) sudo apt install -y snapd ;;
                dnf) sudo dnf install -y snapd ;;
                pacman) sudo pacman -Sy --noconfirm snapd ;;
                zypper) sudo zypper install -y snapd ;;
                apk) sudo apk add snapd ;;
            esac
            ;;
        flatpak)
            case "$main_pm" in
                apt) sudo apt install -y flatpak ;;
                dnf) sudo dnf install -y flatpak ;;
                pacman) sudo pacman -Sy --noconfirm flatpak ;;
                zypper) sudo zypper install -y flatpak ;;
                apk) sudo apk add flatpak ;;
            esac
            ;;
        aur)
            case "$main_pm" in
                pacman)
                    sudo pacman -Sy --noconfirm git base-devel
                    tmpdir=$(mktemp -d)
                    git clone https://aur.archlinux.org/yay.git "$tmpdir"
                    (cd "$tmpdir" && makepkg -si --noconfirm)
                    ;;
                *)
                    echo "AUR solo disponible en Arch"; exit 1 ;;
            esac
            ;;
        brew)
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            ;;
    esac
}

ensure_alt_manager_installed() {
    local alt="$1"
    local main_pm="$2"
    local bin
    bin="$(alt_manager_binary "$alt")"
    command -v "$bin" &>/dev/null || install_alt_manager "$alt" "$main_pm"
}

parse_line() {
    local line="$1"
    local name="${line%%=*}"
    local rest="${line#*=}"
    name="$(echo "$name" | xargs)"
    rest="$(echo "$rest" | xargs)"

    IFS=',' read -ra entries <<< "$rest"
    for entry in "${entries[@]}"; do
        entry="$(echo "$entry" | xargs)"
        IFS=':' read -ra parts <<< "$entry"

        local manager="${parts[0]}"
        local pkg="${parts[1]}"
        local flags="${parts[2]:-}"

        PACKAGE["$name,$manager"]="$pkg"
        [[ -n "$flags" ]] && ALT_FLAGS["$name,$manager"]="$flags"
        is_alternative "$manager" && ALTERNATIVE_MANAGER["$name"]=1
    done
}

parse_file() {
    while IFS= read -r line; do
        line="${line%%#*}"
        [[ -z "$line" ]] && continue
        parse_line "$line"
    done < "$DEPS_FILE"
}

install_native() {
    local pm="$1"
    local pkg="$2"

    case "$pm" in
        apt) sudo apt update -y && sudo apt install -y "$pkg" ;;
        dnf) sudo dnf install -y "$pkg" ;;
        pacman) sudo pacman -Sy --noconfirm "$pkg" ;;
        zypper) sudo zypper install -y "$pkg" ;;
        apk) sudo apk add "$pkg" ;;
    esac
}

install_alternative() {
    local manager="$1"
    local pkg="$2"
    local main_pm="$3"
    local flags="${ALT_FLAGS[$name,$manager]}"

    ensure_alt_manager_installed "$manager" "$main_pm"

    case "$manager" in
        snap) sudo snap install "$pkg" ${flags:+$flags} ;;
        flatpak) flatpak install -y ${flags:+$flags} "$pkg" ;;
        aur) yay -S --noconfirm ${flags:+$flags} "$pkg" ;;
        brew) brew install ${flags:+$flags} "$pkg" ;;
    esac
}

install_package() {
    local name="$1"
    local main_pm="$2"

    if [[ -n "${ALTERNATIVE_MANAGER[$name]}" ]]; then
        for alt in "${ALT_MANAGERS[@]}"; do
            if [[ -n "${PACKAGE[$name,$alt]}" ]]; then
                install_alternative "$alt" "${PACKAGE[$name,$alt]}" "$main_pm"
                return
            fi
        done
    fi

    if [[ -n "${PACKAGE[$name,$main_pm]}" ]]; then
        install_native "$main_pm" "${PACKAGE[$name,$main_pm]}"
        return
    fi

    if [[ -n "${PACKAGE[$name,native]}" ]]; then
        install_native "$main_pm" "${PACKAGE[$name,native]}"
        return
    fi

    echo "No se puede instalar $name"
}

MAIN_PM=$(detect_pkg_manager)
parse_file

declare -A NAMES
for key in "${!PACKAGE[@]}"; do
    IFS=',' read -r name manager <<< "$key"
    NAMES["$name"]=1
done

for name in "${!NAMES[@]}"; do
    install_package "$name" "$MAIN_PM"
done

