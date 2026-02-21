extends Control

signal pressed

var house: String
var character_name: String
var row: int
var col: int
var collected: bool = false
var protected_card: bool = false
var is_varys: bool = false

@onready var button: Button = $Button


# ===============================
# READY
# ===============================

func _ready():
	if button == null:
		push_error("Button node not found inside Card scene")
		return

	button.pressed.connect(_emit_pressed)


func _emit_pressed():
	if collected:
		return
	pressed.emit(self)


# ===============================
# SETUP
# ===============================

func set_character(name: String, house_name: String):

	character_name = name
	house = house_name

	if button != null:
		button.text = name

	apply_house_color()


# ===============================
# VARYS
# ===============================

func set_varys_mark(enabled: bool):

	if button == null:
		return

	is_varys = enabled

	if enabled:
		button.text = "V"
		button.modulate = Color(0.8, 0.8, 0.2)
	else:
		button.text = character_name
		apply_house_color()


# ===============================
# COLLECTION
# ===============================

func mark_collected():

	collected = true
	button.disabled = true
	button.modulate = Color(1, 0.3, 0.3) # אדום רך


func reset_visual():

	collected = false
	is_varys = false
	button.disabled = false
	button.text = character_name
	button.remove_theme_stylebox_override("normal")
	apply_house_color()


# ===============================
# COLORS
# ===============================

func apply_house_color():

	if button == null:
		return

	match house:

		"Stark":
			button.modulate = Color(0.75, 0.75, 0.75)

		"Lannister":
			button.modulate = Color(0.85, 0.25, 0.25)

		"Targaryen":
			button.modulate = Color(0.35, 0.1, 0.1)

		"Baratheon":
			button.modulate = Color(1.0, 0.9, 0.3)

		"Tyrell":
			button.modulate = Color(0.35, 0.75, 0.35)

		"Tully":
			button.modulate = Color(0.35, 0.55, 1.0)

		"Greyjoy":
			button.modulate = Color(0.2, 0.85, 0.8)

		"Varys":
			button.modulate = Color(0.9, 0.85, 0.3)

	button.add_theme_color_override("font_color", Color.WHITE)

func set_selected_visual(selected: bool):

	if selected:
		scale = Vector2(1.05, 1.05)

		var style := StyleBoxFlat.new()
		style.bg_color = button.modulate
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_width_top = 4
		style.border_width_bottom = 4
		style.border_color = Color.YELLOW
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6

		button.add_theme_stylebox_override("normal", style)
		
	else:
		scale = Vector2(1, 1)

		button.remove_theme_stylebox_override("normal")
		
		# מחזיר צבע בית רגיל
		apply_house_color()
	
# ===============================
# OPTIONAL
# ===============================

func set_protected():
	protected_card = true


func can_be_killed() -> bool:
	return not protected_card and not collected
