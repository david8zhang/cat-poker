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
	CPU,
	BOTH,
	NONE
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

enum BetType {
	CHECK,
	RAISE,
	CALL,
	ALL_IN
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

@onready var player = $Player as PlayerCardPlayer
@onready var cpu = $CPU as CPUCardPlayer
@onready var pot_label = get_node("/root/Game/CanvasLayer/PotContainer/PotLabel") as Label
@onready var turn_to_bet_label = get_node("/root/Game/CanvasLayer/TurnToBetSection/TurnToBet") as Label
@onready var player_chip_count = get_node("/root/Game/CanvasLayer/BankrollSection/PlayerChips") as Label
@onready var cpu_chip_count = get_node("/root/Game/CanvasLayer/BankrollSection/CPUChips") as Label
@onready var action_log = get_node("/root/Game/CanvasLayer/ActionLogSection") as Panel
@onready var action_log_label = get_node("/root/Game/CanvasLayer/ActionLogSection/ActionLog") as Label
@onready var cpu_reaction_label = get_node("/root/Game/CanvasLayer/CPUReaction") as Label

# Showdown modal text
@onready var showdown_result = get_node("/root/Game/CanvasLayer/ShowdownResult") as Control
@onready var showdown_win_label = get_node("/root/Game/CanvasLayer/ShowdownResult/WinLabel") as Label
@onready var showdown_next_button = get_node("/root/Game/CanvasLayer/ShowdownResult/NextButton") as Button

# Game Over modal
@onready var game_over_modal = get_node("/root/Game/CanvasLayer/GameOverModal") as Control
@onready var game_over_label = get_node("/root/Game/CanvasLayer/GameOverModal/WinLabel") as Label
@onready var game_over_restart_button = get_node("/root/Game/CanvasLayer/GameOverModal/PlayAgainButton") as Button

# Player action buttons
@onready var player_action_buttons = get_node("/root/Game/CanvasLayer/PlayerActionButtons") as HBoxContainer
@onready var player_check_button = get_node("/root/Game/CanvasLayer/PlayerActionButtons/Check") as Button
@onready var player_call_button = get_node("/root/Game/CanvasLayer/PlayerActionButtons/Call") as Button
@onready var player_small_raise_button = get_node("/root/Game/CanvasLayer/PlayerActionButtons/SmallRaise") as Button
@onready var player_big_raise_button = get_node("/root/Game/CanvasLayer/PlayerActionButtons/BigRaise") as Button
@onready var player_all_in_button = get_node("/root/Game/CanvasLayer/PlayerActionButtons/AllIn") as Button

@export var card_scene: PackedScene

signal all_ready

const RANKS = ["02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "K", "A"]
const SUITS = ["diamonds", "spades", "hearts", "clubs"]
const FLOP_START_X = -175

var side_to_act: Game.Side
var pot = 0
var curr_player_bet = 0
var curr_cpu_bet = 0
var curr_phase = GamePhase.PREFLOP
var next_card_x_pos = FLOP_START_X

var did_player_check = false
var did_cpu_check = false
var is_player_all_in = false
var is_cpu_all_in = false
var hand_winner: Game.Side = Side.NONE
var big_blind_side = -1

class Hand:
	var hand_type: HandTypes
	var cards

class CardComparator:
	func compare(a: Card, b: Card) -> int:
		return RANKS.find(a.rank) - RANKS.find(b.rank)

class WheelCardComparator:
	func compare(a: Card, b: Card) -> int:
		var a_rank = RANKS.find(a.rank)
		var b_rank = RANKS.find(b.rank)
		if a.rank == "A":
			a_rank = -1
		if b.rank == "A":
			b_rank = -1
		return a_rank - b_rank

func _ready():
	# connect signals
	player.bet.connect(on_player_bet)
	cpu.bet.connect(on_cpu_bet)
	showdown_next_button.button_up.connect(start_new_hand)
	game_over_restart_button.pressed.connect(new_game)
	action_log.hide()

	# Initialize players
	player.global_position = Vector2(0, 300)
	cpu.global_position = Vector2(0, -65)
	init_game()
	all_ready.emit()

func init_game():
	player_action_buttons.hide()
	for i in range(0, RANKS.size()):
		for j in range(0, SUITS.size()):
			var rank = RANKS[i]
			var suit = SUITS[j]
			deck.append({
				"rank": rank,
				"suit": suit
			})
	deck.shuffle()

	var last_big_blind = big_blind_side
	if last_big_blind == -1:
		# Assign blind randomly if first hand
		big_blind_side = Side.PLAYER if randi_range(0, 1) == 0 else Side.CPU
	else:
		# Otherwise, rotate big blind
		big_blind_side = Side.PLAYER if last_big_blind == Side.CPU else Side.CPU
	turn_to_bet_label.text = "Big Blind: PLAYER" if big_blind_side == Side.PLAYER else "Big Blind: CPU"

	# Handle blind bets, card dealing
	var complete_cb = Callable(self, "on_blind_complete")
	handle_blind_bets(complete_cb)

func on_blind_complete():
	action_log.hide()

	#deal cards
	player.get_cards(draw_cards_from_deck(2), Vector2(-44, -20))
	cpu.get_cards(draw_cards_from_deck(2), Vector2(-44, 50))
	player.display_hand()

	# Do CPU initial reaction
	cpu.react_to_phase()
	process_next_action(Side.PLAYER if big_blind_side == Side.CPU else Side.CPU)

func generate_card(rank, suit):
	return { "rank": rank, "suit": suit }

func draw_cards_from_deck(num_cards: int):
	var cards = []
	for i in range(0, num_cards):
		cards.append(deck.pop_front())
	return cards

func handle_blind_bets(complete_cb):
	# If current big blind can't cover, auto fold
	if player.curr_bankroll < 2:
		fold(Side.PLAYER, "Player folded (not enough for blind!)...\nCPU wins!")
	elif cpu.curr_bankroll < 2:
		fold(Side.CPU, "CPU folded (not enough for blind!)...\nPlayer wins!")
	else:
		big_blind_bet()
		# add some delay between big blind bet and small blind bet
		var timer = Timer.new()
		timer.autostart = true
		timer.one_shot = true
		timer.wait_time = 1
		var on_timeout = Callable(self, "small_blind_bet").bind(complete_cb)
		timer.connect("timeout", on_timeout)
		add_child(timer)

func big_blind_bet():
	if big_blind_side == Side.PLAYER:
		player.blind_bet(2)
	if big_blind_side == Side.CPU:
		cpu.blind_bet(2)

func small_blind_bet(complete_cb):
	if big_blind_side == Side.PLAYER:
		cpu.blind_bet(1)
	if big_blind_side == Side.CPU:
		player.blind_bet(1)

	# add some delay between small blind bet and card dealing
	var timer = Timer.new()
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = 1
	timer.connect("timeout", complete_cb)
	add_child(timer)

func deal_cards_on_table(num_cards):
	var card_pos_y = 150
	var card_pos = Vector2(next_card_x_pos, card_pos_y)
	var flop_cards = draw_cards_from_deck(num_cards)
	for c in flop_cards:
		var card = card_scene.instantiate() as Card
		card.rank = c.rank
		card.suit = c.suit
		card.global_position = card_pos
		curr_community_cards.append(card)
		add_child(card)
		next_card_x_pos += card.sprite.texture.get_width() / 2 * card.sprite.scale.x + 25
		card_pos = Vector2(next_card_x_pos, card_pos_y)
		card.show_card()

func process_next_action(next_side_to_act, skip_betting = false):
	self.side_to_act = next_side_to_act
	if skip_betting:
		go_to_next_phase_with_delay(1)
	elif self.side_to_act == Game.Side.CPU:
		cpu_reaction_label.show()
		player_action_buttons.hide()
		var timer = Timer.new()
		timer.autostart = true
		timer.wait_time = 2.5
		timer.one_shot = true
		var on_timeout = Callable(self, "handle_cpu_action")
		timer.connect("timeout", on_timeout)
		add_child(timer)
	elif self.side_to_act == Game.Side.PLAYER:
		cpu_reaction_label.hide()
		show_player_action_buttons()

func show_player_action_buttons():
	player_action_buttons.show()
	if curr_cpu_bet == 0:
		player_check_button.show()
		player_call_button.hide()
	elif curr_cpu_bet > curr_player_bet:
		var amount_to_call = curr_cpu_bet - curr_player_bet
		if amount_to_call > player.curr_bankroll:
			amount_to_call = player.curr_bankroll
		player_call_button.show()
		player_call_button.text = "Call $" + str(amount_to_call)
		player_check_button.hide()

	# Can't raise when CPU is already all in
	if is_cpu_all_in:
		player_check_button.hide()
		player_small_raise_button.hide()
		player_big_raise_button.hide()
	else:
		player_small_raise_button.show()
		player_big_raise_button.show()

func delay_action(callable, time):
	var timer = Timer.new()
	timer.autostart = true
	timer.wait_time = time
	timer.one_shot = true
	timer.connect("timeout", callable)
	add_child(timer)

func on_player_bet(amount, bet_type):
	action_log.show()
	curr_player_bet += amount
	pot_label.text = "Pot: $" + str(curr_player_bet + curr_cpu_bet + pot)
	player_chip_count.text = "Player: $" + str(player.curr_bankroll)
	match bet_type:
		BetType.CHECK:
			action_log_label.text = "Player checks"
			if did_cpu_check:
				go_to_next_phase_with_delay(1)
			else:
				did_player_check = true
				process_next_action(Game.Side.CPU)
		BetType.RAISE:
			action_log_label.text = "Player raises $" + str(curr_player_bet)
			process_next_action(Game.Side.CPU)
		BetType.CALL:
			action_log_label.text = "Player calls $" + str(curr_player_bet)
			if is_cpu_all_in:
				cpu.display_hand()
			go_to_next_phase_with_delay(1)
		BetType.ALL_IN:
			action_log_label.text = "Player All In!"
			is_player_all_in = true
			if is_cpu_all_in or curr_player_bet <= curr_cpu_bet:
				cpu.display_hand()
				go_to_next_phase_with_delay(1)
			else:
				process_next_action(Game.Side.CPU)

func on_cpu_bet(amount, bet_type):
	cpu_reaction_label.hide()
	action_log.show()
	curr_cpu_bet += amount
	pot_label.text = "Pot: $" + str(curr_player_bet + curr_cpu_bet + pot)
	cpu_chip_count.text = "CPU: $" + str(cpu.curr_bankroll)
	match bet_type:
		BetType.CHECK:
			action_log_label.text = "CPU checks"
			if did_player_check:
				go_to_next_phase_with_delay(1)
			else:
				did_cpu_check = true
				process_next_action(Game.Side.PLAYER)
		BetType.RAISE:
			action_log_label.text = "CPU raises $" + str(curr_cpu_bet)
			process_next_action(Game.Side.PLAYER)
		BetType.CALL:
			action_log_label.text = "CPU calls $" + str(curr_cpu_bet)
			if is_player_all_in:
				cpu.display_hand()
			go_to_next_phase_with_delay(1)
		BetType.ALL_IN:
			action_log_label.text = "CPU All In!"
			is_cpu_all_in = true
			if is_player_all_in or curr_cpu_bet <= curr_player_bet:
				cpu.display_hand()
				go_to_next_phase_with_delay(1)
			else:
				process_next_action(Game.Side.PLAYER)

func go_to_next_phase_with_delay(delay: int):
	player_action_buttons.hide()
	var callable = Callable(self, "go_to_next_phase")
	delay_action(callable, delay)

func go_to_next_phase():
	action_log.hide()
	pot += curr_player_bet + curr_cpu_bet
	curr_player_bet = 0
	curr_cpu_bet = 0
	var is_one_side_all_in = is_player_all_in or is_cpu_all_in
	did_player_check = false
	did_cpu_check = false
	cpu.did_reraise = false
	match curr_phase:
		GamePhase.PREFLOP:
			deal_cards_on_table(3)
			curr_phase = GamePhase.FLOP
			process_next_action(big_blind_side, is_one_side_all_in)
		GamePhase.FLOP:
			deal_cards_on_table(1)
			curr_phase = GamePhase.TURN
			process_next_action(big_blind_side, is_one_side_all_in)
		GamePhase.TURN:
			deal_cards_on_table(1)
			curr_phase = GamePhase.RIVER
			process_next_action(big_blind_side, is_one_side_all_in)
		GamePhase.RIVER:
			cpu.display_hand()
			curr_phase = GamePhase.SHOWDOWN
			check_winner()
	cpu.react_to_phase()

func handle_cpu_action():
	cpu.do_action()

func blind_bet(amount, side: Game.Side):
	action_log.show()
	if side == Side.PLAYER:
		if player.curr_bankroll == 0:
			is_player_all_in = true
			action_log_label.text = "Player All In!"
		else:
			if big_blind_side == Side.PLAYER:
				action_log_label.text = "Player (Big Blind): $" + str(amount)
			else:
				action_log_label.text = "Player (Small Blind): $" + str(amount)
		if is_cpu_all_in:
			player.display_hand()
		curr_player_bet = amount
	elif side == Side.CPU:
		if cpu.curr_bankroll == 0:
			is_cpu_all_in = true
			action_log_label.text = "CPU All In!"
		else:
			if big_blind_side == Side.CPU:
				action_log_label.text = "CPU (Big Blind): $" + str(amount)
			else:
				action_log_label.text = "CPU (Small Blind): $" + str(amount)
		if is_player_all_in:
			cpu.display_hand()
		curr_cpu_bet = amount
	pot_label.text = "Pot: $" + str(curr_player_bet + curr_cpu_bet + pot)
	player_chip_count.text = "Player: $" + str(player.curr_bankroll)
	cpu_chip_count.text = "CPU: $" + str(cpu.curr_bankroll)

func go_to_next_cpu():
	if cpu.curr_difficulty == CPUCardPlayer.Difficulty.HARD:
		get_tree().change_scene_to_file("res://scenes/Victory.tscn")
	else:
		cpu.go_to_next_difficulty()

func start_new_hand():
	if hand_winner == Side.PLAYER:
		player.curr_bankroll += pot
	elif hand_winner == Side.CPU:
		cpu.curr_bankroll += pot
	else:
		player.curr_bankroll += round(pot / 2)
		cpu.curr_bankroll += round(pot / 2)
	if player.curr_bankroll == 0:
		get_tree().change_scene_to_file("res://scenes/GameOver.tscn")
	elif cpu.curr_bankroll == 0:
		go_to_next_cpu()
	reset_game_state()

func new_game():
	get_tree().reload_current_scene()

func reset_game_state():
	pot = 0
	pot_label.text = "Pot: $0"
	is_player_all_in = false
	is_cpu_all_in = false
	did_player_check = false
	did_cpu_check = false
	cpu.did_reraise = false
	player_chip_count.text = "Player: $" + str(player.curr_bankroll)
	cpu_chip_count.text = "CPU: $" + str(cpu.curr_bankroll)
	showdown_result.hide()
	action_log.hide()
	for c in player.cards_in_hand:
		c.queue_free()
	for c in cpu.cards_in_hand:
		c.queue_free()
	for c in curr_community_cards:
		c.queue_free()
	curr_community_cards = []
	player.cards_in_hand = []
	cpu.cards_in_hand = []
	curr_player_bet = 0
	curr_cpu_bet = 0
	curr_phase = GamePhase.PREFLOP
	deck = []
	next_card_x_pos = FLOP_START_X # For positioning flop cards at the middle of the table (fix this later)
	cpu.neutral_react()
	init_game()

func check_winner():
	showdown_result.show()
	var player_hand = get_best_hand_comm_cards(player.cards_in_hand, curr_community_cards)
	var cpu_hand = get_best_hand_comm_cards(cpu.cards_in_hand, curr_community_cards)
	var compare_result = compare_hands(player_hand, cpu_hand)
	if compare_result == 1:
		showdown_win_label.text = "Player Wins!\nHand: " + hand_type_names[player_hand.hand_type] + "\nWinnings: $" + str(pot)
		hand_winner = Side.PLAYER
		cpu.lose_reaction()
	elif compare_result == -1:
		showdown_win_label.text = "CPU Wins!\nHand: " + hand_type_names[cpu_hand.hand_type]
		hand_winner = Side.CPU
		cpu.win_reaction()
	else:
		showdown_win_label.text = "Tie!\nWinnings:" + str(pot / 2)
		hand_winner = Side.BOTH

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
		# -------------------- TIEBREAKER LOGIC --------------------
		# If pair, three of a kind, or 4 of a kind, compare highest set rank. (If full house, compare the pair if the 3ok is the same)
		var set_types = [HandTypes.PAIR, HandTypes.THREE_OF_A_KIND, HandTypes.FOUR_OF_A_KIND, HandTypes.FULL_HOUSE]
		if set_types.has(hand1_type):
			return compare_sets(hand1.cards, hand2.cards)
		# If two pair, compare the highest ranked pair. If same, compare lower ranked pair. If still same, compare highest card outside of set
		elif hand1_type == HandTypes.TWO_PAIR:
			return compare_two_pair(hand1.cards, hand2.cards)
		# Otherwise, we just look at the highest card in the hand (flushes/straights comprise all cards in hand)
		else:
			return compare_high_card(hand1.cards, hand2.cards)

func compare_high_card(hand1, hand2):
	var highest_hand1_card = get_highest_card(hand1)
	var highest_hand2_card = get_highest_card(hand2)
	if highest_hand1_card > highest_hand2_card:
		return 1
	elif highest_hand2_card > highest_hand1_card:
		return -1
	else:
		return 0

func compare_two_pair(hand1, hand2):
	var hand1_mapping = get_rank_mapping(hand1)["mapping"]
	var hand2_mapping = get_rank_mapping(hand2)["mapping"]
	var high_pair1 = _get_highest_rank_in_set(hand1_mapping, 2)
	var high_pair2 = _get_highest_rank_in_set(hand2_mapping, 2)
	if high_pair1 > high_pair2:
		return 1
	elif high_pair1 < high_pair2:
		return -1
	else:
		var low_pair1 = _get_lowest_rank_in_set(hand1_mapping, 2)
		var low_pair2 = _get_lowest_rank_in_set(hand2_mapping, 2)
		if low_pair1 > low_pair2:
			return 1
		elif low_pair1 < low_pair2:
			return -1
		else:
			return compare_high_card(hand1, hand2)

func compare_sets(hand1, hand2):
	var hand1_rank_mapping = get_rank_mapping(hand1)["mapping"]
	var hand2_rank_mapping = get_rank_mapping(hand2)["mapping"]
	for i in range(0, 4):
		# Check all 4 of a kind, 3 of a kind, pair, down to high card
		var set_type_to_check = 4 - i
		var highest_rank1 = _get_highest_rank_in_set(hand1_rank_mapping, set_type_to_check)
		var highest_rank2 = _get_highest_rank_in_set(hand2_rank_mapping, set_type_to_check)
		if highest_rank1 > highest_rank2:
			return 1
		elif highest_rank1 < highest_rank2:
			return -1
	return 0

func _get_highest_rank_in_set(hand_rank_mapping, set_type_to_check):
	var highest_rank_in_set = 0
	for key in hand_rank_mapping.keys():
		if hand_rank_mapping[key] == set_type_to_check:
			highest_rank_in_set = max(highest_rank_in_set, RANKS.find(key))
	return highest_rank_in_set

func _get_lowest_rank_in_set(hand_rank_mapping, set_type_to_check):
	var lowest_rank_in_set = INF
	for key in hand_rank_mapping.keys():
		if hand_rank_mapping[key] == set_type_to_check:
			lowest_rank_in_set = min(lowest_rank_in_set, RANKS.find(key))
	return lowest_rank_in_set

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

func fold(side: Game.Side, message = null):
	cpu_reaction_label.hide()
	pot += curr_player_bet + curr_cpu_bet
	showdown_result.show()
	if side == Game.Side.PLAYER:
		if message != null:
			showdown_win_label.text = message
		else:
			showdown_win_label.text = "Player folded...\nCPU Wins!"
		hand_winner = Side.CPU
	elif side == Game.Side.CPU:
		if message != null:
			showdown_win_label.text = message
		else:
			showdown_win_label.text = "CPU folded...\nPlayer wins!"
		hand_winner = Side.PLAYER
