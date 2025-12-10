# LABORATORIO 4: Explicación Técnica (Ataque vs HMAC)

Este laboratorio es teórico-práctico para entender la mitigación.

---

## 1. Escenario Real Vulnerable
Repasamos el escenario donde `MAC = SHA256(clave || mensaje)`.

**Resumen para informe:** Confirmamos que en sistemas "legacy", el atacante posee todo lo necesario (mensaje + hash) para reconstruir el estado interno de la función de hash, excepto la longitud de la clave, la cual es trivial de adivinar por fuerza bruta.

## 2. Ejecución del Ataque (Demostración)
```bash
hashpump -s <hash> -d <data> -a <extension> -k <keylen>
```
**Resumen para informe:** La herramienta demuestra que la función SHA-256 no "cierra" su estado hasta que termina el input. Si el output se entrega directo al usuario, este puede usarlo como "semilla" para seguir calculando hashes válidos.

## 3. Por qué HMAC mitiga el ataque

**Construcción HMAC:**
`HMAC = Hash( (Key ⊕ opad) || Hash( (Key ⊕ ipad) || mensaje ) )`

**Resumen para informe (Mitigación):**
HMAC introduce dos capas de hashing con modificaciones de la clave (ipad/opad).
1. **Capa Interna:** El atacante no ve el resultado de `Hash((Key ⊕ ipad) || mensaje)`, por lo que no puede extenderlo.
2. **Capa Externa:** El atacante ve el resultado final, pero este hash es sobre `(Key ⊕ opad) || Resultado_Interno`. Para extender este hash, necesitaría saber `(Key ⊕ opad)`, lo cual es imposible sin la clave.
**Conclusión:** HMAC rompe la cadena de confianza que necesita el ataque de extensión, haciendo el sistema robusto incluso si se usan funciones de hash vulnerables a extensión como SHA-256.
