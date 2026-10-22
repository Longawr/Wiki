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
#
# Vi du:
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update enemies
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update statuses
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update items
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources
#   powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources -Fix
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

function Show-Usage {
  Write-Host 'Cach dung: update-data.ps1 -Update <enemies|statuses|items|sources> [-Fix]'
}

$code = 0
if (-not (Test-Path $DataFile)) { Write-Err ("khong tim thay {0}" -f $DataFile); exit 2 }
switch ($Update.ToLower()) {
  'enemies'  { $r = Invoke-CheckEnemies;  $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'statuses' { $r = Invoke-CheckStatuses; $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'items'    { $r = Invoke-CheckItems;    $code = 0; if ($null -eq $r) { $code = 2 } elseif (@($r.new).Count -gt 0) { $code = 1 } }
  'sources'  { $code = Invoke-CheckSources }
  default    { Write-Err ("mode khong ho tro: {0}" -f $Update); Show-Usage; exit 2 }
}
exit $code
