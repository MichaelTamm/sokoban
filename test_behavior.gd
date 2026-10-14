extends SceneTree

func _init() -> void:
	var packed: PackedScene = load("res://level1.tscn")
	var scene: Node2D = packed.instantiate() as Node2D
	root.add_child(scene)
	
	await process_frame
	
	print("Checking initial box states...")
	var boxes_node: Node2D = scene.get_node("Boxes") as Node2D
	var on_target_count: int = 0
	for box: Sprite2D in boxes_node.get_children():
		var pos: Vector2i = scene.world_to_grid(box.position)
		var is_on_target: bool = pos in scene.target_cells
		print("Box at grid ", pos, " (target: ", is_on_target, ") modulate: ", box.modulate)
		if is_on_target:
			assert(box.modulate == Color(0.6, 1.2, 0.6), "Box on target should have green shimmer")
			on_target_count += 1
		else:
			assert(box.modulate == Color.WHITE, "Box not on target should be WHITE")
	
	assert(on_target_count == 1, "Expected exactly 1 box on target initially")
	print("Initial states verified successfully!")
	
	# Simulate moves
	scene.try_move(Vector2i(-1, 0)) # Move player to (4, 3)
	var box_to_push: Sprite2D = scene.get_box_at(Vector2i(3, 3))
	assert(box_to_push != null, "Box should be at (3, 3)")
	assert(box_to_push.modulate == Color.WHITE, "Box at (3, 3) should be WHITE before moving")
	
	scene.try_move(Vector2i(-1, 0)) # Push box to (2, 3), player at (3, 3)
	assert(box_to_push.position == scene.grid_to_world(Vector2i(2, 3)), "Box should have moved to (2, 3)")
	
	var box_on_target: Sprite2D = scene.get_box_at(Vector2i(2, 2))
	assert(box_on_target != null, "Box should be at (2, 2)")
	assert(box_on_target.modulate == Color(0.6, 1.2, 0.6), "Box at (2, 2) should have green shimmer")
	
	scene.try_move(Vector2i(0, -1)) # Move player to (3, 2)
	scene.try_move(Vector2i(-1, 0)) # Push box from (2, 2) to (1, 2)
	assert(box_on_target.modulate == Color.WHITE, "Box moved off target should be WHITE")
	print("Box moved off target became WHITE as expected!")
	
	box_on_target.position = scene.grid_to_world(Vector2i(2, 2))
	scene.update_box_target_state(box_on_target)
	assert(box_on_target.modulate == Color(0.6, 1.2, 0.6), "Box moved back to target should have green shimmer")
	print("Box moved back to target regained green shimmer!")

	print("ALL TESTS PASSED!")
	quit()
