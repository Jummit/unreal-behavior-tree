tool
extends BehaviorTask

export var time := 1.0

func get_name() -> String:
	return "Wait"


func get_info() -> String:
	return "for %s seconds" % time


func run(subject : Node) -> bool:
	yield(subject.get_tree().create_timer(time), "timeout")
	return true
