# Calculadora de aguinaldo (macOS)

Aplicación de línea de comandos escrita en Swift 6 para calcular el aguinaldo conforme a la legislación laboral de Costa Rica: se suman todos los salarios devengados entre el 1° de diciembre del año anterior y el 30 de noviembre del año en curso y se dividen entre 12. El programa genera recibos listos para imprimir por empleado, con encabezado de la empresa y un campo para la firma de RRHH al final.

## Requisitos
- macOS 12+ o Linux con Swift 6.x instalado (compila sin dependencias externas).

## Uso rápido
1. Ajusta o crea un archivo JSON con la información de la empresa, el período y la lista de empleados. Se incluye un ejemplo en `Samples/aguinaldo-ejemplo.json`.
2. Ejecuta el cálculo:
   ```bash
   swift run aguinaldo --input Samples/aguinaldo-ejemplo.json
   ```
   El comando imprimirá en consola el recibo de cada empleado.
3. Para generar un archivo de recibo por empleado (útil para impresión), indica un directorio de salida:
   ```bash
   swift run aguinaldo --input Samples/aguinaldo-ejemplo.json --output recibos
   ```
4. Para emitir el recibo de una persona específica, usa `--employee`:
   ```bash
   swift run aguinaldo --input Samples/aguinaldo-ejemplo.json --employee E001 --output recibos
   ```

### Formato de entrada (JSON)
```json
{
  "company": {
    "name": "Nombre de la empresa",
    "legalId": "Cédula jurídica",
    "address": "Dirección física",
    "phone": "Opcional",
    "email": "Opcional"
  },
  "period": {
    "start": "01/12/2023",
    "end": "30/11/2024"
  },
  "employees": [
    {
      "id": "E001",
      "name": "Nombre del colaborador",
      "position": "Puesto",
      "monthlyEarnings": [1200000, 1200000, ...],
      "notes": "Observaciones opcionales"
    }
  ]
}
```

Cada recibo detalla los ingresos mensuales considerados, el total devengado, el aguinaldo calculado (total / 12), el encabezado con los datos de la empresa y una línea final para la firma del área de RRHH.
