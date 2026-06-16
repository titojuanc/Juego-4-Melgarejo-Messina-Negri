extends Node

@export var cell_data: NodePath
@export var ghost_building: NodePath

@onready var grid_manager=get_parent()

var current_building_scene: PackedScene = null
var is_placing: bool = false

func start_placement(building_scene: PackedScene) -> void:
	current_building_scene = building_scene
	is_placing = true

func confirm_placement(cell: Vector2i) -> void:
	if not is_placing:
		return
	var cd = get_node(cell_data)
	if cd.is_occupied(cell):
		return
	var building = current_building_scene.instantiate()
	get_node("PlacedBuildings").add_child(building)
	building.position = cell_to_world(cell)
	cd.set_occupied(cell, building)

func cancel_placement() -> void:
	is_placing = false
	current_building_scene = null

func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * grid_manager.cell_size, 0, cell.y * grid_manager.cell_size)
