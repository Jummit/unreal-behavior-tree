tool
extends BehaviorDecorator

func get_name() -> String:
	return "Always Succeed"


func run(node, subject : Node) -> bool:
	var result = node.run(subject)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return true
