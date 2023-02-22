extends Node2D
var texture_loc = "art/With Shadow/128px/"
var location = null
var colour = "B"
var piece = null
var board = null

func _enter_tree() -> void:
	board = get_parent()
	
func set_colour(c) -> void:
	colour = c
	$Sprite2D.texture = load("res://" + texture_loc + "square brown " + 
		("dark" if colour =="B" else "light") + ".png")

func set_piece(spiece):
	if self.piece != null:
		self.piece.queue_free()
	self.piece = spiece
#	add_child(piece)
	
	
func highlight(checked=true):
	$highlight.visible = checked
	
func _on_Area2D_mouse_entered() -> void:
	if not GameState.connected:
		return 
	var state = board.selected_state
	if piece != null:
		if state == board.NONE:
			if piece.colour == get_parent().boardstate.active and piece.colour == GameState.side:
				highlight(true)
				
func _on_Area2D_mouse_exited() -> void:
	if get_parent().selected_state == 0:
		highlight(false) 


func _on_Area2D_input_event(viewport: Node, event: InputEvent, 
shape_idx: int) -> void:
	var st = board.boardstate			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not GameState.connected:
				return 
			var state = board.selected_state
			if state == board.NONE:
				if piece != null:
					if get_parent().boardstate.active==piece.colour and GameState.side == piece.colour:
						highlight(true)
						board.select_piece(piece)
			elif state == board.SELECTED:
				if st.legalmove(board.selected_piece.loc, location):
					if true or board.trial_move(board.selected_piece, location):	
						board.move_piece(board.selected_piece.loc, location)
						board.reset_state()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			board.reset_state()
