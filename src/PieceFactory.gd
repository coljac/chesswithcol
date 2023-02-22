extends Node

var piece = preload("res://src/Piece.tscn") #preload("res://Piece.tscn")
var location = "art/With Shadow/128px/"
const NAMES = {
	"n": "knight",
	"b": "bishop",
	"q": "queen",
	"k": "king",
	"p": "pawn",
	"r": "rook"
}

func get_piece(colour, sname):
	var new_piece = piece.instantiate()
	new_piece.colour = colour
	new_piece.short_name = sname
	new_piece.long_name = NAMES[sname.to_lower()]
	new_piece.set_texture(load("res://" + location + colour.to_lower() + "_" + sname.to_lower() + ".png"))
	return new_piece
