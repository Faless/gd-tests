extends "res://base_test.gd"

var req = HTTPRequest.new()
var current = null

const PORT = 13781 # Random high port number

class MockServer extends Reference:
	var tcp = TCP_Server.new()
	var conn = null

	func _init():
		tcp.listen(13781, "127.0.0.1")

	func poll():
		if tcp.is_connection_available():
			conn = tcp.take_connection()

	func send_file(file, replace=""):
		if conn == null or not conn.is_connected_to_host():
			return
		var f = File.new()
		f.open("res://" + file, File.READ)
		var data = f.get_buffer(f.get_len())
		if replace != "":
			var tmp = data.get_string_from_ascii()
			tmp = tmp.replace("Location: https://", "Location: http://")
			# TODO redirecting to url breaks the test, something wrong in godot parsing?
			tmp = tmp.replace("Location: %s" % replace, "Location: ")
			data = tmp.to_ascii()
		conn.put_data(data)

	func send_ok(size=0):
		poll()
		if conn == null or not conn.is_connected_to_host():
			return
		var head = "HTTP/1.1 200 OK\r\nconnection: keep-alive\r\ncontent-length: %d\r\n\r\n" % size
		var body = ""
		for i in range(0, size):
			body += "a"
		conn.put_data((head + body).to_ascii())

var requests = []

var server = null

func setup():
	requests = load("res://utils/http_data.gd").get_data()
	server = MockServer.new()
	req.connect("request_completed", self, "request_complete")
	add_child(req)
	start_next()

func teardown():
	server = null

func start_next():
	if requests.size() == 0:
		done()
		return
	current = requests.pop_front()
	req.max_redirects = current.max_redirects
	Log.info("Requesting: %d - %s - data: %s" % [current.method, current.host + current.path, current.data])
	var host = "http://127.0.0.1:%d"
	if current.host == "https://invalid.dnsname/fail":
		host = current.host
	req.request("http://127.0.0.1:%d" % PORT, PoolStringArray(["Host: %s" % current.host]), true, current.method, "")
	server.poll()
	if current.data != "":
		server.send_file(current.data, current.host if current.max_redirects > 0 else "")

func request_complete(result, code, headers, body):
	Log.info("Request complete: RESULT: %d, CODE: %d, BYTES: %d" % [result, code, body.size()])
	assert_cond(result == current.result)
	if current.max_redirects > 0:
		assert_cond(code == current.follow_code)
	else:
		assert_cond(code == current.code)
	if result == HTTPRequest.RESULT_SUCCESS:
		assert_cond(body.size() == current.bytes)
	else:
		assert_cond(body.size() == 0)
	start_next()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	assert_time(10)
	if req.get_http_client_status() == HTTPClient.STATUS_REQUESTING and current.max_redirects > 0:
		server.send_ok(current.bytes if current.bytes > 0 else 0)