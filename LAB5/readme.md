# LABORATORIO 5: Ataque a Tokens API "Legacy"

**Vulnerabilidad:** Elevación de privilegios en APIs que usan firmas simples.

---

## 1. Crear Token Inseguro
Simulamos el backend de una API antigua.
```bash
echo -n "CLAVE_ULTRA_SECRETA_API" > key.txt
original_mac=$(printf "CLAVE_ULTRA_SECRETA_APIuser_id=15&role=user" | openssl dgst -sha256 | awk '{print $2}')
```
**Resumen para informe:** El servidor emite un token para un usuario con privilegios bajos (`role=user`). La firma se genera incorrectamente concatenando clave y datos, exponiendo el sistema.

## 2. Intercepción
El atacante obtiene el token en Base64.
```bash
echo -n "..." | base64 -d
```
**Resumen para informe:** Como atacantes, decodificamos el token y extraemos el mensaje y la firma. Nuestro objetivo es cambiar `role=user` a `role=admin` sin que el servidor lo note.

## 3. Ejecutar Ataque (HashPump)
Inyectamos `&role=admin`.
```bash
hashpump -s <mac> -d "user_id=15&role=user" -a "&role=admin" -k 23
```
**Resumen para informe:** Usamos la vulnerabilidad de extensión para generar una firma válida para el mensaje modificado. Hashpump nos entrega el hash correcto y el bloque de datos que incluye el padding necesario para que la matemática del hash cuadre.

## 4. Construir Token Falsificado
Reconstruimos el token Base64 con la salida de HashPump.
**Resumen para informe:** Empaquetamos nuestro exploit en el formato que espera la API. El token ahora contiene basura binaria (el padding) seguida de nuestro comando `role=admin`.

## 5. Validación
El servidor verifica la firma del nuevo token.
**Resumen para informe:** El servidor valida el token falsificado correctamente. Al procesar los parámetros, lee primero `role=user`, pero luego encuentra nuestro `role=admin` inyectado al final. Dependiendo de la lógica del parser, el último valor suele prevalecer, logrando así la elevación de privilegios exitosa.
