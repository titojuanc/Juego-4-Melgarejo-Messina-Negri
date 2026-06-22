extends Node3D

@export var grid_width:int=20
@export var grid_height:int=20
@export var cell_size:float=8.0
@export var world_gridmap_path:NodePath
@export var grid_y_offset:float=1.05

@onready var cell_data=$CellData
@onready var building_manager=$BuildingManager
@onready var input_handler=$InputHandler
@onready var grid_visual=$GridVisual

var _world_gridmap:GridMap
var _grid_origin:Vector3=Vector3.ZERO

func _ready()->void:
	await get_tree().process_frame
	if world_gridmap_path!=NodePath("") and has_node(world_gridmap_path):
		_world_gridmap=get_node(world_gridmap_path)
		_setup_from_world()
	else:
		_setup_standalone()

func _setup_from_world()->void:
	var used=_world_gridmap.get_used_cells()
	if used.is_empty():
		_setup_standalone()
		return
	var wcs=_world_gridmap.cell_size
	var min_x:int=999999
	var max_x:int=-999999
	var min_z:int=999999
	var max_z:int=-999999
	for cell in used:
		if cell.x<min_x: min_x=cell.x
		if cell.x>max_x: max_x=cell.x
		if cell.z<min_z: min_z=cell.z
		if cell.z>max_z: max_z=cell.z
	var tiles_per_cell:int=int(wcs.x/cell_size)
	grid_width=(max_x-min_x+1)*tiles_per_cell
	grid_height=(max_z-min_z+1)*tiles_per_cell
	var half_tile_x=wcs.x*0.5
	var half_tile_z=wcs.z*0.5
	_grid_origin=Vector3(min_x*wcs.x-half_tile_x,grid_y_offset,min_z*wcs.z-half_tile_z)
	global_position=_grid_origin
	cell_data.initialize(grid_width,grid_height)
	grid_visual.draw_grid(grid_width,grid_height,cell_size)
	_mark_unbuildable_cells(used,min_x,min_z,tiles_per_cell)

func _setup_standalone()->void:
	global_position.y=grid_y_offset
	cell_data.initialize(grid_width,grid_height)
	grid_visual.draw_grid(grid_width,grid_height,cell_size)

func _mark_unbuildable_cells(used:Array[Vector3i],min_x:int,min_z:int,tiles_per_cell:int)->void:
	var valid_set:Dictionary={}
	for cell in used:
		var item_id=_world_gridmap.get_cell_item(cell)
		var item_name=_world_gridmap.mesh_library.get_item_name(item_id)
		if item_name=="TileAgua":
			continue
		var bx=(cell.x-min_x)*tiles_per_cell
		var bz=(cell.z-min_z)*tiles_per_cell
		for x in tiles_per_cell:
			for z in tiles_per_cell:
				valid_set[Vector2i(bx+x,bz+z)]=true
	for x in grid_width:
		for z in grid_height:
			var c=Vector2i(x,z)
			if not valid_set.has(c):
				if cell_data.cell_map.has(c):
					cell_data.cell_map[c]["passable"]=false
					cell_data.cell_map[c]["occupied"]=true
	_mark_resource_cells(min_x,min_z,tiles_per_cell)

func _mark_resource_cells(min_x:int,min_z:int,tiles_per_cell:int)->void:
	var recursos_node=_world_gridmap.get_node_or_null("RecursosSpawn")
	if not recursos_node:
		return
	for child in recursos_node.get_children():
		var pos=child.global_position
		var local_x=pos.x-global_position.x
		var local_z=pos.z-global_position.z
		var cx=int(floor(local_x/cell_size))
		var cz=int(floor(local_z/cell_size))
		var c=Vector2i(cx,cz)
		if cell_data.cell_map.has(c):
			cell_data.cell_map[c]["occupied"]=true
