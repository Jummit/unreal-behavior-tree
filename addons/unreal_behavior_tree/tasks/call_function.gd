tool
extends BehaviorTask

export var function : String

func get_name() -> String:
	return "Call Function"


func get_info() -> String:
	return function


func run(subject : Node) -> bool:
	return subject.subject.call(function)
