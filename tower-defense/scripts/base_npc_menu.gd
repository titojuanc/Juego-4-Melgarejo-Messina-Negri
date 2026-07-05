extends CanvasLayer

var _building_manager:Node3D
var _tower_options:Array=[]
var _player:Node=null
var _opt_buttons:Array=[]

func initialize(bm:Node3D)->void:
	_building_manager=bm
	_player=get_tree().get_first_node_in_group("Jugador")
	if _player:
		_player.movimiento_bloqueado=true
	_tower_options=[]
	var placed=_building_manager.get_node("PlacedBuildings")
	for b in placed.get_children():
		if b.building_type==BuildingDB.BuildingType.TOWER and b.state==b.State.ACTIVE:
			_tower_options.append(b)
	_build_ui()

func _build_ui()->void:
	var panel=Panel.new()
	panel.custom_minimum_size=Vector2(380,0)
	add_child(panel)
	var vbox=VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT,Control.PRESET_MODE_MINSIZE,8)
	panel.add_child(vbox)
	var titulo=Label.new()
	titulo.text="Gestión de NPCs"
	titulo.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size",14)
	vbox.add_child(titulo)
	vbox.add_child(HSeparator.new())
	var scroll=ScrollContainer.new()
	scroll.custom_minimum_size=Vector2(0,180)
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	var npc_list=VBoxContainer.new()
	npc_list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(npc_list)
	var npcs=get_tree().get_nodes_in_group("Aliado")
	if npcs.is_empty():
		var lbl=Label.new()
		lbl.text="No hay NPCs aliados."
		lbl.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		npc_list.add_child(lbl)
	else:
		for npc in npcs:
			var row=HBoxContainer.new()
			row.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			npc_list.add_child(row)
			var name_lbl=Label.new()
			name_lbl.text=npc.nombre_npc
			name_lbl.custom_minimum_size=Vector2(80,0)
			name_lbl.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			row.add_child(name_lbl)
			if _tower_options.is_empty():
				var no_lbl=Label.new()
				no_lbl.text="Sin torres disponibles"
				no_lbl.add_theme_color_override("font_color",Color(0.6,0.6,0.6))
				row.add_child(no_lbl)
			else:
				var opt=OptionButton.new()
				opt.custom_minimum_size=Vector2(170,0)
				opt.add_item("Sin asignar",-1)
				for i in _tower_options.size():
					var t=_tower_options[i]
					opt.add_item("Torre %d  (%d/%d)" % [i+1,t.current_npcs.size(),t.max_npcs],i)
				var sel=0
				for i in _tower_options.size():
					if npc in _tower_options[i].current_npcs:
						sel=i+1
						break
				opt.selected=sel
				_opt_buttons.append(opt)
				row.add_child(opt)
				var btn=Button.new()
				btn.text="✓"
				btn.custom_minimum_size=Vector2(30,0)
				btn.pressed.connect(_on_assign.bind(npc,opt))
				row.add_child(btn)
	vbox.add_child(HSeparator.new())
	var close_btn=Button.new()
	close_btn.text="Cerrar"
	close_btn.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)
	await get_tree().process_frame
	var vp=get_viewport().get_visible_rect().size
	panel.position=Vector2(vp.x/2-panel.size.x/2,vp.y/2-panel.size.y/2)

func _on_assign(npc:Node,opt:OptionButton)->void:
	var idx=opt.get_selected_id()
	for t in _tower_options:
		if npc in t.current_npcs:
			t.unregister_npc(npc)
			break
	if idx==-1:
		npc.desasignar_torre()
	else:
		var tower=_tower_options[idx]
		if not tower.can_spawn_npc():
			return
		tower.register_npc(npc)
		npc.asignar_a_torre(tower)
	_refresh_opts()

func _refresh_opts()->void:
	for opt in _opt_buttons:
		for i in _tower_options.size():
			var t=_tower_options[i]
			opt.set_item_text(i+1,"Torre %d  (%d/%d)" % [i+1,t.current_npcs.size(),t.max_npcs])

func _on_close()->void:
	if _player:
		_player.movimiento_bloqueado=false
	queue_free()
