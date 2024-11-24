class_name CPUCardPlayer
extends CardPlayer

func call_bet():
	bet.emit(game.curr_player_bet)

func blind_bet(amount):
	game.blind_bet(amount, Game.Side.CPU)