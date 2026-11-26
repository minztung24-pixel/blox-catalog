"""Build seven catalog modules and a standalone client from an exported report."""
import argparse
import hashlib
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
CATEGORIES = {"Fruits": "Fruits", "Permanent": "Permanent", "Fruit Skins": "FruitSkins",
              "Premium": "Premium", "Swords": "Swords", "Guns": "Guns", "Skills": "Skills"}


def mapping(value):
    return value if isinstance(value, dict) else {}


def normalize(config):
    index, display, quality = (mapping(config.get(k)) for k in ("Index", "Display", "Quality"))
    kind, category = index.get("IdType"), display.get("Category")
    name = display.get("Name") or index.get("StorageKey")
    if kind == "PhysicalMoveset" and category == "Blox Fruit":
        group = "Fruits"
    elif kind == "Redeemable" and category == "Blox Fruit" and (
            display.get("RibbonText") == "Permanent" or isinstance(name, str) and name.startswith("Permanent ")):
        group = "Permanent"
    else:
        group = {"Fruit Skin": "Fruit Skins", "Premium": "Premium", "Sword": "Swords", "Gun": "Guns",
                 "Fighting Style": "Skills", "Ability": "Skills", "Admin Ability": "Skills"}.get(category)
    if group is None:
        return None
    item_id = index.get("ItemId")
    if isinstance(item_id, bool) or not isinstance(item_id, (int, float)) or not math.isfinite(item_id) or item_id <= 0 or item_id != int(item_id):
        raise ValueError("Invalid game ItemId")
    if not isinstance(name, str) or not name:
        raise ValueError(f"Missing name and StorageKey for {item_id}")
    sprite = mapping(display.get("Sprite"))
    item = {"id": str(int(item_id)), "name": name, "category": group,
            "nameSource": "Display.Name" if display.get("Name") else "Index.StorageKey",
            "storageKey": index.get("StorageKey", ""), "idType": kind, "gameCategory": category,
            "rarity": quality.get("Rarity") or "Unknown", "icon": sprite.get("Image") or "",
            "title": display.get("Title") or "", "description": display.get("Description") or "",
            "missing": [], "source": f"ItemConfig:{int(item_id)}"}
    if not quality.get("Rarity"):
        item["missing"].append("rarity")
    if not sprite.get("Image"):
        item["missing"].append("icon")
    for field, target in (("ImageRectOffset", "iconRectOffset"), ("ImageRectSize", "iconRectSize")):
        rect = mapping(sprite.get(field))
        if rect:
            coords = [rect.get("x"), rect.get("y")]
            if not all(isinstance(n, (int, float)) and math.isfinite(n) and n >= 0 for n in coords):
                raise ValueError(f"Invalid atlas coordinates for {item_id}")
            item[target] = coords
    skin = mapping(config.get("Skin"))
    if isinstance(skin.get("Physical"), (int, float)):
        item["physicalId"] = skin["Physical"]
    return item


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, str):
        escapes = {"\\": "\\\\", '"': '\\"', "\n": "\\n", "\r": "\\r", "\t": "\\t"}
        return '"' + "".join(escapes.get(c, "\\" + str(ord(c)).zfill(3) if ord(c) < 32 else c) for c in value) + '"'
    if isinstance(value, (int, float)):
        if not math.isfinite(value):
            raise ValueError("Non-finite Luau number")
        return str(value)
    if isinstance(value, list):
        return "{" + ", ".join(lua(v) for v in value) + "}"
    if isinstance(value, dict):
        return "{" + ", ".join("[" + lua(k) + "] = " + lua(v) for k, v in value.items()) + "}"
    raise TypeError(type(value))


def package_xml(sources, data_sources):
    root = ET.Element("roblox", version="4")
    folder = ET.SubElement(root, "Item", {"class": "Folder"})
    ET.SubElement(ET.SubElement(folder, "Properties"), "string", name="Name").text = "BloxCatalog"

    def script(parent, name, source, kind="ModuleScript"):
        item = ET.SubElement(parent, "Item", {"class": kind})
        props = ET.SubElement(item, "Properties")
        ET.SubElement(props, "string", name="Name").text = name
        ET.SubElement(props, "ProtectedString", name="Source").text = source
        return item

    data = script(folder, "Data", sources["Data"])
    for name, source in data_sources.items():
        script(data, name, source)
    for name in ("Catalog", "NativeItems", "NativeEquip", "NativeDialogue", "Equipment", "FruitAnimations", "FruitModels", "Inventory", "UI"):
        script(folder, name, sources[name])
    script(folder, "Main", sources["Main"], "LocalScript")
    return ET.tostring(root, encoding="utf-8", xml_declaration=True)


def bundle(snapshot_version=None):
    output = ROOT / "dist"
    output.mkdir(exist_ok=True)
    if snapshot_version is None and (output / "catalog.json").exists():
        snapshot_version = json.loads((output / "catalog.json").read_text(encoding="utf-8"))["manifest"]["placeVersion"]
    data_sources = {name: (ROOT / "catalog" / "Data" / (name + ".luau")).read_text(encoding="utf-8") for name in CATEGORIES.values()}
    sources = {name: (ROOT / "catalog" / ("Data/init.luau" if name == "Data" else name + (".client.luau" if name == "Main" else ".luau"))).read_text(encoding="utf-8")
               for name in ("Data", "Catalog", "NativeItems", "NativeEquip", "NativeDialogue", "Equipment", "FruitAnimations", "FruitModels", "Inventory", "UI", "Main")}
    parts = ["-- Blox Catalog v12.3 simulator. Snapshot place version " + str(snapshot_version) + ".\n"]
    for name, text in data_sources.items():
        parts.append("local Data" + name + " = (function()\n" + text + "\nend)()\n")
    for name in ("Data", "Catalog", "NativeItems", "NativeEquip", "NativeDialogue", "Equipment", "FruitAnimations", "FruitModels", "Inventory", "UI"):
        text = sources[name]
        if name == "Data":
            for category, module in CATEGORIES.items():
                text = text.replace("require(script." + module + ")", "Data" + module)
        elif name == "Catalog":
            text = text.replace("local Database = require(script.Parent.Data)", "local Database = Data")
        elif name in ("UI", "FruitModels"):
            for dependency in ("Catalog", "Inventory", "NativeItems", "NativeEquip", "NativeDialogue", "Equipment", "FruitAnimations", "FruitModels"):
                text = text.replace("local " + dependency + " = require(script.Parent." + dependency + ")", "local " + dependency + " = " + dependency)
        parts.append("local " + name + " = (function()\n" + text + "\nend)()\n")
    parts.append("return UI.start()\n")
    bundled = "".join(parts)
    if "require(script." in bundled:
        raise ValueError("Unbundled module dependency")
    (ROOT / "client.lua").write_text(bundled, encoding="utf-8")
    (output / "blox-catalog-sim-v12.lua").write_text(bundled, encoding="utf-8")
    (output / "BloxCatalog.rbxmx").write_bytes(package_xml(sources, data_sources))


def build(source):
    raw = source.read_bytes()
    report = json.loads(raw.decode("utf-8-sig"))
    if not report.get("complete") or report.get("modules", {}).get("ItemConfig", {}).get("status") != "ok":
        raise ValueError("Catalog export did not complete successfully")
    section = report["sections"]["ItemConfig"]
    if section.get("reason"):
        raise ValueError("ItemConfig hit an export limit; preserve and inspect the report")
    groups, seen = {name: [] for name in CATEGORIES}, set()
    for row in section["records"]:
        item = normalize(mapping(row.get("data")))
        if item:
            if item["id"] in seen:
                raise ValueError("Duplicate ItemId: " + item["id"])
            seen.add(item["id"])
            groups[item["category"]].append(item)
    data_dir, output = ROOT / "catalog" / "Data", ROOT / "dist"
    data_dir.mkdir(parents=True, exist_ok=True)
    output.mkdir(exist_ok=True)
    for category, name in CATEGORIES.items():
        rows = sorted(groups[category], key=lambda r: (r["name"].casefold(), int(r["id"])))
        groups[category] = rows
        source_text = "-- Generated from ItemConfig; update with tools/build_catalog.py.\nreturn {\n" + "".join("\t" + lua(row) + ",\n" for row in rows) + "}\n"
        (data_dir / (name + ".luau")).write_text(source_text, encoding="utf-8")
    manifest = {"placeId": report.get("placeId"), "placeVersion": report.get("placeVersion"),
                "sourceSha256": hashlib.sha256(raw).hexdigest(), "sourceRecords": len(section["records"]),
                "items": len(seen), "categories": {c: {"items": len(rows),
                  "missingRarity": sum("rarity" in r["missing"] for r in rows),
                  "missingIcon": sum("icon" in r["missing"] for r in rows)} for c, rows in groups.items()},
                "scope": "Client inventory, balance, gifts and visual previews are simulations."}
    (output / "catalog.json").write_text(json.dumps({"manifest": manifest, "databases": groups}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    bundle(report.get("placeVersion"))
    print(json.dumps(manifest, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, nargs="?", help="Optional report to regenerate databases; omit to rebuild existing source")
    args = parser.parse_args()
    if args.source:
        build(args.source)
    else:
        bundle()
        print("Built client.lua and dist/BloxCatalog.rbxmx from checked-in modules")
