# ⚔️ EBF5 Wiki (Tiếng Việt)

Wiki tĩnh cho game **Epic Battle Fantasy 5** (Matt Roszak / Kupo Games), được dựng bằng
HTML + CSS + JavaScript thuần — **không cần cài đặt, không cần build**.

> 📚 Dữ liệu "Nhân vật / Kỹ năng / Trang bị" đã được đối chiếu theo
> [Epic Battle Fantasy Wiki chính thức](https://epicbattlefantasy.fandom.com/wiki/).
> Ảnh render nhân vật tải từ wiki về thư mục `img/` (độc quyền thuộc Matt Roszak /
> Kupo Games).

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
| Kẻ địch | `enemies` | 50 mục: 8 loài slime thật + 32 quái thường dàn theo 18 khu vực (Blood Bat, Green Bush, Flybot, Wraith, Golem, Rồng biển... icon chuẩn `EBF5 Bestiary X` từ `img/enemies/`) + 10 boss thật (NoLegs, Neon Valkyrie, 4 bóng ma Temple, Rafflesia, Laurelin...) — 50/50 có ảnh — **drops thật cho 50/50** (tên item + tỉ lệ % trích từ bảng `FoeTableEBF5` từng trang wiki) — **15: khắc chế 50/50**: trường `res` từ cột % của `FoeTableEBF5` (10 nguyên tố + nhóm trạng thái như `death&doom`, `chill&freeze`, `atkdown`...) — trang chi tiết hiển thị bảng Yếu / Kháng / Miễn / Hấp thụ |
| Kỹ năng | `skills` | **183 mục — đủ bộ 5 nhân vật + 53 Extra Skills (kỹ năng học qua trang bị, kèm danh sách nhân vật học được)** theo *List of Skills in Epic Battle Fantasy 5* + Guard; 183/183 icon chuẩn `EBF5 Skill X`; Guard dùng icon EBF4 (lệnh giống hệt) |
| Vật phẩm | `items` | 28 món Food thật của EBF5 (Pumpkin → Pizza, số liệu theo bảng wiki), Hand Bomb và 5 Steroid riêng từng nhân vật — tất cả đều có icon (`img/items/`) |
| Trang bị | `equipment` | **228 mục** — 86 vũ khí (78 sinh máy lượt 16 đủ bộ 84 theo wiki + 8 entry tay: Heaven Gate, Ultra Pro 9000X, Fairy Bow, Dark Tooth, Shadow Blaster, Spine Snapper, Crystal Staff, Steel Buckler) + **84 mũ giáp** (21 Mũ nam + 21 Giáp nam + 21 Mũ nữ + 21 Giáp nữ, bảng hiện hành post-v2 của `Male Hats and Armor`/`Female Hats and Armor`) + **58 Flair** (55 sinh máy từ trang `Flairs` + giữ 3 món tay NoLegs: Human Skull, Book of Spells, Neon Lightbulb) - desc sinh máy gồm vị trí, chỉ số, hiệu ứng (Cast triệu hồi ngẫu nhiên / Boost / Trạng thái tự nhận / Defend / Gây trạng thái khi đánh / Kháng) - 24 món nhãn Độc quyền bản Steam (15 lượt 16 + 9 lượt 17: Fur Hat, Ninja Skirt, School Uniform, Maid Outfit, Mecha Suit, Sword Medal, Shield Medal, Gold Star, Platinum Star) - **228/228 có ảnh** (`img/equipment/`) |
| Trạng thái | `statuses` | 25 hiệu ứng (thêm Doom, Scorch, Berserk, Syphon, Brave, Regen, Vận may; thay "Trói chân" bằng Mỏi theo wiki) — 24/25 có icon chuẩn `EBF5 Status X` (`img/status/`), Radiation giữ emoji — **còn thiếu "Hoang mang" (Confuse)**: nhóm "Chững & Hoang mang" và các desc summon dùng tên này nhưng chưa có entry để tooltip (được ghi nhận lượt 18) |
| Khu vực | `areas` | 12 khu vực chính + 6 khu vực trả phí (Freezeflame, Mineshaft Maze, Deathly Hollows, The Great Sea, Temple of Trials, Crystal Caverns) theo trang Epic Battle Fantasy 5 Map — 18/18 có ảnh tile bản đồ (`img/areas/`), kèm ô lưới — **với từng ô lưới có bảng Quái (waves) + Key Items + vị trí con + ghi chú cơ chế** (dành cho 18 khu, lấy từ các trang `EBF5 Map/X`) |
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

- Trang chủ + 9 chủ đề wiki, điều hướng cố định
- Tìm kiếm toàn wiki (bỏ dấu, không phân biệt hoa/thường) — tìm sâu cả **mẹo, hiệu quả, key items, quái theo từng ô lưới khu vực**
- Lọc danh sách theo **nguyên tố** và **loại**
- Trang chi tiết riêng cho từng loại dữ liệu (nhân vật có bảng kỹ năng, mẹo chơi...)
- Ảnh minh hoạ nhân vật, chip nguyên tố màu, breadcrumb, theme tối kiểu game
- **Lightbox**: nhấp ảnh trang chi tiết để xem full; đóng bằng ✕ / nền / `Esc`
- **Tooltip trạng thái**: đưa chuột lên tên trạng thái (Đốt, Ướt, Doom...) để xem icon + mô tả ngắn, nhấp đến trang chi tiết
- **Phím tắt trang chi tiết**: `←/→` mục trước/sau, `Esc` về danh sách
- Nút **↑ Đầu trang** hiện khi cuộn dài
- Trang `test.html` — smoke test chạy trực tiếp trong trình duyệt (không cần Node), xoá khi không cần

## 📦 Deploy miễn phí

Dự án là trang tĩnh nên có thể đẩy thẳng lên bất kỳ host tĩnh nào:

- **GitHub Pages:** tạo repo → upload các file → Settings → Pages → chọn nhánh `main`
- **Netlify / Vercel / Cloudflare Pages:** kéo-thả thư mục là xong

## 🛣️ Tiếp theo có thể làm

- Tải thêm ảnh kẻ địch / trang bị từ wiki (`img/enemies/...`, thêm trường `image`)
- Bổ sung summon theo nhu cầu: bảng hiện hành còn ~150 summon chưa đưa vào (wiki.gg *Summons/Epic Battle Fantasy 5*)
- Bảng khắc chế nguyên tố tương tác (nút bấm xem điểm yếu)
- So sánh đội hình / máy tính đòn damage
- Chuyển dữ liệu sang file JSON nếu muốn gắn server/CMS sau này

