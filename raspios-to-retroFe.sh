#!/bin/bash

# --- 1. ACTUALIZACIÓN Y DEPENDENCIAS CRÍTICAS ---
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y build-essential git cmake libasound2-dev libpulse-dev \
libudev-dev libx11-dev libxext-dev libvulkan-dev libgles2-mesa-dev \
libgbm-dev libdrm-dev libsdl2-dev libfreeimage-dev liblua5.3-dev \
libsqlite3-dev zlib1g-dev libcurl4-openssl-dev libavcodec-dev libavformat-dev

# --- 2. OPTIMIZACIÓN DEL SISTEMA (Config.txt) ---
# Se recomienda un ventilador oficial para estos valores.
if ! grep -q "arm_freq=2800" /boot/firmware/config.txt; then
    echo "Aplicando Overclock y optimizaciones de energía..."
    sudo bash -c "cat >> /boot/firmware/config.txt <<EOF
# Optimizaciones Gaming RPi5
arm_freq=2800
gpu_freq=900
force_turbo=1
over_voltage_delta=50000
dtparam=pciex1_gen=3
EOF"
fi

# --- 3. COMPILACIÓN DE RETROARCH (Optimizado para Cortex-A76) ---
cd ~
git clone --depth 1 https://github.com/libretro/RetroArch.git retroarch
cd retroarch
# Flags específicos para Raspberry Pi 5 y arquitectura ARM64
export CFLAGS="-Ofast -mcpu=cortex-a76 -mtune=cortex-a76"
./configure --enable-vulkan --enable-egl --enable-gbm --enable-drm --enable-kms \
            --enable-x11 --enable-wayland --enable-floathard --enable-neon
make -j$(nproc)
sudo make install

# --- 4. COMPILACIÓN DE CORES SELECCIONADOS ---
# Se recomienda usar libretro-super para gestionar la descarga y compilación
cd ~
git clone --depth 1 https://github.com/libretro/libretro-super
cd libretro-super
# Compilamos cores de alto rendimiento recomendados para RPi5
./libretro-fetch.sh flycast genesis_plus_gx snes9x picodrive mgba mupen64plus_next
./libretro-build.sh flycast genesis_plus_gx snes9x picodrive mgba mupen64plus_next
mkdir -p ~/.config/retroarch/cores
cp dist/unix/*.so ~/.config/retroarch/cores/

# --- 5. COMPILACIÓN DE RETROFE (Frontend) ---
cd ~
git clone https://github.com/phulshof/RetroFE
cd RetroFE/RetroFE
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
sudo make install

# Activar autologin 
sudo raspi-config nonint do_boot_behaviour B2

# Inicio automatico de RetroFE
# Crear o editar el archivo de perfil del usuario
cat <<EOF >> ~/.bash_profile

# Si estamos en la tty1 (la principal de arranque), lanza el frontend
if [ "\$(tty)" = "/dev/tty1" ]; then
    # Opcional: Limpiar la pantalla para un look de consola
    clear
    echo "Iniciando Sistema de Juegos..."
    
    # Ejecuta RetroFE (asegúrate de que la ruta sea la correcta tras la compilación)
    # Si lo instalaste con 'sudo make install', suele estar en /usr/local/bin/retrofe
    retrofe
fi
EOF


echo "Instalación completada. Reinicia para aplicar el overclock y demas configuraciones."

sudo reboot
