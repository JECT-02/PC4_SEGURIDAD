# RETO EXTRA: Cifrado Vigenère

**Desafío:** Recuperar la llave y el texto plano.

## Ejecución
`python solve_vigenere_kasiski.py`

**Resumen para informe (Metodología):**
1. **Análisis Kasiski:** Identificamos patrones de texto repetidos ("GMN", "NIG", etc.) en el criptograma. Las distancias entre estas repeticiones sugirieron que la longitud de la clave era un divisor común, apuntando fuertemente a 4 u 8 caracteres.
2. **Test de Friedman:** El Índice de Coincidencia calculado se acercó más al esperado para un texto en español cifrado con clave corta, reforzando la hipótesis derivada de Kasiski.
3. **Criptoanálisis:** Dividimos el texto en 8 columnas (cosets) y aplicamos análisis de frecuencia (Chi-cuadrado) comparando con la distribución de letras del idioma Español para cada columna individualmente.

**Resumen para informe (Resultados):**
El análisis estadístico recuperó la clave **"CIENCIAS"**. Con esta llave, el texto fue descifrado exitosamente, revelando un mensaje coherente sobre simulacros de ciberseguridad. Esto demuestra que los cifrados polialfabéticos clásicos como Vigenère son vulnerables al análisis estadístico moderno debido a que no ocultan las propiedades inherentes del lenguaje original.
