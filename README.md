# TMDB Power BI — avance 01–12

Abrir `TMDB.pbip` con Power BI Desktop actualizado, con PBIP y PBIR habilitados si la versión lo requiere. Antes de abrir, configurar los Parquet locales con las instrucciones de la sección «Configuración portable de Parquet». No contiene datos incrustados ni credenciales.

- 57 páginas: índice + 56 páginas numeradas. 01–12 tienen gráfica y filtros reales; 13–56 están reservadas, no son visualizadores terminados.
- Yoshiro 01–12; Marco 13–23; Paco 24–34; Filip 35–45; Gabo 46–56.
- 13 tablas, 12 relaciones. Los catálogos filtran sus puentes, y cada puente filtra hechos en ambos sentidos. No se materializa una unión que multiplique filas de hechos; los totales DAX se calculan en el contexto de películas. Los grupos multivalor se solapan y sus subtotales no deben sumarse para reconstruir el total. Fecha y película filtran hechos en un solo sentido.
- CAD × MCH = 7 × 8 = 56 combinaciones potenciales; no implica 56 gráficos finalizados.
- Fecha: cohorte por año o década de estreno; no es una serie de recaudación histórica ni una predicción. Fecha desconocida usa clave 0 y valores nulos.
- Importes en USD según la fuente, sin convertir ausencias a cero. ROI es una razón aproximada (formato %), no beneficio neto. Los datos sospechosos no fueron verificados externamente.
- El estilo y las estructuras PBIR/BIM se adaptaron de Chinook, pero no se incluyen datos ni medidas de Chinook.
- Validación local: JSON, rutas relativas, proyecciones y relaciones comprobadas estáticamente. No se ha abierto en Power BI Desktop ni refrescado contra los Parquet reales (no adjuntos). Si el primer refresco falla, no reemplazar el dataset con datos simulados; comprobar ruta, permisos y tipos.

## Correccion v2
Se agrega definition/version.json con version PBIR 2.0.0, tomado de la plantilla original de Chinook. No se cambian las paginas, las medidas ni las fuentes de datos.

## Corrección v3 (26/11/2026)
Basada en el RAR del usuario que abrió en Desktop. Cerrar el informe anterior, extraer el ZIP en carpeta aparte, abrir TMDB.pbip y pulsar Actualizar (verificar RutaParquet si es necesario). No requiere reexportar ni modificar PostgreSQL. No se incluye caché local.
- Se agregan dos columnas descriptivas en Power Query: dim_fecha[periodo_estreno] y fact_peliculas[calidad_financiera]. Son atributos técnicos de filtro, no nuevas medidas de hechos ni dimensiones; CAD × MCH sigue siendo 7 × 8.
- Páginas 01–12: selector Período de estreno, histórico por defecto (1888–26/11/2026 inclusive). El corte corresponde al análisis, no al momento de captura de TMDB. Para ver fechas anteriores, posteriores o desconocidas, cambiar/limpiar selector y, si hace falta, limpiar intervalo.
- Selector Calidad financiera: las páginas 01, 02, 07, 08, 09 y 10 abren con «Sin alertas detectadas» y «Sin importes» seleccionados; el resto abre sin restricción de calidad. «Revisar» identifica casos a examinar: presupuesto <1000 o >=300 millones, ingresos <=100 o >=5 mil millones, ROI >=100 (10,000%), presupuesto igual a ingresos. Solo se evalúan valores no nulos. Las películas con importes parciales se conservan si no activan reglas. Umbrales heurísticos, no pruebas de falsedad; quitar selección para ver todos.
- ROI mediano en gráfica y tarjeta 08, promedio original en tooltip y como medida DAX disponible. Se sigue analizando el mismo campo roi_approx.
- Candidatas ML usa KEEPFILTERS y devuelve 0 si el contexto no contiene candidatas.
- No se cambia ninguna clave, relación, Parquet, página pendiente 13–56 ni asignación. Se mantienen 13 tablas, 12 relaciones, 57 páginas y 21 medidas DAX.
- Prueba pendiente: abrir y actualizar en Power BI Desktop, comprobar que los selectores abran con los valores indicados, limpiar filtros y comprobar los conteos globales originales; seleccionar Candidata ML = false y comprobar 0 candidatas.

## Configuración portable de Parquet (propuesta v1.0.2)

Cada integrante debe usar un clon propio de Git, no editar la misma carpeta .git sincronizada de OneDrive. La carpeta de datos puede proceder de OneDrive, pero los Parquet deben estar descargados localmente (Mantener siempre en este dispositivo).

Estructura recomendada (nombres de usuario y carpeta del clon pueden variar):

    salida_tmdb/
      parquet/                   # los 13 archivos .parquet
      TMDB-DataWarehouse-PowerBI/
        Configurar_Parquet.ps1
        TMDB.pbip
        TMDB.SemanticModel/

Con Power BI Desktop cerrado, abre PowerShell en la raíz del clon:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1
~~~

Esta política de ejecución se aplica únicamente al proceso iniciado. El script resuelve ..\parquet respecto a su propia ubicación, comprueba los 13 nombres esperados y tamaños no nulos, actualiza el único parámetro RutaParquet de model.bim y abre TMDB.pbip. Si los datos están en otra carpeta, especifica su ubicación local:

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Configurar_Parquet.ps1 -RutaParquet "D:\Datos\TMDB\parquet"
~~~

Usa -NoAbrir para configurar sin iniciar Power BI. En Desktop, pulsa Actualizar y verifica la carga de las 13 tablas. File.Contents recibe una ruta absoluta resuelta localmente; Power Query no interpreta ..\parquet directamente respecto al PBIP.

El script modifica model.bim en el clon local. No subas la ruta de tu equipo a GitHub: revisa git status y git diff antes de hacer commit; agrega exclusivamente las carpetas de las páginas asignadas. Si solo cambiaste la ruta y no tienes otras modificaciones del modelo, puedes restaurarla con Power BI cerrado mediante:

~~~powershell
git restore -- TMDB.SemanticModel/model.bim
~~~

Esto elimina la configuración local: vuelve a ejecutar el script para abrir el informe cuando lo necesites. Antes de cambiar de rama o fusionar cambios del modelo, cierra Power BI y preserva cualquier modificación semántica legítima por separado. No uses git add . para publicar visualizadores.

La configuración no altera ni descarga los Parquet y no comprueba su contenido interno. No requiere reejecutar Pentaho ni PostgreSQL. Pendiente de prueba con Power BI Desktop y los Parquet reales del equipo antes de integrar esta corrección.
