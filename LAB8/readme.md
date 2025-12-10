# LABORATORIO 8: Versión Dockerizada (Server + Attacker)

Este laboratorio reproduce el ataque de extensión de longitud (Lab 7) en un entorno totalmente aislado y reproducible usando **Docker Compose**.

## Estructura
*   `docker-compose.yml`: Define los servicios `vulnserver` y `attacker`.
*   `server/`: Contiene la API vulnerable (Flask).
*   `attacker/`: Contiene el script de ataque y las herramientas (`hashpump`, `curl`).

## Requisitos Previo
*   Docker y Docker Compose instalados.

---

## Instrucciones de Ejecución

### 1. Construir e Iniciar Servicio
Desde la carpeta `LAB8/`:

```bash
docker compose build
docker compose up
```

### 2. Observar la Salida
Docker levantará ambos contenedores.
*   `vulnserver`: Iniciará Flask en el puerto 5000.
*   `attacker`: Esperará a que el servidor responda, obtendrá un token legítimo e iniciará un bucle de fuerza bruta de longitud de clave (key length brute-force) usando `hashpump`.

**Salida Esperada en el log de `attacker`:**
Verás intentos fallidos (`Trying keylen=...`) hasta llegar a la longitud correcta (21).
```
SUCCESS with keylen=21
Response: {"ok": true, "secret": "FLAG{ADMIN_ACCESS_GRANTED}"}
```

### 3. Inspección Manual (Opcional)
Si deseas entrar al contenedor del atacante para probar comandos manualmente:
```bash
docker compose exec attacker /bin/bash
```

### 4. Limpieza
Para detener y borrar todo:
```bash
docker compose down --rmi all --volumes
```

---

## Mitigación y Buenas Prácticas

Haber logrado explotar esta vulnerabilidad demuestra por qué **NUNCA** se debe implementar criptografía propia ("roll-your-own crypto") sin conocimiento profundo.

### 1. El Problema Raíz
La construcción `MAC = SHA256(clave || datos)` es vulnerable debido a la naturaleza iterativa de las funciones hash Merkle-Damgård (MD5, SHA1, SHA2, etc.), que permiten continuar el hash desde un estado previo.

### 2. Solución Correcta: HMAC
HMAC (Hash-based Message Authentication Code) está diseñado específicamente para prevenir esto mediante una estructura anidada:
`HMAC(K, m) = H((K ⊕ opad) || H((K ⊕ ipad) || m))`

**Implementación Segura en Python:**
```python
import hmac, hashlib

# En lugar de hashlib.sha256(key + data)
mac = hmac.new(SECRET_KEY, data, hashlib.sha256).hexdigest()
```

### 3. Otras Recomendaciones
*   **Usar Estándares:** Prefiere **JWT** (JSON Web Tokens) con algoritmos robustos (HS256, RS256). Las librerías de JWT ya implementan las firmas correctamente.
*   **Rotación de Claves:** Cambia las claves secretas periódicamente.
*   **No exponer detalles:** Los errores de verificación no deben revelar si la firma es inválida o si el token expiró (timing attacks, aunque es otro tema).
