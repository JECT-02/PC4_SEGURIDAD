# LABORATORIO 6

## 1. Escenario real
Un API antiguo devuelve tokens del tipo:
```json
{
"user": "juan",
"role": "user",
"expires": 1738000000
}
```
El token enviado al cliente es:
`token = BASE64( payload_json ) . SHA256( clave || payload_json )`

Un diseño inseguro, porque SHA256(clave || msg) permite Length Extension Attack.
El atacante no conoce la clave, pero sí:
1. el payload en base64,
2. el hash enviado por el servidor.
Esto basta para explotar el sistema.

**Resumen para informe:**
Analizamos un esquema de tokenización basado en JSON donde la firma se realiza de manera insegura. El token consta del payload codificado en Base64 concatenado con su firma hash.

## 2. Crear clave secreta (solo del servidor)
```bash
echo -n "CLAVE_SÚPER_SECRETA_DEL_API" > api.key
```
**Resumen para informe:**
Se definió "CLAVE_SÚPER_SECRETA_DEL_API" como el secreto del servidor.

## 3. Crear payload del token
```bash
echo -n '{"user":"juan","role":"user","expires":1738000000}' > payload.json
```
**Generar la parte base64:**
```bash
base64 payload.json > payload.b64
cat payload.b64
```
**Ejemplo:**
`eyJ1c2VyIjoianVhbiIsInJvbGUiOiJ1c2VyIiwiZXhwaXJlcyI6MTczODAwMDAwMH0=`

**Resumen para informe:**
Se creó el payload JSON para un usuario estándar y se codificó en Base64, simulando el primer componente del token.

## 4. El servidor genera el hash inseguro (MAC)
```bash
mac=$(printf "CLAVE_SÚPER_SECRETA_DEL_API$(cat payload.json)" | openssl dgst -sha256 | awk '{print $2}')
echo $mac
```
**Ejemplo:**
`7df0faeec84a4f71c76db548a3d909cb0f78c03199e15ef4b88d132fb9258769`

El token entregado al usuario es:
`TOKEN = payload.b64 . mac`
Que el atacante puede interceptar.

**Resumen para informe:**
El servidor firmó el payload JSON inseguramente. El token completo (Base64 + Hash) es entregado al cliente, quedando expuesto a intercepción.

## 5. El atacante quiere escalar privilegios
**Modificación maliciosa deseada:**
`,"role":"admin"`

Pero el atacante no conoce la clave secreta del API.
Sin embargo, esta API insegura sí es vulnerable.

## 6. Ejecutar el ataque de extensión
Usamos hashpump:
```bash
hashpump \
-s 7df0faeec84a4f71c76db548a3d909cb0f78c03199e15ef4b88d132fb9258769 \
-d '{"user":"juan","role":"user","expires":1738000000}' \
-a ',"role":"admin"' \
-k 28
```

**Explicación:**
● -s → hash original
● -d → JSON conocido
● -a → datos que desea agregar
● -k → longitud estimada de clave

**Salida típica:**
New hash:
`c41fa603b49ea682e62974b1389fb10b10d9433741c59b03b26dfd5a89778b10`
New data:
`{"user":"juan","role":"user","expires":1738000000}%80...padding...,"role":"admin"`

Este output contiene:
● nuevo MAC válido,
● payload extendido,
● padding interno SHA-256,
● mensaje malicioso agregado

**Resumen para informe:**
Se ejecutó hashpump para inyectar una propiedad JSON adicional. A pesar de que esto introduce basura binaria en la cadena JSON, la firma generada es criptográficamente válida para la nueva estructura extendida.

## 7. Atacante reconstruye el nuevo token
1. **Codifica el nuevo payload en base64:**
   ```bash
   echo -n '<nuevo_payload>' | base64 > payload_mod.b64
   ```
2. **Une los campos:**
   `TOKEN_MODIFICADO = payload_mod.b64 . nuevo_hash`

Este token es totalmente válido para el servidor.

**Resumen para informe:**
Se ensambló el token fraudulento combinando el nuevo payload (ahora incluyendo el rol admin y el padding) en Base64 con la nueva firma generada.

## 8. Verificación del servidor (simulada)
El servidor hace:
`SHA256( CLAVE_SÚPER_SECRETA_DEL_API || payload_modificado )`

y obtiene:
`c41fa603b49ea682e62974b1389fb10b10d9433741c59b03b26dfd5a89778b10`

El mismo valor producido por el atacante.
**Resultado:** el servidor acepta el token modificado.

## 9. ¿Qué logró el atacante?
● Cambió "role": "user" → "role": "admin"
● No tocó la parte original del JSON
● No conocía la clave secreta
● No rompió SHA-256
● Aprovechó la mala construcción del token

**Resumen para informe (Conclusión):**
El ataque tuvo éxito explotando la permisividad de los parsers JSON ante datos extraños y la debilidad criptográfica del esquema de firma. Se logró escalar privilegios sin comprometer la clave secreta.
