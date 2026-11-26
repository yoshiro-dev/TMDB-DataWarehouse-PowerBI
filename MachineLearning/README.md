# TMDB Revenue Predictor — avance 01

Primera etapa: extracción y lectura de la fuente de conocimiento, sin entrenamiento.

## Ejecutar en Windows

Se requiere Node.js 18 o superior. Desde PowerShell, en la carpeta MachineLearning:

```powershell
npm run check
npm start
```

Abre http://localhost:3000. Para detener el servidor usa Ctrl+C.
No requiere npm install: por ahora utiliza módulos nativos de Node.js (fs, path y http). Express y TensorFlow.js se incorporarán al implementar el modelo.

## Fuente

`peliculas.csv` contiene los 9,808 registros reales de `TMDB_financial_sin_alertas.csv` (salida de la transformación 03 de Pentaho), proyectados a cinco campos y ordenados por año e ID. No se consultó PostgreSQL directamente ni se generaron registros simulados.

- `pelicula_id`: trazabilidad, no entrada del modelo.
- `budget`, `runtime`, `release_year`: entradas propuestas.
- `revenue`: objetivo supervisado, no entrada.

Los datos no presentan las alertas de la auditoría aplicada, lo que no certifica su exactitud. La muestra financiera es selectiva y no representa todo el catálogo. Los importes conservan las unidades monetarias reportadas por la fuente; no se verificó moneda ni inflación. Antes de entrenar se revisará la elegibilidad, la división cronológica y la disponibilidad de variables antes del estreno.

Fuente original: https://www.kaggle.com/datasets/asaniczka/tmdb-movies-dataset-2023-930k-movies

## Alcance

`app.js` lee y valida enteros positivos e IDs únicos, calcula un resumen y sirve el HTML y CSS. No crea tensores, no entrena, no predice ni calcula métricas de ML. La tabla muestra cinco filas reales de la fuente.

Rama propuesta: `feature/machine-learning`. No contiene credenciales, Parquet, ni cambios de Power BI.
