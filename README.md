# TMDB Power BI — avance 01–12

## Abrir el proyecto en Windows

El repositorio trae los 13 archivos Parquet en `parquet/`. Solo necesitas Git y Power BI Desktop. El configurador prepara la ruta local y abre `TMDB.pbip`. No hace falta descargar los datos de OneDrive ni editar Power Query.

### Si todavía no tienes un clon

Cierra Power BI Desktop. Ejecuta estos comandos en PowerShell o en el Símbolo del sistema (CMD). El clon abrirá la rama `main` por defecto:

~~~powershell
git clone https://github.com/yoshiro-dev/TMDB-DataWarehouse-PowerBI.git
cd TMDB-DataWarehouse-PowerBI
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -RutaParquet .\parquet
~~~

Cuando abra el informe, pulsa **Inicio → Actualizar** para cargar las 13 tablas. Si tu versión de Desktop lo requiere, habilita el formato de proyectos PBIP y PBIR.

### Si ya tienes un clon

Cierra Power BI Desktop y guarda tus cambios en tu rama de trabajo. Si ese clon ya tiene una ruta local configurada, sigue los pasos de «Antes de publicar cambios» para restaurar el marcador antes de cambiar de rama. Desde la raíz del clon, ejecuta:

~~~powershell
git fetch origin
git switch main
git pull --ff-only origin main
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -RutaParquet .\parquet
~~~

Pulsa **Inicio → Actualizar** cuando se abra el informe. `-RutaParquet .\parquet` elige los 13 archivos que vienen en el clon. Si mueves el clon o restauras el marcador de la ruta, ejecuta de nuevo el configurador con Power BI cerrado.

### Si Power BI dice que falta `displayName`

El mensaje `Required properties are missing from object: displayName` aparece al abrir un clon con metadatos antiguos. La corrección agrega `metadata.displayName` a los archivos `.platform` del informe y del modelo semántico. Se confirmó la apertura en el equipo que mostraba el error.

Cierra Power BI Desktop y sigue los pasos de [Si ya tienes un clon](#si-ya-tienes-un-clon). La actualización del repositorio descarga ambos archivos corregidos. Después, ejecuta el configurador y pulsa **Inicio → Actualizar**.

## Contenido del informe

- 57 páginas: índice + 56 páginas numeradas. 01–12 tienen gráfica y filtros reales; 13–56 están reservadas, no son visualizadores terminados.
- Yoshiro 01–12; Marco 13–23; Paco 24–34; Filip 35–45; Gabo 46–56.
- 13 tablas, 12 relaciones. Los catálogos filtran sus puentes, y cada puente filtra hechos en ambos sentidos. No se materializa una unión que multiplique filas de hechos; los totales DAX se calculan en el contexto de películas. Los grupos multivalor se solapan y sus subtotales no deben sumarse para reconstruir el total. Fecha y película filtran hechos en un solo sentido.
- CAD × MCH = 7 × 8 = 56 combinaciones potenciales; no implica 56 gráficos finalizados.
- Fecha: cohorte por año o década de estreno; no es una serie de recaudación histórica ni una predicción. Fecha desconocida usa clave 0 y valores nulos.
- Importes en USD según la fuente, sin convertir ausencias a cero. ROI es una razón aproximada (formato %), no beneficio neto. Los datos sospechosos no fueron verificados externamente.
- El estilo y las estructuras PBIR/BIM se adaptaron de Chinook, pero no se incluyen datos ni medidas de Chinook.
- Si el refresco falla, comprueba la ruta local, los permisos y los tipos de los Parquet originales.

## Correccion v2
Se agrega definition/version.json con version PBIR 2.0.0, tomado de la plantilla original de Chinook. No se cambian las paginas, las medidas ni las fuentes de datos.

## Corrección v3 (26/11/2026)
Esta revisión partió del proyecto que abrió en Desktop. Para abrir la versión actual, sigue los pasos del inicio del README.
- Se agregan dos columnas descriptivas en Power Query: dim_fecha[periodo_estreno] y fact_peliculas[calidad_financiera]. Son atributos técnicos de filtro, no nuevas medidas de hechos ni dimensiones; CAD × MCH sigue siendo 7 × 8.
- Páginas 01–12: selector Período de estreno, histórico por defecto (1888–26/11/2026 inclusive). El corte corresponde al análisis, no al momento de captura de TMDB. Para ver fechas anteriores, posteriores o desconocidas, cambiar/limpiar selector y, si hace falta, limpiar intervalo.
- Selector Calidad financiera: las páginas 01, 02, 07, 08, 09 y 10 abren con «Sin alertas detectadas» y «Sin importes» seleccionados; el resto abre sin restricción de calidad. «Revisar» identifica casos a examinar: presupuesto <1000 o >=300 millones, ingresos <=100 o >=5 mil millones, ROI >=100 (10,000%), presupuesto igual a ingresos. Solo se evalúan valores no nulos. Las películas con importes parciales se conservan si no activan reglas. Umbrales heurísticos, no pruebas de falsedad; quitar selección para ver todos.
- ROI mediano en gráfica y tarjeta 08, promedio original en tooltip y como medida DAX disponible. Se sigue analizando el mismo campo roi_approx.
- Candidatas ML usa KEEPFILTERS y devuelve 0 si el contexto no contiene candidatas.
- No se cambia ninguna clave, relación, Parquet, página pendiente 13–56 ni asignación. Se mantienen 13 tablas, 12 relaciones, 57 páginas y 21 medidas DAX.
- Se actualizó un proyecto limpio con los 13 Parquet del clon y se verificaron sus conteos. También se probaron los botones de navegación en Power BI Desktop.

## Configuración portable de Parquet (v1.0.2)

Si prefieres usar los Parquet de OneDrive, sincroniza la carpeta compartida del Equipo Huitlacoche y marca `parquet` como «Mantener siempre en este dispositivo». Mantén un clon de Git por integrante.

La estructura recomendada no depende del nombre del usuario de Windows:

    salida_tmdb/
      parquet/                   # los 13 archivos .parquet
      TMDB-DataWarehouse-PowerBI/
        Configurar_Parquet.ps1
        TMDB.pbip
        TMDB.SemanticModel/

Si el clon no tiene una carpeta hermana `..\parquet`, el script también admite los Parquet incluidos en `parquet/` dentro del clon. Para abrir el proyecto:

1. Cierra Power BI Desktop.
2. Abre PowerShell en la raíz de tu clon.
3. Ejecuta:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1
~~~

El script resuelve la carpeta de datos respecto a su propia ubicación, comprueba los 13 nombres, abre cada archivo y valida las firmas Parquet `PAR1`. Luego modifica únicamente el parámetro `RutaParquet` de `model.bim` y abre `TMDB.pbip`.

Si los datos están en otra carpeta, indícala una sola vez. La ruta queda recordada en `.tmdb-local/RutaParquet.txt`, que Git ignora:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -RutaParquet "D:\Datos\TMDB\parquet"
~~~

Usa `-NoAbrir` para configurar sin iniciar Power BI. En Desktop, pulsa **Actualizar** y verifica las 13 tablas. Power Query necesita una ruta absoluta para `File.Contents`; por eso el script convierte la referencia local `..\parquet` en la ruta absoluta de cada computadora.

### Antes de publicar cambios

Power BI guarda el valor local del parámetro dentro de `model.bim`. Cuando termines de trabajar:

1. Cierra Power BI Desktop.
2. Restaura solo `RutaParquet` al marcador neutro:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -Restaurar
~~~

3. Comprueba que no quede una ruta personal y revisa el diff:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -VerificarRepositorio
git status
git diff
~~~

El modo `-Restaurar` conserva las demás ediciones del modelo. Ejecuta `-VerificarRepositorio` antes de hacer el commit para comprobar que `RutaParquet` usa el marcador neutro.

No uses `git add .`: agrega únicamente los archivos de tu tarea. El configurador no modifica los Parquet, no toca `MachineLearning` y no requiere reejecutar Pentaho ni PostgreSQL.
