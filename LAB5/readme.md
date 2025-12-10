# LABORATORIO 5: Ataque de Extensión de Longitud a Tokens API "Legacy"

**Vulnerabilidad:** Elevación de privilegios en APIs antiguas que usan `MAC = SHA256(clave || datos)`.

**Contexto:**
Muchas implementaciones antiguas generaban tokens concatenando datos y hash, por ejemplo: `base64( datos || "." || sha256( key || datos ) )`. Esto permite a un atacante agregar campos (como `&role=admin`) y generar un MAC válido sin conocer la clave.

---

## 1. Crear un token inseguro (Simulación del Servidor)

Vamos a actuar como el servidor que emite un token para un usuario normal.

### 1.1 Crear clave secreta
```bash
echo -n "CLAVE_ULTRA_SECRETA_API" > key.txt
```

### 1.2 Datos del usuario
```bash
echo -n "user_id=15&role=user" > datos.txt
```

### 1.3 Generar MAC inseguro
El servidor calcula el hash de `CLAVE` + `DATOS`.
```bash
original_mac=$(printf "CLAVE_ULTRA_SECRETA_APIuser_id=15&role=user" | openssl dgst -sha256 | awk '{print $2}')
echo "MAC Original: $original_mac"
```
*(Ejemplo esperado: `6ccab030c0d32cd63da4bc86c87410c432e119ce8843a554d91044c33f7382fb`)*

### 1.4 Construcción del Token (Lo que recibe el cliente)
El token suele viajar en Base64.
```bash
echo -n "user_id=15&role=user.$original_mac" | base64
```
**Este es el token que el atacante intercepta.**

---

## 2. El Atacante intercepta y analiza

El atacante captura el string Base64.
1.  **Decodifica:**
    ```bash
    echo -n "<TOKEN_BASE64_CAPTURADO>" | base64 -d
    ```
2.  **Separa los componentes:**
    *   **Mensaje:** `user_id=15&role=user`
    *   **Firma (MAC):** `6ccab030...`

**Objetivo:** Agregar `&role=admin` al final para obtener control total.

---

## 3. Ejecutar el Ataque (HashPump)

Usamos `hashpump` para calcular el nuevo hash y el bloque de padding necesario para conectar el mensaje original con el payload malicioso.

**Parámetros:**
*   `-s`: MAC original interceptado.
*   `-d`: Datos originales (`user_id=15&role=user`).
*   `-a`: Datos a inyectar (`&role=admin`).
*   `-k`: Longitud de la clave (23 caracteres en este caso, en la realidad se haría fuerza bruta).

```bash
hashpump \
-s 6ccab030c0d32cd63da4bc86c87410c432e119ce8843a554d91044c33f7382fb \
-d "user_id=15&role=user" \
-a "&role=admin" \
-k 23
```
*(Asegúrate de reemplazar el hash `-s` si te salió uno diferente en el paso 1.3)*

**Salida de HashPump:**
*   **New Hash:** `e7a1e378...` (Tu nuevo MAC válido).
*   **New Message:** `user_id=15&role=user\x80\x00...\x00&role=admin` (Tu mensaje con padding).

---

## 4. Construir el Token Falsificado

El atacante ahora debe armar el token en el formato que espera el servidor (Base64).

Debido a que el *New Message* tiene caracteres hexadecimales no imprimibles (`\x80`, etc.), es difícil copiar y pegar directamente en la terminal. Hashpump a veces imprime con escapes.

**Opción manual (conceptual):**
Token Falso = `Base64( NewMessage + "." + NewHash )`

---

## 5. Validación en el Servidor (Prueba de Éxito)

El servidor vulnerable recibe el token, lo decodifica y verifica:
`SHA256( CLAVE || MENSAJE_RECIBIDO ) == MAC_RECIBIDO ?`

Simulamos la verificación del servidor con el mensaje falsificado que generó hashpump:

```bash
# Nota: <nuevo_mensaje_con_padding> es lo que hashpump generó como "New message"
# concatenado a la clave.
# Esto es difícil de hacer con copy-paste por los caracteres nulos (\x00).
```

**Verificación conceptual:**
El servidor procesará:
`CLAVE` + `user_id=15&role=user` + `PADDING` + `&role=admin`

Debido a cómo funciona SHA-256, el hash resultante será **idéntico** al `New Hash` que generaste con hashpump.
El servidor leerá `role=user`, luego basura (padding), y luego `role=admin`. La mayoría de parsers de API simples tomarán el **último parámetro**, otorgando privilegios de administrador.

---

## 6. Explicación Técnica y Defensa

**Por qué funciona:**
El atacante usa el MAC original (que es el estado interno del hash) como punto de partida para continuar hasheando los datos extra (`&role=admin`). No necesita la clave porque el estado interno ya "absorbió" la clave en la primera etapa.

**Cómo prevenirlo:**
1.  **NO USAR** `MAC = SHA256(key || data)`.
2.  **USAR HMAC:** `HMAC-SHA256(key, data)`. HMAC hace un doble hash (`hash(key XOR opad || hash(key XOR ipad || data))`) que impide matemáticamente extender el mensaje desde la salida.
3.  **Modernización:** Usar estándares como **JWT (JSON Web Tokens)** firmados correctamente (HS256 usa HMAC, RS256 usa firmas asimétricas).
