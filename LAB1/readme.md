# LABORATORIO 1
**Demostración práctica del uso de Hash criptográfico (SHA-256)**

## Objetivo
● Comprender qué es un hash
● Generar hashes reales
● Verificar integridad de un archivo
● Mostrar cómo un bit modificado cambia totalmente el hash

---

## 1. Crear un archivo real
```bash
echo "Mensaje de prueba para hashing." > mensaje.txt
```
**Resumen para informe:**
Se creó un archivo de texto plano denominado "mensaje.txt" con contenido controlado para establecer una línea base de integridad.

## 2. Generar un hash SHA-256
```bash
openssl dgst -sha256 mensaje.txt
```

**Salida esperada:**
```
SHA256(mensaje.txt)=
4a6d7c0f3e0f5e48cd177c2f92cd30b8e134ea7b9c7295400cc72cfa6142b5af
```

**Interpretación:**
● El archivo puede tener 10 bytes o 10 MB; el hash siempre tiene 256 bits (64 caracteres hexadecimales).
● Cualquier cambio en el archivo produce un hash totalmente diferente.

**Resumen para informe:**
Se generó la firma digital (hash) del archivo original utilizando el algoritmo SHA-256. Se obtuvo una cadena hexadecimal única que identifica inequívocamente el contenido actual del archivo.

## 3. Guardar el hash en un archivo separado
```bash
openssl dgst -sha256 mensaje.txt > hash_original.txt
```
**Resumen para informe:**
Se almacenó el hash calculado en un archivo externo ("hash_original.txt") para simular un mecanismo de control de integridad que permitirá validaciones futuras.

## 4. Simular integridad: copiar archivo y verificar
```bash
cp mensaje.txt copia_mensaje.txt
openssl dgst -sha256 copia_mensaje.txt
```
**El hash debe ser exactamente el mismo.**

**Resumen para informe:**
Se realizó una copia exacta del archivo y se calculó su hash. Al comparar este nuevo hash con el original almacenado, se confirmó que son idénticos, validando matemáticamente que la copia no ha sufrido alteraciones.

## 5. Demostrar sensibilidad al cambio de 1 bit
Modificar ligeramente el archivo:
```bash
echo " " >> copia_mensaje.txt
```

Nuevo hash:
```bash
openssl dgst -sha256 copia_mensaje.txt
```

**Salida totalmente distinta (ejemplo):**
```
SHA256(copia_mensaje.txt)=
c8a91c332f2c2e2bdee7d3ad05c8c40fb98f4dfd2fc01eccf9df7047b1e844d1
```

**Interpretación:**
● Aunque el contenido es casi idéntico, el hash es completamente distinto.
● Esto demuestra **Avalancha**: propiedad esencial de funciones hash criptográficas.

**Resumen para informe:**
Se introdujo una modificación mínima (un espacio en blanco) en el archivo copia. El recálculo del hash arrojó un valor completamente diferente al original, demostrando el efecto avalancha: cualquier cambio arbitrario en la entrada resulta en una salida impredecible y sin correlación con la anterior, garantizando la detección de manipulaciones.
