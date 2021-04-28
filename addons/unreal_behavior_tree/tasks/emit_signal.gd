tool
extends BehaviorTask

export var signal_name : String

func get_name() -> String:
	return "Emit Signal"


func run(subject : Node) -> bool:
	subject.emit_signal(signal_name)
	return true
