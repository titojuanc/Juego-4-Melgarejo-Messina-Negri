extends Node3D

const BUILDING_SCENE=preload("res://scenes/buildings/Building.tscn")

@onready var grid_manager=get_parent()
@onready var _cell_data=grid_manager.get_node("CellData")
@onready var _ghost_building=$GhostBuilding
@onready var _placed_buildings=$PlacedBuildings

var current_type:int=-1
var is_placing:bool=false
var is_removing:bool=false

func start_placement(type:int)->void:
	cancel_remove()
	current_type=type
	is_placing=true
	_ghost_building.visible=true
	for child in _ghost_building.get_children():
		child.queue_free()
	var preview=BUILDING_SCENE.instantiate()
	_ghost_building.add_child(preview)
	preview.setup(type,grid_manager.cell_size)

func move_ghost(cell:Vector2i)->void:
	var gs=BuildingDB.get_grid_size(current_type)
	_ghost_building.position=cell_to_world(cell,gs)
	var valid=_can_place(cell,gs)
	_update_ghost_color(valid)

func _update_ghost_color(can_place:bool)->void:
	var preview=_ghost_building.get_child(0) if _ghost_building.get_child_count()>0 else null
	if not preview:
		return
	var mesh_inst=preview.get_node_or_null("Model/Placeholder")
	if not mesh_inst:
		return
	var mat=mesh_inst.material_override as StandardMaterial3D
	if not mat:
		return
	if can_place:
		mat.albedo_color=Color(0.2,0.8,0.2,0.5)
	else:
		mat.albedo_color=Color(0.8,0.2,0.2,0.5)
	mat.transparency=1

func can_place_at(cell:Vector2i)->bool:
	if not is_placing or current_type==-1:
		return false
	var gs=BuildingDB.get_grid_size(current_type)
	return _can_place(cell,gs)

func confirm_placement(cell:Vector2i)->void:
	if not is_placing:
		return
	var gs=BuildingDB.get_grid_size(current_type)
	if not _can_place(cell,gs):
		return
	var building=BUILDING_SCENE.instantiate()
	_placed_buildings.add_child(building)
	building.setup(current_type,grid_manager.cell_size)
	building.position=cell_to_world(cell,gs)
	building.start_construction()
	_occupy_cells(cell,gs,building)

func cancel_placement()->void:
	is_placing=false
	current_type=-1
	_ghost_building.visible=false
	for child in _ghost_building.get_children():
		child.queue_free()

func start_remove()->void:
	cancel_placement()
	is_removing=true

func cancel_remove()->void:
	is_removing=false

func remove_at(cell:Vector2i)->void:
	if not is_removing:
		return
	if not _cell_data.cell_map.has(cell):
		return
	if not _cell_data.is_occupied(cell):
		return
	var building=_cell_data.cell_map[cell]["building_ref"]
	_free_building_cells(building)
	building.queue_free()

func _free_building_cells(building:Node3D)->void:
	for key in _cell_data.cell_map.keys():
		if _cell_data.cell_map[key]["building_ref"]==building:
			_cell_data.clear_cell(key)

func cell_to_world(cell:Vector2i,gs:Vector2i)->Vector3:
	var s=grid_manager.cell_size
	return Vector3(cell.x*s+gs.x*s*0.5,0,cell.y*s+gs.y*s*0.5)

func _can_place(cell:Vector2i,gs:Vector2i)->bool:
	for x in gs.x:
		for y in gs.y:
			var c=Vector2i(cell.x+x,cell.y+y)
			if not _cell_data.cell_map.has(c):
				return false
			if _cell_data.is_occupied(c):
				return false
	return true

func _occupy_cells(cell:Vector2i,gs:Vector2i,building:Node3D)->void:
	for x in gs.x:
		for y in gs.y:
			_cell_data.set_occupied(Vector2i(cell.x+x,cell.y+y),building)
