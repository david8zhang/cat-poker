class_name HardCPUDecisionMaker
extends CPUDecisionMaker

func react_to_phase():
	cpu.neutral_react()

func respond_to_all_in(best_hand, is_pre_flop):
	game.fold(Game.Side.CPU)

func respond_to_raise(best_hand, is_pre_flop):
	cpu.call_bet()

func respond_to_check(best_hand, is_pre_flop):
	cpu.check()

func place_first_bet(best_hand, is_pre_flop):
	cpu.check()