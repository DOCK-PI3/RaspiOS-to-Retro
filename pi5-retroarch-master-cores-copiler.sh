#!/bin/bash

# --- CONFIGURACIÓN DE ARQUITECTURA PI 5 ---
export CFLAGS="-O3 -march=armv8.2-a+crc+simd -mtune=cortex-a76 -mcpu=cortex-a76 -ffast-math -ftree-vectorize"
export CXXFLAGS="$CFLAGS"
export MAKEFLAGS="-j$(nproc)"
CORE_DIR="$HOME/.config/retroarch/cores"
TEMP_DIR="$HOME/build_all_cores"

mkdir -p "$CORE_DIR"
mkdir -p "$TEMP_DIR"

# --- INSTALACIÓN DE DEPENDENCIAS ---
sudo apt update
sudo apt install -y git build-essential cmake pkg-config libvulkan-dev \
libgles2-mesa-dev libgbm-dev libdrm-dev libasound2-dev libudev-dev \
libfreetype6-dev libxml2-dev libx11-dev libxkbcommon-dev curl jq


# --- OBTENCIÓN DINÁMICA DE REPOS DE CORES ---
echo "Consultando todos los repositorios de cores en Libretro..."
# Usamos 'jq' para extraer solo los nombres de repositorios que son cores
PAGE=1
while : ; do
    REPOS=$(curl -s "https://api.github.com" | jq -r '.[].name | select(endswith("-libretro") or endswith("_libretro"))')
    [ -z "$REPOS" ] && break
    ALL_CORES+="$REPOS "
    ((PAGE++))
done

# --- BUCLE DE COMPILACIÓN ---
cd "$TEMP_DIR"

for core in $ALL_CORES; do
    echo "--------------------------------------"
    echo " COMPILANDO: $core"
    echo "--------------------------------------"
    
    # Clonar de forma recursiva por si tiene submódulos (necesario en muchos cores)
    git clone --depth 1 --recursive "https://github.com"
    cd "$core"
    
    # Lógica de compilación adaptativa
    if [ -f "Makefile.libretro" ]; then
        make -f Makefile.libretro
    elif [ -f "Makefile" ]; then
        make
    elif [ -d "libretro" ]; then
        cd libretro && make && cd ..
    else
        mkdir -p build && cd build && cmake .. && make && cd ..
    fi

    # Mover el .so resultante y limpiar para no llenar el disco
    find . -name "*_libretro.so" -exec cp {} "$CORE_DIR/" \;
    cd "$TEMP_DIR"
    rm -rf "$core"
done

echo "Proceso finalizado. Cores optimizados en $CORE_DIR"