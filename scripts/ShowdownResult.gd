class_name ShowdownResult
extends Control

@onready var game = get_node("/root/Game") as Game

@onready var result_sprite = $ResultSprite as TextureRect

# CPU Cards
@onready var cpu_hand = $CPUHand as Control
@onready var cpu_card_1 = $CPUHand/LeftCard as TextureRect
@onready var cpu_card_2 = $CPUHand/RightCard as TextureRect

# Player Cards
@onready var player_hand = $PlayerHand as Control
@onready var player_card_1 = $PlayerHand/LeftCard as TextureRect
@onready var player_card_2 = $PlayerHand/RightCard as TextureRect

# Community Cards
@onready var comm_cards = $CommunityCards as Control
@onready var comm_card_1 = $CommunityCards/Card as TextureRect
@onready var comm_card_2 = $CommunityCards/Card2 as TextureRect
@onready var comm_card_3 = $CommunityCards/Card3 as TextureRect
@onready var comm_card_4 = $CommunityCards/Card4 as TextureRect
@onready var comm_card_5 = $CommunityCards/Card5 as TextureRect

class ShowdownResultCard:
	var texture_rect: TextureRect
	var card: Card

func show_result(winning_side: Game.Side):
	match winning_side:
		Game.Side.PLAYER:
			result_sprite.texture = load("res://sprites/backgrounds/win_hand.png")
		Game.Side.CPU:
			result_sprite.texture = load("res://sprites/backgrounds/lose_hand.png")
		Game.Side.BOTH:
			result_sprite.texture = load("res://sprites/backgrounds/tie_hand.png")

func display_winning_hand(winning_hand: Game.Hand):
	cpu_hand.show()
	player_hand.show()
	comm_cards.show()
	update_card_textures()
	var winning_hand_textures = winning_hand.cards.map(func(c): return c.sprite.texture.resource_path)
	var all_cards = [cpu_card_1, cpu_card_2, player_card_1, player_card_2, comm_card_1, comm_card_2, comm_card_3, comm_card_4, comm_card_5]
	for c in all_cards:
		if not winning_hand_textures.has(c.texture.resource_path):
			c.hide()
		else:
			c.show()

func hide_winning_hand():
	cpu_hand.hide()
	player_hand.hide()
	comm_cards.hide()

func update_card_textures():
	var cpu_cards = game.cpu.cards_in_hand
	cpu_card_1.texture = load(cpu_cards[0].sprite.texture.resource_path)
	cpu_card_2.texture = load(cpu_cards[1].sprite.texture.resource_path)

	var player_cards = game.player.cards_in_hand
	player_card_1.texture = load(player_cards[0].sprite.texture.resource_path)
	player_card_2.texture = load(player_cards[1].sprite.texture.resource_path)

	var all_comm_cards = [comm_card_1,comm_card_2,comm_card_3,comm_card_4,comm_card_5]
	for i in range(0, game.curr_community_cards.size()):
		var card = game.curr_community_cards[i]
		var this_comm_card = all_comm_cards[i]
		this_comm_card.texture = load(card.sprite.texture.resource_path)
		this_comm_card.show()
