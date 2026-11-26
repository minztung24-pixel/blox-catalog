# ASSET_AUDIT — Fruit gốc và skin

Kiểm kê ngày 26/11/2026. Phạm vi là 81 mục trong tab Fruits của Catalog v12.1. Đã đọc lại 50 file .rbxm trong Work Potassium, kiểm tra header và đối chiếu tên cùng thời điểm sửa file với hai báo cáo cùng bộ file. Các cột Mesh, Texture và VFX dùng bằng chứng đã ghi ngày 20–21/11. Khả năng cầm và trạng thái animation của 7 trái đã được đo lại trong Blox Fruits ngày 26/11, theo báo cáo motion-check. Tiger chưa có mẫu trong lượt đo mới. Các kết quả khác giữ ngày đo đã nêu.

- Có model qua đối chiếu: **45/81**. File có một root Tool/Model và có BasePart. Kết quả này chưa kiểm tra thao tác Equip của từng trái.
- **35/81** chưa có file khớp. **1/81** có file đúng tên nhưng chứa nhầm model và bị chặn khi nhập.
- **34 rig** đã có số đo chuyển động trong báo cáo v12. Số liệu không đánh giá hình ảnh có đúng với bản game hiện tại hay không.
- **496/497** tham chiếu tài nguyên riêng biệt tải thành công trong lần đo cũ. Lỗi duy nhất là texture hạt trên Buddha. Đây không phải số món đồ hay số texture của icon Catalog.
- **Kiểm tra lại ngày 26/11 trong Studio:** place demo bị từ chối quyền tải cả 7 ID animation gốc của 8 trái thiếu chuyển động và clip thử của Flame. Hai clip đối chứng tải được. Cột Animation bên dưới giữ kết quả theo rig và file đã đo trước đó. [Kết quả Studio trong DIAG](DIAG.md#kiểm-tra-lại-trong-roblox-studio-ngày-26112026)

- **Đo lại trong Blox Fruits ngày 26/11:** Dragon, Dragon (West), Ember, Flame, Lightning, Quake và Werewolf (Tiger) đều có 4 mẫu Tool đang cầm, trạng thái cuối Failed do preload trả Failure và không có track đang chạy. Báo cáo kết thúc bình thường nhưng thiếu Tiger (1430).


## Phân loại cập nhật ngày 27/11/2026, v12.5

Bảng bên dưới bao gồm **81 trái vật phẩm**, hiện chia thành **47 mục Fruits** và **34 mục Fruit Skins**. Arcsteel và Galaxy thuộc nhóm skin. Empyrean → Kitsune, Fiend (Yeti) → Yeti, Hellfire (Gas) → Gas và Werewolf (Tiger) → Tiger được phân loại theo xác nhận của người dùng, lưu trong data/fruit-variant-relations.json. IsDefault chỉ xác định diện mạo mặc định trong một biến thể, không chứng minh đó là fruit gốc.

**Fruit gốc** có 40 file khớp và **7 mục thiếu file**, gồm Celestial, Dragon (East), Magnet, Oni, Portal, Rocket, Venom. **Trái mang skin** có 5 file được chấp nhận, **28 mục thiếu file**, và Empyrean có file chứa sai Galaxy nên bị chặn. Tổng vẫn là 45 nguồn qua đối chiếu, 35 mục thiếu file và 1 nguồn bị chặn.

Tab Fruit Skins có 87 thẻ, gồm 34 trái vật phẩm mang skin, 31 skin chưa có Physical và 22 bản redeemable. 46 định nghĩa skin có bản vật phẩm tương ứng được ẩn khỏi kết quả tìm kiếm để tránh thẻ trùng. Cả 351 ItemId vẫn có trong database. Model và tham chiếu animation của skin tiếp tục gắn với ItemId riêng, không lấy file của fruit gốc thay vào.

Lỗi chuyển động được báo ở cả hai nhóm. Fruit gốc gồm Dragon, Dragon (West), Flame, Lightning, Quake và Tiger. Skin gồm Ember và Werewolf (Tiger). Phép đo mới ghi được 7/8 mục đang cầm nhưng preload thất bại, riêng Tiger chưa có mẫu mới. VFX trong bảng ghi cấu trúc file và phản hồi đã có, chưa xác nhận toàn bộ hình ảnh đúng với game hiện tại.

Cột **Mesh** ghi số MeshPart và số tham chiếu mesh tải thành công / tổng trong báo cáo. **Texture** đếm các tham chiếu bề mặt và texture ngoài VFX. **VFX** ghi số ParticleEmitter/Beam/Trail bật / tổng trong file, sau đó là tỷ lệ tải texture của chúng. Tài nguyên dùng chung có thể xuất hiện ở nhiều dòng. **0 ref.** nghĩa là phép đo không ghi được tham chiếu thuộc nhóm đó. VFX không xuất hiện trong file hoặc chưa được người dùng nhìn thấy chưa đủ để kết luận có lỗi.

| Fruit | ID | Tab v12.5 | Model trong Work Potassium | Mesh | Texture | Cầm / Equip | Animation | VFX | Ghi chú |
|---|---|---|---|---|---|---|---|---|---|
| Arcsteel Magnet | 1525 | Fruit Skins | Có model · Arcsteel Magnet.rbxm | 3 · 3/3 | 7/7 | Đã thấy cầm | Rig chạy · 47 khớp · 90561160320604 | 9/51 bật · 33/33 | — |
| Azura Bomb | 512 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Blade | 1399 | Fruits | Có model · Blade-Blade.rbxm | 4 · 4/4 | 0 ref. | Có BasePart · chưa thử cầm | Rig chạy · 11 khớp · 15123613404 | 0/0 bật · 0 ref. | — |
| Blizzard | 1416 | Fruits | Có model · Blizzard-Blizzard.rbxm | 4 · 4/4 | 6/6 | Có BasePart · chưa thử cầm | Rig chạy · 28 khớp · 15123587371 | 8/8 bật · 7/7 | — |
| Bomb | 1397 | Fruits | Có model · Bomb-Bomb.rbxm | 5 · 5/5 | 1/1 | Có BasePart · chưa thử cầm | Rig chạy · 38 khớp · 15123595806 | 3/12 bật · 8/8 | — |
| Buddha | 1393 | Fruits | Có model · Buddha-Buddha.rbxm | 6 · 6/6 | 1/1 | Có mẫu thật từng cầm | Rig chạy · 61 khớp · 15123606541 | 1/2 bật · 1/2 ⚠ | Đổi Idle theo mẫu Buddha; 1 texture VFX tải lỗi |
| Celebration Bomb | 539 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Celestial | 1428 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Celestial Pain | 498 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Control | 1409 | Fruits | Có model · Control-Control.rbxm | 5 · 5/5 | 1/1 | Đã thấy cầm | Rig chạy · 36 khớp · 15123616275 | 0/0 bật · 0 ref. | Model cũ theo phản hồi |
| Creation | 1426 | Fruits | Có model · Creation-Creation.rbxm | 13 · 13/13 | 0 ref. | Có BasePart · chưa thử cầm | Rig chạy · 68 khớp · 116828771482820 | 0/0 bật · 0 ref. | — |
| Dark | 1395 | Fruits | Có model · Dark-Dark.rbxm | 6 · 6/6 | 3/3 | Có BasePart · chưa thử cầm | Rig chạy · 47 khớp · 15123618591 | 0/0 bật · 0 ref. | — |
| Diamond | 1421 | Fruits | Có model · Diamond-Diamond.rbxm | 5 · 5/5 | 0 ref. | Có BasePart · chưa thử cầm | File thiếu clip và controller | 3/3 bật · 2/2 | — |
| Divine | 1048 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Dough | 1417 | Fruits | Có model · Dough-Dough.rbxm | 6 · 6/6 | 4/4 | Có BasePart · chưa thử cầm | Rig chạy · 77 khớp · 15123624401 | 0/6 bật · 1/1 | — |
| Dragon | 1447 | Fruits | Có model · Dragon-Dragon.rbxm | 7 · 7/7 | 7/7 | Đã đo cầm · 4 mẫu · 26/11 | 89485756852231 · Preload Failure · 0 track · 26/11 | 8/8 bật · 7/7 | Người dùng thấy đứng yên; đã thấy VFX |
| Dragon (East) | 885 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Dragon (West) | 884 | Fruits | Có model · Dragon (West)-Dragon (West).rbxm | 7 · 7/7 | 7/7 | Đã đo cầm · 4 mẫu · 26/11 | 89485756852231 · Preload Failure · 0 track · 26/11 | 33/33 bật · 12/12 | Root ghi Dragon-Dragon, thiếu ItemId; Người dùng thấy đứng yên; đã thấy VFX |
| Eagle | 1425 | Fruits | Có model · Eagle-Eagle.rbxm | 3 · 3/3 | 4/4 | Có BasePart · chưa thử cầm | Rig chạy · 50 khớp · 77885466312115 | 0/12 bật · 7/7 | Eagle được thêm clip đã đo |
| Ember | 1047 | Fruit Skins | Có model · Ember Dragon (West).rbxm | 7 · 7/7 | 1/1 | Đã đo cầm · 4 mẫu · 26/11 | 96038340477884 · Preload Failure · 0 track · 26/11 | 8/8 bật · 7/7 | Người dùng thấy đứng yên; đã thấy VFX |
| Emerald Diamond | 471 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Empyrean | 1041 | Fruit Skins | Sai model · chặn · Empyrean (Kitsune)-Empyrean (Kitsune).rbxm | 6 · 6/6 | 2/2 | Bị chặn | — | 3/3 bật · 2/2 | Root Galaxy, thiếu ItemId |
| Fiend (Yeti) | 1060 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Flame | 1394 | Fruits | Có model · Flame-Flame.rbxm | 8 · 8/8 | 4/4 | Đã đo cầm · 4 mẫu · 26/11 | 92872930988510 · Preload Failure · 0 track · 26/11 | 6/6 bật · 5/5 | Người dùng thấy đứng yên; đã thấy VFX; Clip thử trước đó tải được nhưng 0 khớp chạy |
| Frustration Pain | 492 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Galaxy | 1042 | Fruit Skins | Có model · Galaxy Empyrean Kitsune.rbxm | 6 · 6/6 | 2/2 | Người dùng đã xem · chưa đo Equip | Rig chạy · 102 khớp · 121051622257427 | 3/3 bật · 2/2 | — |
| Gas | 1422 | Fruits | Có model · Gas-Gas.rbxm | 6 · 6/6 | 3/3 | Đã thấy cầm | Rig chạy · 109 khớp · 118054805452821 | 7/7 bật · 3/3 | Gas đã được chấp nhận |
| Ghost | 1412 | Fruits | Có model · Ghost-Ghost.rbxm | 3 · 3/3 | 1/1 | Có BasePart · chưa thử cầm | Rig chạy · 75 khớp · 15123662036 | 4/4 bật · 4/4 | — |
| Glacier Eagle | 496 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Gravity | 1405 | Fruits | Có model · Gravity-Gravity.rbxm | 8 · 8/8 | 3/3 | Có BasePart · chưa thử cầm | Rig chạy · 8 khớp · 15123633312 | 0/0 bật · 0 ref. | — |
| Green Lightning | 462 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Hellfire (Gas) | 1601 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Ice | 1392 | Fruits | Có model · Ice-Ice.rbxm | 4 · 4/4 | 3/3 | Có BasePart · chưa thử cầm | File thiếu clip và controller | 10/10 bật · 8/8 | — |
| Kitsune | 1423 | Fruits | Có model · Kitsune-Kitsune.rbxm | 6 · 6/6 | 4/4 | Người dùng đã xem · chưa đo Equip | Rig chạy · 128 khớp · 15487764876 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Light | 1407 | Fruits | Có model · Light-Light.rbxm | 6 · 6/6 | 3/3 | Có BasePart · chưa thử cầm | Rig chạy · 32 khớp · 15123640714 | 0/0 bật · 0 ref. | — |
| Lightning | 1427 | Fruits | Có model · Lightning-Lightning.rbxm | 8 · 8/8 | 4/4 | Đã đo cầm · 4 mẫu · 26/11 | 74759006007335 · Preload Failure · 0 track · 26/11 | 4/4 bật · 4/4 | Người dùng thấy đứng yên; đã thấy VFX |
| Lime Blade | 1526 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Love | 1408 | Fruits | Có model · Love-Love.rbxm | 6 · 6/6 | 6/6 | Người dùng đã xem · chưa đo Equip | Rig chạy · 46 khớp · 15123643097 | 3/3 bật · 2/2 | — |
| Magma | 1391 | Fruits | Có model · Magma-Magma.rbxm | 4 · 4/4 | 0 ref. | Đã thấy cầm | Rig chạy · 33 khớp · 15123645682 | 3/9 bật · 2/2 | Người dùng chưa thấy VFX |
| Magnet | 1516 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Mammoth | 1418 | Fruits | Có model · Mammoth-Mammoth.rbxm | 6 · 6/6 | 3/3 | Người dùng đã xem · chưa đo Equip | Rig chạy · 14 khớp · 15123648309 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Matrix Eagle | 502 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Meme | 1431 | Fruits | Có model · Meme-Meme.rbxm | 2 · 2/2 | 2/2 | Người dùng đã xem · chưa đo Equip | Đã thấy chạy · 94535044798318 (Success) | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Nuclear Bomb | 508 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Oni | 1429 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Orange Portal | 463 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Pain | 1406 | Fruits | Có model · Pain-Pain.rbxm | 6 · 6/6 | 7/7 | Người dùng đã xem · chưa đo Equip | Rig chạy · 43 khớp · 15123652069 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Phoenix | 1401 | Fruits | Có model · Phoenix-Phoenix.rbxm | 11 · 11/11 | 7/7 | Người dùng đã xem · chưa đo Equip | Rig chạy · 120 khớp · 15123654553 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Pink Portal | 458 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Portal | 1414 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Purple Lightning | 460 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Quake | 1389 | Fruits | Có model · Quake-Quake.rbxm | 4 · 4/4 | 3/3 | Đã đo cầm · 4 mẫu · 26/11 | 87225712156404 · Preload Failure · 0 track · 26/11 | 0/5 bật · 5/5 | Người dùng thấy đứng yên |
| Red Lightning | 540 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Requiem Eagle | 495 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Rocket | 1390 | Fruits | Thiếu file | — | — | Đã từng cầm · ngoài file | Người dùng từng thấy chuyển động | — | Đã từng cầm theo phản hồi |
| Rose Quartz Diamond | 470 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Rubber | 1396 | Fruits | Có model · Rubber-Rubber.rbxm | 3 · 3/3 | 3/3 | Người dùng đã xem · chưa đo Equip | Rig chạy · 83 khớp · 15123668008 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Ruby Diamond | 468 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Runic Fiend | 1522 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Sadness Pain | 479 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Sand | 1404 | Fruits | Có model · Sand-Sand.rbxm | 3 · 3/3 | 4/4 | Người dùng đã xem · chưa đo Equip | Rig chạy · 126 khớp · 15123673019 | 4/5 bật · 5/5 | — |
| Scarlet Ghost | 1524 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Shadow | 1413 | Fruits | Có model · Shadow-Shadow.rbxm | 6 · 6/6 | 6/6 | Người dùng đã xem · chưa đo Equip | Rig chạy · 89 khớp · 15123675904 | 3/4 bật · 3/3 | — |
| Smoke | 1400 | Fruits | Có model · Smoke-Smoke.rbxm | 4 · 4/4 | 3/3 | Có BasePart · chưa thử cầm | Rig chạy · 162 khớp · 15123677932 | 0/0 bật · 0 ref. | — |
| Sound | 1419 | Fruits | Có model · Sound-Sound.rbxm | 7 · 7/7 | 4/4 | Có BasePart · chưa thử cầm | Rig chạy · 3 khớp · 15123679712 | 7/7 bật · 6/6 | — |
| Spider | 1403 | Fruits | Có model · Spider-Spider.rbxm | 5 · 5/5 | 0 ref. | Người dùng đã xem · chưa đo Equip | Rig chạy · 100 khớp · 15123681598 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Spike | 1398 | Fruits | Có model · Spike-Spike.rbxm | 7 · 7/7 | 1/1 | Có BasePart · chưa thử cầm | Rig chạy · 72 khớp · 15124220207 | 0/0 bật · 0 ref. | — |
| Spin | 1411 | Fruits | Có model · Spin-Spin.rbxm | 3 · 3/3 | 3/3 | Có mẫu thật từng cầm | Rig chạy · 15 khớp · 15123685330 | 0/0 bật · 0 ref. | — |
| Spirit | 1415 | Fruits | Có model · Spirit-Spirit.rbxm | 11 · 11/11 | 11/11 | Người dùng đã xem · chưa đo Equip | Rig chạy · 24 khớp · 11911905519 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Spring | 1402 | Fruits | Có model · Spring-Spring.rbxm | 4 · 4/4 | 3/3 | Người dùng đã xem · chưa đo Equip | Rig chạy · 38 khớp · 15123689268 | 0/0 bật · 0 ref. | Người dùng chưa thấy VFX |
| Starlight Gravity | 1523 | Fruit Skins | Có model · Heavenly Gravity.rbxm | 9 · 9/9 | 6/6 | Có BasePart · chưa thử cầm | Rig chạy · 29 khớp · 15123633312 | 0/0 bật · 0 ref. | — |
| Super Spirit Pain | 541 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| T-Rex | 1420 | Fruits | Có model · T-Rex-T-Rex.rbxm | 3 · 3/3 | 5/5 | Có BasePart · chưa thử cầm | Rig chạy · 27 khớp · 15694681122 | 4/4 bật · 3/3 | — |
| Thermite Bomb | 511 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Tiger | 1430 | Fruits | Có model · Tiger-Tiger.rbxm | 6 · 6/6 | 2/2 | Người dùng đã xem · chưa đo Equip | 119940442528522 (Failure) | 0/0 bật · 0 ref. | Người dùng thấy đứng yên; đã thấy VFX |
| Topaz Diamond | 469 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Torment Pain | 491 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Venom | 1410 | Fruits | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Werewolf (Tiger) | 814 | Fruit Skins | Có model · Werewolf (Tiger)-Werewolf (Tiger).rbxm | 6 · 6/6 | 3/3 | Đã đo cầm · 4 mẫu · 26/11 | 133333989918142 · Preload Failure · 0 track · 26/11 | 0/0 bật · 0 ref. | Người dùng thấy đứng yên; đã thấy VFX |
| Yellow Lightning | 450 | Fruit Skins | Thiếu file | — | — | Chưa xác nhận | — | — | — |
| Yeti | 1424 | Fruits | Có model · Yeti-Yeti.rbxm | 5 · 5/5 | 4/4 | Người dùng đã xem · chưa đo Equip | Rig chạy · 108 khớp · 115276580506154 | 8/8 bật · 6/6 | — |

## Các file Catalog chưa chọn

- `Bloodmoon Dragon (West).rbxm` — root `(Bloodmoon) Dragon (West)-(Bloodmoon) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `33b816c9c5b85555b08a29061041e2a13bbca8a43bbfe5986283f9f0ab652bf3`.
- `Eclipse Dragon (West).rbxm` — root `(Eclipse) Dragon (West)-(Eclipse) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `7f238d685bc7272a99bbd868a5493f84db42a43362a492489261f85e40be59a9`.
- `Violet Night Dragon (West).rbxm` — root `(Violet Night) Dragon (West)-(Violet Night) Dragon (West)`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `fdf279aea92dcb7201159aa30e9d63632da78b1d17b71f3269b8b009056f4159`.
- `Werewolf-Werewolf.rbxm` — root `Werewolf-Werewolf`. Chưa có mục Fruits khớp theo storageKey/tên. SHA-256 `e7ba4e0c537f2d1b2be3d924e1d887d1cccfa9400aff6e04aa46bfb0f1c071e0`.

`Werewolf-Werewolf.rbxm` và file được chọn cho Werewolf (Tiger) có SHA-256 và ID animation khác nhau dù root cùng tên. Tên root không đủ để hoán đổi hai file. Các file Dragon biến thể cũng thiếu xác nhận ItemId tương ứng.

## Bằng chứng

- Catalog `dist/catalog.json` và quy tắc tra file trong `catalog/FruitModels.luau`.
- Work Potassium `codex_fruit_studio/models` cùng các báo cáo `blox-fruits-model-audit-100117331123089.json`, `blox-fruits-visual-parity-2753915549.json` và `blox-fruits-all-fruit-animations-v2-2753915549.json`.
- Đo chuyển động `blox-fruits-v12-animation-validation-2753915549.json` và `blox-fruits-original-animation-rigs-2753915549.json`. Bằng chứng cầm dùng `blox-fruits-held-visuals-2753915549.json`, `blox-fruits-fruit-runtime-100117331123089.json` và các mẫu Spin/Buddha trước đó.
- Phản hồi hình ảnh trong `data/fruit-user-feedback-2026-11-21.json` và cập nhật ngày 26/11 chấp nhận trạng thái Gas.
