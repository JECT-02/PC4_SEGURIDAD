# LABORATORIO 8: Versión Dockerizada

Entorno aislado y reproducible.

---

## 1. Construir e Iniciar
`docker compose up`
**Resumen para informe:** Desplegamos la infraestructura completa (Servidor + Atacante) usando contenedores. Esto simula un entorno de red real donde el atacante reside en una máquina distinta al servidor víctima.

## 2. Observar Salida (Ataque Automático)
El contenedor atacante prueba longitudes de clave hasta tener éxito.
**Resumen para informe:** El script atacante demuestra la realidad de estos ataques: aunque no conozcamos la longitud exacta de la clave, podemos probar variaciones rápidamente (fuerza bruta de longitud) hasta que el servidor acepte nuestra falsificación. En segundos, el log muestra el éxito del acceso administrativo.

## Mitigación (HMAC)
**Resumen para informe (Conclusión Final):**
La única defensa efectiva contra este ataque estructural no es ocultar la longitud de la clave, sino cambiar el algoritmo de firma.
La implementación de **HMAC (Hash-based Message Authentication Code)** resuelve el problema de raíz mediante su diseño de doble hash, haciendo matemáticamente imposible extender la firma sin conocer el secreto. La migración a estándares como JWT (correctamente firmados) es la recomendación profesional estándar.
