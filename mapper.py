#!/usr/bin/env python3
# Mapper: lee el archivo crudo, valida cada viaje y emite el par origen-destino
import sys
from datetime import datetime

def a_fecha(texto):
    # Construccion directa en lugar de strptime, que es lento sobre millones de registros
    return datetime(int(texto[0:4]), int(texto[5:7]), int(texto[8:10]),
                    int(texto[11:13]), int(texto[14:16]), int(texto[17:19]))

for linea in sys.stdin:
    campos = linea.rstrip("\n").split(",")

    # Se descartan el encabezado y las lineas incompletas
    if len(campos) != 17 or campos[0] == "vendor_id":
        continue

    try:
        recogida  = a_fecha(campos[1])
        entrega   = a_fecha(campos[2])
        distancia = float(campos[4])
        total     = float(campos[14])
        origen    = campos[15].strip()
        destino   = campos[16].strip()
    except (ValueError, IndexError):
        continue

    duracion = (entrega - recogida).total_seconds() / 60.0

    # Reglas de calidad: las mismas definidas en el ETL del Corte 1
    if duracion <= 0 or duracion > 1440:      # viajes nulos o de mas de 24 horas
        continue
    if distancia <= 0 or total <= 0:          # distancias y montos invalidos
        continue
    if not origen.isdigit() or not destino.isdigit():
        continue

    # Llave: par de zonas. Valor: conteo y medidas del viaje
    print(f"{origen},{destino}\t1,{distancia},{duracion},{total}")
