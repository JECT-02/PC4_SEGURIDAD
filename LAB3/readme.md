# LABORATORIO 3: Ataque de Extensión de Longitud (Length Extension Attack)

**Vulnerabilidad:** Uso inseguro de HASH(clave || mensaje) como MAC.  
**Afecta a:** MD5, SHA-1, SHA-256, SHA-512 (hashes basados en Merkle–Damgård).

---

## 1. Concepto
Un atacante puede generar un nuevo MAC válido para un mensaje extendido (`mensaje || datos_extra`) sin conocer la clave secreta, si el sistema usa la construcción: `MAC = SHA256(clave || mensaje)`.

## 2. Requerimientos
*   **openssl**
*   **hashpump**: Herramienta estándar para demostrar este ataque.

**Instalación en Kali Linux:**
```bash
sudo apt install hashpump
```
*(Nota: Si no funciona el install, compilar desde source o usar hash_extender).*

---

## 3. Escenario del Laboratorio

### Paso 1: Configuración del Servidor (Víctima)
El servidor tiene una clave secreta que **nadie más conoce**.

```bash
# Crear clave secreta (simulada)
echo -n "CLAVE_SUPER_SECRETA_123" > clave.key
```

### Paso 2: Mensaje Legítimo
Se crea una transacción legítima.
```bash
echo -n "operacion=transferencia&cantidad=100" > mensaje.txt
```

### Paso 3: Servidor genera MAC inseguro
El servidor calcula el MAC concatenando clave y mensaje. **Este MAC se envía por la red y es visible para el atacante.**

```bash
# Calculamos SHA256(clave || mensaje)
mac_original=$(printf "CLAVE_SUPER_SECRETA_123operacion=transferencia&cantidad=100" | openssl dgst -sha256 | awk '{print $2}')

echo "MAC Original capturado: $mac_original"
```
*(Ejemplo de salida esperada: `4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17`)*

---

## 4. El Ataque

El atacante quiere agregar `&cantidad=1000000` al mensaje original sin romper la validez del MAC, pero **no tiene la clave**.

### Paso 4: Ejecutar HashPump
Usamos `hashpump` para calcular el nuevo hash y el padding necesario.

**Parámetros:**
*   `-s`: Firma (hash) original capturada.
*   `-d`: Datos originales (mensaje conocido).
*   `-a`: Datos a añadir (el ataque).
*   `-k`: Longitud estimada de la clave (aquí sabemos que es 23 caracteres, pero un atacante probaría varias longitudes).

```bash
# Reemplaza el hash (-s) con el que obtuviste en el Paso 3
hashpump \
-s 4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17 \
-d "operacion=transferencia&cantidad=100" \
-a "&cantidad=1000000" \
-k 23
```

*(Nota: La longitud de la clave "CLAVE_SUPER_SECRETA_123" es 23 caracteres).*

### Paso 5: Resultado del Ataque
`hashpump` te dará:
1.  **New Hash:** El nuevo MAC válido.
2.  **New Message:** El mensaje con el padding binario inyectado y el nuevo comando al final.

*Ejemplo de salida:*
```
New hash: c4ae908bd63e5fd621153df132764ebebd078d43a3d581123f0b89031db03bfb
New message: operacion=transferencia&cantidad=100\x80\x00...\x00&cantidad=1000000
```

---

## 5. Verificación (El Servidor la acepta)

Para probar que el ataque funcionó, simularemos que el servidor recibe este mensaje "basura" (con padding) y verifica el hash manualmente.

1.  Copia el "string hexadecimal" o binario que generó hashpump (el *New Message*) a un archivo `mensaje_modificado.txt`. (Esto suele requerir manejo cuidadoso de caracteres no imprimibles, hashpump a veces lo saca en formato `\x`).
2.  Verifica:

```bash
# Simulación conceptual de la verificación del servidor
# Concatenamos CLAVE + MENSAJE_MODIFICADO y hasheamos
printf "CLAVE_SUPER_SECRETA_123<CONTENIDO_DEL_NUEVO_MENSAJE>" | openssl dgst -sha256
```

**Resultado:** El hash debe coincidir con el **New Hash** que predijo el atacante.

---

## 6. Explicación Técnica
1.  **Merkle-Damgård**: SHA-256 procesa en bloques y guarda un estado interno.
2.  El hash final *es* el estado interno final.
3.  El atacante toma ese estado (el MAC original), lo carga en su calculadora de SHA-256, añade el padding que SHA-256 hubiera añadido, y sigue procesando los datos extra.
4.  Resultado: Un hash válido para `Clave || Mensaje || Padding || DatosExtra` sin necesitar la `Clave`.

## 7. Prevención
Usar **HMAC**.
`HMAC = H( (key ⊕ opad) || H( (key ⊕ ipad) || mensaje ) )`
El anidamiento y uso de la clave en dos pasos previene que el atacante pueda extender el mensaje desde el hash de salida.
