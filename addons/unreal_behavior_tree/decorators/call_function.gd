tool
extends BehaviorDecorator

export var function : String

func get_name() -> String:
	return "Call Function"


func get_info() -> String:
	return function


func run(node, subject : Node) -> bool:
	var result = subject.call(function)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result
