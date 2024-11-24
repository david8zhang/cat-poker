class_name PlayerCardPlayer
extends CardPlayer

func _on_check_button_up():
	# Can only check if CPU has not placed a bet yet
	if game.curr_cpu_bet == 0:
		check()

func _on_call_pressed():
	call_bet()

func _on_raise_pressed():
	make_bet(game.curr_cpu_bet + 5) # raise 5

func _on_fold_pressed():
	pass # Replace with function body.

func call_bet():
	bet.emit(game.curr_cpu_bet)

func blind_bet(amount):
	game.blind_bet(amount, Game.Side.PLAYER)
