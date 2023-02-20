extends Node2D
var label  = preload("res://src/label.tscn")

onready var persistFile = "user://colchess_" + GameState.player + ".save"
onready var saveHandle = File.new()
var hello = preload("res://sounds/hello.mp3")
var hmm = preload("res://sounds/hmmm.mp3")
var heh = preload("res://sounds/heh.mp3")
var click = preload("res://sounds/clunk.mp3")
var prefs_file = "user://colchess_prefs.json"

func saveUserData(dict):
	saveHandle.open(persistFile, File.WRITE)
	saveHandle.store_line(to_json(dict))
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
	var f = File.new()
	if f.file_exists(prefs_file):
		f.open(prefs_file, File.READ)
		var p_dict = parse_json(f.get_line())
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
				
remote func refresh_remote(game_dict):
	if "new" in game_dict:
		print("NEW")
		return
	$gameover.visible = false	
	get_node("board").boardstate.state_from_dict(game_dict)
	get_node("board").refresh_from_state()


func _ready():
	print("Player ", GameState.player, " Side: ", GameState.side)
	var f = 1
	for c in "abcdefgh":
		var l = label.instance()
		l.text = c
		l.set_position(Vector2(f*128 - 64, 1047))
		add_child(l)
		f += 1		
	f = 1
	for c in "12345678":
		var l = label.instance()
		l.text = c
		l.set_position(Vector2(-20, 1024 - (f*128 - 64)))
		add_child(l)
		f += 1		
	load_game()
	
	network_connect()
	
func network_connect():
	var peer = NetworkedMultiplayerENet.new()
	var r = null
	if GameState.player == "Col":
		r = peer.create_server(16751, 2)
		# peer.connect("network_peer_connected", self, "_connected")
	else:
		print("Not col, connecting")
		r = peer.create_client("localhost", 16751)
	get_tree().network_peer = peer
	get_tree().connect("network_peer_connected", self, "connected")
	get_tree().connect("network_peer_disconnected", self, "disconnected")
	get_tree().connect("connected_to_server", self, "connected")
	get_tree().connect("connection_failed", self, "disconnected")
	get_tree().connect("server_disconnected", self, "disconnected")
	
func connected():
	shello()
	GameState.connected = true
	$Info.offline.visible = false
	$Info.online.visible = true

func disconnected():
	shmm()
	$Info.offline.visible = true
	GameState.connected = false
	$Info.online.visible = false
		
func quit():
	save_game()
	get_tree().quit()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		quit() 
			
func save_game():
	var to_save = get_node("board").boardstate.serialize()
	
	var save_game = saveHandle
	save_game.open(persistFile, File.WRITE)
	save_game.store_line(to_json(to_save))
	save_game.close()


func _turn_update():
	var who = "White" if $board.boardstate.active == "W" else "Black"
	who += "'s turn ("
	who += "You" if GameState.side == $board.boardstate.active else GameState.opponent
	who += ")"
	$turn_label.set_text("Turn: " + str($board.boardstate.turn) + " " + who)

func load_game():
	var save_game = saveHandle
	if not save_game.file_exists(persistFile):
		return 
	save_game.open(persistFile, File.READ)
	var save_dict = parse_json(save_game.get_line())
	save_game.close()

	if save_dict != null:
		get_node("board").boardstate.state_from_dict(save_dict)
		get_node("board").refresh_from_state()
		_turn_update()	
	

# Save preferences
func _on_preference_pane_name_changed() -> void:
	var f = File.new()
	f.open(prefs_file, File.WRITE)
	f.store_line(to_json({"name": GameState.player}))
	f.close()


func _on_recon_timer_timeout():
	if not GameState.connected:
		network_connect()
		
