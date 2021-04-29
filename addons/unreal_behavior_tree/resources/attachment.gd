tool
extends Resource
class_name BehaviorAttachment, "../icon.svg"

var name : String setget , get_name

func get_name() -> String:
	return ""


func get_info() -> String:
	return ""


func get_text() -> String:
	return get_name() + " " + get_info()
