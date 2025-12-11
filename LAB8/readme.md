# LABORATORIO 8
**Versión Dockerizada (server + attacker containers, paso a paso)**

**Objetivo:** montar el laboratorio anterior dentro de Docker Compose para reproducir el entorno aislado: un contenedor vulnserver (Flask) y otro attacker que ejecuta hashpump y prueba el ataque.

## Ventajas
● Totalmente aislado, reproducible.
● No afecta el host.
● Fácil destrucción con docker compose down.

## Requisitos
● Docker & Docker Compose v2 (or docker compose)
● Git (opcional)

## Estructura de archivos (directorio lab-docker/)
● docker-compose.yml
● server/
  o Dockerfile
  o server.py (igual que antes)
  o requirements.txt
● attacker/
  o Dockerfile
  o attack.sh (adaptado)

---

## Construir y ejecutar

### 1. Desde el directorio lab-docker/:
### 1. Desde el directorio lab-docker/:
```bash
# NOTA: Si obtienes "permission denied", usa sudo
sudo docker compose build
sudo docker compose up
```
*(Alternativamente, si tu usuario ya está en el grupo docker y reiniciaste sesión, no necesitas sudo).*

**Resumen para informe:**
Se desplegó la infraestructura completa del laboratorio utilizando contenedores Docker, garantizando un entorno estéril y reproducible idéntico para el servidor víctima y la máquina atacante.

### 2. Observa la salida del servicio attacker.
Verás intentos para diferentes keylen. Si algún keylen funciona, la respuesta incluirá `FLAG{ADMIN_ACCESS_GRANTED}` (tal como el servidor devuelve).

**Resumen para informe:**
Se monitoreó la ejecución automática del ataque. El contenedor atacante realizó un ataque de fuerza bruta sobre la longitud de la clave (Key Length Brute-Force), probando secuencialmente hasta encontrar el valor que permitía generar una firma válida aceptada por el servidor.

### 3. Para entrar al contenedor attacker manualmente:
```bash
docker compose exec attacker /bin/bash
```

### 4. Para detener y limpiar:
```bash
docker compose down --rmi all --volumes
```

---

## Notas de seguridad del laboratorio Docker
● La red labnet es interna a Docker; no expongas a Internet.
● No uses claves reales.
● El contenedor attacker arranca y ejecuta el script automáticamente; el ENTRYPOINT deja una shell al final para inspección.
● Limpia imágenes y contenedores cuando termines.

---

## Mitigación y buenas prácticas (obligatorio)
Tras ejecutar y observar éxito del ataque, aplica estas contramedidas:

1. Reemplazar `MAC = SHA256(key || data)` por **HMAC-SHA256**:
   ```python
   import hmac, hashlib
   mac = hmac.new(KEY, data, hashlib.sha256).hexdigest()
   ```
   **HMAC mitiga extensión de longitud.**

2. Usar librerías estándar para tokens: JWT (con RS256 o ES256 para firmas asimétricas) o librerías probadas que realizan validaciones correctas.
3. Evitar roll-your-own crypto. Usa estándares y revisa las librerías.
4. Añadir expiración y nonce a tokens para limitar ventana de ataque.
5. Monitoreo y validación: registrar intentos y analizar patrones sospechosos.

## Conclusión breve
● Los laboratorios muestran de forma práctica la vulnerabilidad de usar HASH(key || data) como MAC.
● En ambos entornos (local Python y Docker) puedes observar elevación de privilegios por forging del token con hashpump.
● Solución: migrar a HMAC o mecanismos de firma correctos.
