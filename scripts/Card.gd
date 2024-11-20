class_name Card
extends Node2D

@onready var sprite = $Sprite2D as Sprite2D

var suit
var rank
var back_texture
var front_texture

func _ready():
	sprite.texture = load("res://sprites/cards/card_back.png")

func show_card():
	sprite.texture = load("res://sprites/cards/card_" + str(suit) + "_" + str(rank) + ".png")