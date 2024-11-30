class_name CPUDecisionMaker
extends Node

@onready var game = get_node("/root/Game") as Game
@export var cpu: CPUCardPlayer

func react_to_phase():
	pass

func respond_to_all_in(best_hand, is_pre_flop):
	pass

func respond_to_raise(best_hand, is_pre_flop):
	pass

func respond_to_check(best_hand, is_pre_flop):
	pass

func place_first_bet(best_hand, is_pre_flop):
	pass

func do_action():
	var best_hand = Game.Hand.new()
	var is_pre_flop = false
	match game.curr_phase:
		Game.GamePhase.PREFLOP:
			is_pre_flop = true
		Game.GamePhase.FLOP:
			best_hand = cpu.get_best_hand_flop()
		Game.GamePhase.TURN:
			best_hand = cpu.get_best_hand_turn()
		Game.GamePhase.RIVER:
			best_hand = cpu.get_best_hand_river()

	if game.is_player_all_in:
		respond_to_all_in(best_hand, is_pre_flop)
	elif game.curr_player_bet > game.curr_cpu_bet:
		respond_to_raise(best_hand, is_pre_flop)
	elif game.curr_player_bet == 0:
		respond_to_check(best_hand, is_pre_flop)
	else:
		place_first_bet(best_hand, is_pre_flop)