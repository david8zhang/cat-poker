class_name Hand
extends Node2D

@export var card_scene: PackedScene
var cards_in_hand = []

func get_cards(cards):
	for card in cards:
		var new_card = card_scene.instantiate() as Card
		new_card.rank = card.rank
		new_card.suit = card.suit
		cards_in_hand.append(new_card)
		add_child(new_card)