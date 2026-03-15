#!/bin/bash

# 1. Actualización e Instalación de herramientas
echo "--- Actualizando sistema e instalando dependencias ---"
sudo apt update && sudo apt upgrade -y
sudo apt install -y snapd vlc ffmpeg git python3-pip

# 2. Instalación del reproductor optimizado
echo "--- Instalando rpi-iptv-player (vía Snap) ---"
sudo systemctl enable --now snapd.seeded.service
sudo snap install rpi-iptv-player

# 3. Configuración de Memoria GPU (256MB para video fluido)
echo "--- Optimizando memoria GPU en config.txt ---"
# Elimina cualquier línea previa de gpu_mem y añade la nueva
sudo sed -i '/gpu_mem=/d' /boot/config.txt
echo "gpu_mem=256" | sudo tee -a /boot/config.txt

# 4. Configurar Autologin (Inicio de sesión sin contraseña)
echo "--- Configurando Autologin en consola ---"
# Esto emula lo que hace raspi-config para el usuario actual
USER_NAME=$(whoami)
sudo raspi-config nonint do_boot_behaviour B2

# 5. Configurar el arranque automático del programa
echo "--- Configurando inicio automático del reproductor ---"
# Añade el comando al final de .bashrc si no existe ya
if ! grep -q "rpi-iptv-player" ~/.bashrc; then
  echo "" >> ~/.bashrc
  echo "# Inicio automático del reproductor IPTV" >> ~/.bashrc
  echo "rpi-iptv-player" >> ~/.bashrc
fi

echo "-------------------------------------------------------"
echo "¡TODO LISTO! La Raspberry se reiniciará en 5 segundos."
echo "Al volver, entrará directa al reproductor IPTV."
echo "-------------------------------------------------------"
sleep 5
sudo reboot