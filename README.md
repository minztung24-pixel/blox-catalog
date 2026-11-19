# Blox Catalog

Modular Luau catalog and local inventory simulator. This repository is separate from `virus-visualizer-loader`.

## Run the latest client

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Open Items in Blox Fruits, press Rescan, and wait for `Items linked locally`. Add updates the local Items cache and the Added tab. Adding Fruits also creates slots in the separate **FRUITS / local visuals** bar above the game's hotbar. Click a fruit slot to hold its local model. Right Shift hides/shows the catalog panel; Tools enables/disables utilities, including the fruit bar.

The client, inventory entries, balance and gifts are local simulations. They do not grant server items, combat abilities, Robux products or permanent ownership. Icon/ID data does not contain 3D models; missing models are reported without consuming local stock.

## v5 Fruits and local model files

Fruit Equip first uses a matching player Tool, then an already available game model, then a local file at `codex_fruit_studio/models/<StorageKey>.rbxm` or `<Name>.rbxm` in the executor workspace. Files are loaded on demand through `getcustomasset` and `game:GetObjects`; these require an environment that supports local model imports. The model files stay on the user's machine and are not bundled or uploaded to this repository. [Potassium local asset documentation](https://docs.potassium.pro/api-reference/Instance%20Library/getcustomasset).

The inspected local folder contains exact filename matches for **46 of the 81** catalog fruit records, including Arcsteel Magnet, Blizzard, Bomb and Control. Dragon (East), Celestial and several skins still lack exact files; no unrelated model or icon placeholder is substituted. Other users need their own matching local files.

The fruit bar scrolls horizontally, shows quantities and highlights the held fruit. It remains visible when the panel is hidden. Clear removes slots and cosmetic Tools; Undo restores slots; Close removes the bar and cleans up imported templates. The game's existing hotbar and CoreGui settings are left intact.

Imported raw objects remain outside the DataModel. Equipment strips scripts, remotes and component tags before any copy enters Backpack/Character. Tests cover path validation, cache reuse, import errors and cleanup. Studio UI checks use injected model imports and verify Add, hold, switching, Hide, Clear and Undo with real Humanoid equipment. Local `.rbxm` importing through Potassium has not yet been verified live.

## Existing Tool behavior

Visual Equip now equips the selected item instead of opening a preview. View remains the preview button. Existing Tools retain their scripts and activation behavior; Clear, Restore visuals and Close leave those Tools intact. Native Equip actions for stock that existed before the local overlay retain the game's original handler.

Entries without a Tool, available model or matching local fruit file show `No model`. Repeated Visual Equip does not add duplicate stock. Restore visuals removes all cosmetic Tools created through Visual.

Studio tests verified existing Tool equip and server activation, two cosmetic equips, repeated equip, missing-model handling and cleanup. This does not verify Blox Fruits combat or its custom hotbar in the current live version.

## Cache behavior

The inspected game cache normalizes `false` and `0` to `nil`. Earlier versions compared these values literally and reported a failed write. The adapter now writes only Quantity, accepts its zero-to-nil representation and leaves other item flags to the game. Verification remains enabled, and rejected or mismatched writes are rolled back. Errors include the item ID, key and expected/actual values; supported environments also save `blox-catalog-native-error-<PlaceId>.json` locally.

Regression tests match the inspected cache behavior. The user has confirmed local entries now appear in the live Items UI; equipment changes still need a live-game check.

## Source and updates

- `catalog/Data/`: seven databases, 351 records from the exported ItemConfig snapshot.
- `catalog/`: UI, inventory, local equipment and the native cache adapter.
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

Lua suites return a function accepting their tested modules. Run them in Studio Edit: `Simulation.spec.luau` takes Inventory/Catalog, `NativeItems.spec.luau` takes NativeItems, `Equipment.spec.luau` takes Equipment, and `FruitModels.spec.luau` takes FruitModels/Equipment. [Detailed runtime notes](catalog/README.md).
