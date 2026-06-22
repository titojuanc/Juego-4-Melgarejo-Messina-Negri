extends Node3D

enum State {GHOST,CONSTRUCTING,ACTIVE,DESTROYED}

var building_type:int=-1
var state:int=State.GHOST
var build_timer:float=0.0
var build_time:float=0.0
var current_npcs:Array=[]
var max_npcs:int=0
var grid_cells:Array=[]

@onready var model=$Model
@onready var npc_spawn_point=$NPCSpawnPoint

func setup(type:int,cell_size:float=8.0)->void:
	building_type=type
	var data=BuildingDB.get_data(type)
	build_time=data["build_time"]
	max_npcs=data["max_npcs"]
	var gs:Vector2i=data["grid_size"]
	model.scale=Vector3(gs.x*cell_size,cell_size,gs.y*cell_size)

func start_construction()->void:
	state=State.CONSTRUCTING
	build_timer=0.0

func _process(delta:float)->void:
	if state==State.CONSTRUCTING:
		build_timer+=delta
		if build_timer>=build_time:
			state=State.ACTIVE
			_on_construction_complete()

func _on_construction_complete()->void:
	pass

func can_spawn_npc()->bool:
	return state==State.ACTIVE and current_npcs.size()<max_npcs

func get_spawn_position()->Vector3:
	return npc_spawn_point.global_position

func register_npc(npc:Node)->void:
	current_npcs.append(npc)

func unregister_npc(npc:Node)->void:
	current_npcs.erase(npc)
