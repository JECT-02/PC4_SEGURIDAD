# LABORATORIO 2
**Demostración práctica del uso de HMAC (Hash-based Message Authentication Code)**

**Objetivo:**
● Mostrar cómo HMAC combina hash + clave secreta  
● Demostrar autenticación de mensajes  
● Mostrar que sin la clave correcta, la verificación falla  

---

## 1. Crear un mensaje real
Ejecuta el siguiente comando para simular una transacción sensible:
```bash
echo "Transaccion=100;Cuenta=987654;" > mensaje.txt
```
**Resumen para informe:** Definimos una transacción crítica. A diferencia del lab anterior, ahora nos preocupa no solo la integridad, sino también saber quién generó este mensaje.

## 2. Crear una clave secreta compartida
Esta clave debe ser conocida solo por las partes legítimas:
```bash
echo "ClaveSecretaSuperSegura123" > clave.key
```
**Resumen para informe:** Establecemos un secreto compartido. Este archivo simula la clave criptográfica que solo el emisor y el receptor legítimos poseen, base de la autenticación simétrica.

## 3. Generar el HMAC real
Calculamos el HMAC combinando el mensaje y la clave:
```bash
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```
**Resumen para informe:** Generamos un código de autenticación (HMAC). Este hash no depende solo del contenido, sino también de la clave secreta. Solo quien tenga la clave puede producir este valor específico.

## 4. Modificar un bit del mensaje y regenerar HMAC
Modificamos el archivo y recalculamos:
```bash
echo " " >> mensaje.txt
openssl dgst -sha256 -hmac "$(cat clave.key)" mensaje.txt
```
**Resumen para informe:** Al igual que en el hash simple, el HMAC cambia totalmente ante cualquier modificación del mensaje, garantizando la integridad de los datos.

## 5. Demostrar autenticación: usar clave incorrecta
Intentamos verificar con una clave incorrecta:
```bash
openssl dgst -sha256 -hmac "ClaveIncorrecta" mensaje.txt
```
**Resumen para informe:** Intentar generar el HMAC con una clave falsa produce un resultado erróneo. Esto demuestra la autenticidad: es matemáticamente imposible falsificar la firma sin conocer la clave secreta exacta.

## 6. Simular verificación del receptor
**Escenario:** Cliente envía mensaje y HMAC. Servidor recibe y recalcula.

**Generar HMAC del Cliente:**
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

**Resumen para informe:** El servidor valida el mensaje recalculando el HMAC con su propia copia de la clave. Al coincidir los valores, se confirman dos cosas: el mensaje no fue alterado (integridad) y fue generado por alguien que tenía la clave (autenticidad).
