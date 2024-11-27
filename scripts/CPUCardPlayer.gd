class_name CPUCardPlayer
extends CardPlayer

enum FaceReactionTypes {
	NEUTRAL,
	EXCITED,
	SAD,
	ANGRY,
	SURPRISED,
	DEVIOUS
}

enum TailReactionTypes {
	NEUTRAL,
	QUESTION,
	POSITIVE,
	NEGATIVE
}

# Hole card classifications
const STRONG_HOLE_CARD_TYPES = [
	HoleCardType.POCKET_ACES,
	HoleCardType.POCKET_KINGS,
	HoleCardType.POCKET_QUEENS,
	HoleCardType.POCKET_JACKS,
	HoleCardType.POCKET_TENS,
	HoleCardType.A_K,
	HoleCardType.A_Q,
	HoleCardType.A_J,
	HoleCardType.A_10,
]
const DECENT_HOLE_CARD_TYPES = [
	HoleCardType.PAIR,
	HoleCardType.SUITED_CONNECTOR
]

# Hand classifications
const VERY_STRONG_HAND_TYPES = [
	Game.HandTypes.FULL_HOUSE,
	Game.HandTypes.FOUR_OF_A_KIND,
	Game.HandTypes.STRAIGHT_FLUSH
]
const STRONG_HAND_TYPES = [
	Game.HandTypes.STRAIGHT,
	Game.HandTypes.FLUSH
]
const DECENT_HAND_TYPES = [
	Game.HandTypes.TWO_PAIR,
	Game.HandTypes.THREE_OF_A_KIND,
]

var curr_face_reaction = FaceReactionTypes.NEUTRAL
var curr_tail_reaction = TailReactionTypes.NEUTRAL

func _ready():
	game.all_ready.connect(all_ready)

func all_ready():
	update_curr_reaction()

func update_curr_reaction():
	var cpu_reaction_label = game.cpu_reaction_label
	var neutral_face_reaction_label = get_enum_name(FaceReactionTypes, curr_face_reaction)
	var neutral_tail_reaction_label = get_enum_name(TailReactionTypes, curr_tail_reaction)
	cpu_reaction_label.text = "Face: " + neutral_face_reaction_label + "\nTail: " + neutral_tail_reaction_label

func get_enum_name(enum_dict: Dictionary, value: int) -> String:
	for name_key in enum_dict.keys():
		if enum_dict[name_key] == value:
				return name_key
	return "Unknown"

func call_bet():
	var amount_to_call = game.curr_player_bet - game.curr_cpu_bet
	curr_bankroll -= amount_to_call
	bet.emit(game.curr_player_bet)

func blind_bet(amount):
	curr_bankroll -= amount
	game.blind_bet(amount, Game.Side.CPU)

func make_bet(amount):
	var amount_added = amount - game.curr_cpu_bet
	curr_bankroll -= amount_added
	bet.emit(amount)

func raise(raise_amount):
	var amount_to_call = 0
	if game.curr_player_bet > game.curr_cpu_bet:
		amount_to_call = game.curr_player_bet - game.curr_cpu_bet
	bet.emit(amount_to_call + raise_amount)

# Reaction behavior (for easy CPU)
func react_to_phase():
	match game.curr_phase:
		Game.GamePhase.PREFLOP:
			var type_of_hole_cards = get_hole_cards_type()
			if STRONG_HOLE_CARD_TYPES.has(type_of_hole_cards):
				very_positive_react()
			elif DECENT_HOLE_CARD_TYPES.has(type_of_hole_cards):
				slightly_positive_react()
			else:
				slightly_negative_react()
		Game.GamePhase.FLOP:
			var best_hand_so_far = get_best_hand_flop().hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_so_far):
				very_positive_react()
			elif STRONG_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			elif DECENT_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			elif is_straight_draw_flop() or is_flush_draw_flop():
				slightly_positive_react()
			else:
				neutral_react()
		Game.GamePhase.TURN:
			var best_hand_so_far = get_best_hand_turn().hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_so_far):
				very_positive_react()
			elif STRONG_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			elif DECENT_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			elif is_straight_draw_turn() or is_flush_draw_turn():
				slightly_positive_react()
			else:
				neutral_react()
			pass
		Game.GamePhase.RIVER:
			var best_hand_so_far = get_best_hand_turn().hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_so_far):
				very_positive_react()
			elif STRONG_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			elif DECENT_HAND_TYPES.has(best_hand_so_far):
				slightly_positive_react()
			else:
				very_negative_react()
			pass

func neutral_react():
	curr_face_reaction = FaceReactionTypes.NEUTRAL
	curr_tail_reaction = TailReactionTypes.NEUTRAL
	update_curr_reaction()

func very_positive_react():
	curr_face_reaction = FaceReactionTypes.EXCITED
	curr_tail_reaction = TailReactionTypes.POSITIVE
	update_curr_reaction()

func slightly_positive_react():
	curr_face_reaction = FaceReactionTypes.NEUTRAL
	curr_tail_reaction = TailReactionTypes.POSITIVE
	update_curr_reaction()

func very_negative_react():
	curr_face_reaction = FaceReactionTypes.SAD
	curr_tail_reaction = TailReactionTypes.NEGATIVE
	update_curr_reaction()

func slightly_negative_react():
	curr_face_reaction = FaceReactionTypes.NEUTRAL
	curr_tail_reaction = TailReactionTypes.NEGATIVE
	update_curr_reaction()

# Deceptive positive reactions are where face + tail don't match
func deceptive_positive_react():
	curr_face_reaction = FaceReactionTypes.EXCITED
	curr_tail_reaction = TailReactionTypes.NEGATIVE
	update_curr_reaction()

func deceptive_negative_react():
	curr_face_reaction = FaceReactionTypes.SAD
	curr_tail_reaction = TailReactionTypes.POSITIVE
	update_curr_reaction()

# Surprise = either really good OR really bad (Tail react as a clue)
func surprised_react(is_positive):
	curr_face_reaction = FaceReactionTypes.SURPRISED
	curr_tail_reaction = TailReactionTypes.POSITIVE if is_positive else TailReactionTypes.NEGATIVE
	update_curr_reaction()

func is_reverse_react():
	# Reverse -> positive reaction at a bad hand, negative reaction at a good hand
	pass

# Check if close to getting a straight on the flop/turn
func is_straight_draw(hand_to_check):
	var ranks = hand_to_check.map(func(card): return game.RANKS.find(card.rank))
	var unique_ranks = []
	for r in ranks:
		if r not in unique_ranks:
			unique_ranks.append(r)

	# If Ace is present, check wheel straights also
	if 12 in ranks:
		unique_ranks.append(-1)
	
	for i in range(unique_ranks.size() - 3):  # Only check groups of 4
		var sequence = unique_ranks.slice(i, i + 4)
		# Check if the sequence forms a gap of 4 numbers
		if sequence[-1] - sequence[0] <= 4:
				return true
	return false

# Check if close to getting a flush on the flop/turn
func is_flush_draw(hand_to_check):
	var suit_mapping = {}
	for card in hand_to_check:
		if suit_mapping.has(card.suit):
			suit_mapping[card.suit] += 1
		else:
			suit_mapping[card.suit] = 1
	for suit in suit_mapping.keys():
		if suit_mapping[suit] == 4:
			return true
	return false

func is_straight_draw_flop():
	var hand_to_check = cards_in_hand + game.curr_community_cards
	return is_straight_draw(hand_to_check)

func is_straight_draw_turn():
	for card in cards_in_hand:
		var hand_to_check = [card] + game.curr_community_cards
		if is_straight_draw(hand_to_check):
			return true
	var card_combs = game.generate_combinations(game.curr_community_cards, 3)
	for comb in card_combs:
		var hand_to_check = comb + cards_in_hand
		if is_straight_draw(hand_to_check):
			return true
	return false

func is_flush_draw_flop():
	var hand_to_check = cards_in_hand + game.curr_community_cards
	return is_flush_draw(hand_to_check)

func is_flush_draw_turn():
	for card in cards_in_hand:
		var hand_to_check = [card] + game.curr_community_cards
		if is_flush_draw(hand_to_check):
			return true
	var card_combs = game.generate_combinations(game.curr_community_cards, 3)
	for comb in card_combs:
		var hand_to_check = comb + cards_in_hand
		if is_flush_draw(hand_to_check):
			return true
	return false

# Get the best possible hand with cards on the board so far
func get_best_hand_flop():
	var hand_to_check = cards_in_hand + game.curr_community_cards
	return game.get_best_5card_hand(hand_to_check)

func get_best_hand_turn():
	var best_hand_so_far = null
	for card in cards_in_hand:
		var hand_to_check = [card] + game.curr_community_cards
		var best_hand = game.get_best_5card_hand(hand_to_check)
		if best_hand_so_far == null or game.compare_hands(best_hand, best_hand_so_far) == 1:
			best_hand_so_far = best_hand
	# Check all 3-card combinations of 4 cards on the board
	var card_combs = game.generate_combinations(game.curr_community_cards, 3)
	for comb in card_combs:
		var hand_to_check = comb + cards_in_hand
		var best_hand = game.get_best_5card_hand(hand_to_check)
		if best_hand_so_far == null or game.compare_hands(best_hand, best_hand_so_far) == 1:
			best_hand_so_far = best_hand
	return best_hand_so_far

func get_best_hand_river():
	return game.get_best_hand_comm_cards(cards_in_hand, game.curr_community_cards)