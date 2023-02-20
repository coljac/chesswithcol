extends Node2D

var pieces = []

func accept_piece(piece):
	var sc = self.scale
	var x = -1*64 + len(pieces)%3 * 64
	var y = -1.75*64 + int(len(pieces)/3) * 64
	pieces.append(piece)
	piece.set_position(Vector2(x, y))
	piece.scale = Vector2(0.5, 0.5)
	add_child(piece)
	piece.add_to_group("captured")
