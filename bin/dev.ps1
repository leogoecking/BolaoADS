$ErrorActionPreference = "Stop"

$ProjectRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$DefaultRuby = Join-Path $HOME "Ruby33-x64\bin\ruby.exe"
$DefaultUcrt = Join-Path $HOME "Ruby33-x64\msys64\ucrt64\bin"
$HostAddress = if ($env:HOST) { $env:HOST } else { "0.0.0.0" }
$Port = if ($env:PORT) { [int]$env:PORT } else { 3000 }
$PidPath = Join-Path $ProjectRoot "tmp\pids\server.pid"

function Get-LanAddress {
  if ($env:PUBLIC_HOST) {
    return $env:PUBLIC_HOST
  }

  $DefaultRoute = Get-NetRoute -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -and $_.NextHop -ne "0.0.0.0" } |
    Sort-Object RouteMetric |
    Select-Object -First 1

  if ($DefaultRoute) {
    $Configuration = Get-NetIPConfiguration -InterfaceIndex $DefaultRoute.InterfaceIndex -ErrorAction SilentlyContinue
    $Address = $Configuration.IPv4Address |
      Where-Object { $_.IPAddress -and $_.IPAddress -notlike "169.254.*" } |
      Select-Object -First 1

    if ($Address) {
      return $Address.IPAddress
    }
  }

  $Fallback = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.254.*" } |
    Select-Object -First 1

  if ($Fallback) {
    return $Fallback.IPAddress
  }

  return "127.0.0.1"
}

function Test-PortAvailable($HostAddress, $Port) {
  $Listener = $null
  try {
    $Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($HostAddress), $Port)
    $Listener.Start()
    return $true
  } catch {
    return $false
  } finally {
    if ($Listener) {
      $Listener.Stop()
    }
  }
}

if (Get-Command ruby -ErrorAction SilentlyContinue) {
  $Ruby = "ruby"
} elseif (Test-Path $DefaultRuby) {
  $Ruby = $DefaultRuby
  $env:Path = "$(Split-Path $DefaultRuby);$DefaultUcrt;$env:Path"
} else {
  throw "Ruby nao encontrado. Instale Ruby 3.3.11 ou ajuste o PATH antes de rodar bin\dev.ps1."
}

Push-Location $ProjectRoot
try {
  $LanAddress = Get-LanAddress

  if (Test-Path $PidPath) {
    $ExistingPid = [int](Get-Content $PidPath -Raw)
    $ExistingProcess = Get-Process -Id $ExistingPid -ErrorAction SilentlyContinue

    if ($ExistingProcess) {
      $Connection = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Where-Object { $_.OwningProcess -eq $ExistingPid } |
        Select-Object -First 1

      if ($Connection) {
        $DisplayAddress = if ($Connection.LocalAddress -eq "0.0.0.0") { $LanAddress } else { $Connection.LocalAddress }
        Write-Host "BolaoADS ja esta rodando localmente em http://127.0.0.1:$($Connection.LocalPort)"
        Write-Host "Acesso na rede local em http://${DisplayAddress}:$($Connection.LocalPort) (pid $ExistingPid)"
      } else {
        Write-Host "BolaoADS ja esta rodando (pid $ExistingPid)."
      }

      Write-Host "Pare esse processo antes de iniciar outra instancia."
      exit 0
    }

    Remove-Item -LiteralPath $PidPath -Force
  }

  while (-not (Test-PortAvailable $HostAddress $Port)) {
    $Port += 1
  }

  if (-not $env:BOLAOADS_DEVELOPMENT_DATABASE) {
    $env:BOLAOADS_DEVELOPMENT_DATABASE = Join-Path $ProjectRoot "db\development.sqlite3"
  }

  if (-not $env:BOLAOADS_TEST_DATABASE) {
    $env:BOLAOADS_TEST_DATABASE = Join-Path $ProjectRoot "db\test.sqlite3"
  }

  Write-Host "Gateway detectado. IP desta maquina na rede: $LanAddress"
  Write-Host "BolaoADS rodando localmente em http://127.0.0.1:$Port"
  Write-Host "Acesso na rede local em http://${LanAddress}:$Port"
  Write-Host "Use Ctrl+C para parar o servidor."

  & $Ruby "bin\rails" "server" "-b" $HostAddress "-p" $Port
} finally {
  Pop-Location
}
