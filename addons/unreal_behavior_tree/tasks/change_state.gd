tool
extends BehaviorTask

export var expression : String

func get_name() -> String:
	return "Change State"


func get_text() -> String:
	return expression


func run(subject : Node) -> bool:
	var script := GDScript.new()
	script.source_code = """extends DictionaryWrapper
func run() -> void:
	self.""" + expression
	script.reload()
	var instance = script.new()
	instance.state = subject.state
	instance.run()
	subject.state = instance.state
	return true
