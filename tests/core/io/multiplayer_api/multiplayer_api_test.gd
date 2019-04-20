extends "res://base_test.gd"

const MP = preload("res://tests/core/io/multiplayer_api/mp_game.gd")

var tests = {
	'master_func': 0,
	'remote_func': 0,
	'puppet_func': 0,
	'none_func': 0,
	'master_sync': 0,
	'remote_sync': 0,
	'puppet_sync': 0
}

var masterapi = MultiplayerAPI.new()
var puppet1api = MultiplayerAPI.new()
var puppet2api = MultiplayerAPI.new()
var puppet3api = MultiplayerAPI.new()

func _make_node(api : MultiplayerAPI, is_master : bool):
	var node = Node.new()
	var peer = NetworkedMultiplayerENet.new()
	var peer_node = MP.new()
	api.set_root_node(node)
	api.connect("network_peer_connected", self, "_peer_connected", [node])
	peer_node.name = "1"
	node.add_child(peer_node)
	if is_master:
		peer.create_server(4666)
	else:
		peer.create_client("127.0.0.1", 4666)
	api.network_peer = peer
	node.custom_multiplayer = api
	peer_node.custom_multiplayer = api
	add_child(node)

func setup():
	_make_node(masterapi, true)
	_make_node(puppet1api, false)
	_make_node(puppet2api, false)
	_make_node(puppet3api, false)
	var func_calls = get_expected_func_count(true)
	# Wait for connection to be established
	yield(get_tree().create_timer(1), "timeout")
	# Get all ids
	var all_ids = masterapi.get_network_connected_peers()
	all_ids.push_back(1)
	for peer in get_children():
		for player in peer.get_children():
			for k in func_calls:
				player.rpc(k)
				player.rset(k.replace('func', 'var'), 10)
				# Also call to ID
				for sid in all_ids:
					player.rpc_id(sid, k)
					player.rset_id(sid, k.replace('func', 'var'), 10)
	# Wait for RPCs to flow
	yield(get_tree().create_timer(2), "timeout")
	for peer in get_children():
		for player in peer.get_children():
			var expected = get_expected_func_count(player.is_network_master(), 4)
			var state = player.state
			for k in state:
				# Times 2 because we call both broadcast and to ID
				_compare_state(k, expected[k] * 2, state[k], player)
				var vk = k.replace('func', 'var')
				# Times 2 because we call both broadcast and to ID, times 10 because each time the var is incremented by 10
				_compare_state(vk, expected[k] * 10 * 2, player.get(vk), player)
	# Wait for potential failure
	yield(get_tree().create_timer(0.1), "timeout")
	done()

func _peer_connected(id : int, node : Node):
	var add_id = id
	if id == 1:
		add_id = node.custom_multiplayer.get_network_unique_id()

	var pnode = MP.new()
	pnode.name = str(add_id)
	pnode.set_network_master(add_id)
	pnode.custom_multiplayer = node.custom_multiplayer
	node.add_child(pnode)

func _compare_state(key : String, expected : int, state : int, player : Node):
	if expected != state:
		printt(key, expected, state, player.is_network_master(), player.get_network_master(), player.custom_multiplayer.get_network_unique_id())
	assert_cond(expected == state)

func get_expected_func_count(is_master : bool, peers : int = 2) -> Dictionary:
	if is_master:
		return {
			'masterfunc': peers, # All peers, including local
			'puppetfunc': 0, # Never
			'remotefunc': peers - 1, # All peers, not local
			'mastersyncfunc': peers, # All peers
			'puppetsyncfunc': 1, # Only local, others not allowed
			'remotesyncfunc': peers, # All peers, including local
		}
	else:
		return {
			'masterfunc': 0, # Never
			'puppetfunc': 2, # Only by master, and local
			'remotefunc': peers - 1, # All peers, not local
			'mastersyncfunc': 1, # Only local
			'puppetsyncfunc': 2, # Only by master, and local
			'remotesyncfunc': peers, # All peers, including local
		}

func _process(delta):
	assert_time(6) # This test can't take more than 5 seconds
	masterapi.poll()
	puppet1api.poll()
	puppet2api.poll()
	puppet3api.poll()