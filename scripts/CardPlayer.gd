class_name CardPlayer
extends Node2D

const STARTING_BANKROLL = 1000
@export var card_scene: PackedScene
@onready var game = get_node("/root/Game") as Game

var cards_in_hand = []
var curr_bankroll = STARTING_BANKROLL
var is_dealer = false
var curr_bet = 0

signal bet(amount)

func get_cards(cards):
	var curr_pos = Vector2(0, 0)
	for card in cards:
		var new_card = card_scene.instantiate() as Card
		new_card.global_position = curr_pos
		new_card.rank = card.rank
		new_card.suit = card.suit
		cards_in_hand.append(new_card)
		add_child(new_card)

		# TODO: Figure out how to center cards
		curr_pos.x += new_card.sprite.texture.get_width() * 2

func display_hand():
	for card in cards_in_hand:
		card.show_card()

func make_bet(amount):
	curr_bankroll -= amount
	bet.emit(amount)

func check():
	make_bet(0)

func call_bet():
	pass

func blind_bet(_amount):
	pass
