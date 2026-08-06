extends Node3D

var volumen: float = 1.0
var resoluciones: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]
var resolucion_idx: int = 0

@onready var label_volumen: Label3D = $LabelVolumen
@onready var label_resolucion: Label3D = $LabelResolucion

func _ready() -> void:
	_actualizar_labels()

func _actualizar_labels() -> void:
	label_volumen.text = "%d%%" % int(volumen * 100)
	label_resolucion.text = "%dx%d" % [resoluciones[resolucion_idx].x, resoluciones[resolucion_idx].y]

func _on_boton_volver_boton_activado() -> void:
	get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func _on_boton_vol_menos_boton_activado() -> void:
	volumen = maxf(0.0, volumen - 0.1)
	AudioServer.set_bus_volume_db(0, linear_to_db(volumen))
	_actualizar_labels()

func _on_boton_vol_mas_boton_activado() -> void:
	volumen = minf(1.0, volumen + 0.1)
	AudioServer.set_bus_volume_db(0, linear_to_db(volumen))
	_actualizar_labels()

func _on_boton_res_menos_boton_activado() -> void:
	resolucion_idx = maxi(0, resolucion_idx - 1)
	DisplayServer.window_set_size(resoluciones[resolucion_idx])
	_actualizar_labels()

func _on_boton_res_mas_boton_activado() -> void:
	resolucion_idx = mini(resoluciones.size() - 1, resolucion_idx + 1)
	DisplayServer.window_set_size(resoluciones[resolucion_idx])
	_actualizar_labels()
