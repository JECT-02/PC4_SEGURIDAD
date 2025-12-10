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
**Resumen para informe:** Creamos un archivo base que servirá como nuestra "evidencia digital". Este archivo tiene un contenido específico que queremos proteger o verificar.

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

**Resumen para informe:** Obtenemos la huella digital única (fingerprint) del archivo. Este valor alfanumérico de 256 bits representa el contenido exacto del archivo. Mientras el contenido no cambie, este valor será siempre idéntico.

## 3. Guardar el hash en un archivo separado
Es común guardar el hash para verificaciones futuras:
```bash
openssl dgst -sha256 mensaje.txt > hash_original.txt
```
**Resumen para informe:** Almacenamos el hash original. Esto simula el proceso de guardar un checksum de seguridad para validar la integridad en el futuro.

## 4. Simular integridad: copiar archivo y verificar
Hacemos una copia exacta del archivo y verificamos su hash:
```bash
cp mensaje.txt copia_mensaje.txt
openssl dgst -sha256 copia_mensaje.txt
```
**Resumen para informe:** Al verificar la copia, el hash coincide perfectamente. Esto demuestra matemáticamente que la copia es idéntica al original y que la integridad de los datos se mantiene intacta.

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

**Resumen para informe:** Una modificación trivial (un espacio) alteró por completo el resultado del hash. Esto ilustra el "Efecto Avalancha": no existen similitudes entre el hash original y el modificado, lo que impide predecir cambios o revertir la función.
