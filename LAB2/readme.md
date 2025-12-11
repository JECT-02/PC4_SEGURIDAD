# LABORATORIO 2
**Demostración práctica del uso de HMAC (Hash-based Message Authentication Code)**

## Objetivo
● Mostrar cómo HMAC combina hash + clave secreta
● Demostrar autenticación de mensajes
● Mostrar que sin la clave correcta, la verificación falla
● Comparar hash simple vs HMAC

**Usaremos SHA-256 como algoritmo base.**

---

## 1. Crear un mensaje real
```bash
echo "Transaccion=100;Cuenta=987654;" > mensaje.txt
```
**Resumen para informe:**
Se creó un archivo simulando una transacción financiera sensible, cuyo contenido requiere garantías tanto de integridad como de autenticidad.

## 2. Crear una clave secreta compartida
```bash
echo "ClaveSecretaSuperSegura123" > clave.key
```
**Esta clave debe ser conocida solo por las partes legítimas.**

**Resumen para informe:**
Se generó un archivo conteniendo una clave secreta ("clave.key"). Este secreto compartido es el componente fundamental que permitirá validar que un mensaje proviene de una fuente confiable.

## 3. Generar el HMAC real
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```

**Salida ejemplo:**
```
HMAC-SHA256(mensaje.txt)=
b79c68f6292f5dd1d2ff4f9cf19a0ef48d98ef63bd39e4df68cb02dbb8c229a1
```

**Resumen para informe:**
Se calculó el Código de Autenticación de Mensaje (HMAC) utilizando SHA-256 y la clave secreta. El resultado es una firma única ligada criptográficamente tanto al contenido del mensaje como a la clave.

## 4. Modificar un bit del mensaje y regenerar HMAC
```bash
echo " " >> mensaje.txt
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```
**Compare ambos HMAC: serán completamente diferentes, igual que en el hash.**

**Resumen para informe:**
Se modificó el mensaje original y se recalculó el HMAC. El cambio radical en la salida confirma que HMAC preserva la propiedad de integridad: cualquier alteración en los datos invalida la firma anterior.

## 5. Demostrar autenticación: usar clave incorrecta
```bash
openssl dgst -sha256 -hmac "ClaveIncorrecta" mensaje.txt
```

**Salida completamente distinta:**
```
HMAC-SHA256(mensaje.txt)=
3bb9a89378fa21934974338b4e48c74a6273494b9bfa81dc3698c81d95c651e1
```

**Interpretación:**
● A diferencia del hash simple, sin la clave secreta no puedes generar el HMAC correcto, aunque conozcas el mensaje completo.
● Esto demuestra la propiedad de autenticación.

**Resumen para informe:**
Se intentó generar la firma del mensaje usando una clave errónea. El resultado no coincide con la firma legítima, demostrando que es computacionalmente inviable falsificar la autenticidad del mensaje sin poseer la clave secreta correcta.

## 6. Simular verificación del receptor
**Supongamos:**
● Cliente envía → mensaje.txt + HMAC
● Servidor recalcula HMAC con la misma clave y compara

**Generar HMAC del cliente:**
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt > hmac_cliente.txt
```

**Servidor recalcula:**
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt > hmac_servidor.txt
```

**Comparación:**
```bash
diff hmac_cliente.txt hmac_servidor.txt
```

**Resultado:**
● Si no hay diferencias → autenticidad e integridad confirmadas.
● Si hay diferencias → mensaje manipulado o clave incorrecta.

**Resumen para informe:**
Se simuló el proceso de verificación donde el receptor recalcula el HMAC usando su copia de la clave secreta. La coincidencia exacta entre el HMAC recibido y el calculado localmente confirma de manera irrefutable la autenticidad del emisor y la integridad del mensaje.
