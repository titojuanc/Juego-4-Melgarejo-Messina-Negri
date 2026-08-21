extends Node3D

func _on_boton_jugar_boton_activado() -> void:
	if Gamestate.has_method("reset_jugador"):
		Gamestate.reset_jugador()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func _on_boton_opciones_boton_activado() -> void:
	get_tree().change_scene_to_file("res://scenes/Opciones.tscn")
