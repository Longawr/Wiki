# ============================================================================
# EBF5 Wiki - fetch-images.ps1 (luot 13)
# Hoa quy trinh tai anh tu Epic Battle Fantasy Wiki (fandom) de rebuild repo.
# Quy uoc file .ps1 cua du an: soan van ASCII khong dau (theo mau check.ps1).
#
# Che do chay (chon 1, cu the ben duoi):
#   (mac dinh) -Check      quet tham chieu `image: 'img/...'` trong js/data.js,
#                          doi chieu voi file that tren dia: bao thieu, bao file le.
#   -BuildMap              sinh stub cho anh thieu vao fetch-images.map.txt:
#                          moi dong `img/<chude>/<id>.png<TAB>tten-file-tren-wiki`.
#                          Cot 2 de trong = bo qua khi download.
#   -Download              doc map, giai URL tung file qua fandom API (bo 50/luot)
#                          roi tai ve dung vi tri. Chi tai file chua co (-Force de tai de).
#
# Vi du:
#   powershell -ExecutionPolicy Bypass -File fetch-images.ps1
#   powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -BuildMap
#   powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -Download -DryRun
#   powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -Download -Limit 30
#
# Bai hoc da kiem chung (ROADMAP.md):
#   - CDN static.wikia.nocookie.net BAT BUOC header Referer + User-Agent trinh duyet,
#     neu khong tra 403.
#   - Chia lo hop ly ~50 URL/luot, nghi giua cac lo de tranh rate-limit.
#   - Ten file tren wiki thuong theo mau (tra duoc qua CustomIcon trong wikitext):
#     EBF5 Bestiary <Ten EN>.png | EBF5 Skill X.png | EBF5 Item X.png
#     EBF5 Status X.png          | EBF5 Foe Icon X.png | <Tile>.png (tile ban do)
#   - Map file phan cach bang TAB; dong bat dau # va dong rong bi bo qua.
# ============================================================================

param(
  [switch]$BuildMap,
  [switch]$Download,
  [switch]$Force,
  [switch]$DryRun,
  [int]$Limit = 0,                                   # 0 = khong gioi han
  [string]$DataFile = 'js\data.js',
  [string]$MapFile = 'fetch-images.map.txt'
)

$ErrorActionPreference = 'Stop'
$script:API      = 'https://epicbattlefantasy.fandom.com/api.php'
$script:Referer  = 'https://epicbattlefantasy.fandom.com/'
$script:UA       = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$script:BATCH    = 50                               # so trang/luot khi giai URL
$script:DELAY_MS = 500                              # nghi giua cac luot

function Write-Section($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }

# ---------------------------------------------------------------------------
# 1. Quet data.js - lay moi tham chieu image
# ---------------------------------------------------------------------------
function Get-ImageRefs {
  $refs = @()
  $i = 0
  switch -Regex -File $DataFile {
    'image:\s*''(img/[^'']+)''' {
      $i++
      $m = [regex]::Match($_, "id:\s*'([^']+)'")
      $id = if ($m.Success) { $m.Groups[1].Value } else { "line$i" }
      $refs += [pscustomobject]@{ Id = $id; Path = $Matches[1]; Line = $i }
    }
  }
  return , $refs
}

# ---------------------------------------------------------------------------
# 2. Check - doi chieu data.js vs dia (mode mac dinh)
#    Tra ve 0 khi 0 file thieu, 1 khi con thieu (cua chan nhu check.ps1).
# ---------------------------------------------------------------------------
function Invoke-Check {
  Write-Section 'CHECK ANH - data.js vs img/'
  $refs = Get-ImageRefs
  if (-not $refs.Count) {
    Write-Host '  [FAIL] khong tim thay tham chieu image nao trong data.js' -ForegroundColor Red
    return 1
  }

  $missing = @($refs | Where-Object { -not (Test-Path $_.Path) })
  $allDisk = @(Get-ChildItem img -Recurse -File | ForEach-Object {
    $_.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
  })
  $refSet = [System.Collections.Generic.HashSet[string]]::new()
  $refs | ForEach-Object { [void]$refSet.Add($_.Path) }
  $orphan = @($allDisk | Where-Object { -not $refSet.Contains($_) })

  Write-Host ("  tham chieu image: {0} | file tren dia: {1}" -f $refs.Count, $allDisk.Count)
  if ($missing.Count) {
    Write-Host ("  THIEU {0} file:" -f $missing.Count) -ForegroundColor Yellow
    $missing | ForEach-Object {
      Write-Host ("    {0}  (id: {1}, dong {2})" -f $_.Path, $_.Id, $_.Line)
    }
  } else {
    Write-Host '  [OK] 0 file thieu' -ForegroundColor Green
  }
  if ($orphan.Count) {
    Write-Host ("  FILE LE (khong duoc tham chieu) {0}:" -f $orphan.Count) -ForegroundColor Yellow
    $orphan | ForEach-Object { Write-Host "    $_" }
  } else {
    Write-Host '  [OK] 0 file le' -ForegroundColor Green
  }

  Write-Section 'SO FILE THEO THU MUC'
  Get-ChildItem img -Directory | ForEach-Object {
    Write-Host ('{0,-11}: {1,4} file' -f $_.Name, @(Get-ChildItem $_.FullName -File).Count)
  }
  $rootCount = @(Get-ChildItem img -File).Count
  if ($rootCount) { Write-Host ('{0,-11}: {1,4} file' -f '(goc img)', $rootCount) }

  return $(if ($missing.Count) { 1 } else { 0 })
}

# ---------------------------------------------------------------------------
# 3. BuildMap - sinh stub (cot 2 de trong) cho anh thieu, noi vao map file
# ---------------------------------------------------------------------------
function Update-Map {
  Write-Section 'BUILD MAP - sinh stub cho anh thieu'
  $present = @{}
  if (Test-Path $MapFile) {
    switch -Regex -File $MapFile {
      '^\s*(#.*)?$' { continue }
      '^(.+?)\t(.*)$' { $present[$Matches[1].Trim()] = $true }
    }
    Write-Host ("  doc {0} duong dan hien co tu {1}" -f $present.Count, $MapFile)
  } else {
    Write-Host ("  chua co {0} - se tao moi" -f $MapFile)
  }

  $missing = @(Get-ImageRefs | Where-Object { -not (Test-Path $_.Path) })
  $new = @($missing | Where-Object { -not $present.ContainsKey($_.Path) })
  if (-not $new.Count) {
    Write-Host '  [OK] map da cho du anh thieu' -ForegroundColor Green
    return 0
  }

  $stamp = '# sinh luc ' + (Get-Date -Format 'yyyy-MM-dd HH:mm') + ' - dien ten file wiki o cot 2 (phan cach TAB)'
  Add-Content -Path $MapFile -Value $stamp
  $new | ForEach-Object { Add-Content -Path $MapFile -Value ("{0}`t" -f $_.Path) }
  Write-Host ('  da them {0} dong stub vao {1}' -f $new.Count, $MapFile) -ForegroundColor Green
  return 0
}

# ---------------------------------------------------------------------------
# 4. Download - giai URL qua fandom API (bo $BATCH/luot) roi tai ve
# ---------------------------------------------------------------------------
function Get-BatchUrls($names) {
  # Ep kieu de dam bao $names (co the null) phai la mang chuoi
  $titles = @($names | ForEach-Object { 'File:' + $_ })
  $titleParam = ($titles | ForEach-Object { [uri]::EscapeDataString($_) }) -join '|'
  $url = $script:API + '?action=query&format=json&prop=imageinfo&iiprop=url&titles=' + $titleParam
  $resp = Invoke-WebRequest -Uri $url -Headers @{ Referer = $script:Referer } `
    -UserAgent $script:UA -UseBasicParsing
  $json = $resp.Content | ConvertFrom-Json
  $urls = @{}
  foreach ($p in $json.query.pages.PSObject.Properties.Value) {
    if ($p.imageinfo) {
      $t = $p.title -replace '^File:', ''
      $urls[$t.ToLower()] = $p.imageinfo[0].url
    }
  }
  return $urls
}

function Invoke-Download {
  Write-Section 'DOWNLOAD ANH THIEU'
  if (-not (Test-Path $MapFile)) {
    Write-Host ("  khong co {0} - chay -BuildMap truoc" -f $MapFile) -ForegroundColor Yellow
    return 2
  }

  # Doc map: cot 1 = duong dan local, cot 2 = ten file wiki; de trong thi bo qua
  $plan = @()
  switch -Regex -File $MapFile {
    '^\s*(#.*)?$' { continue }
    '^(.+?)\t(.+)$' {
      $localPath = $Matches[1].Trim()
      $wikiName  = $Matches[2].Trim() -replace '\.png$', ''
      if (-not $wikiName) { continue }
      $existed = Test-Path $localPath
      if (-not $existed -or ($existed -and $Force)) {
        $plan += [pscustomobject]@{ Local = $localPath; Wiki = $wikiName }
      }
    }
  }
  if (-not $plan.Count) {
    Write-Host '  [OK] khong co anh nao can tai (map trong / file da co; -Force de tai de)' -ForegroundColor Green
    return 0
  }
  if ($Limit -gt 0 -and $plan.Count -gt $Limit) {
    Write-Host ("  gioi han -Limit {0}: chot {1}/{2} dong" -f $Limit, $Limit, $plan.Count) -ForegroundColor Yellow
    $plan = @($plan | Select-Object -First $Limit)
  }

  $ok = 0; $fail = 0; $skip = 0
  for ($i = 0; $i -lt $plan.Count; $i += $script:BATCH) {
    $end = [Math]::Min($i + $script:BATCH - 1, $plan.Count - 1)
    $batch = @($plan[$i..$end])
    if ($i -eq $end) { Write-Host ("  lo {0}/{1}: giai URL..." -f ($i + 1), $plan.Count) -NoNewline }
    else             { Write-Host ("  lo {0}-{1}/{2}: giai URL..." -f ($i + 1), $end, $plan.Count) -NoNewline }
    try {
      $urls = Get-BatchUrls ($batch | ForEach-Object { $_.Wiki + '.png' })
    } catch {
      Write-Host ("  LOI API: {0}" -f $_.Exception.Message) -ForegroundColor Red
      $fail += $batch.Count
      continue
    }
    if ($script:DELAY_MS) { Start-Sleep -Milliseconds $script:DELAY_MS }

    foreach ($row in $batch) {
      $key = ($row.Wiki + '.png').ToLower()
      $u = $urls[$key]
      if (-not $u) {
        Write-Host ("    [SKIP] khong thay tren wiki: {0}.png" -f $row.Wiki) -ForegroundColor Yellow
        $skip++
        continue
      }
      if ($DryRun) {
        Write-Host ("    [DRY] {0} <- {1}" -f $row.Local, $u)
        continue
      }
      $dir = Split-Path $row.Local -Parent
      if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
      try {
        Invoke-WebRequest -Uri $u -Headers @{ Referer = $script:Referer } `
          -UserAgent $script:UA -UseBasicParsing -OutFile $row.Local
        Write-Host ("    [OK] {0}" -f $row.Local) -ForegroundColor Green
        $ok++
      } catch {
        Write-Host ("    [FAIL] {0}: {1}" -f $row.Local, $_.Exception.Message) -ForegroundColor Red
        $fail++
      }
    }
  }
  Write-Host ("`n  ket qua: OK {0} / SKIP {1} / FAIL {2}" -f $ok, $skip, $fail)
  return $(if ($fail) { 1 } else { 0 })
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
if (-not (Test-Path $DataFile)) {
  Write-Host ("khong tim thay {0}" -f $DataFile) -ForegroundColor Red
  exit 2
}

$code = 0
if ($Download)   { $code = Invoke-Download }
elseif ($BuildMap) { $code = Update-Map }
else             { $code = Invoke-Check }
exit $code
