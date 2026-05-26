param(
  [switch]$CloseBrowsers,
  [ValidateSet('Chrome', 'Edge', 'Brave')]
  [string[]]$Browsers = @('Chrome', 'Edge', 'Brave'),
  [string[]]$Patterns = @('claude.ai', 'api.claude.ai', 'anthropic.com'),
  [switch]$WhatIf,
  [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

function Resolve-Sqlite {
  $candidates = @(
    (Get-Command sqlite3 -ErrorAction SilentlyContinue).Source,
    Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\sqlite3.exe',
    Join-Path $env:PROGRAMFILES 'SQLite\sqlite3.exe',
    Join-Path ${env:PROGRAMFILES(x86)} 'SQLite\sqlite3.exe'
  )

  foreach ($path in $candidates | Where-Object { $_ }) {
    if (Test-Path $path) {
      return (Resolve-Path $path).Path
    }
  }

  throw 'sqlite3 未找到，请先安装 SQLite 并确保在 PATH，或安装 Android Platform Tools 后重试。'
}

function New-LikeClause {
  param([string]$Column, [string[]]$Terms)
  $parts = foreach ($term in $Terms) {
    "$Column LIKE '%$term%'"
  }
  return "($($parts -join ' OR '))"
}

function Test-ColumnExists {
  param([string]$DbPath, [string]$Table, [string]$Column, [string]$SqliteExe)
  $rows = & $SqliteExe $DbPath "PRAGMA table_info($Table);" 2>$null
  if ($LASTEXITCODE -ne 0) {
    return $false
  }
  foreach ($r in $rows) {
    $cells = $r -split '\|'
    if ($cells.Count -ge 2 -and $cells[1] -eq $Column) {
      return $true
    }
  }
  return $false
}

function Invoke-SqliteIfExists {
  param(
    [string]$DbPath,
    [string]$SqliteExe,
    [string[]]$Statements
  )
  if (-not (Test-Path $DbPath)) {
    return
  }

  foreach ($stmt in $Statements) {
    try {
      $null = & $SqliteExe $DbPath $stmt 2>$null
      if ($LASTEXITCODE -eq 0 -and $VerboseOutput) {
        Write-Host "  [OK] $DbPath"
      }
    }
    catch {
      if ($VerboseOutput) {
        Write-Host "  [WARN] $DbPath -> $($stmt): $($_.Exception.Message)"
      }
    }
  }
}

function Stop-BrowserProcesses {
  param([string[]]$ProcNames)
  foreach ($name in $ProcNames) {
    $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($procs) {
      if ($WhatIf) {
        Write-Host "[WHATIF] would stop $($procs.Count) $name process(es)"
      }
      else {
        $procs | Stop-Process -Force
        Write-Host "已停止 $name 进程: $($procs.Count) 个"
      }
    }
  }
}

function Clear-ProfileData {
  param(
    [string]$ProfilePath,
    [string]$Browser,
    [string[]]$Patterns,
    [string]$SqliteExe
  )

  Write-Host "清理 $Browser :: $ProfilePath"
  $urlClause = New-LikeClause -Column 'url' -Terms $Patterns
  $hostClause = New-LikeClause -Column 'host_key' -Terms $Patterns
  $termClause = New-LikeClause -Column 'term' -Terms $Patterns
  $realmClause = New-LikeClause -Column 'origin' -Terms $Patterns

  $historyDb = Join-Path $ProfilePath 'History'
  $historyTables = @()
  if (Test-Path $historyDb) {
    $historyTables = (& $SqliteExe $historyDb '.tables' 2>$null) `
      -split [Environment]::NewLine | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  }

  if ($historyTables -contains 'urls') {
    Invoke-SqliteIfExists -DbPath $historyDb -SqliteExe $SqliteExe -Statements @(
      "DELETE FROM urls WHERE $urlClause;"
    )
  }

  if ($historyTables -contains 'visits' -and (Test-ColumnExists -DbPath $historyDb -Table 'visits' -Column 'url_id' -SqliteExe $SqliteExe)) {
    Invoke-SqliteIfExists -DbPath $historyDb -SqliteExe $SqliteExe -Statements @(
      "DELETE FROM visits WHERE url_id IN (SELECT id FROM urls WHERE $urlClause);"
    )
  }

  if ($historyTables -contains 'keyword_search_terms') {
    Invoke-SqliteIfExists -DbPath $historyDb -SqliteExe $SqliteExe -Statements @(
      "DELETE FROM keyword_search_terms WHERE $termClause;"
    )
  }

  if ($historyTables -contains 'origin') {
    Invoke-SqliteIfExists -DbPath $historyDb -SqliteExe $SqliteExe -Statements @(
      "DELETE FROM origin WHERE $hostClause;"
    )
  }

  $cookiePaths = @(
    Join-Path $ProfilePath 'Network\\Cookies',
    Join-Path $ProfilePath 'Cookies'
  )
  foreach ($cookie in $cookiePaths) {
    if (Test-Path $cookie) {
      Invoke-SqliteIfExists -DbPath $cookie -SqliteExe $SqliteExe -Statements @(
        "DELETE FROM cookies WHERE $hostClause;"
      )
    }
  }

  $loginDb = Join-Path $ProfilePath 'Login Data'
  if (Test-Path $loginDb) {
    $loginTables = (& $SqliteExe $loginDb '.tables' 2>$null) `
      -split [Environment]::NewLine | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    if ($loginTables -contains 'logins' -and (Test-ColumnExists -DbPath $loginDb -Table 'logins' -Column 'origin' -SqliteExe $SqliteExe)) {
      Invoke-SqliteIfExists -DbPath $loginDb -SqliteExe $SqliteExe -Statements @(
        "DELETE FROM logins WHERE $realmClause;"
      )
    }
  }

  $storageRoots = @(
    'Local Storage',
    'IndexedDB',
    'Session Storage',
    'Service Worker',
    'Cache',
    'Code Cache'
  )
  $storageKeywordRegex = ($Patterns | ForEach-Object { [regex]::Escape($_) }) -join '|'
  foreach ($root in $storageRoots) {
    $rootPath = Join-Path $ProfilePath $root
    if (-not (Test-Path $rootPath)) {
      continue
    }
    $hits = Get-ChildItem -Path $rootPath -Recurse -Force -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -match $storageKeywordRegex -or $_.FullName -match 'claude|anthropic' } |
      Sort-Object -Property FullName -Descending
    foreach ($item in $hits) {
      if ($WhatIf) {
        Write-Host "[WHATIF] would remove $($item.FullName)"
      }
      else {
        try {
          Remove-Item -LiteralPath $item.FullName -Recurse -Force
          Write-Host "  [OK] remove $($item.FullName)"
        }
        catch {
          if ($VerboseOutput) {
            Write-Host "  [WARN] remove $($item.FullName): $($_.Exception.Message)"
          }
        }
      }
    }
  }
}

$browserMap = @{
  'Chrome' = @{
    Path = Join-Path $env:LOCALAPPDATA 'Google\\Chrome\\User Data'
    Processes = @('chrome')
  }
  'Edge'   = @{
    Path = Join-Path $env:LOCALAPPDATA 'Microsoft\\Edge\\User Data'
    Processes = @('msedge')
  }
  'Brave'  = @{
    Path = Join-Path $env:LOCALAPPDATA 'BraveSoftware\\Brave-Browser\\User Data'
    Processes = @('brave')
  }
}

$sqliteExe = Resolve-Sqlite
if ($CloseBrowsers) {
  $processes = foreach ($name in $Browsers) { $browserMap[$name].Processes } | Select-Object -Unique
  Stop-BrowserProcesses -ProcNames $processes
}

foreach ($browser in $Browsers) {
  if (-not $browserMap.ContainsKey($browser)) {
    continue
  }

  $data = $browserMap[$browser]
  if (-not (Test-Path $data.Path)) {
    Write-Host "[Skip] $browser 未安装或数据目录不存在: $($data.Path)"
    continue
  }

  $profiles = Get-ChildItem -Path $data.Path -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq 'Default' -or $_.Name -like 'Profile*' }

  if (-not $profiles) {
    Write-Host "[Skip] $browser 未检测到浏览器配置目录"
    continue
  }

  foreach ($profile in $profiles) {
    if ($WhatIf) {
      Write-Host "[WHATIF] 清理配置: $($profile.FullName)"
    }
    Clear-ProfileData -ProfilePath $profile.FullName -Browser $browser -Patterns $Patterns -SqliteExe $sqliteExe
  }
}

Write-Host '清理完成。'
