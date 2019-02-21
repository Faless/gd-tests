extends "res://base_test.gd"

var FAILURE_STATES = [HTTPClient.STATUS_CANT_RESOLVE, HTTPClient.STATUS_CANT_CONNECT, HTTPClient.STATUS_CONNECTION_ERROR, HTTPClient.STATUS_SSL_HANDSHAKE_ERROR]

var hosts = []

var client = HTTPClient.new()
var current = null
var _requested = false
var _read = 0

func _init():
	disable()

func setup():
	hosts = load("res://utils/http_data.gd").get_data()
	start_next()

func start_next():
	if current != null:
		Log.info("Request complete: Status: %d, Code: %d, Bytes: %d" % [client.get_status(), client.get_response_code(), _read])
		assert_cond(client.get_response_code() == current.code)
		if current.bytes >= 0:
			assert_cond(_read == current.bytes)
	if hosts.size() == 0:
		done()
		return

	_read = 0
	var old_host = current.host if current != null else ""
	current = hosts.pop_front()
	if old_host != current.host:
		client.close()

	_requested = false
	_request()

func _request():
	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		Log.debug("Connecting to: %s:%d" % [current.host, current.port])
		client.connect_to_host(current.host, current.port, false, current.validate)
	else:
		Log.debug("Requesting: %s | %s" % [current.method, current.path])
		client.request(current.method, current.path, PoolStringArray())
		_requested = true

func _process(delta):
	assert_time(30) # This test can't take more than 10 seconds

	var status = client.get_status()
	if status == HTTPClient.STATUS_CONNECTING or status == HTTPClient.STATUS_REQUESTING or status == HTTPClient.STATUS_RESOLVING:
		client.poll()
		return # Wait more

	if status in FAILURE_STATES:
		assert_cond(current.result != HTTPRequest.RESULT_SUCCESS)
		start_next()
		return

	if status == HTTPClient.STATUS_CONNECTED:
		# Connected, make a new request
		if not _requested:
			_request()
		else:
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