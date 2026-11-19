# Blox Catalog simulator — v3

Giao diện quản lý/mô phỏng chạy trên client. Nguồn: báo cáo `blox-fruits-catalog-data-v1-2753915549.json`, place version 4632. File chạy chứa sẵn database, không cần chạy script mẫu hoặc helper trước mỗi lần mở.

## Chạy trong Potassium

Link tải ổn định từ repo riêng:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Right Shift ẩn/hiện; kéo thanh tiêu đề để di chuyển; Hide thu thành nút Catalog; X đóng và dọn kết nối. Tools bật/tắt Visual, Balance, Gift Perm, icon và xem model 3D. F6/Rescan cập nhật model hiện có trên client. Danh sách có thanh cuộn và tối đa 30 thẻ mỗi trang.

Hoặc dùng file local `dist/blox-catalog-sim-v3.lua`. Trong Blox Fruits, mở Items trước rồi nhấn Rescan. Dòng `Items linked locally` xác nhận đã nối vào cache inventory của client. Khi đó Add vừa cập nhật Added vừa gọi API WriteTempItem của game để hiển thị các bản ghi cục bộ trong Items. Nếu chưa nối được, header ghi `Items offline / panel only`; console có nguyên nhân. Không require module game chưa được tải.

V3 sửa lỗi ghi native được báo từ game thật: UserReplicationCache.Set chuyển 0/false thành nil. Adapter chỉ ghi Quantity, so sánh đúng biểu diễn nil của stock bằng 0 và để game quản lý các cờ khác. Vẫn kiểm tra đọc lại; ghi bị từ chối, bị biến đổi hoặc ném lỗi sau khi cập nhật sẽ được rollback. Nếu còn lỗi, console ghi rõ key/ID/expected/actual và tạo báo cáo `blox-catalog-native-error-<PlaceId>.json` khi writefile khả dụng. Căn cứ là báo cáo cache chỉ đọc do người dùng xuất trong phiên thật; không tắt restriction của game.

Added có nút Equip: nếu client có model phù hợp, tạo Tool cục bộ và gọi Humanoid:EquipTool. Các action EquipFruit/EquipItem trong Items gốc được chuyển sang cùng luồng cục bộ, với giá trị trả về Future<Result> theo RemoteUtil thực tế. Các giao dịch native khác trên bản mô phỏng được chặn; item không liên quan giữ handler gốc. Một vé Permanent mô phỏng không mở khóa quyền Permanent trên máy chủ.

Add/Clear/Clear Whole Inventory/Undo Clear đồng bộ kho mô phỏng với cache client khi kết nối được. Clear xóa Tool do script tạo và phục hồi giá trị native do script đã thay; cập nhật khác giá trị cuối đã ghi được giữ lại. Undo phục hồi lần Clear gần nhất, gộp đúng các mục đã Add sau lần Clear. Balance lưu số dư mô phỏng trong phiên. Gift Perm ghi lịch sử mô phỏng tối đa 50 dòng. Chạy lại, đóng script hoặc teleport sẽ kết thúc phiên và mất các chỉnh sửa mô phỏng.

## Database và ModuleScript

| Database | Bản ghi | Thiếu rarity | Thiếu icon |
|---|---:|---:|---:|
| Fruits | 81 | 0 | 0 |
| Permanent | 46 | 0 | 0 |
| Fruit Skins | 99 | 0 | 0 |
| Premium | 30 | 0 | 7 |
| Swords | 42 | 1 | 1 |
| Guns | 14 | 0 | 0 |
| Skills | 39 | 37 | 21 |

`Data/` chứa bảy ModuleScript database; `Data/init.luau` tổng hợp chúng. `Catalog.luau` tìm kiếm bằng chuỗi thường theo tên/ID/rarity; `Inventory.luau` quản lý trạng thái mô phỏng; `NativeItems.luau` nối cache và bảo vệ native action; `Equipment.luau` tạo/equip/dọn Tool cục bộ; `UI.luau` dựng giao diện; `Main.client.luau` khởi chạy. Bản `dist/catalog.json` chứa dữ liệu dễ đọc và thống kê nguồn.

Phân loại dựa trên Index.IdType và Display.Category thực tế. Permanent được xác định bằng RibbonText hoặc tên Permanent trong nhóm Blox Fruit/Redeemable; không biến mọi Redeemable thành Permanent. Wenlock's Rocket Fruit không có dấu hiệu đó nên không được gán nhầm. Skin và vé redeem skin giữ ID riêng của game. Skills bao gồm Fighting Style, Ability và Admin Ability theo danh mục gốc; sự hiện diện trong database không đồng nghĩa có thể sở hữu hoặc sử dụng.

Tên ưu tiên Display.Name, nếu thiếu dùng Index.StorageKey và ghi `nameSource`. ID là **ItemId của game**, khác ID của hình ảnh hoặc game pass. Icon giữ ImageRectOffset/ImageRectSize từ sprite atlas. Metadata không có trong nguồn được đánh dấu trong trường `missing`, hiển thị Unknown hoặc dấu hỏi; không tự đoán rarity hay ghép icon theo tên.

Trong Studio, chèn `dist/BloxCatalog.rbxmx` vào StarterPlayer > StarterPlayerScripts rồi Play. Package chứa Folder BloxCatalog với các ModuleScript và LocalScript Main. File bundle và package được tạo từ cùng mã nguồn.

## Visual

Use trong Visual chọn mục để xem trong cửa sổ preview. Khi client đã có Tool/Model mang ItemId trùng khớp trong Backpack, Character, cache được xác định hoặc Tool trực tiếp trong Workspace, preview có thể dùng model 3D. Tool không có ItemId có thể đối chiếu tên chính xác, không mơ hồ, từ StorageKey/Display.Name; không ghép tên mơ hồ của Model hiệu ứng. Bản clone preview được bỏ script/sound và chỉ nằm trong ViewportFrame. Restore visuals xóa lựa chọn preview.

Equip trong Added dùng model tương ứng để tạo Tool riêng, giữ grip/joint của model gốc, bỏ script, remote, tag component và liên kết tới vật thể ngoài bản clone. Tool được vô hiệu hóa activation, không có chức năng chiến đấu hoặc trái thật trên máy chủ. Clear/đóng UI dọn Tool do script tạo; respawn đưa các bản mô phỏng trở về stock. Khi thiếu model, Equip báo `Missing 3D model` và không giảm stock. Database icon/ID không cung cấp model 3D; chưa có nguồn tải model của mọi trái/skin trong phiên sạch. Arcsteel/Permanent Dragon trong ảnh người dùng chưa có nguồn model được xác minh, nên không hứa chúng cầm được chỉ từ database.

## Cập nhật và kiểm tra

Từ thư mục gốc dự án, sau khi có báo cáo export mới:

```powershell
python tools/build_catalog.py 'C:\duong-dan\blox-fruits-catalog-data-v1-2753915549.json'
python -m unittest discover -s tests -p test_build_catalog.py
```

Builder tạo lại bảy database, client.lua, bundle v3, package Studio và catalog JSON. Chạy `python tools/build_catalog.py` không kèm báo cáo để chỉ build các module/database đã có trong repo. Không cần thư viện Python ngoài standard library. Tệp đầu vào phải complete=true, ItemConfig.status=ok và không chạm giới hạn hàng/thời gian. Cờ partial ở export hiện tại đến từ Color3 của các mục ngoài bảy nhóm và một số vô hạn trong Quality của Dark Blade; các trường đã trích xuất được đối chiếu riêng với nguồn.

`tests/Simulation.spec.luau` trả về hàm nhận Inventory và Catalog để chạy assert trong Studio Edit. `tests/NativeItems.spec.luau` kiểm tra chữ ký self/key/itemId/uid/value, Future<Result>, action guard, cập nhật baseline, rollback và restore. `tests/Equipment.spec.luau` kiểm tra clone sạch, tag, rig/joint, weld và nguồn model không bị sửa.

Đã kiểm tra lõi và thao tác UI trên Studio desktop: Add x2, Clear/Undo, Clear Whole/Undo, tìm ID, Balance, Gift Perm, icon/3D preview, Restore, bật/tắt tiện ích, Hide/Reopen/Right Shift, kéo cửa sổ và cuộn. Bản v2 được thử với mock cache theo mã game đã xuất và Humanoid thật trong Studio: Add cập nhật quantity native giả lập, nút Equip tạo Tool trong Character, native Equip đi cùng luồng, Clear/Undo/Close phục hồi baseline, thiếu model giữ nguyên stock. Kiểm tra ở server xác nhận không có Tool cục bộ được cấp lên server. Đây chưa phải kiểm chứng renderer Items của Blox Fruits thật. Bố cục cửa sổ rộng 360px đã được kiểm tra bằng cách thu nhỏ panel; chưa thử trên điện thoại thật hoặc Potassium thật.
