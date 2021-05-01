tool
extends BehaviorService

export var function : String

func run(player : Node) -> void:
	player.subject.call(function)


func get_name() -> String:
	return "Call Function"


func get_info() -> String:
	return function


func get_text() -> String:
	return "Call %s every %ss" % [function, interval]
