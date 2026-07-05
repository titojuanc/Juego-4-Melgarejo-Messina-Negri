extends Node3D

const _BASE_NPC_MENU=preload("res://scripts/base_npc_menu.gd")

enum State {GHOST,CONSTRUCTING,ACTIVE,DESTROYED}

var building_type:int=-1
var state:int=State.GHOST
var build_timer:float=0.0
var build_time:float=0.0
var current_npcs:Array=[]
var max_npcs:int=0
var grid_cells:Array=[]
var wall_variant:String="solo"
var _npc_menu=null

@onready var model=$Model
@onready var npc_spawn_point=$NPCSpawnPoint
@onready var npc_detect_area=$NPCDetectArea
@onready var _collision_body=$CollisionBody

func setup(type:int,cell_size:float=8.0)->void:
	building_type=type
	var data=BuildingDB.get_data(type)
	build_time=data["build_time"]
	max_npcs=data["max_npcs"]
	var gs:Vector2i=data["grid_size"]
	model.scale=Vector3(gs.x*cell_size,cell_size,gs.y*cell_size)
	var col_node=_collision_body.get_node("CollisionShape3D")
	var col_shape=col_node.shape.duplicate() as BoxShape3D
	col_node.shape=col_shape
	var col_w=cell_size
	var col_d=cell_size
	if type==BuildingDB.BuildingType.BASE:
		col_w=2*cell_size
		col_d=2*cell_size
	col_shape.size=Vector3(col_w,cell_size,col_d)
	col_node.position=Vector3(0,cell_size*0.5,0)
	if max_npcs>0:
		var npc_col=npc_detect_area.get_node("CollisionShape3D")
		var npc_shape=npc_col.shape.duplicate() as BoxShape3D
		npc_col.shape=npc_shape
		npc_shape.size=Vector3(gs.x*cell_size*1.2,cell_size,gs.y*cell_size*1.2)
	else:
		npc_detect_area.monitoring=false
		npc_detect_area.monitorable=false

func start_construction()->void:
	state=State.CONSTRUCTING
	build_timer=0.0

func place_instantly()->void:
	state=State.ACTIVE
	_on_construction_complete()

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

func _unhandled_input(event:InputEvent)->void:
	if building_type!=BuildingDB.BuildingType.BASE:
		return
	if state!=State.ACTIVE:
		return
	if get_tree().paused:
		return
	if _npc_menu and is_instance_valid(_npc_menu):
		return
	if not event is InputEventMouseButton:
		return
	if event.button_index!=MOUSE_BUTTON_RIGHT or not event.pressed:
		return
	var camera=get_viewport().get_camera_3d()
	if not camera:
		return
	var space=get_world_3d().direct_space_state
	var origin=camera.project_ray_origin(event.position)
	var params=PhysicsRayQueryParameters3D.create(origin,origin+camera.project_ray_normal(event.position)*300.0)
	var result=space.intersect_ray(params)
	if result.is_empty():
		return
	if result["collider"].get_parent()!=self:
		return
	get_viewport().set_input_as_handled()
	_open_npc_menu()

func _open_npc_menu()->void:
	var bm=get_parent().get_parent()
	_npc_menu=_BASE_NPC_MENU.new()
	get_tree().root.add_child(_npc_menu)
	_npc_menu.initialize(bm)
	_npc_menu.tree_exiting.connect(func(): _npc_menu=null)
