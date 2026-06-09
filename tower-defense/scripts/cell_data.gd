extends Node

var cell_map: Dictionary = {}

func initialize(grid_width:int,grid_height:int)->void:
	for x in grid_width:
		for z in grid_height:
			cell_map[Vector2i(x,z)]={
				"occupied":false,
				"building_ref":null,
				"terrain_type":0,
				"passable":true
			}

func is_occupied(cell:Vector2i) -> bool:
	return cell_map[cell]["occupied"]

func set_occupied(cell:Vector2i,building:Node3D) -> void:
	cell_map[cell]["occupied"]=true
	cell_map[cell]["building_ref"]=building

func clear_cell(cell:Vector2i)->void:
	cell_map[cell]["occupied"]=false
	cell_map[cell]["building_ref"]=null
