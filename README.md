# Blox Catalog

Modular Luau catalog and local inventory simulator. This repository is separate from `virus-visualizer-loader`.

## Run the latest client

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Open Items in Blox Fruits, press Rescan, and wait for `Items linked locally`. Add a fruit, open Added, and press Equip. A fruit with a model becomes a local Tool; the game's own hotbar displays it. There is no separate catalog hotbar. Right Shift hides/shows the catalog panel; Tools enables/disables utilities.

The client, inventory entries, balance and gifts are local simulations. They do not grant server items, combat abilities, Robux products or permanent ownership. Icon/ID data does not contain 3D models; missing models are reported without consuming local stock.

## v8 Native fruit dialogue

Fruit Equip first uses a matching player Tool, then an already available game model, then a local file at `codex_fruit_studio/models/<StorageKey>.rbxm` or `<Name>.rbxm` in the executor workspace. Files are loaded on demand through `getcustomasset` and `game:GetObjects`; these require an environment that supports local model imports. The model files stay on the user's machine and are not bundled or uploaded to this repository. [Potassium local asset documentation](https://docs.potassium.pro/api-reference/Instance%20Library/getcustomasset).

The inspected local folder contains exact filename matches for **46 of the 81** catalog fruit records, including Arcsteel Magnet, Blizzard, Bomb and Control. Dragon (East), Celestial and several skins still lack exact files; no unrelated model or icon placeholder is substituted. Other users need their own matching local files.

The custom fruit bar and its setting have been removed. The legacy Items panel's Equip button is connected to the same local Tool creation path for added-only Fruits. Real stock retains its original button callback. Clear removes cosmetic Tools; Undo restores inventory entries; Close cleans up Tools and imported templates. The game's hotbar and CoreGui settings are left intact.

Held or locally dropped fruits play the `Idle` animation found beside their own AnimationController. Tracks are reused on re-equip, stopped outside Workspace and destroyed on cleanup. Authored particle rates, colors, enabled states, beams, trails, bones and joints are retained; missing scripted FX are not replaced with invented motion. Animation asset permissions and missing files may still prevent exact visual parity. [Animator loading requirements](https://create.roblox.com/docs/reference/engine/classes/Animator#LoadAnimation).

Click a held local fruit to open the game's own `DialogueController.start` renderer. The dialogue configuration comes from the user's captured real-fruit menu: title Blox Fruit, the original prompt and animation tag, Chat options Eat/Drop/Store, Nevermind, and default layout. No legacy GUI clone, custom coordinates, fonts or icons are used. The catalog hides while this menu is open so it does not cover the native renderer.

V8 avoids `startForTool`, whose lazy require of ToolInteraction failed in the live executor with `Cannot require a non-RobloxScript module from a RobloxScript`. It calls the already-loaded controller's start method directly and manages owned-tool Unequipped/Destroying cleanup. It does not change script identity or module permissions. Menu failures now print to the console and save `blox-catalog-menu-error.txt` when writefile is available.

Actions retain local simulation semantics: Drop places this client's visual in the world with a pickup prompt; Store removes its Tool and restores local stock; Eat explains that a real server-owned fruit is required. These callbacks run after the native dialogue closes and do not call EatRemote. The catalog footer identifies the local visual context. Original player Tools retain their native scripts and menu.

Only an already-loaded DialogueController is required. Closing the catalog dismisses only its own dialogue; an NPC or genuine fruit menu is never replaced or closed. If the controller is not cached, open any game dialogue once and retry. The outdated Main.Dialogue fallback has been removed.

Imported raw objects remain outside the DataModel. Equipment strips scripts, remotes and component tags before any copy enters Backpack/Character. Fruit clones activate only their menu; cosmetic weapons remain disabled. The native dialogue regression reproduces the failing lazy entry and passes using direct start. Studio input tests verify opening the native-controller adapter and closing/restoring on tool unequip with the lazy entry set to fail. The direct v8 call still needs a live Potassium check.

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
