tool
extends BehaviorDecorator

export var function : String

func get_name() -> String:
	return "Call Function"


func get_info() -> String:
	return function


func should_abort(player : Node) -> bool:
	return player.subject.call(function)
