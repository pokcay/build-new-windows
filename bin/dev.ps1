# bin/dev.ps1 -- Windows launcher for Rails + Vite development server
# Usage: .\bin\dev.ps1
#
# Uses Procfile.dev.windows (web + vite only). Background jobs run in-process
# via the :async ActiveJob adapter on Windows since SolidQueue's supervisor
# requires POSIX signals (SIGQUIT) not available on Windows.

if (-not $env:PORT) { $env:PORT = "3000" }

function Stop-PortListeners {
    param([int]$Port)
    try {
        $connections = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            $procId = $conn.OwningProcess
            if ($procId -and $procId -ne 0) {
                $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Host "Stopping stale process on port $Port (pid: $procId, name: $($proc.ProcessName))..." -ForegroundColor Yellow
                    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                }
            }
        }
        if ($connections) { Start-Sleep -Seconds 1 }
    } catch {}
}

Stop-PortListeners -Port ([int]$env:PORT)
Stop-PortListeners -Port 3036

$pidFile = "tmp\pids\server.pid"
if (Test-Path $pidFile) {
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

$foreman = Get-Command foreman -ErrorAction SilentlyContinue
if (-not $foreman) {
    Write-Host "Installing foreman..."
    gem install foreman
}

foreman start -f Procfile.dev.windows @args
