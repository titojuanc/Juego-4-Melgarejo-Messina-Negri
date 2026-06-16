extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var target = global_position + Vector3(3, 0, 0)
	nav_agent.target_position = target
	print("npc pos: ", global_position)
	print("target: ", target)

func _physics_process(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		print("navegacion terminada")
		return
	
	var next = nav_agent.get_next_path_position()
	print("next pos: ", next)
	var dir = (next - global_position).normalized()
	velocity = dir * 3.0
	move_and_slide()
