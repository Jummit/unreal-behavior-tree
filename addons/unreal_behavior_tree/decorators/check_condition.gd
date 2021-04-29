tool
extends BehaviorDecorator

export var condition : String

func get_name() -> String:
	return "Check Condition"


func get_text() -> String:
	return "If " + condition


func run(node, subject : Node) -> bool:
	var script := GDScript.new()
	script.source_code = """
extends DictionaryWrapper
func run() -> bool:
	return self.""" + condition
	script.reload()
	var instance = script.new()
	instance.state = subject.state
	if not instance.run():
		return false
	var result = node.run(subject)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result
