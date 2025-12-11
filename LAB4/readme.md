# LABORATORIO 4
Usaremos sha256sum y la herramienta hashpump (típica para demostrar ataques de extensión de longitud).

**Instalación de hashpump:**
Linux:
```bash
sudo apt install hashpump
```

## Escenario real
Servidor usa:
`mac = sha256(key || message)`

Atacante conoce:
● el mensaje original,
● el hash resultante.
Pero NO conoce la clave.

**Mensaje conocido:**
`mensaje="operacion=transferencia&cantidad=100"`

**Hash publicado por el servidor (ejemplo):**
`4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17`

El atacante quiere modificarlo agregando:
`&cantidad=1000000`
sin conocer la clave.

**Resumen para informe:**
Se establece el contexto teórico del ataque: un escenario donde poseemos los datos públicos (mensaje y firma) y deseamos inyectar datos fraudulentos explotando la estructura algorítmica de SHA-256.

## Ejecutamos el ataque
```bash
hashpump \
-s 4e1ab0f3f06076a4787a7cefb7310b6a3f7bf978f40320bc0da36ba3f1e12c17 \
-d "operacion=transferencia&cantidad=100" \
-a "&cantidad=1000000" \
-k 16
```

**Explicación:**
● -s: hash original
● -d: datos originales
● -a: datos que el atacante quiere añadir
● -k: longitud estimada de la clave (se prueba varias)

**Salida típica:**
Nuevo MAC:
`c4ae908bd63e5fd621153df132764ebebd078d43a3d581123f0b89031db03bfb`
Nuevo mensaje:
`operacion=transferencia&cantidad=100%80...padding...&cantidad=1000000`

**Observaciones:**
1. hashpump genera un nuevo MAC válido sin conocer la clave.
2. El mensaje incluye padding interno del hash, lo cual el servidor acepta como válido.
3. El atacante creó un mensaje extendido sin romper SHA-256.
4. Esto solo ocurre porque se usa HASH(key || message), que es inseguro.

**Resumen para informe:**
Se demostró empíricamente cómo `hashpump` automatiza el cálculo del estado interno del hash y genera los bloques de relleno (padding) necesarios para extender el mensaje de forma válida, sin requerir acceso a la clave original.

## 3. Explicación técnica del ataque
SHA-256 procesa los datos en bloques de 512 bits y mantiene un estado interno de 256 bits.

Cuando se calcula:
`hash = sha256(key || message)`

El atacante conoce:
● hash: estado final interno
● message: los bytes exactos

Con esto puede:
● reconstruir bloques internos,
● aplicar el padding estándar,
● continuar hash con datos adicionales.

Esto funciona porque SHA-256 permite continuar hashing desde un estado arbitrario:
`state_final_original → continuar_hash(message_extra)`
Este es el corazón del ataque.

## 4. Demostración de por qué HMAC mitiga completamente el ataque
HMAC no es:
`sha256(key || message)`

HMAC usa la construcción:
`HMAC = H( (key ⊕ opad) || H((key ⊕ ipad) || message) )`

Donde:
● ipad = 0x36
● opad = 0x5c

El atacante no tiene los valores:
(key ⊕ ipad)
(key ⊕ opad)

Ambas operaciones convierten la clave secreta en valores completamente desconocidos, obligando a cualquiera a conocer la clave para iniciar o continuar un hash.

**Razón técnica:**
Para aplicar extensión de longitud se necesita:
● El estado interno del hash después de procesar (key ⊕ ipad)
● Y conocer el tamaño exacto de ese bloque

Sin conocer la clave, el atacante NO puede:
● reproducir el estado intermedio,
● continuar el hash,
● ni producir padding válido.

Por eso HMAC no permite ataque de extensión de longitud.

**Resumen para informe:**
Se concluye que HMAC es la solución definitiva. Su diseño anidado protege el estado interno intermedio, cortando la cadena causal que permite el ataque de extensión. Incluso si el algoritmo de hash subyacente es vulnerable a la extensión, la construcción HMAC permanece segura.
