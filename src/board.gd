extends Node2D

### This class links to a boardstate and manages all
### the sprites and visual representation of the board.
### The mouse event handling is delegated to squares

# TODO:
# Sound for move
# Sync game state on load
# Chat
# History
# Timer
# Bugs:
## The whose turn is it is broken after loading save?

enum {NONE, SELECTED}
var highlight = preload("res://src/highlight.tscn")
var square = preload("res://src/Square.tscn")
var promotion = preload("res://src/promotion.tscn")
var squares = []
var boardstate = null
var selected_piece = null
var selected_state = NONE
var temp_state = null
const FILES = " abcdefgh"
const DEFAULT_SETUP = \
"WRWNWBWQWKWBWNWR" + \
"WPWPWPWPWPWPWPWP" + \
"                " + \
"                " + \
"                " + \
"                " + \
"BPBPBPBPBPBPBPBP" + \
"BRBNBBBQBKBBBNBR"

var initial_state = DEFAULT_SETUP



	
remote func move_remote(from, to):
	move_piece(from, to, true)

func _process(delta):
	if Input.is_key_pressed(KEY_ESCAPE):
		reset_state()
		
func xy_to_pix(pos: Vector2):
	var x_pixel = 64+(pos.x-1)*128
	var y_pixel = 0
	if GameState.side == "B": #
#	if ProjectSettings.get("global/flip_board"):
		y_pixel = 64 + ((pos.y-1)*128)
	else:
		y_pixel = 1024 - 64 - ((pos.y-1)*128)
	return Vector2(x_pixel, y_pixel)

func pix_to_xy(pos):
	var col = int(pos.x/128)
	var row = 0
	if GameState.side == "B": #ProjectSettings.get("global/flip_board"):
		row = int(pos.y/128)
	else:	
		row = 7 - int(pos.y/128)
	return Vector2(col+1, row+1)
		
func _ready():
	boardstate = load("res://src/BoardState.gd").new()
	boardstate.connect("castling", self, "_do_castle")
	var clr = "B"
	squares.resize(64)
	# Add the squares (now I regret it)
	for y in range(1, 9):
		clr = "B" if y%2==0 else "W"
		for x in range(1, 9):
			boardstate.set_state(Vector2(x, y), null)
			var sq = square.instance()
			sq.set_colour(clr)
			sq.location = Vector2(x, y)

			clr = "B" if clr == "W" else "W"
			sq.position = xy_to_pix(sq.location)
			add_child(sq)
			set_square(sq.location, sq)
	
	boardstate.string_to_board(initial_state)
	boardstate.connect("highlight", self, "highlight_move")
	boardstate.connect("stalemate", self, "stalemate")
	boardstate.connect("checkmate", self, "checkmate")	
#	boardstate.connect("capture", self, "_piece_captured")
	refresh_from_state()

func _piece_captured(pc):
#	var piece = get_square(pc).piece
#	piece.queue_free() 
	var child = $capturezone_us
	if pc.colour == GameState.side:
		child = $capturezone_them
	self.remove_child(pc)
	child.accept_piece(pc)		
#	print("PIECE CAPTURED!", pc)
	
func _do_castle(rookloc):
	print("CASTLE")
	var piece = get_square(rookloc).piece
	piece.move_to(Vector2(3 if rookloc.x == 1 else 6, 
			rookloc.y))
	get_square(Vector2(3 if rookloc.x == 1 else 6, 
			rookloc.y)).piece = piece
	
func highlight_square(xy):
	var hl = highlight.instance()
	hl.position = boardstate.xy_to_pix(xy)
	add_child(hl)

func checkmate(c):
	get_node("../gameover/label").set_text("Game Over\n" +\
		("White" if boardstate.inactive == "W" else "Black") + " wins!")
	get_node("../gameover").visible = true

func stalemate(c):
	get_node("../gameover/label").set_text("Game Over\n" +\
		"DRAW")
	get_node("../gameover").visible = true


func move_piece(from, dest, remoted=false):
	# Update the board state
	
	# EN PASSANT is complex
	var cap_loc = boardstate.move_piece(from, dest)
	
	print(boardstate.check_check())
	# Update the view
#	var from = piece.loc
	var sq_from = get_square(from)
	var sq_to = get_square(dest)
	var piece = sq_from.piece
	sq_from.piece = null
#	sq_from.remove_child(piece)
	add_child(piece)
	piece.position = sq_from.position
	
	var capture = get_square(cap_loc).piece
		
	piece.move_to(dest, capture)
	sq_to.piece = piece
	GameState.move += 1
	boardstate.turn += 1
	if boardstate.promotion_needed() != null:
		var prom = promotion.instance()
		prom.position = Vector2(556, 556)
		prom.connect("promotion", self, "promotion_chosen")
		add_child(prom)
	boardstate.check_check()
	boardstate.check_checkmate(boardstate.active)
	get_parent()._turn_update()
	if not remoted:
		rpc("move_remote", from, dest)
	get_parent().clunk()


func highlight_move(loc):
	get_square(loc).highlight(true)

func promotion_chosen(type):
	var where = boardstate.promotion_needed()
	boardstate.promote(where, type)
	refresh_from_state()

#
func reset_state():
	get_tree().call_group("squares","highlight", false)
	selected_piece = null
	selected_state = NONE
	
	
func refresh_from_state():
	get_tree().call_group("pieces","queue_free")
	
	for x in range(1, 9):
		for y in range(1, 9):
			var board_loc = Vector2(x, y)
#			var pos = xy_to_pix(board_loc)
			var piece = boardstate.get_state(board_loc)
			if piece != null:
				piece = PieceFactory.get_piece(piece.colour, piece.short_name)
				piece.loc = board_loc
				get_square(board_loc).set_piece(piece)
				piece.position = get_square(board_loc).position
				add_child(piece)
			else:
				get_square(board_loc).set_piece(null)
	for c in ["W", "B"]:
		for p in boardstate.captured[c]:
			_piece_captured(PieceFactory.get_piece(p.colour, p.short_name))
			

func get_square(pos):
	return squares[(pos.y-1)*8 + (pos.x-1)]
	
func set_square(pos, sq):
	squares[(pos.y-1)*8 + (pos.x-1)] = sq
	
func _highlight_legal_move(loc):
	get_square(loc).highlight(true)	
	

func select_piece(piece):
	if piece == null:
		return
	selected_piece = piece
	selected_state = SELECTED
	var legal = boardstate.count_legalmoves_for_piece(piece.loc, true)
	if legal == 0:
		selected_state = NONE
		selected_piece = null
