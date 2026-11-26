# Configura el origen local de los 13 Parquet. Ejecutar con Power BI cerrado.
[CmdletBinding()]
param(
    [string]$RutaParquet = (Join-Path $PSScriptRoot '..\parquet'),
    [switch]$NoAbrir
)

$ErrorActionPreference = 'Stop'
$modelPath = Join-Path $PSScriptRoot 'TMDB.SemanticModel\model.bim'
$projectPath = Join-Path $PSScriptRoot 'TMDB.pbip'

if (-not (Test-Path -LiteralPath $modelPath -PathType Leaf) -or
    -not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
    throw 'No se encontro el proyecto TMDB. Ejecuta el script desde su clon completo.'
}

if (Get-Process -Name PBIDesktop -ErrorAction SilentlyContinue) {
    throw 'Cierra Power BI Desktop antes de configurar la ruta.'
}

if (-not (Test-Path -LiteralPath $RutaParquet -PathType Container)) {
    throw "No se encontro la carpeta: $RutaParquet. Sincroniza o descarga los Parquet, o usa -RutaParquet con su ubicacion local."
}

$folder = (Resolve-Path -LiteralPath $RutaParquet).ProviderPath
$folder = $folder.TrimEnd('\')
$expected = @(
    'dim_fecha', 'dim_pelicula', 'dim_genero',
    'dim_productora', 'dim_pais', 'dim_idioma', 'dim_palabra_clave',
    'fact_peliculas', 'bridge_pelicula_genero', 'bridge_pelicula_productora',
    'bridge_pelicula_pais', 'bridge_pelicula_idioma', 'bridge_pelicula_palabra_clave'
)

$missing = @(
    foreach ($table in $expected) {
        $path = Join-Path $folder "$table.parquet"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            "$table.parquet"
        } elseif ((Get-Item -LiteralPath $path).Length -le 0) {
            "$table.parquet (vacio)"
        }
    }
)
if ($missing.Count -gt 0) {
    throw ("Faltan archivos o estan vacios: " + ($missing -join ', '))
}

# Modificar exclusivamente el literal JSON de RutaParquet, sin reformatear BIM.
$utf8 = New-Object System.Text.UTF8Encoding($false)
$raw = [System.IO.File]::ReadAllText($modelPath, $utf8)
$model = ConvertFrom-Json -InputObject $raw
$params = @($model.model.expressions | Where-Object { $_.name -eq 'RutaParquet' -and $_.kind -eq 'm' })
if ($params.Count -ne 1 -or $params[0].expression -isnot [string]) {
    throw 'No se encontro un unico parametro RutaParquet de tipo M compatible.'
}
$oldExpression = $params[0].expression
$prefixPattern = '^"(?:[^"]|"")*"\s+(?<meta>meta\s+\[.*\])$'
$match = [regex]::Match($oldExpression, $prefixPattern)
if (-not $match.Success) {
    throw 'El formato del parametro RutaParquet cambio. No se modifico el modelo.'
}
$mPath = $folder.Replace('#', '#(#)').Replace('"', '""')
$newExpression = '"' + $mPath + '" ' + $match.Groups['meta'].Value

if ($oldExpression -cne $newExpression) {
    $pattern = '"expression"\s*:\s*(?<value>"(?:\\.|[^"\\])*")'
    $matchesFound = @(
        foreach ($candidate in [regex]::Matches($raw, $pattern)) {
            $literal = $candidate.Groups['value'].Value
            $decoded = (ConvertFrom-Json -InputObject ('{"v":' + $literal + '}')).v
            if ($decoded -ceq $oldExpression) { $candidate }
        }
    )
    if ($matchesFound.Count -ne 1) {
        throw 'No se pudo identificar un unico literal para modificar. No se modifico el modelo.'
    }
    $token = $matchesFound[0].Groups['value']
    $newLiteral = ConvertTo-Json -InputObject $newExpression -Compress
    $updated = $raw.Substring(0, $token.Index) + $newLiteral + $raw.Substring($token.Index + $token.Length)
    $verified = ConvertFrom-Json -InputObject $updated
    $verifyParam = @($verified.model.expressions | Where-Object { $_.name -eq 'RutaParquet' })
    if ($verifyParam.Count -ne 1 -or $verifyParam[0].expression -cne $newExpression) {
        throw 'Error de validacion JSON. No se modifico el modelo.'
    }
    [System.IO.File]::WriteAllText($modelPath, $updated, $utf8)
}

Write-Host "RutaParquet: $folder" -ForegroundColor Green
Write-Host '13 archivos encontrados (existencia y tamano comprobados).' -ForegroundColor Green
Write-Host 'El cambio es local: no incluyas model.bim en tus commits si solo cambiaste la ruta.'
if (-not $NoAbrir) {
    Start-Process -FilePath $projectPath
    Write-Host 'En Power BI, pulsa Actualizar para verificar la carga.'
}
