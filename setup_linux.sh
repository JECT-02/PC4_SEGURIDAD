#!/bin/bash

# Instalación de herramientas de sistema necesarias para los laboratorios en Kali Linux

echo "[+] Actualizando repositorios..."
sudo apt-get update

echo "[+] Instalando herramientas base (openssl, curl, jq, git)..."
sudo apt-get install -y openssl curl jq git

echo "[+] Instalando hashpump (Vital para laboratorios 3-8)..."
# Si hashpump no está en el repo oficial de tu versión de Kali, puedes necesitar compilarlo o agregar repos universe
sudo apt-get install -y hashpump || echo "ADVERTENCIA: No se pudo instalar hashpump via apt. Intentando compilar o usar alternativa..."

echo "[+] Instalando Docker y Compose (Para Laboratorio 8)..."
sudo apt-get install -y docker.io docker-compose-v2

echo "[+] Instalando dependencias de Python..."
if command -v pip3 &> /dev/null; then
    pip3 install -r requirements.txt
else
    sudo apt-get install -y python3-pip
    pip3 install -r requirements.txt
fi

echo "[+] Listado de instalación completado."
echo "Nota: Si hashpump falló, revisa https://github.com/iagox86/hash_extender"
