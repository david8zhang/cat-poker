class_name Game
extends Node2D

var deck = []
var communal_cards = []

enum GamePhase {
	PREFLOP,
	FLOP,
	TURN,
	RIVER
}

enum Side {
	PLAYER,
	CPU
}

@onready var player = $Player as CardPlayer
@onready var cpu = $CPU as CardPlayer
@onready var pot_label = get_node("/root/Game/CanvasLayer/PotLabel") as Label
@onready var player_action_buttons = get_node("/root/Game/CanvasLayer/PlayerActionButtons") as HBoxContainer
@onready var turn_to_bet_label = get_node("/root/Game/CanvasLayer/TurnToBet") as Label

@export var card_scene: PackedScene

const RANKS = ["02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "A"]
const SUITS = ["diamonds", "spades", "hearts", "clubs"]

var side_to_act: Game.Side
var pot = 0
var curr_player_bet = 0
var curr_cpu_bet = 0
var curr_phase = GamePhase.PREFLOP
var next_card_x_pos = 0

func _ready():
	# connect signals
	player.bet.connect(on_player_bet)
	cpu.bet.connect(on_cpu_bet)

	# Initialize deck
	for i in range(0, RANKS.size()):
		for j in range(0, SUITS.size()):
			var rank = RANKS[i]
			var suit = SUITS[j]
			deck.append({
				"rank": rank,
				"suit": suit
			})

	# Initialize players
	player.global_position = Vector2(0, 200)
	cpu.global_position = Vector2(0, -200)

	# shuffle deck
	deck.shuffle()

	# Place blind bets
	player.blind_bet(1)
	cpu.blind_bet(2)

	#deal cards
	player.get_cards(draw_cards_from_deck(2))
	cpu.get_cards(draw_cards_from_deck(2))
	player.display_hand()

	process_next_action(Side.PLAYER)
	
func draw_cards_from_deck(num_cards: int):
	var cards = []
	for i in range(0, num_cards):
		cards.append(deck.pop_front())
	return cards

func deal_cards_on_table(num_cards):
	var card_pos = Vector2(next_card_x_pos, 0)
	var flop_cards = draw_cards_from_deck(num_cards)
	for c in flop_cards:
		var card = card_scene.instantiate() as Card
		card.rank = c.rank
		card.suit = c.suit
		card.global_position = card_pos
		communal_cards.append(card)
		add_child(card)
		next_card_x_pos += card.sprite.texture.get_width() * 1.5
		card_pos = Vector2(next_card_x_pos, 0)
		card.show_card()

func process_next_action(next_side_to_act):
	self.side_to_act = next_side_to_act
	turn_to_bet_label.text = "Turn to Bet: PLAYER" if next_side_to_act == Side.PLAYER else "Turn to Bet: CPU"
	if self.side_to_act == Game.Side.CPU:
		player_action_buttons.hide()
		var timer = Timer.new()
		timer.autostart = true
		timer.wait_time = 3
		timer.one_shot = true
		var on_timeout = Callable(self, "handle_cpu_action")
		timer.connect("timeout", on_timeout)
		add_child(timer)
	if self.side_to_act == Game.Side.PLAYER:
		player_action_buttons.show()

func on_bet(side: Game.Side, amount):
	# pot_label.text = "$" + str(pot)
	if side == Game.Side.CPU:
		curr_cpu_bet = amount
		# CPU raise or
		if curr_cpu_bet > curr_player_bet or amount == 0:
			process_next_action(Game.Side.PLAYER)
		# CPU call
		elif curr_cpu_bet == curr_player_bet:
			var callable = Callable(self, "go_to_next_phase")
			delay_action(callable, 2)

	else:
		curr_player_bet = amount
		# Player raise or check
		if curr_player_bet > curr_cpu_bet or amount == 0:
			process_next_action(Game.Side.CPU)
		# Player call
		elif curr_player_bet == curr_cpu_bet:
			var callable = Callable(self, "go_to_next_phase")
			delay_action(callable, 2)

	# Update the pot
	pot_label.text = "$" + str(curr_player_bet + curr_cpu_bet + pot)


func delay_action(callable, time):
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = time
	timer.one_shot = true
	timer.connect("timeout", callable)
	add_child(timer)

func on_player_bet(amount):
	on_bet(Game.Side.PLAYER, amount)

func on_cpu_bet(amount):
	on_bet(Game.Side.CPU, amount)

func go_to_next_phase():
	pot += curr_player_bet + curr_cpu_bet
	curr_player_bet = 0
	curr_cpu_bet = 0
	if curr_phase == GamePhase.PREFLOP:
		deal_cards_on_table(3)
		curr_phase = GamePhase.FLOP
		process_next_action(Side.PLAYER)
	elif curr_phase == GamePhase.FLOP:
		deal_cards_on_table(1)
		curr_phase = GamePhase.TURN
		process_next_action(Side.PLAYER)
	elif curr_phase == GamePhase.TURN:
		deal_cards_on_table(1)
		curr_phase = GamePhase.RIVER
		process_next_action(Side.PLAYER)

func handle_cpu_action():
	print("Went here!")
	if curr_player_bet == 0:
		cpu.check()
	else:
		cpu.call_bet()

func blind_bet(amount, side: Game.Side):
	if side == Side.PLAYER:
		curr_player_bet = amount
	elif side == Side.CPU:
		curr_cpu_bet = amount
	pot_label.text = "$" + str(curr_player_bet + curr_cpu_bet + pot)

