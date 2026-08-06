extends Node3D

func _on_boton_jugar_boton_activado() -> void:
	get_tree().change_scene_to_file("res://scenes/Debug.tscn")
