extends Reference
class_name DictionaryWrapper

var state : Dictionary

func _get(property : String):
	if property in state:
		return state[property]


func _set(property : String, value) -> bool:
	state[property] = value
	return true
