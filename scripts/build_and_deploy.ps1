<#
.SYNOPSIS
  Build and optionally deploy the OnlineExam webapp using Ant and (optionally) Tomcat.

.DESCRIPTION
  This script checks for Java and Ant, warns if a MySQL JDBC driver is missing from
  `web/WEB-INF/lib`, runs `ant dist` to create `dist/OnlineExam.war`, and if requested
  copies the WAR into a provided Tomcat `webapps` folder and starts Tomcat.

.PARAMETER Deploy
  If supplied the script will copy the WAR to the Tomcat `webapps` directory and start Tomcat.

.PARAMETER TomcatPath
  The root path to a Tomcat installation (used when `-Deploy` is passed).

USAGE
  From the project root (where `build.xml` lives):
    .\scripts\build_and_deploy.ps1            # just build
    .\scripts\build_and_deploy.ps1 -Deploy -TomcatPath 'C:\apache-tomcat-9.0.58'  # build+deploy
#>

param(
    [switch]$Deploy,
    [string]$TomcatPath = ''
)

function Write-Info($msg){ Write-Host "[INFO]  $msg" }
function Write-Warn($msg){ Write-Warning "[WARN]  $msg" }
function Write-Err($msg){ Write-Error "[ERROR] $msg" }

$RepoRoot = (Get-Location).Path
Write-Info "Repository root: $RepoRoot"

# Check Java
Write-Info "Checking for Java..."
try {
    $javaOut = & java -version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host $javaOut
} catch {
    Write-Err "Java is not available. Install JDK 1.8 and ensure 'java' is on PATH."
    exit 2
}

# Check Ant
Write-Info "Checking for Ant..."
try {
    $antOut = & ant -version 2>&1
    if ($LASTEXITCODE -ne 0) { throw }
    Write-Host $antOut
} catch {
    Write-Err "Apache Ant is not available. Install Ant and add its 'bin' to PATH."
    exit 3
}

# Check MySQL connector presence
$libPath = Join-Path $RepoRoot 'web\WEB-INF\lib'
if (-not (Test-Path $libPath)) { Write-Warn "Library path not found: $libPath" }
else {
    $connector = Get-ChildItem -Path $libPath -Filter '*mysql*.jar' -ErrorAction SilentlyContinue
    if (-not $connector) { Write-Warn "No MySQL connector jar found in $libPath. Add mysql-connector-java.jar before running in production." }
    else { Write-Info "Found JDBC connector(s): $($connector.Name -join ', ')" }
}

# Run Ant dist
Write-Info "Running 'ant dist' from: $RepoRoot"
Push-Location $RepoRoot
try {
    $p = Start-Process -FilePath ant -ArgumentList 'dist' -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -ne 0) {
        Write-Err "Ant build failed with exit code $($p.ExitCode). Check the Ant output above."
        Pop-Location
        exit $p.ExitCode
    }
} catch {
    Write-Err "Failed to run 'ant dist': $_"
    Pop-Location
    exit 4
}
Pop-Location

$warPath = Join-Path $RepoRoot 'dist\OnlineExam.war'
if (-not (Test-Path $warPath)) {
    Write-Err "Expected WAR not found at $warPath. Build may have failed or produced a different artifact."
    exit 5
}

Write-Info "Build succeeded. WAR: $warPath"

if ($Deploy) {
    if ([string]::IsNullOrWhiteSpace($TomcatPath)) {
        Write-Err "-Deploy requested but -TomcatPath was not provided."
        exit 6
    }

    $webapps = Join-Path $TomcatPath 'webapps'
    if (-not (Test-Path $webapps)) {
        Write-Err "Tomcat webapps folder not found at: $webapps"
        exit 7
    }

    Write-Info "Copying WAR to Tomcat webapps: $webapps"
    try {
        Copy-Item -Path $warPath -Destination $webapps -Force
    } catch {
        Write-Err "Failed to copy WAR: $_"
        exit 8
    }

    $startup = Join-Path $TomcatPath 'bin\startup.bat'
    if (-not (Test-Path $startup)) { Write-Warn "Tomcat startup script not found at $startup. You may need to start Tomcat manually." }
    else {
        Write-Info "Starting Tomcat using: $startup"
        Start-Process -FilePath $startup -WorkingDirectory (Join-Path $TomcatPath 'bin')
        Write-Info "Tomcat start requested. Check Tomcat logs if the server does not become available." 
    }

    Write-Host "Open: http://localhost:8080/OnlineExam/ (context path is the WAR name 'OnlineExam')"
}

Write-Info "Done."
