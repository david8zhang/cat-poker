class_name EndScreen
extends Node2D

@export var play_again_button: Button

func _unhandled_key_input(event):
	if event.is_pressed():
			get_tree().change_scene_to_file("res://scenes/Main.tscn")