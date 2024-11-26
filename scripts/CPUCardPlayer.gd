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
var did_reraise = false

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
	amount = min(amount, curr_bankroll)
	var amount_added = amount - game.curr_cpu_bet
	curr_bankroll -= amount_added
	bet.emit(amount)

func raise(raise_amount):
	var amount_to_call = 0
	if game.curr_player_bet > game.curr_cpu_bet:
		amount_to_call = game.curr_player_bet - game.curr_cpu_bet
	bet.emit(amount_to_call + raise_amount)

func is_curr_hand_better_than_community():
	match game.curr_phase:
		Game.GamePhase.FLOP:
			var best_hand = get_best_hand_flop()
			var community_hand = Game.Hand.new()
			community_hand.cards = game.curr_community_cards
			if game.is_three_of_a_kind(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.THREE_OF_A_KIND
			if game.is_pair(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.PAIR
			else:
				community_hand.hand_type = Game.HandTypes.HIGH_CARD
			print("Community hand: " + get_enum_name(Game.HandTypes, community_hand.hand_type))
			print("CPU hand: " + get_enum_name(Game.HandTypes, best_hand.hand_type))
			return game.compare_hands(best_hand, community_hand) == 1
		Game.GamePhase.TURN:
			var best_hand = get_best_hand_turn()
			var community_hand = Game.Hand.new()
			community_hand.cards = game.curr_community_cards
			if game.is_four_of_a_kind(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.FOUR_OF_A_KIND
			elif game.is_three_of_a_kind(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.THREE_OF_A_KIND
			elif game.is_two_pair(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.TWO_PAIR
			if game.is_pair(game.curr_community_cards):
				community_hand.hand_type = Game.HandTypes.PAIR
			else:
				community_hand.hand_type = Game.HandTypes.HIGH_CARD
			print("Community hand: " + get_enum_name(Game.HandTypes, community_hand.hand_type))
			print("CPU hand: " + get_enum_name(Game.HandTypes, best_hand.hand_type))
			return game.compare_hands(best_hand, community_hand) == 1
		Game.GamePhase.RIVER:
			var community_hand = game.get_best_5card_hand(game.curr_community_cards)
			var best_hand = get_best_hand_river()
			print("Community hand: " + get_enum_name(Game.HandTypes, community_hand.hand_type))
			print("CPU hand: " + get_enum_name(Game.HandTypes, best_hand.hand_type))
			return game.compare_hands(best_hand, community_hand) == 1

# Reaction behavior (for easy CPU)
func react_to_phase():
	# TODO: Compare the current hand with the best hand using JUST community cards (otherwise we're reacting to a hand the opp may also have)
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
			if is_curr_hand_better_than_community():
				var best_hand_so_far = get_best_hand_flop().hand_type
				if VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or STRONG_HAND_TYPES.has(best_hand_so_far):
					very_positive_react()
				elif DECENT_HAND_TYPES.has(best_hand_so_far):
					slightly_positive_react()
				elif is_straight_draw_flop() or is_flush_draw_flop():
					slightly_positive_react()
				else:
					neutral_react()
			else:
				neutral_react()
		Game.GamePhase.TURN:
			if is_curr_hand_better_than_community():
				var best_hand_so_far = get_best_hand_turn().hand_type
				if VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or STRONG_HAND_TYPES.has(best_hand_so_far):
					very_positive_react()
				elif DECENT_HAND_TYPES.has(best_hand_so_far):
					slightly_positive_react()
				elif is_straight_draw_turn() or is_flush_draw_turn():
					slightly_positive_react()
				else:
					neutral_react()
			else:
				neutral_react()
		Game.GamePhase.RIVER:
			if is_curr_hand_better_than_community():
				var best_hand_so_far = get_best_hand_river().hand_type
				if VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or STRONG_HAND_TYPES.has(best_hand_so_far):
					slightly_positive_react()
				elif DECENT_HAND_TYPES.has(best_hand_so_far):
					slightly_positive_react()
				else:
					very_negative_react()
			else:
				neutral_react()

func do_action():
	var best_hand = Game.Hand.new()
	var is_pre_flop = false
	match game.curr_phase:
		Game.GamePhase.PREFLOP:
			is_pre_flop = true
		Game.GamePhase.FLOP:
			best_hand = get_best_hand_flop()
		Game.GamePhase.TURN:
			best_hand = get_best_hand_turn()
		Game.GamePhase.RIVER:
			best_hand = get_best_hand_river()

	# If player goes all in
	if game.curr_player_bet == game.player.curr_bankroll:
		print("Responding to player all-in...")
		if is_pre_flop:
			var hole_card_type = get_hole_cards_type()
			if STRONG_HOLE_CARD_TYPES.has(hole_card_type):
				# Fold 25% of the time, otherwise call
				var should_fold = randi_range(0, 3) == 1
				if should_fold:
					game.fold(Game.Side.CPU)
				else:
					call_bet()
			else:
				# Fold 66% of the time, otherwise call
				var should_fold = randi_range(0, 2) != 1
				if should_fold:
					game.fold(Game.Side.CPU)
				else:
					call_bet()
		else:
			# Only call if we have the strongest hands
			if VERY_STRONG_HAND_TYPES.has(best_hand.hand_type):
				call_bet()
			else:
				var should_fold = randi_range(0, 3) == 1
				if should_fold:
					game.fold(Game.Side.CPU)
				else:
					call_bet()

	# If player raises:
	if game.curr_player_bet > game.curr_cpu_bet:
		print("Responding to player raise...")
		# CPU only ever re-raises once
		if did_reraise:
			call_bet()
		elif is_pre_flop:
			var hole_card_type = get_hole_cards_type()
			if hole_card_type == HoleCardType.TRASH:
				var should_fold = randi_range(0, 1) == 1
				if should_fold:
					game.fold(Game.Side.CPU)
				else:
					call_bet()
			elif STRONG_HOLE_CARD_TYPES.has(hole_card_type):
				did_reraise = true
				raise(SMALL_RAISE_AMOUNT)
			else:
				call_bet()
		else:
			var best_hand_type = best_hand.hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_type):
				raise(BIG_RAISE_AMOUNT)
			elif STRONG_HAND_TYPES.has(best_hand_type):
				raise(SMALL_RAISE_AMOUNT)
			elif DECENT_HAND_TYPES.has(best_hand_type):
				call_bet()
			else:
				game.fold(Game.Side.CPU)
			
			
	# If player checks
	elif game.curr_player_bet == 0:
		print("Responding to player check...")
		if is_pre_flop:
			var hole_card_type = get_hole_cards_type()
			if STRONG_HOLE_CARD_TYPES.has(hole_card_type):
				raise(SMALL_RAISE_AMOUNT)
			else:
				check()
		else:
			var best_hand_type = best_hand.hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_type):
				raise(BIG_RAISE_AMOUNT)
			elif STRONG_HAND_TYPES.has(best_hand_type):
				raise(SMALL_RAISE_AMOUNT)
			else:
				check()
			
	# If CPU is the first to act
	else:
		if is_pre_flop:
			var hole_card_type = get_hole_cards_type()
			if STRONG_HOLE_CARD_TYPES.has(hole_card_type):
				raise(SMALL_RAISE_AMOUNT)
			else:
				check()
		else:
			var best_hand_type = best_hand.hand_type
			if VERY_STRONG_HAND_TYPES.has(best_hand_type):
				raise(BIG_RAISE_AMOUNT)
			elif STRONG_HAND_TYPES.has(best_hand_type):
				raise(SMALL_RAISE_AMOUNT)
			elif DECENT_HAND_TYPES.has(best_hand_type):
				var should_bet = randi_range(0, 1) == 1
				if should_bet:
					raise(SMALL_RAISE_AMOUNT)
				else:
					check()
			else:
				check()

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
