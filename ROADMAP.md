# ROADMAP — Wiki tiếng Việt Epic Battle Fantasy 5

> Wiki tĩnh thuần HTML/CSS/JS, chạy trực tiếp khi mở `index.html` (không build, không server).
> Dữ liệu soạn trong `js/data.js`, đối chiếu theo **Epic Battle Fantasy Wiki** chính thức
> (epicbattlefantasy.fandom.com) — ảnh tải về repo, không hotlink.
> Bản quyền game & ảnh: Matt Roszak / Kupo Games.

---

## 1. Đã làm được

### Kiến trúc
- **SPA router tĩnh 3 trang**: `index.html` (trang chủ), `list.html?type=X` (danh sách + bộ lọc), `detail.html?id=Y&type=X` (chi tiết).
- **Nguồn dữ liệu trung tâm** `js/data.js`: 9 mảng chủ đề + `categories` + `elements` (10 nguyên tố) + `externalWiki`.
- `js/app.js` render mọi thứ: nav tự sinh từ `categories`, thẻ card có ảnh + chip, trang chi tiết có bảng thông tin / panel mẹo / ghi chú nguồn dẫn về trang wiki tương ứng của từng chủ đề.
- `css/style.css`: theme tối phong cách game, card grid, chip, `.detail-media`, fallback `.img-fail`.
- Thêm chủ đề mới = **1 hàng trong `categories` + 1 mảng dữ liệu + (tuỳ) 1 nhánh chip/detail trong app.js**.

### Dữ liệu — 9 chủ đề, 388 mục, 387/382 ảnh (0 thiếu, 0 file lẻ)

| # | Chủ đề | key | Mục | Ảnh | Ghi chú |
|---|--------|-----|-----|-----|---------|
| 1 | Nhân vật | `characters` | 5 | 5/5 | Matt, Natalie, Lance, Anna, NoLegs — lore EBF5 thật, kèm danh mục kỹ năng/trang bị chính |
| 2 | Kẻ địch | `enemies` | 50 | 50/50 | 8 slime thật + 32 quái thường dàn theo 18 khu vực + 10 boss — icon `EBF5 Bestiary X`; **drops thật 50/50** (tên item + % từ bảng `FoeTableEBF5`); **15: khắc chế 50/50** — trường `res` trích cột % `FoeTableEBF5` (10 nguyên tố + nhóm trạng thái), hiển thị Yếu/Kháng/Miễn/Hấp thụ ở trang chi tiết |
| 3 | Kỹ năng | `skills` | 183 | 183/183 | **Đủ bộ 5 nhân vật + 53 Extra Skills** (kèm chars từng người học được từ trang bị), theo *List of Skills in EBF5*; icon `EBF5 Skill X` |
| 4 | Vật phẩm | `items` | 28 | 28/28 | 24 món Food thật (Pumpkin→Pizza, Garlic/Banana gỡ status/debuff, Apple/Cupcake trừ cooldown…) + 5 Steroid từng nhân vật — icon `EBF5 Item X` |
| 5 | Trang bị | `equipment` | 19 | 19/19 | Vũ khí/mũ giáp/Flair tên thật; Crystal Staff có ghi chú "không trở lại EBF5" theo wiki |
| 6 | Trạng thái | `statuses` | 25 | 24/25 | Đủ Doom, Scorch, Berserk, Syphon, Brave, Regen, Vận may…; "Trói chân" (không tồn tại) đã thay bằng Mỏi (Tired) — icon `EBF5 Status X`; Radiation giữ emoji |
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
- `data.js`: braces 585/585, brackets 695/695, quotes chẵn (tính cá biệt Apostrophe trong double-quoted string), 0 ký tự rác, JScript parse OK.
- `app.js`: braces 125/125, brackets 42/42 (file có ES6 sẵn nên JScript bỏ qua, trình duyệt chạy tốt).
- `test.html`: trang smoke test chạy trong trình duyệt (7 case: 9 chủ đề/25 status, `renderDetail` sinh tooltip `.st-tip` + hàng `.prev-next`, lightbox, `#statusTip`, `#toTop`) — mở trực tiếp là chạy, không cần Node; xoá đi khi không cần nữa.
- 387 tham chiếu `image:` ↔ 382 file thật (limit dùng lại icon skills) — **0 thiếu, 0 file lẻ**.
- README + hero trang chủ khớp số liệu thật.

---

## 2. Mục tiêu tiếp theo

### A. UI polish (ưu tiên cao — nâng trải nghiệm ngay) ✅ Hoàn tất lượt 12
- [x] **Lightbox** phóng to ảnh trong trang chi tiết (click ảnh → overlay xem full; đóng bằng ✕ / click nền / Esc).
- [x] **Tooltip icon trạng thái**: hover (hoặc focus) vào tên status trong desc/bảng → hiện icon + mô tả ngắn; **nhấp vào tên** → chuyển tới trang chi tiết status đó. Áp dụng cho desc, tips, strengths/weaknesses, drops, effect, foes/keys/notes của ô lưới, bảng kỹ năng nhân vật.
- [x] **Điều hướng bằng phím** ở trang chi tiết: ←/→ qua mục trước/sau cùng chủ đề, Esc về danh sách (Esc ưu tiên đóng lightbox nếu đang mở; bỏ qua khi đang gõ trong input/select).
- [x] Nút "↑ Đầu trang" (hiện khi cuộn > 400px, mọi trang) + header đã sticky sẵn.
- [x] Tìm kiếm toàn cục — nâng lên tìm theo cả tips/effect/kind: gộp tên + desc + kind + effect + unlock + slot + tips/features/strengths/weaknesses/drops + kỹ năng trong trang nhân vật + **quái & Key Items trong từng ô lưới khu vực** + tên nhân vật học kỹ năng; trang danh sách dùng chung nên tìm theo type=all ăn theo.

### B. Triển khai (để wiki dùng được thật)
- [x] `git init` + commit đầu tiên ✅ (commit `343eeba`, working tree sạch; warning LF→CRLF vô hại).
- [ ] Đẩy lên GitHub, bật **GitHub Pages** (thuần tĩnh nên chạy ngay, không cần build).
- [ ] Kiểm tra lại đường dẫn tương đối `img/...` sau deploy (đã dùng tương đối nên an toàn).
- [ ] (Tuỳ) tên miền riêng + favicon/logo.

### C. Mở rộng dữ liệu (dày hơn nữa)
- [x] Kỹ năng: phát hiện trang tổng *List of Skills in Epic Battle Fantasy 5* — thêm **91 entry (39 → 130)** rồi **53 Extra Skills (130 → 183)**, kèm ảnh chuẩn; status hoàn tất bộ 5 nhân vật + **danh sách ai học được từ trang bị** cho Extra Skills.
- [x] Kẻ địch: bổ sung cột **drops thật 50/50** (tên item + tỉ lệ %) từ bảng `FoeTableEBF5` của từng trang quái — 48/50 có drop thật, Slime Bunny & Lancelot ghi chú "không drop".
- [x] Limit Break: **phủ kín 20/20 icon** — 5 cái tải từ `EBF5 Skill X` (bảng *Extra Limit Breaks*), 4 cái tái sử dụng icon mảng skills; Radiation status giữ emoji (wiki không có file).
- [x] Khu vực (C3): **quái + Key Items theo từng ô lưới cho đủ 18 khu** — parser nguồn các trang `Epic Battle Fantasy 5 Map/X` (điểm xuất phát theo ô lưới, wave quái, Key Items, ô con như Nhà Matt/Phòng Arcade/Khu Glitch), các ghi chú cơ chế dịch tay (rương mở bằng mã, Đầu Đá trên bệ đá, cần gạt, Arcade Boss Rush…), bỏ các ghi chú trivia (mã Morse, tên hex glitch). Hiển thị trong panel areas "Ô lưới — Quái và Key Items".
- [x] Summon (C4): **mở rộng 18 → 40 + cột "Mở khoá"** — nguồn = trang *Summons/Epic Battle Fantasy 5*, dùng bảng hiện hành post-v2 (bảng chính; bảng `Pre-v2 update` chỉ giữ đối chiếu). 22 summon mới: Glitch, Annabelle, Lancelot, Matteus, Laurelin, War Mammoth, Sól, Viking Monolith, Ultra Chibi Knight, Zombie Hand, Wooden Idol, SNEK, Roasted Gloop, Sapphire Ore, Ruby Ore, Amethyst Ore, Red Bush, Metal Idol (14, heavy +5), Cat Sniper, PUMPKUS, Cutie Worm, Cat Wizard; SP của 18 entry cũ chốt lại theo bảng hiện hành (God 160, Natalia 139…). 22 icon mới tải từ `EBF5 Foe Icon` (wiki.gg).

### D. Chất lượng dài hạn
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

1. **Dùng được** (đã đạt): 9 chủ đề, 388 mục (387 có ảnh thật), chạy offline bằng double-click `index.html`.
2. **Dễ dùng** (đã đạt lượt 12): lightbox + tooltip + phím tắt + tìm kiếm sâu (tips/effect/quái theo ô lưới) + nút lên đầu trang; deploy GitHub Pages để chia sẻ link (còn lại phần B).
3. **Sống lâu** (mục tiêu xa): dữ liệu phủ ~100% kỹ năng/quái; quy trình cập nhật từ fandom API thành script có sẵn; mỗi mục truy vết được về trang wiki gốc để tự đối chiếu khi game ra bản vá mới (EBF5 vẫn nhận update v2+).

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

*Cập nhật lần cuối: 2026-10-20 — sau lượt 15 (khắc chế 50/50 kẻ địch từ bảng FoeTableEBF5 wiki + panel hiển thị Yếu/Kháng/Miễn/Hấp thụ; tổng dữ liệu giữ nguyên 539 mục).*
