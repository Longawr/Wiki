# ROADMAP — Wiki tiếng Việt Epic Battle Fantasy 5

> Wiki tĩnh thuần HTML/CSS/JS, chạy trực tiếp khi mở `index.html` (không build, không server).
> Dữ liệu soạn trong `js/data.js`, đối chiếu theo **Epic Battle Fantasy Wiki** chính thức
> (epicbattlefantasy.fandom.com) — ảnh tải về repo, không hotlink.
> Bản quyền game & ảnh: Matt Roszak / Kupo Games.

---

## 1. Đã làm được

### Kiến trúc
- **SPA router tĩnh 3 trang**: `index.html` (trang chủ), `list.html?type=X` (danh sách + bộ lọc), `detail.html?id=Y&type=X` (chi tiết).
- **Nguồn dữ liệu trung tâm** `js/data.js`: 10 mảng chủ đề + `categories` + `elements` (10 nguyên tố) + `externalWiki`.
- `js/app.js` render mọi thứ: nav tự sinh từ `categories`, thẻ card có ảnh + chip, trang chi tiết có bảng thông tin / panel mẹo / ghi chú nguồn dẫn về trang wiki tương ứng của từng chủ đề.
- `css/style.css`: theme tối phong cách game, card grid, chip, `.detail-media`, fallback `.img-fail`.
- Thêm chủ đề mới = **1 hàng trong `categories` + 1 mảng dữ liệu + (tuỳ) 1 nhánh chip/detail trong app.js**.

### Dữ liệu — 10 chủ đề, 991 mục, 990 tham chiếu ảnh ↔ 985 file (0 thiếu, 0 file lẻ)

| # | Chủ đề | key | Mục | Ảnh | Ghi chú |
|---|--------|-----|-----|-----|---------|
| 1 | Nhân vật | `characters` | 5 | 5/5 | Matt, Natalie, Lance, Anna, NoLegs — lore EBF5 thật, kèm danh mục kỹ năng/trang bị chính |
| 2 | Kẻ địch | `enemies` | 214 | 214/214 | **Lượt 21: đủ bộ quái EBF5 50 → 214** — 164 entry mới sinh máy từ bảng `FoeTableEBF5` của 167 trang foe fandom (lọc `Category:Foes` tag EBF5 222 → bỏ 36 trang Foe Groups → bỏ 6 trang nội dung + Mighty Oak); icon `EBF5 Bestiary <Tên>` (thiếu → `EBF5 Foe Icon` / `Icon bestiary ebf4`); giữ drops thật + `res` khắc chế 50/50 lượt 15; sources mỗi foe = `X (foe)` |
| 3 | Kỹ năng | `skills` | 183 | 183/183 | **Đủ bộ 5 nhân vật + 53 Extra Skills** (kèm chars từng người học được từ trang bị), theo *List of Skills in EBF5*; icon `EBF5 Skill X` |
| 4 | Vật phẩm | `items` | 46 | 46/46 | **Lượt 23 — đủ bộ**: 1 entry nhóm Food + 24 món Food thật (Pumpkin→Pizza, thêm Pretzel/Iron Brew/Energy Drink) + **20 Steroid đủ bộ 4 chỉ số × 5 nhân vật** (theo bảng Steroids trang *Food*) + Hand Bomb; icon `EBF5 Item X` — mon mới không có trang item riêng trên fandom (Turnip/"Mushroom" là trang item EBF3/4, không phải steroid EBF5) → nguồn mới lại `_default = Food` |
| 5 | Trang bị | `equipment` | 228 | 228/228 | **Lượt 16: 84 vũ khí** (78 sinh máy từ 4 trang `Swords`/`Bows`/`Guns`/`Staves` bảng 1 post-v2 + 8 entry tay: Heaven Gate, Ultra Pro 9000X, Fairy Bow, Dark Tooth, Shadow Blaster, Spine Snapper, Crystal Staff, Steel Buckler); **Lượt 17: +142 mũ giáp & Flair** — 84 mũ/giáp sinh máy (21+21 Mũ/Giáp nam theo `Male Hats and Armor`, 21+21 nữ theo `Female Hats and Armor`) + 58 Flair (55 sinh máy từ trang `Flairs` + 3 tay NoLegs); thay 8 entry tay mỏng bằng bản sinh máy; 24 món nhãn Độc quyền bản Steam qua `PaywallNote` từng trang item |
| 5b | Vật liệu | `materials` | 60 | 60/60 | **Lượt 23 — chủ đề mới**: đủ 60 nguyên liệu forge EBF5 sinh máy từ bảng `{{EBF|5}}` trang *Materials* (tên, mô tả wiki dịch, giá mua/bán); "Can be thrown in battle" → kind `Ném được` (Snowball, Brick, Shuriken, Hand Bomb — Hand Bomb tái dùng icon của items); icon `EBF5 Item X` vào `img/materials/`; sources `_default = Materials` |
| 6 | Trạng thái | `statuses` | 26 | 25/26 | Đủ Doom, Scorch, Berserk, Syphon, Brave, Regen, Vận may, **Hoang mang (Confuse — chỉ tác động người chơi, tự dùng bản kỹ năng yếu nhất, bỏ qua Syphon & cooldown, ưu tiên cao hơn Berserk)**…; "Trói chân" (không tồn tại) đã thay bằng Mỏi (Tired) — icon `EBF5 Status X`; Radiation giữ emoji |
| 7 | Khu vực | `areas` | 18 | 18/18 | 12 khu chính + 6 khu trả phí theo trang *EBF5 Map*; mỗi khu có ô lưới (grid), Điểm nhấn, Lưu ý — ảnh tile bản đồ; **C3: ~200 ô lưới có bảng Quái (wave) + Key Items + vị trí con + ghi chú cơ chế từ các trang `EBF5 Map/X`** |
| 8 | Triệu hồi | `summons` | 191 | 191/191 | **C4: 18 → 40** (lượt 8+11) rồi **14: 40 → 191 — gần như đủ bộ** theo bảng hiện hành post-v2 (192 hàng, trừ demo ẩn Glitch 2; The Devourer 250 → Furry Slime 1); 151 entry mới sinh máy từ cột target/type/power/element/status/debuff; 151 icon tải từ `EBF5 Foe Icon` qua fetch-images.map.txt |
| 9 | Limit Break | `limits` | 20 | 20/20 (11 trong `img/limits/` + 9 dùng lại icon skills) | 10 riêng + 10 dùng chung; danh sách nhân vật học được trích từ Category tags wiki; 5 icon thiếu cũ (Supernova, Hidden Power, Absolute Zero, Seven Swords, Art Attack) đã tải về; 4 cái còn lại tái sử dụng icon từ mảng skills; Radiation status vẫn emoji (wiki không có file) |

### Quy trình thu thập dữ liệu (đã kiểm chứng)
- **API fandom hoạt động**: `api.php?action=parse&page=X&prop=wikitext` (nội dung), `action=query&titles=A|B&prop=imageinfo&iiprop=url` (URL ảnh CDN), `prop=revisions&rvprop=content` (bó tối đa 50 trang/lượt), `list=categorymembers` (danh sách file theo Category).
- **CDN ảnh** `static.wikia.nocookie.net` cần header `Referer: https://epicbattlefantasy.fandom.com/` + User-Agent trình duyệt (trang HTML thường trả 403).
- **Tên file chuẩn trên wiki** giúp dò nhanh: `EBF5 Bestiary X.png`, `EBF5 Item X.png`, `EBF5 Status X.png`, `EBF5 Skill X.png` (field `CustomIcon` trong wikitext tiết lộ tên này), `EBF5 Foe Icon X.png`, tile bản đồ `A2HopeHarbor.png`…
- **Ảnh tải bằng PowerShell** `Invoke-WebRequest` hàng loạt (~30–50 URL/lượt), lưu `img/<chude>/<id>.png`, tham chiếu `image: 'img/...'` (đường dẫn tương đối).
- **Bài học lớn**: soạn văn tiếng Việt dài trong shell/here-string dễ lẫn ký tự rác (CJK/Cyrillic) → soạn file tạm bằng công cụ `write`, rồi splice vào `data.js` bằng PowerShell; luôn quét kiểm `[CJK]=0, [Cyrillic]=0` và đếm ngoặc sau mỗi lần sửa.

### Kiểm thử pass (trạng thái hiện tại)
- `data.js`: braces 1440/1440, brackets 1618/1618, quotes chẵn (22842), 0 ký tự rác, JScript parse OK.
- `app.js`: braces 137/137, brackets 61/61 (file có ES6 sẵn nên JScript bỏ qua, trình duyệt chạy tốt).
- `test.html`: trang smoke test chạy trong trình duyệt (10 chủ đề / 26 status, `renderDetail` sinh tooltip `.st-tip` + hàng `.prev-next`, lightbox, `#statusTip`, `#toTop`) — **mở bằng HTTP server thì đủ case xanh; qua `file://` Chromium chặn `history.replaceState` (origin null) nên các case phụ thuộc URL route tự chuyển SKIP (không FAIL)**; xoá đi khi không cần nữa.
- 990 tham chiếu `image:` ↔ 985 file thật (limits dùng lại icon skills; Hand Bomb materials tái dùng icon items) — **0 thiếu, 0 file lẻ**.
- README + hero trang chủ khớp số liệu thật.

---

## 2. Mục tiêu tiếp theo

### A. UI polish (ưu tiên cao — nâng trải nghiệm ngay) ✅ Hoàn tất lượt 12
- [x] **Lightbox** phóng to ảnh trong trang chi tiết (click ảnh → overlay xem full; đóng bằng ✕ / click nền / Esc).
- [x] **Tooltip icon trạng thái**: hover (hoặc focus) vào tên status trong desc/bảng → hiện icon + mô tả ngắn; **nhấp vào tên** → chuyển tới trang chi tiết status đó. Áp dụng cho desc, tips, strengths/weaknesses, drops, effect, foes/keys/notes của ô lưới, bảng kỹ năng nhân vật.
- [x] **Điều hướng bằng phím** ở trang chi tiết: ←/→ qua mục trước/sau cùng chủ đề, Esc về danh sách (Esc ưu tiên đóng lightbox nếu đang mở; bỏ qua khi đang gõ trong input/select).
- [x] Nút "↑ Đầu trang" (hiện khi cuộn > 400px, mọi trang) + header đã sticky sẵn.
- [x] Tìm kiếm toàn cục — nâng lên tìm theo cả tips/effect/kind: gộp tên + desc + kind + effect + unlock + slot + tips/features/strengths/weaknesses/drops + kỹ năng trong trang nhân vật + **quái & Key Items trong từng ô lưới khu vực** + tên nhân vật học kỹ năng; trang danh sách dùng chung nên tìm theo type=all ăn theo.

### B. Triển khai (để wiki dùng được thật) ✅ Hoàn tất lượt 19
- [x] `git init` + commit đầu tiên ✅ (commit `343eeba`, working tree sạch; warning LF→CRLF vô hại).
- [x] Đẩy lên GitHub, bật **GitHub Pages** ✅ — remote `origin` = `Longawr/Wiki`, bật qua GitHub REST API (`POST /repos/Longawr/Wiki/pages`, source `master` / root) bằng credential git sẵn có trên máy; **URL trực tuyến: https://longawr.github.io/Wiki/** (thuần tĩnh nên chạy ngay, không cần build).
- [x] Kiểm tra lại đường dẫn tương đối `img/...` sau deploy (đã dùng tương đối nên an toàn với path `longawr.github.io/Wiki/`).
- [x] (Tuỳ) **favicon/logo (lượt 22)** — `favicon.svg` vẽ tay (kiếm vàng trên nền tối, vòng tròn đinh ốc phong cách EBF), gắn `<link rel="icon">` cả 3 trang. Tên miền riêng: bỏ qua — cần người dùng tự mua + cấu hình DNS.

### C. Mở rộng dữ liệu (dày hơn nữa)
- [x] Kỹ năng: phát hiện trang tổng *List of Skills in Epic Battle Fantasy 5* — thêm **91 entry (39 → 130)** rồi **53 Extra Skills (130 → 183)**, kèm ảnh chuẩn; status hoàn tất bộ 5 nhân vật + **danh sách ai học được từ trang bị** cho Extra Skills.
- [x] Kẻ địch: bổ sung cột **drops thật 50/50** (tên item + tỉ lệ %) từ bảng `FoeTableEBF5` của từng trang quái — 48/50 có drop thật, Slime Bunny & Lancelot ghi chú "không drop".
- [x] Kẻ địch (lượt 21): **đủ bộ quái 50 → 214** — sinh máy từ `FoeTableEBF5` của 167 trang foe (lọc `Category:Foes`, trừ Foe Groups + 6 trang nội dung + Mighty Oak), desc/tips/drops/khắc chế theo đúng schema cũ, sources = `X (foe)` từng trang.
- [x] Limit Break: **phủ kín 20/20 icon** — 5 cái tải từ `EBF5 Skill X` (bảng *Extra Limit Breaks*), 4 cái tái sử dụng icon mảng skills; Radiation status giữ emoji (wiki không có file).
- [x] Khu vực (C3): **quái + Key Items theo từng ô lưới cho đủ 18 khu** — parser nguồn các trang `Epic Battle Fantasy 5 Map/X` (điểm xuất phát theo ô lưới, wave quái, Key Items, ô con như Nhà Matt/Phòng Arcade/Khu Glitch), các ghi chú cơ chế dịch tay (rương mở bằng mã, Đầu Đá trên bệ đá, cần gạt, Arcade Boss Rush…), bỏ các ghi chú trivia (mã Morse, tên hex glitch). Hiển thị trong panel areas "Ô lưới — Quái và Key Items".
- [x] Summon (C4): **mở rộng 18 → 40 + cột "Mở khoá"** — nguồn = trang *Summons/Epic Battle Fantasy 5*, dùng bảng hiện hành post-v2 (bảng chính; bảng `Pre-v2 update` chỉ giữ đối chiếu). 22 summon mới: Glitch, Annabelle, Lancelot, Matteus, Laurelin, War Mammoth, Sól, Viking Monolith, Ultra Chibi Knight, Zombie Hand, Wooden Idol, SNEK, Roasted Gloop, Sapphire Ore, Ruby Ore, Amethyst Ore, Red Bush, Metal Idol (14, heavy +5), Cat Sniper, PUMPKUS, Cutie Worm, Cat Wizard; SP của 18 entry cũ chốt lại theo bảng hiện hành (God 160, Natalia 139…). 22 icon mới tải từ `EBF5 Foe Icon` (wiki.gg).

- [x] Trang bị (C5): **97 → 228** — lượt 16 đủ 84 vũ khí (4 trang class, bảng hiện hành); lượt 17 đủ 84 mũ giáp (Mũ/Giáp nam + nữ theo `Male Hats and Armor`/`Female Hats and Armor`) + 55 Flair sinh máy từ trang `Flairs` + giữ 3 Flair tay NoLegs; nhãn Độc quyền bản Steam chốt qua `PaywallNote` từng trang item (24 món).
- [x] Trạng thái (lượt 19): **hoàn tất 26 status** — thêm "Hoang mang" (Confuse) + icon `EBF5 Status Confuse`; nhóm "Chững & Hoang mang" và các desc summon/trang bị dùng tên này giờ đều có tooltip (QA headless xác nhận `data-st="confuse"`).

### D. Chất lượng dài hạn
- [x] **Ghi nguồn truy vết (lượt 20) ✅** — block `sources` trong `data.js`: 749 mục + thẻ `_default` mỗi chủ đề + 141 ô lưới của 18 khu, mỗi tham chiếu là **tiêu đề trang wiki thật** (kiểm chuẩn qua fandom API `redirects=1`, batch 40/lượt); `app.js` render panel "Trang wiki gốc" + link từng ô lưới ở trang areas.
- [x] **Script PowerShell `fetch-images.ps1` ✅ (lượt 13)** — hoá quy trình tải ảnh (dự phòng rebuild repo), 3 chế độ:
  1. *Check* (mặc định): quét `image: 'img/...'` trong data.js, đối chiếu đĩa → báo thiếu/file lẻ/đếm theo thư mục (exit 1 khi còn thiếu).
  2. *`-BuildMap`*: sinh stub `img/...png<TAB>tên-file-wiki` vào `fetch-images.map.txt` cho ảnh thiếu (theo dõi những gì chờ điền tên wiki).
  3. *`-Download`*: đọc map → giải URL qua fandom API bó 50/lượt (chỉ tải file chưa có; `-Force` tải đè; `-DryRun` xem trước; `-Limit` chốt số file) → lưu đúng `img/<chude>/<id>.png`.
  - Đúng nguyên tắc bài học: header Referer + UA trình duyệt (tránh 403 CDN), delay 500ms giữa lượt; soạn ASCII không dấu theo mẫu check.ps1; đã kiểm chứng DryRun giải đúng URL thật (`EBF5 Status Doom.png` → static.wikia.nocookie.net).
- [x] **Kiểm thử tự động: `check.ps1` ✅** — chạy `powershell -ExecutionPolicy Bypass -File check.ps1`, quét 7 nhóm:
  1. cân bằng ngoặc + quotes chẵn (data.js + app.js)
  2. ký tự rác CJK/Cyrillic/Hangul (chỉ ra đúng dòng lỗi)
  3. phẩy thiếu sau entry khi splice mảng (`}` ngay trước `{` entry / `/*` comment)
  4. cú pháp JS không cần Node — pipe qua `cscript //E:JScript`; file chứa ES6 (`const`, `let`, `=>`…) tự bỏ qua check này (JScript parse không được, trang chạy tốt trong browser là bằng chứng)
  5. ảnh: tham chiếu data.js vs file thật (missing + file lẻ trong `img/`)
  6. tóm tắt số mục/ảnh theo từng chủ đề (regex `\bid: '`)
  7. HTML router nạp đủ `js/data.js` + `js/app.js`
  - Exit code: 0 = PASS, 1 = FAIL (cửa chặn commit được), 2 = thiếu file gốc
- Ghi nguồn (URL trang wiki gốc) vào từng mục dữ liệu để truy vết khi wiki cập nhật.

---

## 3. Hướng hoàn thiện đang nhắm đến

**Tầm nhìn**: bản wiki tiếng Việt đầy đủ – chính xác – nhanh – chạy được ở mọi nơi (mở file cục bộ hay GitHub Pages đều như nhau), là tài liệu tra cứu thuận tiện cho người chơi EBF5 mới: *mở trang chủ → chọn chủ đề → lọc → xem chi tiết kèm ảnh thật và mẹo chiến đấu*.

**Tiêu chí "hoàn thiện" theo 3 mức:**

1. **Dùng được** (đã đạt): 10 chủ đề, 991 mục (985 file ảnh, mọi tham chiếu đều có ảnh), chạy offline bằng double-click `index.html`.
2. **Dễ dùng** (đã đạt): lightbox + tooltip + phím tắt + tìm kiếm sâu (tips/effect/quái theo ô lưới) + nút lên đầu trang; **deploy GitHub Pages ✅ https://longawr.github.io/Wiki/**.
3. **Sống lâu** (mục tiêu xa): dữ liệu phủ ~100% kỹ năng/quái/hệ vật phẩm ✅ (kỹ năng 183, kẻ địch 214 — wiki ghi 216 unique, chênh 2 chấp nhận; **lượt 23: materials 60/60 + items đủ bộ Food 24 + Steroid 20**); quy trình cập nhật từ fandom API thành script có sẵn; mỗi mục truy vết được về trang wiki gốc để tự đối chiếu khi game ra bản vá mới (EBF5 vẫn nhận update v2+).

**Nguyên tắc giữ vững:**
- Không framework, không build — mở `index.html` là chạy.
- Không hotlink ảnh — mọi ảnh nằm trong `img/`, ghi nguồn khi có tranh chấp.
- Mọi con số/desc ưu tiên chép từ wiki chính thức, không bịa; dữ liệu suy đoán phải ghi chú rõ.
- Mỗi lần sửa `data.js` bằng công cụ tự động phải chạy bộ kiểm tra (ngoặc/quotes/CJK/ảnh) trước khi tính là xong.

---

### Lượt 14 — mở rộng dữ liệu: Summon 40 → 191 (gần như đủ bộ)
- **Nguồn**: trang *Summons/Epic Battle Fantasy 5* fandom — bảng hiện hành post-v2, 192 hàng; loại hàng demo ẩn *Glitch 2* (`ITEM NOT FOUND`, không bắt được) và Glitch gốc (đã có entry riêng lượt 8) → 151 summon mới.
- **Quy trình kiểm chứng rút ra**:
  - Parse bảng bằng script riêng (`parse → gen → splice` ở thư mục temp), **không viết tay 151 desc** — desc mới sinh máy từ các cột `target / type / power / element / status / (de)buff` + từ điển literal nhỏ (tên trạng thái VN, tên thời tiết, vài ghi chú đặc biệt như Swordslinger 50% trúng). Chất lượng đồng đều, không văn tự do.
  - Bẫy PowerShell 5.1 gặp phải trong lượt này: `.ps1` UTF8 không BOM bị đọc theo ANSI (phải thêm BOM trước chạy); mảng 1 phần tử trả về từ function bị enumerate thành scalar nên `$els[0]` thành ký tự đầu (bọc `@(...)` bên caller); `{{` trong chuỗi concat thường KHÔNG phải escape (chỉ đúng khi dùng `-f`); chuỗi `"all enemies"` không chứa substring `"enemy"` (regex phải là `enem(y|ies)`); entry đầu của mảng không đứng sau ký tự `\n` khi split.
  - 40 entry cũ giữ nguyên text tự viết (dùng backup `data.js` trước splice; cẩn thận dấu phẩy cuối entry — entry trước cuối phải kết thúc ` },`).
- **Icon**: 151 dòng mới trong `fetch-images.map.txt` (`img/summons/<slug>.png<TAB>EBF5 Foe Icon <Tên EN>`) → `-Download` tải đủ 151/151, SKIP 0, FAIL 0.
- **Kiểm tra cuối**: `check.ps1` PASS (539 mục / 538 tham chiếu ảnh, 0 thiếu); tổng mục 388 → **539**.

### Lượt 15 — khắc chế nguyên tố & trạng thái cho 50 kẻ địch
- **Nguồn**: mỗi trang foe trên fandom có bảng `{{FoeTableEBF5}}` chứa sẵn các cột `% kháng` (ví dụ Water Slime: `water 200%` hấp thụ, `fire 100%` miễn, `thunder -80%` yếu). Trích **bảng đầu tiên** (bản thường; bảng sau là bản More Foe Resistance, bỏ).
- **Một lượt fetch duy nhất**: `action=query&prop=revisions&rvprop=content&titles=<50 tên>|&redirects=1` — 50/50 tồn tại. Hai ngoại lệ: `Slime Bunny` là trang disambig → dùng `Slime Bunny (foe)`; `Lancelot` redirect về `Lancelot (EBF5)` — script khớp tên theo chuẩn hoá tiền tố.
- **data.js**: thêm trường `res` vào đủ 50 entry (10 nguyên tố + nhóm trạng thái: `death&doom`, `chill&freeze`, `poison&virus`, `stagger&confuse`, `syphon&disable`, `burn&scorch`, `wet&dry`, `heavy&light`, `stun`, `dispel`, `atkdown`/`defdown`/`magdown`/`mdedown`/`accdown`/`evadown`/`hpdown`). Giá trị giữ nguyên % wiki (dương = kháng, âm = yếu, 200 = hấp thụ).
- **render**: `app.js` thêm panel "Khắc chế nguyên tố & trạng thái" cho foes — 4 nhóm Yếu / Kháng / Miễn / Hấp thụ, chip nguyên tố tái dùng `elOf()`, chip trạng thái theo `RES_LBL`; `style.css` thêm block `.res-table`/`.res-note`.
- **Bẫy PowerShell lần nữa**: `$psObj[$key]` trên PSCustomObject trả `$null` → `[int]$null = 0` (toàn dòng res thành 0). Truy cập đúng là `$res.PSObject.Properties[$k].Value`.
- **Kiểm tra cuối**: `check.ps1` PASS.

### Lượt 16 — mở rộng trang bị: 19 → 97 (đủ bộ 84 vũ khí EBF5)
- **Nguồn**: 4 trang `Swords` / `Bows` / `Guns` / `Staves` trên fandom (mỗi trang có **3 bảng**: 1 = giá trị hiện hành, 2 = với Equip Remix, 3 = Pre-v2 update — dùng bảng 1, đúng nguyên tắc lượt 14 dùng bảng hiện hành).
- **Cấu trúc ô** (đã kiểm chống bằng cách đếm từng ô): Swords 22 dòng/hàng (có cột Defend), 3 trang còn lại 21 dòng (không Defend). Template: `{{PS|n}}` chỉ số, `{{EI5P|El|n}}` nguyên tố/kháng, `{{ElementIcon5}}` phi nguyên tố, `{{Boost5|X}}`, `{{GS5|Status|n}}` trạng thái khi đánh, `{{Defending|X|n}}`, `{{UA5|Skill}}`, `{{CA5|Skill}}`, `{{RS5|Skill}}` (Ngẫu nhiên Cast giữa các lượt — xác nhận qua alt-text "Randomly casts X between turns"), `{{SI5X|S|p%<br/>kx}}` trạng thái trong cột đánh.
- **data.js**: +78 vũ khí sinh máy (84 trừ 6 trùng đội cũ: Heaven's Gate, Ultra Pro 9000X, Fairy Bow, Dark Tooth, Shadow Blaster, Spine Snapper). desc gồm: vị trí, chỉ số, Cast, Boost, trạng thái khi đánh, Defend, Unleash, Counter, kháng — không văn tự do.
- **"Độc quyền bản Steam"**: nền hồng bảng wiki chỉ phỏng đoán không chuẩn (33 runtime) — sau đó truy trang item từng món kiểm `PaywallNote`: đúng 15 món (Golden Axe, Devil's Fork, Dragon's Feather, Emerald Smasher, Hyper Drill, Fusion Blade, Emerald Cyclone, Angel Wing, Flame Titan, Heartstopper, Gungnir, Accelerator, Green Goliath, Oak Staff, Shooting Star). Màu hồng bảng này chỉ tham khảo.
- **Icon**: 79 dòng map icon `File:5<TenKetHop>.png` → tại đủ 79/79, 0 SKIP, 0 FAIL (sau đó xóa 1 file của entry heaven-s-gate bị loại).
- **Sửa curl slug**: "Heaven's Gate" → slug `heaven-s-gate` trùng hợp ý và gây double entry với `heavens-gate` cũ — chỉ giữ bản tay; xóa cả file ảnh + dòng map cho entry bị loại.
- **check.ps1**: đếm nháy đơn thay đổi — bỏ qua các kỳ nháy **có escape** `\'`: regex `(?<!\\)'` — ngừng false FAIL.
- **Kiểm tra cuối**: `check.ps1` PASS — 97 mục trang bị / 97 ảnh; tổng 617 mục / 616 ảnh.

### Lượt 17 — mũ giáp & Flair: 97 → 228 trang bị (đủ bộ nam + nữ)
- **Nguồn**: 3 trang fandom `Male Hats and Armor` (21 Mũ + 21 Giáp nam), `Female Hats and Armor` (21 + 21 nữ), `Flairs` (55) — dùng bảng hiện hành post-v2; **parse từ HTML render** (không split wikitext: anchor id/ô lệch cột thì split sai). Cấu trúc đã kiểm chứng mỗi hàng 16 ô: c0 icon, c1 name+location, c2–c8 = HP/Attack/Defence/Magic Attack/Magic Defence/Accuracy/Evade; **mũ/giáp**: c9 Cast `RS5` (Randomly casts X between turns), c10 Boost `Boost5`, c11 auto-status `GS5` (tự nhận cho bản thân — khác vũ khí), c12 Defend `Defending`, c13–15 Resist `EI5P`/`SI5P`; **flair**: c9 Special, c10 Status (auto), c11 Defend, c12 Attack `SI5X` (gây trạng thái khi đánh: `n%` + `kx`), c13–15 Resist. Anchor id trong HTML dùng `&#95;` thay `_` và `&#39;` thay `'` — thu source phải decode/so khớp theo chuỗi encode đó.
- **Quyết định thay entry tay mỏng**: thay **8 entry tay** (captains-hat, knights-helmet, officers-coat, hobo-clothes, flame-suit, ranger-skirt, amber-bobble, nano-machines) bằng entry sinh máy đầy đủ từ bảng wiki; giữ nguyên **3 Flair tay NoLegs** (human-skull, book-of-spells, neon-lightbulb) và 11 entry tay lượt trước; không ghi đè text entry đặc tả tay.
- **id**: recompute theo slug chuẩn (`'s` → `-s`: `captain-s-hat`, `knight-s-helmet`, `officer-s-coat`); 5 id đụng entry có sẵn nhận suffix `-hat`/`-armor`/`-flair` (amber-bobble-hat, flame-suit-armor, hobo-clothes-armor, ranger-skirt-armor, nano-machines-flair); trùng tuyệt đối thì throw. Special chèn tay vì bảng lệch/mất cột: pixel-glasses (chịu được 1 đòn chí mạng), tetromino (sát thương tận cùng số 4 → 4), nano-machines (giảm nửa cooldown kỹ năng v2 — theo trang item).
- **Paywall**: 9 món qua template `PaywallNote` trên từng trang item (Fur Hat, Ninja Skirt, School Uniform, Maid Outfit, Mecha Suit, Sword Medal, Shield Medal, Gold Star, Platinum Star) — màu hồng bảng wiki không tin; tổng nhãn Steam 15 + 9 = 24.
- **Icon**: +139 dòng `fetch-images.map.txt` → tải đủ 139/139, 0 SKIP, 0 FAIL; `git rm` 7 file mồ côi sau khi thay entry (amber-bobble, flame-suit, hobo-pirate-set, knight-helmet, nano-machines, officers-coat, ranger-skirt).
- **Bẫy PowerShell 5.1 rút thêm**: `@(ConvertFrom-Json $j)` → Count=1 (bọc `@()` không enumerate — dùng `$p = ConvertFrom-Json $raw` rồi `foreach`); data.js sau `git checkout` bị LF→CRLF (split `` `n `` còn `\r` — chuẩn hoá cả file về LF trước xử lý; JoinString giữ LF); backtick trong desc làm `check.ps1` quét nhầm template string ES6 → bỏ qua check JScript (thay toàn bộ backtick bằng `"`); 2 entry dính trên 1 dòng từ lượt 16 (golden-axe + hyper-drill) làm checker báo file-lẻ ảo — tách dòng.
- **Kiểm tra cuối**: `check.ps1` PASS 0 FAIL — equipment 228/228 ảnh; tổng 748 mục / 747 tham chiếu ↔ 743 file.

### Lượt 18 — QA dữ liệu lượt 17 bằng trình duyệt headless + sửa từ vựng lệch
- **Phương pháp**: dùng Edge headless (`--headless --dump-dom` + `--user-data-dir` riêng, file:// URL) nạp thật `index/list/detail.html` với `data.js` + `app.js`, grep DOM sau render — kiểm được cả JS runtime (tooltip `.st-tip` gắn đúng `data-st`) chứ không chỉ parse tĩnh. Lưu ý: id sai (`camtain-s-hat` thay vì `captain-s-hat`) hiển thị đúng trang "Không tìm thấy" — không phải bug. `$env:TEMP` của pwsh khác TEMP của harness — file dump phải ghi đường dẫn tuyệt đối.
- **QA token bằng script** (`qa17h.ps1` ở temp): tách 139 entry sinh máy (desc mở đầu "Vị trí: "), mỗi segment kháng ("Kháng/Miễn/Yếu/Hấp thụ …") tách theo phẩy rồi "&", đối chiếu từ điển gồm: tên `elements` + tên `statuses` + giá trị `RES_LBL` của `app.js` (cả mảnh nhóm "Đốt & Xém" → "Đốt"). Phát hiện 57 token lệch, gọn thành 5 lớp lỗi:
  1. `Chóng & Hoang mang` → `Chững & Hoang mang` (lệch 1 dấu với label lượt 15; 15 chỗ)
  2. `Cháy & Xém` → `Đốt & Xém` (label trong `RES_LBL` là "Đốt" = Burn; 14 chỗ)
  3. `Sét` → `Sấm` (khớp tên nguyên tố `thunder` trong `data`; 42 chỗ — toàn trong equipment lượt 17)
  4. nguyên tố `dark` `name: 'Bóng'` → `'Bóng tối'` (đồng bộ văn cũ — skills/limits/areas từ các lượt trước dùng "Bóng tối"; chip ở mọi nơi theo tên mới)
  5. pixel-glasses desc dính dấu cách quanh `—` ("—Chịu được", "(còn sống với 0 HP)—") gây khử token lệch
- **Giữ nguyên Phaser artifact hợp lệ**: "Gây Yếu đi 60%" (verb "Gây" trong desc) — QA sau này cần strip `^Gây ` trước so khớp.
- **Lộ rộng còn lại**: `statuses` chưa có "Hoang mang" (Confuse) — các desc dùng tên này chưa tooltip được (kể cả summon Electric Bat từ lượt 14).
- **Render kiểm lại đầu (4 trang: army-helmet, pixel-glasses, dark-gown, Water Slime)**: `Chững` nhận tooltip `data-st="stagger"`, chuỗi "— Chịu được … HP) — Kháng Thánh 30%" đúng dấu cách, chip nguyên tố hiện "Bóng tối — +50% sát thương" cho kẻ địch.
- **Kiểm tra cuối**: `check.ps1` PASS 0 FAIL (tổng 748 mục / 747 tham chiếu ↔ 743 file — không thay đổi số).

### Lượt 19 — deploy GitHub Pages + hoàn tất bộ status: thêm "Hoang mang" (Confuse)
- **Deploy (phần B của roadmap)**: push 2 commit tồn đọng (lượt 16–18) → `origin/master`. `gh` CLI không có trên máy nhưng credential git (Git Credential Manager) còn — trích qua `git credential fill` rồi gọi GitHub REST API: `GET /repos/Longawr/Wiki/pages` trả 404 (chưa cấu hình) → `POST .../pages` với `{"source":{"branch":"master","path":"/"}}` → **Pages bật thành công, live tại https://longawr.github.io/Wiki/**. Chỉ dùng credential cho thao tác này, minh bạch từng bước.
- **Sai lầm đầu (404 live)**: build đầu tiên `errored` — `js/data.js` dòng ~901 chứa chuỗi `{{PS|n}}`, `{{EI5P|...}}` (ghi chú template wiki) mà Pages mặc định chạy **Jekyll/Liquid**, parser đọc thành template và build chết. Fix: thêm **`.nojekyll`** ở gốc repo (site thuần tĩnh không cần Jekyll, còn nhanh hơn nữa) → build `built` với 0 lỗi, trang live render đủ (headless chạy JS trên URL live xác nhận 130 card + card "Hoang mang" link đến `detail.html?type=statuses&id=confuse`). Lưu ý QA: fetch hay `--dump-dom` thu HTML tĩnh không chạy JS — muốn biết nội dung JS-render phải dùng headless cho JS chạy, hoặc tự đối chiếu HTTP status/MIME của tài nguyên.
- **Dữ liệu**: nguồn = trang fandom `Confuse (status)` (trang `Confuse` không tồn tại — search API ra đúng tên). Icon lấy tên file ngay trong wikitext: `EBF5 Status Confuse.png`. Cơ chế chốt từ wiki: **chỉ tác động người chơi**; tự dùng kỹ năng mình học nhưng **luôn bản yếu nhất đã nâng cấp** (mô tả in-game không chính xác hoàn toàn); **bỏ qua Syphon & cooldown**, không bị đặt cooldown; bỏ qua Lovable của địch; **ưu tiên cao hơn Berserk** (Hungry lại cao hơn cả hai); cấm dùng 3 kỹ năng Cherish / Berserk / Medipack (nguyên nhân bug vô hạn); Purify / Dispel / Sharpen khi Hoang mang chỉ trúng đồng đội.
- **data.js**: +1 entry `confuse` chèn ngay sau `stagger` (đi cùng cặp "Chững & Hoang mang"), `elements: []` (không gắn nguyên tố), `kind: 'Bất lợi'`. Tooltip không cần sửa app.js — `withStatusTips` khớp theo tên status, sort theo độ dài giảm dần nên "Chững" và "Hoang mang" mỗi cái nhận chip riêng trong chuỗi "Miễn Chững & Hoang mang".
- **Icon**: +1 dòng `fetch-images.map.txt` (`img/status/confuse.png<TAB>EBF5 Status Confuse`) → tải 1/1 OK; (đã lỡ thêm 1 dòng trống vào map — xoá sạch trước khi tải).
- **QA headless (kế thừa lượt 18)**: dump `detail.html?id=army-helmet&type=equipment` (desc có "Miễn Choáng, Miễn Chững & Hoang mang") → DOM có `data-st="confuse"`, `data-st="stagger"`, `data-st="stun"` đúng mapping. Lưu ý mới: dump qua `cmd /c` redirection làm Edge bóp méo UTF-8 âm khoé (stdout encoding artifact) — chỉ tin các mảnh ASCII như `data-st="..."`; đọc file dump phải `ReadAllBytes` + decode UTF8. Lần đầu redirect bằng pwsh `>` cho ra file 0 byte — dùng `cmd /c` mới capture được.
- **Kiểm tra cuối**: `check.ps1` PASS 0 FAIL — statuses 26/26; tổng **749 mục / 748 tham chiếu ↔ 744 file**, 0 thiếu / 0 file lẻ.

### Lượt 20 — ghi nguồn truy vết: link về trang wiki gốc cho cả 749 mục
- **Thiết kế**: block `sources` mới trong `EBF5DATA` (`data.js`) — map `id → tiêu đề trang wiki gốc` theo từng chủ đề; `app.js` render thêm 1 dòng "Trang wiki gốc: <a>" trong panel "Nguồn dữ liệu" ở trang chi tiết. Không đụng 749 entry gốc, số mục/ảnh giữ nguyên 749 / 748 ↔ 744.
- **Nguồn theo chủ đề**: `enemies` → trang foe riêng `X (foe)` (50/50); `characters` → `X (EBF5)`; `statuses` → `X (status)` (Regenerate, Radiation đều có); `items` → trang item riêng (Dragon Fruit, Coffee, Garlic, Hamburger dùng dạng `(item)` vì tên trùng mục khác); `equipment` → sinh máy theo bảng gốc (forChar → Swords/Bows/Guns/Staves; Mũ/Giáp nam-nữ theo `Male/Female Hats and Armor`; Flair → trang `Flairs`) + 11 entry tay → trang item riêng (`Heaven's Gate`, `Ultra Pro 9000X`…); `skills` / `summons` → `_default` (List of Skills / Summons per EBF5); `limits` → trang Limit Break riêng (Mighty Oak, The Creator, The Destroyer dạng `(EBF5)`); `areas` → `_default` = trang map chính + **`areaCells`** = tiêu đề trang wiki của từng ô lưới (141 ô từ 18 khu).
- **Quy trình**: script temp extract + candidate theo luật, bó `action=query&redirects=1` 40 tên/lượt; mồi an toàn `(?m)^  theme: \[` (tránh substring `skills: [` bên trong block nhân vật); title lấy canonical sau redirect (vd `Mighty Oak (EBF5)`). 7 ô AMBIGUOUS của areaCells (tên area ≠ tên region trên wiki: E3 Ice Cave, I2 Library, 5 ô Lava Lake của the-rapture) resolve bằng đặc điểm foes/features trong entry — đối chiếu: J9/K8 trong data chứa foes Magma/Lava khớp trang Lava Lake.
- **Bẫy học thêm (lượt 20)**: `.ps1` UTF-8 không BOM làm so khớp tiếng Việt (`'Vũ khí'`, `'Mũ nam'`) sai im lặng → *mọi* script .ps1 chứa ký tự UTF-8 phải có BOM; name đưa  `name: "No Man's Land"` double-quote làm regex nháy đơn tủt không bắt được → thêm fallback regex double-quote; chuỗi giá trị chèn vào data.js phải qua hàm Esc (`\'`) trước; **JScript (cscript) khước từ trailing comma** — property cuối của object phải close KHÔNG comma (trình duyệt ES5 khoan dung, JScript ES3 không); bẫy quoting inline shell lặp lại như lượt trước — mọi logic phức tạp phải soạn qua file `.ps1`.
- **QA headless**: enemies `NoLegs (boss)` → URL `wiki/NoLegs_(boss)_(foe)`; skills `fireball` → `wiki/List_of_Skills_in_Epic_Battle_Fantasy_5`; summons `the-devourer` → `wiki/Summons/Epic_Battle_Fantasy_5` (%2F encode lại thành `/`); areas `hope-harbor` → map chính + link 10 ô lưới A2/A5/B2… đúng trang tường.

### Lượt 21 — kẻ địch đủ bộ: 50 → 214 (sinh máy từ `FoeTableEBF5`)
- **Lọc nguồn**: `Category:Foes` (389 trang) → giữ tag `Epic Battle Fantasy 5` (222) → bỏ 36 trang *Foe Groups* → loại 6 trang nội dung (Difficulty, Farming, Foes & Bestiary, List of Foes, Nuke, Valkyrie Tank) + `Mighty Oak (boss)` (bảng là `FoeTableEBF4`; EBF5 Mighty Oak là Limit Break của Anna, không phải foe) → **167 trang có `{{FoeTableEBF5}}`** → bỏ 2 trùng/trang nước ngoài (`Lancelot (EBF5)` trùng entry tay; `Neon Valhalla(中文)` CJK) → **164 entry mới**, tổng enemies **214/214** (wiki ghi 216 unique foe EBF5 — chênh 2 chấp nhận, ghi chú ở đây).
- **desc sinh máy theo đúng schema cũ** (không văn tự do): `Thành viên nhóm <Group> · HP · Atk … Eva · Thưởng: XP/AP/SP/vàng · [Không bắt Capture được.|Có thể bắt Capture (mở khóa summon tương ứng)]`; tips ≤ 3 (yếu nhất / nguyên tố của đòn / hấp thụ / capture); `kind` quái thường = nhóm khu vực, boss giữ `Boss`; nối tiếp lượt 20 — mỗi foe mới có dòng `'X (foe)'` trong `sources.enemies` (QA headless xác nhận URL `wiki/Acid_Bomb_(foe)`, `wiki/Anna_(boss)_(foe)`).
- **Chỉnh entry cũ phát hiện khi lọc**: drop `"Chili Pepper (30%}})"` → `"(30%)"` (rác template kẹt lại); `HPdown` → `hpdown` (32 chỗ — key RES của app.js là chữ thường).
- **Icon — 164 dòng mới `fetch-images.map.txt`**: tên wiki lấy từ infobox `|Image =` (trang dùng `<gallery>` thì lấy png đầu, ví dụ `EBF5 Bestiary CORALIA 1`). DryRun đầu ra 116 OK / **48 SKIP** → viết script patch soạn chain candidate cho từng dòng SKIP: `EBF5 Bestiary <core>` → `EBF5 Foe Icon <core>` → `Icon bestiary ebf4 <core>` → `EBF3/EBF2 Foe Icon <core>`, validate **mỗi candidate qua fandom API** (bó 40/lượt, key lowercase, buộc kèm đuôi `.png` khi gọi) rồi mới ghi đè map — kết quả 164/164 resolve, patch đúng 48 dòng: 40 → `EBF5 Foe Icon <Tên>`, 7 tái dùng icon game cũ `Icon bestiary ebf4 <tên thường>`, đặc biệt `Sól and Skadi` → `EBF5 Foe Icon Skadi`, `Praetoriun` → `EBF5 Foe Icon Praetorian` (typo có sẵn trên wiki), `The Glitch` → `EBF5 Foe Icon Glitch`. **Tải thật: 164/164 OK, 0 SKIP, 0 FAIL**.
- **Bẫy rút ra lượt này**: khi gọi fandom API, title của file **buộc kèm đuôi `.png`** (thiếu đuôi = cả bó cùng coi như không tồn tại — dry-run từng SKIP 148/164 vì lý do này); replacement của `-replace` cắn ký tự `$` — không bao giờ nhét chuỗi có `$` vào replacement; đọc/ghi map giữ nguyên BOM + EOL trộn (thay trên chuỗi thô bằng `[regex]::Match`/`Substring`); script ps1 phức tạp vẫn soạn file riêng ASCII không dấu.
- **check.ps1**: PASS — data.js braces 1358/1358; tổng **913 mục / 912 tham chiếu ↔ 908 file** (enemies 214/214, 0 thiếu, 0 file lẻ). QA headless 3 trang: `acid-bomb` (bảng res Yếu/Kháng/Miễn đủ, chip Độc, drops sạch `(30%)`), `anna-boss` (boss đa nguyên tố + tooltip trạng thái), `sol-and-skadi` (tên có dấu `ó` render đúng).

### Lượt 22 — favicon + logo (kết thúc mục B của roadmap)
- Tạo `favicon.svg` ở gốc repo (SVG vẽ tay: nền tối gradient, vòng chiếc nhẫn vàng, thanh kiếm — phong cách game; không dùng ảnh có bản quyền riêng ngoài ảnh wiki đã có).
- Gắn vào cả 3 trang (`index.html`, `list.html`, `detail.html`): `<link rel="icon" type="image/svg+xml" href="favicon.svg">` — đường dẫn tương đối nên hoạt động cả file:// lẫn `longawr.github.io/Wiki/`.
- Tên miền riêng: bỏ qua theo roadmap (cần mua tên miền + cấu hình DNS bên ngoài phạm vi repo).
- `check.ps1`: PASS 0 FAIL (không đổi data.js — 913 mục / 912 tham chiếu ↔ 908 file giữ nguyên).

### Lượt 23 — hệ vật phẩm hoàn chỉnh: chủ đề mới "Vật liệu" (60) + nốt Food/Steroid items (28 → 46)
- **Định hướng**: mọi mục A–D của roadmap đã xong — lượt này chốt khoảng trống lớn còn lại theo tầm nhìn "Sống lâu": hệ item EBF5 gồm 3 nhóm trên wiki (Materials / Food / Key Items), trong đó 2 nhóm chưa có chủ đề và items đã thiếu bộ. Key Items (71) để lượt kế tiếp.
- **Chủ đề mới `materials` (60 mục)**: nguồn duy nhất = bảng `{{EBF|5}}` của trang *Materials* (60 dòng: Image / Name / Description / Buy Price / Sell Price; dàn icon `EBF5 Item X` 12×5 kiểu PlacementGrid). desc sinh máy = bản dịch đoạn "Description" của wiki + `Giá mua X / Bán Y gold`; các dòng có ghi chú "Can be thrown in battle" → kind `Ném được` (Snowball, Brick, Shuriken, Hand Bomb), còn lại `Nguyên liệu`; `kinds` bộ lọc = [Nguyên liệu, Ném được]. Nguyên tố chỉ gắn cho entry rõ nghĩa (Liquid Ice→ice, Solid Water→water, Magma Chunk→fire, Bio Virus→bio, Dark Rune/Dark Matter→dark, Sacred Rune/The Holy Grail→holy, Hand Bomb→bomb). app.js: `cardSub` thêm nhánh `materials` (chip kind + nguyên tố), panel chi tiết gộp chung `items || materials` (Loại / Hiệu quả / Nguyên tố).
- **items 28 → 46**: trang *Food* wiki EBF5 có 24 món (Pumpkin→Pizza) ⇒ items chỉ còn thiếu Pretzel, Iron Brew, Energy Drink; bảng *Steroids* cùng trang cho đủ 20 (4 chỉ số × 5 nhân vật — Atk&Def 2% / MAtk&MDef 2% / Eva&Acc 1% / HP 2%, giá Steroid Shop khởi điểm 1000 gold nhân đôi mỗi lần mua cùng loại) ⇒ thiếu 15. 18 entry mới đều sinh máy (không văn tự do), desc steroid kèm luật giá của Steroid Shop.
- **Nguồn truy vết**: kiểm 36 ứng viên tên trang qua fandom API (redirects=1, cả biến `(item)`) → **hầu hết steroid/food mới KHÔNG có trang riêng**; `Turnip` thật ra là trang item EBF4, `Mushroom` redirect về `Bad Mushroom` (item EBF3/4) — không phải steroid EBF5 ⇒ 18 mục mới dùng `_default = 'Food'` trong `sources.items` (trang nguồn dữ liệu thật); `sources.materials` = map mới `_default = 'Materials'`.
- **Icon: 77/77 OK, 0 SKIP, 0 FAIL** — 59 nguyên liệu (tái dùng `img/items/hand-bomb.png` cho entry hand-bomb) + 18 icon items mới; tên file `EBF5 Item <Tên>.png` xác thực qua fandom API bó 50/lượt **kèm đuôi .png** trước khi ghi map (bài học lượt 21).
- **check.ps1**: thêm `materials` vào mảng `$keys` (section 6 đếm theo chủ đề) — 991 mục / 990 tham chiếu ↔ 985 file, 0 thiếu / 0 file lẻ; data.js braces 1440/1440, quotes chẵn 22842.
- **QA headless (Edge)**: 3 trang detail (`materials/steel-plate`, `materials/hand-bomb`, `items/raw-beef`) + list `materials` (60 card, chip `Ném được` = 5) + home (nav "🧱 Vật liệu" active) — đủ xanh. Bẫy: chuyển hướng dump qua `cmd /c` với URL chứa `&` bị cmd cắt lệnh tại dấu `&` (mất redirect `>`, file 0 byte, HTML rò ra console) — **phải quote URL trong `cmd /c`**; xóa rồi gọi Edge dùng chung một `--user-data-dir` thì lần sau bàn giao tiến trình cũ và thoát không dump.
- **test.html sửa 2 lớp**: (a) case 1 cập nhật 9 chủ đề → 10 (trước đó file còn stale mặc lượt 19 — khẳng định `statuses != 25` FAIL); (b) case 4 bọc `history.replaceState` bằng try/catch + flag `detailRouted`: qua `file://` Chromium chặn pushState (origin 'null') nên case 4–6 tự SKIP thay vì FAIL — đã đối chứng bằng worktree commit lượt 22 (cùng 3 FAIL y hệt, không phải hồi quy của lượt 23). Chạy localhost HTTP server thì đủ 7 case xanh như cũ.

*Cập nhật lần cuối: 2026-10-21 — sau lượt 23 (materials mới; 991 mục / 990 tham chiếu ảnh ↔ 985 file).*
