#!/bin/bash
### Creado por DockPi3 15-03-2026
# 1. Optimización del Kernel y Firmware
echo "Configurando Overclock y Video para Pi 5..."
sudo apt update && sudo apt upgrade -y
sudo bash -c 'cat <<EOF >> /boot/firmware/config.txt
# Optimización Pro
arm_freq=2600
gpu_freq=900
v3d_freq=900
force_turbo=1
dtparam=pciex1_gen=3
EOF'

# 2. Dependencias esenciales y Drivers Vulkan
echo "Instalando dependencias y drivers Mesa (Vulkan)..."
sudo apt install -y build-essential git cmake libasound2-dev libpulse-dev \
libwayland-dev libx11-dev libxkbcommon-dev libegl1-mesa-dev \
libgles2-mesa-dev libgbm-dev libdrm-dev mesa-vulkan-drivers \
python3-dev libusb-1.0-0-dev liblua5.3-dev libavcodec-dev libavformat-dev

# 3. Instalación de RetroArch (Compilado para Pi 5)
echo "Compilando RetroArch..."
cd ~
git clone --depth 1 https://github.com/libretro/RetroArch.git
cd RetroArch
./fetch-submodules.sh
./configure --enable-floathard --enable-neon --enable-7zip --enable-vulkan --enable-wayland
make -j$(nproc)
sudo make install
cd ..

# 4. Instalación de EmulationStation-DE
echo "Instalando EmulationStation-DE..."

# --- 1. PREPARACIÓN Y DEPENDENCIAS DE COMPILACIÓN ---
echo "Instalando herramientas de compilación para Pi 5..."
sudo apt install -y build-essential git cmake pkg-config libfreeimage-dev \
libfreetype6-dev libcurl4-openssl-dev libasound2-dev libicu-dev \
libsdl2-dev libvlc-dev libvlccore-dev libcommon-vlc-dev libpoppler-cpp-dev \
libavcodec-dev libavformat-dev libswresample-dev libpugixml-dev

# --- 2. CLONAR REPOSITORIO ---
cd ~
git clone https://gitlab.com/es-de/emulationstation-de.git
cd emulationstation-de

# --- 3. COMPILACIÓN OPTIMIZADA ---
# Usamos -march=native para que use todas las instrucciones de la Pi 5 (ARMv8.2-A)
# Usamos -O3 para máxima optimización de velocidad
echo "Compilando ES-DE con optimizaciones de CPU (esto tardará un poco)..."
mkdir build && cd build

cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-march=native -O3 -pipe" \
      -DCMAKE_C_FLAGS="-march=native -O3 -pipe" ..

make -j$(nproc)

# --- 4. INSTALACIÓN ---
echo "Instalando ES-DE en el sistema..."
sudo make install

# --- 5. CONFIGURACIÓN DE RENDIMIENTO GRÁFICO ---
# ES-DE en Pi 5 vuela con el renderizador de hardware habilitado
mkdir -p ~/.emulationstation/settings
cat <<EOF > ~/.emulationstation/settings/es_settings.xml
<?xml version="1.0"?>
<config>
    <string name="Renderer" value="OpenGL" />
    <bool name="VramLimit8192" value="true" />
    <bool name="PreloadUI" value="true" />
    <bool name="OptimizeImages" value="true" />
</config>
EOF

echo "ES-DE compilado e instalado con éxito."


# 5. Configuración de Auto-Arranque (Modo Kiosk)
echo "Configurando arranque directo a ES-DE..."
sudo apt install -y xserver-xorg xinit x11-xserver-utils
cat <<EOF > ~/.xinitrc
exec emulationstation
EOF

# Añadir a bash_profile para que arranque al loguearse en Lite
echo 'if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then startx; fi' >> ~/.bash_profile



# --- INSTALACIÓN DE CORES OPTIMIZADOS (64-BIT),primero busca en la web oficial,si no encuentra ninguno los compila uno a uno ---
# seguramente elimine este trozo d codigo q busca en la web oficial los cores y los descarga.. mejor compilar aunque tarde mas.
echo "Instalando y configurando los mejores cores para Raspberry Pi 5..."

# Crear directorios necesarios
mkdir -p ~/.config/retroarch/cores
mkdir -p ~/.config/retroarch/config

# Lista de cores de alto rendimiento (Libretro Buildbot)
CORES=(
  "mupen64plus_next_libretro.so.zip" # Nintendo 64 (Optimizado)
  "flycast_libretro.so.zip"          # Dreamcast/Naomi (Vulkan)
  "ppsspp_libretro.so.zip"          # PSP (Máximo rendimiento)
  "snes9x_libretro.so.zip"          # SNES (Precisión y velocidad)
  "genesis_plus_gx_libretro.so.zip" # Genesis/Mega Drive
  "fbneo_libretro.so.zip"           # Arcade/NeoGeo
  "duckstation_libretro.so.zip"     # PS1 (Con reescalado 4K)
  "mgba_libretro.so.zip"            # GameBoy Advance
)

BASE_URL="https://buildbot.libretro.com"

for core in "${CORES[@]}"; do
    echo "Descargando core: $core"
    wget -q "${BASE_URL}${core}" -P ~/.config/retroarch/cores
    unzip -o "~/.config/retroarch/cores/$core" -d ~/.config/retroarch/cores
    rm "~/.config/retroarch/cores/$core"
done

# --- CONFIGURACIÓN DE VIDEO VULKAN (CLAVE PARA PI 5) ---
# Forzamos a RetroArch a usar Vulkan y el driver de video correcto
cat <<EOF > ~/.config/retroarch/retroarch.cfg
video_driver = "vulkan"
menu_driver = "ozone"
input_joypad_driver = "udev"
video_vsync = "true"
video_threaded_buildup = "true"
libretro_directory = "~/.config/retroarch/cores"
EOF

# --- VINCULACIÓN CON EMULATIONSTATION-DE ---
# Creamos el archivo de configuración de sistemas para que ES-DE use nuestros cores
mkdir -p ~/.emulationstation/custom_systems
cat <<EOF > ~/.emulationstation/es_systems.xml
<systemList>
    <system>
        <name>psx</name>
        <fullname>PlayStation</fullname>
        <path>~/ROMs/psx</path>
        <extension>.cue .CUE .chd .CHD .img .IMG</extension>
        <command>retroarch -L ~/.config/retroarch/cores/duckstation_libretro.so %ROM%</command>
        <platform>psx</platform>
        <theme>psx</theme>
    </system>
</systemList>
EOF

echo "Cores instalados y configurados para Vulkan."


# 1. Configuración de Arquitectura Pi 5 (Cortex-A76)
export CFLAGS="-O3 -march=armv8.2-a+crc+simd -mtune=cortex-a76 -mcpu=cortex-a76 -ffast-math -ftree-vectorize"
export CXXFLAGS="$CFLAGS"
export MAKEFLAGS="-j$(nproc)"
CORE_DIR="$HOME/.config/retroarch/cores"
mkdir -p "$CORE_DIR"

# 2. Instalación de dependencias de compilación
sudo apt update && sudo apt install -y git build-essential cmake pkg-config \
libgles2-mesa-dev libgbm-dev libdrm-dev libasound2-dev libudev-dev \
libfreetype6-dev libxml2-dev libx11-dev libxkbcommon-dev libvulkan-dev

# 3. Función para clonar y compilar cada core
compile_core() {
    REPO_URL=$1
    DIR_NAME=$2
    echo "--- Compilando $DIR_NAME ---"
    cd ~
    git clone --depth 1 "$REPO_URL" "$DIR_NAME"
    cd "$DIR_NAME"
    
    # Intentar compilar (la mayoría usa Makefile, algunos CMake)
    if [ -f "Makefile.libretro" ]; then
        make -f Makefile.libretro
    elif [ -f "Makefile" ]; then
        make
    else
        mkdir build && cd build && cmake .. && make
    fi

    # Mover el binario optimizado y limpiar
    find . -name "*_libretro.so" -exec cp {} "$CORE_DIR/" \;
    cd ~
    rm -rf "$DIR_NAME"
}

# 4. Lista de Cores (Añade todos los que necesites aquí)
# Estos son los esenciales que cubren casi todo:
cores=(
    "https://github.com n64"
    "https://github.com flycast"
    "https://github.com ppsspp"
    "https://github.com duckstation"
    "https://github.com snes9x"
    "https://github.com genesis"
    "https://github.com fbneo"
    "https://github.com mgba"
    "https://github.com ps1_accuracy"
    "https://github.com picodrive"
    "https://github.com pcsx_rearmed"
    "https://github.com dolphin"
)

for core in "${cores[@]}"; do
    compile_core $core
done

echo "Todos los cores compilados y optimizados en $CORE_DIR"




echo "Instalación finalizada. Reiniciando.... " sleep 3

sudo reboot
