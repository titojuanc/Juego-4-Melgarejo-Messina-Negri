extends CanvasLayer

@onready var panel = $Panel
@onready var titulo_label = $Panel/VBoxContainer/TituloLabel
@onready var opciones_label = $Panel/VBoxContainer/OpcionesLabel

func set_titulo(texto: String) -> void:
	titulo_label.text = texto

func set_opciones_texto(texto: String) -> void:
	opciones_label.text = texto

func actualizar_posicion(pos_pantalla: Vector2) -> void:
	panel.position = pos_pantalla - panel.size / 2
