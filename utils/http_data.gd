extends Node

static func _merge(dict, base):
	for k in base:
		if not (k in dict):
			dict[k] = base[k]
	return dict

const _BASE = {
	"port": -1,
	"path": "/",
	"data": "",
	"code": 200,
	"fail": false,
	"result": HTTPRequest.RESULT_SUCCESS,
	"method": HTTPClient.METHOD_GET,
	"max_redirects": 0,
	"valid": true,
	"bytes": -1, # No check
	"follow_code": 200,
	"ssl": false,
	"validate": true
}

const _DATA = [
	{
		"host": "https://jigsaw.w3.org",
		"path": "/HTTP/ChunkedScript",
		"data": "data/response_200_body_chunked",
		"code": 200,
		"bytes": 72200,
	},
#	{
#		"host": "http://fsfe.org",
#		"path": "/",
#		"data": "data/response_200_head",
#		"method": HTTPClient.METHOD_HEAD,
#		"code": 200,
#		"bytes": 0,
#	},
	{
		"host": "https://godotengine.org",
		"path": "/",
		"data": "data/response_200_ssl_head",
		"method": HTTPClient.METHOD_HEAD,
		"code": 200,
		"bytes": 0,
	},
#	{
#		"host": "http://www.fsfe.org",
#		"path": "/",
#		"data": "data/response_301_body",
#		"result": HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,
#		"code": 301,
#		"bytes": 293,
#	},
	{
		"host": "http://godotengine.org",
		"path": "/",
		"data": "data/response_301_tossl_head",
		"method": HTTPClient.METHOD_HEAD,
		"code": 301,
		"bytes": 0,
		"max_redirects": 1,
	},
	{
		"host": "https://godotengine.org",
		"path": "/download",
		"data": "data/response_302_ssl_body",
		"result": HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,
		"code": 302,
		"bytes": 404
	},
	{
		"host": "https://godotengine.org",
		"path": "/docs/latest/404/",
		"data": "data/response_404_ssl_body",
		"code": 404,
		"bytes": 448,
	}
]

static func get_data():
	var list = []
	for v in _DATA:
		list.append(_merge(v, _BASE))
	return list