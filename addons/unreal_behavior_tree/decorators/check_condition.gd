tool
extends BehaviorDecorator

export var condition : String

func get_name() -> String:
	return "Check Condition"


func get_text() -> String:
	return "If " + condition


func should_abort(player : Node) -> bool:
	var script := GDScript.new()
	script.source_code = """
extends DictionaryWrapper
func run() -> bool:
	return self.""" + condition
	script.reload()
	var instance = script.new()
	instance.state = player.state
	return instance.run()
