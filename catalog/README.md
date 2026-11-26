# Blox Catalog simulator — v12.5

Giao diện quản lý/mô phỏng chạy trên client. Nguồn: báo cáo `blox-fruits-catalog-data-v1-2753915549.json`, place version 4632. File chạy chứa sẵn database, không cần chạy script mẫu hoặc helper trước mỗi lần mở.

## Chạy trong Potassium

Link tải ổn định từ repo riêng:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Right Shift ẩn/hiện; kéo thanh tiêu đề để di chuyển; Hide thu thành nút Catalog; X đóng và dọn kết nối. Tools bật/tắt Visual, Balance, Gift Perm, icon và xem model 3D. F6/Rescan cập nhật model hiện có trên client. Danh sách có thanh cuộn và tối đa 30 thẻ mỗi trang.

Hoặc dùng file local `dist/blox-catalog-sim-v12.lua`. Trong Blox Fruits, mở Items trước rồi nhấn Rescan. Dòng `Items linked locally` xác nhận đã nối vào cache inventory của client. Khi đó Add vừa cập nhật Added vừa gọi API WriteTempItem của game để hiển thị các bản ghi cục bộ trong Items. Nếu chưa nối được, header ghi `Items offline / panel only`; console có nguyên nhân. Không require module game chưa được tải.

V3 sửa lỗi ghi native được báo từ game thật: UserReplicationCache.Set chuyển 0/false thành nil. Adapter chỉ ghi Quantity, so sánh đúng biểu diễn nil của stock bằng 0 và để game quản lý các cờ khác. Vẫn kiểm tra đọc lại; ghi bị từ chối, bị biến đổi hoặc ném lỗi sau khi cập nhật sẽ được rollback. Nếu còn lỗi, console ghi rõ key/ID/expected/actual và tạo báo cáo `blox-catalog-native-error-<PlaceId>.json` khi writefile khả dụng. Căn cứ là báo cáo cache chỉ đọc do người dùng xuất trong phiên thật; không tắt restriction của game.

Added có nút Equip: ưu tiên Tool có sẵn, nếu không có thì dùng model phù hợp để tạo Tool hiển thị cục bộ. Các action EquipFruit/EquipItem của bản mô phỏng trong Items gốc dùng cùng luồng cục bộ, với giá trị trả về Future<Result> theo RemoteUtil thực tế. Nếu stock đã có trước lớp mô phỏng, Equip giữ handler gốc của game. Các giao dịch native khác trên bản mô phỏng được chặn; item không liên quan giữ handler gốc. Một vé Permanent mô phỏng không mở khóa quyền Permanent trên máy chủ.

Add/Clear/Clear Whole Inventory/Undo Clear đồng bộ kho mô phỏng với cache client khi kết nối được. Clear xóa Tool do script tạo và phục hồi giá trị native do script đã thay; cập nhật khác giá trị cuối đã ghi được giữ lại. Undo phục hồi lần Clear gần nhất, gộp đúng các mục đã Add sau lần Clear. Balance lưu số dư mô phỏng trong phiên. Gift Perm ghi lịch sử mô phỏng tối đa 50 dòng. Chạy lại, đóng script hoặc teleport sẽ kết thúc phiên và mất các chỉnh sửa mô phỏng.

## Database và ModuleScript

| Database | Bản ghi | Thiếu rarity | Thiếu icon |
|---|---:|---:|---:|
| Fruits | 47 | 0 | 0 |
| Permanent | 46 | 0 | 0 |
| Fruit Skins | 133 | 0 | 0 |
| Premium | 30 | 0 | 7 |
| Swords | 42 | 1 | 1 |
| Guns | 14 | 0 | 0 |
| Skills | 39 | 37 | 21 |

`Data/` chứa bảy ModuleScript database; `Data/init.luau` tổng hợp chúng. `Catalog.luau` tìm kiếm bằng chuỗi thường theo tên/ID/rarity; `Inventory.luau` quản lý trạng thái mô phỏng; `NativeItems.luau` nối cache và bảo vệ native action; `Equipment.luau` tạo/equip/dọn Tool cục bộ; `FruitModels.luau` nhập model trái từ file cục bộ; `FruitAnimations.luau` đối chiếu animation đã kiểm chứng; `UI.luau` dựng giao diện; `Main.client.luau` khởi chạy. Bản `dist/catalog.json` chứa dữ liệu dễ đọc và thống kê nguồn.

Phân loại dùng Index.IdType, Display.Category và quan hệ Skin.Physical/Skin.IsDefault. 34 trái vật phẩm mang skin nằm ở Fruit Skins, gồm cả bốn biến thể Empyrean, Fiend (Yeti), Hellfire (Gas), Werewolf (Tiger) theo data/fruit-variant-relations.json. 46 định nghĩa skin có bản vật phẩm tương ứng được ẩn khỏi kết quả tìm kiếm để bỏ default và thẻ trùng, nên tab Fruit Skins có 87 thẻ hiển thị trên 133 bản ghi. Các ID gốc được giữ để tra cứu. Permanent được xác định bằng RibbonText hoặc tên Permanent trong nhóm Blox Fruit/Redeemable; không biến mọi Redeemable thành Permanent. Wenlock's Rocket Fruit không có dấu hiệu đó nên không được gán nhầm. Skin và vé redeem skin giữ ID riêng của game. Skills bao gồm Fighting Style, Ability và Admin Ability theo danh mục gốc; sự hiện diện trong database không đồng nghĩa có thể sở hữu hoặc sử dụng.

Tên ưu tiên Display.Name, nếu thiếu dùng Index.StorageKey và ghi `nameSource`. ID là **ItemId của game**, khác ID của hình ảnh hoặc game pass. Icon giữ ImageRectOffset/ImageRectSize từ sprite atlas. Metadata không có trong nguồn được đánh dấu trong trường `missing`, hiển thị Unknown hoặc dấu hỏi; không tự đoán rarity hay ghép icon theo tên.

Trong Studio, chèn `dist/BloxCatalog.rbxmx` vào StarterPlayer > StarterPlayerScripts rồi Play. Package chứa Folder BloxCatalog với các ModuleScript và LocalScript Main. File bundle và package được tạo từ cùng mã nguồn.

## Fruits / v12

v12.1 chặn file Empyrean không có ItemId nhưng root tên Galaxy Empyrean Kitsune Fruit: file này đang chứa nhầm skin Galaxy. Khi đó Equip báo rõ cần model Empyrean đúng; không đổi tên Galaxy thành Empyrean. Mẫu native, file Empyrean đúng và Galaxy (1042) vẫn dùng được. [Danh sách người dùng kiểm tra](../data/fruit-user-feedback-2026-11-21.json) lưu 22 trường hợp chưa hoàn chỉnh và các trái đã xác nhận đúng. Các phép đo v12 chỉ xác nhận chuyển động khớp, không chứng minh model mới nhất hoặc đủ FX. Chưa bổ sung hiệu ứng đoán cho các trái thiếu mẫu thật.

Đã kiểm tra trong Blox Fruits gốc: 3/3 trái đối chứng chuyển động; 30 ID thay thế làm Bone/Motor6D của đúng model chuyển động, gồm Control, Kitsune, Gravity, Gas và Eagle. `FruitAnimations.luau` chỉ sửa bản import khi ItemId, ID cũ và fingerprint rig khớp. Eagle được bổ sung Animation đã kiểm chứng trên rig có sẵn; không tạo rig/model giả. Tool thật và mẫu native giữ nguyên. Xem [báo cáo](../docs/fruit-animation-validation.json). Flame tải được nhưng rig không chuyển động nên bị loại; Dragon chưa đối chiếu chắc chắn. 35/81 mục vẫn chưa có file model khớp. Chuyển động khớp rig chưa chứng minh mọi FX/hoạt ảnh giống hoàn toàn game.

Chạy client một lần, không cần helper preload riêng. Equip lần đầu tự preload bằng Animation instance và giữ kết quả theo ID trong phiên Catalog, kể cả lỗi; các yêu cầu đồng thời dùng chung lần tải. Track riêng của từng Animator được dùng lại khi cầm lại. Chỉ Play khi Length > 0; nạp asset và chờ track có dữ liệu đều có giới hạn 8 giây. Đổi trái hoặc đóng UI ngăn phát muộn; Close hủy việc nạp còn chờ. Dòng trạng thái phân biệt đang kiểm tra, sẵn sàng, không có animation và lỗi có ID. Việc này không sửa được quyền tải của ID lỗi hoặc sinh thêm model/FX gốc còn thiếu.

Import v10 sửa đúng ID Idle cũ 78877647242196 của Buddha (ItemId 1393) sang 15123606541, lấy từ Tool Buddha thật và đã tải thành công qua kiểm tra typed Animation v2. Chỉ sửa trên bản sao khi ID cũ khớp; file local và Tool thật giữ nguyên, không áp dụng sang trái khác. Cần file model Buddha nhưng không cần cầm Buddha thật sau mỗi lần mở script. Chưa xác nhận đầy đủ chuyển động/FX trong Potassium sau thay đổi này.

Add một Fruit rồi mở Added và bấm Equip. Trái có model được tạo thành Tool và hiển thị trên hotbar gốc của game. Thanh Fruits tự tạo cùng tùy chọn bật/tắt đã bị gỡ theo yêu cầu người dùng. Clear xóa Tool cục bộ; Undo phục hồi bản ghi kho; X dọn Tool và cache model đã tải. Bản v6 giữ nguyên luồng tạo Tool và tải file đã hoạt động ở v5.

Nút Equip trong kho cũ `Main.InventoryContainer.Left.Equip` được nối cho các Fruit mô phỏng chưa có stock thật: lớp nút trong suốt dùng đúng vị trí/kích thước của nút gốc, gọi luồng tạo Tool cục bộ và không gọi handler máy chủ. Khi chọn đồ thật hoặc mục khác, lớp này bị gỡ. Adapter RemoteUtil vẫn xử lý giao diện kho mới. Tên chọn được đối chiếu chính xác sau khi chuẩn hóa khoảng trắng; tên trùng không được tự đoán ID.

V8 dùng trực tiếp DialogueController.new/start từ module đã cache trong game. Nhánh startForTool của v7 gọi require ToolInteraction lúc mở menu và bị lỗi quyền module trong Potassium thật. Bản sửa tránh nhánh đó, tự nối Unequipped/Destroying để đóng đúng menu của Tool cục bộ; không đổi identity hay quyền module. Cấu hình vẫn lấy nguyên từ menu thật: Blox Fruit, câu hỏi có AnimateYield=3, ba nút Chat Eat/Drop/Store, Nevermind và layout mặc định. Game tự dựng khung, font, icon, HUD và hiệu ứng; Catalog tạm ẩn rồi phục hồi Enabled cũ. Lỗi mới được in console và lưu blox-catalog-menu-error.txt.

Drop và Store vẫn chỉ tác động Tool/stock mô phỏng cục bộ; Eat giải thích cần trái thật, không gọi EatRemote. Ngữ cảnh Local visual được ghi ở dòng trạng thái Catalog. Callback chỉ chạy sau khi menu đóng, không chạy nếu Catalog đã bị đóng. NativeDialogue kiểm tra quyền sở hữu phiên menu trước khi đóng, nên không chạm menu NPC/trái thật. Tool thật có sẵn giữ nguyên xử lý gốc.

Rig có AnimationController và Animation tên Idle (hoặc Animation như mẫu Buddha thật) được phát bằng Animator sau khi Tool vào Workspace, gồm lúc cầm và thả cục bộ. Track được tái sử dụng, dừng khi cất và hủy khi dọn Tool. Các giá trị ParticleEmitter/Beam/Trail và rig gốc không bị thay bằng hiệu ứng đoán; script FX hoặc quyền asset còn thiếu vẫn có thể gây khác biệt so với game.

Rescan v9 giữ bản sao đã lọc của Tool trái thật trong Backpack/Character, đối chiếu ItemId chính xác. Mẫu thật được ưu tiên hơn file import và còn dùng được trong phiên Catalog khi Tool thật đã rời Backpack. Cần đợi model thật hiện đủ rồi Rescan; không sửa Tool gốc, không lưu mẫu ra file hoặc lên GitHub. Close hủy các bản sao. Mẫu Buddha thật đã cho thấy ID animation khác file import; không áp dụng ID của Buddha sang trái khác. v12 đã đối chiếu và sửa animation Control/Kitsune trên rig import; Dragon và FX chưa đối chiếu vẫn còn giới hạn.

Equip ưu tiên Tool có sẵn, model đang có trên client, rồi file `codex_fruit_studio/models/<StorageKey>.rbxm` hoặc `<Name>.rbxm` trong Potassium workspace. Import dùng getcustomasset và game:GetObjects, chỉ khi người dùng bấm Equip; không chạy script trong file. Các object gốc ở ngoài DataModel, bản clone được lọc script/remote/tag bằng Equipment trước khi vào Backpack. Bản build trên GitHub không chứa các file model cục bộ.

Thư mục đã kiểm kê có 46 tên file khớp chính xác trong 81 bản ghi Fruits, gồm Arcsteel Magnet, Blizzard, Bomb và Control. Chưa có file khớp cho Dragon (East), Celestial và các mục còn thiếu khác. Không tự dùng model gần giống hoặc icon thay model. Nguồn local này đã bị bỏ sót khi chẩn đoán v4; kết luận trước rằng Arcsteel/Blizzard không có nguồn model đã được thay bằng kiểm kê file này.

Người dùng xác nhận v6 hoạt động với trái, còn v7 gặp lỗi lazy require trong môi trường thật. Kiểm thử hồi quy mới tái hiện lỗi rồi qua khi chuyển sang start. Luồng Studio v8 kiểm tra mở menu qua controller, bỏ Tool đóng menu và phục hồi Catalog, với startForTool giả lập luôn báo lỗi. Người dùng đã xác nhận menu v8 trong Potassium; cache model thật của v9 còn cần kiểm tra live. Các trái thiếu file vẫn báo No model; không có ăn trái/chiêu thức hoặc quyền sở hữu mới trên máy chủ.

## Model và preview

Equip trong Visual đi qua Add → Equip khi cần, không tăng số lượng khi bấm lại. View mở cửa sổ preview. Khi client đã có Tool/Model mang ItemId trùng khớp trong Backpack, Character, cache được xác định hoặc Tool trực tiếp trong Workspace, preview có thể dùng model 3D. Tool không có ItemId có thể đối chiếu tên chính xác, không mơ hồ, từ StorageKey/Display.Name; không ghép tên mơ hồ của Model hiệu ứng. Bản clone preview được bỏ script/sound và chỉ nằm trong ViewportFrame. Restore visuals dọn tất cả Tool trang trí đã tạo qua Visual, giữ nguyên Tool có sẵn.

Equip ưu tiên Tool có sẵn trong Backpack/Character, giữ nguyên script và activation. Với Tool không có ItemId, đối chiếu tên sau khi bỏ khoảng trắng; Tool trái cần hậu tố Fruit. Nếu không có Tool có sẵn, Equip dùng model tương ứng để tạo Tool riêng, giữ grip/joint của model gốc, bỏ script, remote, tag component và liên kết tới vật thể ngoài bản clone. Tool trang trí được vô hiệu hóa activation, không có chức năng chiến đấu hoặc trái thật trên máy chủ. Clear/đóng UI dọn Tool do script tạo; respawn đưa các bản mô phỏng trở về stock. Khi thiếu model, nút hiện `No model`, báo nguyên nhân khi bấm và không giảm stock. Database icon/ID không cung cấp model 3D; chưa có nguồn tải model của mọi trái/skin trong phiên sạch. Arcsteel đã có file cục bộ; các vé Permanent không được chuyển thành Tool trái thật.

## Cập nhật và kiểm tra

Từ thư mục gốc dự án, sau khi có báo cáo export mới:

```powershell
python tools/build_catalog.py 'C:\duong-dan\blox-fruits-catalog-data-v1-2753915549.json'
python -m unittest discover -s tests -p test_build_catalog.py
```

Builder tạo lại bảy database, client.lua, bundle v12, package Studio và catalog JSON. Chạy `python tools/build_catalog.py` không kèm báo cáo để chỉ build các module/database đã có trong repo. Không cần thư viện Python ngoài standard library. Tệp đầu vào phải complete=true, ItemConfig.status=ok và không chạm giới hạn hàng/thời gian. Cờ partial ở export hiện tại đến từ Color3 của các mục ngoài bảy nhóm và một số vô hạn trong Quality của Dark Blade; các trường đã trích xuất được đối chiếu riêng với nguồn.

`tests/Simulation.spec.luau` trả về hàm nhận Inventory và Catalog để chạy assert trong Studio Edit. `tests/NativeItems.spec.luau` kiểm tra chữ ký self/key/itemId/uid/value, Future<Result>, action guard, stock có sẵn giữ handler gốc, cập nhật baseline, rollback và restore. `tests/Equipment.spec.luau` kiểm tra chọn đúng Tool có sẵn, loại bản clone/ID sai, clone sạch, tag, rig/joint, weld và nguồn model không bị sửa.

Kiểm tra v4 trong Studio: Tool Bisento fixture do server tạo được equip nguyên bản và nhận activation ở server; script/Enabled/ManualActivationOnly giữ nguyên. Hai model fixture được cầm bằng Visual; bấm lại không tăng stock; thiếu model không tạo mục/Tool; Restore và đóng UI giữ Tool gốc. Cả ba bộ assert Luau và bốn test Python đã qua. Đây chưa phải kiểm chứng combat hoặc hotbar tùy chỉnh của Blox Fruits thật. Ảnh người dùng xác nhận bản v3 đã hiển thị các mục mô phỏng trong Items thật.

Đã kiểm tra lõi và thao tác UI trên Studio desktop: Add x2, Clear/Undo, Clear Whole/Undo, tìm ID, Balance, Gift Perm, icon/3D preview, Restore, bật/tắt tiện ích, Hide/Reopen/Right Shift, kéo cửa sổ và cuộn. Bản v2 được thử với mock cache theo mã game đã xuất và Humanoid thật trong Studio: Add cập nhật quantity native giả lập, nút Equip tạo Tool trong Character, native Equip đi cùng luồng, Clear/Undo/Close phục hồi baseline, thiếu model giữ nguyên stock. Kiểm tra ở server xác nhận không có Tool cục bộ được cấp lên server. Đây chưa phải kiểm chứng renderer Items của Blox Fruits thật. Bố cục cửa sổ rộng 360px đã được kiểm tra bằng cách thu nhỏ panel; chưa thử trên điện thoại thật hoặc Potassium thật.
