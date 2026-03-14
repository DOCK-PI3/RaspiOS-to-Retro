#!/bin/bash
### Creado por DockPi3 15-03-2026
####################################
#set -o xtrace # Realiza una traza de lo que se ha ejecutado. Es para depurar ,ver donde y porque se está produciendo un error.
#set -o errexit # Se sale del script inmediatamente cuando falla un comando.

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
sudo apt install -y build-essential git cmake libasound2-dev libpulse-dev libwayland-dev libx11-dev libxkbcommon-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libdrm-dev mesa-vulkan-drivers ffmpeg python3-dev libusb-1.0-0-dev liblua5.3-dev libavcodec-dev libavformat-dev

# 3. Instalación de RetroArch (Compilado para Pi 5)
echo "Compilando RetroArch..."
cd ~

# Script para instalar RetroArch en RPi 5 (OS Lite 64-bit) modo KMS

set -e

echo "Actualizando el sistema..."
echo "Instalando dependencias necesarias..."
sudo apt install -y build-essential git libx11-xcb-dev libudev-dev libegl-dev libgles-dev libasound2-dev libpulse-dev libdrm-dev libgbm-dev libfreetype6-dev libxkbcommon-dev libxml2-dev zlib1g-dev libavcodec-dev libavformat-dev libswscale-dev libavdevice-dev libvulkan-dev mesa-vulkan-drivers yasm libpng-dev zlib1g-dev libxkbcommon-dev libsdl2-dev libasound2-dev libusb-1.0-0-dev
sudo apt install -y libc6-dev libc6-dev-arm64-cross libsigc++-3.0-dev

# INSTALAR DEPENDENCIAS DESPUES DE ACTUALIZAR LISTA DE PAQUETES --->
sudo apt install -y build-essential libasound2-dev libudev-dev libxkbcommon-dev zlib1g-dev libfreetype6-dev libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libavcodec-dev libsdl2-dev libsdl-image1.2-dev libxml2-dev yasm libavformat-dev libavdevice-dev libswresample-dev libswscale-dev libv4l-dev libgl*-mesa-dev
sudo apt install -y xcb-proto libxcb-xkb-dev x11-xkb-utils libx11-xcb-dev libxkbcommon-x11-dev
sudo apt install -y libusb-1.0-0-dev libraspberrypi-dev

# Clonar repositorio oficial
if [ ! -d "RetroArch" ]; then
    git clone --depth 1 https://github.com/libretro/RetroArch.git
fi

cd RetroArch
export CFLAGS="-march=armv8-a+crc+simd -O3"
export CXXFLAGS="-march=armv8-a+crc+simd -O3"
echo "Configurando compilación para RPi 5 (KMS/Vulkan)..."
# Optimizaciones específicas para RPi 5 y desactivación de X11
#./configure --enable-vulkan --enable-kms --enable-egl --enable-udev --enable-alsa --enable-ssl --disable-x11 --disable-wayland
./configure --disable-x11 --disable-wayland --enable-kms --enable-egl --enable-vulkan --disable-sdl --enable-sdl2 --disable-oss --disable-al --disable-jack --disable-qt --enable-builtinmbedtls
echo "Compilando (esto puede tardar unos minutos)..."
make -j$(nproc) HAVE_NEON=0

echo "Instalando RetroArch..."
sudo make install

echo "Instalación completada. Puedes iniciar con el comando: retroarch"

# 4. Instalación de EmulationStation-DE
echo "Instalando EmulationStation-DE..."

# --- 1. PREPARACIÓN Y DEPENDENCIAS DE COMPILACIÓN ---
echo "Instalando herramientas de compilación para Pi 5..."
sudo apt install -y build-essential git cmake pkg-config libfreeimage-dev \
libfreetype6-dev libcurl4-openssl-dev libasound2-dev libicu-dev \
libsdl2-dev libvlc-dev libvlccore-dev libpoppler-cpp-dev \
libavcodec-dev libavformat-dev libswresample-dev libpugixml-dev

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


# 5. Configuración de Auto-Arranque (Modo Kiosk)


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
mkdir -p ~/ES-DE/custom_systems
cat <<EOF > ~/ES-DE/es_systems.xml
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
sleep 2
echo "Instalación de ES-DE y RetroArch finalizada. Reiniciando.... " 
sleep 3

#sudo reboot
