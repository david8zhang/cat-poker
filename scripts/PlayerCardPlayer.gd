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

func _on_small_raise_pressed():
	var amount_to_call = 0
	if game.curr_cpu_bet > game.curr_player_bet:
		amount_to_call = game.curr_cpu_bet - game.curr_player_bet
	make_bet(amount_to_call + SMALL_RAISE_AMOUNT, Game.BetType.RAISE)

func _on_big_raise_pressed():
	var amount_to_call = 0
	if game.curr_cpu_bet > game.curr_player_bet:
		amount_to_call = game.curr_cpu_bet - game.curr_player_bet
	make_bet(amount_to_call + BIG_RAISE_AMOUNT, Game.BetType.RAISE)

func _on_all_in_pressed():
	make_bet(curr_bankroll, Game.BetType.ALL_IN)

func _on_fold_pressed():
	game.fold(Game.Side.PLAYER)

func call_bet():
	var amount_to_call = game.curr_cpu_bet - game.curr_player_bet
	make_bet(amount_to_call, Game.BetType.CALL)

func blind_bet(amount):
	curr_bankroll -= amount
	game.blind_bet(amount, Game.Side.PLAYER)