extends "res://base_test.gd"

var req = HTTPRequest.new()
var current = null

var requests = []

func _init():
	disable()

func setup():
	requests = load("res://utils/http_data.gd").get_data()
	req.connect("request_completed", self, "request_complete")
	add_child(req)
	start_next()

func _def_dict(dict, base):
	for k in base:
		if not (k in dict):
			dict[k] = base[k]
	return dict

func start_next():
	if requests.size() == 0:
		done()
		return
	current = requests.pop_front()
	req.max_redirects = current.max_redirects
	Log.info("Requesting: %d - %s" % [current.method, current.host + current.path])
	req.request(current.host + current.path, PoolStringArray(), true, current.method, "")

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