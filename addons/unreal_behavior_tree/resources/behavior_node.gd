tool
extends Resource
class_name BehaviorNode, "../icon.svg"

export var position : Vector2
export var connections : Array
#export var connections : PoolIntArray
export var attachments : Array

var name : String setget , get_name

func _init() -> void:
	connections = []


func get_name() -> String:
	return ""


func run(_subject : Node) -> bool:
	return true


func get_info() -> String:
	return ""


func get_text() -> String:
	return get_name() + " " + get_info()
