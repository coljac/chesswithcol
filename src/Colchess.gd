extends Node2D
var label  = preload("res://src/label.tscn")

const server = "localhost"
@onready var persistFile = "user://colchess_" + GameState.player + ".save"
#@onready var saveHandle = FileAccess.new()
@onready var peer = ENetMultiplayerPeer.new()
var hello = preload("res://sounds/hello.mp3")
var hmm = preload("res://sounds/hmmm.mp3")
var heh = preload("res://sounds/heh.mp3")
var click = preload("res://sounds/clunk.mp3")
var prefs_file = "user://colchess_prefs.json"

func saveUserData(dict):
	var saveHandle = FileAccess.open(persistFile, FileAccess.WRITE)
	saveHandle.store_line(JSON.new().stringify(dict))
	saveHandle.close()

func shello():
	if not $audio.is_playing():
		$audio.stream = hello
		$audio.play()
			
func clunk():
	if not $audio.is_playing():
		$audio.stream = click
		$audio.play()
func sheh():
	if not $audio.is_playing():
		$audio.stream = heh
		$audio.play()
		
func shmm():
	if not $audio.is_playing():
		$audio.stream = hmm
		$audio.play()
		
func _enter_tree() -> void:
	var f = null
	if FileAccess.file_exists(prefs_file):
		f = FileAccess.open(prefs_file, FileAccess.READ)
		var test_json_conv = JSON.new()
		test_json_conv.parse(f.get_line())
		var p_dict = test_json_conv.get_data()
		GameState.player = p_dict['name']
		f.close()
	for arg in OS.get_cmdline_args():
		if arg != ".":
			GameState.player = arg
	if GameState.player == "Player":
		$preference_pane.visible = true
	get_node("preference_pane/namet").set_text(GameState.player)
	if GameState.player == "Col":
		GameState.side = GameState.col_side
	else:
		GameState.opponent = "Col" 
		GameState.side = "W" if GameState.col_side == "B" else "B"
	persistFile = "user://colchess_" + GameState.player + ".save"

func new_game(opponent):
	if GameState.player == "Col":
		# Set sides
		var rng = RandomNumberGenerator.new()
		GameState.col_side = "W"
		rng.randomize()
		if rng.randi_range(0, 1) == 1:
			GameState.col_side = "B"
		if GameState.player != "Col":
			GameState.side = "W" if GameState.col_side == "B" else "W"
			GameState.opponent = opponent
		else:
			GameState.side = GameState.col_side
		GameState.move = 1
		# reset board state
		get_node("board").boardstate.string_to_board($board.DEFAULT_SETUP)
		$board.refresh_from_state()
		# communicate
		
		rpc("refresh_remote", {"game_state": get_node("board").boardstate.serialize()})
	else:
		rpc("refresh_remote", {"new": GameState.player})
				
@rpc("any_peer") func refresh_remote(game_dict):
	if "new" in game_dict:
		print("NEW")
		return
	$gameover.visible = false	
	get_node("board").boardstate.state_from_dict(game_dict)
	get_node("board").refresh_from_state()


func _ready():
	print("Player ", GameState.player, " Side: ", GameState.side)
	var f = 1
	var l = null
	for c in "abcdefgh":
		l = label.instantiate()
		l.text = c
		l.set_position(Vector2(f*128 - 64, 1047))
		add_child(l)
		f += 1		
	f = 1
	for c in "12345678":
		l = label.instantiate()
		l.text = c
		l.set_position(Vector2(-20, 1024 - (f*128 - 64)))
		add_child(l)
		f += 1		
	add_sibling(l)#, get_node("splash"))
	load_game()
	
	network_connect()
	
func network_connect():
	if GameState.player == "Col":
		print("Start server")
		peer.create_server(16751, 2)
	else:
		print("Not Col, connecting")
		peer.create_client(server, 16751)
	multiplayer.multiplayer_peer = peer
#	get_tree().network_peer = peers
	get_tree().connect("peer_connected",Callable(self,"_connected"))
	get_tree().connect("peer_disconnected",Callable(self,"_disconnected"))
	get_tree().connect("connected_to_server",Callable(self,"connected"))
	get_tree().connect("connection_failed",Callable(self,"disconnected"))
	get_tree().connect("server_disconnected",Callable(self,"disconnected"))
	
func _connected(id):
	connected()
	
func _disconnected(id):
	disconnected()
	
func connected():
	shello()
	GameState.connected = true
	get_node("Info/offline").visible = false
	get_node("Info/online").visible = true
	# if GameState.player == "Col":
		# GameState.opponent = str(rpc("get_name")) + ""
		# persistFile = "user://colchess_" + GameState.opponent + ".save"
		#load_game()
		
#@rpc("any_peer") func get_name():
#	print("ASKED")
#	return GameState.player
	
func disconnected():
	shmm()
	get_node("Info/offline").visible = true
	GameState.connected = false
	get_node("Info/online").visible = false
		
func quit():
	save_game()
	get_tree().quit()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit() 
			
func save_game():
	var to_save = get_node("board").boardstate.serialize()
	var save_game = FileAccess.open(persistFile, FileAccess.WRITE)
	save_game.store_line(JSON.new().stringify(to_save))
	save_game.close()


func _turn_update():
	var who = "White" if $board.boardstate.active == "W" else "Black"
	who += "'s turn ("
	who += "You" if GameState.side == $board.boardstate.active else GameState.opponent
	who += ")"
	$turn_label.set_text("Turn: " + str($board.boardstate.turn) + " " + who)

func load_game():
	if not FileAccess.file_exists(persistFile):
		return 
	var save_game = FileAccess.open(persistFile, FileAccess.READ)
	var test_json_conv = JSON.new()
	test_json_conv.parse(save_game.get_line())
	var save_dict = test_json_conv.get_data()
	save_game.close()

	if save_dict != null:
		get_node("board").boardstate.state_from_dict(save_dict)
		get_node("board").refresh_from_state()
		_turn_update()	
	

# Save preferences
func _on_preference_pane_name_changed() -> void:
	var f = FileAccess.open(prefs_file, FileAccess.WRITE)
	f.store_line(JSON.new().stringify({"name": GameState.player}))
	f.close()


func _on_recon_timer_timeout():
	if not GameState.connected:
		network_connect()
		
