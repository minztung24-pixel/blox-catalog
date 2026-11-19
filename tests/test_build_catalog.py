import importlib.util
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path


class BuildCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        spec = importlib.util.spec_from_file_location("build_catalog", Path(__file__).parents[1] / "tools" / "build_catalog.py")
        cls.module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(cls.module)

    def test_physical_and_permanent_ids_stay_distinct(self):
        config = {"Index": {"ItemId": 1393, "IdType": "PhysicalMoveset", "StorageKey": "Buddha-Buddha"},
                  "Display": {"Name": "Buddha", "Category": "Blox Fruit", "Sprite": {"Image": "rbxassetid://123",
                    "ImageRectOffset": {"x": 153, "y": 305}, "ImageRectSize": {"x": 150, "y": 150}}},
                  "Quality": {"Rarity": "Legendary"}}
        item = self.module.normalize(config)
        self.assertEqual((item["id"], item["category"], item["iconRectOffset"]), ("1393", "Fruits", [153, 305]))
        config["Index"].update(ItemId=372, IdType="Redeemable")
        config["Display"].update(Name="Permanent Buddha", RibbonText="Permanent")
        self.assertEqual(self.module.normalize(config)["category"], "Permanent")

    def test_missing_metadata_is_explicit_and_unknown_categories_are_skipped(self):
        config = {"Index": {"ItemId": 1152, "IdType": "Ability", "StorageKey": "Last Resort"},
                  "Display": {"Category": "Ability"}, "Quality": []}
        item = self.module.normalize(config)
        self.assertEqual((item["name"], item["rarity"], item["icon"]), ("Last Resort", "Unknown", ""))
        self.assertEqual(set(item["missing"]), {"rarity", "icon"})
        config["Display"]["Category"] = "Title"
        self.assertIsNone(self.module.normalize(config))

    def test_skin_and_redeemable_are_separate_real_records(self):
        config = {"Index": {"ItemId": 1538, "IdType": "Skin", "StorageKey": "MAGNETSKINarksteel"},
                  "Display": {"Category": "Fruit Skin", "Name": "Arcsteel", "Title": "Arcsteel <Magnet>"},
                  "Skin": {"Physical": 1525}, "Quality": {"Rarity": "Mythical"}}
        item = self.module.normalize(config)
        self.assertEqual((item["category"], item["id"], item["physicalId"]), ("Fruit Skins", "1538", 1525))

    def test_luau_strings_are_escaped_and_invalid_ids_are_rejected(self):
        self.assertEqual(self.module.lua('a"b\n'), '"a\\"b\\n"')
        self.assertEqual(self.module.lua('\x001'), '"\\0001"')
        self.assertEqual(self.module.lua('\\u001b'), '"\\\\u001b"')
        with self.assertRaises(ValueError):
            self.module.normalize({"Index": {"ItemId": float("nan")}, "Display": {"Category": "Sword"}})

    def test_studio_package_contains_required_fruit_model_module(self):
        folder = Path(__file__).parents[1] / "catalog"
        sources = {name: (folder / (name + ".luau")).read_text(encoding="utf-8")
                   for name in ("Catalog", "NativeItems", "Equipment", "FruitModels", "Inventory", "UI")}
        sources.update(Data="return {}", Main="return nil")
        root = ET.fromstring(self.module.package_xml(sources, {}))
        names = {item.findtext("Properties/string[@name='Name']") for item in root.find("Item").findall("Item")}
        self.assertIn("FruitModels", names, "Studio package must include the UI's new dependency")


if __name__ == "__main__":
    unittest.main()
