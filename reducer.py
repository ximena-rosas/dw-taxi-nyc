#!/usr/bin/env python3
# Reducer: consolida cada par de zonas y calcula las medidas finales
import sys

def emitir(llave, n, dist, dur, total):
    if llave is None or n == 0:
        return
    # Las medidas de razon se calculan como cociente de sumas y no como
    # promedio de cocientes (mismo criterio aplicado en los cubos del Corte 2)
    velocidad = dist / (dur / 60.0) if dur > 0 else 0.0
    print(f"{llave}\t{n},{dist/n:.2f},{dur/n:.2f},{total/n:.2f},{velocidad:.2f}")

llave_actual, n, dist, dur, total = None, 0, 0.0, 0.0, 0.0

for linea in sys.stdin:
    try:
        llave, valores = linea.rstrip("\n").split("\t", 1)
        c, d, t, m = valores.split(",")
        c, d, t, m = int(c), float(d), float(t), float(m)
    except ValueError:
        continue

    if llave != llave_actual:
        emitir(llave_actual, n, dist, dur, total)
        llave_actual, n, dist, dur, total = llave, 0, 0.0, 0.0, 0.0

    n += c; dist += d; dur += t; total += m

emitir(llave_actual, n, dist, dur, total)
