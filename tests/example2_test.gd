extends "res://base_test.gd"

func setup():
	# Setup a longer running test...

	# Add a one shot timer
	var timer = Timer.new()
	timer.one_shot = true
	timer.autostart = true
	timer.wait_time = 1.0
	add_child(timer)

	# Add recurring timer too, and connect it to the done function
	timer = Timer.new()
	timer.one_shot = false
	timer.autostart = true
	timer.wait_time = 1.0
	timer.connect("timeout", self, "done")
	add_child(timer)

func _process(delta):
	# assert_time allows you to assert the less then the given time has passed since the beginning of the test.
	# This is both to check time-based failures and make sure that a failing test does not stall forever.
	assert_time(1 + delta)

# Override this to do cleanup, make assertions at the end of the test (called on _exit_tree)
# NOTE: You can still fail here if you like with fail() or by failing an assertion
func teardown():
	# Either done was called, or the time assertion failed.

	# Check that the first timer is stopped (should have fired by now, and is not recurring)
	assert_cond(get_child(0).is_stopped())
	# Check that the second timer is not stopped, as it's recurring, and should have restarted.
	assert_cond(not get_child(1).is_stopped())