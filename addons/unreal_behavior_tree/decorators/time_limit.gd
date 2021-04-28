tool
extends BehaviorDecorator

export var seconds := 1.0

class Waiter:
	signal completed(signal_name)
	
	func _init(object_a : Object, signal_a : String, object_b : Object,
			signal_b : String) -> void:
		object_a.connect(signal_a, self, "_on_Object_signal_emitted", [signal_a])
		object_b.connect(signal_b, self, "_on_Object_signal_emitted", [signal_b])
	
	func _on_Object_signal_emitted(signal_name : String) -> void:
		emit_signal("completed")


func get_name() -> String:
	return "Time Limit"


func get_info() -> String:
	return " max %s seconds" % seconds


func run(node, subject : Node) -> bool:
	var timer := subject.get_tree().create_timer(seconds)
	var result = node.run(subject)
	if not result is GDScriptFunctionState:
		return result
	var signal_name : String = yield(Waiter.new(timer, "timeout", result,
			"completed"), "completed")
	if signal_name == "timeout":
		return false
	return result
