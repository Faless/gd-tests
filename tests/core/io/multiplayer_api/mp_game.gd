extends Node

var state = {
	'masterfunc': 0,
	'puppetfunc': 0,
	'remotefunc': 0,
	'mastersyncfunc': 0,
	'puppetsyncfunc': 0,
	'remotesyncfunc': 0,
}

var nonevar = 0 setget nonefunc
master var mastervar = 0 setget masterfunc
puppet var puppetvar = 0 setget puppetfunc
remote var remotevar = 0 setget remotefunc
mastersync var mastersyncvar = 0 setget mastersyncfunc
puppetsync var puppetsyncvar = 0 setget puppetsyncfunc
remotesync var remotesyncvar = 0 setget remotesyncfunc

func nonefunc(val = 0):
	get_parent().get_parent().assert_cond(false)

master func masterfunc(val = 0):
	if val == 0:
		state['masterfunc'] += 1
	else:
		mastervar += val
	get_parent().get_parent().assert_cond(multiplayer.get_network_unique_id() == get_network_master())

puppet func puppetfunc(val = 0):
	if val == 0:
		state['puppetfunc'] += 1
	else:
		puppetvar += val
	get_parent().get_parent().assert_cond(multiplayer.get_network_unique_id() != get_network_master())

remote func remotefunc(val = 0):
	if val == 0:
		state['remotefunc'] += 1
	else:
		remotevar += val
	var caller = multiplayer.get_rpc_sender_id()
	get_parent().get_parent().assert_cond(caller != 0)

mastersync func mastersyncfunc(val = 0):
	if val == 0:
		state['mastersyncfunc'] += 1
	else:
		mastersyncvar += val
	var id = multiplayer.get_network_unique_id()
	var caller = multiplayer.get_rpc_sender_id()
	get_parent().get_parent().assert_cond(id == get_network_master() || (caller == 0) && !is_network_master())

puppetsync func puppetsyncfunc(val = 0):
	if val == 0:
		state['puppetsyncfunc'] += 1
	else:
		puppetsyncvar += val
	var id = multiplayer.get_network_unique_id()
	var caller = multiplayer.get_rpc_sender_id()
	get_parent().get_parent().assert_cond(id != get_network_master() || (caller == 0 && is_network_master()))

remotesync func remotesyncfunc(val = 0):
	if val == 0:
		state['remotesyncfunc'] += 1
	else:
		remotesyncvar += val