# LABORATORIO 1
**Demostración práctica del uso de Hash criptográfico (SHA-256)**

## Objetivo
● Comprender qué es un hash  
● Generar hashes reales  
● Verificar integridad de un archivo  
● Mostrar cómo un bit modificado cambia totalmente el hash

---

## 1. Crear un archivo real
Ejecuta el siguiente comando para crear un archivo de texto simple:
```bash
echo "Mensaje de prueba para hashing." > mensaje.txt
```

## 2. Generar un hash SHA-256
Calcula el hash SHA-256 del archivo creado:
```bash
openssl dgst -sha256 mensaje.txt
```

**Salida esperada:**
```
SHA256(mensaje.txt)=
4a6d7c0f3e0f5e48cd177c2f92cd30b8e134ea7b9c7295400cc72cfa6142b5af
```
*(Nota: El hash puede variar si tu implementación de echo incluye/excluye saltos de línea diferentes, pero el formato será el mismo).*

**Interpretación:**
● El archivo puede tener 10 bytes o 10 MB; el hash siempre tiene **256 bits** (64 caracteres hexadecimales).
● Cualquier cambio en el archivo produce un hash totalmente diferente.

## 3. Guardar el hash en un archivo separado
Es común guardar el hash para verificaciones futuras:
```bash
openssl dgst -sha256 mensaje.txt > hash_original.txt
```

## 4. Simular integridad: copiar archivo y verificar
Hacemos una copia exacta del archivo y verificamos su hash:
```bash
cp mensaje.txt copia_mensaje.txt
openssl dgst -sha256 copia_mensaje.txt
```
*El hash debe ser exactamente el mismo que en el paso 2.*

## 5. Demostrar sensibilidad al cambio de 1 bit
Modificamos ligeramente el archivo (agregando un espacio al final) para ver el efecto avalancha:
```bash
echo " " >> copia_mensaje.txt
```

Calculamos el nuevo hash:
```bash
openssl dgst -sha256 copia_mensaje.txt
```

**Salida totalmente distinta (ejemplo):**
```
SHA256(copia_mensaje.txt)=
c8a91c332f2c2e2bdee7d3ad05c8c40fb98f4dfd2fc01eccf9df7047b1e844d1
```

**Conclusión:**
● Aunque el contenido es casi idéntico, el hash es completamente distinto.
● Esto demuestra **Avalancha**: propiedad esencial de funciones hash criptográficas.
