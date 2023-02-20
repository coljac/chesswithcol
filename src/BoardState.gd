extends Node

signal capture(loc)
signal castling(rookloc)
#signal check(colour)
signal checkmate(colour)
signal stalemate(colour)
signal highlight(sq)

var history = []
var state = []
#var squares = []
var is_check = {"B": false, "W": false}
var en_passant = null
var kings_moved = {"W": false, "B": false}
var active = "W"
var inactive = "B"
var captured = {"B": [], "W": []}
var turn = 1

class Piece:
	var colour = "W"
	var short_name = "P"
	
	func _init(c, t):
		colour = c
		short_name = t
	
func _init() -> void:
	state.resize(64)

func _strtov(s):
	if s != null and len(s) > 0:
		return Vector2(int(s[1]), int(s[4]))
	
	return null
	
func state_from_dict(d):
	string_to_board(d['state'])
	active = d['active']
	en_passant = _strtov(d['en_passant'])
	captured = {"W": [], "B": []}
	for c in ["W", "B"]:
		for p in d['captured'][c]:
			captured[c].append(Piece.new(p[0], p[1]))
	kings_moved = d['kings_moved']

func string_to_board(boardstring=null):
	if boardstring == null:
		boardstring = get_parent().DEFAULT_SETUP
	var y = 0
	var x  = 0
	for i in range(0, len(boardstring), 2):
		if i%16 == 0:
			y += 1
			x = 0

		x += 1
		var piece = null
		if boardstring[i] != " ":
			piece = Piece.new(boardstring[i], boardstring[i+1])

		set_state(Vector2(x, y), piece)


func get_state(pos):
	return state[(pos.y-1)*8 + (pos.x-1)]
	
func set_state(pos, st):
	state[(pos.y-1)*8 + (pos.x-1)] = st
		

func is_under_attack(loc, colour):
	for x in range(1, 9):
		for y in range(1, 9):
			var l = Vector2(x, y)
			var p = get_state(l)
			if p != null and p.colour == colour:
				if _legalmove(l, loc):
					return true
	return false	
	
func check_check():
	var kings = {"B":null, "W": null}
	for x in range(1, 9):
		for y in range(1, 9):
			var l = Vector2(x, y)
			var p = get_state(l)
			if p != null:
				if p.short_name == "K":				
					kings[p.colour] = l
	var checked = {"B": false, "W": false}
	for o in ["W", "B"]:
		if is_under_attack(kings[o], "B" if o=="W" else "W"):
			checked[o] = true
	is_check = checked
	return checked

func check_checkmate(c):
#	for c in ["W", "B"]:
	if count_legalmoves(c) == 0:
		if is_check[c]:
			emit_signal("checkmate", c)		
		else:
			emit_signal("stalemate", c)	
				
func count_legalmoves_for_piece(selected_piece, highlight=false):
	var legal_moves = 0
	for i in range(1, 9):
		for j in range(1, 9):
			var l = Vector2(i, j)
			if legalmove(selected_piece, l):
				if highlight:
					emit_signal("highlight", l)
				legal_moves += 1
	return legal_moves

func count_legalmoves(colour):
	var legal_moves = 0
	for i in range(1, 9):
		for j in range(1, 9):
			var l = Vector2(i, j)
			var piece = get_state(l)
			if piece != null and piece.colour == colour:
				legal_moves += count_legalmoves_for_piece(l)
	return legal_moves	
	
func move_piece(from, to):
	if get_state(from) == null:
		return
	var piece = get_state(from)
	var cap_loc = to
	# Special moves
	# En Passant
	if piece.short_name == "P" and abs(from.y - to.y) == 1 and \
		abs(from.x - to.x) == 1 and get_state(to) == null and \
		en_passant != null and to.x == en_passant.x:
			#captured[active].append(Piece.new("B" if active == "W" else "W", "P"))
			capture_piece(en_passant)
			cap_loc = en_passant

	elif piece.short_name == "P" and abs(from.y - to.y) == 2:
		en_passant = to
	else:
		en_passant = null

	# Castling
	
	if piece.short_name == "K" and abs(from.x-to.x) > 1:
		var rookloc = Vector2(1 if from.x>to.x else 8, from.y)
		var rook = get_state(rookloc)
		set_state(rookloc, null)
		set_state(Vector2(6 if to.x == 7 else 3, to.y), rook)
		emit_signal("castling", rookloc)
		
	set_state(from, null)
	if get_state(to) != null:
		# captured[active].append(get_state(to))
		capture_piece(to)
	set_state(to, piece)
	inactive = active
	active = "W" if active == "B" else "B"
	if piece.short_name == "K":
		kings_moved[piece.colour] = true

	return cap_loc

func promotion_needed():
	for x in range(1, 9):
		for y in [1, 8]:
			var loc = Vector2(x, y)
			var piece = get_state(loc)
			if piece != null and piece.short_name == "P":
				return loc
	return null
	
func promote(from, type):
	if get_state(from) == null or get_state(from).short_name != "P":
		return
	set_state(from, Piece.new(get_state(from).colour, type))
	
func capture_piece(loc):
	emit_signal("capture", loc)
	var piece = get_state(loc)
	captured[active].append(piece)
	set_state(loc, null)
	
func clone():
	var copied_state = load("res://BoardState.gd").new()
	for x in range(1, 9):
		for y in range(1, 9):
			var l = Vector2(x, y)
			copied_state.set_state(l, get_state(l))
	return copied_state
	
func not_check_check(loc, dest):
	var copy = clone()
	copy.move_piece(loc, dest)
	var checks = copy.check_check()
	return not checks[active] 
	
func legalmove(loc, dest):
	return _legalmove(loc, dest) and not_check_check(loc, dest)
	
func _legalmove(loc, dest):
	var piece = get_state(loc)
	if piece == null:
		return false
	var dest_piece = get_state(dest)
	if dest_piece != null and dest_piece.colour == piece.colour:
		return false
	if loc == dest:
		return false
		
	var move = [dest.x - loc.x, 
				dest.y - loc.y, 
				abs(loc.x - dest.x), 
				abs(loc.y - dest.y), 
				0 if dest.x == loc.x else (dest.x - loc.x)/abs(dest.x - loc.x),
				0 if dest.y == loc.y else (dest.y - loc.y)/abs(dest.y - loc.y),
				0 if dest.y == loc.y else (dest.y - loc.y)/abs(dest.y - loc.y) * (-1 if piece.colour == "B" else 1)]
	if piece.short_name == "P":
		if move[6] == -1:
			return false # No backwards
		if move[3] > 2:
			return false
		elif (move[1] == 2 and dest.y != 4) or (move[1] == -2 and dest.y != 5):
			# Double first move
			return false
		if move[2] > 1:
			return false
		elif move[2] == 1 and move[3] == 1:
			if dest_piece == null:
				if en_passant != null and Vector2(dest.x, loc.y) == en_passant:
					return true
				return false
			elif dest_piece.colour == piece.colour:
				return false
			return true
		if move[3] == 1 and move[2] == 0:
			return dest_piece == null
		if move[3] == 2 and move[0] == 0:
			return dest.y == 4 or dest.y == 5
		return false
	elif piece.short_name == "N":
		if move[3] + move[2] !=3:
			return false
		return move[1] * move[0] != 0
	elif piece.short_name == "B":
		if move[2] != move[3]:
			return false
		for i in range(1, move[3]):
			var new_x = loc.x + i*move[4]
			var new_y = loc.y + i*move[5]
			
			if get_state(Vector2(new_x, new_y)) != null:
				return false
		return true
	elif piece.short_name == "K":
		if not kings_moved[piece.colour] and \
			 	move[3] == 0 and (dest.x == 2 or dest.x==7) and \
				dest.y == (1 if piece.colour == "W" else 8):
			for xx in range(loc.x+move[4], 	dest.x, move[4]):
				if is_under_attack(Vector2(xx, dest.y), inactive):
					return false
			return true
		elif move[2]+move[3] > 2 or move[2]>1 or move[3]>1:
			return false		
		return true
	elif piece.short_name == "R":
		if move[2]*move[3] != 0:
			return false
		for i in range(1, max(move[2], move[3])):
			var new_x = loc.x + i*move[4]
			var new_y = loc.y + i*move[5]
			if get_state(Vector2(new_x, new_y)) != null:
				return false			
		return true		
	elif piece.short_name == "Q":
		if move[2]*move[3] != 0 and move[2] != move[3]:
			return false
		for i in range(1, max(move[2], move[3])):
			var new_x = loc.x + i*move[4]
			var new_y = loc.y + i*move[5]
			if get_state(Vector2(new_x, new_y)) != null:
				return false			
		return true		
	return false
		
func state_to_string():
	var s = ""
	for y in range(1, 9):
		for x in range(1, 9):
			var p = get_state(Vector2(x, y))
			s += "  " if p==null else p.colour + p.short_name	
	return s
		
func serialize():
	var outputs = {}
	outputs['active'] = active
	outputs['en_passant'] = en_passant
	outputs['kings_moved'] = kings_moved
	outputs['state'] = state_to_string()
	outputs['turn'] = turn
	var white_caps = []
	var black_caps = []
	for p in captured['W']:
		white_caps.append("B" + p.short_name)
	for p in captured['B']:
		black_caps.append("W" + p.short_name)
	outputs['captured'] = {"W": white_caps, "B": black_caps}
	return outputs
	
	

