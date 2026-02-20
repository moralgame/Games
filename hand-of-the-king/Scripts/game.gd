extends Control

@onready var grid = $CenterContainer/GridContainer
var varys_card = null
var houses = ["Stark","Greyjoy","Targaryen","Baratheon","Tyrell","Tully"]
var selected_house = "Stark"

func _ready():
	generate_board()
	place_varys()

func generate_board():
	for i in range(36):
		var card = preload("res://card.tscn").instantiate()

		var house = houses.pick_random()
		card.set_house(house)

		card.pressed.connect(on_card_pressed.bind(card))
		grid.add_child(card)
		
func place_varys():
	var index = randi() % grid.get_child_count()
	varys_card = grid.get_child(index)
	set_varys(varys_card)

func set_varys(card):
	if varys_card:
		varys_card.highlight(false)

	varys_card = card
	varys_card.button.text = "V"
	varys_card.highlight(true)

func on_card_pressed(card):
	if not is_valid_move(card):
		return

	collect_cards_between(varys_card, card)
	set_varys(card)
		
func is_valid_move(target):
	var cards = grid.get_children()
	var current_index = cards.find(varys_card)
	var target_index = cards.find(target)

	var current_row = current_index / 6
	var current_col = current_index % 6

	var target_row = target_index / 6
	var target_col = target_index % 6

	return current_row == target_row or current_col == target_col
	
func collect_cards_between(from_card, to_card):
	var cards = grid.get_children()

	var from_i = cards.find(from_card)
	var to_i = cards.find(to_card)

	var from_row = from_i / 6
	var from_col = from_i % 6

	var to_row = to_i / 6
	var to_col = to_i % 6

	if from_row == to_row:
		var start = min(from_col, to_col)
		var end = max(from_col, to_col)

		for c in range(start, end + 1):
			var index = from_row * 6 + c
			var card = cards[index]
			if card != varys_card and card.house == selected_house:
				card.queue_free()

	elif from_col == to_col:
		var start = min(from_row, to_row)
		var end = max(from_row, to_row)

		for r in range(start, end + 1):
			var index = r * 6 + from_col
			var card = cards[index]
			if card != varys_card and card.house == selected_house:
				card.queue_free()
