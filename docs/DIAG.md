# DIAG — Model và chuyển động của Fruits

Ngày 26/11/2026. Catalog v12.1. Trong 81 mục, **45 có model qua đối chiếu, 35 chưa có file khớp, 1 bị chặn vì file chứa sai model**. Xem bảng theo ItemId trong [ASSET_AUDIT.md](ASSET_AUDIT.md).

## Model có file nhưng không dùng được hoặc hiển thị chưa đúng

- **Empyrean (1041)** có file đúng storageKey nhưng root là Galaxy Empyrean Kitsune Fruit và thiếu ItemId. [FruitModels.luau](../catalog/FruitModels.luau#L60) chặn khi mở file. Thẻ có thể vẫn báo Equip vì [UI.luau](../catalog/UI.luau#L372) dùng việc tìm thấy đường dẫn như một điều kiện tô xanh. Galaxy (1042) có file riêng đã đo rig.
- **Control (1409)** có file, đã từng cầm và rig đã chạy với clip v12. Người dùng báo hình dáng trong file là mẫu cũ. Việc đổi animation không cập nhật được hình dáng.
- **Dragon (West) (884)** có file riêng, khác file Dragon (1447). Root vẫn ghi Dragon-Dragon và thiếu ItemId. Báo cáo ngày 26/11 đã bắt được 4 mẫu đang cầm, nhưng animation preload thất bại. **Dragon (East) (885)** chưa có file trùng tên hoặc storageKey. Chưa có bằng chứng để dùng hai file kia cho East.
- **Rocket (1390)** không có file trong Work Potassium dù người dùng từng báo có chuyển động. Có thể cầm ở một phiên không xác nhận Catalog có thể nhập lại model từ ổ đĩa. Báo cáo quét nguồn thời gian chạy cũ chạm giới hạn, nên kết quả trống của báo cáo không chứng minh tài nguyên không tồn tại trong game.
- Bốn file chưa được chọn đã được đối chiếu theo tên và root. Chưa tìm được liên kết ItemId đủ chắc chắn để dùng chúng thay cho các trái đang thiếu. Hai file Werewolf cùng tên root nhưng khác checksum và clip.

## Các trái được báo thiếu chuyển động

| Fruit | ID | Kết quả trên model hiện có |
|---|---|---|
| Dragon | 1447 | Rig có controller. Clip trong file 89485756852231 tải lỗi ở lần đo cũ. |
| Dragon (West) | 884 | Rig có controller. Clip trong file 89485756852231 tải lỗi ở lần đo cũ. |
| Ember | 1047 | Rig có controller. Clip trong file 96038340477884 tải lỗi ở lần đo cũ. |
| Flame | 1394 | Rig có controller. Clip trong file 92872930988510 tải lỗi ở lần đo cũ. Clip thử 121545956771325 tải được, nhưng 0 khớp đổi pose. |
| Lightning | 1427 | Rig có controller. Clip trong file 74759006007335 tải lỗi ở lần đo cũ. |
| Quake | 1389 | Rig có controller. Clip trong file 87225712156404 tải lỗi ở lần đo cũ. Cả 5 emitter/beam/trail trong file đều tắt. |
| Tiger | 1430 | Rig có controller. Clip trong file 119940442528522 tải lỗi ở lần đo cũ. |
| Werewolf (Tiger) | 814 | Rig có controller. Clip trong file 133333989918142 tải lỗi ở lần đo cũ. |

Diamond và Ice thiếu cả clip lẫn AnimationController trong file. Chưa có mẫu đối chứng xác nhận hai trái này phải chuyển động. Eagle thiếu clip trong file gốc nhưng đã có clip được đo chạy trong v12. Báo cáo tải clip gốc có **5 ID thành công và 38 ID thất bại** ở lần đo cũ. Báo cáo tiếp theo đo được chuyển động trên **34 rig**, gồm 30 ánh xạ kiểm tra đúng rig, Buddha và 3 trái đối chứng. Không trộn số đo tải clip với số đo chuyển động.

### Đo lại trong Blox Fruits ngày 26/11/2026

Đã đọc blox-catalog-motion-check-2753915549.json trong Work Potassium. Báo cáo kết thúc bình thường (complete=true) nhưng chưa ghi đủ 8 mục (targetsComplete=false). Mục thiếu là Tiger (1430). Có 7 Tool thuộc Catalog, mỗi Tool có 4 mẫu đang được cầm.

| Fruit | ItemId | Clip thực tế trong Tool | Kết quả mới |
|---|---|---|---|
| Dragon | 1447 | 89485756852231 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Dragon (West) | 884 | 89485756852231 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Ember | 1047 | 96038340477884 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Flame | 1394 | 92872930988510 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Lightning | 1427 | 74759006007335 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Quake | 1389 | 87225712156404 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |
| Werewolf (Tiger) | 814 | 133333989918142 | Preload Failure, trạng thái cuối Failed, 0 track trong cả 4 mẫu |

Nguyên nhân trực tiếp của việc đứng yên trong lượt đo là bước tải clip thất bại trước Animator:LoadAnimation. Tool đã nằm trong Character. Lượt đo chưa đánh giá được khả năng hoạt động của rig với clip tải thành công. Kết quả này cũng chưa xác định được lý do cụ thể của Failure trong Blox Fruits. Lỗi quyền đã quan sát ở Studio thuộc place test riêng.

Flame đang dùng lại clip trong file (92872930988510). Clip thử trước đó (121545956771325) chưa được chấp nhận vì không tạo chuyển động trên rig. Việc thử thất bại không phải một ánh xạ animation đã được phát hành.

Tiger chưa có lượt Equip được ghi nhận trong báo cáo này. Gas được loại khỏi phạm vi theo yêu cầu. Các lỗi NPC Desert Officer và asset FX khác trong ảnh F9 không đủ liên hệ với lỗi clip của 7 Tool, nên chưa gán chúng làm nguyên nhân.

Cần clip phù hợp mà môi trường đích tải được để kiểm tra chuyển động tiếp. Chưa có clip thay thế đã được kiểm chứng cho 7 Tool trong lần đo này.

### Kiểm tra lại trong Roblox Studio ngày 26/11/2026

Place `Untitled Experience` (`85329861831512`) chỉ có các model demo trong lần kiểm tra. Studio trả trạng thái `Failure` và ghi lỗi quyền truy cập cho cả **7 ID gốc** trong bảng trên và **clip thử của Flame** (`121545956771325`). Dragon và Dragon (West) dùng chung một ID gốc. Hai clip đối chứng trong tài liệu Roblox (`656118852` và `656117400`) tải thành công qua cùng API. Ví dụ đối chứng đầu tiên (`2515090838`) cũng bị từ chối trong place này.

Phép đo mới kiểm tra quyền tải của place Studio. Kết quả Flame tải được nhưng không làm khớp đổi pose là từ báo cáo cũ, ở một phiên khác. Để thử chuyển động trong Studio cần có đúng rig cùng clip mà place được cấp quyền dùng. [Tài liệu Roblox về tải tài nguyên](https://create.roblox.com/docs/reference/engine/classes/ContentProvider#PreloadAsync)

### Kiểm tra model và clip được phép dùng

[`CheckStudioFruitAsset.luau`](../tools/CheckStudioFruitAsset.luau) nhận một Model/Tool và một Animation tùy chọn. Nếu bỏ qua Animation, công cụ tìm `Idle` rồi `Animation` cạnh controller. Nó báo ItemId, Handle, số MeshPart, VFX đang bật và số khớp. Trong Edit, công cụ kiểm tra khả năng tải. Trong Play, công cụ lấy mẫu pose trên một bản sao tạm và dọn bản sao khi xong.

Kết quả `LoadFailed` nghĩa là clip không tải được. `NoMotionObserved` nghĩa là clip đã tải nhưng không có thay đổi pose trong các mẫu đã đo. `Moved` nghĩa là đã đo được khớp đổi pose. Các kết quả này không xác nhận hiệu ứng hiển thị hay thao tác Equip trong Catalog.

Đã thử công cụ trong Studio ngày 26/11. Demo Ember báo `MissingClip`. Avatar Studio với clip đối chứng báo `Moved`, 13/15 khớp đổi pose. Clip Dragon bị từ chối báo `LoadFailed`. Phiên Play đã kết thúc và bản sao đã được dọn.

## VFX và khả năng cầm

- **Buddha** có rig chạy. Texture hạt `6960307279` tại `Fruit/Aura1/Attachment/Particle_2` tải thất bại trong báo cáo. Các tham chiếu mesh của file này tải thành công khi đó.
- **Magma** có số đo khi đang cầm và có VFX trong file. Người dùng chưa thấy VFX khi thử. Các trường hợp như **Kitsune** có chuyển động nhưng file không có emitter/beam/trail cần mẫu đối chiếu trước khi kết luận lỗi VFX.
- **Arcsteel Magnet, Gas, Magma và Control** có mẫu ghi nhận Tool mô phỏng đang được cầm. Có BasePart hoặc rig chạy riêng chưa đủ để ghi đã thử Equip. Gas được người dùng chấp nhận và mắt không còn nằm trong phạm vi sửa.

Ưu tiên các trái đã có đúng model nhưng thiếu chuyển động trong bảng trên. Flame cần clip có chuyển động đo được trên chính rig của nó. Các trái thiếu file, Control và Empyrean cần model đúng ItemId mà dự án có quyền dùng. Kết quả hiện tại chưa xác nhận được nguồn thay thế cho các mục này.

## Drop ngày 27/11/2026

Bản v1 đã ghi được Spin Fruit (1411) từ Character sang Workspace. Lúc thả, khớp RightGrip với tay biến mất, Handle cách phía trước nhân vật khoảng 5 studs, CanCollide=true, Massless=false, vận tốc tuyến tính (0, 1, 0), vận tốc góc bằng 0. Mẫu không có ProximityPrompt. Báo cáo ghi dropObserved=true. Người dùng cho biết người khác đã nhặt trái, còn công cụ không quan sát được pickup của người dùng.

v12.2 sửa Drop của Tool mô phỏng theo dữ liệu ban đầu đã ghi. Bỏ prompt nhặt bằng E, gỡ khớp với tay, bảo toàn khớp trong model, đặt vị trí và vận tốc thả. Nhặt bằng tiếp xúc được triển khai cho mô phỏng và kiểm tra riêng trong Studio. Không suy diễn các mẫu sau khi vật phẩm đã bị người khác nhặt thành vật lý rơi bình thường.

Kiểm tra Studio đã qua thao tác tiếp xúc của nhân vật, bỏ qua tiếp xúc của vật ngoài nhân vật, thả lại và dọn kết nối khi Clear. Chưa kiểm tra hình ảnh bản v12.2 trong phiên Blox Fruits của người dùng.

Người dùng xác nhận v12.2 thả và nhặt được, nhưng ảnh Arcsteel cho thấy thân trái ở cao hơn mặt đất. Studio tái hiện được với Handle vô hình quá lớn và thân nhìn thấy nằm lệch phía trên Handle. v12.3 dùng một hộp va chạm theo các góc của BasePart nhìn thấy trong hệ tọa độ Handle, bỏ qua các phần hoàn toàn trong suốt. Collider này chỉ va chạm khi đã thả. Phép đo tiếp đất của thân trong fixture nằm trong sai số 0.15 studs so với mặt sàn. Box theo biên MeshPart chưa đánh giá được mọi biến dạng của mesh skinned trong animation.
