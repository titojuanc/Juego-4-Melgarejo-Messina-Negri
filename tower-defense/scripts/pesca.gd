extends CanvasLayer

var pool_restante:Array[String]=["llave","pez","pez","pez","pez"]
var item_actual:String=""

signal pesca_cerrada(item:String)

enum Fase {BOYA,RITMO,REVEAL}
var fase:Fase=Fase.BOYA
var transicionando:bool=false

const POPUP_W:=540.0
const POPUP_H:=560.0
const BOYA_TAM:=Vector2(28.0,28.0)
const TURB_TAM:=Vector2(80.0,80.0)
const TURB_G_TAM:=Vector2(140.0,140.0)
const MARGEN:=10.0
const TURB_MIN_Y:=40.0

@onready var fase1:Control=$PanelPopup/Fase1
@onready var boya:TextureRect=$PanelPopup/Fase1/Boya
@onready var turbulencia:ColorRect=$PanelPopup/Fase1/Turbulencia
@onready var barra_precision:ProgressBar=$PanelPopup/Fase1/BarraPrecision
@onready var hint_label:Label=$PanelPopup/Fase1/HintLabel

const BOYA_SPEED:=220.0
const TURB_SPEED_MIN:=55.0
const TURB_SPEED_MAX:=105.0
const RADIO_DETECCION:=65.0
const P_SUBE:=0.17
const P_BAJA:=0.26
const P_REQ:=0.85

var precision:float=0.0
var turb_pos:Vector2=Vector2.ZERO
var turb_vel:Vector2=Vector2.ZERO
var t_cambio_dir:float=0.0
var jalando:bool=false

@onready var fase2:Control=$PanelPopup/Fase2
@onready var turb_grande:ColorRect=$PanelPopup/Fase2/TurbulenciaGrande
@onready var linea_pesca:Line2D=$PanelPopup/Fase2/LineaPesca
@onready var nota_container:Control=$PanelPopup/Fase2/Carril/NotaContainer
@onready var zona_hit:ColorRect=$PanelPopup/Fase2/Carril/ZonaHit
@onready var resultado_label:Label=$PanelPopup/Fase2/ResultadoLabel

const VELOCIDAD_NOTA:=220.0
const Y_ZONA_HIT:=380.0
const ANCHO_CARRIL:=80.0
const ALTO_TAP:=18.0
const VENTANA_BIEN:=55.0

const PATRONES:Dictionary={
	"llave":[
		{"t":0.7,"tipo":0,"dur":0.0},
		{"t":1.05,"tipo":0,"dur":0.0},
		{"t":1.40,"tipo":0,"dur":0.0},
		{"t":2.30,"tipo":0,"dur":0.0},
		{"t":2.65,"tipo":0,"dur":0.0},
	],
	"pez":[
		{"t":0.7,"tipo":1,"dur":0.85},
		{"t":2.00,"tipo":0,"dur":0.0},
		{"t":2.70,"tipo":1,"dur":0.45},
	],
}

var patron:Array=[]
var tiempo_ritmo:float=0.0
var indice_spawn:int=0
var notas_activas:Array=[]
var aciertos:int=0
var fallos:int=0
var input_abajo:bool=false
var nota_hold_activa=null

@onready var panel_reveal:Control=$PanelPopup/Reveal
@onready var sprite_reveal:TextureRect=$PanelPopup/Reveal/Sprite
@onready var texto_reveal:Label=$PanelPopup/Reveal/Texto
@onready var boton_cerrar:Button=$PanelPopup/Reveal/BotonCerrar

@export var tex_fish:Texture2D
@export var tex_llave:Texture2D
@export var test_mode:bool=false

func _ready()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	visible=false
	boton_cerrar.pressed.connect(_on_boton_cerrar)
	if test_mode:
		abrir(pool_restante.duplicate())

func abrir(pool:Array)->void:
	if pool.is_empty():
		return
	pool_restante=pool.duplicate()
	transicionando=false
	if not test_mode:
		get_tree().paused=true
	visible=true
	_ir_a_boya()

func _on_boton_cerrar()->void:
	visible=false
	if not test_mode:
		get_tree().paused=false
	pesca_cerrada.emit(item_actual)

func _ir_a_boya()->void:
	fase=Fase.BOYA
	transicionando=false
	fase1.visible=true
	fase2.visible=false
	panel_reveal.visible=false

	precision=0.5
	jalando=false
	nota_hold_activa=null

	boya.position=Vector2(POPUP_W/2-BOYA_TAM.x/2,POPUP_H/2-BOYA_TAM.y/2)
	turb_pos=Vector2(randf_range(MARGEN+TURB_TAM.x,POPUP_W-TURB_TAM.x*2-MARGEN),randf_range(TURB_MIN_Y+TURB_TAM.y,POPUP_H-TURB_TAM.y*2-MARGEN))
	turbulencia.position=turb_pos
	_nueva_vel_turb()

func _proceso_boya(delta:float)->void:
	var dir:=Vector2(Input.get_axis("la_A","la_D"),Input.get_axis("la_W","la_S"))
	var centro_boya:=boya.position+BOYA_TAM/2
	centro_boya+=dir*BOYA_SPEED*delta
	centro_boya=centro_boya.clamp(BOYA_TAM/2,Vector2(POPUP_W,POPUP_H)-BOYA_TAM/2)
	boya.position=centro_boya-BOYA_TAM/2
	if jalando:
		var destino:=Vector2(POPUP_W/2-TURB_TAM.x/2,POPUP_H-TURB_TAM.y-MARGEN)
		turb_pos=turb_pos.move_toward(destino,200.0*delta)
		turbulencia.position=turb_pos
		if turb_pos.distance_to(destino)<4.0:
			_ir_a_ritmo()
			return
	else:
		t_cambio_dir-=delta
		if t_cambio_dir<=0.0:
			_nueva_vel_turb()
		turb_pos+=turb_vel*delta
		if turb_pos.x<MARGEN or turb_pos.x>POPUP_W-TURB_TAM.x-MARGEN:
			turb_vel.x=-turb_vel.x
			turb_pos.x=clamp(turb_pos.x,MARGEN,POPUP_W-TURB_TAM.x-MARGEN)
		if turb_pos.y<TURB_MIN_Y or turb_pos.y>POPUP_H-TURB_TAM.y-MARGEN:
			turb_vel.y=-turb_vel.y
			turb_pos.y=clamp(turb_pos.y,TURB_MIN_Y,POPUP_H-TURB_TAM.y-MARGEN)
		turbulencia.position=turb_pos
	var c_boya:=boya.position+BOYA_TAM/2
	var c_turb:=turb_pos+TURB_TAM/2
	if c_boya.distance_to(c_turb)<RADIO_DETECCION:
		precision=min(precision+P_SUBE*delta,1.0)
	else:
		precision=max(precision-P_BAJA*delta,0.0)
	barra_precision.value=precision
	if precision<=0.0 and not transicionando:
		_cerrar_sin_item()
		return

	var puede_jalar:=precision>=P_REQ
	var boton_jalar:=Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_SPACE)
	jalando=puede_jalar and boton_jalar
	hint_label.visible=puede_jalar and not jalando

func _nueva_vel_turb()->void:
	var ang:=randf_range(0.0,TAU)
	var spd:=randf_range(TURB_SPEED_MIN,TURB_SPEED_MAX)
	turb_vel=Vector2(cos(ang),sin(ang))*spd
	t_cambio_dir=randf_range(1.0,2.5)

func _ir_a_ritmo()->void:
	if pool_restante.is_empty():
		_cerrar_sin_item()
		return

	fase=Fase.RITMO
	fase1.visible=false
	fase2.visible=true
	panel_reveal.visible=false
	transicionando=false
	var idx:=randi()%pool_restante.size()
	item_actual=pool_restante[idx]

	patron=(PATRONES.get(item_actual,PATRONES["pez"]) as Array).duplicate(true)
	tiempo_ritmo=0.0
	indice_spawn=0
	aciertos=0
	fallos=0
	input_abajo=false
	nota_hold_activa=null
	resultado_label.visible=false
	for entry in notas_activas:
		if is_instance_valid(entry.rect):
			entry.rect.queue_free()
	notas_activas.clear()
	turb_grande.position=Vector2(POPUP_W/2-TURB_G_TAM.x/2,POPUP_H-TURB_G_TAM.y-40.0)
	var mat:=turb_grande.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensidad",2.2)

	_actualizar_linea()

func _proceso_ritmo(delta:float)->void:
	tiempo_ritmo+=delta
	var tiempo_caida:=Y_ZONA_HIT/VELOCIDAD_NOTA
	while indice_spawn<patron.size():
		var nd:Dictionary=patron[indice_spawn]
		if tiempo_ritmo>=nd.t-tiempo_caida:
			_spawnear_nota(nd)
			indice_spawn+=1
		else:
			break
	for entry in notas_activas.duplicate():
		var r:=entry["rect"] as ColorRect
		if not is_instance_valid(r):
			notas_activas.erase(entry)
			continue

		r.position.y+=VELOCIDAD_NOTA*delta
		var bottom:float=r.position.y+r.size.y
		if not bool(entry["golpeada"]) and not bool(entry["finalizada"]) and bottom>Y_ZONA_HIT+VENTANA_BIEN:
			_nota_fallida(entry)
			continue
		var tipo_entry:int=int((entry["data"] as Dictionary).get("tipo",0))
		if bool(entry["golpeada"]) and tipo_entry==1 and not bool(entry["finalizada"]):
			if r.position.y>Y_ZONA_HIT+VENTANA_BIEN:
				if input_abajo:
					_nota_acertada(entry)
				else:
					_nota_fallida(entry)

	if not transicionando and indice_spawn>=patron.size() and notas_activas.is_empty():
		_terminar_ritmo()
	_actualizar_linea()

func _spawnear_nota(nd:Dictionary)->void:
	var alto:float
	if nd.tipo==0:
		alto=ALTO_TAP
	else:
		alto=nd.dur*VELOCIDAD_NOTA+ALTO_TAP

	var rect:=ColorRect.new()
	rect.size=Vector2(ANCHO_CARRIL-8.0,alto)
	var tiempo_caida:=Y_ZONA_HIT/VELOCIDAD_NOTA
	var retraso:float=max(0.0,tiempo_ritmo-(float(nd["t"])-tiempo_caida))
	rect.position=Vector2(4.0,-alto+retraso*VELOCIDAD_NOTA)
	if nd["tipo"]==0:
		rect.color=Color(0.85,0.92,1.0,0.95)
	else:
		rect.color=Color(0.35,0.75,1.0,0.88)
		var head:=ColorRect.new()
		head.color=Color(1.0,1.0,1.0,0.95)
		head.size=Vector2(ANCHO_CARRIL-8.0,ALTO_TAP)
		head.position=Vector2(0.0,alto-ALTO_TAP)
		rect.add_child(head)
	nota_container.add_child(rect)
	notas_activas.append({
		"rect":rect,
		"data":nd,
		"golpeada":false,
		"finalizada":false,
	})

func _intentar_golpe()->void:
	var mejor_entry=null
	var mejor_dist:=INF

	for entry in notas_activas:
		if entry.golpeada or entry.finalizada:
			continue
		var bottom:float=entry.rect.position.y+entry.rect.size.y
		var dist:float=abs(bottom-Y_ZONA_HIT)
		if dist<mejor_dist and dist<VENTANA_BIEN:
			mejor_dist=dist
			mejor_entry=entry

	if mejor_entry==null:
		return

	var tipo_mejor:int=int((mejor_entry["data"] as Dictionary).get("tipo",0))
	if tipo_mejor==0:
		mejor_entry["golpeada"]=true
		_nota_acertada(mejor_entry)
	else:
		mejor_entry["golpeada"]=true
		nota_hold_activa=mejor_entry

func _soltar_hold()->void:
	if nota_hold_activa==null:
		return
	var entry=nota_hold_activa
	nota_hold_activa=null
	if not entry.finalizada and entry.rect.position.y<=Y_ZONA_HIT+VENTANA_BIEN:
		_nota_fallida(entry)

func _nota_acertada(entry:Dictionary)->void:
	if entry.finalizada:
		return
	entry.finalizada=true
	if nota_hold_activa==entry:
		nota_hold_activa=null
	aciertos+=1
	var r:=entry["rect"] as ColorRect
	r.color=Color(1.0,1.0,1.0,1.0)
	var tw:=get_tree().create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_interval(0.12)
	tw.tween_property(r,"modulate:a",0.0,0.3)
	tw.tween_callback(r.queue_free)
	notas_activas.erase(entry)

func _nota_fallida(entry:Dictionary)->void:
	if entry.finalizada:
		return
	entry.finalizada=true
	if nota_hold_activa==entry:
		nota_hold_activa=null
	fallos+=1
	var r:=entry["rect"] as ColorRect
	r.color=Color(1.0,0.22,0.22,0.80)
	_animar_y_borrar(r)
	notas_activas.erase(entry)
	if not transicionando and fallos>int(patron.size()*0.5):
		_pez_escapa()

func _animar_y_borrar(rect:ColorRect)->void:
	var tw:=get_tree().create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(rect,"modulate:a",0.0,0.3)
	tw.tween_callback(rect.queue_free)

func _pez_escapa()->void:
	transicionando=true
	for entry in notas_activas.duplicate():
		if is_instance_valid(entry.rect):
			_animar_y_borrar(entry.rect)
	notas_activas.clear()
	await get_tree().create_timer(0.3).timeout
	resultado_label.text="¡Escapó!"
	resultado_label.visible=true
	await get_tree().create_timer(1.2).timeout
	resultado_label.visible=false
	_ir_a_boya()

func _terminar_ritmo()->void:
	transicionando=true
	var total:=patron.size()
	var pct:float
	if total>0:
		pct=float(aciertos)/float(total)
	else:
		pct=0.0

	if pct>=0.6:
		pool_restante.erase(item_actual)
		await get_tree().create_timer(0.25).timeout
		_mostrar_reveal()
	else:
		resultado_label.text="¡Se escapó!"
		resultado_label.visible=true
		await get_tree().create_timer(1.2).timeout
		resultado_label.visible=false
		_ir_a_boya()

func _actualizar_linea()->void:
	linea_pesca.set_point_position(0,Vector2(POPUP_W/2,0.0))
	linea_pesca.set_point_position(1,turb_grande.position+TURB_G_TAM/2)


func _mostrar_reveal()->void:
	fase=Fase.REVEAL
	fase1.visible=false
	fase2.visible=false
	panel_reveal.visible=true

	if item_actual=="llave":
		sprite_reveal.texture=tex_llave
		texto_reveal.text="¡Encontraste una llave!"
		var jugador=get_tree().get_first_node_in_group("Jugador")
		if jugador:
			jugador.agregar_llave()
	else:
		sprite_reveal.texture=tex_fish
		texto_reveal.text="Era un pez.\nDevuelto al agua."

func _cerrar_sin_item()->void:
	visible=false
	get_tree().paused=false
	pesca_cerrada.emit("")

func _process(delta:float)->void:
	if not visible or transicionando:
		return
	match fase:
		Fase.BOYA:_proceso_boya(delta)
		Fase.RITMO:_proceso_ritmo(delta)

func _input(event:InputEvent)->void:
	if not visible:
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled()
	if fase!=Fase.RITMO:
		return
	if not event is InputEventKey:
		return
	var ke:=event as InputEventKey
	if ke.keycode==KEY_SPACE or ke.keycode==KEY_E:
		if ke.pressed and not ke.echo:
			input_abajo=true
			_intentar_golpe()
		elif not ke.pressed:
			input_abajo=false
			_soltar_hold()
