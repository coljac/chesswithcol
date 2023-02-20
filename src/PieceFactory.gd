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

func get_piece(colour, name):
	var new_piece = piece.instance()
	new_piece.colour = colour
	new_piece.short_name = name
	new_piece.long_name = NAMES[name.to_lower()]
	new_piece.set_texture(load("res://" + location + colour.to_lower() + "_" + name.to_lower() + ".png"))
	return new_piece
