extends Control

# ===== Game nodes =====
@onready var grid: GridContainer = $Game/MainRow/CenterPanel/VBoxContainer/CenterContainer/GridContainer
@onready var companions_bar: HBoxContainer = $Game/MainRow/CenterPanel/VBoxContainer/CompanionsBar
@onready var house_dialog: AcceptDialog = $Game/HouseCompletedDialog
@onready var companion_confirm_dialog = $Game/CompanionConfirmDialog
@onready var player1_banners = $Game/MainRow/Player1Panel/BannerList
@onready var player2_banners = $Game/MainRow/Player2Panel/BannerList
@onready var turn_label = $Game/TurnBanner/TurnLabel

# ===== Jon Snow Dialog =====
@onready var jon_dialog = $Game/JonSnowDialog
@onready var jon_houses_list = $Game/JonSnowDialog/VBoxContainer/HousesList

# ===== Kill Confirm =====
@onready var kill_confirm_dialog = $Game/KillConfirmDialog

# ===== Overlay =====
@onready var game_over_panel = $GameOverPanel
@onready var game_over_label = $GameOverPanel/CenterContainer/ResultPanel/VBoxContainer/GameOverLabel
@onready var winner_label = $GameOverPanel/CenterContainer/ResultPanel/VBoxContainer/WinnerLabel
@onready var restart_button = $GameOverPanel/CenterContainer/ResultPanel/VBoxContainer/RestartButton

const CARD_SCENE = preload("res://card.tscn")
const COMPANION_SCENE = preload("res://companion.tscn")

# ===============================
# GAME STATE
# ===============================

enum GameState {
	NORMAL_TURN,
	COMPANION_SELECTION,
	ABILITY_TARGETING
}

#var engine = GameEngine.new()
var varys_card = null
var ability_mode = null
var first_selected_card = null
var pending_companion = null
var companion_deck = []
var active_companions = []
var last_completed_house = ""
var current_player = 1   # 1 = Player1, 2 = Player2
var board_cards = []
var game_finished: bool = false
var selecting_player = false
var selecting_house = false
var selected_cards: Array = []
var kill_selected_card = null
var swap_confirm_button: Button
var player_panels = []


# ===== GAME STATE =====
var game_state: GameState = GameState.NORMAL_TURN

# ===== JON SNOW STATE =====
var jon_selected_house: String = ""
var jon_selection_active := false

# ===============================
# FULL DECK (36 CARDS)
# ===============================

var ALL_CARDS = [

	# STARK (8)
	{ name="Eddard", house="Stark" },
	{ name="Catelyn", house="Stark" },
	{ name="Robb", house="Stark" },
	{ name="Sansa", house="Stark" },
	{ name="Arya", house="Stark" },
	{ name="Bran", house="Stark" },
	{ name="Rickon", house="Stark" },
	{ name="Jon Snow", house="Stark" },

	# LANNISTER (7)
	{ name="Tywin", house="Lannister" },
	{ name="Cersei", house="Lannister" },
	{ name="Jaime", house="Lannister" },
	{ name="Tyrion", house="Lannister" },
	{ name="Joffrey", house="Lannister" },
	{ name="Myrcella", house="Lannister" },
	{ name="Tommen", house="Lannister" },

	# TARGARYEN (6)
	{ name="Daenerys", house="Targaryen" },
	{ name="Viserys", house="Targaryen" },
	{ name="Drogon", house="Targaryen" },
	{ name="Rhaegal", house="Targaryen" },
	{ name="Viserion", house="Targaryen" },
	{ name="Jorah", house="Targaryen" },

	# BARATHEON (5)
	{ name="Robert", house="Baratheon" },
	{ name="Stannis", house="Baratheon" },
	{ name="Renly", house="Baratheon" },
	{ name="Shireen", house="Baratheon" },
	{ name="Gendry", house="Baratheon" },

	# TYRELL (4)
	{ name="Olenna", house="Tyrell" },
	{ name="Mace", house="Tyrell" },
	{ name="Margaery", house="Tyrell" },
	{ name="Loras", house="Tyrell" },

	# TULLY (3)
	{ name="Hoster", house="Tully" },
	{ name="Edmure", house="Tully" },
	{ name="Blackfish", house="Tully" },

	# GREYJOY (2)
	{ name="Balon", house="Greyjoy" },
	{ name="Theon", house="Greyjoy" },

	# VARYS
	{ name="Varys", house="Varys" }
]

const COMPANIONS_POOL = [

	# 1
	{
		id="sandor",
		name="Sandor Clegane",
		type="board_target",
		ability="kill_one",
		ability_text="Kill one character on the board."
	},

	# 2
	{
		id="ramsay",
		name="Ramsay Snow",
		type="board_double_target",
		ability="swap_two",
		ability_text="Swap two characters on the board."
	},

	# 3
	{
		id="jon",
		name="Jon Snow",
		type="house_target",
		ability="house_bonus",
		ability_text="Choose a house. Gain +1 for banner calculation."
	},

	# 4
	{
		id="drogo",
		name="Khal Drogo",
		type="instant",
		ability="take_daenerys",
		ability_text="Take Daenerys from the board."
	},

	# 5
	{
		id="jaqen",
		name="Jaqen H'ghar",
		type="board_target",
		ability="kill_extra_turn",
		ability_text="Kill one character and take another turn."
	},

	# 6
	{
		id="melisandre",
		name="Melisandre",
		type="board_target",
		ability="take_one",
		ability_text="Recruit one character directly from the board."
	},

	# 7
	{
		id="theon",
		name="Theon Greyjoy",
		type="player_target",
		ability="steal_greyjoy",
		ability_text="Steal one Greyjoy card from opponent."
	},

	# 8
	{
		id="tyrion",
		name="Tyrion Lannister",
		type="player_target",
		ability="steal_lannister",
		ability_text="Steal one Lannister card from opponent."
	},

	# 9
	{
		id="aemon",
		name="Maester Aemon",
		type="house_target",
		ability="return_house",
		ability_text="All players return one card of selected house to the board."
	},

	# 10
	{
		id="brienne",
		name="Brienne of Tarth",
		type="board_target",
		ability="force_varys_move",
		ability_text="Choose a character. Varys must move toward it next turn."
	},

	# 11
	{
		id="cersei",
		name="Cersei Lannister",
		type="player_target",
		ability="force_give_card",
		ability_text="Choose opponent. They must give you one card."
	},

	# 12
	{
		id="crow",
		name="Three-Eyed Crow",
		type="companion_deck",
		ability="swap_companion",
		ability_text="Swap one available companion with top of deck."
	},

	# 13
	{
		id="baelish",
		name="Petyr Baelish",
		type="companion_deck",
		ability="reveal_two",
		ability_text="Reveal next two companions and add them to available pool."
	},

	# 14
	{
		id="hodor",
		name="Hodor",
		type="board_target",
		ability="varys_jump",
		ability_text="Varys jumps over selected card and collects along the path."
	}
]

var players = [
	{ id = 1, cards = {}, banners = [], house_bonus = {} },
	{ id = 2, cards = {}, banners = [], house_bonus = {} }
]

var house_remaining = {}
var banners = {}

# ===============================
# READY
# ===============================

func _ready():
	
	grid.columns = 6
	update_turn_ui()
	init_houses()
	generate_board()
	choose_companions()
	spawn_companions()

	house_dialog.confirmed.connect(_on_house_dialog_closed)
	companion_confirm_dialog.confirmed.connect(_on_companion_confirmed)
	companion_confirm_dialog.canceled.connect(_on_companion_canceled)
	restart_button.pressed.connect(_on_restart_pressed)
	
	# ===== Jon Dialog =====
	jon_dialog.get_ok_button().text = "Confirm"
	jon_dialog.confirmed.connect(_on_jon_confirm_pressed)
	jon_dialog.visible = false
	
	# ===== Kill Confirm =====
	print("Kill dialog ref:", kill_confirm_dialog)
	kill_confirm_dialog.confirmed.connect(_on_kill_confirm_pressed)
	kill_confirm_dialog.get_ok_button().text = "Confirm"
	kill_confirm_dialog.dialog_text = "Confirm Kill?"
	kill_confirm_dialog.hide()
	
	# ===== Overlay background (שחור שקוף) =====
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.7)
	$GameOverPanel.add_theme_stylebox_override("panel", overlay_style)

	# ===== Result panel (קופסה פנימית) =====
	var result_style := StyleBoxFlat.new()
	result_style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	result_style.corner_radius_top_left = 12
	result_style.corner_radius_top_right = 12
	result_style.corner_radius_bottom_left = 12
	result_style.corner_radius_bottom_right = 12

	$GameOverPanel/CenterContainer/ResultPanel.add_theme_stylebox_override("panel", result_style)

	# ===== Hide overlay initially =====
	$GameOverPanel.visible = false

	# ===== Font sizes =====
	game_over_label.add_theme_font_size_override("font_size", 48)
	winner_label.add_theme_font_size_override("font_size", 32)

	player_panels = [
		$Game/MainRow/Player1Panel,
		$Game/MainRow/Player2Panel
	]
	
	swap_confirm_button = Button.new()
	swap_confirm_button.text = "Confirm Swap"
	swap_confirm_button.visible = false
	swap_confirm_button.pressed.connect(_on_swap_confirmed)

	add_child(swap_confirm_button)

	swap_confirm_button.anchor_left = 0.4
	swap_confirm_button.anchor_right = 0.6
	swap_confirm_button.anchor_top = 0.9
	swap_confirm_button.anchor_bottom = 0.95
	
	

# ===============================
# INIT TURN
# ===============================
func update_turn_ui():
	if current_player == 1:
		turn_label.text = "Player 1 Turn"
		turn_label.add_theme_color_override("font_color", Color.RED)
	else:
		turn_label.text = "Player 2 Turn"
		turn_label.add_theme_color_override("font_color", Color.BLUE)
# ===============================
# INIT HOUSES
# ===============================

func init_houses():

	house_remaining.clear()

	for p in players:
		p.cards.clear()
		p.banners.clear()
		p.house_bonus.clear()

	for data in ALL_CARDS:
		if data.house == "Varys":
			continue

		if not house_remaining.has(data.house):
			house_remaining[data.house] = 0

		house_remaining[data.house] += 1

		for p in players:
			if not p.cards.has(data.house):
				p.cards[data.house] = 0

# ===============================
# BOARD GENERATION
# ===============================

func generate_board():

	board_cards.clear()

	var deck = ALL_CARDS.duplicate()
	deck.shuffle()

	for child in grid.get_children():
		child.queue_free()

	for i in range(deck.size()):

		var card = CARD_SCENE.instantiate()
		grid.add_child(card)

		card.row = i / 6
		card.col = i % 6

		card.set_character(deck[i].name, deck[i].house)
		card.pressed.connect(on_card_pressed)

		board_cards.append(card)

		if deck[i].name == "Varys":
			varys_card = card
			card.set_varys_mark(true)
			
#func choose_companions():
#
	#companion_deck = COMPANIONS_POOL.duplicate()
	#companion_deck.shuffle()
#
	#active_companions = companion_deck.slice(0, 6)
	#companion_deck = companion_deck.slice(6, companion_deck.size())
	
func choose_companions():

	companion_deck = COMPANIONS_POOL.duplicate()

	# 🔥 מוציאים את Jaqen מהרשימה
	var jaqen_data = null

	for c in companion_deck:
		if c.id == "jaqen":
			jaqen_data = c
			break

	if jaqen_data != null:
		companion_deck.erase(jaqen_data)

	# ערבוב שאר הקלפים
	companion_deck.shuffle()

	# בוחרים 5 רנדומליים
	active_companions = companion_deck.slice(0, 5)

	# 🔥 מוסיפים את Jon תמיד
	if jaqen_data != null:
		active_companions.append(jaqen_data)

	# מה שנשאר נכנס ל-deck
	companion_deck = companion_deck.slice(5, companion_deck.size())
	
func spawn_companions():

	# ניקוי קודם
	for child in companions_bar.get_children():
		child.queue_free()

	for data in active_companions:
		var c = COMPANION_SCENE.instantiate()
		companions_bar.add_child(c)
		c.setup(data)
		c.used.connect(_on_companion_used)

func _on_companion_used(comp):

	print("Clicked companion")
	print("Current Game State:", game_state)

	if game_state != GameState.COMPANION_SELECTION:
		print("Not in companion selection mode")
		return

	pending_companion = comp
	show_companion_confirm_dialog(comp)
	
func _on_companion_canceled():

	print("Companion selection canceled")

	pending_companion = null
	ability_mode = null

	# נשארים במצב COMPANION_SELECTION
	game_state = GameState.COMPANION_SELECTION
	
func _on_swap_confirmed():

	if selected_cards.size() != 2:
		return

	var card_a = selected_cards[0]
	var card_b = selected_cards[1]

	swap_positions(card_a, card_b)

	# ניקוי סימונים
	for c in selected_cards:
		c.set_selected_visual(false)

	selected_cards.clear()
	swap_confirm_button.visible = false

	finish_companion_phase()
	
func show_companion_confirm_dialog(comp):
	
	print("Opening dialog")
	print(companion_confirm_dialog)
	print("Visible before:", companion_confirm_dialog.visible)
	
	var text = comp.data.get("name", "") + \
		"\n\nAbility:\n" + comp.data.get("ability", "")

	companion_confirm_dialog.dialog_text = text
	
	companion_confirm_dialog.visible = true
	companion_confirm_dialog.popup_centered()
	companion_confirm_dialog.grab_focus()
		
func enter_house_selection_mode():
	selecting_house = true
	print("Select a house for Jon Snow bonus.")
	

func enter_player_selection_mode():

	selecting_player = true
	print("Select a player to target.")

	for panel in player_panels:
		panel.modulate = Color(1,1,1,0.8) # הדגשה
	
# ===============================
# MOVEMENT
# ===============================

func on_card_pressed(card):

	print("Board cards size:", board_cards.size())
		
		# אם אנחנו במצב בחירת קומפניין — אסור לזוז בלוח
	if game_state == GameState.COMPANION_SELECTION:
		print("You must choose a companion first.")
		return
		
	# אם אנחנו במצב יכולת — לא מבצעים תור רגיל
	if game_state == GameState.ABILITY_TARGETING:
		print("ABILITY_TARGETING Start.")
		handle_ability_click(card)
		return
		
	if ability_mode != null:
		handle_ability_click(card)
		return
	
	if selecting_house:
		apply_house_bonus(card.house)
		selecting_house = false
		remove_used_companion()
		reset_ability()
		return
	
	for card_in_list in board_cards:
		print(card_in_list.character_name, card_in_list.row, card_in_list.col)

	if card.collected or card == varys_card:
		return

	# חייב להיות באותה שורה או עמודה
	if not (card.row == varys_card.row or card.col == varys_card.col):
		return

	var house_type = card.house
	if house_type == "Varys":
		return

	var found_cards = []

	var x = varys_card.row
	var y = varys_card.col

	# ===== למעלה =====
	if card.col == y and card.row < x:

		x -= 1
		while x >= 0:
			var current = get_card_at(x, y)
			if current and not current.collected and current.house == house_type:
				found_cards.append(current)
			x -= 1

	# ===== למטה =====
	elif card.col == y and card.row > x:

		x += 1
		while x < 6:
			var current = get_card_at(x, y)
			if current and not current.collected and current.house == house_type:
				found_cards.append(current)
			x += 1

	# ===== שמאלה =====
	elif card.row == x and card.col < y:

		y -= 1
		while y >= 0:
			var current = get_card_at(x, y)
			if current and not current.collected and current.house == house_type:
				found_cards.append(current)
			y -= 1

	# ===== ימינה =====
	elif card.row == x and card.col > y:

		y += 1
		while y < 6:
			var current = get_card_at(x, y)
			if current and not current.collected and current.house == house_type:
				found_cards.append(current)
			y += 1

	if found_cards.size() == 0:
		return

	# הקיצוני ביותר בכיוון
	var target = found_cards[found_cards.size() - 1]

	# חסימת מיקום ישן
	varys_card.set_varys_mark(false)
	varys_card.mark_collected()

	# איסוף הקלפים
	for c in found_cards:
		c.mark_collected()
		players[current_player - 1].cards[house_type] += 1
		house_remaining[house_type] -= 1

	update_banners(house_type)

	# מעבר ואריז
	varys_card = target
	varys_card.collected = false
	varys_card.button.disabled = false
	varys_card.set_varys_mark(true)

	check_house_completion(house_type)
	
	if game_state == GameState.NORMAL_TURN:
		current_player = 2 if current_player == 1 else 1
		update_turn_ui()
	
	if is_varys_stuck():
		end_game()
	return
	
func swap_positions(card_a, card_b):

	var a_name = card_a.character_name
	var a_house = card_a.house
	var a_collected = card_a.collected
	var a_is_varys = card_a.is_varys

	card_a.set_character(card_b.character_name, card_b.house)
	card_a.collected = card_b.collected
	card_a.set_varys_mark(card_b.is_varys)

	card_b.set_character(a_name, a_house)
	card_b.collected = a_collected
	card_b.set_varys_mark(a_is_varys)
	
	# 🔥 ניקוי highlight אחרי swap
	card_a.set_selected_visual(false)
	card_b.set_selected_visual(false)
	
func get_card_at(r, c):

	for card in board_cards:
		if card.row == r and card.col == c:
			return card

	return null
	
func is_varys_stuck() -> bool:

	var x = varys_card.row
	var y = varys_card.col

	# ==== בדיקה למעלה ====
	var r = x - 1
	while r >= 0:
		var card = get_card_at(r, y)
		if card and not card.collected and card.house != "Varys":
			return false
		r -= 1

	# ==== בדיקה למטה ====
	r = x + 1
	while r < 6:
		var card = get_card_at(r, y)
		if card and not card.collected and card.house != "Varys":
			return false
		r += 1

	# ==== בדיקה שמאלה ====
	var c = y - 1
	while c >= 0:
		var card = get_card_at(x, c)
		if card and not card.collected and card.house != "Varys":
			return false
		c -= 1

	# ==== בדיקה ימינה ====
	c = y + 1
	while c < 6:
		var card = get_card_at(x, c)
		if card and not card.collected and card.house != "Varys":
			return false
		c += 1

	# אם לא מצאנו אף קלף חוקי
	return true
	
# ===============================
# ABILITIES
# ===============================

func handle_ability_click(card):

	match ability_mode:

		"kill_one":
			
			if card.collected or card.is_varys:
				return

			# אסור להרוג Jon Snow
			if card.character_name == "Jon Snow":
				return

			# אם כבר מסומן → בטל סימון
			if kill_selected_card == card:
				card.set_selected_visual(false)
				kill_selected_card = null
				return

			# אם היה מסומן אחר → נקה אותו
			if kill_selected_card != null:
				kill_selected_card.set_selected_visual(false)

			kill_selected_card = card
			card.set_selected_visual(true)
			
			kill_confirm_dialog.dialog_text = "Kill " + card.character_name + " ?"
			kill_confirm_dialog.popup_centered()
			
			
			return

		"kill_extra_turn":

			if card.collected or card.is_varys:
				return

			if card.character_name == "Jon Snow":
				return

			if kill_selected_card == card:
				card.set_selected_visual(false)
				kill_selected_card = null
				return

			if kill_selected_card != null:
				kill_selected_card.set_selected_visual(false)

			kill_selected_card = card
			card.set_selected_visual(true)

			kill_confirm_dialog.dialog_text = "Kill " + card.character_name + "?"
			kill_confirm_dialog.popup_centered()

			return

		"take_one":
			card.mark_collected()
			players[current_player - 1].cards[card.house] += 1
			update_banners(card.house)
			finish_companion_phase()

		"swap_two":

			# אם הקלף כבר מסומן → בטל סימון
			if card in selected_cards:
				selected_cards.erase(card)
				card.set_selected_visual(false)

			else:
				# אם כבר 2 מסומנים → לא מאפשרים עוד
				if selected_cards.size() >= 2:
					return

				selected_cards.append(card)
				card.set_selected_visual(true)

			# עדכון כפתור לפי מצב אמיתי
			swap_confirm_button.visible = (selected_cards.size() == 2)

			return
			
		_:
			print("Ability not implemented yet")

func set_selected_visual(selected: bool):

	if selected:
		add_theme_color_override("border_color", Color.YELLOW)
	else:
		add_theme_color_override("border_color", Color.BLACK)
	
func remove_used_companion():
	for comp in companions_bar.get_children():
		if comp.data.get("ability") == ability_mode:
			comp.queue_free()
			break

func swap_cards(card_a, card_b):
	var index_a = card_a.get_index()
	var index_b = card_b.get_index()

	grid.move_child(card_a, index_b)
	grid.move_child(card_b, index_a)


func reset_ability():

	ability_mode = null
	first_selected_card = null

	for c in selected_cards:
		c.set_selected_visual(false)

	selected_cards.clear()

	if swap_confirm_button:
		swap_confirm_button.visible = false

	for c in grid.get_children():
		c.set_selected_visual(false)
		
func _on_companion_confirmed():

	if pending_companion == null:
		return

	ability_mode = pending_companion.data.get("ability")
	var ability_type = pending_companion.data.get("type")

	print("Ability confirmed:", ability_mode)

	match ability_type:

		"board_target":
			game_state = GameState.ABILITY_TARGETING

		"board_double_target":
			game_state = GameState.ABILITY_TARGETING

		"house_target":
			if ability_mode == "house_bonus":
				enter_jon_selection_mode()

		"player_target":
			game_state = GameState.ABILITY_TARGETING
			enter_player_selection_mode()

		"instant":
			execute_instant_ability()
	
func execute_instant_ability():

	if ability_mode == "take_daenerys":
		
		var found = false
		
		for card in board_cards:
			if card.character_name == "Daenerys" and not card.collected:
				card.mark_collected()

				var player_index = current_player - 1

				players[player_index].cards["Targaryen"] += 1
				house_remaining["Targaryen"] -= 1

				update_banners("Targaryen")

				check_house_completion("Targaryen")

				found = true
				break
				
			if not found:
				print("Daenerys not available on board.")

	finish_companion_phase()

func execute_player_ability(target_index):

	var opponent = players[target_index]
	var current = players[current_player - 1]

	match ability_mode:

		"steal_greyjoy":
			if opponent.cards.get("Greyjoy", 0) > 0:
				opponent.cards["Greyjoy"] -= 1
				current.cards["Greyjoy"] += 1
				update_banners("Greyjoy")

		"steal_lannister":
			if opponent.cards.get("Lannister", 0) > 0:
				opponent.cards["Lannister"] -= 1
				current.cards["Lannister"] += 1
				update_banners("Lannister")

		"force_give_card":
			for house in opponent.cards.keys():
				if opponent.cards[house] > 0:
					opponent.cards[house] -= 1
					current.cards[house] += 1
					update_banners(house)
					break

	finish_companion_phase()

func finish_companion_phase(skip_turn_switch=false):

	remove_used_companion()
	reset_ability()

	game_state = GameState.NORMAL_TURN
	pending_companion = null

	if not skip_turn_switch:
		current_player = 2 if current_player == 1 else 1
		update_turn_ui()
	
func enter_jon_selection_mode():

	jon_selection_active = true
	jon_selected_house = ""
	build_jon_house_list()

	jon_dialog.popup_centered()
	
func build_jon_house_list():

	for child in jon_houses_list.get_children():
		child.queue_free()

	var current_index = current_player - 1
	var opponent_index = 1 - current_index

	for house in house_remaining.keys():

		var btn = Button.new()

		update_jon_button(btn, house)

		btn.pressed.connect(func():
			jon_selected_house = house
			refresh_jon_selection_ui()
		)

		jon_houses_list.add_child(btn)
		
func update_jon_button(btn: Button, house: String):

	var current_index = current_player - 1
	var opponent_index = 1 - current_index

	var my_count = players[current_index].cards[house] + players[current_index].house_bonus.get(house, 0)

	# אם זה הבית שנבחר → נחשב כאילו כבר קיבל +1
	if house == jon_selected_house:
		my_count += 1

	var enemy_count = players[opponent_index].cards[house] + players[opponent_index].house_bonus.get(house, 0)

	btn.text = house + "  (" + str(my_count) + " vs " + str(enemy_count) + ")"

	# צבע לפי השוואה
	if my_count > enemy_count:
		btn.add_theme_color_override("font_color", Color.GREEN)
	elif my_count < enemy_count:
		btn.add_theme_color_override("font_color", Color.RED)
	else:
		btn.add_theme_color_override("font_color", Color.WHITE)

	# highlight לבית שנבחר
	if house == jon_selected_house:
		btn.add_theme_color_override("font_outline_color", Color.YELLOW)
		btn.add_theme_constant_override("outline_size", 2)
	else:
		btn.add_theme_constant_override("outline_size", 0)
		
func refresh_jon_selection_ui():

	for btn in jon_houses_list.get_children():

		var house_name = btn.text.split(" ")[0]
		update_jon_button(btn, house_name)
		
func _on_jon_confirm_pressed():

	if jon_selected_house == "":
		return

	var player_index = current_player - 1

	var current_bonus = players[player_index].house_bonus.get(jon_selected_house, 0)
	players[player_index].house_bonus[jon_selected_house] = current_bonus + 1

	update_banners(jon_selected_house)

	add_jon_to_player(player_index)

	jon_dialog.hide()

	jon_selection_active = false
	finish_companion_phase()
	
func add_jon_to_player(player_index):

	if not players[player_index].cards.has("JonSnow"):
		players[player_index].cards["JonSnow"] = 1
	else:
		players[player_index].cards["JonSnow"] += 1
		
func _on_kill_confirm_pressed():
	
	kill_confirm_dialog.hide()
	
	if kill_selected_card == null:
		return

	var house = kill_selected_card.house

	kill_selected_card.mark_collected()

	house_remaining[house] -= 1

	# אם הבית נסגר בגלל kill → לא נותנים companion
	check_house_completion(house, false)

	var extra_turn = (ability_mode == "kill_extra_turn")

	kill_selected_card.set_selected_visual(false)
	kill_selected_card = null
	
	finish_companion_phase(extra_turn)
		
# ===============================
# HOUSE BANNERS
# ===============================
	
func update_banners(house):

	var p1_cards = players[0].cards[house]
	var p2_cards = players[1].cards[house]

	# שליפת בונוסים אם קיימים
	var p1_bonus = players[0].house_bonus.get(house, 0)
	var p2_bonus = players[1].house_bonus.get(house, 0)

	var p1_total = p1_cards + p1_bonus
	var p2_total = p2_cards + p2_bonus

	# ניקוי באנר קודם
	players[0].banners.erase(house)
	players[1].banners.erase(house)

	if p1_total > p2_total:
		players[0].banners.append(house)
	elif p2_total > p1_total:
		players[1].banners.append(house)
	# אם שוויון → לאף אחד אין באנר

	update_player_ui()
	
func apply_house_bonus(house):
	
	if ability_mode == "house_bonus":
		players[current_player - 1].house_bonus[house] += 1
		update_banners(house)
		finish_companion_phase()
		
	var player = players[current_player - 1]

	player.house_bonus[house] = player.house_bonus.get(house, 0) + 1

	update_banners(house)

# ===============================
# PLAYERS
# ===============================

func update_player_ui():

	# ניקוי קודם
	for child in player1_banners.get_children():
		child.queue_free()

	for child in player2_banners.get_children():
		child.queue_free()

	# Player 1 banners
	for house in players[0].banners:
		player1_banners.add_child(create_banner_label(house))

	# Player 2 banners
	for house in players[1].banners:
		player2_banners.add_child(create_banner_label(house))
		
func create_banner_label(house: String) -> Label:
	var label = Label.new()
	label.text = house

	var house_color: Color = Color.WHITE

	match house:
		"Stark":
			house_color = Color(0.75,0.75,0.75)
		"Lannister":
			house_color = Color(0.85,0.25,0.25)
		"Targaryen":
			house_color = Color(0.35,0.1,0.1)
		"Baratheon":
			house_color = Color(1.0,0.9,0.3)
		"Tyrell":
			house_color = Color(0.35,0.75,0.35)
		"Tully":
			house_color = Color(0.35,0.55,1.0)
		"Greyjoy":
			house_color = Color(0.2,0.85,0.8)

	label.add_theme_color_override("font_color", house_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_font_size_override("font_size", 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	return label
# ===============================
# HOUSE COMPLETION
# ===============================

func check_house_completion(house, allow_companion := true):

	if house_remaining[house] == 0:

		print("House completed:", house)

		if allow_companion:
			game_state = GameState.COMPANION_SELECTION
			show_house_completed_dialog(house)
		else:
			print("House destroyed. No companion awarded.")
		
func show_house_completed_dialog(house):

	last_completed_house = house

	house_dialog.dialog_text = "You collected the last card of House " + house + "!\nChoose a companion."
	house_dialog.popup_centered()

func _on_house_dialog_closed():
	enable_companion_selection()
	
func enable_companion_selection():
	game_state = GameState.COMPANION_SELECTION
	print("Select a companion to use.")

# ===============================
# END GAME
# ===============================

func end_game():

	if game_finished:
		return
	game_finished = true

	var p1_score = players[0].banners.size()
	var p2_score = players[1].banners.size()

	var winner_text = ""

	if p1_score > p2_score:
		winner_text = "Player 1 Wins!"
		game_over_label.add_theme_color_override("font_color", Color.RED)
	elif p2_score > p1_score:
		winner_text = "Player 2 Wins!"
		game_over_label.add_theme_color_override("font_color", Color.BLUE)
	else:
		winner_text = "It's a Draw!"
		game_over_label.add_theme_color_override("font_color", Color.WHITE)

	# ===== יצירת רשימת בתים =====
	var p1_houses_text = ""
	var p2_houses_text = ""

	if p1_score > 0:
		p1_houses_text = "\n- " + "\n- ".join(players[0].banners)
	else:
		p1_houses_text = "\nNone"

	if p2_score > 0:
		p2_houses_text = "\n- " + "\n- ".join(players[1].banners)
	else:
		p2_houses_text = "\nNone"

		# ===== עדכון טקסטים =====
		game_over_label.text = winner_text

		winner_label.text = "Player 1: " + str(p1_score) + " Banners" + p1_houses_text + \
							"\n\nPlayer 2: " + str(p2_score) + " Banners" + p2_houses_text

		game_over_panel.visible = true

# ===============================
# RESTART GAME
# ===============================

func _on_restart_pressed():
	get_tree().reload_current_scene()

# ===============================
# TESTING
# ===============================
func _gui_input(event):

	if event is InputEventMouseButton and event.pressed:

		if selecting_player:
			handle_player_click(event.position)
			return
				
func handle_player_click(click_position: Vector2):

	for i in range(player_panels.size()):

		var rect = player_panels[i].get_global_rect()

		if rect.has_point(click_position):

			# אי אפשר לבחור את עצמך
			if i == current_player - 1:
				print("Cannot target yourself.")
				return

			selecting_player = false

			# ניקוי highlight
			for p in player_panels:
				p.modulate = Color.WHITE

			execute_player_ability(i)
			return

	print("Clicked outside player panels.")
