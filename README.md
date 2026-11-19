# Blox Catalog

Modular Luau catalog and local inventory simulator. This repository is separate from `virus-visualizer-loader`.

## Run the latest client

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/minztung24-pixel/blox-catalog/main/load.lua"))()
```

Open Items in Blox Fruits, press Rescan, and wait for `Items linked locally`. Add updates the local Items cache and the Added tab. Equip in Added creates a local visual Tool when the matching model is already available to the client. Right Shift hides/shows the window; Tools enables/disables utilities.

The client, inventory entries, balance and gifts are local simulations. They do not grant server items, combat abilities, Robux products or permanent ownership. Icon/ID data does not contain 3D models; missing models are reported without consuming local stock.

## v3 cache fix

The inspected game cache normalizes `false` and `0` to `nil`. Earlier versions compared these values literally and reported a failed write. The adapter now writes only Quantity, accepts its zero-to-nil representation and leaves other item flags to the game. Verification remains enabled, and rejected or mismatched writes are rolled back. Errors include the item ID, key and expected/actual values; supported environments also save `blox-catalog-native-error-<PlaceId>.json` locally.

The fix has a regression test matching the inspected cache behavior. Final live-game compatibility still requires checking the current game version.

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

Lua suites return a function accepting their tested modules. Run them in Studio Edit: `Simulation.spec.luau` takes Inventory/Catalog, `NativeItems.spec.luau` takes NativeItems, and `Equipment.spec.luau` takes Equipment. [Detailed runtime notes](catalog/README.md).
