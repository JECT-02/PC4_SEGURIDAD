# LABORATORIO 3
**¿Qué es el ataque de extensión de longitud?**

Afecta a funciones hash basadas en Merkle–Damgård, como:
● MD5
● SHA-1
● SHA-256
● SHA-512

El ataque funciona cuando se usa HASH(clave || mensaje) como MAC (antigua práctica insegura).
El atacante no conoce la clave, pero puede hacer:
`HASH(clave || mensaje || datos_extra)`
y producir un nuevo MAC válido para un mensaje extendido, sin conocer la clave.

Esto permite manipular datos en sistemas antiguos que usaban:
`mac = sha256(key || message)`

El laboratorio es seguro, controlado y permite comprender por qué esta construcción es insegura y por qué debe reemplazarse por HMAC.

## Demostración del ataque de extensión de longitud (Length Extension Attack)
**Caso inseguro:** SHA-256(key || message)

**Herramientas necesarias:**
● openssl
● hashpump (herramienta estándar para demostrar ataques de extensión)

**Instalación:**
```bash
sudo apt install hashpump
```

---

## 1. Escenario del laboratorio
Supongamos un servidor que genera autenticación así:
`MAC = SHA256(clave_secreta || mensaje)`

El atacante no conoce la clave, pero sí:
● el mensaje transmitido
● el MAC transmitido

Esto ocurre en sistemas antiguos (APIs legacy, cookies inseguras, tokens viejos).

**Resumen para informe:**
Se plantea un escenario vulnerable donde un sistema utiliza una construcción criptográfica obsoleta (concatenación simple de clave y mensaje) para autenticar transacciones, exponiéndolo a ataques de extensión.

## 2. Crear clave secreta (solo el servidor la conoce)
```bash
echo -n "CLAVE_SUPER_SECRETA_123" > clave.key
```
**Resumen para informe:**
Se estableció una clave secreta en el servidor, desconocida para cualquier atacante externo.

## 3. Crear mensaje legítimo
```bash
echo -n "operacion=transferencia&cantidad=100" > mensaje.txt
```
**Resumen para informe:**
Se generó una transacción legítima que será enviada por la red.

## 4. Servidor genera MAC inseguro
```bash
mac_original=$(printf "CLAVE_SUPER_SECRETA_123operacion=transferencia&cantidad=100" | openssl dgst -sha256 | awk '{print $2}')
echo $mac_original
```

**Ejemplo de salida:**
`4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17`

Este MAC viaja por la red junto al mensaje. El atacante lo captura.

**Resumen para informe:**
El servidor firmó el mensaje usando el método inseguro. Como atacantes, interceptamos este hash ("MAC original") y el mensaje, obteniendo los insumos necesarios para el ataque.

## 5. El atacante desea modificar el mensaje
El atacante no conoce la clave, pero quiere añadir:
`&cantidad=1000000`
sin invalidar el MAC.

Esto es justo lo que el ataque permite.

**Resumen para informe:**
Se definió el objetivo del ataque: agregar un parámetro fraudulento al mensaje original sin romper la validez de la firma criptográfica, logrando que el servidor acepte la transacción modificada.

## 6. Atacante prepara el ataque de extensión
Ejecuta:
```bash
hashpump \
-s 4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17 \
-d "operacion=transferencia&cantidad=100" \
-a "&cantidad=1000000" \
-k 22
```

**Explicación de parámetros:**
● -s → hash original
● -d → mensaje original
● -a → datos a añadir
● -k → longitud estimada de la clave secreta (el atacante prueba varias)

**Resumen para informe:**
Se utilizó la herramienta `hashpump` para explotar el estado interno del algoritmo SHA-256. Utilizando el hash original como punto de partida, se calculó la extensión necesaria para agregar los datos maliciosos.

## 7. Salida del ataque (real)
**Ejemplo típico:**
New hash:
`c4ae908bd63e5fd621153df132764ebebd078d43a3d581123f0b89031db03bfb`
New message:
`operacion=transferencia&cantidad=100%80%00%00%00%00%00%00(...)&cantidad=1000000`

**Resultado:**
● El atacante obtuvo un MAC válido sin conocer la clave.
● Se generó un mensaje extendido válido para el servidor, aunque contiene padding interno del hash.

Esto demuestra el ataque.

**Resumen para informe:**
La herramienta generó exitosamente una nueva firma válida y el payload correspondiente (mensaje original + padding + extensión). Esto confirma que es posible falsificar firmas en este esquema sin conocer la clave.

## 8. Verificación del servidor (simulación)
El servidor recibe:
1. mensaje_modificado.txt
2. mac_nuevo

Servidor ejecuta:
```bash
printf "CLAVE_SUPER_SECRETA_123<mensaje_modificado>" | openssl dgst -sha256
```
El hash coincide con el del atacante.

**Por lo tanto:**
El servidor acepta un mensaje modificado por un atacante SIN que el atacante conozca la clave secreta.
Este es el ataque exitoso.

**Resumen para informe:**
Se simuló la validación en el servidor. Al procesar el mensaje manipulado junto con la clave secreta real, el servidor obtuvo el mismo hash que forjó el atacante, aceptando la transacción fraudulenta como válida.

## 9. Explicación técnica del porqué funciona
SHA-256 es un hash Merkle–Damgård:
● procesa bloques de 512 bits,
● mantiene un estado interno de 256 bits después de procesar clave || mensaje,
● ese estado se filtra directamente como el hash final,
● el atacante puede usar ese estado como punto inicial,
● agregar padding válido,
● continuar hasheando más datos.

Por eso se puede crear: `SHA256(clave || mensaje || extensión)` sin conocer la clave.

## 10. ¿Qué demuestra este laboratorio?
1. Que NO se debe usar `MAC = SHA256(clave || mensaje)`
2. Que el atacante puede forjar mensajes válidos.
3. Que SHA-256 no está roto; el problema está en USO incorrecto del hash para autenticación.
4. Que sistemas antiguos aún son vulnerables.

## 11. ¿Cómo prevenirlo?
Con HMAC, que usa:
`HMAC = H( (key ⊕ opad) || H( (key ⊕ ipad) || mensaje ) )`

Esto:
● oculta la clave,
● oculta los valores internos,
● impide extensión de longitud,
● fuerza dos capas de hashing.

HMAC elimina la vulnerabilidad al 100%.
