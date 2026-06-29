extends CharacterBody3D

@export var speed: int = 10
@export var danio: int = 15
var direccion := Vector3.ZERO


func _ready() -> void:
	await get_tree().create_timer(3.0).timeout
	queue_free()
	
func _physics_process(delta: float) -> void:
	velocity = direccion * speed
	move_and_slide()
	
	if get_slide_collision_count() > 0:
		var collision = get_slide_collision(0)
		var body = collision.get_collider()
		if body.is_in_group("Enemigo"):
			if body.has_method("recibir_danio"):
				body.recibir_danio(danio)
			else:
				body.vida -= danio
		queue_free()
