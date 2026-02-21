extends Control

signal used(companion)

var id: String
var data: Dictionary

@onready var panel: Panel = $Panel
@onready var image: TextureRect = panel.find_child("TextureRect", true, false)
@onready var ability_label = get_node_or_null("Panel/Ability")
@onready var name_label = get_node_or_null("Panel/Name")
@onready var button: Button = $Button

func _ready():
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(_on_pressed)
	
func _on_pressed():
	print("Button pressed")
	used.emit(self)
	
func setup(companion_data: Dictionary):

	data = companion_data

	if not data.has("id"):
		push_error("Companion missing id")
		return

	id = data["id"]

	# ===== טקסטים =====
	if name_label:
		name_label.text = data.get("name", "")

	if ability_label:
		ability_label.text = data.get("ability_text", "")

	# ===== תמונה =====
	if data.has("texture") and data["texture"] != "":
		image.texture = load(data["texture"])
	else:
		image.texture = null

	# ===== עיצוב קלף =====
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.55, 0.1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0,0,0)

	panel.add_theme_stylebox_override("panel", style)

	if name_label:
		name_label.add_theme_color_override("font_color", Color.WHITE)

	if ability_label:
		ability_label.add_theme_color_override("font_color", Color.BLACK)

	button.flat = true
	button.modulate = Color(1,1,1,0)

# ===============================
# TESTING
# ===============================
#func _gui_input(event):
	#if event is InputEventMouseButton and event.pressed:
		#print("Companion node got click")
