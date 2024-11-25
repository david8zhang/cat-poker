class_name CPUCardPlayer
extends CardPlayer

func call_bet():
	var amount_to_call = game.curr_player_bet - game.curr_cpu_bet
	curr_bankroll -= amount_to_call
	bet.emit(game.curr_player_bet)

func blind_bet(amount):
	curr_bankroll -= amount
	game.blind_bet(amount, Game.Side.CPU)