class_name Game
extends Node2D

var deck = []
var communal_cards = []

enum GAME_PHASE {
	PREFLOP,
	FLOP,
	TURN,
	RIVER
}

@onready var player = $Player as CardPlayer
@onready var cpu = $CPU as CardPlayer

const RANKS = ["02", "03", "04", "05", "06", "07", "08", "09", "10", "J", "Q", "A"]
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

	# Initialize players
	player.global_position = Vector2(0, 200)
	cpu.global_position = Vector2(0, -200)

	# shuffle deck
	deck.shuffle()

	#deal cards
	player.get_cards(deal(2))
	cpu.get_cards(deal(2))

	player.display_hand()
	
func deal(num_cards: int):
	var cards = []
	for i in range(0, num_cards):
		cards.append(deck.pop_front())
	return cards