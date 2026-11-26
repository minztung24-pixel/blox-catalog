# Blox Catalog

Modular Luau catalog and local inventory simulator. This repository is separate from `virus-visualizer-loader`.

## Run the latest client

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Open Items in Blox Fruits, press Rescan, and wait for `Items linked locally`. Add a fruit, open Added, and press Equip. A fruit with a model becomes a local Tool; the game's own hotbar displays it. There is no separate catalog hotbar. Right Shift hides/shows the catalog panel; Tools enables/disables utilities.

The client, inventory entries, balance and gifts are local simulations. They do not grant server items, combat abilities, Robux products or permanent ownership. Icon/ID data does not contain 3D models; missing models are reported without consuming local stock.

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
