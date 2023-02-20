extends Control
signal name_changed

func _on_save_pressed() -> void:
	if GameState.player != $namet.text:
		GameState.player = $namet.text
		emit_signal("name_changed")
	visible = false


func _on_cancel_pressed() -> void:
	queue_free()


func _on_TextEdit_text_changed() -> void:
	if $namet.text == "Col":
		$save.disabled = true
	else:
		$save.disabled = false


func _on_CheckBox_pressed() -> void:
	$save.disabled = $CheckBox.is_pressed()
	 
