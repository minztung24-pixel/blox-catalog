# DIAG — Model và chuyển động của Fruits

Cập nhật ngày 28/11/2026, Catalog v12.25. Trong 81 trái vật phẩm, **45 nạp được model, 35 chưa có file khớp, 1 bị chặn vì file chứa sai model**. Thống kê toàn bộ giữ mốc 27/11; các lượt đối chứng 28/11 ghi riêng bên dưới. Chưa tăng số model đã xác nhận. Xem bảng theo ItemId trong [ASSET_AUDIT.md](ASSET_AUDIT.md).

## Nhận nguồn từ người chơi khác và lưu cache, v12.25

Mở rộng watcher để nhận Tool trái vật phẩm trực tiếp trong Character của người chơi khác mà client đã nhận qua replication. Xác thực Character bằng Players.GetPlayerFromCharacter, ItemId vật phẩm phải khớp Catalog. Không quét Backpack riêng của người khác, không chọn model NPC theo tên, không yêu cầu server tải tài nguyên. Nguồn của mình vẫn ưu tiên; nguồn của người chơi khác được thay bằng bản mới khi nguồn quan sát cũ biến mất. Nguồn gốc không bị đổi parent, phá hủy hay sửa thuộc tính. Có xử lý người vào/rời và Character mới.

Nguồn nhận được đi qua Equipment.clone như trước. FruitArchive lưu bản sao riêng, loại scripts/remotes, tags và metadata runtime, giữ ItemId vật phẩm; không lưu tên/ID chủ sở hữu vào chỉ mục. Native saveinstance chỉ nhận đúng bản sao Tool với Decompile=false, không nhận game hay Character. Model/metadata dùng tên riêng blox-catalog-captured-fruit-<ItemId>-<GUID>; không ghi đè 50 file gốc trong codex_fruit_studio/models. Chỉ mục blox-catalog-captured-fruits-v1.json có bản dự phòng.

Exporter native đã được đo trên Yeti: xuất đúng Tool/rig nhưng bỏ ItemId và làm tròn một số NumberRange/NumberSequence của VFX. File đó bị từ chối. Thêm metadata giá trị gốc cho ba kiểu NumberRange/NumberSequence/ColorSequence để khôi phục đúng giá trị đã quan sát, không nới dung sai 0.000001. Sau nạp phải khớp cây cha/con, class/tên node và các thuộc tính mesh/texture/rig/render/VFX được kiểm tra. Sai cấu trúc, geometry, ItemId hoặc file hỏng không được ghi vào chỉ mục. Archive được thử trước bộ file cũ khi Equip; thẻ khả dụng nhận chỉ mục từ lúc mở Catalog.

Giới hạn: tối đa 3000 descendants/model, 8 MiB file model, 2 MiB metadata; chỉ lưu sau khi có MeshPart/SpecialMesh. Save được gom đợt, đóng Catalog hủy các save đang chờ và ngăn commit muộn. Export không hỗ trợ hoặc kiểm chứng thất bại vẫn giữ snapshot trong RAM của phiên hiện tại. Không phục hồi controller/code đã loại bỏ, quyền tải asset hay motion clip server chưa cấp. Không theo dõi mọi thay đổi thuộc tính chạy theo frame.

Kiểm thử Client Play đạt: FruitOtherCharacter, FruitSourceWatch, FruitVisuals, FruitArchive, FruitModels, FruitPreviewModels, FruitAnimationImport và FruitPreviewScan. Có cold load qua FruitModels, sai skin, metadata vượt quyền, cây bị đổi dù thứ tự node giữ nguyên, geometry hỏng, đường dẫn vượt namespace, đóng trước save; mutation bỏ kiểm chứng geometry bị bài test bắt. Thay nguồn quan sát đã biến mất được tái hiện lỗi trước sửa và đạt sau sửa. 7 Python build checks đạt và bundle chạy được trong Studio.

Lượt native Potassium đã hoàn tất, complete=true và passed=true: Yeti (1424), Arcsteel Magnet (1525), Dark (1395) đều export → kiểm chứng → ghi chỉ mục → tạo bộ nạp mới → load lại thành công. Đúng ItemId, đúng rig signature, khớp cấu trúc cha/con và các thuộc tính đã đo sau khôi phục curve/range. Snapshot lần lượt có 148/150/89 descendants, file 79578/113194/47177 bytes. Giá trị runtime bị loại nên đây không phải bản sao toàn bộ Tool gameplay. Không Equip, Drop hoặc gọi giao dịch trong phép đo. Báo cáo chi tiết và model ở Work Potassium riêng tư; bản tổng hợp không có danh tính người chơi ở data/fruit-capture-check-2026-11-28.json.

Không có model thuộc 35 mục thiếu được xác nhận mới trong đợt này. Dragon và 7 mục idle lỗi khác giữ nguyên kết quả cũ; mở rộng đường tìm nguồn và lưu nguồn không đồng nghĩa đã sửa clip.

## Tự nhận nguồn native đến muộn, v12.24

V12.23 chỉ nhận nguồn đang có lúc mở panel, respawn hoặc Rescan. Regression UI tạo native preview holder/model sau lần quét đầu tiên giữ thẻ Venom ở màu thiếu model; World Tool mới cũng chưa vào cache nếu không quét lại. Thêm FruitModels.watch để nghe thụ động DescendantAdded trong player/Workspace, ItemId và ancestry của nguồn phù hợp. Không polling theo frame, gọi remote hoặc tự mở/quay Gacha.

Chỉ theo dõi Tool trực tiếp ở Backpack của player, Character hiện tại hoặc Workspace; Tool/Model trong đúng PlayerGui.__ReplicatedSpinnerInstances cũng hợp lệ. Bỏ qua clone Catalog, ID không thuộc trái vật phẩm và nguồn của nhân vật khác. Tối đa 256 nguồn được theo dõi đồng thời; giới hạn nhập model 3000 descendants vẫn giữ. Rescan cũ vẫn dùng được.

Capture được defer/coalesce theo nguồn để nhận các child cùng đợt replication. ItemId đến sau hoặc thêm child mesh/animation/VFX sẽ cập nhật snapshot qua sanitizer hiện có; giữ clip/FX đang quan sát, không suy diễn tài nguyên chưa có. Refresh cùng nguồn không còn bị memoization bỏ qua. Preview khác vẫn không đè Tool thật đã cache. Một đợt cập nhật chỉ yêu cầu render một lần; không sửa inventory/stock, model gốc hay giao dịch.

Đóng Catalog ngắt cả listener toàn cục và listener từng nguồn, hủy tác dụng của callback đang chờ; native source không bị phá. Kiểm thử Client Play: model tới sau khi mở UI tự hiện xanh không bấm Rescan, Tool native tới sau cũng được nhận, ItemId/animation/FX tới muộn được giữ, đúng base/skin, loại scripts/remotes, giữ ưu tiên Tool thật, giữ snapshot sau cleanup và đóng khi capture đang chờ. Regression UI thất bại trước sửa và đạt sau sửa; các bài FruitModels/FruitPreviewModels/FruitAnimationImport vẫn đạt.

Đây là sửa đường nhận/cập nhật nguồn game thực sự cấp, không chứng minh đã khôi phục 35 file thiếu hay clip Dragon. Không theo dõi mọi thay đổi thuộc tính FX do script chạy theo frame; không phục dựng controller bị thiếu trong file. Chưa đo lại toàn bộ 81 trái hoặc xác nhận một model thiếu mới trong live game. Kết quả 33 ca animation trước đó giữ nguyên.

## Đối chứng Yeti/Shadow/Dark và Dragon, ngày 28/11/2026

User xác nhận Yeti, Shadow và Dark là các mẫu hiển thị đầy đủ. Chạy CompareFruitAnimationPaths trong Blox Fruits bằng module v12.23, trên bản sao sạch, vô hình; không Equip/Drop/Store trái thật và không gọi giao dịch. 11 mục × 3 đường phát = 33 trường hợp, hoàn tất trong 124.05 giây, cả 9 trường hợp đối chứng đều đổi pose. Ba đường gồm Catalog preload, Animator.LoadAnimation rồi Play ngay, và AnimationController.LoadAnimation rồi Play ngay theo API dùng trong FruitAnimator native. Mỗi đường trực tiếp chờ tối đa 7 giây.

| Đối chứng | Khớp đổi pose / đo | VFX đang bật / có trong file | Kết quả cả 3 đường |
|---|---|---|---|
| Yeti, 1424 | 108/120 | 8/8 | Đổi pose |
| Shadow, 1413 | 89/99 | 3/4 | Đổi pose |
| Dark, 1395 | 47/70 | 0/0 | Đổi pose |

Dragon (1447), Dragon (West) (884), Ember (1047), Flame (1394), Lightning (1427), Quake (1389), Tiger (1430) và Werewolf (Tiger) (814): cả 8 bị preload Failure; cả 16 đường phát trực tiếp trả track nhưng Length vẫn bằng 0 khi hết hạn. Dragon và Dragon (West) dùng chung 89485756852231, nên đây là 8 mục và 7 ID riêng biệt. Không có bằng chứng rằng bỏ preload hoặc đổi từ Animator sang AnimationController sẽ khắc phục được các clip hiện có. Phép đo chưa phân biệt được quyền truy cập, ID cũ hay nguyên nhân phân phối tài nguyên; không kết luận chắc chắn bị khóa quyền chỉ từ kết quả này.

Dragon vẫn có 8/8 VFX bật, West 33/33, Ember 8/8, Flame 6/6, Lightning 4/4; Quake 0/5, Tiger/Werewolf 0/0 trong file. Đây là trạng thái dữ liệu trước khi tắt FX trên bản sao đo, không phải phép thử VFX hình ảnh. Dark là mẫu user xác nhận chuẩn dù file không có ParticleEmitter/Beam/Trail, nên không đánh dấu mọi mục 0 VFX là lỗi hoặc tự bật tất cả emitter.

Chạy thêm CompareFruitVisuals trên 50 file hiện có với Equipment.clone v12.23: complete=true, 0 lỗi model, 0 lỗi đọc thuộc tính, 0 file có khác biệt ở các thuộc tính được đo. Bao gồm mesh/texture/PBR, attachment, bone/motor, emitter/beam/trail, image, GUI và light. 496/497 tham chiếu render tải được; Buddha 6960307279 tiếp tục Failure. Đối chiếu này chỉ chứng minh bảo toàn dữ liệu từ file sang clone, không chứng minh file đầy đủ so với game hiện tại, không kiểm tra controller/script đã thiếu từ trước khi xuất file.

Không đổi logic animation sản phẩm hoặc tăng số model đã khôi phục sau lượt kiểm tra này. 35 file thiếu và Empyrean chứa nhầm Galaxy vẫn còn; các trái khác ngoài 11 mục không được phát lại animation. Kết quả đã loại source thô/thông tin cá nhân ở data/fruit-reference-check-2026-11-28.json; hai báo cáo runtime gốc giữ private. Chưa cần user chạy thêm mã hoặc mua/thả trái để đo lại.

## Shop, Dealer, Gacha và nguồn preview bị bỏ sót, v12.23

Kiểm tra ItemConfig đang cache ghi 258 cấu hình liên quan, gồm đủ 81 PhysicalMoveset. Shop gốc có 195 ImageLabel, 37 ImageButton và không có ViewportFrame trong lượt đọc ban đầu. Những ảnh atlas đủ tên/icon không phải model 3D. Các cấu hình vật phẩm dùng State.EquipMethod=LoadFruit nhưng không chứa trường mesh/model/animation/VFX; tên phương thức không cung cấp mã tải phía server.

NPC FruitShop (Blox Fruit Dealer) mở Library.openFruitShop("FruitDealer"). Chính lời thoại native nói mua ở đây cấp năng lực thay vì trái vật phẩm. StateUtil mua tạm thời qua PurchaseRawFruit, mua permanent qua buyRobuxShop, chuyển năng lực đã sở hữu qua SwitchFruit. Chỉ đọc source, không gọi các giao dịch đó.

NPC RandomFruitSeller (Blox Fruit Gacha/Zioles) dùng GachaClient.CheckGachaAsync rồi GachaWindow.Open("ZiolesGacha", cost). GachaClient phân biệt rõ Context Check/getGachaFromBoxName với Purchase trên GachaNetworkRF. Cửa Gacha nối Spinner; Spinner nhận SpinGacha và PrepClientSpin từ server. GachaSimulation là công cụ riêng có kiểm tra build không phải live, không dùng để thử cấp model hay quay.

PreviewModel.HOLDER_NAME xác nhận kho native PlayerGui.__ReplicatedSpinnerInstances. Replicator chỉ đọc/clone template khi game đã cấp; không phải danh sách ID tải được tùy ý. Catalog trước đây bỏ qua kho này. Rescan nay quét kho trước các root cũ, chỉ nhận root Tool/Model có ItemId vật phẩm chính xác, không suy từ tên/icon, không lấy base fruit thay skin. Bản sao qua Equipment.clone giữ animation/FX gốc, loại code/remotes/tags; cache sống sau khi preview bị dọn. Tool thật đã capture được ưu tiên hơn preview. Không gọi PreviewModel.new, remote tải tài nguyên, Purchase, Roll, admin preview hay simulation.

Trong lượt đọc nguồn ban đầu kho preview chưa tồn tại. 18 ứng viên tên trùng tìm trong ReplicatedStorage/PlayerGui là các asset kỹ năng, chalice, NPC hoặc đạo cụ; không có ItemId vật phẩm để xác nhận là nguồn trái cầm. Không dùng MemeFakeFruits, PortalPotion hay đảo Magma/Ice thay fruit. Không tìm thêm file RBXM/RBXMX ngoài 50 file cũ trong Work Potassium.

Lượt tiếp theo khi người dùng giữ màn hình Spin: kho preview đã tồn tại nhưng không còn child; Tool Spin-Spin [PhysicalMoveset-1411] đang ở Workspace, có ItemId=1411, 6 BasePart, Idle 15123685330 và FruitAnimator. Đây là model 3D thật, khác các FruitIcon/AnimatedTile 2D trong cửa Cousin. Rescan nay cũng snapshot Tool vật phẩm đúng ItemId ở Workspace trước khi native đóng preview/phá Tool. Regression mới mất model sau cleanup trên code cũ và đạt sau sửa. Spin đã thuộc 45 file có sẵn, không tính thành model thiếu mới khôi phục. Không suy lượt Spin này đã tải toàn bộ model; không yêu cầu mua/quay thêm. Tổng lượt đọc kết thúc có 39 module source, không lỗi/truncated; bản tổng hợp đã bỏ source thô và thông tin cá nhân nằm ở data/fruit-shop-source-audit-2026-11-28.json.

Regression nhận preview thất bại trên code cũ, đạt sau sửa trong Client Play. Kiểm tra cache và UI thực cover nhận Model/Tool native đúng ID, thiếu ID, nhầm fruit/skin, từ chối clone Catalog, giữ nguồn thật, sanitation và giữ model sau cleanup. FruitModels/FruitAnimationImport cũ vẫn đạt. Không nâng số asset đã khôi phục; 35 thiếu file, Empyrean sai file và 8 idle tải lỗi vẫn chưa được giải quyết. Source/report game thô giữ private.

## Phản hồi lấy trái ra và Store, v12.22

Equipment trước đây chỉ phát trạng thái animation; UI.Store chỉ viết thanh trạng thái rồi kết thúc menu. Thêm thông báo native sau khi tạo/equip thành công Tool trái vật phẩm hoặc skin: Fruit added to backpack. Không phát khi cầm lại cùng Tool, nhặt Tool local đã tồn tại, dùng Tool thật, preview khả năng hay nạp model/sync thất bại. Store thành công phát Blox Fruit stored.; thao tác thất bại không phát thành công.

Tách phần gọi Notification.new(text):Display() đã có cho gift thành helper dùng chung, giữ nguyên điều kiện balance/applied cho gift và guard alive. Source Notification trong phiên hiện tại xác nhận Display đưa thông báo qua Controllers.UI.NotificationFeed với duration mặc định của game. Không dựng TextLabel hoặc tự chọn font/màu/tọa độ thông báo.

NativeDialogue giữ running xuyên suốt Store và trang kết quả. Ngắt listener của Tool trước khi action Store phá Tool; chỉ khi callback trả true mới mở dialogue native mới cùng title Blox Fruit, Cinematic=true, nội dung [Blox Fruit stored.] với tag AnimateYield=3 và không có cancel. Lỗi action hoặc một dialogue khác xuất hiện thì không dựng kết quả thành công hay đóng menu của người khác. UI.Store trả kết quả thật của Equipment.store cho adapter.

Hai regression thất bại trước sửa và đạt trong Client Play sau sửa: NativeDialogue kiểm tra nội dung terminal, lỗi action, chống mở chồng và quyền sở hữu; FruitFeedback kiểm tra thiếu model, sync thất bại, Equip lặp, Store thất bại/thành công và lấy ra lại. Trang Store native đã được quan sát trực tiếp trong Blox Fruits. Chưa xác nhận toàn bộ luồng Catalog mới trong game live hoặc mọi loại trái; không dùng trái thật để thử, không đổi ASSET_AUDIT/model/animation/VFX. Source/report game thô giữ private.

## Hai kiểu menu trái, v12.21

User xác nhận cả trái thật đôi lúc cũng hiện menu xám phẳng. Probe trong phiên kết nối mới thấy DialogueController đã đổi cấu trúc từ Dialogue/ReactComponents sang Builder.Dialogue và React.Components.DialogueSession. Root mới đọc nhóm thử nghiệm DialogueV1: nil hoặc Legacy bật LegacyThemeProvider, trừ khi riêng dialogue có layout.Cinematic=true. Phiên đo có isLegacyTheme()=true. Window/ContextLayer/usePageProps xác nhận layout được truyền đến chính bộ dựng UI gốc; kích thước, font, nền và icon tùy theo native theme, không phải do model trái thiếu tài nguyên.

Sửa đúng một điểm chung NativeDialogue.show: gọi dialogue:setLayout({Cinematic=true}) sau setTitle, trước build/start. Không sửa attribute nhóm thử nghiệm, không hook renderer, không sao chép hoặc tự dựng các nút. Menu NPC/trái thật không bị can thiệp. Bản game cũ đã đọc trước đó cũng có API setLayout.

Regression mới thất bại trước sửa và đạt sau sửa; các kiểm tra giữ quyền sở hữu menu, từ chối đè menu khác, Nevermind, lỗi render và đóng khi đang mở vẫn đạt. Phép thử menu native 15 giây trong Blox Fruits đã hiện icon Chat/Leave, nút đen bo góc và dải vàng Blox Fruit giống ảnh 2; không thực hiện Eat/Drop/Store. Kiểm tra build Python đạt 7 bài. Chưa kiểm tra touch/gamepad hoặc mọi phiên bản game; ASSET_AUDIT không đổi vì đây là lựa chọn theme, không thêm model/animation/VFX. Source và dữ liệu game thô giữ private.

## Khoảng hở khi Drop, v12.20

Ảnh mới cho thấy trái thật có khoảng hở dưới hình ảnh, trái script chạm sàn. Nguyên nhân là dropCollider v12.3 tính hộp từ biên BasePart nhìn thấy và bắt hộp đó chạm sàn, thay thế va chạm của Handle ngay cả khi Handle đã đúng cấu hình game.

Đo mới trong Blox Fruits: Rocket thật có Handle vô hình 2.25×2.25×2.25, CanCollide=true khi thả. Có 24 mẫu vận tốc dưới 0.05, tâm Handle cách sàn 1.10495–1.12057 studs. Trước đó Spin cũng có Handle cùng kích thước; Bomb mới ghi được Handle 2.25 nhưng không có mẫu ổn định đủ điều kiện trong báo cáo này. Mẫu khi vật phẩm đã vào tay người khác không được xem là trạng thái tiếp đất. User báo hai trái thật bị người khác nhặt; không yêu cầu thêm mẫu thật.

Yeti script hiện có Handle chuẩn 2.25; collider Catalog thêm có Size khoảng (2.991,2.219,2.120), tâm tương đối khoảng (0.039,0.218,-0.146). Hộp này ép biên nhìn thấy xuống mặt sàn. Nay Handle vô hình có Size chuẩn trong sai số 0.001 dùng trực tiếp làm va chạm, xóa collider Catalog cũ. Không thêm một hằng số nâng model hoặc vòng hover giả. Các model nhập có Handle không chuẩn vẫn dùng fallback biên mesh để tránh tái phát lỗi Handle quá lớn của v12.2.

Kiểm chứng: assertion mới thất bại trên mã cũ, sau sửa pass trong Client Play: tâm Handle ~1.125 trên sàn, hình ảnh còn khoảng hở, nhặt bằng tiếp xúc vật lý, Drop lại không tạo collider mới; fixture Handle 6 studs vẫn tiếp đất theo biên nhìn thấy, bỏ qua vật chạm ngoài nhân vật và dọn listener khi Clear. Fixture dùng Backpack thật và có Head để Humanoid:EquipTool hoạt động đúng trong Play; root có chuyển động vật lý cho phép thử Touched của Handle đang nghỉ. Equipment/EquipmentActions và 7 test Python build đạt. Chưa kiểm tra hình ảnh Yeti sau sửa trong live game; không đổi animation, model, VFX hay ASSET_AUDIT. Báo cáo thô giữ private.

## Mastery và hai slot khả năng, v12.19

Nguyên nhân: UI Visual và Equipment.equip đều yêu cầu BasePart/model. Điều này đúng cho trái vật phẩm nhưng không cần thiết cho khả năng fighting style hay permanent fruit. Thêm NativeAbilities làm đường riêng, dùng Tool local RequiresHandle=false, Enabled=false, ManualActivationOnly=true, không có script, Remote hay model. Skills ở ô 1; Permanent ở ô 2. + Add Permanent đồng thời preview, bấm lại không nhân thêm stock. Nút Equip trong Added dùng cùng đường này. Clear/Restore/đóng trả Tool thật và slot gốc; số lượng ability không bị trừ như trái vật phẩm khi đưa vào tay.

Đã đọc module live: ItemConfig, ItemReplicationService, React Inventory.ItemCard.Display/useMastery/useMoveset, PlayerGui.Backpack.LocalScriptB, Main.UIController.SetUpSkills và FruitSkills. Quan hệ Permanent → Moveset dùng Economy.PurchaseWith và bỏ SkillRedirect theo hook useMoveset gốc; không dùng icon vật phẩm permanent hay ID PhysicalMoveset để giả làm ID khả năng. Control trong phiên đo resolve ItemId 95, không phải ID 402 của dữ liệu CombatData khác.

Hotbar đọc ItemId để lấy icon. Numeric branch của native row:Drag(nil,slot) chỉ đổi row local. UIController nhận Tool vào Character, lấy FruitSkills theo StorageKey và gọi SetUpSkills. SetUpSkills cần LegacyDataAggregate; preview cung cấp chính CombatData có sẵn từ ItemReplicationService qua hook getToolData, chỉ cho các Tool proxy thuộc adapter. Không chép source Roblox vào renderer và không gọi getFruitDataAsync vì hàm đó sẽ InvokeServer. Các mục Skills không có Moveset hoặc bảng chiêu/cache gốc báo rõ unavailable; không tạo chiêu/hiệu ứng để lấp chỗ thiếu.

Mastery trong thẻ React chỉ dựng khi useMastery trả giá trị. NativeItems khởi tạo Mastery=1 nếu đang thiếu ở trái vật phẩm local; giữ giá trị đã có. Restore chỉ bỏ giá trị chính mình đã viết; cập nhật từ replication được giữ. Lỗi setter Mastery hoàn tác đúng stock trước lần Add, không xóa stock đã thêm trước đó.

Kiểm chứng: 6 suite Luau trong Edit (NativeItems, Equipment, NativeEquip, NativeShop, RobloxPrompt, Simulation); NativeAbilities chạy trên nhân vật thật của Client Play để kiểm tra Equip/đổi slot/không Handle/khôi phục. 7 test Python kiểm tra build và dependency mới trong package. Trial local có hoàn tác trong Blox Fruits: Death Step (1184), slot 1, Mastery 400, Rocket Kick/Wind Bullet/Vermillion Drill/Maximum Overheat; Permanent Control (358) → Control-Control (95), slot 2, Mastery 1, Domain Control/Slice N’ Dice/Gamma Blade/Total Concentration/Transmutation. Hai proxy held=true, RequiresHandle=false; native hotbar hiện đúng atlas icon; cleanup restored=true. Trial Mastery Dragon (West) ghi nil → 1 → nil, masteryOk=true. Không gọi đòn đánh, mua hay InventoryAction trong mã thử. Dữ liệu/source thô giữ local.

Chưa kiểm tra respawn và thao tác touch/gamepad trong game thật. Đây là preview client, không đổi fighting style hoặc fruit thật trên server, không tạo model hay VFX mới; ASSET_AUDIT giữ nguyên số liệu model.

## Bỏ nhãn checkout, v12.18

Theo yêu cầu, xóa TextLabel SimulationMode trong renderer chung để cả cửa Buy item và Purchase completed không còn dòng LOCAL SIMULATION. Không đổi tọa độ, font, icon hoặc nội dung khác của hai cửa. Thuộc tính Simulation và hướng dẫn preview trong Catalog vẫn mô tả đúng hoạt động local; không đổi giao dịch, số dư hay thông báo. Regression mới thất bại trên bản cũ; 5 suite Luau và 7 test build đạt sau sửa. Không thực hiện giao dịch thật; không cần lượt đo UI mới cho việc xóa nhãn.

## Khung hoàn tất và gạch chân điều khoản, v12.17

Ảnh 1 của người dùng là local hiện tại; ảnh 2 là mẫu completion cần đối chiếu. Khung mẫu rộng khoảng 718px, cao khoảng 371px trong ảnh đã phóng; chuẩn hóa về bề rộng dialog 456px cho chiều cao khoảng 236px. Không dùng trực tiếp kích thước pixel của ảnh phóng làm kích thước UI. Đổi completion từ 456×280 thành 456×236, slot icon circle-check 48×48 tại (204,64), nội dung 416×32 tại (20,124), OK tại y=176. Vẫn dùng glyph BuilderIcons cài cùng Roblox, không vẽ dấu tích mới. Vị trí được đối chiếu ảnh, không tuyên bố trích được cây nội dung CoreGui.

Câu xác nhận rút về `You have successfully bought Dragon.` theo tên ngắn của sản phẩm; bỏ Permanent và phần for tên người nhận ở riêng dialog này. Quote, tên/ID/recipient trong record và hai thông báo gift gốc không đổi. RichText footer đổi thành `Your payment method will be charged. Roblox <u>Terms of Use</u> apply.`: Roblox không gạch chân. Khung Buy item thường và Plus giữ bố cục v12.16, nhãn local vẫn hiện.

Kiểm chứng: thêm assertion trước khi sửa, xác nhận bản cũ lỗi ở nội dung completion và vùng gạch chân; 5 suite Luau và 7 test build đạt sau sửa. Đã xem screenshot completion và confirmation trong Studio, click OK thật đóng đúng một lần, dừng Play để dọn fixture client. Chưa kiểm tra hình ảnh bản mới trong phiên Blox Fruits của người dùng, không mua thật hay yêu cầu thêm lượt trả Robux. ASSET_AUDIT không đổi.

## Buy item và thông báo theo formatter game, v12.16

Theo yêu cầu sửa lại, trả title về Buy item và bỏ card Total riêng. Khung thường 456×264; Plus thu gọn 456×344, mở chi tiết 456×456. Total chỉ còn trong chi tiết Plus cùng Subtotal và khoản giảm. Không có khoản tiết kiệm thực tế thì không hiện accordion. Giữ tên ngắn, vị trí sản phẩm/giá, icon Roblox đã cài, nút Buy và chuyển động trước đó. Đây là renderer local, không tuyên bố đã trích nguyên dialog CoreGui.

Probe chỉ đọc trong Potassium đã ghi đủ 14 module trình bày được chỉ định. Source game xác nhận Notification → Controllers.UI.NotificationFeed → React.Components.NotificationFeed; TextLayer dùng useColorShortcuts(useTranslation(text)). Hook màu chỉ nhận Color shorthand, rồi tự escape dấu < và > còn lại. Vì vậy gửi nguyên tên có ngoặc nhọn, không escape hai lần và không tạo TextLabel thông báo riêng.

- Dòng đầu: `Sending gift <Color=Yellow><Permanent …><Color=/> to receiver...`.
- Dòng sau: `<Color=Green>Gift sent successfully!<Color=/>`.

ColorPalette gốc và formatter cho Yellow RGB(255,229,51), Green RGB(102,255,102). Đã chạy chính thân formatter đọc từ báo cáo với dependency palette thực, xác nhận kết quả RichText giữ được &lt;Permanent Control&gt; trong font vàng và dòng thành công xanh có dấu chấm than. Font Source Sans Pro SemiBold, size 32, stroke và feed tween 0.22s vẫn do game dựng. Thông báo lưu tên đầy đủ của quote đã hoàn tất; chuyển lựa chọn sang món khác không đổi nội dung cũ. Vẫn phát sau khi đóng completion theo timing v12.14; không giả nhận đó là timing server.

Kiểm chứng: 5 suite Luau đạt cho renderer, NativeShop, Simulation, NativeItems, NativeEquip; 7 test build Python đạt. Regression kiểm tra tên item đã commit khi đổi context, hai chuỗi màu chính xác, không card Total riêng, Plus không tiết kiệm, guard/hủy/Reset và không gọi callback mua gốc sau Apply. Đã xem Studio ở khung thường, Plus thu gọn và mở rộng; fixture client được dọn bằng Stop Play. Chưa xem hai dòng mới chạy trong feed Blox Fruits thực tế. Không bấm mua thật, không đóng cửa thanh toán thật hay chạy đè loader trong phiên của người dùng. Báo cáo và source game thô không đưa lên GitHub.

## Tên ngắn, giá và bố cục theo mẫu, v12.15 (lịch sử; title/Total đã thay ở v12.16)

Đọc báo cáo mới khi cửa mua thật đang mở: complete=true, 31 node PurchasePromptApp, chỉ một text node là StopPropagationOverlay với text rỗng. Đã thấy RobuxUpsellContainer nhưng chưa có nội dung dialog. Không giả nhận đã lấy được nguyên cây UI hoặc kích thước từng thành phần từ file.

Đo trực tiếp ảnh native Blade/Flame người dùng cung cấp, với tọa độ tương đối so với dialog: glyph tên bắt đầu khoảng (102,76); giá có icon khoảng (103,99), chữ số khoảng (125,102). Ảnh local cũ có tên khoảng (110,72), số khoảng (134,104). Điều chỉnh TextLabel tên từ (108,60) sang (100,64); giá từ (132,94) sang (123,92); icon từ (108,101), size 16 sang (100,97), size 18. Giữ ảnh vật phẩm 72×72 tại (20,58), tên có 336px bề rộng; gap giá gốc gạch ngang 8px. Đây là đối chiếu pixel trong ảnh, không phải đọc được label native bị ẩn.

Theo yêu cầu mới, title local dùng Buy Robux and item kể cả khi đủ số dư giả; khung xác nhận thường cũng 456×344 như mẫu, Plus mở rộng giữ 456×456. Đây là override trình bày của simulator, không tuyên bố đó là nhánh đủ Robux nguyên bản của Roblox. Native checkout trước Apply và sau Reset không đổi.

Chỉ rút tiền tố Permanent ở tên hiển thị xác nhận, không nối - Gift. ID, tên đầy đủ trong bản ghi, quote gốc, giá và các kiểm tra người nhận/session không đổi. Card Total dùng đúng cost đã quote; Plus vẫn dùng giá gốc/giảm giá/tổng từ cùng cost. Không thêm tiền tệ thật hay tự suy ra giá gói nạp 500/400, 1000/800, v.v. từ ảnh. Card Total là UI local, không phải bản trích nguyên hàng nạp tiền của CoreGui.

Kiểm chứng: 5 suite Luau, 7 test Python đạt. Fixture giữ nguyên rich text nhãn giá gốc sau khi chạy thêm case Blade/Flame. Click Studio: Blade=100, Flame giá gốc=550, Plus=495; số dư 9800 → 9700 → 9205; 2 record vẫn tên Permanent Blade/Permanent Flame; 4 thông báo sau OK; callback mua gốc 0; Reset trả lại nút gốc. Đã xem screenshot thường/Plus, dừng Play và bỏ fixture client. Cửa thanh toán Roblox standalone vẫn mở; không bấm Buy, đóng cửa hay chạy đè loader trong phiên thật. Không cần người dùng chạy mã đo mới cho lượt sửa này.

## Đo trực tiếp, icon X và màu thông báo, v12.14

Đã tự chạy `tools/InspectCheckoutLayout.client.luau` trong Potassium bằng Computer Use. Mã chỉ đọc UI và decompile các module trình bày cụ thể, không require module, kích hoạt nút hay gọi remote. Báo cáo private complete=true, viewport 1920×1017, GuiInset trên 58px. PurchasePromptApp gốc có ScreenInsets=DeviceSafeInsets; local trước đó là CoreUISafeInsets. Đổi sang DeviceSafeInsets để cùng hệ tọa độ, thay vì bù một giá trị Y cố định. Trong Studio, viewport 1452×761, inset 58, dialog Plus có AbsolutePosition=(498,150.5), Size=(456,344): cộng inset thì tâm nằm đúng giữa viewport.

Đo ảnh native/local người dùng cung cấp cho thấy vùng nền phẳng của cả hai rộng khoảng 456px. Khung native cao khoảng 344px có hàng gói nạp Robux; local không Plus cao 264px không có hàng đó. Đây là hai nhánh khác nhau: ảnh native Robux=0 hiển thị Buy Robux and item, còn local đủ số dư hiển thị Buy item. Không ép tiêu đề của nhánh nạp tiền vào nhánh đủ số dư. Buy được hạ 24px và legal footer hạ 6px theo khoảng cách trong ảnh; footer giữ nguyên câu được cung cấp. Điều chỉnh này là đối chiếu ảnh, chưa phải trích được cây nội dung CoreGui được bảo vệ.

Icon dùng font `rbxasset://LuaPackages/Packages/_Index/BuilderIcons/BuilderIcons/BuilderIcons.json`, đã tìm thấy cùng hai TTF Regular/Filled trong bản Roblox đang cài và xác nhận AssetFetchStatus.Success cho family. X dùng glyph x Regular, size 24 trong hit target 40; Robux, Roblox Plus, chevron-small-down/up và circle-check dùng cùng bộ icon. Đối chiếu [BuilderIcons Font](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/BuilderIcons/BuilderIcons/Font.luau) và [CloseAffordance](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Foundation/Foundation/Components/CloseAffordance/CloseAffordance.luau). Không require CorePackage, đổi identity, sao chép font hay tạo asset thay thế.

Module game Notification.Label xác nhận TextColor3=(1,1,1), BODY=Source Sans Pro SemiBold, TextSize=32, TextStrokeTransparency=1−0.5×alpha; bảng màu có White=(1,1,1). Giữ nguyên renderer/animation của game, chỉ truyền `<Color=White>…<Color=/>`. Hai câu theo ảnh người dùng nay chờ completion được đóng qua OK/X: đợi 0.1s để backdrop thoát rồi phát Sending gift to tên…, tiếp đến Gift sent successfully sau 0.22s (transition của feed). Đây là nhịp local có chủ đích để thông báo không bị tối/hết hạn dưới modal; không giả nhận đó là thời gian server đã đo. Hủy xác nhận, Reset hoặc đóng adapter không phát thành công muộn.

Kiểm chứng: 5 suite Luau, 7 test build Python đạt. Screenshot Studio đã xem ở cả thường/Plus/completed; click Buy thường và Plus: 1000000 → 996500 → 993350, 2 gift local, 0 callback mua gốc. Notification fixture không nhận thông báo khi completion còn mở, nhận 2 sau OK và thêm 2 sau completion X; X ở màn xác nhận không trừ thêm hoặc phát thêm. Reset trả callback gốc; fixture đã dọn. Font/package có trong client thực; vẻ ngoài notification feed sau thay đổi vẫn cần người dùng xác nhận trong game. Dữ liệu/source thô vẫn giữ private. Không cần chi Robux thật cho lượt kiểm tra này.

## Plus, thông báo và đổi fruit để gift, v12.13 (lịch sử; timing sửa ở v12.14)

- Bấm Saving… with Plus mở/thu Subtotal → Roblox Plus → Total. Đối chiếu [DiscountSummary](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Workspace/Packages/_Index/IAPExperience/IAPExperience/Generic/DiscountSummary.luau) và hook useDiscountAccordionConfig: có subscription discount và giá giảm thì dùng accordion, ban đầu thu gọn. Việc xem chi tiết không thay đổi quote hay số dư.
- Footer xác nhận dùng câu trong ảnh native do người dùng cung cấp; completion bỏ footer. Nhãn LOCAL SIMULATION chuyển lên cạnh nội dung dialog và vẫn hiện ở cả hai trạng thái. Câu legal giống ảnh không đại diện cho giao dịch thật.
- Đọc lại hai báo cáo checkout thật: không có chuỗi Sending gift / Gift sent successfully. Vì vậy hai câu này ghi nhận theo mô tả của người dùng, chưa tuyên bố là câu đã trích được từ báo cáo. API `ReplicatedStorage.Notification.new(text):Display()` đã xác minh từ source module đã lưu: trên client chỉ gọi NotificationFeed. Bản local gọi API này khi confirm và sau khi charge thành công, không gọi remote hay phát tín hiệu purchase success. GiftNotificationStatus trên Catalog cho biết Displayed/Failed/Unavailable.
- Source GiftWindow đã lưu cho thấy Cancel.Activated gọi `Close(u85.onClose)`. Close không đối số bỏ qua callback chủ sở hữu Shop, giải thích khả năng bị giữ trạng thái gift khi đổi sản phẩm. Bản mới chỉ đọc kết nối của nút **Cancel**; nếu có đúng một handler bật và đọc được thì gọi handler UI đó, giữ callback onClose của game. Không đọc hay gọi handler Purchase. Nếu runtime không hỗ trợ hoặc kết nối không rõ ràng thì giữ fallback Close cũ; chưa khẳng định fix được trên runtime không có khả năng này. GiftWindow.BloxCatalogClosePath ghi NativeCancel/ControllerFallback.
- Một lỗi riêng trong adapter: refresh trả về vô điều kiện khi Completed. Nay nếu cửa Gift gốc đã được mở lại thì dọn completion cũ và nhận lựa chọn mới. Fixture đã kiểm tra đổi Magnet → Buddha và bắt đầu gift mới mà không khởi động lại Shop.

Kiểm chứng: 5 bộ assertion Luau, 7 test build Python đạt. Click thực trong Studio: mở Plus xem chi tiết, Control → Yeti → Yeti, số dư 65500 → 61900 → 59200 → 56500, ba gift local, ba callback đóng UI và sáu thông báo đúng thứ tự; callback mua gốc giữ 0 sau Apply, Reset trả về callback gốc. Đã xem screenshot hai dialog và dọn fixture sau test. Cancel/getconnections và Notification trong lượt này là fixture UI-only, không giả nhận đó là xác nhận runtime Potassium hoặc feed live.

Các báo cáo/source game thô vẫn chỉ lưu local. Không cần mua bằng Robux thật để kiểm tra bản sửa. Native notification và khả năng đọc Cancel của Potassium cần xác nhận trong phiên thực tế.

## Bộ hiển thị local và chuyển động, v12.12

Tách `RobloxPrompt` thành module chỉ hiển thị; `NativeShop` truyền dữ liệu quote/callback và giữ toàn bộ kiểm tra session, số dư, giá và người nhận. Renderer không gọi MarketplaceService, remote, receipt hoặc CorePackages. Vẫn dùng Shop/Gift và Processing overlay gốc; hai dialog xác nhận/hoàn tất là bản local có nhãn mô phỏng. Chưa xác nhận khớp từng pixel với client Roblox đang cài.

Đã lần theo alias package trong cùng artifact commit `69b8d709dccdb25eb71fefd5b23f26b12fdb9b43`, đối chiếu các nguồn:

- [Dark theme](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/RbxDesignFoundations-31ab8d40-6.1.1/RbxDesignFoundations/Default/Dark.luau): nền Surface100 RGB 25/26/31; backdrop RGB 10/10/14, transparency 0.25; BuilderSans heading-small 25 Bold, title-medium 18 Bold, label-medium 18 Medium, body-small 15 Regular, body-medium 18 Regular; radius-large 16.
- [Otter ease](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Otter-31ab8d40-1.3.7/Otter/ease.luau): Enum Quad là p*p, tức ease-in. **Sửa nội suy Quad/Out của v12.11**; tại nửa thời gian thanh chạy 25%, không phải 75%.
- [CenterSheet](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Foundation/Foundation/Components/Sheet/CenterSheet.luau): entry 0.3s, offset 32px, StandardOut cubic Bezier (0.2,0,0,1); exit 0.1s StandardIn (0.8,0,0.4,1); backdrop fade 0.1s. Tôn trọng ReducedMotionEnabled.
- [Initial button delay](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Workspace/Packages/_Index/IAPExperience/IAPExperience/Generic/Hooks/useInitialButtonDisableDelay.luau): khóa đầu 0.3s, rồi Buy fill 2.5s theo UnifiedProductPurchaseModal. Tổng khóa xác nhận 2.8s; completion OK cũng khóa đầu 0.3s.
- [Button variants](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Foundation/Foundation/Components/Button/useButtonVariants.luau): InputSize.Medium dùng text-label-medium.
- [Unified completion](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Workspace/Packages/_Index/IAPExperience/IAPExperience/Generic/UnifiedPurchaseCompletionModal.luau): heading-small, CircleCheck 48px, body-medium và khóa đầu OK.

Chỉ chuyển các thông số cần thiết sang renderer tự viết, không phân phối lại package/source Roblox. Source artifact ngoài chưa được xác nhận cùng binary với máy người dùng. Hai khoảng Processing local 0.33s trước/sau xác nhận là nhịp xem trước chủ động, không phải độ trễ server đã đo. Không mô phỏng nạp Robux bằng tiền thật khi thiếu số dư.

Kiểm chứng: 5 bộ assertion Luau (RobloxPrompt, NativeShop, Simulation, NativeItems, NativeEquip), 7 test build Python đạt. Studio client fixture: Control giá 4000, Plus mô phỏng giảm còn 3600, số dư 975141 → 971541, chỉ một gift local; callback mua gốc không tăng sau Apply; UI Close fixture gọi một lần, Gift tắt nhưng completion còn hiển thị; OK dọn modal; Reset trả lại callback gốc. Đã kiểm tra bằng click thực trong Studio, không mua thật; fixture test đã dọn. Tích hợp controller/overlay của Blox Fruits live và thao tác gamepad/mobile vẫn cần đối chiếu trên phiên thực tế.

## Processing và thanh Buy, v12.11 (lịch sử; timing đã sửa ở v12.12)

Đọc lại báo cáo checkout thật đã lưu (SHA256 `82e75c89cc9e1c467776ae2510fbd823d88df99120724e0c3fdfa70fa214e87e`): 12 snapshot, complete=true. Processing Purchase hiện ở 22.629s; PurchasePromptApp tăng từ 7 lên 17 node nhưng vẫn chỉ có khung/cursor, không chứa cây nội dung nút Buy. GiftWindow.Enabled=false ở 45.265s; tín hiệu client hoàn tất ở 59.948s. Đây không phải video hoặc mã hoạt ảnh Buy; không thể lấy thời lượng thanh từ báo cáo này. Dữ liệu và source game thô giữ local.

Source GiftWindow đã lấy được cho thấy `Window.Overlay.Loading.ImageLabel/TextLabel`, cập nhật dấu chấm mỗi 0.33s; Close tắt ScreenGui và dọn Trove/UI overlay. V12.11 dùng trực tiếp các object này để hiển thị Processing, giữ và khôi phục thuộc tính gốc. Không gọi callback Purchase, WrapPurchase, buyRobuxShop hay tín hiệu/receipt thanh toán. Nếu không có khung native hoặc khung đang bận thì dừng, không dựng một khung game khác để thay thế.

Đối chiếu thêm artifact client công khai, cố định commit `69b8d709dccdb25eb71fefd5b23f26b12fdb9b43`:

- [UnifiedProductPurchaseModal](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Workspace/Packages/_Index/IAPExperience/IAPExperience/ProductPurchase/v3/UnifiedProductPurchaseModal.luau): inputDelay=2.5 khi bật delayed input.
- [Foundation Button](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Foundation/Foundation/Components/Button/Button.luau): tự animate lúc mount, Quad và gradient transparency theo tiến trình; không phải giữ chuột để thanh chạy. Constants của artifact cho disabled transparency=0.5.
- [Dialog variants](https://github.com/Mauio64/roblox-corescripts-decompiled/blob/69b8d709dccdb25eb71fefd5b23f26b12fdb9b43/extracontent-models/InExperience/InExperience/PatchRoot/DataModelInstances/CorePackages/Packages/_Index/Foundation/Foundation/Components/Dialog/useDialogVariants.luau): medium container=480 trước padding. Đối chiếu ảnh native mới có bề rộng khoảng 458px, nên thân dialog local đổi từ 640 xuống 456px.

Các file decompile bên ngoài là bằng chứng đối chiếu, chưa chứng minh cùng binary với bản cài trên máy. Không chép cả package Roblox hay nạp native CoreScript bằng cách đổi identity. Nội suy local dùng Quad/Out; chưa đo đường cong từng khung hình của client gốc. Hai khoảng đợi local trước/sau xác nhận dùng một chu kỳ dấu chấm 0.33s để hiện được Processing, không giả nhận đó là độ trễ server thật.

Luồng mới: Preparing → Confirm với khóa Buy 2.5s → Purchasing local → Completed. Không trừ tiền khi mở hoặc tự chạy đầy thanh. Confirm và trước khi trừ đều kiểm tra quote/session còn hợp lệ; khóa thao tác lặp. Reset/đóng Catalog hủy các phase đang chờ, không trừ muộn. Hoàn tất tắt GiftWindow và thử gọi phương thức Close của controller UI gốc để dọn lock; chỉ dùng phương thức UI đã đối chiếu, không gọi đường mua hàng. Nếu module không đọc được thì vẫn tắt ScreenGui; việc dọn lock native trong Blox Fruits live cần xác nhận. Khung success được giữ khi Gift đóng.

Kiểm tra: NativeShop assertions qua cho thứ tự Processing, tiến trình giữa chừng, khóa click trước hạn, chống sửa attribute để mua sớm, hủy/Reset/đổi quote khi đang chờ, thiếu UI, khung native đang bận, trừ một lần và success không tự mất. Simulation và 7 test Python build qua. Playtest Studio dùng bố cục Processing đo từ report, không dùng giao dịch thật: Processing xuất hiện trước dialog 0.334s; guard Buy 2.515s và có các frame trung gian. Cancel giữ 79150; Control trừ 4000 còn 75150, GiftCount=1, callback Purchase gốc giữ=1 như trước Apply; controller Close fixture được gọi đúng một lần. Sau Reset callback gốc tăng=2 khi bấm lại. Đã xem Processing, thanh đang chạy và Completed; fixture Studio đã dọn. Chưa xác nhận v12.11 trên Blox Fruits live, chưa dựng nhánh mua thêm Robux/giá tiền tệ; không sửa asset Fruit/skin.

## Gift và giao diện checkout, v12.10

Phản hồi ảnh của người dùng: chữ Visual trên nút giá và bảng Local preview dưới GiftWindow đều do Catalog thêm, không có trong UI game. Đã bỏ hai phần này; nút bản sao giữ nguyên Text/RichText của giá native, giữ lớp vẽ gốc để không che nhãn con. Giảm giá preview chỉ xuất hiện trong cửa Buy item. Catalog và footer của hai cửa local vẫn ghi mô phỏng, không giao quà.

Đối chiếu ảnh Buy item / Purchase completed đã cung cấp: dùng Builder Sans và file icon trắng `rbxasset://textures/ui/common/robux@3x.png` đã tìm trong bản Roblox cài trên máy. Chỉnh khoảng cách sản phẩm, font, hàng Plus riêng, giá gạch ngang theo bề rộng chữ, nút đóng và vòng tròn dấu tích. Giá/số dư không dùng chữ R$ thay icon nữa. Đây vẫn là UI local dựng theo ảnh; chưa xác nhận trùng từng pixel và không phải CoreGui thanh toán gốc. Attribute Version đổi sang chuỗi `12.10`.

NativeShop assertions qua cho nhãn Gift không đổi, không banner, xác nhận/hủy, chống trừ hai lần, quote cũ và cleanup; Simulation assertions và 7 test build Python qua. Playtest Studio sạch với fixture: callback nút gốc=1 trước Apply, giữ=1 khi Buy local, thành=2 sau Reset. Số dư 975141 trừ 3150 còn 971991, GiftCount=1. Đã xem cả hai cửa, xác nhận icon engine tải được và giá gốc không đè giá giảm. Chưa xác nhận trên Blox Fruits live, không thử giao dịch thật hoặc cập nhật asset Fruit/skin trong bản này.

## Checkout local hai bước, v12.9

Người dùng đã đổi yêu cầu: giữ Shop/Gift và chọn người bằng UI game, cho phép tái tạo riêng Buy item và Purchase completed ở client. Không cần thêm lượt mua thật để thu dữ liệu. V12.9 triển khai đúng phạm vi này; không tiếp tục tuyên bố dùng UI thanh toán native.

- Chưa Apply: không thay nút Purchase của game.
- Đã Apply: bản sao nút Purchase mở cửa xác nhận local, chưa trừ số dư. Buy mới gọi Inventory.buyGift; hoàn tất hiện cửa success local và OK. Cả hai cửa ghi SIMULATION / Local only, không chi Robux hay giao quà.
- X/Escape/B hủy không trừ số dư. Quote bị vô hiệu khi đổi người, giá, số dư, lần Apply/Reset hoặc giảm giá. Chặn xác nhận lặp. Đóng GiftWindow dọn cửa xác nhận nhưng vẫn che nút mua thật khi Apply còn bật, để mở lại không trở về luồng thật. Reset, tắt Balance hoặc đóng Catalog mới khôi phục các thuộc tính nút gốc.
- Phạm vi vẫn là Permanent khớp Catalog và giá native đọc được. Không gọi WrapPurchase, MarketplaceService, remote gift, không phát receipt hoặc tín hiệu hoàn tất giả.

Kiểm tra: NativeShop assertions qua cho xác nhận/hủy, trừ một lần, success, quote cũ, thiếu tiền, loại chưa hỗ trợ, Reset, disable và cleanup. Simulation assertions và 7 test Python build qua. Playtest Client trong Studio với fixture đúng đường dẫn native dùng click thật: callback gốc=1 trước Apply, giữ nguyên=1 trong checkout local, thành=2 sau Reset. Hủy giữ 975141; Buy Buddha giảm 10% trừ 1485 còn 973656, GiftCount=1. Đã xem ảnh cả hai cửa. Lượt bấm tự động theo batch ban đầu tìm nút mới trước khi UI tạo xong; chạy lại tuần tự có chờ UI qua. Chưa chạy v12.9 trong Blox Fruits live hoặc xác minh thao tác phone/gamepad. Không thay asset Fruit/skin trong bản này; số liệu ASSET_AUDIT giữ nguyên.

## Visual Robux / Shop Gifts, v12.8

### Lịch sử điều tra checkout gốc sau v12.8, trước khi cho phép UI local

Yêu cầu đã được làm rõ: chỉ mô phỏng số dư/giảm giá và kết quả local, không chi Robux hay gửi quà thật; vẫn phải dùng UI gốc và đủ các bước Processing Purchase → Buy item → Purchase completed → OK. Người dùng không đồng ý tái tạo cửa xác nhận từ ảnh. V12.8 chưa có luồng này, vẫn chỉ ghi local gift và trừ số dư preview.

Đã chạy các lượt đọc trực tiếp qua Potassium, không bấm Buy hay gọi giao dịch:

- Báo cáo gift-checkout v1 bị giới hạn scan trước module chính. Lượt v2 ưu tiên module đã load và Controllers, đọc được Controllers.UI.GiftWindow, Modules.Asset.WrapPurchase, Notification và React.Components.ConfirmationDialog.Controller.
- GiftWindow gốc hiện Processing Purchase, sau đó gọi WrapPurchase; nhánh Gift trong wrapper chuyển tiếp sang luồng server buyRobuxShop. Hoàn tất thật đóng cửa qua tín hiệu MarketplaceService hoặc RobuxPurchaseSuccess. Các đường giao dịch/tín hiệu này chưa được gọi, giả lập hoặc thay thế.
- PurchasePromptApp tồn tại. Khi người dùng mở Buy Robux and item và giữ nguyên, bản đọc UI ghi được RobuxUpsellContainer cùng khung; không ghi được nội dung sản phẩm/nút Buy của cửa thanh toán đó. Bản sao unparented không đủ làm checkout tương tác. Không suy ra nhánh Buy item/Purchase completed đã được capture từ kết quả này.
- Lượt checkout-modules tìm thấy 1112 module có tên/path liên quan purchase/robux. Tám module được thử decompile chỉ trả chuỗi `-- Empty bytecode`; không coi đó là mã nguồn có thể sử dụng.
- Lượt checkout-test-api đọc các export của Test.MockStore, Test.MockNetwork, Test.UnitTestContainer, Components.ProductPurchase.ProductPurchasePrompt và Components.PurchasePromptApp. Cả năm đều tồn tại nhưng require trả `Cannot require a RobloxScript module from a non RobloxScript context`. Không đổi identity, không sửa CoreScript hay bật cờ mock toàn cục để vượt lỗi này.

Kết luận hiện tại: đã xác nhận luồng và module gốc, nhưng chưa có cách đã kiểm chứng để render checkout gốc trong ngữ cảnh mô phỏng độc lập của Catalog. Chưa tích hợp native confirmation/success, chưa phát hành client thay thế v12.8. Các probe mới chỉ phục vụ chẩn đoán, raw report và source game giữ local.

Thay trình sửa Beli/Fragments bằng số dư Visual Robux, Apply, giảm giá hiển thị 10% và Reset. Dữ liệu UI được ghi trong báo cáo shop-gift-ui, complete=true, 14 snapshot. Các đường dẫn đã thấy: PlayerGui.GiftWindow.Window.Footer.Context và Window.Content.Buttons.Purchase.TextLabel. Native context có dạng Gifting [username] <Permanent Magnet}> với dấu } thừa; adapter chỉ khớp tên permanent có trong Catalog và giá đang hiển thị, không đoán giá khi thiếu.

Khi Apply bật, NativeShop ẩn/vô hiệu hóa nút Purchase gốc và dùng một bản sao UI đã gỡ script, remote và tag. Callback của bản sao chỉ gọi Inventory.buyGift để ghi lịch sử và trừ số dư mô phỏng. Chưa chọn người nhận, tên sản phẩm chưa hỗ trợ hoặc giá không đọc được đều không mua trong chế độ này. Các tab Server/Global và tìm người vẫn là UI của game. Không gọi API mua hàng hay remote gift.

Reset, tắt tiện ích Balance hoặc đóng Catalog trả lại trạng thái Visible/Interactable/Selectable của nút gốc và gỡ bản sao. Nhãn trạng thái đặt dưới Footer.Context để không tham gia layout của Window. Test NativeShop và Simulation qua; test luồng Equip hiện có qua; 7 test build Python qua. Playtest Client trong Studio đã bấm Apply, bật giảm giá, bấm Gift giả lập Buddha: 758796 trừ 1485 còn 757311, GiftCount=1, bộ đếm callback Purchase gốc=0; Reset về trạng thái chưa Apply và cleanup qua. Ảnh màn Balance đã được kiểm tra. Chưa xác nhận phiên bản mới trong Blox Fruits đang mở của người dùng.

Đây là mô phỏng local, không cấp quyền Plus, không trao permanent hay gửi quà thật. Phạm vi sản phẩm hiện tại là permanent fruit khớp database; Global search tận dụng giao diện native, chưa có lượt chọn một tài khoản ngoài server trong playtest.

## Equip từ kho game, v12.7

Người dùng xác nhận Equip trên panel được nhưng nhiều trái bấm Equip trong kho game không được; Shadow vẫn dùng được. Ảnh có lỗi Local model load failed: GetObjects is not a valid member of DataModel. NativeItems gọi onEquip ngay trong Future của callback game; FruitModels.load tra GetObjects tại đó, còn mẫu đã có trong cache không cần gọi API này. Đây là đường lỗi được sửa, chưa phải bằng chứng tất cả nút kho đã hoạt động trên máy người dùng.

NativeItems chuyển yêu cầu Equip mô phỏng sang worker được tạo từ script Catalog và chờ kết quả Future<Result>. Giữ nguyên đường game cho kho thật và bản có NetworkedUID. Hàng đợi giới hạn 16 yêu cầu; lỗi callback vẫn được trả về, đóng Catalog giải phóng các yêu cầu đang đợi. Test bắt được bản cũ chạy importer trong cùng coroutine với callback và kiểm tra bản sửa chạy ở worker; chưa kiểm chứng lại quyền API trong phiên game thật sau sửa.

## Đo riêng Fruit và Fruit Skins ngày 27/11/2026

Báo cáo blox-catalog-fruit-skin-audit-100117331123089.json, GameId 994732206, complete=true, processed=134, thời gian 87.8 giây. Có 47 thẻ Fruits và 87 thẻ Fruit Skins; 53 thẻ chỉ có metadata, không tính là thiếu model vật phẩm.

Trong 81 trái vật phẩm: 40 fruit và 5 skin nạp được model; thiếu 7 fruit và 28 skin; Empyrean bị chặn vì nguồn là Galaxy. Các mẫu nạp từ file, không có Tool thật được capture trong lượt này. 35 rig đổi pose trên bản sao riêng; 8 rig lỗi tải clip; Diamond và Ice không có idle animation trong nguồn. Đây không phải phép thử cầm/hotbar hay đối chiếu hình ảnh của toàn bộ trái thật.

| Mục | ItemId | Clip trong file | Kết quả mới |
|---|---|---|---|
| Dragon | 1447 | 89485756852231 | Preload Failure, không có khớp chuyển động được đo |
| Dragon (West) | 884 | 89485756852231 | Preload Failure, không có khớp chuyển động được đo |
| Flame | 1394 | 92872930988510 | Preload Failure, không có khớp chuyển động được đo |
| Lightning | 1427 | 74759006007335 | Preload Failure, không có khớp chuyển động được đo |
| Quake | 1389 | 87225712156404 | Preload Failure, không có khớp chuyển động được đo |
| Tiger | 1430 | 119940442528522 | Preload Failure, đã có mẫu mới trong lượt này |
| Ember | 1047 | 96038340477884 | Preload Failure, không có khớp chuyển động được đo |
| Werewolf (Tiger) | 814 | 133333989918142 | Preload Failure, không có khớp chuyển động được đo |

Tham chiếu render duy nhất báo tải lỗi trong lượt này là VFX texture Buddha rbxassetid://6960307279. Các VFX được kiểm kê theo cấu hình nguồn trước khi bị tắt trên bản sao ẩn để đo chuyển động; chưa xác nhận hình ảnh chạy đúng game. Control đổi pose nhưng phản hồi model cũ vẫn chưa được giải quyết. Không thay ID animation hay tạo VFX thay thế từ số đo này.

## Nhận diện file trước lần Equip đầu, v12.6

Meme và nhiều trái khác có file local nhưng thẻ v12.5 vẫn báo No model vì sourceFor chỉ trả model đã nằm trong cache. Bước thực sự nạp file nằm trong luồng Equip. Bỏ kiểm tra đường dẫn mà chưa thay bằng trạng thái file chưa nạp đã gây ra lỗi này.

FruitModels.available hiện nhận diện cả file local chưa nạp. Lỗi nhập file được lưu theo ItemId và đường dẫn để file đã bị từ chối không báo khả dụng. Rescan cho thử lại file đã sửa. Nạp thành công hoặc capture một mẫu native hợp lệ xóa lỗi trước đó. Equip cập nhật lại thẻ sau kết quả tải.

tools/AuditFruitAndSkins.client.luau kiểm tra cả Fruits và Fruit Skins, dùng đúng 81 ItemId vật phẩm cùng các mục metadata của hai tab. Báo cáo có tên blox-catalog-fruit-skin-audit-PLACEID.json. Lượt đo mới đã hoàn thành, tóm tắt ở trên; các phần lịch sử bên dưới giữ ngày đo cũ.

## Phân loại bổ sung ngày 27/11/2026, v12.5

Người dùng xác nhận thêm bốn skin mặc định của biến thể. Quan hệ được lưu rõ trong data/fruit-variant-relations.json và được kiểm tra tên, ItemId cùng fruit gốc khi build. Empyrean (1041) thuộc Kitsune (1423), Fiend (Yeti) (1060) thuộc Yeti (1424), Hellfire (Gas) (1601) thuộc Gas (1422), Werewolf (Tiger) (814) thuộc Tiger (1430). IsDefault vẫn được giữ đúng dữ liệu gốc để mô tả diện mạo mặc định trong biến thể.

Hiện có 47 mục Fruits và 34 trái vật phẩm trong Fruit Skins. Fruit gốc thiếu 7 file, skin thiếu 28 file. Empyrean còn có file sai model. Các lỗi preload và VFX ở cả hai nhóm chưa được giải quyết bằng việc phân loại.

Thẻ có file nhưng bị trình nạp từ chối sẽ không còn tô xanh và hiện Equip chỉ vì đường dẫn tồn tại. UI dùng model nạp được hoặc Tool thực tế để xác định khả năng Equip. Trường hợp Empyrean vẫn giữ thông báo nguồn Galaxy bị gán nhầm.

Các kiểm kê và phép đo v12/v12.4 bên dưới là bằng chứng tại thời điểm đó, không phải số lượng thẻ mới.

## Phân loại ngày 27/11/2026, v12.4

Lỗi trước đây là dùng PhysicalMoveset làm điều kiện đưa tất cả trái vật phẩm vào Fruits. Các skin như Arcsteel và Galaxy cũng có bản vật phẩm PhysicalMoveset riêng. Điều đó làm tab Fruits lẫn skin, đồng thời tab Fruit Skins hiển thị thêm định nghĩa skin mặc định như Magnet.

Bản mới dùng quan hệ Skin.Physical cùng Skin.IsDefault. Có 30 trái vật phẩm mang skin được chuyển sang Fruit Skins. Những định nghĩa Skin đã được thể hiện bằng thẻ vật phẩm được ẩn khỏi kết quả tìm kiếm, nhưng ID gốc vẫn còn trong Catalog.byId. Tìm theo skinId cũng ra được thẻ vật phẩm tương ứng. Add/Equip/menu/Drop và nạp model dùng cờ isPhysicalFruit, nên vẫn hoạt động khi mục nằm ở Fruit Skins.

51 fruit gốc còn 9 mục thiếu file. 30 trái mang skin có 26 mục thiếu file. Arcsteel, Galaxy, Ember và Starlight Gravity là bốn mục skin có file đã tìm thấy. Chuyển tab không bổ sung các file còn thiếu và chưa sửa được lỗi tải animation. Thống kê 81 mục bên dưới là nhóm trái vật phẩm của bản cũ, bao gồm cả skin.

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
