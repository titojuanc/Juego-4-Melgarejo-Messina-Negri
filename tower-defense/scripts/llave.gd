extends Area3D

# Esta escena representa una llave física en el mundo que el jugador puede recoger.
# NOTA: En el futuro, la llave se obtendrá principalmente a través de la pesca.
# Para eso, no instanciar esta escena sino llamar directamente jugador.agregar_llave()
# desde la lógica de pesca cuando corresponda.

func _ready() -> void:
	$AnimatedSprite3D.play("idle")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Jugador"):
		body.agregar_llave()
		queue_free()
