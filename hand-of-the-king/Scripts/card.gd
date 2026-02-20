extends Control

signal pressed

var house:String
@onready var button:Button = $Button

func _ready():
	if button == null:
		push_error("Button node not found inside Card scene")
		return
		
	button.pressed.connect(_emit_pressed)

func _emit_pressed():
	pressed.emit()

func set_house(h):
	house = h
	
	if button:
		button.text = house.substr(0,1)

func highlight(on:bool):
	if button:
		button.modulate = Color.YELLOW if on else Color.WHITE
