tool
extends BehaviorComposite

func get_name() -> String:
	return "Sequence"


func run(subject : Node) -> bool:
	for child in connections:
		var result = subject.execute_node(child)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if not result:
			return false
	return true
