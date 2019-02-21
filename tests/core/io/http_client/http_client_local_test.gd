extends "res://base_test.gd"

var FAILURE_STATES = [HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_SSL_HANDSHAKE_ERROR]

var tests = []

var client = HTTPClient.new()
var current = null
var _read = 0

func setup():
	tests = load("res://utils/http_data.gd").get_data()
	start_next()

func _def_dict(dict, base):
	for k in base:
		if not (k in dict):
			dict[k] = base[k]
	return dict

func start_next():
	if current != null:
		Log.info("Request complete: Status: %d, Code: %d, Bytes: %d" % [client.get_status(), client.get_response_code(), _read])
		assert_cond(client.get_response_code() == current.code)
		if current.bytes >= 0:
			assert_cond(_read == current.bytes)
		current = null
	if tests.size() == 0:
		done()
		return
	client.close()
	_read = 0
	current = tests.pop_front()
	var conn = StreamPeerBuffer.new()

	# Dummy request
	client.connection = conn
	client.request(current.method, "/", PoolStringArray())

	# We could read the written request.
	# And make tests here...
	# print(conn.data_array.get_string_from_utf8())

	# Write the mocked response
	var f = File.new()
	f.open("res://" + current.data, File.READ)
	var buf = f.get_buffer(f.get_len())
	buf.append(0)
	f.close()
	conn.resize(0)
	conn.data_array = buf
	conn.seek(0)
	Log.debug("Requesting: %s" % [current.data])
	client.poll()

func _process(delta):
	assert_time(5) # This test can't take more than 5 seconds

	var status = client.get_status()
	if status == HTTPClient.STATUS_CONNECTING or status == HTTPClient.STATUS_REQUESTING or status == HTTPClient.STATUS_RESOLVING:
		client.poll()
		return # Wait more

	if status in FAILURE_STATES:
		assert_cond(current.fail)
		start_next()
		return

	if status == HTTPClient.STATUS_CONNECTED:
		# Done, make a new request
		start_next()
		return
	elif status == HTTPClient.STATUS_REQUESTING:
		client.poll()
	elif status == HTTPClient.STATUS_BODY:
		var data = client.read_response_body_chunk()
		_read += data.size()
	else:
		Log.debug("Unchecked HTTPClient status: %s" % status)
		assert_cond(false)