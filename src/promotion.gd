extends Node2D

signal promotion(type)

func _ready() -> void:
	var colour = GameState.side
	var y = 32
	var x = -(5*128)/2 - 256
	x = 0 - 64 - 128
	for type in "QRBN":
		var piece = PieceFactory.get_piece(colour, type)
		piece.position = Vector2(x, y)
		x += 128
		add_child(piece)
		piece.connect("clicked",Callable(self,"_clicked"))

func _clicked(type):
	print("Promotion choice: ", type)
	emit_signal("promotion", type)
	queue_free()

