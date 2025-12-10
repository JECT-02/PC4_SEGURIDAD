# LABORATORIO 3: Ataque de Extensión de Longitud

**Vulnerabilidad:** Uso inseguro de HASH(clave || mensaje) como MAC.  
**Herramienta:** `hashpump`

---

## 1. Escenario del Laboratorio
### Paso 1: Configuración del Servidor (Víctima)
El servidor crea su secreto.
```bash
echo -n "CLAVE_SUPER_SECRETA_123" > clave.key
```
**Resumen para informe:** Simulamos un servidor seguro estableciendo una clave maestra que el atacante (nosotros) desconoce teóricamente.

### Paso 2: Mensaje Legítimo
```bash
echo -n "operacion=transferencia&cantidad=100" > mensaje.txt
```

### Paso 3: Servidor genera MAC inseguro
El servidor calcula `SHA256(clave || mensaje)` y lo publica.
```bash
mac_original=$(printf "CLAVE_SUPER_SECRETA_123operacion=transferencia&cantidad=100" | openssl dgst -sha256 | awk '{print $2}')
echo "MAC Original capturado: $mac_original"
```
**Resumen para informe:** El servidor emite una firma digital usando un método obsoleto (concatenación simple). Capturamos esta firma ("MAC Original") y el mensaje asociado, que son los únicos insumos que tenemos como atacantes.

---

## 2. El Ataque

### Paso 4: Ejecutar HashPump
El atacante quiere agregar `&cantidad=1000000` pero no tiene la clave para generar una nueva firma válida. Usa `hashpump` explotando la vulnerabilidad de Merkle-Damgård.

```bash
hashpump \
-s 4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17 \
-d "operacion=transferencia&cantidad=100" \
-a "&cantidad=1000000" \
-k 23
```
**Resumen para informe:** Ejecutamos el ataque. Hashpump toma el hash original (estado interno) y "continúa" el cálculo agregando nuestros datos maliciosos y el padding necesario. Logramos generar una firma válida sin jamás interactuar con la clave secreta.

### Paso 5: Resultado del Ataque
Obtenemos un **New Hash** y un **New Message** (con basura/padding binario en medio).

---

## 3. Verificación

### Paso 6: Servidor Valida
Simulamos que el servidor recibe nuestro mensaje manipulado.

```bash
# Simulación de verificación
printf "CLAVE_SUPER_SECRETA_123<CONTENIDO_DEL_NUEVO_MENSAJE>" | openssl dgst -sha256
```
**Resumen para informe:** El servidor procesa el mensaje manipulado junto con su clave secreta. Sorprendentemente, el hash coincide con el que forjamos. Esto demuestra que la construcción insegura permite a un atacante extender mensajes arbitrariamente, rompiendo la integridad del sistema.
