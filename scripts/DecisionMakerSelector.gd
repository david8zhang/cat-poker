class_name DecisionMakerSelector
extends Node

@onready var easy_decision_maker = $EasyDecisionMaker as CPUDecisionMaker
@onready var medium_decision_maker = $MediumDecisionMaker as CPUDecisionMaker
@onready var hard_decision_maker = $HardDecisionMaker as CPUDecisionMaker

func get_decision_maker_based_on_difficulty(difficulty: CPUCardPlayer.Difficulty):
	match difficulty:
		CPUCardPlayer.Difficulty.EASY:
			return easy_decision_maker
		CPUCardPlayer.Difficulty.MEDIUM:
			return medium_decision_maker
		CPUCardPlayer.Difficulty.HARD:
			return hard_decision_maker