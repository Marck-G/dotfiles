#!/usr/bin/env python3

import re
import json
import subprocess
import time
import sys
import threading
import shutil

# This file is allocated relative to this script so we need to get the current file's path
DEPS_FILE = __file__.replace('run.sh', 'deps.pkg')
dependencies = {}

# Line pattern
line_pattern = re.compile(r"^\s*(?![#])(?P<key>[\w-]+)\s*=\s*(?P<raw_value>.+)$", re.MULTILINE)

# Value pattern
item_pattern = re.compile(r"\s*(?P<manager>[^:,]+):(?P<package>[^:,]+)(?::(?P<flags>[^,]+))?")

# Alternative manager names with the package name
alt_managers = {
	'snap': 'snapd',
	'flatpak': 'flatpak',
}

PACKAGE_MANAGERS = [
    ("apt", ["apt-get", "apt"]),
    ("dnf", ["dnf"]),
    ("yum", ["yum"]),
    ("pacman", ["pacman"]),
    ("zypper", ["zypper"]),
    ("apk", ["apk"]),
]

INSTALL_COMMANDS = {
    "apt": {
        "snapd": ["sudo", "apt-get", "install", "-y", "snapd"],
        "flatpak": ["sudo", "apt-get", "install", "-y", "flatpak"],
    },
    "dnf": {
        "snapd": ["sudo", "dnf", "install", "-y", "snapd"],
        "flatpak": ["sudo", "dnf", "install", "-y", "flatpak"],
    },
    "yum": {
        "snapd": ["sudo", "yum", "install", "-y", "snapd"],
        "flatpak": ["sudo", "yum", "install", "-y", "flatpak"],
    },
    "pacman": {
        "snapd": ["sudo", "pacman", "-S", "--noconfirm", "snapd"],
        "flatpak": ["sudo", "pacman", "-S", "--noconfirm", "flatpak"],
    },
    "zypper": {
        "snapd": ["sudo", "zypper", "install", "-y", "snapd"],
        "flatpak": ["sudo", "zypper", "install", "-y", "flatpak"],
    },
    "apk": {
        "snapd": ["sudo", "apk", "add", "snapd"],
        "flatpak": ["sudo", "apk", "add", "flatpak"],
    }
}

def has_snap():
    return shutil.which("snap") is not None

def has_flatpak():
    return shutil.which("flatpak") is not None

def log(msg: str, emoji: str = "📦"):
    """
    Imprime un mensaje con un emoji al inicio de cada línea.
    """
    # Asegura que si el mensaje tiene varias líneas, todas lleven emoji
    for line in msg.splitlines():
        print(f" {emoji} {line}")


def detect_package_manager():
    for name, executables in PACKAGE_MANAGERS:
        for exe in executables:
            if shutil.which(exe):
                return name
    return None

CURRENT_MANAGER = detect_package_manager()
log (f"Gestor de paquetes detectado: {CURRENT_MANAGER}", "🔍")
def install_package(pkg):
    pm = detect_package_manager()
    cmd = []
    if pm == "apt":
        cmd = ["sudo", "apt-get", "install", "-y", pkg]
    elif pm == "dnf":
        cmd = ["sudo", "dnf", "install", "-y", pkg]
    elif pm == "yum":
        cmd = ["sudo", "yum", "install", "-y", pkg]
    elif pm == "pacman":
        cmd = ["sudo", "pacman", "-S", "--noconfirm", pkg]
    elif pm == "zypper":
        cmd = ["sudo", "zypper", "install", "-y", pkg]
    elif pm == "apk":
        cmd = ["sudo", "apk", "add", pkg]
    else:
        raise RuntimeError("No se encontró un gestor de paquetes compatible.")
    log(f"Instalando paquete '{pkg}' usando {pm}…", "📦")
    subprocess.run(cmd, check=True)

def ensure_manager_installed(manager_name):
    """
    manager_name = 'snapd' o 'flatpak'
    """
    system_pm = detect_system_package_manager()
    if not system_pm:
        raise RuntimeError("No se pudo detectar el gestor base del sistema.")

    cmd = INSTALL_COMMANDS.get(system_pm, {}).get(manager_name)
    if not cmd:
        raise RuntimeError(f"No sabemos cómo instalar {manager_name} en {system_pm}")

    print(f"🛠️ Instalando {manager_name} usando {system_pm}…")
    subprocess.run(cmd, check=True)

def install_snap_package(pkg, flags=""):
    if not has_snap():
        ensure_manager_installed("snapd")

    cmd = ["sudo", "snap", "install", pkg, flags]
    print(f"📦 Instalando paquete snap: {pkg}")
    subprocess.run(cmd, check=True)


def install_flatpak_package(pkg, flags=""):
    if not has_flatpak():
        ensure_manager_installed("flatpak")

    cmd = ["flatpak", "install", "-y", pkg, flags]
    print(f"📦 Instalando paquete flatpak: {pkg}")
    subprocess.run(cmd, check=True)

def run_with_spinner(cmd, emoji="⏳"):
    spinner_chars = ["|", "/", "-", "\\"]
    start = time.time()
    spinner_running = True

    # Función del spinner corriendo en segundo plano
    def spinner():
        i = 0
        while spinner_running:
            elapsed = int(time.time() - start)
            sys.stdout.write(f"\r{emoji} {spinner_chars[i % 4]}  Ejecutando... {elapsed}s")
            sys.stdout.flush()
            i += 1
            time.sleep(0.1)

    # Lanzamos spinner en thread
    spinner_thread = threading.Thread(target=spinner)
    spinner_thread.start()

    # Lanzamos el proceso
    process = subprocess.Popen(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    # Leemos salida en tiempo real
    for line in process.stdout:
        # Aquí puedes usar tu log con emojis:
        log(f"\n {line.strip()}", "📄")

    # Esperamos a que acabe
    process.wait()

    # Terminamos spinner
    spinner_running = False
    spinner_thread.join()

    # Línea final para limpiar spinner
    elapsed = int(time.time() - start)
    log(f"\r Completado en {elapsed}s         ", "✅")

    return process.returncode

with open(DEPS_FILE, 'r') as f:
	file_content = f.read()
	for match in line_pattern.finditer(file_content):
		key = match.group('key')
		items = {}
		raw_value = match.group('raw_value')
		for item_match in item_pattern.finditer(raw_value):
			manager = item_match.group('manager')
			package = item_match.group('package')
			flags = item_match.group('flags')
			items[manager] = {
				'package': package,
			}
			if flags:
				items[manager]['flags'] = flags
		log(f"Dependency '{key}':")
		dependencies[key] = items



for pkg, managers in dependencies.items():
	log(f"Procesando dependencia '{pkg}'…", "🔄")
	log(f"Opciones de gestores: {json.dumps(managers)}", "ℹ️")
	if CURRENT_MANAGER in managers:
		pkg_info = managers[CURRENT_MANAGER]
		package_name = pkg_info['package']
		flags = pkg_info.get('flags', '')

		log(f"Instalando '{pkg}' usando {CURRENT_MANAGER}…", "🚀")

		try:
			log(f"'{package_name}' instalado correctamente.", "✅")
			install_package(package_name)
		except Exception as e:
			log(f"Error al instalar '{pkg}': {e}", "❌")
	elif 'snap' in managers:
		package_name = managers['snap']['package']
		install_snap_package(package_name, flags)
	elif 'flatpak' in managers:
		package_name = managers['flatpak']['package']
		install_flatpak_package(package_name, flags)
	elif 'native' in managers:
		package_name = managers['native']['package']
		install_package(package_name)
	else:
		log(f"No hay información de instalación para '{pkg}' con el gestor '{CURRENT_MANAGER}'.", "⚠️")