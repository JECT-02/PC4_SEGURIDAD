# LABORATORIO 6: Ataque de Extensión de Longitud en Tokens JSON

**Escenario:** Un API "legacy" utiliza una construcción insegura para firmar tokens JSON:
`Token = Base64(payload) . SHA256(clave || payload)`

Aprovecharemos esto para **escalar privilegios** (de `user` a `admin`) inyectando campos JSON adicionales sin conocer la clave secreta.

---

## 1. Preparación del Servidor (Víctima)

### 1.1 Crear la clave secreta
```bash
echo -n "CLAVE_SÚPER_SECRETA_DEL_API" > api.key
```

### 1.2 Crear el payload original
El servidor genera un token para un usuario normal "juan".
```bash
echo -n '{"user":"juan","role":"user","expires":1738000000}' > payload.json
```

### 1.3 Generar el Token (Base64 + MAC)
El token consta de los datos en Base64 y una firma hash.

**1. Generar Base64:**
```bash
base64 payload.json > payload.b64
cat payload.b64
```
*(Guarda este valor: `eyJ1c2VyIjoianVhbiIsInJvbGUiOiJ1c2VyIiwiZXhwaXJlcyI6MTczODAwMDAwMH0=`)*

**2. Generar MAC Inseguro:**
Calculamos `SHA256(clave || payload)`.
```bash
mac=$(printf "CLAVE_SÚPER_SECRETA_DEL_API$(cat payload.json)" | openssl dgst -sha256 | awk '{print $2}')
echo "MAC Original: $mac"
```
*(Ejemplo esperado: `7df0faeec84a4f71c76db548a3d909cb0f78c03199e15ef4b88d132fb9258769`)*

---

## 2. El Ataque

El atacante intercepta:
1.  **Payload Base64:** `eyJ...`
2.  **MAC:** `7df0...`

**Objetivo:** Inyectar `,"role":"admin"` al JSON.
Aunque esto rompe la estructura JSON estricta (queda basura en medio), muchos parsers aceptan la *última* ocurrencia de una clave repetida o ignoran datos binarios intermedios, permitiendo la escalada.

### Ejecución con HashPump

```bash
hashpump \
-s 7df0faeec84a4f71c76db548a3d909cb0f78c03199e15ef4b88d132fb9258769 \
-d '{"user":"juan","role":"user","expires":1738000000}' \
-a ',"role":"admin"' \
-k 28
```
*(Nota: `-k 28` es la longitud de la clave "CLAVE_SÚPER_SECRETA_DEL_API")*

**Salida de HashPump:**
*   **New Hash:** `c41fa603b49ea682e62974b1389fb10b10d9433741c59b03b26dfd5a89778b10`
*   **New Data:** `{"user":"juan"...,"expires":1738000000}\x80\x00...\x00,"role":"admin"`

---

## 3. Reconstrucción del Token Falsificado

El atacante debe ensamblar el nuevo token para enviarlo a la API.

1.  **Codificar nuevo payload:**
    El "New Data" de hashpump (incluyendo el padding binario) debe codificarse a Base64.
    *(Conceptualmente)*: `base64( NewData )` -> `payload_mod.b64`

2.  **Unir:**
    `Token_Final = payload_mod.b64 . NewHash`

---

## 4. Validación (Simulación Servidor)

El servidor recibe el `Token_Final`, decodifica el Base64 para obtener el JSON modificado, y verifica la firma concatenando su clave.

```bash
# Simulación de lo que hace el servidor internamente:
# printf "CLAVE...<CONTENIDO_DEL_NUEVO_PAYLOAD>" | openssl dgst -sha256
```

Debido a la propiedad de Merkle-Damgård, el hash resultante será:
`c41fa603b49ea682e62974b1389fb10b10d9433741c59b03b26dfd5a89778b10`

¡Coincide con el hash enviado por el atacante!

**Consecuencia:**
El servidor acepta el token. Si el parser JSON procesa el input:
`{"user":"juan", ..., "expires":1738000000} <BASURA_PADDING> ,"role":"admin"`

Podría interpretar `role` como `admin` (sobrescribiendo el anterior) o simplemente aceptar el objeto extendido, logrando el atacante acceso administrativo.

---

## 5. Conclusión
*   **Logro:** Se modificó el contenido semántico del token (`role: admin`) y se generó una firma válida sin la clave.
*   **Causa:** Uso de `SHA256(clave || mensaje)` para autenticar.
*   **Solución:** Usar **HMAC** o JWTs estándares (que usan HMAC internamente).
