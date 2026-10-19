# =====================================================================
# check.ps1 - Bo kiem tra tu dong cho Wiki EBF5
# Chay:  powershell -ExecutionPolicy Bypass -File check.ps1
# Quet:  can bang ngoac/quotes, ky tu rac, phuy thieu khi splice mang,
#        cu phap JS (JScript), anh tham chieu vs file that, tom tat chu de, HTML router.
# Exit code: 0 = PASS, 1 = co FAIL, 2 = khong tim thay file goc
# Chu y: toan bo noi dung script la ASCII khong dau (PS 5.1 doc file khong
#        BOM nhu ANSI nen khong duoc dung dau tieng Viet trong file nay).
# =====================================================================
param([switch]$Quiet)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$script:fail = 0
$script:warn = 0

function Ok($msg)   { Write-Output ("  [OK]   " + $msg) }
function Bad($msg)  { $script:fail++; Write-Output ("  [FAIL] " + $msg) }
function Warn($msg) { $script:warn++; Write-Output ("  [WARN] " + $msg) }

# ---------------------------------------------------------------------
# 0. File goc
# ---------------------------------------------------------------------
$jsFiles   = @('js\data.js', 'js\app.js')
$htmlFiles = @('index.html', 'list.html', 'detail.html')
$keys      = @('characters','enemies','skills','items','equipment','statuses','areas','summons','limits')
$imgRoot   = 'img'

foreach ($f in ($jsFiles + $htmlFiles)) {
  if (-not (Test-Path $f)) {
    Write-Output ("Khong tim thay " + $f + " - hay chay script nay tu thu muc goc wiki.")
    exit 2
  }
}

$all = @{}
foreach ($f in $jsFiles) { $all[$f] = [System.IO.File]::ReadAllText($f) }
$data = $all['js\data.js']

# ---------------------------------------------------------------------
# 1. Can bang ngoac + quotes
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 1. CAN BANG NGOAC + QUOTES =="
foreach ($f in $jsFiles) {
  $t   = $all[$f]
  # Bo qua noi dung trong chuoi double-quoted (da co apostrophe hop le nhu "Phyrnna's Blessing")
  $tq  = [regex]::Replace($t, '"(?:[^"\\\r\n]|\\.)*"', '""')
  $ob  = [regex]::Matches($t, '\{').Count
  $cb  = [regex]::Matches($t, '\}').Count
  $osb = [regex]::Matches($t, '\[').Count
  $csb = [regex]::Matches($t, '\]').Count
  $msg = ("{0}: braces {1}/{2} brackets {3}/{4}" -f $f, $ob, $cb, $osb, $csb)
  if ($ob -eq $cb -and $osb -eq $csb) { Ok $msg } else { Bad $msg }
  $q = 0
  $tlines = $tq -split "\r?\n"
  foreach ($tl in $tlines) {
    $tr = $tl.TrimStart()
    if ($tr.StartsWith('/*') -or $tr.StartsWith('*') -or $tr.StartsWith('//')) { continue }
    $q += ([regex]::Matches($tl, "'")).Count
  }
  if ($q % 2 -eq 0) { Ok ("{0}: single-quotes chan ({1})" -f $f, $q) }
  else { Bad ("{0}: single-quotes LE ({1}) - kha nang co chuoi chua dau nhay don" -f $f, $q) }
}

# ---------------------------------------------------------------------
# 2. Ky tu rac (CJK / Cyrillic / Hangul)
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 2. KY TU RAC =="
$garbageRe = '[\u4E00-\u9FFF\u3040-\u30FF\uAC00-\uD7AF\u0400-\u04FF]'
foreach ($f in $jsFiles) {
  $lines = [System.IO.File]::ReadAllLines($f)
  $hits = @()
  for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match $garbageRe) { $hits += ($i + 1) }
  }
  if ($hits.Count -eq 0) { Ok ("$f`: khong co CJK/Cyrillic/Hangul") }
  else {
    $shown = ($hits | Select-Object -First 5) -join ', '
    Bad ("$f`: " + $hits.Count + " dong chua ky tu rac (dong: $shown...)")
  }
}

# ---------------------------------------------------------------------
# 3. Phuy thieu khi splice mang:
#      "}" + khoang trang + xuong dong + "{" bat dau entry (hoac "/*")
#    Neu co phuy thi "}," bi chan ngay vi phuy khong phai \s.
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 3. PHUY THIEU SAU ENTRY =="
$commaRe = [regex]'\}\s*\r?\n\s*(?:\{(?=\s*(?:\r?\n\s*)?id)|/\*)'
$commaBad = $commaRe.Matches($data)
if ($commaBad.Count -eq 0) {
  Ok "data.js: khong co entry nao thieu phuy truoc entry/comment ke tiep"
} else {
  Bad ("data.js: " + $commaBad.Count + " cho nghi van thieu phuy")
  foreach ($m in $commaBad) {
    $head = [Math]::Max(0, $m.Index - 80)
    $ctx  = $data.Substring($head, [Math]::Min(220, $data.Length - $head)) -replace '\s+', ' '
    if ($ctx.Length -gt 170) { $ctx = $ctx.Substring(0, 170) }
    Write-Output ("    >> ..." + $ctx)
  }
}

# ---------------------------------------------------------------------
# 4. Cu phap JS bang JScript (khong can Node).
#    eval() parse TOAN BO chuoi truoc khi thuc thi, nen khi gap loi runtime
#    (vi du 'window' is undefined) thi cu phap toan file chac chan dung.
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 4. CU PHAP JS (cscript //E:JScript) =="
$tmpDir = Join-Path $env:TEMP 'opencode'
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$probe = Join-Path $tmpDir 'ebf5-js-syntax-probe.js'
$probeCode = @'
try {
  eval(WScript.StdIn.ReadAll());
  WScript.Echo("RUNTIME-OK");
} catch (e) {
  var m = String(e.message);
  if (/Expected|Unexpected|Unterminated|token|identifier|reserved|Syntax/i.test(m)) {
    WScript.Echo("SYNTAX-FAIL: " + m);
    WScript.Quit(2);
  } else {
    WScript.Echo("SYNTAX-OK-RUNTIME: " + m);
  }
}
'@
Set-Content -Path $probe -Value $probeCode -Encoding ASCII
foreach ($f in $jsFiles) {
  $t = $all[$f]
  # JScript 5.7 khong parse duoc ES6+: =>, let, const, template (`)... file nao co thi bo qua.
  $es6 = @()
  if ($t.Contains('=>'))                     { $es6 += 'arrow (=>)' }
  if ($t -match '\blet\b')                   { $es6 += 'let' }
  if ($t -match '\bconst\b')                 { $es6 += 'const' }
  if ($t.Contains([char]0x60))               { $es6 += 'template string' }
  if ($t -match '\basync\b|\bclass\b')       { $es6 += 'async/class' }
  if ($es6.Count -gt 0) {
    Warn ("$f`: dung ma ES6 (" + ($es6 -join ', ') + ") - JScript khong parse duoc nen bo qua check cu phap cho file nay")
    Write-Output ("    (trang chay tot trong browser = bang chung parse duoc; khi sua " + $f + " hay mo lai cac trang de xac nhan)")
    continue
  }
  $out = @(Get-Content $f -Raw | & cscript //nologo //E:JScript $probe 2>$null)
  $ex  = $LASTEXITCODE
  if ($ex -eq 0) {
    Ok ("$f`: cu phap day du (JScript parse OK)")
  } else {
    $detail = @($out | Where-Object { "$_" -match 'SYNTAX-FAIL|RUNTIME-|SYNTAX-OK' }) -join ' | '
    Bad ("$f`: cscript exit=$ex " + $detail)
  }
}

# ---------------------------------------------------------------------
# 5. Anh: tham chieu trong data.js vs file thuc te
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 5. ANH =="
$refMatches = [regex]::Matches($data, "image:\s*'img/([^']+)'")
$refs = $refMatches | ForEach-Object { 'img/' + $_.Groups[1].Value }
$uniq = @($refs | Select-Object -Unique)
$missing = @($refs | Where-Object { -not (Test-Path $_) })
if ($missing.Count -eq 0) {
  Ok ("image refs: " + $refs.Count + " / " + $uniq.Count + " unique - 0 missing")
} else {
  Bad ("image refs: " + $refs.Count + " nhung " + $missing.Count + " file khong ton tai")
  foreach ($p in ($missing | Select-Object -First 10)) { Write-Output ("    >> " + $p) }
}
$root = (Get-Location).Path
$diskFiles = @(Get-ChildItem $imgRoot -Recurse -File |
  ForEach-Object { ($_.FullName.Substring($root.Length + 1)) -replace '\\', '/' })
$unused = @($diskFiles | Where-Object { $uniq -notcontains $_ })
if ($unused.Count -eq 0) {
  Ok ("img/: " + $diskFiles.Count + " file, khong co file le trong")
} else {
  Warn ("img/: " + $diskFiles.Count + " file nhung " + $unused.Count + " khong duoc tham chieu: " + (($unused | Select-Object -First 6) -join ', '))
}

# ---------------------------------------------------------------------
# 6. Tom tat so muc theo tung chu de
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 6. SO MUC THEO CHU DE =="
$total = 0
foreach ($k in $keys) {
  $m = [regex]::Match($data, "(?s)\r?\n  $k`: \[(.*?)\r?\n  \],")
  if ($m.Success) {
    $body = $m.Groups[1].Value
    $n  = [regex]::Matches($body, "\bid:\s*'").Count
    $im = [regex]::Matches($body, "image:\s*'img/").Count
    $total += $n
    if (-not $Quiet) {
      $note = ''
      if ($im -lt $n) { $note = (" (thieu " + ($n - $im) + " anh - null/emoji la binh thuong voi status/limit)") }
      $line = "  {0,-11} {1,3} muc / {2,3} anh{3}" -f $k, $n, $im, $note
      Write-Output $line
    }
  } else {
    Warn ("khong tim thay mang '$k' trong data.js")
  }
}
Write-Output ("  Tong cong: $total muc / " + $refs.Count + " tham chieu anh")

# ---------------------------------------------------------------------
# 7. HTML router
# ---------------------------------------------------------------------
Write-Output ""
Write-Output "== 7. HTML ROUTER =="
foreach ($h in $htmlFiles) {
  $c = [System.IO.File]::ReadAllText($h)
  $lack = @()
  if (-not $c.Contains('js/data.js')) { $lack += 'js/data.js' }
  if (-not $c.Contains('js/app.js'))  { $lack += 'js/app.js' }
  if ($lack.Count -eq 0) { Ok ("$h`: nap day du js/data.js + js/app.js") }
  else { Bad ("$h`: thieu the script: " + ($lack -join ', ')) }
}

# ---------------------------------------------------------------------
# Tong ket
# ---------------------------------------------------------------------
Write-Output ""
if ($script:fail -gt 0) {
  Write-Output ("KET QUA: FAIL - " + $script:fail + " loi, " + $script:warn + " canh bao. Xem dong co [FAIL] o tren.")
  exit 1
}
if ($script:warn -gt 0) {
  Write-Output ("KET QUA: PASS co canh bao - " + $script:warn + " WARN, 0 FAIL.")
  exit 0
}
Write-Output "KET QUA: PASS DAY DU - 0 FAIL, 0 WARN."
exit 0
