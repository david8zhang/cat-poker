class_name Game
extends Node2D

var deck = []

@onready var player = $Player as CardPlayer
@onready var cpu = $CPU as CardPlayer

const RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "A"]
const SUITS = ["diamonds", "spades", "hearts", "clubs"]

func _ready():
	# Initialize deck
	for i in range(0, RANKS.size()):
		for j in range(0, SUITS.size()):
			var rank = RANKS[i]
			var suit = SUITS[j]
			deck.append({
				"rank": rank,
				"suit": suit
			})

	# shuffle deck
	deck.shuffle()

	#deal cards
	player.get_cards(deal(2))
	cpu.get_cards(deal(2))
	
func deal(num_cards: int):
	var cards = []
	for i in range(0, num_cards):
		cards.append(deck.pop_front())
	return cards