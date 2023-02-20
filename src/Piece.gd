extends Area2D

var colour = "W"
var short_name = "P"
var long_name = "pawn"
var moving = false
var loc = null
var capturing = null


func set_texture(tex):
	$texture.texture = tex


func move_to(dest, capture=null):
#	var st = get_parent().boardstate
	capturing = capture
	loc = dest
#	get_parent().boardstate.set_state(dest, self)
	$movement_tween.interpolate_property(self, "position", position, 
		get_parent().get_square(dest).position, 
		.2/ProjectSettings.get("global/movement_speed"), 
		Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)# , ease_type=Tween.EASE_IN_OUT)
	$movement_tween.connect("tween_step", self, "_tween_step", [capture])
	$movement_tween.start()
	
func _tween_step(object, key, elapsed, value, x):
	if capturing != null:
		if elapsed > 0.9*$movement_tween.get_runtime():
			capturing.capture()
			capturing = null
			
func capture():
	get_parent()._piece_captured(self)
#	if get_parent().boardstate.get_state(loc) == self:
#		get_parent().boardstate.set_state(loc, null)
#		get_parent().boardstate.get_square(loc).piece = null
#	self.queue_free()

#func _on_Piece_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
#	if event is InputEventMouseButton:
#		if event.button_index == BUTTON_LEFT and event.pressed:
#			emit_signal("clicked", self.short_name)


#func _on_movement_tween_tween_step(object, key, elapsed, value):
#	print("/") # Replace with function body.
