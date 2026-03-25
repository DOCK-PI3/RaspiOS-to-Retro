#!/bin/bash
### Creado por DockPi3 15-03-2026
####################################
#set -o xtrace # Realiza una traza de lo que se ha ejecutado. Es para depurar ,ver donde y porque se está produciendo un error.
#set -o errexit # Se sale del script inmediatamente cuando falla un comando.
#set -e   # Cuando hay un error el script se detiene para que veas el fallo !!!

# 0. check root, not permited !
if [ "$EUID" -eq 0 ]
  then echo "Don't run script as root."
  exit
fi

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
sudo apt install -y build-essential git curl cmake libasound2-dev libpulse-dev libwayland-dev libx11-dev libxkbcommon-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libdrm-dev mesa-vulkan-drivers ffmpeg python3-dev libusb-1.0-0-dev liblua5.3-dev libavcodec-dev libavformat-dev

# 3. Instalación de RetroArch (Compilado para Pi 5)
echo "Compilando RetroArch..."
cd ~

# Script para instalar RetroArch en RPi 5 (OS Lite 64-bit) modo KMS


echo "Actualizando el sistema..."
echo "Instalando dependencias necesarias..."
sudo apt install -y libx11-xcb-dev libudev-dev libegl-dev libgles-dev libasound2-dev libpulse-dev libdrm-dev libgbm-dev libfreetype6-dev libxkbcommon-dev libxml2-dev zlib1g-dev libavcodec-dev libavformat-dev libswscale-dev libavdevice-dev libvulkan-dev mesa-vulkan-drivers yasm libpng-dev zlib1g-dev libxkbcommon-dev libsdl2-dev libasound2-dev libusb-1.0-0-dev
sudo apt install -y libc6-dev libc6-dev-arm64-cross libsigc++-3.0-dev libegl1-mesa libgles2-mesa

# INSTALAR DEPENDENCIAS DESPUES DE ACTUALIZAR LISTA DE PAQUETES --->
sudo apt install -y libasound2-dev libudev-dev libxkbcommon-dev zlib1g-dev libfreetype6-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libavcodec-dev libsdl2-dev libsdl-image1.2-dev libxml2-dev yasm libavformat-dev libavdevice-dev libswresample-dev libswscale-dev libv4l-dev libgl*-mesa-dev
sudo apt install -y xcb-proto libxcb-xkb-dev x11-xkb-utils libx11-xcb-dev libxkbcommon-x11-dev
sudo apt install -y libusb-1.0-0-dev clang
sudo apt -y install build-essential git wget libdrm-dev python3-full python3-pip python3-setuptools python3-wheel ninja-build libopenal-dev premake4 autoconf libevdev-dev ffmpeg libsnappy-dev libboost-tools-dev magics++ libboost-thread-dev libboost-all-dev pkg-config zlib1g-dev libpng-dev libsdl2-dev clang cmake cmake-data libarchive13 libcurl4 libfreetype6-dev libuv1 mercurial mercurial-common

ln -s /usr/include/libdrm/ /usr/include/drm

# Descargar version del repositorio oficial
# Configuración de descarga usando los tags
VERSION="v1.22.2"
REPO="/libretro/RetroArch"
FILE_NAME="RetroArch-${VERSION}.zip"
URL="https://github.com${REPO}/archive/refs/tags/${VERSION}.zip"

echo "Descargando RetroArch ${VERSION} en formato ZIP..."

# Descarga con curl
if curl -L "$URL" -o "$FILE_NAME"; then
    echo "Descarga exitosa. Descomprimiendo..."
    
    # -q para modo silencioso, -o para sobrescribir si ya existe
    if unzip -q "$FILE_NAME"; then
        echo "¡Listo! El contenido se encuentra en la carpeta: RetroArch-${VERSION/v/}"
        # Opcional: eliminar el zip tras extraer
         rm "$FILE_NAME"
    else
        echo "Error: No se pudo descomprimir. Asegúrate de tener 'unzip' instalado."
    fi
else
    echo "Error: Falló la descarga de la versión ${VERSION}."
    exit 1
fi

cd RetroArch-${VERSION}

export CFLAGS="-Ofast -march=armv8-a+crc+simd -O3"
export CXXFLAGS="-Ofast -march=armv8-a+crc+simd -O3"

echo "Actualizando modulos y configurando compilación para RPi 5 (KMS/Vulkan)..."
./fetch-submodules.sh
# Optimizaciones específicas para RPi 5 y desactivación de X11
#./configure --enable-vulkan --enable-kms --enable-egl --enable-udev --enable-alsa --enable-ssl --disable-x11 --enable-wayland --disable-oss --disable-sdl --enable-sdl2 --disable-discord
./configure --enable-vulkan --enable-kms --enable-egl --enable-udev --enable-alsa --enable-ssl --disable-x11 --disable-wayland
#./configure --enable-kms --enable-egl --enable-vulkan --enable-udev --disable-neon --disable-sdl --enable-sdl2 --disable-oss --enable-x11 --enable-wayland --disable-al --disable-jack --disable-qt --enable-builtinmbedtls
echo "Compilando (esto puede tardar unos minutos)..."
make -j$(nproc)

echo "Instalando RetroArch..."
sudo make install

echo "Instalación completada. Puedes iniciar con el comando: retroarch"

# 1. Instalación de dependencias
echo "--- Descarga de cores, Instalando dependencias (git, unzip, p7zip) ---"
sudo apt install -y git unzip p7zip-full

# 2. Configuración
REPO_URL="https://github.com/DOCK-PI3/Rpi5_Retroarch_CORES_AARCH64"
TEMP_DIR="$HOME/temp_retro_cores"
TARGET_DIR="$HOME/.config/retroarch/cores"

# Crear directorios necesarios
mkdir -p "$TEMP_DIR"
mkdir -p "$TARGET_DIR"

# 3. Descarga del repositorio
echo "--- Descargando repositorio de DOCK-PI3 ---"
if [ -d "$TEMP_DIR/.git" ]; then
    cd "$TEMP_DIR" && git pull
else
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
fi

# 4. Extracción de archivos
echo "--- Extrayendo núcleos... ---"
# Directorio temporal para la extracción
EXTRACT_PATH="$TEMP_DIR/extracted_cores"
mkdir -p "$EXTRACT_PATH"

# Extraer .zip
find "$TEMP_DIR" -maxdepth 1 -name "*.zip" -exec unzip -o {} -d "$EXTRACT_PATH" \;

# Extraer .7z (maneja también archivos divididos como .7z.001)
# Buscamos el primer archivo de la secuencia para que 7z los una automáticamente
find "$TEMP_DIR" -maxdepth 1 -name "*.7z.001" -exec 7z x -y {} -o"$EXTRACT_PATH" \;
# Y archivos .7z normales si los hubiera
find "$TEMP_DIR" -maxdepth 1 -name "*.7z" ! -name "*.7z.[0-9]*" -exec 7z x -y {} -o"$EXTRACT_PATH" \;

# 5. Instalación en RetroArch
echo "--- Copiando archivos .so a $TARGET_DIR ---"
find "$EXTRACT_PATH" -name "*.so" -exec cp {} "$TARGET_DIR" \;
cd "$TARGET_DIR" && sudo chmod +x *.so
cd 

# 6. Limpieza
echo "--- Limpiando archivos temporales ---"
rm -rf "$TEMP_DIR"

echo "¡Proceso completado! Los cores optimizados para RPi5 ya están en su sitio."


# 7. Instalación de EmulationStation-DE
echo "Instalando EmulationStation-DE..."

# --- 1. PREPARACIÓN Y DEPENDENCIAS DE COMPILACIÓN ---
echo "Instalando herramientas de compilación para Pi 5..."
sudo apt install -y build-essential git cmake pkg-config alsamixergui libfreeimage-dev \
libfreetype6-dev libcurl4-openssl-dev libasound2-dev libicu-dev \
libsdl2-dev libvlc-dev libvlccore-dev libpoppler-cpp-dev \
libavcodec-dev libavformat-dev libswresample-dev libpugixml-dev cage xwayland
#xfce4 xfce4-pulseaudio

sudo apt-get -y install clang-format cmake gettext libharfbuzz-dev libicu-dev libsdl2-dev libavcodec-dev libavfilter-dev libavformat-dev libavutil-dev libfreeimage-dev libfreetype6-dev libgit2-dev libcurl4-openssl-dev libpugixml-dev libasound2-dev libbluetooth-dev libgl1-mesa-dev libpoppler-cpp-dev
 
# 1,2. seleccionar clang para compilar
#sudo update-alternatives --config c++

# --- 2. CLONAR REPOSITORIO ---
cd ~
git clone https://gitlab.com/es-de/emulationstation-de.git
cd emulationstation-de

# --- 3. COMPILACIÓN OPTIMIZADA ---
echo "Compilando ES-DE con optimizaciones de CPU (esto tardará un poco)..."

cmake -DGLES=on -DVIDEO_HW_DECODING=on -DDEINIT_ON_LAUNCH=on .
make -j$(nproc)

# --- 4. INSTALACIÓN ---
echo "Instalando ES-DE en el sistema..."
sudo make install

# --- 5. CONFIGURACIÓN DE RENDIMIENTO GRÁFICO ---
# ES-DE en Pi 5 vuela con el renderizador de hardware habilitado
mkdir -p ~/ES-DE/settings
cat <<EOF > ~/ES-DE/settings/es_settings.xml
<?xml version="1.0"?>
<config>
    <string name="Renderer" value="OpenGL" />
    <bool name="VramLimit8192" value="true" />
    <bool name="PreloadUI" value="true" />
    <bool name="OptimizeImages" value="true" />
</config>
EOF

echo "ES-DE compilado e instalado con éxito."


# 8. Configuración de Auto-Arranque (Modo Kiosk) PROXIMO


# --- CONFIGURACIÓN DE VIDEO VULKAN (CLAVE PARA PI 5) ---
# 9.Forzamos a RetroArch a usar Vulkan y el driver de video correcto
cat <<EOF > ~/.config/retroarch/retroarch.cfg
video_driver = "vulkan"
menu_driver = "ozone"
input_joypad_driver = "udev"
video_vsync = "true"
video_threaded_buildup = "true"
libretro_directory = "~/.config/retroarch/cores"
EOF

# --- Configurando video intro part1
sudo apt install -y mpv seatd
sudo usermod -a -G video,render,audio $USER

echo "ES-DE y RetroArch con sus Cores instalados y configurados para Vulkan. Reiniciando.... " 
sleep 3

#sudo reboot
