# ⚔️ EBF5 Wiki (Tiếng Việt)

Wiki tĩnh cho game **Epic Battle Fantasy 5** (Matt Roszak / Kupo Games), được dựng bằng
HTML + CSS + JavaScript thuần — **không cần cài đặt, không cần build**.

> 📚 Dữ liệu "Nhân vật / Kỹ năng / Trang bị" đã được đối chiếu theo
> [Epic Battle Fantasy Wiki chính thức](https://epicbattlefantasy.fandom.com/wiki/).
> Ảnh render nhân vật tải từ wiki về thư mục `img/` (độc quyền thuộc Matt Roszak /
> Kupo Games).

🌐 **Trực tuyến:** https://longawr.github.io/Wiki/ (GitHub Pages)

## 🚀 Chạy trang wiki

Chỉ cần mở file `index.html` bằng trình duyệt (double-click). Không cần server.

Nếu muốn chạy qua server cục bộ (khuyên dùng để tránh hạn chế `file://` của trình duyệt):

```cmd
python -m http.server 8080
:: hoặc
npx serve .
```

sau đó mở `http://localhost:8080`.

## ✅ Kiểm tra sức khoẻ wiki

Sau mỗi lần sửa `js/data.js` / `js/app.js`, chạy script kiểm tra tự động (không cần Node):

```powershell
powershell -ExecutionPolicy Bypass -File check.ps1
```

Script quét: cân bằng ngoặc/quotes, ký tự rác (CJK/Cyrillic/Hangul), phẩy thiếu sau entry khi splice mảng, cú pháp JS (JScript), ảnh tham chiếu vs file thật, số mục theo chủ đề, và HTML router nạp đủ script. Exit code `0` = PASS, `1` = FAIL.

## 🖼️ Tải / khôi phục ảnh (`fetch-images.ps1`)

Dự phòng cần rebuild repo — hoá quy trình tải ảnh từ wiki chính thức:

```powershell
powershell -ExecutionPolicy Bypass -File fetch-images.ps1            # Check: thiếu / file lẻ / đếm theo thư mục
powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -BuildMap  # sinh stub ảnh thiếu vào fetch-images.map.txt
powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -Download -DryRun  # xem trước URL
powershell -ExecutionPolicy Bypass -File fetch-images.ps1 -Download -Limit 30
```

- Map file phân cách bằng TAB: `img/<chude>/<id>.png<TAB>tên-file-trên-wiki` — cột 2 trống = bỏ qua.
- Tải qua fandom API (bó 50/lượt), tự gửi header `Referer` + User-Agent trình duyệt (CDN cần để tránh 403), chỉ tải file chưa có (`-Force` để tải đè), tạo sẵn thư mục con, exit `1` khi còn FAIL/thiếu.

## 🔁 Cập nhật dữ liệu từ wiki (`update-data.ps1`, lượt 26–27)

Kiểm độ "tươi" của data.js so với fandom wiki và tự sửa phần lệch có thể sửa:

```powershell
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update enemies
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update statuses
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update items
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources        # chỉ báo cáo title stale
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update sources -Fix   # tự sửa title stale trong data.js
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update areas          # báo ô lưới/cặp areaCells thiếu
powershell -ExecutionPolicy Bypass -File update-data.ps1 -Update areas -Fix     # tự thêm cell + cặp areaCells vào data.js
```

- `enemies`: liệt kê trang foe gắn `{{FoeTableEBF5}}` qua API `list=embeddedin` (215 trang hiện nay), so khớp **tên chuẩn hoá** (lower, gộp khoảng trắng, bỏ đuôi `(foe)`/`(item)`/`(status)`/`(EBF5)`/`(boss)`/`(EBF5 boss)`, bỏ suffix ngoặc chứa ký tự non-ASCII như bản ngôn ngữ khác — quy tắc ăn khớp cả `God (EBF5 boss)` lẫn `Neon Valhalla(中文)`) với entry `enemies` + `sources.enemies` → báo foe mới xuất hiện trên wiki.
- `statuses`: so heading có icon EBF5 của trang *Status Effects* (41) với title per-entry lẫn **id entry** (tên như Epic/Brimstone/Stoned/Undead/Repulsion/Regen không có trang riêng nên phải khớp qua id); `items`: so anchor `5<Tên>` của trang *Food* (44) với title + id (dash chép thành space) — entry không trang riêng được tính đã phủ qua `_default`.
- `sources`: kiểm từng title per-entry trong block `sources` (674 mục, trừ `_default`) còn tồn tại trên wiki (`redirects=1`, bó 40/lượt). `-Fix` chọn trang theo thứ tự: (1) foes → trang thật khớp theo norm map từ 215 trang FoeTableEBF5 (`God (foe)` → `God (EBF5 boss)`, `Sand Worm (foe)` → `Sand Worm`); (2) tách suffix + redirect chuẩn (`The Destroyer (EBF5)` → `The Destroyer (boss)`); (3) không tồn tại trang riêng → trang `_default` của chủ đề (26 item Food/Steroid trần → `Food`, Radiation/Regen → `Status Effects`). Chỉ thay pair khi chuỗi xuất hiện **đúng 1 lần** trong block sources, thay bằng `String.Replace` literal (không regex — replacement chứa `$` không an toàn), ghi UTF-8 **no BOM**.
- `areas` (lượt 27–28): quét 303 trang `Epic Battle Fantasy 5 Map/GR Tên khu` (nhóm 20/lượt), parse bảng `Foes`/`Treasures` — ô có nội dung = có foes hoặc [Key Items#] thật (hàng chỉ material không tính) — đối chiếu `areas.cells` 18 khu chính + `sources.areaCells` 2 chiều. Ô đã tách thành entry `kind: 'Khu con'` được bỏ qua khi đối chiếu khu mẹ, nên `-Fix` không tự thêm lại. Sau đó `check.ps1` section 8 tự kiểm 205 cặp khớp nhau.
- Exit code: `0` = đã phủ / sạch, `1` = phát hiện foe/status/item mới hoặc title stale (hoặc ô lưới/cặp `areas` thiếu), `2` = lỗi. Sau mỗi lần script tự sửa data.js, chạy lại `check.ps1` để kiểm tra toàn bộ.

## 📁 Cấu trúc dự án

```
Wiki/
├─ index.html     → Trang chủ (tìm nhanh, tổng quan chủ đề, bảng nguyên tố)
├─ list.html      → Trang danh sách (tìm kiếm + lọc theo nguyên tố/loại)
├─ detail.html    → Trang chi tiết (dùng chung cho mọi chủ đề)
├─ img/           → Ảnh render nhân vật (Matt, Natalie, Lance, Anna, NoLegs)
├─ css/style.css  → toàn bộ giao diện
└─ js/
   ├─ data.js     → ⭐ DỮ LIỆU WIKI (bạn sẽ sửa file này nhiều nhất)
   └─ app.js      → logic render (không cần động tới)
```

## ✏️ Cách thêm / sửa nội dung

Toàn bộ nội dung nằm trong **`js/data.js`**, chia theo chủ đề:

| Chủ đề | Biến trong data.js | Ghi chú |
|---|---|---|
| Nhân vật | `characters` | 5 nhân vật, dữ liệu theo wiki chính thức, có ảnh |
| Kẻ địch | `enemies` | **216 mục — khớp đúng "216 unique foe" của wiki** (8 slime thật + quái thường theo 18 khu vực + boss + entry sinh máy lượt 21 từ bảng `FoeTableEBF5`; lượt 26 tách 2 entry gộp: `sol-and-skadi` → **Sól** + **Skadi**, và **Glitch nhỏ** vào entry riêng cạnh **The Glitch** boss) — so khớp qua script `update-data.ps1 -Update enemies` với 215 trang foe gắn `FoeTableEBF5` trên fandom — 216/216 có ảnh (`EBF5 Bestiary <Tên>`, thiếu mới dùng `EBF5 Foe Icon` / `Icon bestiary ebf4`) — **drops thật** (tên item + %) — **khắc chế nguyên tố & trạng thái** (`res` từ cột % của `FoeTableEBF5`) — trang chi tiết hiển thị bảng Yếu / Kháng / Miễn / Hấp thụ, kèm link trang wiki gốc từng foe |
| Kỹ năng | `skills` | **183 mục — đủ bộ 5 nhân vật + 53 Extra Skills (kỹ năng học qua trang bị, kèm danh sách nhân vật học được)** theo *List of Skills in Epic Battle Fantasy 5* + Guard; 183/183 icon chuẩn `EBF5 Skill X`; Guard dùng icon EBF4 (lệnh giống hệt) |
| Vật phẩm | `items` | 46 mục (lượt 23 đủ bộ): 1 entry nhóm Food + 24 món Food thật của EBF5 (Pumpkin → Pizza, thêm Pretzel, Iron Brew, Energy Drink) + 20 Steroid (4 chỉ số × 5 nhân vật, theo bảng Steroids của trang Food) + Hand Bomb (throwable) — tất cả đều có icon (`img/items/`) |
| Vật liệu | `materials` | **60 mục — đủ bộ nguyên liệu forge EBF5** sinh máy từ bảng EBF5 của trang *Materials* (tên, mô tả wiki, giá mua/bán; món "Can be thrown in battle" loại `Ném được`: Snowball, Brick, Shuriken, Hand Bomb — Hand Bomb tái dùng icon của items) — 60/60 có icon `EBF5 Item X` (`img/materials/`) |
| Trang bị | `equipment` | **228 mục** — 86 vũ khí (78 sinh máy lượt 16 theo 4 trang `Swords`/`Bows`/`Guns`/`Staves` bảng hiện hành post-v2 + 8 entry tay: Heaven Gate, Ultra Pro 9000X, Fairy Bow, Dark Tooth, Shadow Blaster, Spine Snapper, Crystal Staff, Steel Buckler) + **84 mũ giáp** (21 Mũ nam + 21 Giáp nam + 21 Mũ nữ + 21 Giáp nữ, bảng hiện hành post-v2 của `Male Hats and Armor`/`Female Hats and Armor`) + **58 Flair** (55 sinh máy từ trang `Flairs` + giữ 3 món tay NoLegs: Human Skull, Book of Spells, Neon Lightbulb) - desc sinh máy gồm vị trí, chỉ số, hiệu ứng (Cast triệu hồi ngẫu nhiên / Boost / Trạng thái tự nhận / Defend / Gây trạng thái khi đánh / Kháng) - 24 món nhãn Độc quyền bản Steam (15 lượt 16 + 9 lượt 17: Fur Hat, Ninja Skirt, School Uniform, Maid Outfit, Mecha Suit, Sword Medal, Shield Medal, Gold Star, Platinum Star) - **228/228 có ảnh** (`img/equipment/`) |
| Trạng thái | `statuses` | **48 hiệu ứng — đủ bộ trạng thái EBF5** theo trang *Status Effects* (lượt 25: thêm Tích lực, Phòng thủ, Epic — aura trận God, Tốc hành, Đáng yêu, Tinh thần, Random — máy gieo ngẫu nhiên 20 status, Diêm ngục, Delete, Vô hiệu, Đói bụng, No căng, Che khuất, Repulsion, Undead, Hoá đá, Mục tiêu, Khô, Enchanted, Nặng, Vô hình, Đầu hàng — gồm cả 6 cơ chế "không thể gỡ" của riêng từng trận boss) — 47/48 có icon chuẩn `EBF5 Status X` (`img/status/`): Disable không có icon in-game (ghi rõ trên wiki), Defend dùng icon chung `Status Defend`, Radiation giữ emoji |
| Khu vực | `areas` | **81 entry**: 12 khu vực chính + 6 khu vực trả phí (Freezeflame, Mineshaft Maze, Deathly Hollows, The Great Sea, Temple of Trials, Crystal Caverns) + **63 khu con** (Ice Cave, Library, Lava Lake, Data Bunker, Battle Arena, Arcade Room, shops, nhà, Medals Room…) — 18/18 khu chính và 63/63 khu con có ảnh (`img/areas/`: 18 tile + 84 ảnh map ô) — **205 ô lưới (195 ô có foes hoặc Key Items): 121 ô khu chính + 84 ô khu con**, kiểm `cells ↔ areaCells` 2 chiều trong check.ps1 section 8 (205 cặp) — khu con có `kind: 'Khu con'`, `parent`, `cells[].image`, `sources.areas[id]` và `sources.areaCells[id]`; trường `subs` cũ đã bỏ — tên Key Item trong ô lưới là **link** sang chủ đề `keyitems` |
| Vật phẩm nhiệm vụ | `keyitems` | **66 mục — đủ bộ Key Items EBF5** (lượt 24) theo bảng mục `{{EBF|5}}` của trang *Key Items* (theo wiki: "There are 66 key items in total" — con số ~71 trong roadmap chỉ là ước lượng trước khi trích nguồn); desc = dịch hàng Description, `note` cô đọng hàng Note (tìm thấy ở đâu, nhiệm vụ của ai, số lượng đánh số (1)…(N), dùng Equip Remix nào); 5 loại bộ lọc: Qua vật cản (16) / Chìa khoá (6) / Nhiệm vụ (34) / Cổng The Beyond (7) / Công cụ hệ thống (3) — **66/66 icon `5<Tên>` theo bảng PlacementGrid** (`img/keyitems/` — Green Keycard → `5GreenCard`, Tomato → `EBF5 Item Tomato`); panel **"Ô lưới có Key Item này"** quét tự động từ `areas.cells`, ngược lại 9 món không nằm trên grid (Scouter, Old Boots, Rubber Boots, Star Ball, Wooden Plank, Snail Mail, Green Keycard, Big Battery, Empty Bottle) vẫn có ghi chú tìm nguồn; Cool Headband đã có trong ô Equipment/Food Shop sau lượt 28 |
| Triệu hồi | `summons` | 191 summon — gần như đủ bộ theo bảng Summons/Epic Battle Fantasy 5 (bảng hiện hành post-v2, 192 hàng; trừ demo ẩn Glitch 2): The Devourer 250, Glitch 177, God 160 → Furry Slime 1 —.SP rõ; cột **Nguồn mở khoá** (bắt quái Capture); 40 entry đặc tả tay (lượt 8+11) + 151 entry sinh máy từ các cột bảng wiki (lượt 14); lọc theo Tấn công/Hỗ trợ — 191/191 có icon `EBF5 Foe Icon` (`img/summons/`) |
| Limit Break | `limits` | 20 Limit Break: 10 riêng (Cleaver, Ragnarok, Genesis, 7th Heaven, Nuke, Oblivion...) + 10 dùng chung (Annihilate, Black Hole, Tsunami, Seven Swords...) — 11/20 có ảnh (`img/limits/`), còn lại emoji; thể hiện character char mỗi skill |

Mỗi mục có dạng:

```js
{
  id: 'ten-viet-lien-khong-dau',   // dùng trong URL, duy nhất trong chủ đề
  name: 'Tên hiển thị',
  kind: 'Loại',                    // phải nằm trong kinds của category tương ứng
  elements: ['fire', 'ice'],       // id nguyên tố trong bảng elements
  image: 'img/xxx.png',            // (tuỳ chọn) ảnh minh hoạ, hiển thị trên card/chi tiết
  desc: 'Mô tả ngắn...'
}
```

Muốn thêm chủ đề mới (VD: khu vực/bản đồ, NPC, DSP, cheat): thêm 1 dòng vào `categories`
và 1 mảng dữ liệu cùng tên `key` vào `window.EBF5DATA` — trang web tự nhận.

## 🧩 Tính năng hiện có

- Trang chủ + 11 chủ đề wiki, điều hướng cố định
- Tìm kiếm toàn wiki (bỏ dấu, không phân biệt hoa/thường) — tìm sâu cả **mẹo, hiệu quả, key items, quái theo từng ô lưới khu vực**
- **Chủ đề Vật phẩm nhiệm vụ ↔ ô lưới Khu vực link hai chiều**: tên Key Item trong ô lưới nhấp được tới trang chi tiết; trang chi tiết quét ngược về khu + ô chứa món đó
- Lọc danh sách theo **nguyên tố** và **loại**
- Trang chi tiết riêng cho từng loại dữ liệu (nhân vật có bảng kỹ năng, mẹo chơi...)
- Ảnh minh hoạ nhân vật, chip nguyên tố màu, breadcrumb, theme tối kiểu game
- **Lightbox**: nhấp ảnh trang chi tiết để xem full; đóng bằng ✕ / nền / `Esc`
- **Tooltip trạng thái**: đưa chuột lên tên trạng thái (Đốt, Ướt, Doom...) để xem icon + mô tả ngắn, nhấp đến trang chi tiết
- **Nguồn truy vết**: panel "Nguồn dữ liệu" ở trang chi tiết có link **Trang wiki gốc** cho từng mục (areas còn link riêng theo từng ô lưới)
- **Phím tắt trang chi tiết**: `←/→` mục trước/sau, `Esc` về danh sách
- Nút **↑ Đầu trang** hiện khi cuộn dài
- Trang `test.html` — smoke test chạy trực tiếp trong trình duyệt (không cần Node), xoá khi không cần

## 📦 Deploy miễn phí

Dự án là trang tĩnh nên có thể đẩy thẳng lên bất kỳ host tĩnh nào:

- **GitHub Pages:** tạo repo → upload các file → Settings → Pages → chọn nhánh `main`
- **Netlify / Vercel / Cloudflare Pages:** kéo-thả thư mục là xong

## 🛣️ Tiếp theo có thể làm

- ~~(Tuỳ) favicon/logo~~ ✅ đã có `favicon.svg` trên GitHub Pages; (Tuỳ) tên miền riêng — cần tự mua
- Bảng khắc chế nguyên tố tương tác (nút bấm xem điểm yếu)
- So sánh đội hình / máy tính đòn damage
- Chuyển dữ liệu sang file JSON nếu muốn gắn server/CMS sau này

