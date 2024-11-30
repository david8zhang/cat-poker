class_name SceneTransition
extends CanvasLayer

func change_scene_to_file(scene_file_path: String, slow_down_factor: float=1.0) -> void:
	"""
	Use this function to change scenes, which wraps get_tree().change_scene()
	with a fade in and fade out animation.
	
	Args:
		scene_file_path - file path to the .tscn scene file.
	"""

	Engine.time_scale = 1.0 / slow_down_factor
	($AnimationPlayer as AnimationPlayer).play('dissolve', -1, slow_down_factor)
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file(scene_file_path)
	Engine.time_scale = 1
	$AnimationPlayer.play_backwards('dissolve')
