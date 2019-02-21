# Let's test!
This repository contains both a simple testing system and a set of tests for Godot (mainly networking for now).

# How does it work?

The framework is composed of three files:
- `runner.gd` allows to run the tests via command line.
- `tester.gd` scan the `tests` folder for files ending with `_test.gd` and load them as scenes.
- `base_test.gd` is the base test class, `_test.gd` files should extend this. This script extends `Node`, you can use it to instance the rest of the scene as child if needed be.

At the core, the `tester` instances `base_test` subclasses as scenes one at a time, wait for them to either set failure state, or done state, then teardown the test, reports success or failure, deletes the instance from tree, and goes to the next one.

# Okay, but how do I write a test?

Writing a test is simple! Here are some examples with exaplainations.

**A simple test assert that 2 + 2 = 4 (looking for large values of 2)**
```gdscript
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
```

**A more complex test, that runs on multiple frames, and test Timer functionalities**
```gdscript
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
```

# Running the tests

From the repo folder:
`/path/to/Godot -d -s runner.gd`

From any folder (specifying path correctly):
`/path/to/Godot -d -s --path /path/to/repo /path/to/repo/runner.gd`
