extends Node

@onready var grid_manager=get_parent()
@onready var _cell_data=grid_manager.get_node("CellData")
@onready var _ghost_building=$GhostBuilding
@onready var _placed_buildings=$PlacedBuildings

var current_building_scene:PackedScene=null
var is_placing:bool=false

func start_placement(building_scene:PackedScene)->void:
	current_building_scene=building_scene
	is_placing=true
	_ghost_building.visible=true
	# Clear old ghost children
	for child in _ghost_building.get_children():
		child.queue_free()
	# Add a preview instance
	var preview=building_scene.instantiate()
	_ghost_building.add_child(preview)

func move_ghost(cell:Vector2i)->void:
	_ghost_building.position=cell_to_world(cell)

func confirm_placement(cell:Vector2i)->void:
	if not is_placing:
		return
	if not _cell_data.cell_map.has(cell):
		return
	if _cell_data.is_occupied(cell):
		return
	var building=current_building_scene.instantiate()
	_placed_buildings.add_child(building)
	building.position=cell_to_world(cell)
	_cell_data.set_occupied(cell,building)

func cancel_placement()->void:
	is_placing=false
	current_building_scene=null
	_ghost_building.visible=false
	for child in _ghost_building.get_children():
		child.queue_free()

func cell_to_world(cell:Vector2i)->Vector3:
	var s=grid_manager.cell_size
	return Vector3(cell.x*s+s*0.5,0,cell.y*s+s*0.5)
