# RETO EXTRA: Cifrado Vigenère

**Desafío:** Recuperar la llave y el texto plano del archivo `ciphertext.txt` utilizando el método de Kasiski (análisis de frecuencias y patrones repetidos).

## Archivos
*   `ciphertext.txt`: El mensaje cifrado.
*   `solve_vigenere_kasiski.py`: Script en Python que implementa el ataque.

## Instrucciones para Resolver
Ejecuta el script proporcionado:

```bash
python solve_vigenere_kasiski.py
```

El script genera un archivo `results.txt` con las posibles llaves y descifrados basados en las longitudes más probables detectadas.

---

## SOLUCIÓN (SPOILER)

**Método de Kasiski:**
El análisis de secuencias repetidas (como "GMN") reveló distancias que eran múltiplos de 4 y 8. Al probar longitud 8 y realizar análisis de frecuencia con el idioma Español:

*   **LLAVE RECUPERADA:** `CIENCIAS`
*   **TEXTO DESCIFRADO:**
    > "ESTE SIMULACRO CONSISTE EN UNA SERIE DE EJERCICIOS DONDE SE SIMULA UN CIBERATAQUE EN UN ENTORNO CONTROLADO A CADA ENTIDAD PARTICIPANTE Y SE OBSERVA LAS ACCIONES DE SU EQUIPO DE RESPUESTAS ANTE INCIDENTES DE SEGURIDAD DIGITAL EL OBJETIVO ES MEDIR Y FORTALECER LA CAPACIDAD DE REACCION DE LAS ENTIDADES PUBLICAS Y PRIVADAS ANTE POSIBLES CIBERATAQUES ASI COMO CONSOLIDAR LAS ACCIONES DE SEGURIDAD DIGITAL PARA LA PROTECCION DE LA CIUDADANIA FRENTE A LOS RIESGOS Y AMENAZAS EN EL ENTORNO DIGITAL EL SIMULACRO ES DIRIGIDO POR LA SECRETARIA DE GOBIERNO Y TRANSFORMACION DIGITAL DE LA PCM A TRAVES DEL CENTRO NACIONAL DE SEGURIDAD DIGITAL EN EL MARCO DEL QUINTO OBJETIVO PRIORITARIO DE LA POLITICA NACIONAL DE TRANSFORMACION DIGITAL GARANTIZAR LA SEGURIDAD Y CONFIANZA DIGITAL EN EL PAIS"
