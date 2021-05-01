tool
extends BehaviorDecorator

func get_name() -> String:
	return "Always Succeed"


func run(node, player : Node) -> bool:
	var result = node.run(player)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return true
