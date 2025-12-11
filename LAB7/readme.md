# LABORATORIO 7 API vulnerable en Python (end-to-end, local)

**Objetivo:** desplegar una API simple que genera tokens inseguros `token = base64(data + "." + sha256(key || data))`, capturar un token, forjar un token extendido con hashpump y demostrar acceso no autorizado.

## Resumen del flujo
1. API (Flask) crea tokens inseguros y valida tokens comparando sha256(key || data).
2. Cliente obtiene token normal (role=user).
3. Atacante usa hashpump para producir `data' = data || padding || extension` y nuevo MAC.
4. Atacante llama la API con token forjado (role=admin) y la API lo acepta.

## Requisitos
● Python 3.8+
● pip
● hashpump (instalable en Debian/Ubuntu con `sudo apt install hashpump` o `pip install hashpumpy`)
● curl (opcional)

**Ejecuta todo en una VM/entorno aislado.**

## Estructura de archivos (directorio lab-python/)
● `server.py` — API vulnerable (Flask)
● `client_get_token.sh` — script para obtener token legítimo
● `attacker_forge.sh` — script que usa hashpump para forjar token
● `requirements.txt`

*(Nota: Los archivos deben ser creados con el contenido provisto en los bloques de código)*.

---

## Pasos para ejecutar (en el directorio lab-python/)

### 1. Crear entorno y deps:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
sudo apt install -y hashpump jq # hashpump for attack, jq for pretty JSON (Ubuntu/Debian)
```

**Resumen para informe:**
Se preparó el entorno de ejecución aislando las dependencias de Python e instalando las herramientas de sistema necesarias (`hashpump`, `jq`) para realizar y validar el ataque.

### 2. Iniciar servidor:
```bash
python server.py
```
**Servidor escucha en http://0.0.0.0:5000.**

**Resumen para informe:**
Se desplegó la API vulnerable. El código del servidor implementa deliberadamente una verificación de firma insegura para fines demostrativos.

### 3. Obtener token legítimo:
```bash
./client_get_token.sh
```
**Salida ejemplo:**
```json
{
"token": "dXNlcl9pZD0xNSZyb2xlPXVzZXIuNmNjYWIwMzBj...",
"data": "user_id=15&role=user"
}
```

**Resumen para informe:**
Se simuló la interacción de un usuario legítimo obteniendo sus credenciales. La API entregó un token válido con privilegios restringidos (`role=user`).

### 4. Ejecutar el ataque (intenta KEYLEN = 16..24)
```bash
TOKEN=$(curl -s http://127.0.0.1:5000/get_token | jq -r .token)
./attacker_forge.sh "$TOKEN" 20
```
*(Nota: Prueba con 20, 21, etc hasta que funcione)*.

**Salida esperada (cuando keylen correcto o suficientemente close):**
● `attacker_forge.sh` mostrará New MAC, the forged token, y la respuesta del endpoint `/resource` que debe devolver el `FLAG{ADMIN_ACCESS_GRANTED}` si el token fue aceptado.

**Si no funciona con una keylen, prueba otras longitudes (10..32) hasta que hashpump genera token que server acepta.**

**Resumen para informe:**
Se ejecutó el script de explotación automatizado. Este script descompone el token legítimo y utiliza la vulnerabilidad de extensión para inyectar `role=admin`. Al enviar el token falsificado de vuelta a la API, esta respondió otorgando acceso administrativo, confirmando el éxito del ataque.

---

## Observaciones
● El servidor no usa HMAC; por eso el atacante puede continuar desde estado interno.
● hashpump reconstruye el padding y el estado interno dados hash y message.
● En producción, un servidor del mundo real expuesto podría permitir elevación de privilegios si hace uso de este esquema.

## Mitigación inmediata:
usar HMAC-SHA256 con clave secreta (no sha256(key||data)), o migrar a JWT firmados correctamente (HS256/RS256) o a sistemas con firma asimétrica.
