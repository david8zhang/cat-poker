class_name CardPlayer
extends Node2D

@export var card_scene: PackedScene
var cards_in_hand = []

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
		curr_pos.x += new_card.sprite.texture.get_width() * 1.5

func display_hand():
	for card in cards_in_hand:
		card.show_card()
