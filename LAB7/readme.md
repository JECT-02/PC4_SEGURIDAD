# LABORATORIO 7: API Vulnerable End-to-End en Python

Este laboratorio despliega una API local en Flask que utiliza un esquema de firma inseguro (`sha256(key || data)`), permitiendo un Ataque de Extensión de Longitud real.

## Estructura
*   `server.py`: API vulnerable.
*   `client_get_token.sh`: Obtiene un token legítimo.
*   `attacker_forge.sh`: Automatiza el ataque usando `hashpump`.
*   `requirements.txt`: Dependencias.

---

## Instrucciones de Ejecución

### 1. Preparación del Entorno
Se recomienda usar un entorno virtual de Python y tener instalado `hashpump` y `jq` en el sistema (Kali Linux).

```bash
# Instalar herramientas del sistema
sudo apt install -y hashpump jq

# Crear entorno virtual y activar
python3 -m venv venv
source venv/bin/activate

# Instalar dependencias python
pip install -r requirements.txt
```

### 2. Iniciar el Servidor
En una terminal, ejecuta:
```bash
python server.py
```
*(El servidor escuchará en `http://0.0.0.0:5000`)*.

### 3. Obtener Token Legítimo (Cliente)
En **otra terminal** (manten el servidor corriendo), obtén un token de usuario normal:

```bash
chmod +x client_get_token.sh
./client_get_token.sh
```

**Salida ejemplo:**
```json
{
  "token": "dXNlcl9pZD0xNSZyb2xlPXVzZXIuNmNjYWIwMzBj...",
  "data": "user_id=15&role=user"
}
```
Copia el valor del `"token"`.

### 4. Ejecutar el Ataque (Atacante)
Usa el script de ataque pasando el token capturado y una longitud estimada de clave.
*(Nota: La clave en `server.py` es `TEST_SECRET_KEY_12345`, que tiene longitud **21**).*

```bash
chmod +x attacker_forge.sh

# Reemplaza <TOKEN_B64> con el token que obtuviste
# Prueba con longitud 21 (o juega a adivinar con 20, 22, etc.)
./attacker_forge.sh "<TOKEN_B64>" 21
```

### 5. Resultado Esperado
Si el ataque funciona, verás la respuesta del servidor con la bandera de administrador:

```json
{
  "ok": true,
  "secret": "FLAG{ADMIN_ACCESS_GRANTED}"
}
```

### Notas Técnicas
*   El servidor valida tokens con `sha256(SECRET_KEY + data)`.
*   `hashpump` genera un nuevo hash válido para `SECRET_KEY + data + padding + &role=admin` sin conocer `SECRET_KEY`.
*   El servidor decodifica los datos (incluyendo el padding binario) y encuentra `role=admin` al final, otorgando acceso.
