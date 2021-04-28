tool
extends Resource
class_name BehaviorTree

export var nodes : Dictionary
export var comments : Array

const StartNode = preload("start_node.gd")

func _init() -> void:
	if nodes.empty():
		nodes[0] = StartNode.new()


func get_available_id() -> int:
	var max_id := 0
	for node_id in nodes:
		max_id = max(max_id, node_id)
	return max_id + 1


func get_start() -> StartNode:
	return nodes[0]
