# ASSET_AUDIT — Fruit gốc và skin

Kiểm kê cập nhật ngày 27/11/2026 cho 81 trái vật phẩm trong Fruits và Fruit Skins. Model, Mesh, Texture, Animation và VFX trong bảng dùng báo cáo grouped audit vừa chạy trong Blox Fruits; Cầm / Equip và Ghi chú giữ bằng chứng người dùng cùng các lượt đo cũ. Bộ nguồn có 50 file .rbxm trong Work Potassium. Phạm vi ban đầu là tab Fruits của v12.1, hiện đã phân loại lại và ghi rõ tab riêng.

- Có model qua đối chiếu: **45/81**. File có một root Tool/Model và có BasePart. Kết quả này chưa kiểm tra thao tác Equip của từng trái.
- **35/81** chưa có file khớp. **1/81** có file đúng tên nhưng chứa nhầm model và bị chặn khi nhập.
- **35 rig** đổi pose trong lượt mới; báo cáo v12 trước đó ghi 34 rig. Số liệu không đánh giá hình ảnh có đúng với bản game hiện tại hay không.
- **496/497** tham chiếu tài nguyên riêng biệt tải thành công trong lần đo cũ. Lỗi duy nhất là texture hạt trên Buddha. Đây không phải số món đồ hay số texture của icon Catalog.
- **Kiểm tra lịch sử ngày 26/11 trong Studio:** place demo bị từ chối quyền tải cả 7 ID animation gốc của 8 trái thiếu chuyển động và clip thử của Flame. Hai clip đối chứng tải được. Không dùng kết quả quyền tải của place demo để suy ra nguyên nhân trong game gốc. [Kết quả Studio trong DIAG](DIAG.md#kiểm-tra-lại-trong-roblox-studio-ngày-26112026)

- **Đo lại trong Blox Fruits ngày 26/11:** Dragon, Dragon (West), Ember, Flame, Lightning, Quake và Werewolf (Tiger) đều có 4 mẫu Tool đang cầm, trạng thái cuối Failed do preload trả Failure và không có track đang chạy. Báo cáo kết thúc bình thường nhưng thiếu Tiger (1430).


## Đối chứng chuyển động và bảo toàn model ngày 28/11/2026

Đã kiểm tra sâu Yeti, Shadow, Dark (user xác nhận đầy đủ) và 8 mục lỗi bằng v12.23. 33 ca gồm preload Catalog, phát trực tiếp qua Animator và phát trực tiếp qua AnimationController. Yeti đổi pose 108/120 khớp, Shadow 89/99, Dark 47/70 ở cả ba đường. Dark không có ParticleEmitter/Beam/Trail trong file; 0 VFX không tự động đồng nghĩa chưa hoàn chỉnh.

Dragon, Dragon (West), Ember, Flame, Lightning, Quake, Tiger, Werewolf (Tiger) vẫn preload Failure và không có dữ liệu clip trong cả hai đường phát trực tiếp sau thời hạn 7 giây. 8 mục dùng 7 ID riêng biệt. Không thay clip bằng chuyển động của các trái đối chứng; chưa xác định nguyên nhân phân phối/quyền/ID cũ. Đường gọi native cũng không giải quyết được nguồn clip hiện có trong lượt đo.

Đối chiếu riêng **50 file gốc → clone v12.23** hoàn tất: 0 lỗi model, 0 lỗi đọc thuộc tính, 0 file khác các thuộc tính render/attachment/bone/motor/VFX đã đo. **496/497 tham chiếu render tải thành công**; texture VFX Buddha 6960307279 vẫn lỗi. Đây là kiểm tra bảo toàn dữ liệu file, không xác nhận toàn bộ VFX/controller hiện tại của game. Không thêm emitter giả hay tự bật các emitter vốn bị tắt.

Bảng chi tiết bên dưới giữ số đo toàn bộ ngày 27/11, trừ phần bổ sung đối chứng này. Không tăng phạm vi thành đã thử Equip thật mọi trái. Số nguồn model vẫn **45 nạp được, 35 thiếu file, 1 Empyrean sai model**. Báo cáo tổng hợp mới: data/fruit-reference-check-2026-11-28.json; chi tiết phương pháp và giới hạn ở DIAG.md.

## Đối chiếu nguồn Shop/Dealer/Gacha ngày 28/11/2026, v12.23

Đã đọc dữ liệu ItemConfig và 39 source UI/NPC gốc; mã kiểm tra không mua hoặc quay. Shop hiển thị 232 thành phần ảnh, không có ViewportFrame trong lượt đọc; đủ icon không chứng minh đủ mesh, texture bề mặt hay rig. Dealer mở Fruit Shop để đổi năng lực; Gacha đi qua RandomFruitSeller → GachaClient → GachaWindow → Spinner, template 3D được game cấp riêng cho preview. Không dùng chế độ GachaSimulation của build thử nghiệm.

Khi người dùng giữ màn hình Spin, đã xác nhận Tool 3D ItemId 1411 ở Workspace: 6 BasePart, Idle 15123685330, 0 ParticleEmitter/Beam/Trail. Kho preview lúc này có mặt nhưng rỗng. Rescan cũng giữ snapshot sạch của Tool native ở Workspace trước khi preview đóng. Spin là nguồn đã có trong nhóm 45, không tăng số model thiếu đã khôi phục; chưa có bằng chứng toàn bộ danh sách Gacha đã có model local.

Phát hiện và sửa Catalog bỏ sót `PlayerGui.__ReplicatedSpinnerInstances`: Rescan nhận template theo đúng ItemId, giữ snapshot sạch sau khi native dọn preview, ưu tiên Tool thật đã có. Không suy ItemId từ tên preview, không lắp FX/animation phỏng đoán. Kho này chưa có trong lượt đọc nguồn ban đầu; 18 model trùng tên ở các nhánh kỹ năng/chalice/NPC không đủ căn cứ nhận thành trái vật phẩm. Không có file model mới được xác minh.

**Số liệu bảng bên dưới giữ nguyên lượt 27/11: 45 nạp được, 35 thiếu file, 1 Empyrean sai model; 35 rig đổi pose, 8 idle preload lỗi, Diamond/Ice thiếu idle.** Sửa nhận diện nguồn không chứng minh đã khôi phục chuyển động/VFX của các trái đang lỗi. Chưa đối chiếu hình ảnh toàn bộ 81 trái trong game hiện tại. Chi tiết luồng và kiểm thử ở [DIAG.md](DIAG.md#shop-dealer-gacha-và-nguồn-preview-bị-bỏ-sót-v1223).

## Đo lại ngày 27/11/2026, v12.6

Báo cáo `blox-catalog-fruit-skin-audit-100117331123089.json` hoàn tất 134 thẻ trong 87.8 giây. Bảng dưới đây cập nhật model, mesh/texture, animation và VFX theo phép đo mới. 53 thẻ metadata-only không nằm trong 81 trái vật phẩm của bảng.

- **45 model nạp được**, **35 mục thiếu file** và **1 file Empyrean chứa nhầm Galaxy**. Không capture được Tool thật trong lượt này.
- **35 rig đổi pose**, **8 clip tải thất bại**, **2 nguồn (Diamond, Ice) không có idle animation**. Tiger đã được đo lần này. Khớp đổi pose được lấy trên bản sao ẩn qua sáu pha, không phải phép thử cầm trái thật hay chứng minh hình ảnh hiện tại.
- Render fetch hoàn tất cho cả 45 model. Tham chiếu lỗi duy nhất trong lượt này là texture VFX Buddha `rbxassetid://6960307279`. Không suy ra VFX đúng game chỉ từ số emitter hoặc trạng thái tải.
- Cột Cầm / Equip và Ghi chú giữ bằng chứng người dùng/lượt đo cũ. Lỗi Equip từ kho ngày 27/11 được sửa đường gọi trong v12.7, đang chờ kiểm tra lại trên máy người dùng.

## Phân loại cập nhật ngày 27/11/2026, v12.5

Bảng bên dưới bao gồm **81 trái vật phẩm**, hiện chia thành **47 mục Fruits** và **34 mục Fruit Skins**. Arcsteel và Galaxy thuộc nhóm skin. Empyrean → Kitsune, Fiend (Yeti) → Yeti, Hellfire (Gas) → Gas và Werewolf (Tiger) → Tiger được phân loại theo xác nhận của người dùng, lưu trong data/fruit-variant-relations.json. IsDefault chỉ xác định diện mạo mặc định trong một biến thể, không chứng minh đó là fruit gốc.

**Fruit gốc** có 40 file khớp và **7 mục thiếu file**, gồm Celestial, Dragon (East), Magnet, Oni, Portal, Rocket, Venom. **Trái mang skin** có 5 file được chấp nhận, **28 mục thiếu file**, và Empyrean có file chứa sai Galaxy nên bị chặn. Tổng vẫn là 45 nguồn qua đối chiếu, 35 mục thiếu file và 1 nguồn bị chặn.

Tab Fruit Skins có 87 thẻ, gồm 34 trái vật phẩm mang skin, 31 skin chưa có Physical và 22 bản redeemable. 46 định nghĩa skin có bản vật phẩm tương ứng được ẩn khỏi kết quả tìm kiếm để tránh thẻ trùng. Cả 351 ItemId vẫn có trong database. Model và tham chiếu animation của skin tiếp tục gắn với ItemId riêng, không lấy file của fruit gốc thay vào.

Lỗi chuyển động được báo ở cả hai nhóm. Fruit gốc gồm Dragon, Dragon (West), Flame, Lightning, Quake và Tiger. Skin gồm Ember và Werewolf (Tiger). Lượt đo khi cầm ngày 26/11 có 7/8 mục; lượt bản sao riêng ngày 27/11 đã ghi đủ cả 8 và đều preload thất bại. VFX trong bảng ghi cấu trúc file và phản hồi đã có, chưa xác nhận toàn bộ hình ảnh đúng với game hiện tại.

Cột **Mesh** ghi số MeshPart và số tham chiếu mesh tải thành công / tổng trong lượt đo 27/11. **Texture** đếm các tham chiếu bề mặt và texture ngoài VFX. **VFX** ghi số ParticleEmitter/Beam/Trail bật / tổng trong file, sau đó là tỷ lệ tải texture của chúng. Tài nguyên dùng chung có thể xuất hiện ở nhiều dòng. **0 ref.** nghĩa là phép đo không ghi được tham chiếu thuộc nhóm đó. VFX không xuất hiện trong file hoặc chưa được người dùng nhìn thấy chưa đủ để kết luận có lỗi.

| Fruit | ID | Tab v12.7 | Model trong Work Potassium | Mesh | Texture | Cầm / Equip | Animation | VFX | Ghi chú |
|---|---|---|---|---|---|---|---|---|---|
| Arcsteel Magnet | 1525 | Fruit Skins | Nạp được · Arcsteel Magnet.rbxm | 3 · 3/3 | 7/7 | Đã thấy cầm | Đổi pose · 37/56 khớp · 90561160320604 | 9/51 bật · 33/33 | — |
| Azura Bomb | 512 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Blade | 1399 | Fruits | Nạp được · Blade-Blade.rbxm | 4 · 4/4 | 0 ref. | Có BasePart · chưa thử cầm | Đổi pose · 11/15 khớp · 15123613404 | 0/0 bật · 0 ref. | — |
| Blizzard | 1416 | Fruits | Nạp được · Blizzard-Blizzard.rbxm | 4 · 4/4 | 6/6 | Có BasePart · chưa thử cầm | Đổi pose · 28/43 khớp · 15123587371 | 8/8 bật · 7/7 | — |
| Bomb | 1397 | Fruits | Nạp được · Bomb-Bomb.rbxm | 5 · 5/5 | 1/1 | Có BasePart · chưa thử cầm | Đổi pose · 38/44 khớp · 87174669415581, 15123595806 | 3/12 bật · 8/8 | — |
| Buddha | 1393 | Fruits | Nạp được · Buddha-Buddha.rbxm | 6 · 6/6 | 1/1 | Có mẫu thật từng cầm | Đổi pose · 61/68 khớp · 15123606541 | 1/2 bật · 1/2 | Đổi Idle theo mẫu Buddha; 1 texture VFX tải lỗi |
| Celebration Bomb | 539 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Celestial | 1428 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Celestial Pain | 498 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Control | 1409 | Fruits | Nạp được · Control-Control.rbxm | 5 · 5/5 | 1/1 | Đã thấy cầm | Đổi pose · 36/41 khớp · 15123616275 | 0/0 bật · 0 ref. | Model cũ theo phản hồi |
| Creation | 1426 | Fruits | Nạp được · Creation-Creation.rbxm | 13 · 13/13 | 0 ref. | Có BasePart · chưa thử cầm | Đổi pose · 68/254 khớp · 116828771482820 | 0/0 bật · 0 ref. | — |
| Dark | 1395 | Fruits | Nạp được · Dark-Dark.rbxm | 6 · 6/6 | 3/3 | Có BasePart · chưa thử cầm | Đổi pose · 47/70 khớp · 15123618591 | 0/0 bật · 0 ref. | — |
| Diamond | 1421 | Fruits | Nạp được · Diamond-Diamond.rbxm | 5 · 5/5 | 0 ref. | Có BasePart · chưa thử cầm | Không có idle trong nguồn | 3/3 bật · 2/2 | — |
| Divine | 1048 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Dough | 1417 | Fruits | Nạp được · Dough-Dough.rbxm | 6 · 6/6 | 4/4 | Có BasePart · chưa thử cầm | Đổi pose · 77/83 khớp · 15123624401 | 0/6 bật · 1/1 | — |
| Dragon | 1447 | Fruits | Nạp được · Dragon-Dragon.rbxm | 7 · 7/7 | 7/7 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 89485756852231 | 8/8 bật · 7/7 | Người dùng thấy đứng yên; đã thấy VFX |
| Dragon (East) | 885 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Dragon (West) | 884 | Fruits | Nạp được · Dragon (West)-Dragon (West).rbxm | 7 · 7/7 | 7/7 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 89485756852231 | 33/33 bật · 13/13 | Root ghi Dragon-Dragon, thiếu ItemId; Người dùng thấy đứng yên; đã thấy VFX |
| Eagle | 1425 | Fruits | Nạp được · Eagle-Eagle.rbxm | 3 · 3/3 | 4/4 | Có BasePart · chưa thử cầm | Đổi pose · 50/69 khớp · 77885466312115 | 0/12 bật · 7/7 | Eagle được thêm clip đã đo |
| Ember | 1047 | Fruit Skins | Nạp được · Ember Dragon (West).rbxm | 7 · 7/7 | 2/2 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 96038340477884 | 8/8 bật · 7/7 | Người dùng thấy đứng yên; đã thấy VFX |
| Emerald Diamond | 471 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Empyrean | 1041 | Fruit Skins | Bị chặn · nguồn Galaxy gán nhầm | — | — | Bị chặn | — | — | Root Galaxy, thiếu ItemId |
| Fiend (Yeti) | 1060 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Flame | 1394 | Fruits | Nạp được · Flame-Flame.rbxm | 8 · 8/8 | 4/4 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 92872930988510 | 6/6 bật · 6/6 | Người dùng thấy đứng yên; đã thấy VFX; Clip thử trước đó tải được nhưng 0 khớp chạy |
| Frustration Pain | 492 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Galaxy | 1042 | Fruit Skins | Nạp được · Galaxy Empyrean Kitsune.rbxm | 6 · 6/6 | 2/2 | Người dùng đã xem · chưa đo Equip | Đổi pose · 102/115 khớp · 121051622257427 | 3/3 bật · 2/2 | — |
| Gas | 1422 | Fruits | Nạp được · Gas-Gas.rbxm | 6 · 6/6 | 3/3 | Đã thấy cầm | Đổi pose · 109/144 khớp · 118054805452821 | 7/7 bật · 3/3 | Gas đã được chấp nhận |
| Ghost | 1412 | Fruits | Nạp được · Ghost-Ghost.rbxm | 3 · 3/3 | 1/1 | Có BasePart · chưa thử cầm | Đổi pose · 75/86 khớp · 15123662036 | 4/4 bật · 4/4 | — |
| Glacier Eagle | 496 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Gravity | 1405 | Fruits | Nạp được · Gravity-Gravity.rbxm | 8 · 8/8 | 3/3 | Có BasePart · chưa thử cầm | Đổi pose · 8/18 khớp · 15123633312 | 0/0 bật · 0 ref. | — |
| Green Lightning | 462 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Hellfire (Gas) | 1601 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Ice | 1392 | Fruits | Nạp được · Ice-Ice.rbxm | 4 · 4/4 | 3/3 | Có BasePart · chưa thử cầm | Không có idle trong nguồn | 10/10 bật · 8/8 | — |
| Kitsune | 1423 | Fruits | Nạp được · Kitsune-Kitsune.rbxm | 6 · 6/6 | 4/4 | Người dùng đã xem · chưa đo Equip | Đổi pose · 128/148 khớp · 15487764876 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Light | 1407 | Fruits | Nạp được · Light-Light.rbxm | 6 · 6/6 | 3/3 | Có BasePart · chưa thử cầm | Đổi pose · 32/38 khớp · 15123640714 | 0/0 bật · 0 ref. | — |
| Lightning | 1427 | Fruits | Nạp được · Lightning-Lightning.rbxm | 8 · 8/8 | 4/4 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 74759006007335 | 4/4 bật · 4/4 | Người dùng thấy đứng yên; đã thấy VFX |
| Lime Blade | 1526 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Love | 1408 | Fruits | Nạp được · Love-Love.rbxm | 6 · 6/6 | 6/6 | Người dùng đã xem · chưa đo Equip | Đổi pose · 46/53 khớp · 15123643097 | 3/3 bật · 2/2 | — |
| Magma | 1391 | Fruits | Nạp được · Magma-Magma.rbxm | 4 · 4/4 | 0 ref. | Đã thấy cầm | Đổi pose · 33/37 khớp · 15123645682 | 3/9 bật · 3/3 | Người dùng chưa thấy VFX |
| Magnet | 1516 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Mammoth | 1418 | Fruits | Nạp được · Mammoth-Mammoth.rbxm | 6 · 6/6 | 3/3 | Người dùng đã xem · chưa đo Equip | Đổi pose · 24/59 khớp · 15123648309 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Matrix Eagle | 502 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Meme | 1431 | Fruits | Nạp được · Meme-Meme.rbxm | 2 · 2/2 | 2/2 | Người dùng đã xem · chưa đo Equip | Đổi pose · 39/42 khớp · 94535044798318 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Nuclear Bomb | 508 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Oni | 1429 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Orange Portal | 463 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Pain | 1406 | Fruits | Nạp được · Pain-Pain.rbxm | 6 · 6/6 | 7/7 | Người dùng đã xem · chưa đo Equip | Đổi pose · 43/52 khớp · 15123652069 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Phoenix | 1401 | Fruits | Nạp được · Phoenix-Phoenix.rbxm | 11 · 11/11 | 7/7 | Người dùng đã xem · chưa đo Equip | Đổi pose · 120/134 khớp · 15123654553 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Pink Portal | 458 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Portal | 1414 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Purple Lightning | 460 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Quake | 1389 | Fruits | Nạp được · Quake-Quake.rbxm | 4 · 4/4 | 3/3 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 87225712156404, 87225712156404 | 0/5 bật · 5/5 | Người dùng thấy đứng yên |
| Red Lightning | 540 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Requiem Eagle | 495 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Rocket | 1390 | Fruits | Thiếu file | — | — | Đã từng cầm · ngoài file | — | — | Đã từng cầm theo phản hồi |
| Rose Quartz Diamond | 470 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Rubber | 1396 | Fruits | Nạp được · Rubber-Rubber.rbxm | 3 · 3/3 | 3/3 | Người dùng đã xem · chưa đo Equip | Đổi pose · 83/93 khớp · 15123668008 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Ruby Diamond | 468 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Runic Fiend | 1522 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Sadness Pain | 479 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Sand | 1404 | Fruits | Nạp được · Sand-Sand.rbxm | 3 · 3/3 | 4/4 | Người dùng đã xem · chưa đo Equip | Đổi pose · 126/141 khớp · 15123673019 | 4/5 bật · 5/5 | — |
| Scarlet Ghost | 1524 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Shadow | 1413 | Fruits | Nạp được · Shadow-Shadow.rbxm | 6 · 6/6 | 6/6 | Người dùng đã xem · chưa đo Equip | Đổi pose · 89/99 khớp · 15123675904 | 3/4 bật · 3/3 | — |
| Smoke | 1400 | Fruits | Nạp được · Smoke-Smoke.rbxm | 4 · 4/4 | 3/3 | Có BasePart · chưa thử cầm | Đổi pose · 162/167 khớp · 15123677932 | 0/0 bật · 0 ref. | — |
| Sound | 1419 | Fruits | Nạp được · Sound-Sound.rbxm | 7 · 7/7 | 4/4 | Có BasePart · chưa thử cầm | Đổi pose · 3/11 khớp · 15123679712 | 7/7 bật · 6/6 | — |
| Spider | 1403 | Fruits | Nạp được · Spider-Spider.rbxm | 5 · 5/5 | 0 ref. | Người dùng đã xem · chưa đo Equip | Đổi pose · 100/105 khớp · 15123681598 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Spike | 1398 | Fruits | Nạp được · Spike-Spike.rbxm | 7 · 7/7 | 1/1 | Có BasePart · chưa thử cầm | Đổi pose · 72/144 khớp · 15124220207 | 0/0 bật · 0 ref. | — |
| Spin | 1411 | Fruits | Nạp được · Spin-Spin.rbxm | 3 · 3/3 | 3/3 | Có mẫu thật từng cầm | Đổi pose · 15/23 khớp · 15123685330 | 0/0 bật · 0 ref. | — |
| Spirit | 1415 | Fruits | Nạp được · Spirit-Spirit.rbxm | 11 · 11/11 | 11/11 | Người dùng đã xem · chưa đo Equip | Đổi pose · 24/37 khớp · 11911905519 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Spring | 1402 | Fruits | Nạp được · Spring-Spring.rbxm | 4 · 4/4 | 3/3 | Người dùng đã xem · chưa đo Equip | Đổi pose · 38/48 khớp · 15123689268 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Starlight Gravity | 1523 | Fruit Skins | Nạp được · Heavenly Gravity.rbxm | 9 · 9/9 | 6/6 | Có BasePart · chưa thử cầm | Đổi pose · 29/39 khớp · 15123633312 | 0/0 bật · 0 ref. | — |
| Super Spirit Pain | 541 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| T-Rex | 1420 | Fruits | Nạp được · T-Rex-T-Rex.rbxm | 3 · 3/3 | 5/5 | Có BasePart · chưa thử cầm | Đổi pose · 27/31 khớp · 15694681122 | 4/4 bật · 4/4 | — |
| Thermite Bomb | 511 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Tiger | 1430 | Fruits | Nạp được · Tiger-Tiger.rbxm | 6 · 6/6 | 2/2 | Người dùng đã xem · chưa đo Equip | Preload Failure · 119940442528522 | 0/0 bật · 0 ref. | Người dùng thấy đứng yên; đã thấy VFX |
| Topaz Diamond | 469 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Torment Pain | 491 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Venom | 1410 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Werewolf (Tiger) | 814 | Fruit Skins | Nạp được · Werewolf (Tiger)-Werewolf (Tiger).rbxm | 6 · 6/6 | 3/3 | Đã đo cầm · 4 mẫu · 26/11 | Preload Failure · 133333989918142 | 0/0 bật · 0 ref. | Người dùng thấy đứng yên; đã thấy VFX |
| Yellow Lightning | 450 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Yeti | 1424 | Fruits | Nạp được · Yeti-Yeti.rbxm | 5 · 5/5 | 4/4 | Người dùng đã xem · chưa đo Equip | Đổi pose · 108/120 khớp · 115276580506154 | 8/8 bật · 6/6 | — |

## Các file Catalog chưa chọn

- `Bloodmoon Dragon (West).rbxm` — root `(Bloodmoon) Dragon (West)-(Bloodmoon) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `33b816c9c5b85555b08a29061041e2a13bbca8a43bbfe5986283f9f0ab652bf3`.
- `Eclipse Dragon (West).rbxm` — root `(Eclipse) Dragon (West)-(Eclipse) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `7f238d685bc7272a99bbd868a5493f84db42a43362a492489261f85e40be59a9`.
- `Violet Night Dragon (West).rbxm` — root `(Violet Night) Dragon (West)-(Violet Night) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `fdf279aea92dcb7201159aa30e9d63632da78b1d17b71f3269b8b009056f4159`.
- `Werewolf-Werewolf.rbxm` — root `Werewolf-Werewolf`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `e7ba4e0c537f2d1b2be3d924e1d887d1cccfa9400aff6e04aa46bfb0f1c071e0`.

`Werewolf-Werewolf.rbxm` và file được chọn cho Werewolf (Tiger) có SHA-256 và ID animation khác nhau dù root cùng tên. Tên root không đủ để hoán đổi hai file. Các file Dragon biến thể cũng thiếu xác nhận ItemId tương ứng.

## Bằng chứng

- Lượt đo mới `blox-catalog-fruit-skin-audit-100117331123089.json`, complete=true, processed=134, phạm vi file local và Tool hiện có.
- Catalog `dist/catalog.json` và quy tắc tra file trong `catalog/FruitModels.luau`.
- Work Potassium `codex_fruit_studio/models` cùng các báo cáo `blox-fruits-model-audit-100117331123089.json`, `blox-fruits-visual-parity-2753915549.json` và `blox-fruits-all-fruit-animations-v2-2753915549.json`.
- Đo chuyển động `blox-fruits-v12-animation-validation-2753915549.json` và `blox-fruits-original-animation-rigs-2753915549.json`. Bằng chứng cầm dùng `blox-fruits-held-visuals-2753915549.json`, `blox-fruits-fruit-runtime-100117331123089.json` và các mẫu Spin/Buddha trước đó.
- Phản hồi hình ảnh trong `data/fruit-user-feedback-2026-11-21.json` và cập nhật ngày 26/11 chấp nhận trạng thái Gas.
