extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Jugador"):
		return
	if body.has_method("agregar_cania"):
		body.agregar_cania()
	var drop_root := get_parent()
	if drop_root != null:
		drop_root.queue_free()
	else:
		queue_free()
