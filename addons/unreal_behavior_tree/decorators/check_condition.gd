tool
extends BehaviorDecorator

export var condition : String

func get_name() -> String:
	return "Check Condition"


func get_text() -> String:
	return "If " + condition


func run(node, subject : Node) -> bool:
	var condition := Expression.new()
	# TODO: run expression
	if not condition:
		return false
	var result = node.run(subject)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result
