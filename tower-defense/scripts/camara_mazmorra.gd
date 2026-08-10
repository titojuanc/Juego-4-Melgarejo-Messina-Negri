extends Camera3D

## Offset de la camara respecto al centro de la tile
@export var offset: Vector3 = Vector3(0, 40, 50)
## Duracion de la transicion en segundos al cambiar de tile
@export var duracion_transicion: float = 0.4
## FOV (menor = mas zoom)
@export var fov_objetivo: float = 40.0

var _tween: Tween


func _ready() -> void:
	fov = fov_objetivo
	var mazmorra = get_parent()
	if mazmorra.has_signal("jugador_cambio_tile"):
		mazmorra.jugador_cambio_tile.connect(_on_jugador_cambio_tile)
	else:
		push_warning("camara_mazmorra: el padre no tiene la senal jugador_cambio_tile")


func _on_jugador_cambio_tile(centro_mundo: Vector3) -> void:
	var destino = centro_mundo + offset
	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "global_position", destino, duracion_transicion)
