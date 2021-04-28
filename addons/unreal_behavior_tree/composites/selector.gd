tool
extends BehaviorComposite

func get_name() -> String:
	return "Selector"


func run(subject : Node) -> bool:
	for child in connections:
		if yield(subject.execute_node(child), "completed"):
			return true
	return false
