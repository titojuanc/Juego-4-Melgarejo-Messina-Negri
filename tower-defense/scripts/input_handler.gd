extends Node

var _camera:Camera3D
var _grid_visual:Node3D
var _building_manager:Node3D
var _cell_data:Node
var _gm:Node3D
var current_cell:Vector2i=Vector2i(-1,-1)
var _dragging:bool=false
var _drag_start:Vector2i=Vector2i(-1,-1)

func _ready()->void:
	_gm=get_parent()
	_grid_visual=_gm.get_node("GridVisual")
	_building_manager=_gm.get_node("BuildingManager")
	_cell_data=_gm.get_node("CellData")

func _process(_delta:float)->void:
	_camera=get_viewport().get_camera_3d()
	if not _camera:
		return
	var cell=_get_cell_under_mouse()
	if cell!=current_cell:
		current_cell=cell
		_on_cell_hovered(cell)
		if _dragging and _is_valid_cell(cell):
			_update_drag_preview()

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _is_valid_cell(current_cell):
					if _is_drag_mode():
						_dragging=true
						_drag_start=current_cell
						_update_drag_preview()
					else:
						_click_action(current_cell)
			else:
				if _dragging:
					_confirm_drag()
					_dragging=false
					_drag_start=Vector2i(-1,-1)
					_grid_visual.hide_drag_area()
		elif event.button_index==MOUSE_BUTTON_RIGHT and event.pressed:
			_dragging=false
			_drag_start=Vector2i(-1,-1)
			_grid_visual.hide_drag_area()
			_building_manager.cancel_placement()
			_building_manager.cancel_remove()

func _is_drag_mode()->bool:
	if _building_manager.is_removing:
		return true
	if _building_manager.is_placing and _building_manager.current_type==BuildingDB.BuildingType.WALL:
		return true
	return false

func _click_action(cell:Vector2i)->void:
	if _building_manager.is_placing:
		_building_manager.confirm_placement(cell)
		_grid_visual.set_hover_color(_building_manager.can_place_at(cell))

func _update_drag_preview()->void:
	if not _is_valid_cell(current_cell):
		return
	var color:Color
	if _building_manager.is_removing:
		color=Color(1,0.2,0.2,0.35)
	else:
		color=Color(0.2,1,0.2,0.35)
	_grid_visual.show_drag_area(_drag_start,current_cell,color)

func _confirm_drag()->void:
	var min_x=mini(_drag_start.x,current_cell.x)
	var max_x=maxi(_drag_start.x,current_cell.x)
	var min_y=mini(_drag_start.y,current_cell.y)
	var max_y=maxi(_drag_start.y,current_cell.y)
	if _building_manager.is_placing and _building_manager.current_type==BuildingDB.BuildingType.WALL:
		var cells:Array[Vector2i]=[]
		var is_vertical:bool=(max_y-min_y)>(max_x-min_x)
		if is_vertical:
			for y in range(min_y,max_y+1):
				for x in range(min_x,max_x+1):
					var cell=Vector2i(x,y)
					if _is_valid_cell(cell):
						cells.append(cell)
		else:
			for x in range(min_x,max_x+1):
				for y in range(min_y,max_y+1):
					var cell=Vector2i(x,y)
					if _is_valid_cell(cell):
						cells.append(cell)
		_building_manager.confirm_wall_line(cells,is_vertical)
	else:
		for x in range(min_x,max_x+1):
			for y in range(min_y,max_y+1):
				var cell=Vector2i(x,y)
				if not _is_valid_cell(cell):
					continue
				if _building_manager.is_removing:
					_building_manager.remove_at(cell)
				elif _building_manager.is_placing:
					_building_manager.confirm_placement(cell)
	if _building_manager.is_placing and _is_valid_cell(current_cell):
		_grid_visual.set_hover_color(_building_manager.can_place_at(current_cell))

func _get_cell_under_mouse()->Vector2i:
	var mouse_pos:Vector2=get_viewport().get_mouse_position()
	var ray_origin:Vector3=_camera.project_ray_origin(mouse_pos)
	var ray_dir:Vector3=_camera.project_ray_normal(mouse_pos)
	if absf(ray_dir.y)<0.0001:
		return Vector2i(-1,-1)
	var plane_y=_gm.global_position.y
	var t:float=(plane_y-ray_origin.y)/ray_dir.y
	if t<0.0:
		return Vector2i(-1,-1)
	var world_pos:Vector3=ray_origin+ray_dir*t
	var local_x=world_pos.x-_gm.global_position.x
	var local_z=world_pos.z-_gm.global_position.z
	var cell:=Vector2i(int(floor(local_x/_gm.cell_size)),int(floor(local_z/_gm.cell_size)))
	return cell

func _is_valid_cell(cell:Vector2i)->bool:
	if not _cell_data.cell_map.has(cell):
		return false
	return cell.x>=0 and cell.x<_gm.grid_width and cell.y>=0 and cell.y<_gm.grid_height

func _on_cell_hovered(cell:Vector2i)->void:
	if not _is_valid_cell(cell):
		return
	if _building_manager.is_placing:
		var gs=BuildingDB.get_grid_size(_building_manager.current_type)
		_grid_visual.move_hover_cell(cell,_gm.cell_size,gs)
		_grid_visual.set_hover_color(_building_manager.can_place_at(cell))
		_building_manager.move_ghost(cell)
	else:
		_grid_visual.move_hover_cell(cell,_gm.cell_size)
