# Configura el origen local de los 13 Parquet. Ejecutar con Power BI cerrado.
[CmdletBinding(DefaultParameterSetName = 'Configurar')]
param(
    [Parameter(ParameterSetName = 'Configurar', Position = 0)]
    [string]$RutaParquet,

    [Parameter(ParameterSetName = 'Configurar')]
    [switch]$NoAbrir,

    [Parameter(ParameterSetName = 'Restaurar', Mandatory = $true)]
    [switch]$Restaurar,

    [Parameter(ParameterSetName = 'Verificar', Mandatory = $true)]
    [switch]$VerificarRepositorio
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$portableMarker = '__EJECUTA_CONFIGURAR_PARQUET__'
$modelPath = Join-Path $PSScriptRoot 'TMDB.SemanticModel\model.bim'
$projectPath = Join-Path $PSScriptRoot 'TMDB.pbip'
$localConfigDir = Join-Path $PSScriptRoot '.tmdb-local'
$localRoutePath = Join-Path $localConfigDir 'RutaParquet.txt'
$utf8 = New-Object System.Text.UTF8Encoding($false)

$expected = @(
    'dim_fecha', 'dim_pelicula', 'dim_genero',
    'dim_productora', 'dim_pais', 'dim_idioma', 'dim_palabra_clave',
    'fact_peliculas', 'bridge_pelicula_genero', 'bridge_pelicula_productora',
    'bridge_pelicula_pais', 'bridge_pelicula_idioma', 'bridge_pelicula_palabra_clave'
)

function Get-RutaParquetParameter {
    param([Parameter(Mandatory = $true)][string]$Raw)

    $model = ConvertFrom-Json -InputObject $Raw
    $parameters = @(
        $model.model.expressions |
            Where-Object { $_.name -eq 'RutaParquet' -and $_.kind -eq 'm' }
    )
    if ($parameters.Count -ne 1 -or $parameters[0].expression -isnot [string]) {
        throw 'No se encontro un unico parametro RutaParquet de tipo M compatible.'
    }

    $expression = $parameters[0].expression
    $expressionPattern = '^"(?:[^"]|"")*"\s+(?<meta>meta\s+\[.*\])$'
    $expressionMatch = [regex]::Match($expression, $expressionPattern)
    if (-not $expressionMatch.Success) {
        throw 'El formato del parametro RutaParquet cambio. No se modifico el modelo.'
    }

    [pscustomobject]@{
        Expression = $expression
        Metadata = $expressionMatch.Groups['meta'].Value
    }
}

function Set-RutaParquetParameter {
    param(
        [Parameter(Mandatory = $true)][string]$Raw,
        [Parameter(Mandatory = $true)][string]$Value
    )

    $parameter = Get-RutaParquetParameter -Raw $Raw
    $mValue = $Value.Replace('#', '#(#)').Replace('"', '""')
    $newExpression = '"' + $mValue + '" ' + $parameter.Metadata

    if ($parameter.Expression -ceq $newExpression) {
        return $Raw
    }

    $tokenPattern = '"expression"\s*:\s*(?<value>"(?:\\.|[^"\\])*")'
    $matchesFound = @(
        foreach ($candidate in [regex]::Matches($Raw, $tokenPattern)) {
            $literal = $candidate.Groups['value'].Value
            $decoded = (ConvertFrom-Json -InputObject ('{"v":' + $literal + '}')).v
            if ($decoded -ceq $parameter.Expression) {
                $candidate
            }
        }
    )
    if ($matchesFound.Count -ne 1) {
        throw 'No se pudo identificar un unico literal para modificar. No se modifico el modelo.'
    }

    $token = $matchesFound[0].Groups['value']
    $newLiteral = ConvertTo-Json -InputObject $newExpression -Compress
    $updated = $Raw.Substring(0, $token.Index) +
        $newLiteral +
        $Raw.Substring($token.Index + $token.Length)

    $verifiedParameter = Get-RutaParquetParameter -Raw $updated
    if ($verifiedParameter.Expression -cne $newExpression) {
        throw 'Error de validacion JSON. No se modifico el modelo.'
    }

    return $updated
}

function Write-RutaParquetParameter {
    param([Parameter(Mandatory = $true)][string]$Value)

    $raw = [System.IO.File]::ReadAllText($modelPath, $utf8)
    $updated = Set-RutaParquetParameter -Raw $raw -Value $Value
    if ($updated -cne $raw) {
        [System.IO.File]::WriteAllText($modelPath, $updated, $utf8)
    }
}

function Test-ParquetFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $stream = [System.IO.File]::Open(
        $Path,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::ReadWrite
    )
    try {
        if ($stream.Length -lt 12) {
            throw 'el archivo es demasiado pequeno para ser Parquet'
        }

        $header = New-Object byte[] 4
        $footer = New-Object byte[] 4
        if ($stream.Read($header, 0, 4) -ne 4) {
            throw 'no se pudo leer el encabezado'
        }
        [void]$stream.Seek(-4, [System.IO.SeekOrigin]::End)
        if ($stream.Read($footer, 0, 4) -ne 4) {
            throw 'no se pudo leer el pie'
        }

        $headerText = [System.Text.Encoding]::ASCII.GetString($header)
        $footerText = [System.Text.Encoding]::ASCII.GetString($footer)
        if ($headerText -cne 'PAR1' -or $footerText -cne 'PAR1') {
            throw 'firma PAR1 invalida'
        }
    }
    finally {
        $stream.Dispose()
    }
}

try {
    if (-not (Test-Path -LiteralPath $modelPath -PathType Leaf) -or
        -not (Test-Path -LiteralPath $projectPath -PathType Leaf)) {
        throw 'No se encontro el proyecto TMDB. Ejecuta el script desde su clon completo.'
    }

    if ($VerificarRepositorio) {
        $raw = [System.IO.File]::ReadAllText($modelPath, $utf8)
        $parameter = Get-RutaParquetParameter -Raw $raw
        $safePrefix = '"' + $portableMarker + '" meta '
        if (-not $parameter.Expression.StartsWith(
            $safePrefix,
            [System.StringComparison]::Ordinal
        )) {
            throw 'RutaParquet contiene una ruta local. Ejecuta Configurar_Parquet.ps1 -Restaurar antes de publicar.'
        }

        Write-Host 'OK: el modelo versionado usa el marcador portable de RutaParquet.' -ForegroundColor Green
        exit 0
    }

    if (Get-Process -Name PBIDesktop -ErrorAction SilentlyContinue) {
        throw 'Cierra Power BI Desktop antes de configurar o restaurar la ruta.'
    }

    if ($Restaurar) {
        Write-RutaParquetParameter -Value $portableMarker
        Write-Host 'RutaParquet restaurada al marcador portable.' -ForegroundColor Green
        Write-Host 'La preferencia local permanece en .tmdb-local (ignorada por Git).'
        Write-Host 'Ejecuta git status y el modo -VerificarRepositorio antes de publicar.'
        exit 0
    }

    if ([string]::IsNullOrWhiteSpace($RutaParquet)) {
        if (Test-Path -LiteralPath $localRoutePath -PathType Leaf) {
            $RutaParquet = [System.IO.File]::ReadAllText($localRoutePath, $utf8).Trim()
        }
        if ([string]::IsNullOrWhiteSpace($RutaParquet)) {
            $RutaParquet = Join-Path $PSScriptRoot '..\parquet'
            $repoParquet = Join-Path $PSScriptRoot 'parquet'
            if (-not (Test-Path -LiteralPath $RutaParquet -PathType Container) -and
                (Test-Path -LiteralPath $repoParquet -PathType Container)) {
                $RutaParquet = $repoParquet
            }
        }
    }

    if (-not (Test-Path -LiteralPath $RutaParquet -PathType Container)) {
        throw "No se encontro la carpeta: $RutaParquet. Sincroniza los Parquet o usa -RutaParquet con su ubicacion local."
    }

    $resolved = Resolve-Path -LiteralPath $RutaParquet
    if ($resolved.Provider.Name -ne 'FileSystem') {
        throw 'RutaParquet debe ser una carpeta del sistema de archivos.'
    }
    $folder = $resolved.ProviderPath
    $problems = @(
        foreach ($table in $expected) {
            $path = Join-Path $folder "$table.parquet"
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
                "$table.parquet (ausente)"
                continue
            }

            try {
                Test-ParquetFile -Path $path
            }
            catch {
                "$table.parquet ($($_.Exception.Message))"
            }
        }
    )
    if ($problems.Count -gt 0) {
        throw ('Archivos Parquet no disponibles o invalidos: ' + ($problems -join ', '))
    }

    # Modifica solo el literal JSON de RutaParquet; no serializa de nuevo model.bim.
    Write-RutaParquetParameter -Value $folder.TrimEnd('\')

    if ($PSBoundParameters.ContainsKey('RutaParquet')) {
        [void][System.IO.Directory]::CreateDirectory($localConfigDir)
        [System.IO.File]::WriteAllText($localRoutePath, $folder, $utf8)
    }

    Write-Host "RutaParquet: $folder" -ForegroundColor Green
    Write-Host '13 archivos encontrados y legibles; firmas PAR1 comprobadas.' -ForegroundColor Green
    Write-Host 'La ruta absoluta de este equipo se aplica solo al modelo de trabajo.'

    if (-not $NoAbrir) {
        Start-Process -FilePath $projectPath
        Write-Host 'Power BI Desktop iniciado. Pulsa Actualizar para comprobar la carga.'
    }
    else {
        Write-Host 'Configuracion terminada sin abrir Power BI Desktop.'
    }

    Write-Host 'Al terminar y cerrar Power BI, ejecuta:'
    Write-Host '  .\Configurar_Parquet.ps1 -Restaurar'
    exit 0
}
catch {
    Write-Host ("ERROR: " + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
