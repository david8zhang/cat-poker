class_name Game
extends Node2D

var deck = []
var curr_community_cards = []

enum GamePhase {
	PREFLOP,
	FLOP,
	TURN,
	RIVER,
	SHOWDOWN
}

enum Side {
	PLAYER,
	CPU
}

enum HandTypes {
	HIGH_CARD,
	PAIR,
	TWO_PAIR,
	THREE_OF_A_KIND,
	STRAIGHT,
	FLUSH,
	FULL_HOUSE,
	FOUR_OF_A_KIND,
	STRAIGHT_FLUSH
}

var hand_type_names = [
	"High Card",
	"Pair",
	"Two Pair",
	"Three of a Kind",
	"Straight",
	"Flush",
	"Full House",
	"Four of a Kind",
	"Straight Flush"
]

@onready var player = $Player as CardPlayer
@onready var cpu = $CPU as CardPlayer
@onready var pot_label = get_node("/root/Game/CanvasLayer/PotLabel") as Label
@onready var player_action_buttons = get_node("/root/Game/CanvasLayer/PlayerActionButtons") as HBoxContainer
@onready var turn_to_bet_label = get_node("/root/Game/CanvasLayer/TurnToBet") as Label
@onready var player_chip_count = get_node("/root/Game/CanvasLayer/PlayerChips") as Label
@onready var cpu_chip_count = get_node("/root/Game/CanvasLayer/CPUChips") as Label

# Showdown modal text
@onready var showdown_result = get_node("/root/Game/CanvasLayer/ShowdownResult") as Control
@onready var showdown_win_label = get_node("/root/Game/CanvasLayer/ShowdownResult/WinLabel") as Label
@onready var showdown_next_button = get_node("/root/Game/CanvasLayer/ShowdownResult/NextButton") as Button

@export var card_scene: PackedScene

const RANKS = ["02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "K", "A"]
const SUITS = ["diamonds", "spades", "hearts", "clubs"]

var side_to_act: Game.Side
var pot = 0
var curr_player_bet = 0
var curr_cpu_bet = 0
var curr_phase = GamePhase.PREFLOP
var next_card_x_pos = -150

var did_player_check = false
var did_cpu_check = false

class Hand:
	var hand_type: HandTypes
	var cards

func _ready():
	# connect signals
	player.bet.connect(on_player_bet)
	cpu.bet.connect(on_cpu_bet)
	showdown_next_button.button_up.connect(go_to_new_game)

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

func generate_card(rank, suit):
	return { "rank": rank, "suit": suit }

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
		curr_community_cards.append(card)
		add_child(card)
		next_card_x_pos += card.sprite.texture.get_width() * 2
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

func delay_action(callable, time):
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = time
	timer.one_shot = true
	timer.connect("timeout", callable)
	add_child(timer)

func on_player_bet(amount):
	curr_player_bet = amount
	# Player check
	if amount == 0:
		if did_cpu_check:
			go_to_next_phase_with_delay(2)
		else:
			did_player_check = true
			process_next_action(Game.Side.CPU)
	# Player raise
	if curr_player_bet > curr_cpu_bet:
		process_next_action(Game.Side.CPU)
	# Player call
	elif curr_player_bet == curr_cpu_bet:
		go_to_next_phase_with_delay(2)
	pot_label.text = "$" + str(curr_player_bet + curr_cpu_bet + pot)
	player_chip_count.text = "Player: $" + str(player.curr_bankroll)

func on_cpu_bet(amount):
	curr_cpu_bet = amount
	# CPU check
	if amount == 0:
		if did_player_check:
			go_to_next_phase_with_delay(2)
		else:
			did_cpu_check = true
			process_next_action(Game.Side.PLAYER)
	# CPU raise
	elif curr_cpu_bet > curr_player_bet:
		process_next_action(Game.Side.PLAYER)
	# CPU call
	elif curr_cpu_bet == curr_player_bet:
		go_to_next_phase_with_delay(2)
	pot_label.text = "$" + str(curr_player_bet + curr_cpu_bet + pot)
	cpu_chip_count.text = "CPU: $" + str(cpu.curr_bankroll)

func go_to_next_phase_with_delay(delay: int):
	var callable = Callable(self, "go_to_next_phase")
	delay_action(callable, delay)

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
	elif curr_phase == GamePhase.RIVER:
		cpu.display_hand()
		curr_phase = GamePhase.SHOWDOWN
		check_winner()

func handle_cpu_action():
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
	player_chip_count.text = "Player: $" + str(player.curr_bankroll)
	cpu_chip_count.text = "CPU: $" + str(cpu.curr_bankroll)

func go_to_new_game():
	pass

func check_winner():
	showdown_result.show()
	var player_hand = get_best_hand_comm_cards(player.cards_in_hand, curr_community_cards)
	var cpu_hand = get_best_hand_comm_cards(cpu.cards_in_hand, curr_community_cards)
	var compare_result = compare_hands(player_hand, cpu_hand)
	if compare_result == 1:
		showdown_win_label.text = "Player Wins!\nHand: " + hand_type_names[player_hand.hand_type] + "\nWinnings: $" + str(pot)
	elif compare_result == -1:
		showdown_win_label.text = "CPU Wins!\nHand: " + hand_type_names[cpu_hand.hand_type]
	else:
		showdown_win_label.text = "Tie!\nWinnings:" + str(pot / 2)

# Get the best hand between hole cards and community cards
func get_best_hand_comm_cards(player_cards, community_cards):
	var highest_hand_so_far = Hand.new()
	highest_hand_so_far.hand_type = HandTypes.HIGH_CARD
	highest_hand_so_far.cards = []
	# Check all combinations of 1 player card + 4 community cards
	var community_card_4_comb = generate_combinations(community_cards, 4)
	for card in player_cards:
		for comb in community_card_4_comb:
			var hand_to_check = [card] + comb
			var this_highest_hand = get_best_5card_hand(hand_to_check)
			if highest_hand_so_far.cards.is_empty() or compare_hands(this_highest_hand, highest_hand_so_far) == 1:
				highest_hand_so_far = this_highest_hand
	# Check all combinations of 2 player cards + 3 community cards
	var community_card_3_comb = generate_combinations(community_cards, 3)
	for comb in community_card_3_comb:
		var hand_to_check = player_cards + comb
		var this_highest_hand = get_best_5card_hand(hand_to_check)
		if highest_hand_so_far.cards.is_empty() or compare_hands(this_highest_hand, highest_hand_so_far) == 1:
			highest_hand_so_far = this_highest_hand
	return highest_hand_so_far

# Return 1 if hand1 > hand2, -1 if hand1 < hand2, 0 if hand1 = hand2
func compare_hands(hand1: Hand, hand2: Hand):
	var hand1_type = hand1.hand_type as HandTypes
	var hand2_type = hand2.hand_type as HandTypes
	if hand1_type > hand2_type:
		return 1
	elif hand1_type < hand2_type:
		return -1
	else:
		# If pair, 2-pair, three of a kind, or 4 of a kind, compare highest card in the set. Otherwise, compare highest card outside of set
		var set_types = [HandTypes.PAIR, HandTypes.TWO_PAIR, HandTypes.THREE_OF_A_KIND, HandTypes.FOUR_OF_A_KIND]
		if set_types.has(hand1_type):
			pass
		else:
			var highest_hand1_card = get_highest_card(hand1.cards)
			var highest_hand2_card = get_highest_card(hand2.cards)
			if highest_hand1_card > highest_hand2_card:
				return 1
			elif highest_hand2_card > highest_hand1_card:
				return -1
			else:
				return 0

func get_highest_card(cards):
	var highest_rank = 0
	for card in cards:
		var rank = RANKS.find(card.rank)
		if rank > highest_rank:
			highest_rank = rank
	return highest_rank

# Get the best hand given 5 cards
func get_best_5card_hand(cards):
	var hand = Hand.new()
	hand.cards = cards
	if is_straight(cards) and is_flush(cards):
		hand.hand_type = HandTypes.STRAIGHT_FLUSH
	elif is_four_of_a_kind(cards):
		hand.hand_type = HandTypes.FOUR_OF_A_KIND
	elif is_full_house(cards):
		hand.hand_type = HandTypes.FULL_HOUSE
	elif is_flush(cards):
		hand.hand_type = HandTypes.FLUSH
	elif is_straight(cards):
		hand.hand_type = HandTypes.STRAIGHT
	elif is_three_of_a_kind(cards):
		hand.hand_type = HandTypes.THREE_OF_A_KIND
	elif is_two_pair(cards):
		hand.hand_type = HandTypes.TWO_PAIR
	elif is_pair(cards):
		hand.hand_type = HandTypes.PAIR
	else:
		hand.hand_type = HandTypes.HIGH_CARD
	return hand

func _straight_helper(sorted_ranks):
	for i in range(1, sorted_ranks.size()):
		if sorted_ranks[i] - sorted_ranks[i - 1] != 1:
			return false
	return true

func is_straight(cards):
	# check for "wheel" straights (A, 2, 3, 4, 5)
	var sorted_wheel_ranks = cards.map(func(c): return -1 if c.rank == "A" else RANKS.find(c.rank))
	sorted_wheel_ranks.sort()
	var sorted_ranks = cards.map(func(c): return RANKS.find(c.rank))
	sorted_ranks.sort()
	return _straight_helper(sorted_wheel_ranks) or _straight_helper(sorted_ranks)

func is_flush(cards):
	var this_suit = cards[0].suit
	for card in cards:
		if card.suit != this_suit:
			return false
	return true

func is_four_of_a_kind(cards):
	return get_rank_mapping(cards)["highest_count"] == 4

func is_full_house(cards):
	var rank_mapping = get_rank_mapping(cards)["mapping"]
	var has_pair = false
	var has_three_of_a_kind = false
	for key in rank_mapping.keys():
		if rank_mapping[key] == 2:
			has_pair = true
		elif rank_mapping[key] == 3:
			has_three_of_a_kind = true
	return has_pair and has_three_of_a_kind

func is_two_pair(cards):
	var rank_mapping = get_rank_mapping(cards)["mapping"]
	var num_pairs = 0
	for key in rank_mapping.keys():
		if rank_mapping[key] == 2:
			num_pairs += 1
	return num_pairs == 2

func is_three_of_a_kind(cards):
	return get_rank_mapping(cards)["highest_count"] == 3

func is_pair(cards):
	return get_rank_mapping(cards)["highest_count"] == 2

# Get a mapping of rank to number of cards
func get_rank_mapping(cards):
	var rank_mapping = {}
	var highest_count = 0
	for card in cards:
		if rank_mapping.has(card.rank):
			rank_mapping[card.rank] += 1
		else:
			rank_mapping[card.rank] = 1
		if rank_mapping[card.rank] > highest_count:
			highest_count = rank_mapping[card.rank]
	return {
		"highest_count": highest_count,
		"mapping": rank_mapping
	}

func generate_combinations(arr: Array, combination_size: int) -> Array:
	var result = []
	_combination_helper(arr, combination_size, 0, [], result)
	return result

func _combination_helper(arr: Array, combination_size: int, start: int, current: Array, result: Array) -> void:
	if current.size() == combination_size:
		result.append(current.duplicate())
		return
	for i in range(start, arr.size()):
		current.append(arr[i])
		_combination_helper(arr, combination_size, i + 1, current, result)
		current.pop_back()
