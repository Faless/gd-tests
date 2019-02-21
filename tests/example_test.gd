extends "res://base_test.gd"

func _init():
	# You can disable this test in code by calling:
	# disable()
	pass

# Override this to specify test initialization (called on _ready if not disabled)
# You can run your whole test here, and call done() when finished
func setup():
	# You can make assertions, if it fails, trace will be generated, and test will fail.
	assert_cond(2 + 2 == 4)
	# You can call done now, and the test will finish
	done()
	return