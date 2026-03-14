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
git clone --depth 1 https://github.com/libretro/RetroArch.git
cd RetroArch
./fetch-submodules.sh
# DESCARGAR RETROARCH EN SU ULTIMA VERSION --->
#export CFLAGS='-O3 -march=armv8.2-a+crc+simd -mtune=cortex-a76 -mcpu=cortex-a76 -ffast-math -ftree-vectorize'
#export CXXFLAGS='-O3 -march=armv8.2-a+crc+simd -mtune=cortex-a76 -mcpu=cortex-a76 -ffast-math -ftree-vectorize'
#./configure --enable-floathard --enable-7zip --enable-x11 --enable-wayland --enable-vulkan --enable-opengl
#make -j4
#sudo make install
#cd && sudo rm -R RetroArch/
export CFLAGS="-Ofast -mcpu=cortex-a76 -mtune=cortex-a76"
./configure --enable-vulkan --enable-egl --enable-gbm --enable-drm --enable-kms \
            --disable-x11 --disable-wayland --enable-floathard --enable-neon
make -j$(nproc)
sudo make install

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
# Usamos -march=native para que use todas las instrucciones de la Pi 5 (ARMv8.2-A)
# Usamos -O3 para máxima optimización de velocidad
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
echo "Configurando mini escritorio y arranque directo a ES-DE..."
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y libx264-dev libjpeg-dev neofetch
# install the remaining plugins
sudo apt-get install -y libgstreamer1.0-0 libgstreamer-gl1.0-0 libgstreamer-plugins-base1.0-0 gstreamer1.0-gl gstreamer1.0-pulseaudio gstreamer1.0-plugins-good 
sudo apt-get install -y git g++ cmake dos2unix zlib1g-dev libsdl2-2.0 libsdl2-mixer-2.0 libsdl2-image-2.0 libsdl2-ttf-2.0
sudo apt-get install -y libsdl2-dev libsdl2-mixer-dev libsdl2-image-dev libsdl2-ttf-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
sudo apt-get install -y gstreamer1.0-libav zlib1g-dev libglib2.0-0 libglib2.0-dev libavcodec-extra sqlite3
sudo apt-get install -y gstreamer1.0-omx-* gstreamer1.0-plugins-bad
# Dependencia para hacer el make y ejecutar retrofe en buster RPI4 - retrofe #
# ----> sudo Xorg :0 -configure uuu :0.0
sudo apt-get install -y xinit xterm xorg xorg-dev xorg-server-source menu openbox obconf thunar pulseaudio pulseaudio-utils
sudo apt-get install -y git g++ cmake dos2unix zlib1g-dev libsdl2* zlib1g-dev libglib2.0-0 libglib2.0-dev sqlite3
#Descargar y vlc y mpv
sudo apt install -y mpv xserver-xorg x11-xserver-utils

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
echo "Instalación finalizada. Reiniciando.... " 
sleep 3

#sudo reboot
