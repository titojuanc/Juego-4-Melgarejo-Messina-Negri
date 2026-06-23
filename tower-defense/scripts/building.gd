extends Node3D

enum State {GHOST,CONSTRUCTING,ACTIVE,DESTROYED}

var building_type:int=-1
var state:int=State.GHOST
var build_timer:float=0.0
var build_time:float=0.0
var current_npcs:Array=[]
var max_npcs:int=0
var grid_cells:Array=[]
var wall_variant:String="solo"

@onready var model=$Model
@onready var npc_spawn_point=$NPCSpawnPoint
@onready var npc_detect_area=$NPCDetectArea

func setup(type:int,cell_size:float=8.0)->void:
	building_type=type
	var data=BuildingDB.get_data(type)
	build_time=data["build_time"]
	max_npcs=data["max_npcs"]
	var gs:Vector2i=data["grid_size"]
	model.scale=Vector3(gs.x*cell_size,cell_size,gs.y*cell_size)
	if max_npcs>0:
		var shape=npc_detect_area.get_node("CollisionShape3D").shape as BoxShape3D
		shape.size=Vector3(gs.x*cell_size*1.2,cell_size,gs.y*cell_size*1.2)
	else:
		npc_detect_area.monitoring=false
		npc_detect_area.monitorable=false

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
	if max_npcs>0:
		npc_detect_area.monitoring=true
	var data=BuildingDB.get_data(building_type)
	var scene_to_use:PackedScene=null
	if data.has("wall_models"):
		scene_to_use=data["wall_models"][wall_variant]
	elif data.has("model_scene") and data["model_scene"]!=null:
		scene_to_use=data["model_scene"]
	if scene_to_use:
		var placeholder=model.get_node_or_null("Placeholder")
		if placeholder:
			placeholder.queue_free()
		model.scale=Vector3.ONE
		var m=scene_to_use.instantiate()
		model.add_child(m)

func can_spawn_npc()->bool:
	return state==State.ACTIVE and current_npcs.size()<max_npcs

func get_spawn_position()->Vector3:
	return npc_spawn_point.global_position

func register_npc(npc:Node)->void:
	current_npcs.append(npc)

func unregister_npc(npc:Node)->void:
	current_npcs.erase(npc)

func _on_npc_entered(body:Node3D)->void:
	if state!=State.ACTIVE:
		return
	if not body is CharacterBody3D:
		return
	if body.has_method("asignar_edificio"):
		if can_spawn_npc():
			register_npc(body)
			body.asignar_edificio(self)

func _on_npc_exited(body:Node3D)->void:
	if body in current_npcs:
		unregister_npc(body)
		if body.has_method("desasignar_edificio"):
			body.desasignar_edificio()
