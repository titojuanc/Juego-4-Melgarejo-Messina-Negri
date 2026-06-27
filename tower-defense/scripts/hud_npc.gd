extends CanvasLayer

@onready var panel = $Panel
@onready var titulo_label = $Panel/VBoxContainer/TituloLabel
@onready var opciones_label = $Panel/VBoxContainer/OpcionesLabel
@onready var dialogo_label = $Panel/VBoxContainer/DialogoLabel

var texto_completo = ""
var char_index = 0
var velocidad_texto = 0.05 
var timer_texto = 0.0
var escribiendo = false

signal dialogo_terminado

func set_titulo(texto: String) -> void:
	titulo_label.text = texto

func set_opciones_texto(texto: String) -> void:
	opciones_label.text = texto
	dialogo_label.visible = false
	opciones_label.visible = true

func actualizar_posicion(pos_pantalla: Vector2) -> void:
	panel.position = pos_pantalla - panel.size / 2
	
func mostrar_dialogo(texto: String) -> void:
	print("mostrar_dialogo llamado: ", texto)
	texto_completo = texto
	char_index = 0
	dialogo_label.text = ""
	dialogo_label.visible = true
	opciones_label.visible = false
	escribiendo = true
	
func _physics_process(delta: float) -> void:
	if !escribiendo:
		return
	timer_texto += delta
	if timer_texto >= velocidad_texto:
		timer_texto = 0.0
		if char_index < texto_completo.length():
			char_index += 1
			dialogo_label.text = texto_completo.substr(0, char_index)
		else:
			escribiendo = false
			dialogo_terminado.emit()
