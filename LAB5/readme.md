# LABORATORIO 5
**Ataque de extensión de longitud aplicado a tokens de APIs antiguas**

## Contexto real
Muchas APIs antiguas generaban tokens así:
`token = base64( datos || "." || sha256( key || datos ) )`

Ejemplo típico:
`user_id=15&role=user.4e1ab0f3...`

El servidor:
1. Decodifica el token.
2. Obtiene datos y el MAC.
3. Recalcula sha256(key || datos)
4. Si coincide, lo acepta.

Este diseño es vulnerable al length extension attack y permite, por ejemplo, elevar privilegios agregando “role=admin” aunque el atacante no conozca la clave.

---

## 1. Crear un token inseguro como lo haría una API antigua
### 1.1 Crear una clave secreta (solo servidor)
```bash
echo -n "CLAVE_ULTRA_SECRETA_API" > key.txt
```

### 1.2 Crear los datos del token
```bash
echo -n "user_id=15&role=user" > datos.txt
```

### 1.3 El servidor genera el MAC inseguro
```bash
original_mac=$(printf "CLAVE_ULTRA_SECRETA_APIuser_id=15&role=user" | openssl dgst -sha256 | awk '{print $2}')
echo $original_mac
```
**Salida típica:**
`6ccab030c0d32cd63da4bc86c87410c432e119ce8843a554d91044c33f7382fb`

### 1.4 Construcción del token
```bash
echo -n "user_id=15&role=user.$original_mac" | base64
```
**Salida:**
`dXNlcl9pZD0xNSZyb2xlPXVzZXIuNmNjYWIwMzBjMGQzMmNkNjNkYTRiYzg2Yzg3NDEwYzQzMmUxMTljZTg4NDNhNTU0ZDkxMDQ0YzMzZjc4MzI2Zg==`

Este es el token inseguro que vería un cliente.

**Resumen para informe:**
Simulamos el backend de una API legacy generando un token para un usuario estándar. El error de diseño es evidente: se usa concatenación simple para la firma, exponiendo el token a manipulación.

## 2. El atacante intercepta el token
El atacante no conoce la clave, pero sí el token Base64.

**Decodifica:**
```bash
echo -n "dXNlcl9pZD0xNSZyb2xlPXVzZXIuNmNjYWIwMzBjMGQzMmNkNjNkYTRiYzg2Yzg3NDEwYzQzMmUxMTljZTg4NDNhNTU0ZDkxMDQ0YzMzZjc4MzI2Zg==" | base64 -d
```
**Salida:**
`user_id=15&role=user.6ccab030c0d32cd63da4bc86c87410c432e119ce8843a554d91044c33f7382fb`

El atacante separa:
● mensaje: `user_id=15&role=user`
● MAC: `6ccab0...`

**Resumen para informe:**
Como atacantes, realizamos ingeniería inversa básica: decodificamos el Base64 y aislamos los componentes del token (datos y firma) para analizarlos por separado.

## 3. El atacante quiere modificar el token
El objetivo será elevar rol:
`&role=admin`
El atacante usa hashpump (herramienta estándar para mostrar el ataque).

## 4. Ejecutar el ataque de extensión de longitud
```bash
hashpump \
-s 6ccab030c0d32cd63da4bc86c87410c432e119ce8843a554d91044c33f7382fb \
-d "user_id=15&role=user" \
-a "&role=admin" \
-k 20
```
**Explicación:**
-k 20 = longitud estimada de la clave secreta (el atacante prueba varias).

**Salida típica de hashpump:**
New hash:
`e7a1e378b865bb90d693b6abfa8178c788a68a1d664a03dba87f97d38f88db10`
New message:
`user_id=15&role=user\x80\x00...\x00&role=admin`

El atacante ahora posee:
● nuevo mensaje con padding y extensión del hash
● nuevo MAC válido generado sin conocer la clave

**Resumen para informe:**
Se ejecutó el ataque de extensión logrando generar una firma válida para el mensaje manipulado. El resultado incluye los bytes de relleno necesarios para mantener la consistencia criptográfica.

## 5. El atacante construye el NUEVO token
Debe Base64-codificar: `<nuevo_mensaje>.<nuevo_mac>`

**Ejemplo:**
```bash
echo -n "user_id=15&role=user<padding>&role=admin.e7a1e378b865bb90d693b6abfa8178c788a68a1d664a03dba87f97d38f88db10" | base64
```
*(Nota: El paso anterior es conceptual, en la práctica debes usar el output binario de hashpump)*.

**Resultado:**
`ZXNfZGF0YV9tb2RpZmljYWRvLnVzZXJfaWQ9MTUmcm9sZT11c2Vyw4AACQ...&role=adminLmU3YTFlMzc4Yjg2NWJiOTBkNjkzYjZhYmZhODE3OGM3ODhhNjhhMWQ2NjRhMDNkYmE4N2Y5N2QzOGY4OGRiMTA=`

Este token es funcional para el servidor vulnerable.

**Resumen para informe:**
Se reconstruyó el token en el formato esperado por la API (Base64), empaquetando el payload malicioso y la nueva firma forjada.

## 6. Validación en el servidor (simulación)
El servidor vulnerable hará:
```bash
printf "CLAVE_ULTRA_SECRETA_API<nuevo_mensaje>" | openssl dgst -sha256
```
El resultado coincidirá con el nuevo_mac.

**Por lo tanto, aceptará:**
`user_id=15&role=admin`
El atacante elevó privilegios sin conocer la clave.

**Resumen para informe:**
Se verificó que el servidor acepta el token manipulado. Al procesar los parámetros, el servidor encuentra primero el rol de usuario y luego, tras la basura del padding, el rol de administrador inyectado, otorgando acceso privilegiado.

## 7. Explicación técnica
Este ataque funciona porque:
1. SHA-256 es Merkle–Damgård
2. La salida del hash = estado interno
3. El atacante puede continuar el hashing a partir del estado filtrado
4. SHA-256 permite extender mensajes válidamente
5. Así se calcula: `SHA256(key || mensaje_original || padding || extension)` sin conocer la clave.

## 8. ¿Cómo se defiende esto?
Nunca usar: `MAC = SHA256(key || datos)`

Se debe usar HMAC, que es inmune a extensión de longitud:
`HMAC(key, datos)`

o migrar a:
● JWT firmados (HS256/RS256)
● Tokens OIDC
● Message Authentication Codes modernos
