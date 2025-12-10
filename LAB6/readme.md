# LABORATORIO 6: Ataque a Tokens JSON

**Escenario:** API que firma JSONs con esquema inseguro.

---

## 1. Preparación (Víctima)
Token original JSON: `{"user":"juan","role":"user"}`
**Resumen para informe:** El servidor emite un token JSON legítimo protegiendo los campos con un hash SHA-256 simple. El usuario tiene rol limitado.

## 2. El Ataque
El atacante quiere inyectar `,"role":"admin"` al JSON.
```bash
hashpump -s <mac> -d '<json_original>' -a ',"role":"admin"' -k 28
```
**Resumen para informe:** Explotamos la firma insegura. Aunque JSON es un formato estructurado, el hash lo trata como bytes crudos. Hashpump nos permite agregar bytes al final manteniendo la validez de la firma.

## 3. Token Falsificado
El nuevo payload es: `{"user":"juan"...} <PADDING> ,"role":"admin"`
**Resumen para informe:** El resultado es un JSON "malformado" debido al padding binario en el medio, pero matemáticamente válido para la firma criptográfica.

## 4. Validación y Consecuencias
**Resumen para informe:** El servidor acepta la firma. La vulnerabilidad crítica aquí es doble:
1. **Criptográfica:** La firma admite extensión.
2. **De Aplicación:** El parser JSON del servidor es "permisivo", ignorando la basura binaria o aceptando claves duplicadas, permitiendo que `role:"admin"` sobrescriba al rol original. Esto demuestra que la seguridad depende tanto de la criptografía robusta (HMAC) como de la validación estricta de datos.
