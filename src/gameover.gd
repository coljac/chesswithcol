extends Node2D

func _on_Button2_pressed():
	get_node("/root/Colchess").quit()


func _on_Button_pressed():
	# New game
	# Delete main scene and start again
	get_tree().change_scene_to_file("res://src/Colchess.tscn")
	get_parent().new_game(GameState.player)
