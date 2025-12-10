# LABORATORIO 7: API Vulnerable End-to-End en Python

Laboratorio completo con API real en Flask.

---

## 2. Iniciar el Servidor
`python server.py`
**Resumen para informe:** Levantamos una API real programada en Python. Esta API implementa intencionalmente la verificación de firma insegura `hashlib.sha256(SECRET + data)` para fines educativos.

## 3. Obtener Token Legítimo
`./client_get_token.sh`
**Resumen para informe:** Actuamos como un usuario normal solicitando acceso. La API nos entrega un token válido con privilegios estándar. Guardamos este token para analizarlo.

## 4. Ejecutar el Ataque
`./attacker_forge.sh "<TOKEN>" 21`
**Resumen para informe:** El script automatizado realiza el proceso completo: decodifica el token, extrae la firma, usa hashpump para generar una extensión con `role=admin`, reconstruye el token en Base64 y lo envía de vuelta a la API.

## 5. Resultado
**Resumen para informe:** La API responde con `FLAG{ADMIN_ACCESS_GRANTED}`. Esto confirma que el ataque fue exitoso en un entorno real. Logramos engañar al servidor haciéndole creer que él mismo generó el token de administrador, cuando en realidad fue forjado por nosotros explotando la debilidad matemática del hash.
