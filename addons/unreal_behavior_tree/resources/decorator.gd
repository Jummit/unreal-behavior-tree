tool
extends BehaviorAttachment
class_name BehaviorDecorator

func run(_node, _player : Node) -> bool:
	return true


func should_abort(_player : Node) -> bool:
	return false
