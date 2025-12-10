# LABORATORIO 4: Profundización en Length Extension Attack y Mitigación HMAC

En este laboratorio analizaremos técnicamente por qué ocurre el ataque de extensión de longitud y, lo más importante, **por qué HMAC lo soluciona matemáticamente**.

## Herramientas Necesarias

Para este laboratorio utilizaremos `sha256sum`, `openssl` y `hashpump`.

**Instalación:**
En Kali Linux suele estar disponible o ser fácil de instalar:
```bash
sudo apt install hashpump
```

*Alternativa:* Si tienes problemas con el paquete estándar, puedes compilar la herramienta desde este repositorio recomendado:
[https://github.com/iagox86/hash_extender](https://github.com/iagox86/hash_extender)

---

## 1. Escenario Real Vulnerable

Un servidor "legacy" o mal implementado usa la siguiente construcción para autenticar mensajes:
`MAC = SHA256(clave || mensaje)`

**Información que tiene el atacante:**
1.  **Mensaje original:** `operacion=transferencia&cantidad=100`
2.  **MAC publicado:** `4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17`
3.  **Algoritmo:** Sabe que es SHA-256.

**Lo que NO tiene:**
*   La `clave` secreta.

---

## 2. Ejecución del Ataque

El atacante quiere inyectar `&cantidad=1000000` al final.

Comando con **hashpump**:

```bash
hashpump \
-s 4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17 \
-d "operacion=transferencia&cantidad=100" \
-a "&cantidad=1000000" \
-k 16
```

*(Nota: `-k 16` es una suposición de la longitud de la clave. En un ataque real, esto se fuerza bruta probando 1, 2, 3... hasta que el servidor acepte el mensaje).*

**Salida Típica:**
*   **Nuevo MAC:** `c4ae908bd...` (Válido para el servidor)
*   **Nuevo Mensaje:** `operacion=transferencia&cantidad=100` + `PADDING` + `&cantidad=1000000`

---

## 3. Explicación Técnica del Ataque

¿Por qué funciona esto sin la clave?

1.  **Merkle-Damgård:** SHA-256 divide el mensaje en bloques de 512 bits.
2.  Procesa el primer bloque (que contiene la clave + parte del mensaje).
3.  El resultado es un **estado interno** de 256 bits.
4.  Ese estado se usa para procesar el siguiente bloque, y así sucesivamente.
5.  El **MAC final** que ves (`4e1ab...`) **ES** ese estado interno final.

El atacante toma ese estado final y le dice a su CPU: *"Continúa hasheando desde este estado, ignorando lo que pasó antes (la clave), y procesa estos nuevos datos (`&cantidad=1000000`)"*.

Como SHA-256 es determinista y su estado se filtra en la salida, **no se necesita la clave para continuar la cadena**.

---

## 4. Por qué HMAC mitiga completamente el ataque

HMAC **NO** es `sha256(key || message)`.

La construcción de HMAC es:
```math
HMAC = Hash( (Key ⊕ opad) || Hash( (Key ⊕ ipad) || mensaje ) )
```
*   `ipad` = 0x36 (repetido)
*   `opad` = 0x5c (repetido)

### Razón Técnica de la Inmunidad:

Para hacer una extensión de longitud en el hash externo, el atacante necesitaría conocer **el estado interno de la primera ronda de hash**.

1.  El hash interno es: `H1 = Hash( (Key ⊕ ipad) || mensaje )`
2.  El HMAC final es: `Hash( (Key ⊕ opad) || H1 )`

El atacante ve el HMAC final. Para extender el hash, necesitaría "continuar" desde el estado interno de ese hash final.
Pero ese hash final se calculó sobre `(Key ⊕ opad) || H1`.
Para extenderlo correctamente, el atacante necesitaría fingir que conoce `(Key ⊕ opad)`. Como **no tiene la clave**, no conoce el prefijo del bloque, y por tanto no puede calcular el padding correcto ni simular el estado interno *antes* de que se cerrara el hash.

**En resumen:**
HMAC "envuelve" el hash dos veces. Incluso si pudieras extender el hash interno (que no ves), el hash externo oculta ese resultado y usa nuevamente la clave. **Rompe la linealidad que explota el ataque de extensión.**
