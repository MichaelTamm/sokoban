extends Node2D

@export var box_texture: Texture2D

@onready var walls: TileMapLayer = $WallLayer
@onready var targets: TileMapLayer = $TargetLayer
@onready var box_spawner: TileMapLayer = $BoxSpawnLayer
@onready var boxes: Node2D = $Boxes
@onready var player: Node2D = $Player

# Koordinaten-System: (row, col)
# (0, 0) ist die Zelle oben links.
# (0, 1) ist die Zelle rechts daneben (gleiche Zeile, Spalte + 1).
# (1, 0) ist die Zelle darunter (Zeile + 1, gleiche Spalte).
var moves: Dictionary = {
	"ui_up": Vector2i(-1, 0),
	"ui_down": Vector2i(1, 0),
	"ui_left": Vector2i(0, -1),
	"ui_right": Vector2i(0, 1)
}

# Überführte Koordinaten aus den TileMapLayern im (row, col) System
var wall_cells: Array[Vector2i] = []
var target_cells: Array[Vector2i] = []
var box_cells: Array[Vector2i] = []
var player_pos: Vector2i
var has_won: bool = false
var win_label: Label


# --- Hilfsfunktionen für Koordinaten-Umrechnung ---

# Konvertiert Godot TileMap-Koordinaten (col, row) in unser Koordinatensystem (row, col)
func tile_to_grid(tile_coord: Vector2i) -> Vector2i:
	return Vector2i(tile_coord.y, tile_coord.x)

# Konvertiert unser Koordinatensystem (row, col) in Godot TileMap-Koordinaten (col, row)
func grid_to_tile(grid_coord: Vector2i) -> Vector2i:
	return Vector2i(grid_coord.y, grid_coord.x)

# Konvertiert unsere Koordinaten (row, col) in lokale Weltposition (Pixel)
func grid_to_world(grid_coord: Vector2i) -> Vector2:
	return walls.map_to_local(grid_to_tile(grid_coord))

# Konvertiert lokale Weltposition (Pixel) in unsere Koordinaten (row, col)
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return tile_to_grid(walls.local_to_map(world_pos))


# --- Initialisierung & Lifecycle ---

func _ready() -> void:
	# 1. Wand-Koordinaten aus dem TileMapLayer in unser (row, col) System überführen
	wall_cells.clear()
	for cell: Vector2i in walls.get_used_cells():
		wall_cells.append(tile_to_grid(cell))

	# 2. Ziel-Koordinaten aus dem TileMapLayer in unser (row, col) System überführen
	target_cells.clear()
	for cell: Vector2i in targets.get_used_cells():
		target_cells.append(tile_to_grid(cell))

	# 3. Kisten-Startpositionen aus dem TileMapLayer überführen und instanziieren
	box_cells.clear()
	for cell: Vector2i in box_spawner.get_used_cells():
		var grid_pos: Vector2i = tile_to_grid(cell)
		box_cells.append(grid_pos)

		var box := Sprite2D.new()
		box.texture = box_texture
		box.position = grid_to_world(grid_pos)
		boxes.add_child(box)
		update_box_target_state(box)
		print("Kiste initialisiert @ (row=%d, col=%d) | Welt: %s" % [grid_pos.x, grid_pos.y, box.position])

	box_spawner.visible = false

	create_win_label()

	# 4. Startposition des Spielers in unser Koordinatensystem überführen
	player_pos = world_to_grid(player.position)
	player.position = grid_to_world(player_pos)
	print("Spieler Startposition @ (row=%d, col=%d) | Welt: %s" % [player_pos.x, player_pos.y, player.position])


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_R or event.physical_keycode == KEY_R:
			reset_level()
			return

	for action: String in moves:
		if event.is_action_pressed(action):
			try_move(moves[action])
			break


func reset_level() -> void:
	get_tree().reload_current_scene()


# --- Spiellogik (vollständig im (row, col) Koordinatensystem) ---

func try_move(dir: Vector2i) -> void:
	# Nach dem Sieg sind keine Züge mehr erlaubt (Neustart mit R)
	if has_won:
		return

	var next_cell: Vector2i = player_pos + dir

	# 1. Wandprüfung
	if next_cell in wall_cells:
		return

	# 2. Kistenprüfung
	var box: Sprite2D = get_box_at(next_cell)
	if box != null:
		var behind: Vector2i = next_cell + dir
		if behind in wall_cells or get_box_at(behind) != null:
			return
		box.position = grid_to_world(behind)
		update_box_target_state(box)
		check_win()

	# 3. Spieler bewegen
	player_pos = next_cell
	player.position = grid_to_world(player_pos)
	print("Spieler bewegt zu @ (row=%d, col=%d) | Welt: %s" % [player_pos.x, player_pos.y, player.position])


func update_box_target_state(box: Sprite2D) -> void:
	if world_to_grid(box.position) in target_cells:
		box.modulate = Color(0.6, 1.2, 0.6)
	else:
		box.modulate = Color.WHITE


func get_box_at(grid_coord: Vector2i) -> Sprite2D:
	for b: Sprite2D in boxes.get_children():
		if world_to_grid(b.position) == grid_coord:
			return b
	return null


func check_win() -> void:
	for b: Sprite2D in boxes.get_children():
		var b_cell: Vector2i = world_to_grid(b.position)
		if not b_cell in target_cells:
			return
	has_won = true
	win_label.visible = true
	print("Gewonnen!")


# Erzeugt die Sieg-Anzeige (zunächst unsichtbar) als Overlay über dem Spiel
func create_win_label() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	win_label = Label.new()
	win_label.text = "Gewonnen!\nDrücke R für einen Neustart"
	win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	win_label.add_theme_font_size_override("font_size", 48)
	win_label.add_theme_color_override("font_color", Color.WHITE)
	win_label.add_theme_color_override("font_outline_color", Color.BLACK)
	win_label.add_theme_constant_override("outline_size", 12)
	win_label.visible = false
	layer.add_child(win_label)
