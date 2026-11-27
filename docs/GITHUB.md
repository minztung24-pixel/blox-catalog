# Blox Catalog

Modular Luau catalog and local inventory simulator. This repository is separate from `virus-visualizer-loader`.

## Run the latest client

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Open Items in Blox Fruits, press Rescan, and wait for `Items linked locally`. Add a fruit, open Added, and press Equip. A fruit with a model becomes a local Tool; the game's own hotbar displays it. There is no separate catalog hotbar. Right Shift hides/shows the catalog panel; Tools enables/disables utilities.

The client, inventory entries, Visual Robux balance and gifts are local simulations. They do not grant server items, combat abilities, Robux products or permanent ownership. Icon/ID data does not contain 3D models; missing models are reported without consuming local stock.

## v12.24 Automatically capture native fruit sources arriving later

Previously, native templates arriving after startup were missed until Rescan. The Catalog now passively watches physical fruit/skin Tools in the local Backpack, current Character and Workspace, plus Tool/Model templates in the native preview holder. Exact ItemId remains required; Catalog clones, unrelated IDs and other characters' Tools are ignored. Late ItemIds and added descendants refresh the sanitized snapshot and availability cards without consuming inventory or initiating a resource request, purchase or roll.

Captures and UI notifications are coalesced. Captured genuine Tools retain priority over other holder previews. Closing the Catalog disconnects global/source listeners and prevents queued callbacks from doing work; native objects are left intact. Watchers are bounded to 256 active sources and retain the existing 3000-descendant import limit. Per-frame changes to every FX property are not mirrored.

The late-arrival UI regression fails on v12.23 and passes after the fix. Client Play checks cover streamed structure, late ItemIds/animation/FX, exact base/skin identity, sanitation, priority, retained snapshots and cleanup, while existing model/import assertions still pass. This fixes discovery timing; coverage remains **45 loaded local files, 35 missing files and one mismatched Empyrean file**. Dragon's unavailable idle data and the other previously measured clip failures remain unresolved.

## Additional verification on v12.23: known-good controls and Dragon

Compared Yeti, Shadow and Dark with eight affected fruits/skins using three playback paths in the original game: Catalog preload, immediate Animator playback and immediate AnimationController playback. All nine control cases changed pose; all eight affected items failed preload and both direct paths remained at zero loaded clip length within seven seconds. Changing playback API alone did not restore Dragon or the other affected clips in this session. This does not establish whether permissions, stale IDs or asset delivery caused the missing clip data.

Rechecked all 50 local files against sanitized clones: zero errors or differences in the measured render/rig/FX properties. 496/497 render references loaded; Buddha's existing particle-texture failure remains. Dark has no ParticleEmitter/Beam/Trail in its file despite the user's accepted appearance, so zero emitter count is not treated as an automatic defect. The production animation logic and model coverage are unchanged; the sanitized results and limits are in `data/fruit-reference-check-2026-11-28.json`. Raw game reports stay private.

## v12.23 Recognize native fruit preview templates

Rescan now checks `PlayerGui.__ReplicatedSpinnerInstances` before the older model roots and snapshots native physical Tools in Workspace before preview cleanup. Physical fruit/skin templates need an exact ItemId, pass the existing sanitizer, retain authored animation/FX data and remain cached after their source disappears. Captured held Tools take priority over holder templates; names and icons cannot substitute a base fruit for a skin.

The connected Shop/Dealer/Gacha audit read 258 relevant configs and 39 modules, distinguishing image metadata, server purchase/switch calls and separately replicated preview templates. It initiates no purchases, rolls, resource requests or developer simulation. The initial preview holder was absent; during the user's native Spin display it existed empty while the actual Spin Tool was in Workspace. Spin was already covered by an existing model file. This is a source-recognition fix, not a claim that missing assets were recovered.

Coverage stays at **45 loaded files, 35 missing files and one mismatched Empyrean file** across 81 physical fruits/skins. Eight previously failed idle clips remain unresolved. Client Play regressions cover exact identity, sanitation, source cleanup, held-Tool priority and actual Catalog availability cards; existing model/animation-import checks pass. See `docs/DIAG.md` and `docs/ASSET_AUDIT.md` for scope and evidence. Raw game reports/source remain private.

## v12.22 Native take-out and Store feedback

Taking a local physical fruit or fruit skin out of inventory now calls the game's Notification API with **Fruit added to backpack.** Re-equipping an existing local Tool does not repeat the take-out notice. A successful Store calls the same API with **Blox Fruit stored.** and opens a native cinematic result page containing **[Blox Fruit stored.]** beneath the Blox Fruit title. These messages follow successful local inventory changes; failed model loads or inventory syncs cannot announce success.

The result page keeps menu ownership until it closes, and Tool listeners are disconnected before Store destroys the Tool. Another active game dialogue is never replaced. Notification rendering is shared with the existing gift notices while preserving their applied-balance guard. Fonts, colors, positions, animation and default notification duration come from the live game's modules.

Validation: the two new behavior checks fail before the change and pass in Client Play. They cover repeated take-out, failed Equip/Store, Store followed by another take-out, terminal native result content, action errors, re-entry and foreign-dialogue ownership. The native Store result page was visually checked in Blox Fruits, and the current Notification source was inspected. The complete Catalog flow still needs the user's live confirmation; no real fruits were dropped or stored for testing. Model/VFX availability is unchanged.

## v12.21 Consistent native fruit dialogue

The fruit menu now explicitly selects the game's cinematic layout. The current native controller otherwise selects a legacy theme when the account's `DialogueV1` test group is absent or `Legacy`, explaining the plain gray menu seen on both real and local fruit. The per-dialogue `Cinematic=true` flag selects the native speech-bubble buttons and gold title treatment without changing the account's test-group attribute or replacing the game's UI.

Validation: the regression fails without the layout flag and passes with it; existing ownership, cancellation, error cleanup and delayed-action assertions still pass. A temporary native menu in the connected Blox Fruits session visibly showed the requested icons, rounded options and gold title, then closed automatically without Eat/Drop/Store actions. Seven Python build tests pass. The renderer is supplied by the live game; future native UI changes may require another check. Real-fruit menus and other NPC dialogues keep their original behavior.

## v12.20 Preserve native dropped-fruit clearance

Physical fruits with the game's invisible **2.25×2.25×2.25 Handle** now collide using that Handle. The previous visible-mesh collider forced the fruit's visible bottom onto the floor and removed the native clearance. An inherited Catalog collider is removed for these canonical Handles; imported models with oversized/noncanonical Handles retain the prior bounded-mesh fallback. No arbitrary hover offset or replacement animation is added.

The live Rocket drop yielded 24 settled observations: Handle center 1.105–1.121 studs above the floor, matching a 2.25-stud collision box. Yeti's existing Handle is already 2.25 studs; its extra Catalog collider was the mismatch. Bomb's Handle was also observed at that size, but samples after another player picked up a fruit are excluded from settled-ground measurements. No further real-fruit drops are needed.

Validation: the new native-clearance assertion fails on v12.19 and passes after the change. Studio physics checks cover native clearance, contact pickup, repeated Drop without recreating a collider, the oversized-Handle fallback, foreign-contact rejection and cleanup. Equipment/action assertions and seven Python build tests pass. The new Yeti Drop appearance still needs the user's visual confirmation; no native model/VFX assets were added.

## v12.19 Native Mastery and ability slots without models

**Visual → Skills → Equip** now previews a native fighting style in hotbar **slot 1** without requiring a 3D model. **Inventory → Permanent → + Add** equips the corresponding fruit ability in **slot 2**; selecting another permanent replaces that ability. Added → Equip also supports these previews. These are separate from physical fruit Tools and their model/VFX pipeline.

The native ItemConfig relation resolves the actual Moveset ID, name and icon; the game's cached FruitSkills and CombatData supply the skill list. A handle-free, non-activating local Tool lets the existing hotbar and SetUpSkills build their own UI. The adapter uses the native hotbar's numeric Drag branch and a narrowly scoped skill-data hook for its own proxies only; it does not copy a different fruit's skill data. Real Tools are temporarily held outside the Backpack and restored with their previous slots on Clear, Restore visuals or close. Missing native moveset/skill data produces an explicit error; admin/utility records without a native fighting-style/fruit skill list are not fabricated.

Added physical fruits now initialize missing local Mastery to 1 so the native inventory card can show **1 Mastery**. Existing mastery is preserved; Clear restores missing baselines and keeps newer replicated values. Mastery write failures roll back the attempted quantity update. Ability previews keep their local inventory quantity rather than consuming a physical copy.

Validation: six Luau suites pass in Studio Edit, the ability suite passes in Client Play, and seven Python build tests pass. A reversible Blox Fruits trial confirmed Death Step in slot 1 with Mastery 400 and four native skills, then Control in slot 2 with Mastery 1 and its five current native skills; the game's own hotbar supplied both icons. Original Tools and hooks were restored. A separate cache trial confirmed a missing physical-fruit Mastery changed nil → 1 → nil on cleanup. No attacks, purchases or item transaction actions were invoked by the trial. Reports and decompiled game source remain private. Respawn and gamepad/touch behavior have not been playtested in the live game.

## v12.18 Remove the checkout caption

Removed the **LOCAL SIMULATION** caption from both confirmation and completion. Their geometry, contents, behavior and local-only transaction logic are unchanged. Catalog still describes the preview behavior. Renderer regression assertions cover both dialogs; all five Luau suites and seven build tests pass.

## v12.17 Compact completion and legal-link underline (caption removed in v12.18)

Completion now reads **You have successfully bought Dragon.** (using the selected short product name), without the permanent prefix or recipient. Gift records and native gift notices still retain the full product and recipient. The reference image's aspect ratio gives a 456×236 completion, replacing 456×280; the installed Roblox circle-check glyph is centered in its 48px slot at (204,64), the result is at (20,124) in a 416×32 area, and OK starts at y=176. The visible local marker remains.

The confirmation footer now underlines **Terms of Use** only; **Roblox** is plain text, matching the supplied native screenshot. Ordinary confirmation and Plus layout/behavior are unchanged.

Validation: regression assertions failed against v12.16 and pass after the changes; all five Luau suites and seven build tests pass. Studio screenshots checked completion and confirmation, and a real Studio OK click dismissed completion once. Geometry is derived from the supplied scaled reference image, not a native CoreGui extraction; exact live-game appearance still needs confirmation. No real transaction was used.

## v12.16 Buy item and native gift notification formatting

Affordable visual checkout uses **Buy item** again. The standalone Total card is removed; the regular dialog is 456×264. Short product names, the existing Buy animation and the reference product positions remain. Plus retains its savings accordion, 456×344 collapsed and 456×456 expanded, with Subtotal / reduction / Total inside the expanded details only. Quotes with no actual saving do not show the accordion.

Both gift messages use the game's own `Notification.new(text):Display()` feed. The first is **Sending gift <Permanent …> to receiver...**, with the full committed product name in yellow; the second is **Gift sent successfully!**, in green. The live game's color-shortcut formatter was inspected and tested: it renders the literal angle brackets around the product correctly, yellow RGB(255,229,51), green RGB(102,255,102). The native font, stroke, placement and animation are unchanged. Switching the selected product cannot change an already completed gift's message.

Validation: five Luau suites and seven Python build tests pass. Studio visual checks covered regular and collapsed/expanded Plus layouts. The native text formatter was tested separately with the exact strings. No paid transaction was performed; the actual notification feed after this change still needs visual confirmation in the user's session. The checkout dialogs remain local recreations with a visible local marker, not imported native CoreGui. Raw game reports and source stay private.

## v12.15 Short product names and reference-sized confirmation (superseded heading and Total card)

The local confirmation now uses the requested **Buy Robux and item** heading and short product names such as **Blade** and **Flame**. This is presentation text after Apply; it does not open a real Robux upsell or change the original checkout before Apply. The recorded gift still keeps its permanent item name and ID.

The confirmation footprint is 456×344 with or without Plus. Image measurements place the product name at (100,64), the price at (123,92) and the price icon at (100,97), relative to the dialog. The original-price gap is reduced to 8px. The existing Buy control, input delay, completion and native notification behavior remain in use.

Without Plus, the outlined price area displays **Total** and the actual quoted Robux charge. With Plus, the existing savings accordion shows the discount breakdown. These are local price presentations; the real-currency bundle row in the native screenshots has not been extracted, and no bundle quantities or cash prices are invented.

Validation: five Luau suites and seven Python build tests pass. Studio screenshots/clicks checked Blade at 100, then Flame at a native quote of 550 with the visual Plus cost of 495: 9800 → 9700 → 9205. Records retain Permanent Blade / Permanent Flame, four completion notices arrive after acknowledgement, no original purchase callback runs after Apply, and Reset restores the original button. The user's standalone Roblox purchase window was left open; no real purchase was made or new loader executed there. Native inner-dialog measurements still come from the supplied screenshots, not an extracted CoreGui tree.

## v12.14 Installed Roblox icons, screen alignment and visible gift notices (previous heading and footprint)

A read-only snapshot from the running client confirmed that native PurchasePromptApp uses **DeviceSafeInsets**. The local dialogs now use the same coordinate space, removing the top-bar centering offset. Both reference dialogs measured approximately 456px wide; their different heights also reflect different branches: **Buy Robux and item** includes a Robux bundle when real funds are insufficient, while **Buy item** confirms an affordable item. Enough visual funds retain Buy item; insufficient visual funds remain blocked rather than opening a real-currency upsell.

X, Robux, Plus, the accordion chevrons and the completion check now use the installed **BuilderIcons** font used by Roblox Foundation. The package and font family were located in the installed client and the icon rendering was checked in Studio. No copied bitmap, ordinary multiplication sign or unsupported chevron character is used. Buy and legal-footer spacing follow the supplied native reference more closely; the explicit local marker remains visible.

The two gift messages wait until completion is dismissed with OK/X, so they do not expire or appear dimmed behind the checkout backdrop. After the 0.1s exit, the game's own notification feed receives **Sending gift to …** and then **Gift sent successfully**, separated by its 0.22s transition interval. The verified game White markup preserves white text; its native Source Sans Pro SemiBold, 32px text and dark stroke remain untouched. This is local presentation after a simulated charge, not a server gift.

Validation: five Luau suites and seven Python build tests pass. Studio screenshots checked regular, Plus and completion layouts, icon rendering and screen centering. Clicks verified 1000000 → 996500 → 993350, no notices underneath completion, two notices after OK and another two after completion X. Cancelling confirmation with X neither charged nor emitted gift notices. The original purchase callback remained unused after Apply, and Reset restored it. Test fixtures were removed. See [DIAG](docs/DIAG.md) for live measurements and remaining limits; this is not a claim of a pixel-perfect native CoreGui renderer.

## v12.13 Plus details, native notification feed and consecutive gifts (previous timing)

Click **Saving… with Plus** to expand/collapse Subtotal, the Plus reduction and Total. The layout follows the pinned Roblox `DiscountSummary` component. Opening details never changes the quote, discount or balance. The confirmation footer follows the wording in the supplied native screenshot; completion has no footer. A compact **LOCAL SIMULATION** marker remains beside the dialog content, so the reference legal wording does not mean that a real payment happens.

Local confirmation emits “Sending gift to …” and successful local charging emits “Gift sent successfully” through the game's UI-only `Notification.new(...):Display()` API. These two message strings are based on the user's observation: the saved real checkout reports did not capture them. Missing native notification support is recorded in the Catalog `GiftNotificationStatus` attribute; no replacement notification UI or server event is generated.

The native Cancel handler calls `Close(onClose)`, while the previous adapter called only `Close()`. Where the runtime exposes exactly one enabled readable Cancel handler, the adapter invokes that UI-only handler to release the Shop owner's close callback. It never reads or invokes Purchase handlers. `GiftWindow.BloxCatalogClosePath` records `NativeCancel` or `ControllerFallback`. Runtimes without readable Cancel connections retain the controller fallback and may still require reopening Shop. Opening another native Gift also clears an old local completion rather than leaving the adapter stuck in Completed.

Validation: five Luau suites and seven Python build tests pass. Studio clicks checked the expanded Plus breakdown and both dialog layouts. With a UI-only Cancel/Notification fixture, Control → Yeti → Yeti completed without reopening Shop: 65500 → 61900 → 59200 → 56500, three local records, three close callbacks and six ordered notifications. The original purchase callback stayed at zero after Apply; Reset restored it. Test objects were removed. The live executor's Cancel access and native notification appearance still need confirmation in the user's session. No paid test is required.

## v12.12 Shared local prompt and source-based motion (previous layout)

The presentation now lives in `RobloxPrompt`, separate from the Blox Fruits adapter and local inventory. Both confirmation and completion use one renderer. Reference theme values update Builder Sans sizes, colors, backdrop, corners and the success check. The medium button uses an 18px label; the original price uses 15px body text.

The previous Quad/Out approximation is corrected: there is a 0.3-second initial input lock, followed by a 2.5-second **Quad ease-in** Buy fill. Entry uses 0.3-second StandardOut motion from 32px below; exit uses 0.1-second StandardIn. Backdrop fade takes 0.1 seconds. Reduced-motion settings remove the transitions while preserving the input locks. Filling never submits a purchase. Completion has its own 0.3-second initial OK lock.

These values come from pinned, decompiled Roblox component/theme artifacts, not an imported CoreGui or proof of the installed client's exact build. The native Shop/Gift selection and Processing overlay remain in use; the two financial dialogs remain local recreations with an explicit simulation footer. No real Robux, purchase handler or receipt is used after Apply. Reset restores the original button. Insufficient fake balance is blocked; a real-currency Robux upsell is not simulated.

Validation: five Luau suites (RobloxPrompt, NativeShop, Simulation, NativeItems and NativeEquip) and seven Python build tests pass. Studio clicks checked native processing, the delayed confirmation guard, the visual Plus discount and a single charge: 975141 minus 3600 for Control leaves 971541. The original purchase callback stayed unchanged after Apply, the UI-only Close fixture ran once, OK cleaned up, and Reset restored the original callback. Test-only Studio objects were removed. See [DIAG](docs/DIAG.md) for reference links and remaining live-game limits.

## v12.11 Processing, delayed Buy and completion flow (previous timing)

After Apply, the flow is now **Gift → the existing game Processing Purchase overlay → Buy input-delay fill → local processing → Gift closes → local completion**. The adapter uses `GiftWindow.Window.Overlay.Loading` directly, preserves its icon/caption/visibility, and restores them on cancel or cleanup. Missing or already busy native processing UI is reported instead of creating a replacement. No game purchase handler is called.

The Buy button fills automatically and rejects input for 2.5 seconds. Clicking early does nothing; filling alone never spends. Confirmation enters a pending local phase and revalidates the recipient, price and balance before charging once. Reset/close during preparation or pending processing cancels the charge. Completion disables GiftWindow and, when its game UI module is readable, calls its UI-only Close method to release the native overlay state. The completion dialog remains until OK.

The confirmation width is reduced from 640 to 456 pixels, matching the medium-sheet body and new screenshots more closely. The Buy-delay mechanism is based on pinned, decompiled Roblox client component artifacts; they have not been identified as the exact binary build installed on the user's computer. See [DIAG](docs/DIAG.md) for sources and limits. The two financial dialogs remain local recreations with simulation labels. Insufficient fake funds still block checkout; no real Robux upsell or payment is initiated.

Validation: NativeShop/Simulation assertions and seven Python build tests pass. A Studio client fixture used the recorded native processing layout and a UI-only Close controller. Processing appeared 0.334 seconds before confirmation; the Buy guard lasted 2.515 seconds with intermediate frames captured. Cancel preserved 79150; confirming Control charged 4000 once to 75150, called the fixture's UI Close once, and never called its original purchase handler. OK and Reset passed. Test-only Studio objects were removed. Live Blox Fruits integration still needs confirmation; no real purchase was performed.

## v12.10 Gift appearance and checkout styling (previous flow)

The native Gift price label is copied verbatim, including its icon and rich text. The added “Visual” suffix and the banner below GiftWindow are removed. The visual discount is shown only in checkout. Simulation remains explicit in Catalog and the local confirmation/completion dialogs.

The two local dialogs now use the installed Roblox Builder Sans font and built-in white Robux icon. Product spacing, the separate Plus savings row, strike-through price, close control, centered success text and outlined check circle follow the supplied reference images more closely. This is a local recreation, not an exact native checkout or a verified pixel-for-pixel match. The Version attribute is now the string `12.10` so dotted version numbers retain their meaning.

Validation: NativeShop and Simulation assertions and seven Python build tests pass. A fresh Studio playtest checked the unchanged Gift label, no extra banner, price spacing, real built-in icon loading and the local charge: 975141 minus 3150 leaves 971991, with one local record and no original purchase callback. OK and Reset restore the native callback. Both local screens were visually inspected. Live Blox Fruits and mobile/gamepad behavior still need confirmation.

## v12.9 Local checkout confirmation (previous styling)

Before Apply, the original Shop/Gift purchase button remains unchanged. After Apply, keep using the game's Permanent Fruit Shop → Gift and Server/Global recipient selection. Its purchase button opens a local **Buy item** confirmation with the selected product, recipient, fake balance and optional visual discount. Only pressing **Buy** deducts that balance and records a local gift; **Purchase completed → OK** confirms the simulation. Both dialogs explicitly identify local simulation and no delivery.

Closing confirmation with X, Escape or gamepad B does not charge. Repeated Buy clicks cannot charge twice. Changing the recipient, quote, balance session or discount invalidates confirmation. Reset, disabling Balance or closing the Catalog removes the simulated controls and restores the original purchase button. With preview disabled, purchases use the game's real flow and real Robux again.

The adapter supports permanent-fruit names present in this Catalog; unsupported products, unreadable prices and missing recipients stay blocked while Apply is active. The two checkout dialogs are local recreations authorized by the user, not Roblox's native financial prompt. No purchase API, server gift request, receipt or completion signal is sent. The gift recipient receives nothing.

Validation: NativeShop, Simulation, NativeItems and NativeEquip assertions and seven Python build tests pass. A Studio client playtest used actual clicks against a native-path fixture: the original callback fired before Apply, remained unchanged throughout local checkout, and fired again after Reset. Cancel preserved 975141; confirming a discounted Buddha gift deducted 1485 to 973656 and recorded exactly one gift. Confirmation and success screens were visually inspected. Live Blox Fruits integration and phone/gamepad interaction still need confirmation; no real transaction was performed in these tests.

## v12.8 Visual Robux / Shop Gifts (previous behavior)

**Historical investigation (27 November 2026):** v12.8 performed an immediate local gift record without confirmation. At that point the user required native UI only. Native purchase components and their test mocks were found, but all five attempted export loads failed with `Cannot require a RobloxScript module from a non RobloxScript context`. UI capture contained shells rather than usable checkout controls. The user subsequently authorized the two recreated local dialogs now implemented in v12.9. See [DIAG](docs/DIAG.md).

Balance now contains a Visual Robux input, APPLY BALANCE, an optional 10% visual discount and Reset. The previous Beli/Fragments editor is removed. The discount only changes the simulated checkout price, rounded up to whole visual Robux; it does not represent an account subscription.

After applying, open the game's Shop → Permanent Fruit Shop → Gift, use its existing Server/Global search and select a player. The observed GiftWindow purchase control is replaced by a sanitized UI copy labeled Visual while preview mode is active. Clicking it records a local gift and deducts the current displayed quote from the visual balance, with the visual discount when enabled. The original price label is not rewritten. Unsupported products, unknown prices and unselected recipients remain blocked in preview mode. The adapter currently supports permanent-fruit names present in this Catalog, not every product in the game shop.

No purchase API or server gift action is invoked by the preview adapter. Reset, disabling Balance in Tools, and closing the Catalog remove its copied controls and restore the original button. Gifts are not delivered and do not grant permanent ownership. The existing Gift Perm history also shows these local records.

The implementation uses paths and context/price text measured from the user's GiftWindow report. tools/InspectShopGift.client.luau is a bounded read-only observer; it does not activate controls or copy text entered in TextBoxes. Its raw reports stay local.

Validation: NativeShop and Simulation assertions cover observed context parsing, quotes, insufficient balance, the discount, unknown products, reset and cleanup. Existing NativeItems/NativeEquip checks and seven Python build tests pass. A Studio client playtest used actual UI clicks: applying 758796, enabling the discount, then clicking a fixture's Buddha gift deducted 1485 and recorded one simulated gift while the original purchase callback counter remained zero. Reset and cleanup passed; the Balance screen was visually inspected. Live Blox Fruits UI behavior after loading this version still needs user confirmation.

## v12.7 Equip from the game inventory

Local-only inventory actions now enqueue Equip on a worker created by the catalog script. The native action callback waits for that result instead of importing local files in the game's callback context, where GetObjects was reported unavailable. Errors still return through Future<Result>; the queue is bounded, and closing releases waiting requests. Genuine stock and networked copies retain the game's original action path. The panel Equip path is unchanged.

The completed v12.6 grouped audit in Blox Fruits checked all 134 visible fruit/skin rows in 87.8 seconds: 45 models loaded, 35 physical appearances had no local file, one Empyrean file was rejected as Galaxy, and 53 rows were metadata only. Thirty-five private rigs changed pose, eight animation clips failed fetch, and Diamond/Ice contained no idle animation. A Buddha VFX texture still failed fetch. These measurements do not establish current-game visual parity or validate each native Equip click. See docs/DIAG.md and docs/ASSET_AUDIT.md for dated evidence.

Validation: NativeItems assertions reproduce the native-callback import regression, then verify worker execution, Future error propagation, real-item forwarding and closure during a yielding import.

## v12.6 Model availability before first Equip

The card's availability check now recognizes local model files before they are imported. This restores green cards and the Equip label for items such as Meme on a fresh session. Import errors are remembered separately, so a rejected file becomes unavailable until Rescan clears its error for a retry. Successful native capture clears the error, and Equip refreshes the card after loading.

The grouped audit in tools/AuditFruitAndSkins.client.luau checks the 47 base-fruit cards and 87 skin/redeemable cards. It labels metadata-only entries separately from the 81 physical appearances. It inspects existing local files and player Tools, preloads typed render dependencies and PBR maps, and measures pose changes on hidden sanitized copies with the current animation IDs. It records authored VFX settings before disabling effects on those copies. It saves a local JSON report and cleans up its temporary objects. An asset-fetch result and a pose change do not establish full visual parity with the current game.

Prepare the current bundle as blox-catalog-sim-v12.6.lua and the audit helper as codex-fruit-skin-audit-v1.lua in the Potassium workspace, then run:

```lua
loadstring(readfile("codex-fruit-skin-audit-v1.lua"))()
```

Wait for the saved-report message. The audit does not require manually equipping or dropping real fruit.

## v12.5 Default appearances of variants

Empyrean, Fiend (Yeti), Hellfire (Gas) and Werewolf (Tiger) now appear in Fruit Skins, linked to Kitsune, Yeti, Gas and Tiger respectively. These user-confirmed relationships are stored in data/fruit-variant-relations.json. The source IsDefault flag describes an appearance within a variant and is preserved separately from its UI classification.

The catalog now has 47 base fruits and 34 physical skin variants. The skins tab displays 87 cards including the remaining skin definitions and redeemables. All 351 source IDs are retained. Cards no longer advertise an equip-ready model solely because a file path exists when the model loader has rejected that file.

The current audit finds 7 base fruits and 28 skins without local model files, plus the mislabeled Empyrean export that remains blocked. Animation preload and unresolved VFX findings remain tracked for both tabs.

## v12.4 Base fruits and skins

Catalog classification now follows Skin.Physical and Skin.IsDefault. Thirty physical skin variants, including Arcsteel Magnet and Galaxy, appear in Fruit Skins. Default appearances, including Magnet and Yeti, stay in Fruits. The matching ownership-skin definitions remain addressable by their original IDs and share the physical item's visible card. Searching by the linked skin ID finds that physical card.

There are 51 base-fruit cards and 83 skin/redeemable cards. The latter includes 30 physical variants, 31 skins without a Physical reference and 22 redeemables. All 351 source IDs are retained. Add, Equip, animations, menus and Drop continue to recognize physical fruit models across both tabs.

Of the 35 physical appearances without local files, 9 are base fruits and 26 are skins. Reclassification supplies no new mesh or animation asset. See the per-ID [asset audit](docs/ASSET_AUDIT.md) and [diagnostics](docs/DIAG.md). The Arcsteel/Galaxy and default Magnet regressions were verified alongside model loading and Equipment tests in Studio.

## v12.3 Dropped fruit ground contact

Dropped local fruits now use an invisible collision box fitted to the visible parts. An oversized Handle no longer holds the visible fruit above the floor. The collider is disabled while equipped and reused on subsequent drops. Models that contain only a Handle keep Handle collision.

The Studio physics regression reproduces an oversized invisible Handle and a visible body offset above it. v12.2 fails the floor-contact assertion. v12.3 places the body's lower edge within 0.15 studs of the floor and passes the contact pickup, foreign-contact, repeated Drop and Clear checks. This is a box approximation of visible part bounds, including skinned MeshPart bounds. In-game visual confirmation is still pending.

## v12.2 Drop and contact pickup

Drop now releases the local Tool's external hand grip, keeps its internal rig joints, and places its Handle five studs ahead of the character with initial velocity (0, 1, 0). The Handle has collision and mass while dropped. Walking into the dropped local fruit picks it up after a short contact cooldown. The custom pickup prompt has been removed. Pickup restores held collision/touch settings, and Clear/Store disconnect the pickup listener.

The November 27 Spin observation recorded the hand grip being removed, the initial placement and velocity. Another player collected the genuine fruit, so the report does not verify pickup by the observer. Contact pickup for the local simulator was tested separately in Studio with fixture parts, including foreign-contact rejection, repeated Drop and Clear cleanup. Original fruit Tools are excluded by the existing ownership guard.

Validation includes Equipment action assertions and a physics playtest in Studio. This release changes local Drop behavior. Fruit animation preload failures remain unresolved.

## v12.1 Model identity and visual feedback

### Diagnostic comparison, 2026-11-21

Next, capture the held runtime state with the existing observer's `visuals` mode. Add Arcsteel Magnet, Gas and Magma to the local Added tab first, run the line below, then Equip each one in that order for at least eight seconds. The observer reads all three tools for up to 90 seconds, stopping early when each has a held sample at six seconds. It records eye/mesh positions relative to Handle, bone transforms, weld frames, emitter origins and authored FX parameters. It does not equip or mutate the observed tools. Missing targets are reported explicitly as `targetsComplete=false`.

```lua
loadstring(readfile("codex-fruit-runtime-watch-v1.lua"))("visuals")
```

Copy `tools/WatchFruitRuntime.client.luau` to that workspace filename. Results are saved locally as `blox-fruits-held-visuals-<PlaceId>.json`. `tests/HeldVisualObserver.spec.luau` takes the observer source string; it verifies the three-tool transition, sampling, positions, FX flags and saved output with injected services and a clock. The default observer mode retains its older 40-second report format. Runtime capture is diagnostic, not a visual fix.

`tools/CompareFruitVisuals.client.luau` was run in the original experience against 50 local files. It found no changes in the compared mesh, surface, FX, attachment and rig properties after sanitization, allowing 1e-6 numerical normalization. Of 497 render asset references, 496 fetched successfully; Buddha's particle texture `6960307279` failed. PBR map images were requested explicitly. The raw files contained no scripts or tags; 53 sounds were intentionally removed by the existing clone sanitizer. These checks happen on private copies before equip, so they do not establish runtime FX activation, correct rig placement or current native model parity.

The six user-confirmed good files contain authored particle effects. Kitsune's file has no ParticleEmitter/Beam/Trail; Magma has nine emitters that survive cloning. Gas's Eyes mesh survives and its mesh asset fetched successfully. Missing source FX and runtime activation/placement therefore require separate investigation. [Scoped diagnostic summary](data/fruit-visual-parity-summary-2026-11-21.json).

The helper is available locally as `codex-fruit-visual-parity-v1.lua`; it uses `blox-catalog-sim-v12.lua` and the existing local model pack. It creates private copies, preloads render dependencies and saves `blox-fruits-visual-parity-<PlaceId>.json`. It never starts the UI, equips, plays scripts/animations or invokes game remotes. `tests/CompareFruitVisuals.spec.luau` exercises comparison, PBR image fetching, sound/script filtering and cleanup using injected inputs. This diagnostic does not change the production client or announce a new fix version.

The Empyrean export without an ItemId has the root name `Galaxy Empyrean Kitsune Fruit`, matching the user's report that it displays the Galaxy skin. Import now rejects that mislabeled source for Empyrean (1041) with a specific error, instead of presenting Galaxy as Empyrean. A correctly named Empyrean source, genuine native templates, and Galaxy (1042) remain supported. A proper Empyrean model is still required; this patch does not supply it.

[User visual feedback](data/fruit-user-feedback-2026-11-21.json) records 22 incomplete cases and six confirmed-good references. Control was reported as an outdated model. Gas lacks visible side eyes despite the local file containing an Eyes mesh. Missing FX, inactive authored FX, missing motion and absent models are tracked separately; absence of particles alone is not proof that the native fruit should have them. No FX is synthesized or enabled speculatively. The three-control and 34-model v12 tests measured pose changes, not complete current-game appearance or FX parity.

`tools/InspectCurrentFruitSources.client.luau` reads current client sources and asset fetch status, without requiring game modules, loading assets or touching inventory. Scan limits are explicit; a limited scan cannot establish that a model does not exist. Model files and detailed runtime reports remain local.

## v12 Verified animation references

The local model pack had many incorrect Idle IDs. In the original experience, a batch checked candidate clips on hidden sanitized copies: all three known-good controls moved, and 30 replacement clips changed the corresponding rigs' Bone/Motor6D poses. These include Control, Kitsune, Gravity, Gas and Eagle. Imports now apply only the verified ItemId, old AnimationId and exact rig fingerprint; genuine Tools and captured native templates keep their own animation. Eagle's verified rig also receives its missing Animation instance. No extra preload helper is needed for normal use.

[Validation data and candidate source](docs/fruit-animation-validation.json) record the tested mappings and limits. Pose changes establish rig binding, not complete visual/FX parity. Flame's candidate loaded without moving its rig and was excluded. Diamond lacks a rig; Rocket, Portal and Venom lack matching local files. Dragon variants remain unverified. The existing local pack still matches only 46 of 81 Fruits; this update does not supply missing meshes or invent motion/effects.

The rebuilt v12 import path was checked again in the original game without overriding imported IDs: all 34 tested models moved (30 corrected fruits, Buddha and three controls). Eleven Luau assertion suites and five Python build checks passed. The normal client needs no probe.

## Animation loading in the main client

Run the client once; no separate preload helper is needed. On first fruit Equip, the client preloads a private `Animation` instance and caches the result by AnimationId for this catalog session. Concurrent requests share the same fetch. Each rig still gets its own Animator track, reused on re-equip. Failed IDs are cached too, without automatic retry loops; restarting the catalog starts a new session.

Equipping a local fruit now reports that its animation is being checked. Playback starts only after its track has nonzero Length. Fetching and track readiness each have an 8-second timeout. Unequipping or closing prevents late playback; closing also cancels pending fetches and disposes temporary objects. Missing animation, failed loading and ready states are reported separately. Existing genuine Tools keep their native behavior, and FX properties are retained.

The older export audit found 38 failed IDs; v12 replaces only independently validated mappings. Preload success and nonzero track length do not establish full rig/FX parity. [AnimationTrack.Length](https://create.roblox.com/docs/reference/engine/classes/AnimationTrack#Length).

## v10 Verified Buddha import correction

The native Buddha Tool used animation `15123606541`; the local Buddha export instead referenced `78877647242196`. Typed animation preloading confirmed the native ID succeeds and the exported ID fails in place 2753915549. Import now corrects that exact old ID only for Buddha (ItemId 1393), on the sanitized copy. Original files, genuine Tools, already-correct IDs and other fruits remain unchanged. A matching local Buddha model is still required; a real held Buddha is no longer needed to obtain this correction on each launch.

The earlier v2 preload audit passed its native reference and reported 5 successful IDs and 38 failed IDs, before the v12 reference corrections. Account and place changed together, so it does not isolate an account effect. The earlier v1 raw-string preload audit is invalid for this classification. Unverified animations, missing scripted FX and the 35 catalog fruit records without matching local files remain unresolved.

## v9 Native fruit templates

Rescan keeps a sanitized in-memory copy of real fruit Tools in the local player's Backpack/Character, matched by exact ItemId. These copies take priority over imported files and survive when the genuine Tool is stored or removed during this catalog session. Original Tools are unchanged. Close destroys the copies; they are not saved or uploaded. Hold the real fruit until its model has loaded, then press Rescan.

The captured Buddha reference exposed a different animation ID in the imported file and a native `Fruit/Animation` child rather than `Idle`. The client now accepts that native child name as a fallback beside the same AnimationController. It does not replace another fruit's animation ID with Buddha's. Imported files may still contain unavailable animation IDs; missing scripted FX and absent models remain limitations.

## Native fruit dialogue

Fruit Equip first uses a matching player Tool, then an already available game model, then a local file at `codex_fruit_studio/models/<StorageKey>.rbxm` or `<Name>.rbxm` in the executor workspace. Files are loaded on demand through `getcustomasset` and `game:GetObjects`; these require an environment that supports local model imports. The model files stay on the user's machine and are not bundled or uploaded to this repository. [Potassium local asset documentation](https://docs.potassium.pro/api-reference/Instance%20Library/getcustomasset).

The inspected local folder contains exact filename matches for **46 of the 81** catalog fruit records, including Arcsteel Magnet, Blizzard, Bomb and Control. Dragon (East), Celestial and several skins still lack exact files; no unrelated model or icon placeholder is substituted. Other users need their own matching local files.

The custom fruit bar and its setting have been removed. The legacy Items panel's Equip button is connected to the same local Tool creation path for added-only Fruits. Real stock retains its original button callback. Clear removes cosmetic Tools; Undo restores inventory entries; Close cleans up Tools and imported templates. The game's hotbar and CoreGui settings are left intact.

Held or locally dropped fruits play the `Idle` animation (or native `Animation` fallback) found beside their own AnimationController. Tracks are reused on re-equip, stopped outside Workspace and destroyed on cleanup. Authored particle rates, colors, enabled states, beams, trails, bones and joints are retained; missing scripted FX are not replaced with invented motion. Animation asset permissions and missing files may still prevent exact visual parity. [Animator loading requirements](https://create.roblox.com/docs/reference/engine/classes/Animator#LoadAnimation).

Click a held local fruit to open the game's own `DialogueController.start` renderer. The dialogue configuration comes from the user's captured real-fruit menu: title Blox Fruit, the original prompt and animation tag, Chat options Eat/Drop/Store, Nevermind, and default layout. No legacy GUI clone, custom coordinates, fonts or icons are used. The catalog hides while this menu is open so it does not cover the native renderer.

V8 avoids `startForTool`, whose lazy require of ToolInteraction failed in the live executor with `Cannot require a non-RobloxScript module from a RobloxScript`. It calls the already-loaded controller's start method directly and manages owned-tool Unequipped/Destroying cleanup. It does not change script identity or module permissions. Menu failures now print to the console and save `blox-catalog-menu-error.txt` when writefile is available.

Actions retain local simulation semantics: Drop places this client's visual in the world with a pickup prompt; Store removes its Tool and restores local stock; Eat explains that a real server-owned fruit is required. These callbacks run after the native dialogue closes and do not call EatRemote. The catalog footer identifies the local visual context. Original player Tools retain their native scripts and menu.

Only an already-loaded DialogueController is required. Closing the catalog dismisses only its own dialogue; an NPC or genuine fruit menu is never replaced or closed. If the controller is not cached, open any game dialogue once and retry. The outdated Main.Dialogue fallback has been removed.

Imported raw objects remain outside the DataModel. Equipment strips scripts, remotes and component tags before any copy enters Backpack/Character. Fruit clones activate only their menu; cosmetic weapons remain disabled. The native dialogue regression reproduces the failing lazy entry and passes using direct start. Studio input tests verify opening the native-controller adapter and closing/restoring on tool unequip with the lazy entry set to fail. The user confirmed the v8 native menu in Potassium; v9 template capture still needs a live check.

## Existing Tool behavior

Visual Equip now equips the selected item instead of opening a preview. View remains the preview button. Existing Tools retain their scripts and activation behavior; Clear, Restore visuals and Close leave those Tools intact. Native Equip actions for stock that existed before the local overlay retain the game's original handler.

Entries without a Tool, available model or matching local fruit file show `No model`. Repeated Visual Equip does not add duplicate stock. Restore visuals removes all cosmetic Tools created through Visual.

Studio tests verified existing Tool equip and server activation, two cosmetic equips, repeated equip, missing-model handling and cleanup. Cosmetic Tools do not add Blox Fruits combat abilities.

## Cache behavior

The inspected game cache normalizes `false` and `0` to `nil`. Earlier versions compared these values literally and reported a failed write. The adapter now writes only Quantity, accepts its zero-to-nil representation and leaves other item flags to the game. Verification remains enabled, and rejected or mismatched writes are rolled back. Errors include the item ID, key and expected/actual values; supported environments also save `blox-catalog-native-error-<PlaceId>.json` locally.

Regression tests match the inspected cache behavior. The user has confirmed local entries in the live Items UI and successful Arcsteel equipment with the game's native hotbar.

## Source and updates

- `catalog/Data/`: seven databases, 351 records from the exported ItemConfig snapshot.
- `catalog/`: UI, inventory, local equipment, native cache/Equip adapters and local model imports.
- `client.lua`: generated standalone client used by the stable loader.
- `dist/catalog.json`: normalized data and source manifest.
- `ExportCatalog.client.luau`: metadata exporter for future database refreshes.
- `tests/`: Lua assertion suites and Python build checks.

After editing modules or database source, rebuild from this repository:

```powershell
python tools/build_catalog.py
python -m unittest discover -s tests -p test_build_catalog.py
```

To regenerate databases from a new metadata report:

```powershell
python tools/build_catalog.py 'C:\path\to\blox-fruits-catalog-data-v1-2753915549.json'
```

Commit the updated modules together with generated `client.lua`; users keep the same loader URL. Raw game code dumps, cache reports, local credentials and unrelated projects are excluded from publication.

Lua suites return a function accepting their tested modules. Run them in Studio Edit: `Simulation.spec.luau` takes Inventory/Catalog, `NativeItems.spec.luau` takes NativeItems, `NativeEquip.spec.luau` takes NativeEquip, `NativeDialogue.spec.luau` takes NativeDialogue, `Equipment.spec.luau`, `FruitMotion.spec.luau` and `EquipmentActions.spec.luau` take Equipment, and `FruitModels.spec.luau` takes FruitModels/Equipment. [Detailed runtime notes](catalog/README.md).

Diagnostic probe: copy `tools/ProbeOriginalFruitAnimations.client.luau` to `codex-original-fruit-animation-rigs-v1.lua` in the Potassium workspace, and the corresponding `data/` manifest to its `codex-` filename. `data/original-fruit-animation-candidates.json` is candidate mode; `data/v12-fruit-animation-validation.json` is import verification mode. Both require the corresponding local v11/v12 bundle and model files. Run only in the original Blox Fruits experience.

```lua
loadstring(readfile("codex-original-fruit-animation-rigs-v1.lua"))("codex-v12-fruit-animation-validation.json")
```

`FruitAnimations.spec.luau` takes FruitAnimations; `FruitAnimationImport.spec.luau` takes FruitModels/Equipment/FruitAnimations.
