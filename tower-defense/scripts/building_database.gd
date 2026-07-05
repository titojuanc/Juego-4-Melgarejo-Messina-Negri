extends Node

enum BuildingType {TOWER,WALL,BASE}
enum ResourceType {WOOD,STONE,METAL}

var buildings:Dictionary={
	BuildingType.TOWER:{
		"name":"Tower",
		"grid_size":Vector2i(2,2),
		"cost":{ResourceType.WOOD:0,ResourceType.STONE:0,ResourceType.METAL:0},
		"build_time":8.0,
		"max_npcs":2,
		"model_scene":preload("res://scenes/buildings/madera/tower_model.tscn"),
	},
	BuildingType.WALL:{
		"name":"Wall",
		"grid_size":Vector2i(1,1),
		"cost":{ResourceType.WOOD:10,ResourceType.STONE:10,ResourceType.METAL:0},
		"build_time":3.0,
		"max_npcs":0,
		"wall_models":{
			"solo":preload("res://scenes/buildings/madera/wall_model.tscn"),
			"left":preload("res://scenes/buildings/madera/wall_left_model.tscn"),
			"middle":preload("res://scenes/buildings/madera/wall_transition_model.tscn"),
			"right":preload("res://scenes/buildings/madera/wall_right_model.tscn"),
		},
	},
	BuildingType.BASE:{
		"name":"Base",
		"grid_size":Vector2i(4,4),
		"cost":{ResourceType.WOOD:100,ResourceType.STONE:80,ResourceType.METAL:50},
		"build_time":15.0,
		"max_npcs":0,
		"model_scene":preload("res://scenes/buildings/madera/base_model.tscn"),
	},
}

func get_data(type:BuildingType)->Dictionary:
	return buildings[type]

func get_cost(type:BuildingType)->Dictionary:
	return buildings[type]["cost"]

func get_building_name(type:BuildingType)->String:
	return buildings[type]["name"]

func get_grid_size(type:BuildingType)->Vector2i:
	return buildings[type]["grid_size"]

func get_max_npcs(type:BuildingType)->int:
	return buildings[type]["max_npcs"]
