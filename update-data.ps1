# ============================================================================
# EBF5 Wiki - update-data.ps1 (luot 26)
# Hoa quy trinh cap nhat DATA tu Epic Battle Fantasy Wiki (fandom API):
# quet nguon wiki vs data.js de bao drift (muc moi / title stale), kem
# che do -Fix tu sua title sources theo transform co co so.
#
# Quy uoc file .ps1 cua du an: soan van ASCII khong dau (theo mau check.ps1).
#
# Che do chay (-Update bat buoc):
#   -Update enemies   : liet ke trang foe co {{FoeTableEBF5}} tren wiki
#                       (embeddedin Template:FoeTableEBF5), doi chieu voi
#                       entry `enemies` trong data.js -> bao foe moi.
#   -Update statuses  : trang Status Effects: moi heading co file
#                       `EBF5 Status ...` = 1 status EBF5 -> doi chieu
#                       voi sources.statuses trong data.js.
#   -Update items     : trang Food: anchor <span id="5<Ten>"></span>
#                       cua bang EBF5 -> doi chieu voi sources.items
#                       (chi cap per-entry, bo _default).
#   -Update sources   : kiem tra tat ca title per-entry trong
#                       sources.<key> cua data.js co ton tai tren wiki
#                       (redirects=1, bo 40/luot). -Fix de tu sua title
#                       stale (bo duoi "(foe)"... va lay trang chinh thuc).
#   -Update areas     : quet 303 trang "Epic Battle Fantasy 5 Map/<GR> <Khu>"
#                       (allpages), doi chieu o co noi dung (foes / Key Items)
#                       voi areas.cells trong data.js; o chi co Exits + o da
#                       tach thanh entry kind 'Khu con' bo qua co chu dich.
#                       -Fix tu them cell thieu va block sources.areaCells
#                       tuong ung (idempotent).
#
# Vi du:
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update enemies
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update statuses
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update items
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources -Fix
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update areas
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update areas -Fix
#
# Bai hoc da kiem chung (ROADMAP.md):
#   - CDN fandom BAT BUOC header Referer + User-Agent trinh duyet (403 neu khong).
#   - Ten file tren wiki khi imageinfo phai kem .png (o fetch-images.ps1).
#   - data.js la UTF-8 KHONG BOM: doc/ghi luon ro encoding.
#   - Khi sua data.js tu script: thay pair bang chuoi literal qua
#     String.Replace (dung dich [regex]::Replace co nguy co ky tu "$"
#     trong replacement), va chi trich doan sources de thay the (luot 21).
#   - API: bo 40-50 title/luot, nghi giua cac luot.
#
# Exit code: 0 = da phu (hoan toan xanh); 1 = con muc moi/title stale;
#            2 = loi doc data / khong tim hien nguon.
# ============================================================================

param(
  [string]$Update = '',
  [switch]$Fix,
  [string]$DataFile = 'js\data.js'
)

$ErrorActionPreference = 'Stop'
$script:API      = 'https://epicbattlefantasy.fandom.com/api.php'
$script:Referer  = 'https://epicbattlefantasy.fandom.com/'
$script:UA       = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36'
$script:BATCH    = 40
$script:DELAY_MS = 400

function Write-Section($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Write-Bad($t)     { Write-Host $t -ForegroundColor Yellow }
function Write-Err($t)     { Write-Host $t -ForegroundColor Red }
function Write-Ok($t)      { Write-Host $t -ForegroundColor Green }
function Write-Dim($t)     { Write-Host $t -ForegroundColor DarkGray }

# ---------------------------------------------------------------------------
# data.js: doc / ghi (UTF-8 khong BOM, giu nguyen phan con lai cua file)
# ---------------------------------------------------------------------------
function Read-DataRaw {
  $enc = New-Object System.Text.UTF8Encoding($false)
  return [System.IO.File]::ReadAllText($DataFile, $enc)
}
function Write-DataRaw($text) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($DataFile, $text, $enc)
}

# entries cua 1 chu de: id + name (block gan dang "  <key>: [" ... "  ],").
function Get-Entries($key) {
  $raw = Read-DataRaw
  $lines = $raw -replace "`r`n", "`n" -split "`n"
  $inArr = $false
  $res = New-Object System.Collections.Generic.List[object]
  $kstart = '^  ' + [regex]::Escape($key) + ': \['
  foreach ($l in $lines) {
    if ($l -match $kstart) { $inArr = $true; continue }
    if ($inArr -and $l -match '^  \],?$') { $inArr = $false; continue }
    if ($inArr) {
      # dung ca 2 dang entry: co dong rieng (enemies) va mot dong (statuses/items)
      $mi = [regex]::Match($l, "^[{}\s]+id: '([^']+)',\s+name: '(.+?)',")
      if ($mi.Success) {
        $res.Add([pscustomobject]@{ id = $mi.Groups[1].Value; name = $mi.Groups[2].Value })
      }
    }
  }
  # KHONG dung `return , $res`: trong pwsh, tostring/context nhu `@(...).Count`
  # bi loi "Argument types do not match"; tra ve List thuan thi .Count OK.
  return $res
}

# Phan tich block sources: tra ve $map[$parent][$id] = $title, ho tro 2 chieu
# sau (areaCells > tung khu > tung o, id luu dang 'khu/o' de tranh trung cell).
function Get-SourcesAll {
  $raw = Read-DataRaw
  $s = $raw.IndexOf('  sources: {')
  if ($s -lt 0) { throw 'khong tim thay block sources trong data.js' }
  $e = $raw.IndexOf("`n  },", $s)
  if ($e -lt 0) { throw 'khong tim thay dong ket block sources' }
  $lines = $raw.Substring($s, $e - $s).Replace("`r`n", "`n") -split "`n"
  $map = @{}
  $parent = $null
  $sub = $null
  foreach ($l in $lines) {
    # level 1: "    enemies: {"
    if ($l -match '^    (\w+): \{$') {
      $parent = $Matches[1]
      $sub = $null
      if (-not $map.ContainsKey($parent)) { $map[$parent] = @{} }
      continue
    }
    # level 2 cua areaCells: "      'frozen-valley': {"
    if ($l -match "^      '([^']+?)': \{$") {
      $sub = $Matches[1] -replace "\\'", "'"
      continue
    }
    # cap pair: "'"id"': "'"title"',"
    $m = [regex]::Match($l, "^\s+'([^']+?)':\s*'((?:[^']|\\')*?)',?\s*$")
    if ($m.Success) {
      $id = ($m.Groups[1].Value -replace "\\'", "'")
      $val = ($m.Groups[2].Value -replace "\\'", "'")
      $bucket = $parent
      if ($parent -eq 'areaCells' -and $sub) {
        $id = $sub + '/' + $id
      }
      if (-not $map.ContainsKey($bucket)) { $map[$bucket] = @{} }
      $map[$bucket][$id] = $val
    }
  }
  return $map
}

# vi tri block sources trong raw: return @(start, endExclusive)
# endExclusive = vi tri ket thuc sau bo ket "\n  }," (5 ky tu: `\n`,2 space, `}`, `,`)
function Get-SourcesBounds($raw) {
  $s = $raw.IndexOf('  sources: {')
  if ($s -lt 0) { return @(-1, -1) }
  $e = $raw.IndexOf("`n  },", $s)
  if ($e -lt 0) { return @($s, $raw.Length) }
  return @($s, $e + 5)
}

# ---------------------------------------------------------------------------
# fandom API helpers
# ---------------------------------------------------------------------------
function Invoke-FandomApi($query) {
  $url = $script:API + '?' + $query
  $resp = Invoke-WebRequest -Uri $url -Headers @{ Referer = $script:Referer } `
    -UserAgent $script:UA -UseBasicParsing
  return ($resp.Content | ConvertFrom-Json)
}

# Ton tai + trang chinh quyw (redirects=1) cho mot loat title, bo 40/luot.
# Tra ve hashtable key = title (lower) -> @{ exists = bool; canonical = '...' }.
function Get-TitlesStatus($titles) {
  $result = @{}
  for ($i = 0; $i -lt @($titles).Count; $i += $script:BATCH) {
    $end = [Math]::Min($i + $script:BATCH - 1, @($titles).Count - 1)
    $batch = @(@($titles)[$i..$end])
    $tp = ($batch | ForEach-Object { [uri]::EscapeDataString($_) }) -join '|'
    $j = Invoke-FandomApi ('action=query&format=json&redirects=1&titles=' + $tp)
    if ($i -gt 0) { Start-Sleep -Milliseconds $script:DELAY_MS }
    if ($null -ne $j.query.redirects) {
      foreach ($r in @($j.query.redirects)) {
        $result[$r.from.ToLower()] = @{ exists = $true; canonical = $r.to }
      }
    }
    foreach ($p in $j.query.pages.PSObject.Properties.Value) {
      $result[$p.title.ToLower()] = @{ exists = ($null -ne $p.pageid); canonical = $p.title }
    }
  }
  return $result
}

# Liet ke trang ga'n template (embeddedin) - so trang foe hien nay (~215)
# nam trong 1 phan tra ve (eilimit=500), khong can phan trang.
function Get-EmbeddedPages($templateTitle) {
  $j = Invoke-FandomApi ('action=query&format=json&list=embeddedin&eititle=' + [uri]::EscapeDataString($templateTitle) + '&eilimit=500&einamespace=0')
  $res = @()
  foreach ($p in @($j.query.embeddedin)) { $res += $p.title }
  # `, @($res)`: bao mang mot lop de khong bi unroll thanh 1 chuoi khi ke qua it
  return , @($res)
}

function Get-WikiText($page) {
  $j = Invoke-FandomApi ('action=parse&format=json&page=' + [uri]::EscapeDataString($page) + '&prop=wikitext')
  if (-not ($j.parse)) { return $null }
  return $j.parse.wikitext.'*'
}

# ---------------------------------------------------------------------------
# chuan ten: bo duoi "(foe)"/"(item)"/"(status)"/"(EBF5)"/"(EBF5 boss)"...
# bo suffix ngoac chua ky tu non-ASCII (trang ban ngon khac, vd
# 'Neon Valhalla' + suffix CJK voi ngoac full-width), ve lower + gop khoang.
# File .ps1 giu ASCII: ky tu ngoac full-width xu ly bang ma [char] 0xFF08/0xFF09.
# ---------------------------------------------------------------------------
function Strip-ParensSuffix($x) {
  $openA  = [char]0x28;   $closeA  = [char]0x29
  $openF  = [char]0xFF08; $closeF  = [char]0xFF09
  while ($x.Length -gt 0) {
    $last = $x[$x.Length - 1]
    if ($last -ne $closeA -and $last -ne $closeF) { break }
    $depth = 0; $idx = -1
    for ($i = $x.Length - 1; $i -ge 0; $i--) {
      $c = $x[$i]
      if ($c -eq $closeA -or $c -eq $closeF) { $depth++ }
      elseif ($c -eq $openA -or $c -eq $openF) {
        $depth--
        if ($depth -eq 0) { $idx = $i; break }
      }
    }
    if ($idx -lt 0) { break }
    $inner = $x.Substring($idx + 1, $x.Length - $idx - 2)
    if ($inner.Length -gt 0 -and ($inner -match '[^\x00-\x7F]')) {
      $x = $x.Substring(0, $idx).TrimEnd()
      continue
    }
    break
  }
  return $x
}

function Norm-WikiName($s) {
  if (-not $s) { return '' }
  $x = Strip-ParensSuffix $s.Trim()
  while ($true) {
    $y = $x -replace '\s*\((?:EBF5 ?boss|EBF5|foe|item|status)\)$', ''
    $y = $y -replace '\s*\(boss\)$', ''
    if ($y -eq $x) { break }
    $x = $y
  }
  $x = ($x -replace '\s+', ' ').Trim()
  return $x.ToLowerInvariant()
}

# ---------------------------------------------------------------------------
# MODE enemies
# ---------------------------------------------------------------------------
function Invoke-CheckEnemies {
  Write-Section 'ENEMIES - trang foe co FoeTableEBF5 tren wiki vs data.js'
  $entries = Get-Entries 'enemies'
  if (@($entries).Count -eq 0) { Write-Err '  khong doc duoc entries enemies trong data.js'; return $null }
  Write-Host ("  entries trong data.js: {0}" -f @($entries).Count)

  # map norm-name -> entry id (tu ten entry va tu sources.enemies)
  $pageOf = @{}
  foreach ($o in @($entries)) {
    $kn = Norm-WikiName $o.name
    if (-not $pageOf.ContainsKey($kn)) { $pageOf[$kn] = $o.id }
  }
  $src = Get-SourcesAll
  if ($src.ContainsKey('enemies')) {
    foreach ($eid in @($src['enemies'].Keys)) {
      $kn = Norm-WikiName $src['enemies'][$eid]
      if (-not $pageOf.ContainsKey($kn)) { $pageOf[$kn] = $eid }
    }
  }

  $pages = Get-EmbeddedPages 'Template:FoeTableEBF5'
  Write-Host ("  trang foe tren wiki (embedded): {0}" -f $pages.Count)

  $covered = 0
  $newPages = @()
  $excluded = @()
  foreach ($pg in $pages) {
    $kn = Norm-WikiName $pg
    if (-not $kn) { $excluded += $pg; continue }
    if ($pageOf.ContainsKey($kn)) { $covered++ } else { $newPages += $pg }
  }
  foreach ($pg in $newPages) { Write-Bad ("  [NEW] trang foe chua co entry: {0}" -f $pg) }
  foreach ($pg in $excluded) { Write-Dim ("  [BO QUA] trang ngon ngu khac (foreign-lang): {0}" -f $pg) }
  Write-Host ("  KQ: phu {0}/{1} (bo qua {2}) | moi {3}" -f $covered, $pages.Count, $excluded.Count, @($newPages).Count)
  if (@($newPages).Count -eq 0) { Write-Ok '  [OK] bo enemies da phu tat ca trang foe hien tai' }
  return [pscustomobject]@{ new = @($newPages); total = $pages.Count; matched = $covered; excluded = @($excluded) }
}

# ---------------------------------------------------------------------------
# MODE statuses - heading co 'EBF5 Status' tren trang Status Effects
# ---------------------------------------------------------------------------
function Invoke-CheckStatuses {
  Write-Section 'STATUS - trang Status Effects vs data.js'
  $src = Get-SourcesAll
  if (-not ($src.ContainsKey('statuses')) -or @($src['statuses'].Keys).Count -eq 0) {
    Write-Err '  sources.statuses trong data.js khong co title nao'
    return $null
  }
  $srcStatuses = $src['statuses']
  Write-Host ("  entries trong sources.statuses: {0}" -f @($srcStatuses.Keys).Count)
  $entries = Get-Entries 'statuses'
  Write-Host ("  entries trong data.js statuses: {0}" -f @($entries).Count)

  $txt = Get-WikiText 'Status Effects'
  if (-not $txt) { Write-Err '  khong tai duoc trang Status Effects'; return $null }

  $names = @()
  $lines = $txt.Replace("`r`n", "`n") -split "`n"
  $cur = ''; $curHasEBF5 = $false
  foreach ($l in $lines) {
    if ($l -match '^===') {
      if ($cur -and $curHasEBF5) { $names += $cur }
      $cur = ''; $curHasEBF5 = $false
      $h = $l.Trim('=', ' ')
      $m = [regex]::Match($h, '\{\{s\|([^|}]+)\}\}')
      if ($m.Success) {
        $cur = $m.Groups[1].Value.Trim()
      } else {
        $h2 = ($h -replace "^'''\s*", '')
        $h2 = (($h2 -split '\(')[0]).Trim()
        # bo dau ' con du o 2 dau ten (heading co the la '''Ten''' (rc))
        $h2 = $h2.Trim(' ', "'")
        $cur = $h2
      }
    } elseif ($cur) {
      if ($l -match 'EBF5 Status') { $curHasEBF5 = $true }
    }
  }
  if ($cur -and $curHasEBF5) { $names += $cur }

  Write-Host ("  status co icon EBF5 tren wiki: {0}" -f @($names).Count)
  $wikiSet = @{}
  foreach ($n in @($names)) {
    $k = Norm-WikiName $n
    if (-not $wikiSet.ContainsKey($k)) { $wikiSet[$k] = $n }
  }
  $ourSet = @{}
  foreach ($sid in @($srcStatuses.Keys)) {
    # 1) nom theo title per-entry
    $k = Norm-WikiName $srcStatuses[$sid]
    if (-not $ourSet.ContainsKey($k)) { $ourSet[$k] = $sid }
    # 2) nom theo id (san sang voi heading wiki: 'Epic', 'Stoned'... la
    #    nhung status khong co trang rieng, dung _default 'Status Effects')
    $k2 = Norm-WikiName $sid
    if (-not $ourSet.ContainsKey($k2)) { $ourSet[$k2] = $sid }
  }
  foreach ($o in @($entries)) {
    $k2 = Norm-WikiName ($o.id -replace '-', ' ')
    if (-not $ourSet.ContainsKey($k2)) { $ourSet[$k2] = $o.id }
  }
  $newOnes = @()
  foreach ($k in $wikiSet.Keys) {
    if (-not $ourSet.ContainsKey($k)) {
      $newOnes += $wikiSet[$k]
      Write-Bad ("  [NEW] status chua co entry: {0}" -f $wikiSet[$k])
    }
  }
  if (@($newOnes).Count -eq 0) { Write-Ok '  [OK] statuses da phu het trang Status Effects (EBF5)' }
  Write-Host ("  KQ: muc moi {0}" -f @($newOnes).Count)
  return [pscustomobject]@{ new = @($newOnes); total = @($wikiSet.Keys).Count }
}

# ---------------------------------------------------------------------------
# MODE items - trang Food: anchor <span id="5<Ten>"></span> = item EBF5
# ---------------------------------------------------------------------------
function Invoke-CheckItems {
  Write-Section 'ITEMS - trang Food (anchor 5<Ten>) vs data.js'
  $src = Get-SourcesAll
  if (-not ($src.ContainsKey('items'))) { Write-Err '  sources.items khong co'; return $null }
  $srcItems = $src['items']
  $entries = Get-Entries 'items'

  $txt = Get-WikiText 'Food'
  if (-not $txt) { Write-Err '  khong tai duoc trang Food'; return $null }
  $names = @()
  foreach ($m in ([regex]::Matches($txt, '<span id="5([A-Za-z0-9 ''?\.\-]+)"></span>'))) {
    $n = $m.Groups[1].Value.Trim()
    if ($n.Length -gt 0) { $names += $n }
  }
  $names = @($names | Sort-Object -Unique)
  Write-Host ("  item tren trang Food (anchor 5X): {0}" -f $names.Count)

  $wikiSet = @{}
  foreach ($n in $names) {
    $k = Norm-WikiName $n
    if (-not $wikiSet.ContainsKey($k)) { $wikiSet[$k] = $n }
  }
  $ourSet = @{}
  foreach ($id in @($srcItems.Keys)) {
    if ($id -eq '_default') { continue }
    $k = Norm-WikiName $srcItems[$id]
    if (-not $ourSet.ContainsKey($k)) { $ourSet[$k] = $id }
  }
  # them theo id entry: item duoc _default 'Food' phu (khong co pair per-entry)
  foreach ($o in @($entries)) {
    $k2 = Norm-WikiName ($o.id -replace '-', ' ')
    if (-not $ourSet.ContainsKey($k2)) { $ourSet[$k2] = $o.id }
  }
  $newOnes = @()
  foreach ($k in $wikiSet.Keys) {
    if (-not $ourSet.ContainsKey($k)) {
      $newOnes += $wikiSet[$k]
      Write-Bad ("  [NEW] item chua co entry: {0}" -f $wikiSet[$k])
    }
  }
  if (@($newOnes).Count -eq 0) { Write-Ok '  [OK] items da phu bo Food EBF5' }
  Write-Host ("  KQ: item moi {0}" -f $newOnes.Count)
  return [pscustomobject]@{ new = $newOnes; total = $names.Count }
}

# ---------------------------------------------------------------------------
# MODE sources - kiem tra title per-entry trong sources.* co tren wiki;
# -Fix tu sua cho moi chu de:
#   key `enemies`: chon lai trang goc bang so khop norm voi danh sach
#       trang da gan FoeTableEBF5 (vi du 'God (foe)' -> 'God (EBF5 boss)',
#       'Sand Worm (foe)' -> 'Sand Worm').
#   key khac  : thu ung cu vien bo duoi '(foe)'/'(item)'/'(status)'/
#       '(EBF5)' -> lay trang chinh thuc qua redirect; con kho chon thi
#       dung trang _default cua chu de (Food, Status Effects...);
#       khong co gi hop le -> UNFIX (sua thu cong).
# Moi pair chi duoc thay khi xuat hien DUY NHAT trong block sources.
# ---------------------------------------------------------------------------
function Invoke-CheckSources {
  Write-Section 'SOURCES - title trong sources.* vs wiki'
  $src = Get-SourcesAll

  # thu title per-entry cua TAT CA cac chu de (bo _default)
  $targets = @()
  foreach ($k in @($src.Keys)) {
    foreach ($id in @($src[$k].Keys)) {
      if ($id -eq '_default') { continue }
      $targets += [pscustomobject]@{ key = $k; id = $id; title = $src[$k][$id] }
    }
  }
  if (@($targets).Count -eq 0) { Write-Err '  khong co title can kiem'; return 2 }

  $titles = @(@($targets) | ForEach-Object { $_.title } | Sort-Object -Unique)
  Write-Host ("  kiem {0} title (bo _default)" -f $titles.Count)
  $status = Get-TitlesStatus $titles

  $stale = @()
  foreach ($t in @($targets)) {
    $st = $status[$t.title.ToLower()]
    if ($st -and $st.exists) { continue }
    $stale += $t
  }
  Write-Host ("  title stale: {0}/{1}" -f @($stale).Count, @($targets).Count)
  foreach ($s in $stale) {
    Write-Bad ("  [STALE] {0}:{1} -> '{2}'" -f $s.key, $s.id, $s.title)
  }

  $fixed = 0; $unfixed = 0
  if (@($stale).Count -gt 0 -and $Fix) {
    Write-Section 'FIX - thay title stale trong data.js'

    # ban do norm -> trang, tu danh sach trang foe that (da gan FoeTableEBF5)
    $normToPage = @{}
    $embPages = Get-EmbeddedPages 'Template:FoeTableEBF5'
    foreach ($pg in $embPages) {
      $nk = Norm-WikiName $pg
      if ($nk -and (-not $normToPage.ContainsKey($nk))) { $normToPage[$nk] = $pg }
    }

    # ung cu vien cho key khac (nen tren transforms co co so)
    $candList = @{}
    foreach ($s in $stale) {
      $cs = @()
      $c1 = $s.title -replace '\s*\((foe|item|status|EBF5)\)$', ''
      if ($c1 -ne $s.title) { $cs += $c1 }
      $c1b = $c1 -replace '\s*\(boss\)$', ''
      if ($c1b -ne $c1) { $cs += $c1b }
      $c2 = $c1b -replace '\s*\(EBF5 boss\)$', ''
      if ($c2 -ne $c1b) { $cs += $c2 }
      $candList[$s.title] = @($cs | Select-Object -Unique)
    }
    $allCands = @($candList.Keys | ForEach-Object { $candList[$_] } | Sort-Object -Unique)
    $candStatus = Get-TitlesStatus $allCands

    $raw = Read-DataRaw
    $bounds = Get-SourcesBounds $raw
    $slice = $raw.Substring($bounds[0], $bounds[1] - $bounds[0])
    $newSlice = $slice
    foreach ($s in $stale) {
      $chosen = ''
      if ($s.key -eq 'enemies') {
        # trang foe that (ganz FoeTableEBF5) la chuan khi theo norm
        $kn = Norm-WikiName $s.title
        if ($normToPage.ContainsKey($kn)) { $chosen = $normToPage[$kn] }
      }
      if (-not $chosen) {
        foreach ($c in $candList[$s.title]) {
          $st = $candStatus[$c.ToLower()]
          if ($st -and $st.exists) { $chosen = $st.canonical; break }
        }
      }
      if (-not $chosen) {
        # fallback: trang _default cung chu de (Food, Status Effects...)
        if ($src.ContainsKey($s.key) -and $src[$s.key].ContainsKey('_default')) {
          $chosen = $src[$s.key]['_default']
          Write-Dim ("  [DEFAULT] {0} '{1}' -> dung trang {2}" -f $s.id, $s.title, $chosen)
        }
      }
      if (-not $chosen) {
        $unfixed++
        Write-Err ("  [UNFIX] {0} ({1}) '{2}' - khong co ung cu vien ton tai" -f $s.id, $s.key, $s.title)
        continue
      }
      $escId  = ($s.id  -replace "'", "\'")
      $escOld = ($s.title -replace "'", "\'")
      $escNew = ($chosen -replace "'", "\'")
      $search = "'" + $escId + "': '" + $escOld + "'"
      $repl   = "'" + $escId + "': '" + $escNew + "'"
      $cnt = [regex]::Matches($newSlice, [regex]::Escape($search)).Count
      if ($cnt -eq 1) {
        $newSlice = $newSlice.Replace($search, $repl)
        $fixed++
        Write-Ok ("  [FIX] {0} '{1}' -> '{2}'" -f $s.id, $s.title, $chosen)
      } elseif ($cnt -gt 1) {
        $unfixed++
        Write-Err ("  [UNFIX] {0} - pair xuat hien nhieu lan ({1}) trong sources" -f $s.id, $cnt)
      } else {
        $unfixed++
        Write-Err ("  [UNFIX] {0} - khong tim thay pair trong sources block" -f $s.id)
      }
    }
    if ($fixed -gt 0) {
      $newRaw = $raw.Replace($slice, $newSlice)
      Write-DataRaw $newRaw
      Write-Ok ("  da ghi cap nhat vao {0}" -f $DataFile)
    }
    Write-Host ("  KQ FIX: fixed {0}; can sua thu cong {1}; unfixed {2}" -f $fixed, (@($stale).Count - $fixed - $unfixed), $unfixed)
  } elseif (@($stale).Count -gt 0) {
    Write-Bad '  (chay lai voi -Fix de tu sua title stale co the)'
  }
  Write-Host ("  KQ sources: stale {0} | fixed {1} | unfixed {2}" -f @($stale).Count, $fixed, $unfixed)
  if (@($stale).Count -gt 0) { return 1 } else { return 0 }
}

# ---------------------------------------------------------------------------
# MODE areas - o luoi khu vuc (luot 27)
# ---------------------------------------------------------------------------
# Nguon: cac trang wiki "Epic Battle Fantasy 5 Map/<GR> <Ten khu>" (allpages,
# ~303 trang). Moi trang la 1 o lon tren ban do: <GR> = vi tri luoi (kieu D0),
# phan sau la ten khu. Trang co bang "Foes" (wave chien dau) hoac "Treasures"
# co Key Items = o CO NOI DUNG; trang chi co "Exits" la o RONG, bo qua co
# chu dich (dung metric "o co noi dung", khong them 93 o rong vao data.js).
# Doi chieu voi areas.cells trong data.js; -Fix tu:
#   1) them cell 'foes'/'keys' thieu vao entry khu (dong voi style khu khac),
#   2) them khoi "      '<id khu>': { 'D0': 'Epic Battle Fantasy 5 Map/...' }"
#      vao sources.areaCells (dung khop 2 chieu; check.ps1 section 8 kiem).
# Chi so sanh 18 khu chinh (ten trang == name trong data.js). Trang khu con
# (20 Medals Room, Food Shop...) khong khop ten khu nen bo qua - cong don khu
# con de danh buoc sau (Arcade Room, Medals Rooms, basement, cottage...).
# Chu y: dau ' trong ten foe/pham phai escape thanh \' khi ghi vao data.js.
# ---------------------------------------------------------------------------

function Esc-DataJs($s) {
  # chi escape dau ' (van ban wiki khong chua '\' nen khong can escape them)
  return ("$s").Replace("'", "\'")
}

function Clean-CellText($raw) {
  # don dep text 1 o bang wikitext -> text data.js: bo chu/nghieng (''' ),
  # link [[a|b]] -> b, <br /> -> phan tach wave, rut gon khoang trang.
  if ($null -eq $raw) { return '' }
  $x = "$raw"
  $x = $x -replace "''+", ''
  $x = $x -replace '<br\s*/?\s*>', ', '
  $x = $x -replace '\[\[[^\]]*?\|([^\]]*?)\]\]', '$1'
  $x = $x -replace '\[\[([^\]]*?)\]\]', '$1'
  $x = $x -replace '\s+', ' '
  $x = $x -replace '^[\s,]+', ''
  $x = $x -replace '[\s,]+$', ''
  return $x
}

function Split-TableRows($body) {
  # dau vao: noi dung bang wikitext (sau dong "{| ..." truoc "|}")
  # dau ra : mang; moi phan tu la mang cac o text cua 1 row (phan cach "|-")
  $rows = New-Object System.Collections.Generic.List[object]
  foreach ($chunk in ($body -split '(?m)^\|\-[ \t]*$')) {
    $ms = [regex]::Matches($chunk, '(?m)^\|(.*)$')
    if ($ms.Count -gt 0) {
      $cells = @()
      foreach ($m in $ms) { $cells += $m.Groups[1].Value }
      $rows.Add($cells)
    }
  }
  return $rows
}

function Get-AllMapTitles {
  # tat ca trang con cua "Epic Battle Fantasy 5 Map/" (allpages + continue)
  $res = @()
  $cont = $null
  do {
    $q = 'action=query&format=json&list=allpages&aplimit=500&apprefix=' + [uri]::EscapeDataString('Epic Battle Fantasy 5 Map/')
    if ($cont) { $q += '&apcontinue=' + [uri]::EscapeDataString($cont) }
    $j = Invoke-FandomApi $q
    foreach ($p in @($j.query.allpages)) { $res += $p.title }
    if ($j.continue -and $j.continue.apcontinue) { $cont = $j.continue.apcontinue } else { $cont = $null }
    Start-Sleep -Milliseconds $script:DELAY_MS
  } while ($cont)
  Write-Host ("  trang map tren wiki (allpages): {0}" -f @($res).Count)
  return , @($res)
}

function Get-MapPagesContent($titles) {
  # fetch wikitext theo nhom 20 title/lan de URL vua du; tra ve hashtable
  # title -> wikitext (null neu trang khong co revision nao)
  $res = @{}
  for ($i = 0; $i -lt @($titles).Count; $i += 20) {
    $end = [Math]::Min($i + 19, @($titles).Count - 1)
    $batch = @(@($titles)[$i..$end])
    $tp = ($batch | ForEach-Object { [uri]::EscapeDataString($_) }) -join '|'
    $j = Invoke-FandomApi ('action=query&format=json&redirects=1&prop=revisions&rvprop=content&rvslots=main&titles=' + $tp)
    if ($j.query.pages -is [array]) { $plist = @($j.query.pages) }
    else { $plist = @($j.query.pages.PSObject.Properties.Value) }
    foreach ($pg in $plist) {
      $txt = $null
      if ($pg.revisions -and @($pg.revisions).Count -gt 0) { $txt = $pg.revisions[0].slots.main.'*' }
      $res[$pg.title] = $txt
    }
    if ($i -gt 0) { Start-Sleep -Milliseconds $script:DELAY_MS }
  }
  return $res
}

function Get-MapPageRows($wikitext) {
  # tra ve 2 danh sach row co noi dung cua 1 trang map:
  #   foe = "<coord> - <cac wave, phan tach ' / '>"
  #   key = "<coord> - <ten Key Items, phan tach ', '>"
  $foeList = New-Object System.Collections.Generic.List[string]
  $keyList = New-Object System.Collections.Generic.List[string]
  if (-not $wikitext) {
    return [pscustomobject]@{ foe = $foeList; key = $keyList }
  }
  foreach ($t in [regex]::Matches($wikitext, '(?s)\{\| class="article-table"[^\r\n]*\r?\n(.*?)\r?\n\|\}')) {
    $body = $t.Groups[1].Value
    $head = [regex]::Match($body, '(?m)^![^\r\n]*').Value
    if (-not $head) { continue }
    $rows = Split-TableRows $body
    foreach ($r in $rows) {
      if (@($r).Count -lt 2) { continue }
      $coord = (@($r)[0]).Trim()
      if ($coord -notmatch '^[A-Z] ?\d{1,2}$') { continue }
      if ($head -match 'Foes') {
        $waves = @()
        for ($i = 1; $i -lt @($r).Count; $i++) {
          $v = Clean-CellText (@($r)[$i])
          if ($v) { $waves += $v }
        }
        if ($waves.Count -gt 0) {
          $foeList.Add("$coord - " + ($waves -join ' / '))
        }
      }
      elseif ($head -match 'Treasures') {
        # CHI nhan row co Key Items that ([[Key Items#...]]); cac row chi co
        # vat lieu/food thi khong tinh la noi dung (data.js keys theo quy uoc
        # chi luu Key Items, khong luu drop vat lieu).
        $names = @()
        for ($i = 1; $i -lt @($r).Count; $i++) {
          $km = [regex]::Matches((@($r)[$i]), '\[\[Key Items#([^\]\|]*)(?:\|([^\]]*))?\]\]')
          foreach ($k in $km) {
            $nm = $k.Groups[2].Value
            if (-not $nm) { $nm = $k.Groups[1].Value }
            if ($nm) { $names += $nm.Trim() }
          }
        }
        if ($names.Count -gt 0) {
          $keyList.Add("$coord - " + (($names | Select-Object -Unique) -join ', '))
        }
      }
    }
  }
  return [pscustomobject]@{ foe = $foeList; key = $keyList }
}

function Parse-ArrText($inner) {
  # tach "[ 'a', 'b' ]" (phan trong ngoac) thanh mang cac chuoi (unescape \')
  if (-not $inner) { return @() }
  $res = @()
  foreach ($p in ($inner -split "',\s*'")) {
    $s = $p.Trim()
    if ($s.StartsWith("'")) { $s = $s.Substring(1) }
    if ($s.EndsWith("'")) { $s = $s.Substring(0, $s.Length - 1) }
    if ($s) { $res += ($s -replace "\\'", "'") }
  }
  return @($res)
}

function Get-AreasInfo($raw) {
  # doc block "  areas: [" trong data.js. Moi khu: @{ id; name; kind; parent; open; cells }
  # - kind/parent = 'Khu con' + khu me (entry chinh de trong)
  # - open  = khu co dong '    cells: [' hay khong
  # - cells = hashtable grid -> @{ lineIdx; hasFoes; hasKeys; keysText }
  #           (lineIdx tinh theo dong cua rieng block areas)
  $s = $raw.IndexOf('  areas: [')
  if ($s -lt 0) { throw 'khong tim thay block areas trong data.js' }
  $mEnd = [regex]::Match($raw.Substring($s), '\r?\n  \],')
  if (-not $mEnd.Success) { throw 'khong tim thay dong ket block areas' }
  $absEnd = $s + $mEnd.Index
  $seg = $raw.Substring($s, $absEnd - $s)
  $lines = $seg -split "`n"
  $list = @()
  $cur = $null
  for ($li = 0; $li -lt $lines.Count; $li++) {
    $l = ($lines[$li]).TrimEnd("`r")
    $mA = [regex]::Match($l, "^\s*\{ id: '([^']+)', name: (.+?), kind: ")
    if ($mA.Success) {
      if ($cur) { $list = @($list) + @($cur) }
      $nm = $mA.Groups[2].Value
      # name co the la '...' hoac "..." (vi du: "No Man's Land" co dau ')
      $nm = $nm.Trim()
      if (($nm.StartsWith("'") -and $nm.EndsWith("'")) -or ($nm.StartsWith('"') -and $nm.EndsWith('"'))) {
        $nm = $nm.Substring(1, $nm.Length - 2)
      }
      $cur = [pscustomobject]@{
        id     = $mA.Groups[1].Value
        name   = $nm
        kind   = [regex]::Match($l, "kind: '([^']+)'").Groups[1].Value
        parent = [regex]::Match($l, "parent: '([^']+)'").Groups[1].Value
        open   = $false
        cells  = @{}
      }
      continue
    }
    if ($l -match '^    cells: \[') { if ($cur) { $cur.open = $true }; continue }
    $mc = [regex]::Match($l, "^\s*\{ grid: '([A-Z]\d{1,2})'")
    if ($mc.Success -and $cur) {
      $cur.cells[$mc.Groups[1].Value] = [pscustomobject]@{
        lineIdx  = $li
        hasFoes  = ($l -match '\bfoes: \[')
        hasKeys  = ($l -match '\bkeys: \[')
        keysText = (([regex]::Match($l, 'keys: \[([^\]]*)\]').Groups[1].Value) -replace "\\'", "'")
        foesList = @(Parse-ArrText ([regex]::Match($l, 'foes: \[([^\]]*)\]').Groups[1].Value))
        keysList = @(Parse-ArrText ([regex]::Match($l, 'keys: \[([^\]]*)\]').Groups[1].Value))
      }
    }
  }
  if ($cur) { $list = @($list) + @($cur) }
  return @{ list = $list; seg = $seg; segStart = $s; absEnd = $absEnd }
}

function Sort-Grids($grids) {
  # sap "D0","D1","I9","C15"...: chu cai tang roi so tang dan
  # Dung List[str] de tranh loi PS: return mang 1 phan tu se bi unroll thanh
  # 1 chuoi (~ tuong tu ghi chu ben duoi Get-Entries), khi do $sorted[$i] la
  # 1 KY TU thay vi toan chuoi grid.
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($g in @($grids | Sort-Object -Property @{ e = { $_.Substring(0, 1) } }, @{ e = { [int]$_.Substring(1) } })) {
    $out.Add([string]$g)
  }
  return $out
}

function New-AreaCellLine($grid, $foes, $keys, $crlf) {
  # mot dong cell moi: "        { grid: 'D0', foes: [...], keys: [...] }"
  # $crlf = true neu vung data.js quanh cho chen la CRLF (them \r cuoi dong)
  $parts = @()
  if (@($foes).Count -gt 0) {
    $arr = (@($foes) | ForEach-Object { "'" + (Esc-DataJs $_) + "'" }) -join ', '
    $parts += ('foes: [' + $arr + ']')
  }
  if (@($keys).Count -gt 0) {
    $arr = (@($keys) | ForEach-Object { "'" + (Esc-DataJs $_) + "'" }) -join ', '
    $parts += ('keys: [' + $arr + ']')
  }
  $txt = "        { grid: '$grid', " + ($parts -join ', ') + ' }'
  if ($crlf) { $txt += "`r" }
  return $txt
}

# Doi ket "Tep \n      }" -> tim dong ket khoi con CUOI CUNG truoc dong ket
# areaCells "\n    }" (dung cho ca 2 truong hop chen mapping). Tra ve vi tri
# bat dau cua "\n      }" do (index cua \n), hay -1 neu khong tim thay.
function Find-LastAreaCellsBlockClose($raw, $clAbs) {
  return $raw.LastIndexOf("`n      }", $clAbs - 1)
}

# Xac dinh EOL tai vi tri chen: $idx = index cua \n bat dau doan "\n...".
function Get-EolAt($raw, $idx) {
  if ($idx -gt 0 -and $raw[$idx - 1] -eq [char]13) { return "`r`n" }
  return "`n"
}

# Kiem tra cau truoc ngoac/bracket ben ngoau string & comment (bo qua string,
# '...', /*...*/ va //...). Tra ve $true neu hop le (dung cap, khong thua).
# Khi $Diag la [ref] (mang string) thi gui kem vi tri + doan phan hong dau tien.
function Test-Brackets($text, $Diag) {
  $st = New-Object System.Collections.Generic.List[char]
  $stPos = New-Object System.Collections.Generic.List[int]
  $inDq = $false; $inSq = $false; $inBlock = $false; $inLine = $false
  $prev = [char]0
  for ($i = 0; $i -lt $text.Length; $i++) {
    $c = $text[$i]
    if ($inLine) { if ($c -eq [char]10) { $inLine = $false }; continue }
    if ($inBlock) { if ($c -eq '*' -and $i + 1 -lt $text.Length -and $text[$i + 1] -eq '/') { $inBlock = $false }; continue }
    if ($inDq) {
      if ($prev -eq [char]92) { $prev = $c; continue }
      if ($c -eq [char]92) { $prev = [char]92; continue }
      if ($c -eq '"') { $inDq = $false }
      $prev = $c; continue
    }
    if ($inSq) {
      if ($prev -eq [char]92) { $prev = $c; continue }
      if ($c -eq [char]92) { $prev = [char]92; continue }
      if ($c -eq "'") { $inSq = $false }
      $prev = $c; continue
    }
    if ($c -eq '/' -and $i + 1 -lt $text.Length) {
      $n = $text[$i + 1]
      if ($n -eq '*') { $inBlock = $true; $prev = [char]0; continue }
      if ($n -eq '/') { $inLine = $true; $prev = [char]0; continue }
    }
    if ($c -eq '{' -or $c -eq '[') { $st.Add($c); $stPos.Add($i); $prev = $c; continue }
    if ($c -eq '}' -or $c -eq ']') {
      $open = [char]0
      if ($st.Count -gt 0) { $open = $st[$st.Count - 1] }
      if (($c -eq '}' -and $open -ne '{') -or ($c -eq ']' -and $open -ne '[')) {
        if ($Diag) {
          $from = [Math]::Max(0, $i - 160)
          ($Diag.Value).Add(('khong khop tai pos ' + $i + ': ' + (($text.Substring($from, [Math]::Min(220, $text.Length - $from))).Replace("`r", '').Replace("`n", '|'))))
          if ($st.Count -gt 0) {
            ($Diag.Value).Add(('dang mo: ' + (($st | ForEach-Object { $_ }) -join ' ') + ' tai: ' + (($stPos | ForEach-Object { [Math]::Max(0, $_ - 90) } | ForEach-Object { $_ }) -join ', ')))
          }
        }
        return $false
      }
      if ($st.Count -gt 0) { $st.RemoveAt($st.Count - 1); $stPos.RemoveAt($stPos.Count - 1) }
      $prev = $c; continue
    }
    if ($c -eq '"') { $inDq = $true; $prev = $c; continue }
    if ($c -eq "'") { $inSq = $true; $prev = $c; continue }
    $prev = $c
  }
  if ($st.Count -gt 0 -and $Diag) {
    $last = $stPos[$stPos.Count - 1]
    ($Diag.Value).Add(('con ' + $st.Count + ' ngoac mo chua dong; cuoi cung tai pos ' + $last + ': ' + (($text.Substring([Math]::Max(0, $last - 100), [Math]::Min(140, $text.Length - $last))).Replace("`r", '').Replace("`n", '|'))))
  }
  return (($st.Count -eq 0) -and (-not $inDq) -and (-not $inSq) -and (-not $inBlock))
}

# Ap toan bo fix vao data.js (block areas + sources.areaCells), ghi file 1 lan.
#   $missing     : @(@{ id; grid; foes; keys })         - cell moi can them
#   $keyMissing  : @(@{ id; grid; texts = @('...') })   - key them vao cell co san
#   $pairMissing : @(@{ id; grid; name })               - cap thieu trong areaCells
# Tra ve so muc da ghi (0 = khong ghi gi).
function Apply-AreasFix($missing, $keyMissing, $pairMissing) {
  $nFix = 0
  $unfixed = 0
  $newRaw = $null
  if (@($missing).Count -eq 0 -and @($keyMissing).Count -eq 0 -and @($pairMissing).Count -eq 0) { return 0 }
  $raw = Read-DataRaw
  $info = Get-AreasInfo $raw
  $nameOf = @{}
  foreach ($a in @($info.list)) { $nameOf[$a.id] = $a.name }

  # ---------- 1) block areas: cells / keys ----------
  if ((@($missing).Count -gt 0) -or (@($keyMissing).Count -gt 0)) {
    $lines = New-Object 'System.Collections.Generic.List[string]'
    foreach ($l in ($info.seg -split "`n")) { $lines.Add($l) }

    # vi tri dong "{ id: ..." theo id (de xac dinh ranh gioi block tung khu)
    $areaLines = @{}
    for ($li = 0; $li -lt $lines.Count; $li++) {
      $m = [regex]::Match((($lines[$li]).TrimEnd("`r")), "^\s*\{ id: '([^']+)', name:")
      if ($m.Success) { $areaLines[$m.Groups[1].Value] = $li }
    }
    $ids = @($areaLines.Keys)

    $byArea = @{}
    foreach ($m in @($missing)) {
      if (-not $byArea.ContainsKey($m.id)) {
        $byArea[$m.id] = @{ cells = @(); keys = @() }
      }
      $byArea[$m.id].cells = @($byArea[$m.id].cells) + @($m)
    }
    foreach ($k in @($keyMissing)) {
      if (-not $byArea.ContainsKey($k.id)) {
        $byArea[$k.id] = @{ cells = @(); keys = @() }
      }
      $byArea[$k.id].keys = @($byArea[$k.id].keys) + @($k)
    }

    # ops chen: moi muc @{ at = vi tri chen trong $lines; txt = dong chen }
    # (ap tu CUOI len dau de cac vi tri chen khong bi doi)
    $ops = New-Object System.Collections.Generic.List[object]

    foreach ($aid in @($byArea.Keys)) {
      if (-not $areaLines.ContainsKey($aid)) {
        Write-Err ("  [UNFIX] khu '{0}' khong co trong block areas" -f $aid)
        $unfixed++
        continue
      }
      $aStart = $areaLines[$aid]
      $later = @($ids | Where-Object { $areaLines[$_] -gt $aStart })
      if ($later.Count -gt 0) {
        $mins = ($later | ForEach-Object { $areaLines[$_] }) | Measure-Object -Minimum
        $aEnd = $mins.Minimum
      } else {
        $aEnd = $lines.Count
      }
      $eolCr = (($lines[$aEnd - 1]).TrimEnd("`r")).Length -ne ($lines[$aEnd - 1]).Length

      # (a) key them vao cell co san: sua truc tiep dong do
      $fallbackCells = @()
      foreach ($k in @($byArea[$aid].keys)) {
        $found = $false
        for ($li = $aStart; $li -lt $aEnd; $li++) {
          $t = ($lines[$li]).TrimEnd("`r")
          if ($t -match ('^\s*\{ grid: ' + [regex]::Escape($k.grid) + ', ')) {
            $ent = "'" + (Esc-DataJs $k.texts) + "'"
            if ($t -match 'keys: \[') {
              $iB = $t.IndexOf('[', ($t.IndexOf('keys: ')))
              $lines[$li] = $t.Substring(0, $iB + 1) + $ent + ', ' + $t.Substring($iB + 1) + ($(if ($eolCr) { "`r" }))
            } else {
              $j = $t.LastIndexOf(' }')
              if ($j -lt 0) {
                Write-Err ("  [UNFIX] cell khu {0} o {1} khong co ' }' ket dong" -f $aid, $k.grid)
                $unfixed++
                break
              }
              $lines[$li] = $t.Substring(0, $j) + (", keys: [$ent] }") + ($(if ($eolCr) { "`r" }))
            }
            Write-Ok ("  [FIX] them key vao cell khu {0} o {1}" -f $aid, $k.grid)
            $nFix++
            $found = $true
            break
          }
        }
        if (-not $found) {
          # cell khong ton tai trong area -> bien thanh cell moi keys-only
          $fallbackCells += [pscustomobject]@{ id = $aid; grid = $k.grid; foes = @(); keys = @($k.texts) }
        }
      }

      # (b) cell moi (gop ca key-fallback)
      $cellItems = @($byArea[$aid].cells)
      foreach ($fb in $fallbackCells) {
        $ex = @($cellItems | Where-Object { $_.grid -eq $fb.grid })
        if ($ex.Count -gt 0) {
          $ex[0].keys = @($ex[0].keys) + @($fb.keys)
        } else {
          $cellItems = @($cellItems) + @($fb)
        }
      }
      if ($cellItems.Count -gt 0) {
        $cellsStart = -1
        $cellsClose = -1
        for ($li = $aStart; $li -lt $aEnd; $li++) {
          if ($cellsStart -lt 0) {
            if (($lines[$li]).TrimEnd("`r") -match '^    cells: \[') { $cellsStart = $li }
          } elseif (($lines[$li]).TrimEnd("`r") -match '^      \]') {
            $cellsClose = $li
            break
          }
        }
        $mapByGrid = @{}
        foreach ($c in $cellItems) {
          if (-not $mapByGrid.ContainsKey($c.grid)) { $mapByGrid[$c.grid] = $c }
          else { $g = $mapByGrid[$c.grid]; $g.foes = @($g.foes) + @($c.foes); $g.keys = @($g.keys) + @($c.keys) }
        }
        $entryTexts = @()
        foreach ($g in @(Sort-Grids @($mapByGrid.Keys))) {
          $entryTexts += (New-AreaCellLine $g $mapByGrid[$g].foes $mapByGrid[$g].keys $eolCr)
        }
        # moi entry CU TRU CHOT ' , ' truoc dong sau (style dung nhu khu khac)
        $withComma = @()
        for ($i = 0; $i -lt $entryTexts.Count; $i++) {
          if ($i -lt $entryTexts.Count - 1) {
            $withComma += (($entryTexts[$i]).TrimEnd("`r")) + ',' + ($(if ($eolCr) { "`r" }))
          } else {
            $withComma += $entryTexts[$i]
          }
        }
        $entryTexts = $withComma
        if (($cellsStart -ge 0) -and ($cellsClose -gt $cellsStart)) {
          # khu da co cells: phan tu cuoi hien tai phai them dau phay truoc khi chen
          $lastLi = $cellsClose - 1
          $t = ($lines[$lastLi]).TrimEnd("`r")
          if ($t.EndsWith(' }')) {
            $lines[$lastLi] = $t + ',' + ($(if (($lines[$lastLi]).EndsWith("`r")) { "`r" }))
          } elseif (-not $t.EndsWith(' },')) {
            Write-Err ("  [UNFIX] dong cuoi cells cua khu '{0}' le la: {1}" -f $aid, $t)
            $unfixed++
            continue
          }
          for ($i = 0; $i -lt $entryTexts.Count; $i++) {
            $ops.Add([pscustomobject]@{ at = $cellsClose; txt = $entryTexts[$i] })
          }
        } elseif ($cellsStart -lt 0) {
          # khu chua co cells: bien dong cuoi "... ] }" thanh "], cells:[...] }"
          $lastLi = $aEnd - 1
          $t = ($lines[$lastLi]).TrimEnd("`r")
          if (-not $t.EndsWith(' }')) {
            Write-Err ("  [UNFIX] khu '{0}' chua co cells va dong cuoi le la: {1}" -f $aid, $t)
            $unfixed++
            continue
          }
          $prev = ($t.Substring(0, $t.Length - 2)).TrimEnd()
          if (-not $prev.EndsWith(']')) {
            Write-Err ("  [UNFIX] khu '{0}' dong cuoi khong ket bang ' ] }': {1}" -f $aid, $t)
            $unfixed++
            continue
          }
          $lines[$lastLi] = $prev + ',' + ($(if ($eolCr) { "`r" }))
          $blockTexts = @($(if ($eolCr) { "    cells: [`r" } else { '    cells: [' }))
          for ($i = 0; $i -lt $entryTexts.Count; $i++) { $blockTexts += $entryTexts[$i] }
          $blockTexts += ($(if ($eolCr) { "      ] }`r" } else { '      ] }' }))
          for ($i = 0; $i -lt $blockTexts.Count; $i++) {
            $ops.Add([pscustomobject]@{ at = $aEnd; txt = $blockTexts[$i] })
          }
        } else {
          Write-Err ("  [UNFIX] khu '{0}': co 'cells: [' nhung khong tim thay dong ket" -f $aid)
          $unfixed++
          continue
        }
        foreach ($g in @(Sort-Grids @($mapByGrid.Keys))) {
          Write-Ok ("  [FIX] them cell khu {0} o {1}" -f $aid, $g)
          $nFix++
        }
      }
    }

    if (($unfixed -eq 0) -and ($ops.Count -gt 0)) {
      $groups = $ops | Group-Object -Property { $_.at } | Sort-Object -Property { [int]$_.Name } -Descending
      foreach ($g in $groups) {
        $at = [int]$g.Name
        $texts = @($g.Group | ForEach-Object { $_.txt })
        for ($i = $texts.Count - 1; $i -ge 0; $i--) { $lines.Insert($at, $texts[$i]) }
      }
      $newSeg = [string]::Join("`n", $lines)
      $cand = $raw.Substring(0, $info.segStart) + $newSeg + $raw.Substring($info.absEnd)
      # check nhe truoc khi ghi: cau truc ngoac cua ca file phai con dung cap
      $diag = New-Object 'System.Collections.Generic.List[string]'
      if (-not (Test-Brackets $cand ([ref]$diag))) {
        foreach ($d in $diag) { Write-Err ('  [DIAG] ' + $d) }
        Write-Err '  [UNFIX] cau truc ngoac/bracket le sau khi fix areas - HUY ghi'
        $unfixed++
      } else {
        $raw = $cand
      }
    }
  }

  # ---------- 2) sources.areaCells ----------
  $pairsNeed = @(@($pairMissing))
  foreach ($m in @($missing)) {
    $pairsNeed = @($pairsNeed) + @([pscustomobject]@{ id = $m.id; grid = $m.grid; name = $nameOf[$m.id] })
  }
  if (@($pairsNeed).Count -gt 0) {
    $byId = @{}
    foreach ($p in $pairsNeed) {
      if (-not $byId.ContainsKey($p.id)) { $byId[$p.id] = @{ grids = @(); name = $p.name } }
      if (@($byId[$p.id].grids) -notcontains $p.grid) {
        $byId[$p.id].grids = @($byId[$p.id].grids) + @($p.grid)
      }
      if (-not $byId[$p.id].name) { $byId[$p.id].name = $p.id }
      $byId[$p.id].name = $p.name
    }
    foreach ($aid in @($byId.Keys | Sort-Object)) {
      $iPath = $raw.IndexOf('    areaCells: {')
      if ($iPath -lt 0) { Write-Err '  [UNFIX] khong tim thay areaCells trong sources'; $unfixed++; continue }
      $iClose = [regex]::Match($raw.Substring($iPath), '\r?\n    \}')
      if (-not $iClose.Success) { Write-Err '  [UNFIX] khong tim thay dong ket areaCells'; $unfixed++; continue }
      $clAbs = $iPath + $iClose.Index
      $blockStart = $raw.IndexOf(("      '" + $aid + "': {"))
      if (($blockStart -ge 0) -and ($blockStart -lt $clAbs)) {
        # khoi khu da co: chen cap thieu vao cuoi khoi (truoc '      }' cua khoi)
        $mC = [regex]::Match($raw.Substring($blockStart), '\r?\n      \}')
        if (-not $mC.Success) { Write-Err ("  [UNFIX] khu '{0}' trong areaCells thieu dong ket" -f $aid); $unfixed++; continue }
        $insAbs = $blockStart + $mC.Index
        $nl = Get-EolAt $raw $insAbs
        $lineList = @()
        $sorted = @(Sort-Grids @($byId[$aid].grids))
        for ($i = 0; $i -lt $sorted.Count; $i++) {
          $title = ('Epic Battle Fantasy 5 Map/{0} {1}' -f $sorted[$i], $byId[$aid].name)
          $lineList += ("        '{0}': '{1}'" -f $sorted[$i], (Esc-DataJs $title))
        }
        $insTxt = ','
        for ($i = 0; $i -lt $lineList.Count; $i++) {
          $insTxt += $nl + $lineList[$i]
          if ($i -lt $lineList.Count - 1) { $insTxt += ',' }
        }
        $raw = $raw.Substring(0, $insAbs) + $insTxt + $raw.Substring($insAbs)
        Write-Ok ("  [FIX] them mapping areaCells khu {0}: {1}" -f $aid, ($sorted -join ', '))
        $nFix++
      } else {
        # khu chua co khoi: them khoi moi sau khoi con cuoi cung cua areaCells
        $pEnd = Find-LastAreaCellsBlockClose $raw $clAbs
        if ($pEnd -lt 0) { Write-Err '  [UNFIX] khong tim thay khoi con cuoi trong areaCells'; $unfixed++; continue }
        $nl = Get-EolAt $raw $pEnd
        $insBase = $pEnd + ("`n      }".Length)
        $sorted = @(Sort-Grids @($byId[$aid].grids))
        $insTxt = ',' + $nl + ("      '{0}': {{" -f $aid)
        for ($i = 0; $i -lt $sorted.Count; $i++) {
          $title = ('Epic Battle Fantasy 5 Map/{0} {1}' -f $sorted[$i], $byId[$aid].name)
          $insTxt += $nl + ("        '{0}': '{1}'" -f $sorted[$i], (Esc-DataJs $title))
          if ($i -lt $sorted.Count - 1) { $insTxt += ',' }
        }
        $insTxt += $nl + '      }'
        $raw = $raw.Substring(0, $insBase) + $insTxt + $raw.Substring($insBase)
        Write-Ok ("  [FIX] them block areaCells khu {0}: {1}" -f $aid, ($sorted -join ', '))
        $nFix++
      }
    }
  }

  if (($nFix -gt 0) -and ($unfixed -eq 0)) {
    $diag = New-Object 'System.Collections.Generic.List[string]'
    if (-not (Test-Brackets $raw ([ref]$diag))) {
      foreach ($d in $diag) { Write-Err ('  [DIAG] ' + $d) }
      Write-Err '  [UNFIX] cau truc ngoac/bracket le vong cuoi - HUY ghi file'
      $unfixed++
    } else {
      Write-DataRaw $raw
      Write-Ok ("  da ghi cap nhat vao {0} ({1} muc)" -f $DataFile, $nFix)
    }
  }
  $script:AreaUnfixed = $unfixed
  Write-Host ("  KQ FIX areas: {0} muc; khong sua duoc: {1}" -f $nFix, $unfixed)
  return $nFix
}

# ---------------------------------------------------------------------------
# chinh: quet + doi chieu + bao cao
# ---------------------------------------------------------------------------
function Invoke-CheckAreas {
  Write-Section 'AREAS - o luoi khu vuc: trang Map/<GR> <Khu> vs areas.cells'
  try {
    $raw0 = Read-DataRaw
    $info = Get-AreasInfo $raw0
  } catch {
    Write-Err ("  {0}" -f $_.Exception.Message)
    return $null
  }
  $areas = @($info.list)
  Write-Host ("  khu trong data.js: {0}" -f $areas.Count)
  $byName = @{}
  foreach ($a in $areas) {
    $kn = (($a.name) -replace '\s+', ' ').Trim().ToLowerInvariant()
    if (-not $byName.ContainsKey($kn)) { $byName[$kn] = $a }
  }

  # O da tach thanh khu con (kind = 'Khu con') khong con nam trong cells
  # cua khu me; mode areas khong duoc bao thieu / tu them lai cac o nay.
  $subOwned = @{}
  foreach ($sa in @($areas | Where-Object { $_.kind -eq 'Khu con' })) {
    if (-not $sa.parent) { continue }
    foreach ($sg in @(($sa.cells).Keys)) { $subOwned[$sa.parent + '/' + $sg] = $true }
  }

  # 1) danh sach trang map tren wiki
  try { $pages = Get-AllMapTitles } catch {
    Write-Err ("  loi API allpages: {0}" -f $_.Exception.Message)
    return $null
  }
  $prefix = 'Epic Battle Fantasy 5 Map/'
  $parsed = @()
  $skipped = @()
  foreach ($t in $pages) {
    if (-not $t.StartsWith($prefix)) { $skipped += $t; continue }
    $short = $t.Substring($prefix.Length)
    $m = [regex]::Match($short, '^([A-Z]\d{1,2})\s+(.+)$')
    if (-not $m.Success) { $skipped += $short; continue }
    $parsed += [pscustomobject]@{
      title = $t
      grid  = $m.Groups[1].Value
      name  = (($m.Groups[2].Value) -replace '\s+', ' ').Trim()
    }
  }
  Write-Host ("  trang dang 'GR Ten khu': {0}; bo qua: {1}" -f @($parsed).Count, @($skipped).Count)

  # 2) noi dung tung trang (foes / treasures co Key Items)
  try { $texts = Get-MapPagesContent @($parsed | ForEach-Object { $_.title }) } catch {
    Write-Err ("  loi API hun wikitext: {0}" -f $_.Exception.Message)
    return $null
  }
  $wiki = @{}
  foreach ($p in $parsed) {
    if (-not $texts.ContainsKey($p.title)) { continue }
    $rows = Get-MapPageRows $texts[$p.title]
    if (-not $wiki.ContainsKey($p.name)) { $wiki[$p.name] = @{} }
    if (-not ($wiki[$p.name]).ContainsKey($p.grid)) {
      $wiki[$p.name][$p.grid] = @{
        foe = New-Object System.Collections.Generic.List[string]
        key = New-Object System.Collections.Generic.List[string]
      }
    }
    foreach ($r in $rows.foe) { [void]($wiki[$p.name][$p.grid].foe).Add($r) }
    foreach ($r in $rows.key) { [void]($wiki[$p.name][$p.grid].key).Add($r) }
  }

  # 3) doi chieu: chi 18 khu chinh (ten trang == name trong data.js)
  $missing = @()
  $keyMissing = @()
  $nContent = 0
  $nEmpty = 0
  foreach ($kn in $byName.Keys) {
    $a = $byName[$kn]
    if (-not $wiki.ContainsKey($a.name)) {
      Write-Dim ("  [INFO] khu '{0}': khong co trang map cung ten" -f $a.name)
      continue
    }
    $g = $wiki[$a.name]
    $contentGrids = @(@($g.Keys) | Where-Object { ($g[$_].foe.Count -gt 0) -or ($g[$_].key.Count -gt 0) })
    $nContent += $contentGrids.Count
    $nEmpty += (@($g.Keys).Count - $contentGrids.Count)

    # cells thieu (bo qua o da tach thanh khu con)
    $miss = @($contentGrids | Where-Object {
      -not ($a.cells).ContainsKey($_) -and -not $subOwned.ContainsKey($a.id + '/' + $_)
    })
    foreach ($grid in $miss) {
      $foes = @($g[$grid].foe)
      $keys = @($g[$grid].key)
      $missing += [pscustomobject]@{ id = $a.id; grid = $grid; foes = $foes; keys = $keys }
      Write-Bad ("  [MISS] {0} ({1}): o {2} co noi dung (foes {3}, keys {4}) nhung data.js chua co cell" -f $a.name, $a.id, $grid, $foes.Count, $keys.Count)
    }
    if ($miss.Count -gt 0) {
      Write-Host ("    -> thieu {0} o: {1}" -f $miss.Count, ($miss -join ', '))
    }

    # key thieu trong cell co san
    foreach ($grid in $contentGrids) {
      if (-not ($a.cells).ContainsKey($grid)) { continue }
      # cell gop khu con: key cua khu con da chuyen sang entry rieng
      if ($subOwned.ContainsKey($a.id + '/' + $grid)) { continue }
      $kt = ($a.cells[$grid]).keysText
      foreach ($row in $g[$grid].key) {
        $pos = $row.IndexOf(' - ')
        if ($pos -lt 0) { continue }
        $names = ($row.Substring($pos + 3)) -split ',\s*'
        $lack = @()
        foreach ($nm in $names) {
          if ($nm -and ($kt -notmatch ([regex]::Escape($nm)))) { $lack += $nm }
        }
        if ($lack.Count -gt 0) {
          $keyMissing += [pscustomobject]@{ id = $a.id; grid = $grid; texts = @($row) }
          Write-Bad ("  [MISS] {0} o {1}: thieu tren row keys: {2}" -f $a.name, $grid, ($lack -join ', '))
        }
      }
    }
  }

  # 4) cap 'khu/grid' trong sources.areaCells phai dung khop voi cells
  $pairMissing = @()
  # doan tim trang wiki co dung hang foes/keys: dung de xac dinh title map
  # cho cell da gop tu khu con (vi du the-rapture/J7 la noi dung trang khu con
  # 'Lava Lake', grand-gallery/E5 co the thuoc khu khac ten 'Grand Gallery').
  function Find-PageForCell($cell, $grid) {
    $best = ''
    $bestHits = 0
    $tieName = ''
    foreach ($wn in @($wiki.Keys)) {
      if (-not ($wiki[$wn]).ContainsKey($grid)) { continue }
      $rows = $wiki[$wn][$grid]
      $hits = 0
      foreach ($f in @($cell.foesList)) {
        $fn = ($f -replace '\s', '')
        foreach ($fp in @($rows.foe)) {
          if (($fp -replace '\s', '') -eq $fn) { $hits++; break }
        }
      }
      foreach ($k in @($cell.keysList)) {
        $kn2 = ($k -replace '\s', '')
        foreach ($kp in @($rows.key)) {
          if (($kp -replace '\s', '') -eq $kn2) { $hits += 2; break }
        }
      }
      if ($hits -gt $bestHits) { $bestHits = $hits; $best = $wn; $tieName = '' }
      elseif (($hits -eq $bestHits) -and ($hits -gt 0) -and ($wn -ne $best)) { $tieName = $wn }
    }
    if (($bestHits -gt 0) -and (-not $tieName)) { return @{ name = $best; hits = $bestHits } }
    return $null
  }
  # ten trang chuan danh rieng khi khong doan theo noi dung duoc:
  # - 'Ice Cave'/'Library': cell trong khu chinh lay noi dung tu trang khu con;
  # - 'Lava Lake': khu the-rapture tren wiki su dung ten Lava Lake (da kiem
  #   API: khong ton tai trang 'J7 The Rapture', chi co 'J7 Lava Lake'...).
  $subHint = @{
    'hope-harbor/E3' = 'Ice Cave'
    'greenwood-village/I2' = 'Library'
    'the-rapture/J7' = 'Lava Lake'
    'the-rapture/J8' = 'Lava Lake'
    'the-rapture/J9' = 'Lava Lake'
    'the-rapture/K7' = 'Lava Lake'
    'the-rapture/K8' = 'Lava Lake'
  }
  $src = Get-SourcesAll
  $pairs = @{}
  if (($src.ContainsKey('areaCells'))) { $pairs = $src['areaCells'] }
  foreach ($a in $areas) {
    foreach ($grid in @(($a.cells).Keys)) {
      $kk = $a.id + '/' + $grid
      if (-not $pairs.ContainsKey($kk)) {
        $nm = $null
        $how = ''
        if ($subHint.ContainsKey($kk)) { $nm = $subHint[$kk]; $how = 'hint khu con' }
        else {
          $h = Find-PageForCell $a.cells[$grid] $grid
          if ($h) { $nm = $h.name; $how = ('noi dung khop ' + $h.hits + ' row') }
        }
        if (-not $nm) { $nm = $a.name; $how = 'mac dinh ten khu' }
        $pairMissing += [pscustomobject]@{ id = $a.id; grid = $grid; name = $nm }
        Write-Bad ("  [MISS] sources.areaCells khong co cap {0} (title se dung 'Map/{1} {2}' - {3})" -f $kk, $grid, $nm, $how)
      }
    }
  }
  foreach ($pk in @($pairs.Keys)) {
    $arr = $pk -split '/'
    if ($arr.Count -ne 2) { continue }
    $ao = @($areas | Where-Object { $_.id -eq $arr[0] })
    if ($ao.Count -eq 0) {
      Write-Bad ("  [MISS] areaCells co khu la '{0}' nhung block areas khong co" -f $arr[0])
      continue
    }
    if (-not (($ao[0]).cells).ContainsKey($arr[1])) {
      Write-Bad ("  [MISS] areaCells co cap {0} nhung cells khong co o nay" -f $pk)
    }
  }

  # 5) tom hieu so
  Write-Host ''
  Write-Host ("  o co noi dung tren wiki: {0}" -f $nContent)
  Write-Host ("  o rong (chi Exits) bo qua: {0}" -f $nEmpty)
  $dContent = 0
  foreach ($a in $areas) {
    foreach ($grid in @(($a.cells).Keys)) {
      $cell = $a.cells[$grid]
      if ($cell.hasFoes -or $cell.hasKeys) { $dContent++ }
    }
  }
  Write-Host ("  o co noi dung trong data.js: {0} (tong cells: {1})" -f $dContent, ((@($areas | ForEach-Object { @($_.cells.Keys).Count }) | Measure-Object -Sum).Sum))

  $r = @{ new = @() }
  $r.new = @($missing) + @($keyMissing) + @($pairMissing)
  if (@($r.new).Count -gt 0 -and $Fix) {
    Write-Section 'FIX - them cell/keys/areaCells thieu vao data.js'
    $script:AreaUnfixed = 0
    $n = Apply-AreasFix $missing $keyMissing $pairMissing
    if (($n -gt 0) -and ($script:AreaUnfixed -eq 0)) { $r.new = @() }
  }
  if (@($r.new).Count -gt 0) { Write-Bad '  (chay lai voi -Fix de tu them cac muc thieu)' }
  else { Write-Ok '  da phu: o luoi khu vuc khop voi wiki' }
  return $r
}

function Show-Usage {
  Write-Host 'Cach dung: update-data.ps1 -Update <enemies|statuses|items|sources|areas> [-Fix]'
}

$code = 0
if (-not (Test-Path $DataFile)) { Write-Err ("khong tim thay {0}" -f $DataFile); exit 2 }
switch ($Update.ToLower()) {
  'enemies'  { $r = Invoke-CheckEnemies;  $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'statuses' { $r = Invoke-CheckStatuses; $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'items'    { $r = Invoke-CheckItems;    $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'sources'  { $code = Invoke-CheckSources }
  'areas'    { $r = Invoke-CheckAreas;    $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  default    { Write-Err ("mode khong ho tro: {0}" -f $Update); Show-Usage; exit 2 }
}
exit $code
