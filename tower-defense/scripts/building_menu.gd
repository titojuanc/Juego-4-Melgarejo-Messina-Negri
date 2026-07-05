extends Control

const _WOOD_TEX=preload("res://assets/materiales/Wood_-_Item_-_LEGO_Fortnite.png")
const _STONE_TEX=preload("res://assets/materiales/Icon_Stone.png")
const _METAL_TEX=preload("res://assets/materiales/Icon_IBeam.png")

@onready var _building_manager=get_parent().get_parent().get_node("BuildingManager")
@onready var _btn_container=$VBoxContainer

var _buttons:Dictionary={}

func _ready()->void:
	for type in BuildingDB.buildings.keys():
		if type==BuildingDB.BuildingType.BASE:
			continue
		var vbox=VBoxContainer.new()
		vbox.custom_minimum_size=Vector2(120,0)
		_btn_container.add_child(vbox)
		var btn=Button.new()
		btn.text=BuildingDB.buildings[type]["name"]
		btn.custom_minimum_size=Vector2(120,32)
		btn.pressed.connect(_on_button_pressed.bind(type))
		vbox.add_child(btn)
		_buttons[type]=btn
		var cost_row=HBoxContainer.new()
		cost_row.alignment=BoxContainer.ALIGNMENT_CENTER
		vbox.add_child(cost_row)
		var cost=BuildingDB.get_cost(type)
		for res_type in [BuildingDB.ResourceType.WOOD,BuildingDB.ResourceType.STONE,BuildingDB.ResourceType.METAL]:
			var amount=cost.get(res_type,0)
			if amount<=0:
				continue
			var pair=HBoxContainer.new()
			cost_row.add_child(pair)
			var icon=TextureRect.new()
			icon.custom_minimum_size=Vector2(16,16)
			icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
			icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
			match res_type:
				BuildingDB.ResourceType.WOOD: icon.texture=_WOOD_TEX
				BuildingDB.ResourceType.STONE: icon.texture=_STONE_TEX
				BuildingDB.ResourceType.METAL: icon.texture=_METAL_TEX
			pair.add_child(icon)
			var lbl=Label.new()
			lbl.text=str(amount)
			lbl.add_theme_font_size_override("font_size",11)
			pair.add_child(lbl)
	var sep=HSeparator.new()
	_btn_container.add_child(sep)
	var remove_btn=Button.new()
	remove_btn.text="Remove"
	remove_btn.custom_minimum_size=Vector2(120,40)
	remove_btn.pressed.connect(_on_remove_pressed)
	_btn_container.add_child(remove_btn)
	_building_manager.building_placed.connect(refresh)
	refresh()

func refresh()->void:
	for type in _buttons.keys():
		var btn=_buttons[type]
		var affordable=can_afford(type)
		btn.disabled=not affordable
		if affordable:
			btn.modulate=Color(1,1,1,1)
		else:
			btn.modulate=Color(0.5,0.5,0.5,1)

func can_afford(type:int)->bool:
	return _building_manager.can_afford(type)

func _on_button_pressed(type:int)->void:
	_building_manager.start_placement(type)

func _on_remove_pressed()->void:
	_building_manager.start_remove()
