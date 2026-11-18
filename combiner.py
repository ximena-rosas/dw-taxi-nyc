#!/usr/bin/env python3
# Combiner: suma parcial en el mismo nodo del mapper, antes del shuffle
import sys

def emitir(llave, n, dist, dur, total):
    if llave is not None:
        print(f"{llave}\t{n},{dist:.4f},{dur:.4f},{total:.4f}")

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
