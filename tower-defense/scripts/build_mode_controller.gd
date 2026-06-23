extends Node

signal build_mode_entered
signal build_mode_exited

var active:bool=false
var _camera:Camera3D
var _player:CharacterBody3D
var _grid_manager:Node3D
var _build_camera_offset:=Vector3(0,80,60)
var _build_camera_target:Vector3
var _lerp_speed:float=5.0
var _transitioning:bool=false
var _cam_speed:float=60.0

func _ready()->void:
	await get_tree().process_frame
	await get_tree().process_frame
	_player=get_tree().get_first_node_in_group("Jugador")
	_grid_manager=get_parent().get_node("GridManager")
	_camera=get_viewport().get_camera_3d()
	_grid_manager.get_node("GridVisual").visible=false
	_grid_manager.get_node("BuildingUI").layer=128
	_grid_manager.get_node("BuildingUI").visible=false
	_grid_manager.get_node("InputHandler").set_process(false)
	_grid_manager.get_node("InputHandler").set_process_unhandled_input(false)

func _unhandled_input(event:InputEvent)->void:
	if event.is_action_pressed("la_B"):
		if active:
			exit_build_mode()
		else:
			enter_build_mode()

func enter_build_mode()->void:
	if active:
		return
	active=true
	_transitioning=true
	_build_camera_target=_player.global_position+_build_camera_offset
	_player.movimiento_bloqueado=true
	_grid_manager.get_node("GridVisual").visible=true
	_grid_manager.get_node("BuildingUI").visible=true
	_grid_manager.get_node("InputHandler").set_process(true)
	_grid_manager.get_node("InputHandler").set_process_unhandled_input(true)
	build_mode_entered.emit()

func exit_build_mode()->void:
	if not active:
		return
	active=false
	_transitioning=false
	_grid_manager.get_node("BuildingManager").cancel_placement()
	_grid_manager.get_node("BuildingManager").cancel_remove()
	_grid_manager.get_node("GridVisual").visible=false
	_grid_manager.get_node("BuildingUI").visible=false
	_grid_manager.get_node("InputHandler").set_process(false)
	_grid_manager.get_node("InputHandler").set_process_unhandled_input(false)
	_player.movimiento_bloqueado=false
	_camera.global_position=_player.global_position+_player.camara_offset
	_camera.rotation.x=-0.5
	build_mode_exited.emit()

func _process(delta:float)->void:
	if active and not _transitioning:
		var move_dir=Vector3.ZERO
		if Input.is_action_pressed("la_W"):
			move_dir.z-=1
		if Input.is_action_pressed("la_S"):
			move_dir.z+=1
		if Input.is_action_pressed("la_A"):
			move_dir.x-=1
		if Input.is_action_pressed("la_D"):
			move_dir.x+=1
		if move_dir!=Vector3.ZERO:
			_camera.global_position+=move_dir.normalized()*_cam_speed*delta
		return
	if not _transitioning:
		return
	_camera.global_position=_camera.global_position.lerp(_build_camera_target,_lerp_speed*delta)
	_camera.rotation.x=lerp(_camera.rotation.x,-1.0,_lerp_speed*delta)
	if _camera.global_position.distance_to(_build_camera_target)<0.5:
		_transitioning=false
