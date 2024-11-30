class_name EasyCPUDecisionMaker
extends CPUDecisionMaker

# Reaction behavior (for easy CPU)
func react_to_phase():
	match game.curr_phase:
		Game.GamePhase.PREFLOP:
			var type_of_hole_cards = cpu.get_hole_cards_type()
			if cpu.STRONG_HOLE_CARD_TYPES.has(type_of_hole_cards):
				cpu.very_positive_react()
			elif cpu.DECENT_HOLE_CARD_TYPES.has(type_of_hole_cards):
				cpu.positive_face_react()
			elif type_of_hole_cards == CPUCardPlayer.HoleCardType.TRASH:
				cpu.negative_face_react()
			else:
				cpu.neutral_react()
		Game.GamePhase.FLOP:
			if cpu.is_curr_hand_better_than_community():
				var best_hand_so_far = cpu.get_best_hand_flop().hand_type
				if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or cpu.STRONG_HAND_TYPES.has(best_hand_so_far):
					cpu.very_positive_react()
				elif cpu.DECENT_HAND_TYPES.has(best_hand_so_far):
					cpu.positve_face_react()
				elif cpu.is_straight_draw_flop() or cpu.is_flush_draw_flop():
					cpu.positive_tail_react()
				else:
					cpu.neutral_react()
			else:
				cpu.neutral_react()
		Game.GamePhase.TURN:
			if cpu.is_curr_hand_better_than_community():
				var best_hand_so_far = cpu.get_best_hand_turn().hand_type
				if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or cpu.STRONG_HAND_TYPES.has(best_hand_so_far):
					cpu.very_positive_react()
				elif cpu.DECENT_HAND_TYPES.has(best_hand_so_far):
					cpu.positive_face_react()
				elif cpu.is_straight_draw_turn() or cpu.is_flush_draw_turn():
					cpu.positive_tail_react()
				else:
					cpu.neutral_react()
			else:
				cpu.neutral_react()
		Game.GamePhase.RIVER:
			if cpu.is_curr_hand_better_than_community():
				var best_hand_so_far = cpu.get_best_hand_river().hand_type
				if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_so_far) or cpu.STRONG_HAND_TYPES.has(best_hand_so_far):
					cpu.very_positive_react()
				elif cpu.DECENT_HAND_TYPES.has(best_hand_so_far):
					cpu.positive_face_react()
				elif best_hand_so_far == Game.HandTypes.PAIR:
					cpu.neutral_react()
				else:
					cpu.negative_face_react()
			else:
				cpu.neutral_react()

func respond_to_check(best_hand, is_pre_flop):
	print("Responding to player check...")
	if is_pre_flop:
		var hole_card_type = cpu.get_hole_cards_type()
		if cpu.STRONG_HOLE_CARD_TYPES.has(hole_card_type):
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		else:
			cpu.check()
	else:
		var best_hand_type = best_hand.hand_type
		if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.BIG_RAISE_AMOUNT)
		elif cpu.STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		else:
			do_bluff()

func place_first_bet(best_hand, is_pre_flop):
	if is_pre_flop:
		var hole_card_type = cpu.get_hole_cards_type()
		if cpu.STRONG_HOLE_CARD_TYPES.has(hole_card_type):
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		else:
			cpu.check()
	else:
		var best_hand_type = best_hand.hand_type
		if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.BIG_RAISE_AMOUNT)
		elif cpu.STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		elif cpu.DECENT_HAND_TYPES.has(best_hand_type):
			var should_bet = randi_range(0, 1) == 1
			if should_bet:
				cpu.raise(cpu.SMALL_RAISE_AMOUNT)
			else:
				cpu.check()
		else:
			do_bluff()

func do_bluff():
		# Bluff with 25% chance
	var should_bluff = randi_range(1, 4) == 1
	if should_bluff:
		cpu.curr_face_reaction = CPUCardPlayer.FaceReactionTypes.DEVIOUS
		cpu.curr_tail_reaction = CPUCardPlayer.TailReactionTypes.QUESTION
		cpu.update_curr_reaction()
		cpu.raise(cpu.SMALL_RAISE_AMOUNT)
	else:
		cpu.check()

func respond_to_raise(best_hand, is_pre_flop):
	if cpu.did_reraise:
		cpu.call_bet()
	elif is_pre_flop:
		var hole_card_type = cpu.get_hole_cards_type()
		if hole_card_type == CPUCardPlayer.HoleCardType.TRASH:
			var should_fold = randi_range(0, 1) == 1
			if should_fold:
				game.fold(Game.Side.CPU)
			else:
				cpu.call_bet()
		elif cpu.STRONG_HOLE_CARD_TYPES.has(hole_card_type):
			cpu.did_reraise = true
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		else:
			cpu.call_bet()
	else:
		var best_hand_type = best_hand.hand_type
		if cpu.VERY_STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.BIG_RAISE_AMOUNT)
		elif cpu.STRONG_HAND_TYPES.has(best_hand_type):
			cpu.raise(cpu.SMALL_RAISE_AMOUNT)
		elif cpu.DECENT_HAND_TYPES.has(best_hand_type) or \
			cpu.is_straight_draw_for_phase(game.curr_phase) or \
			cpu.is_flush_draw_for_phase(game.curr_phase):
			cpu.call_bet()
		else:
			# Fold at different rates depending on phase
			var should_fold = false
			if game.curr_phase == Game.GamePhase.FLOP:
				should_fold = randi_range(1, 5) == 1 # Fold 20% of the time if it's the flop
			elif game.curr_phase == Game.GamePhase.TURN:
				should_fold = randi_range(1, 3) == 1 # Fold 33% of the time if it's the turn
			elif game.curr_phase == Game.GamePhase.RIVER:
				should_fold = randi_range(1, 2) == 1 # Fold 50% of the time if it's the river
			if should_fold:
				game.fold(Game.Side.CPU)
			else:
				cpu.call_bet()

func respond_to_all_in(best_hand, is_pre_flop):
	print("Responding to player all-in...")
	var is_call = false
	if is_pre_flop:
		var hole_card_type = cpu.get_hole_cards_type()
		var should_fold = false
		if cpu.STRONG_HOLE_CARD_TYPES.has(hole_card_type):
			# Fold 25% of the time, otherwise call
			should_fold = randi_range(0, 3) == 1
		elif cpu.DECENT_HOLE_CARD_TYPES.has(hole_card_type):
			# Fold 33% of the time, otherwise call
			should_fold = randi_range(0, 2) == 1
		else:
			# Fold 50% of the time, otherwise call
			should_fold = randi_range(0, 1) == 1
		if should_fold:
			game.fold(Game.Side.CPU)
		else:
			is_call = true
	else:
		# Only call if we have the strongest hands
		if cpu.VERY_STRONG_HAND_TYPES.has(best_hand.hand_type):
			is_call = true
		else:
			var should_fold = randi_range(0, 3) == 1
			if should_fold:
				game.fold(Game.Side.CPU)
			else:
				is_call = true
	if is_call:
		cpu.display_hand()
		cpu.call_bet()
