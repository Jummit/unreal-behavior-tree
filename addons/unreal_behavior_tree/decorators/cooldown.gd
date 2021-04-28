tool
extends BehaviorDecorator

export var seconds := 1.0
var cooldown_data := {}

func get_name() -> String:
	return "Cooldown"


func get_info() -> String:
	return "of %s second(s)" % seconds


func run(node, subject : Node) -> bool:
	if OS.get_ticks_msec() - cooldown_data.get(subject, 0) < seconds * 10:
		return false
	cooldown_data[subject] = OS.get_ticks_msec()
	var result = node.run(subject)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result
