tool
extends BehaviorComposite

func get_name() -> String:
	return "Parallel"


func run(subject : Node) -> bool:
	# TODO: wait for all / for one
	for child in connections:
		subject.execute_node(child)
	return true
