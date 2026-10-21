"""Check T7.7 resources without launching or unit-testing SwiftUI views.

Run from the repository root:
    python3 Tools/NavigationCatalog/test_navigation_catalog.py
"""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate catalog key: {key}")
        result[key] = value
    return result


class NavigationCatalogTests(unittest.TestCase):
    def test_navigation_strings_are_translated(self):
        catalog = json.loads(
            (ROOT / "Keepercent/Localizable.xcstrings").read_text(encoding="utf-8"),
            object_pairs_hook=unique_object,
        )
        self.assertEqual(catalog["sourceLanguage"], "en")
        required = [
            "Matches", "Rivals", "My Club", "New Match", "No Matches",
            "No Rivals", "Choose Rival", "Roster", "Team Section",
            "Set Up My Club", "Deleted Rival", "More",
            "Start a match to record shots against a rival.",
            "Add a team in Rivals before starting a match.",
            "Create a rival team to add players and start scouting.",
            "Shot entry is unavailable because this rival was deleted.",
        ]
        for key in required:
            with self.subTest(key=key):
                entry = catalog["strings"][key]
                for language in ("en", "es", "es-419"):
                    unit = entry["localizations"][language]["stringUnit"]
                    self.assertEqual(unit["state"], "translated")
                    self.assertTrue(unit["value"].strip())


if __name__ == "__main__":
    unittest.main()
