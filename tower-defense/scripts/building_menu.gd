extends Control

@onready var _building_manager=get_parent().get_parent().get_node("BuildingManager")
@onready var _btn_container=$VBoxContainer

var _buttons:Dictionary={}

func _ready()->void:
	for type in BuildingDB.buildings.keys():
		var btn=Button.new()
		btn.text=BuildingDB.buildings[type]["name"]
		btn.custom_minimum_size=Vector2(120,40)
		btn.pressed.connect(_on_button_pressed.bind(type))
		_btn_container.add_child(btn)
		_buttons[type]=btn
	var sep=HSeparator.new()
	_btn_container.add_child(sep)
	var remove_btn=Button.new()
	remove_btn.text="Remove"
	remove_btn.custom_minimum_size=Vector2(120,40)
	remove_btn.pressed.connect(_on_remove_pressed)
	_btn_container.add_child(remove_btn)
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

func can_afford(_type:int)->bool:
	# TODO: check player resources against BuildingDB.get_cost(type)
	return true

func _on_button_pressed(type:int)->void:
	_building_manager.start_placement(type)

func _on_remove_pressed()->void:
	_building_manager.start_remove()
