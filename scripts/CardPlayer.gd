class_name CardPlayer
extends Node2D

const STARTING_BANKROLL = 200
const SMALL_RAISE_AMOUNT = 10
const BIG_RAISE_AMOUNT = 30

@export var card_scene: PackedScene
@onready var game = get_node("/root/Game") as Game

var cards_in_hand = []
var curr_bankroll = STARTING_BANKROLL
var is_dealer = false
var curr_bet = 0

# Types of starting hands
enum HoleCardType {
	POCKET_ACES,
	POCKET_KINGS,
	POCKET_QUEENS,
	POCKET_JACKS,
	POCKET_TENS,
	A_K,
	A_Q,
	A_J,
	A_10,
	PAIR,
	SUITED_CONNECTOR,
	HIGH_CARD,
	TRASH
}

signal bet(amount, bet_type)

func get_cards(cards, relative_pos = Vector2(0, 0)):
	var curr_pos = relative_pos
	for card in cards:
		var new_card = card_scene.instantiate() as Card
		new_card.position = curr_pos
		new_card.rank = card.rank
		new_card.suit = card.suit
		cards_in_hand.append(new_card)
		add_child(new_card)

		# TODO: Figure out how to center cards
		curr_pos.x += new_card.sprite.texture.get_width() / 2 * new_card.sprite.scale.x

func display_hand():
	for card in cards_in_hand:
		card.show_card()

func make_bet(amount, bet_type):
	amount = min(amount, curr_bankroll)
	curr_bankroll -= amount
	bet.emit(amount, bet_type)

func check():
	make_bet(0, Game.BetType.CHECK)

func call_bet():
	pass

func blind_bet(_amount):
	pass

func get_hole_cards_type():
	if is_pocket(cards_in_hand, "A"):
		return HoleCardType.POCKET_ACES
	elif is_pocket(cards_in_hand, "K"):
		return HoleCardType.POCKET_KINGS
	elif is_pocket(cards_in_hand, "Q"):
		return HoleCardType.POCKET_QUEENS
	elif is_pocket(cards_in_hand, "J"):
		return HoleCardType.POCKET_JACKS
	elif is_pocket(cards_in_hand, "10"):
		return HoleCardType.POCKET_TENS
	elif is_specific_hand(cards_in_hand, "A", "K"):
		return HoleCardType.A_K
	elif is_specific_hand(cards_in_hand, "A", "Q"):
		return HoleCardType.A_Q
	elif is_specific_hand(cards_in_hand, "A", "J"):
		return HoleCardType.A_J
	elif is_specific_hand(cards_in_hand, "A", "10"):
		return HoleCardType.A_10
	elif is_pair(cards_in_hand):
		return HoleCardType.PAIR
	elif is_suited(cards_in_hand) and is_connector(cards_in_hand):
		return HoleCardType.SUITED_CONNECTOR
	elif is_high_card(cards_in_hand):
		return HoleCardType.HIGH_CARD
	return HoleCardType.TRASH

func is_pocket(cards, rank_to_check):
	return cards[0].rank == rank_to_check and cards[1].rank == rank_to_check

func is_pair(cards):
	return cards[0].rank == cards[1].rank

func is_connector(cards):
	var card1_rank = game.RANKS.find(cards[0].rank)
	var card2_rank = game.RANKS.find(cards[1].rank)
	return abs(card1_rank - card2_rank) == 1

func is_suited(cards):
	return cards[0].suit == cards[1].suit

func is_specific_hand(cards, rank1, rank2):
	return (cards[0].rank == rank1 and cards[1].rank == rank2) or (cards[0].rank == rank2 and cards[1].rank == rank1)

func is_high_card(cards):
	var high_ranks = ["J", "Q", "K", "A"]
	return high_ranks.has(cards[0].rank) or high_ranks.has(cards[1].rank)
