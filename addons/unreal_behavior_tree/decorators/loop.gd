tool
extends BehaviorDecorator

export var max_times := 10

func get_name() -> String:
	return "Loop"


func get_info() -> String:
	return "Max. %s times" % max_times


func run(node, subject : Node) -> bool:
	for i in max_times:
		var result = node.run(subject)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		else:
			yield(subject.get_tree(), "idle_frame")
		if not result:
			return false
	return true
