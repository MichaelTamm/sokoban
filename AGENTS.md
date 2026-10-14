# Godot 4 & GDScript Debugging Guidelines

Diese Richtlinien definieren Projektstruktur, CLI-Tools und typische Fehlermuster für automatisierte Agenten beim Analysieren und Beheben von Bugs.

---

## 1. Environment & Headless Commands

Verwende für Tests und Validierungen ausschließlich die CLI-Flags von Godot. Alle Befehle werden aus dem Projekt-Root ausgeführt (dort, wo `project.godot` liegt).

- Syntax & Parse-Check für einzelne Skripte:
  `godot --headless --check-only -s res://path/to/script.gd`

- Headless-Lauf mit Debug-Ausgabe (Abstürze/Laufzeitfehler reproduzieren):
  `godot --headless --debug 2>&1 | head -n 100`

- Bestimmte Test-Szene headless anstarten:
  `godot --headless --debug res://path/to/test_scene.tscn`

- Unit-Tests ausführen (falls GUT konfiguriert ist):
  `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/ -gexit`

Hinweis für CLI-Runs: Endlos laufende `_process()`-Schleifen blockieren die Shell im Headless-Modus. Wenn du Szenen testweise startest, stelle sicher, dass sie sich nach getaner Arbeit beenden (z. B. via `get_tree().quit()`) oder setze ein Timeout-Kommando vor den Aufruf (z. B. `timeout 5s godot --headless ...`).

---

## 2. Debugging Workflow für den Agenten

Folge bei Fehlermeldungen dieser festen Reihenfolge:

1. Log / Stacktrace analysieren:
   - Prüfe, ob die Exception zur Ladezeit (`_enter_tree()`, `_ready()`) oder zur Laufzeit (`_process()`, Signal-Callbacks) auftritt.
2. Knotenpfade & Szenenvalidierung:
   - Bevor du Skripte änderst, prüfe die zugehörige `.tscn`-Datei (reines Textformat).
   - Verifiziere, ob referenzierte Node-Pfade (z. B. `$Player/CollisionShape2D` oder `%UniqueName`) in der Szene tatsächlich exakt so heißen (Case-Sensitive!).
3. Statische Typprüfung nutzen:
   - Wo möglich, statische Typen deklarieren (`var health: int = 100`), um Typkonflikte sofort beim Parse-Check sichtbar zu machen.
4. Validieren:
   - Nach Code-Änderungen immer mindestens `godot --headless --check-only -s <geändertes_skript>` ausführen.

---

## 3. Typische GDScript- und Godot 4-Fallstricke

- Null Instance on Node Access:
  - `$Node` schlägt fehl, wenn `_ready()` noch nicht abgeschlossen ist oder der Baum sich geändert hat.
  - Lösung: `@onready var node = $Node` nutzen oder `get_node_or_null()` prüfen. Bevorzuge Scene Unique Nodes (`%NodeName`) gegenüber fragilen relativen Pfaden.
- Signal-Syntax (Godot 4 vs. Godot 3):
  - Korrekt (Godot 4): `button.pressed.connect(_on_button_pressed)`
  - Veraltet (Godot 3): `button.connect("pressed", self, "_on_button_pressed")`
  - Callbacks müssen mit `Callable` verknüpft werden.
- Physics & Threading:
  - Physik-Manipulationen (`linear_velocity`, `move_and_slide()`, Raycasts) gehören zwingend in `_physics_process(delta)`, nicht in `_process(delta)`.
  - Direktes Ändern von Physik-Zuständen während eines Physics-Ticks erfordert oft `set_deferred()` oder `call_deferred()`.
- Resource Leaks / Dangling References:
  - Nach `queue_free()` ist die Referenz in GDScript erst am Ende des Frames ungültig.
  - Mit `is_instance_valid(node)` absichern, falls Zugriffe asynchron oder verzögert erfolgen.

---

## 4. Richtlinien für Dateiänderungen

- `.tscn`- und `.tres`-Dateien sind textbasiert, enthalten aber interne UIDs und Sub-Resource-IDs. Ändere sie nur minimal und vorsichtig manuell.
- Tab-Einrückung ist Standard in GDScript (Indent mit Tabs, nicht mit 4 Leerzeichen, sofern nicht anders im Projekt definiert).
- Behalte stets den GDScript-Styleguide bei (Snake_case für Funktionen und Variablen, PascalCase für Klassen).
