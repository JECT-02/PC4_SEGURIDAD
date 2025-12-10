# LABORATORIO 2
**Demostración práctica del uso de HMAC (Hash-based Message Authentication Code)**

**Objetivo:**
● Mostrar cómo HMAC combina hash + clave secreta  
● Demostrar autenticación de mensajes  
● Mostrar que sin la clave correcta, la verificación falla  
● Comparar hash simple vs HMAC  

**Algoritmo base:** SHA-256

---

## 1. Crear un mensaje real
Ejecuta el siguiente comando para simular una transacción sensible:
```bash
echo "Transaccion=100;Cuenta=987654;" > mensaje.txt
```

## 2. Crear una clave secreta compartida
Esta clave debe ser conocida solo por las partes legítimas (emisor y receptor):
```bash
echo "ClaveSecretaSuperSegura123" > clave.key
```

## 3. Generar el HMAC real
Calculamos el HMAC combinando el mensaje y la clave:
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```
**Salida ejemplo:**
```
HMAC-SHA256(mensaje.txt)=
b79c68f6292f5dd1d2ff4f9cf19a0ef48d98ef63bd39e4df68cb02dbb8c229a1
```

## 4. Modificar un bit del mensaje y regenerar HMAC
Modificamos el archivo (ej. agregando un espacio) y recalculamos para ver la sensibilidad:
```bash
echo " " >> mensaje.txt
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```
**Resultado:** Compare ambos HMAC. Serán completamente diferentes, igual que sucede con los hashes simples.

## 5. Demostrar autenticación: usar clave incorrecta
Ahora intentamos verificar con una clave incorrecta:
```bash
openssl dgst -sha256 -hmac "ClaveIncorrecta" mensaje.txt
```
**Salida completamente distinta:**
```
HMAC-SHA256(mensaje.txt)=
3bb9a89378fa21934974338b4e48c74a6273494b9bfa81dc3698c81d95c651e1
```

**Interpretación:**
● A diferencia del hash simple, sin la clave secreta **no puedes generar el HMAC correcto**, aunque conozcas el mensaje completo.
● Esto demuestra la propiedad de **autenticación**.

## 6. Simular verificación del receptor
**Escenario:**
● Cliente envía → `mensaje.txt` + su HMAC.
● Servidor recibe, recalcula HMAC con su copia de la clave y compara.

**Generar HMAC del Cliente:**
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt > hmac_cliente.txt
```

**Servidor recalcula:**
```bash
# El servidor usa su propia copia de la clave y el mensaje recibido
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt > hmac_servidor.txt
```

**Comparación:**
```bash
diff hmac_cliente.txt hmac_servidor.txt
```

**Resultado:**
● Si no imprime nada (y código de salida es 0) → **Autenticidad e Integridad confirmadas.**
● Si hay diferencias → El mensaje fue manipulado o la clave es incorrecta.
