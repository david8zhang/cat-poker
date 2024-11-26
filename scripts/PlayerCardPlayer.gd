class_name PlayerCardPlayer
extends CardPlayer

func _on_check_button_up():
	# Can only check if CPU has not placed a bet yet
	if game.curr_cpu_bet == 0:
		check()

func _on_call_pressed():
	# Can only call if CPU has placed a bet
	if game.curr_cpu_bet > 0:
		call_bet()

func _on_raise_pressed():
	make_bet(game.curr_cpu_bet + 5) # raise 5

func _on_fold_pressed():
	pass # Replace with function body.

func call_bet():
	var amount_to_call = game.curr_cpu_bet - game.curr_player_bet
	curr_bankroll -= amount_to_call
	bet.emit(game.curr_cpu_bet)

func blind_bet(amount):
	curr_bankroll -= amount
	game.blind_bet(amount, Game.Side.PLAYER)

func make_bet(amount):
	var amount_added = amount - game.curr_player_bet
	curr_bankroll -= amount_added
	bet.emit(amount)