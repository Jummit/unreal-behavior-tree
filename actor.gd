extends Sprite

var target : Vector2

func find_spot():
	target = Vector2(randf(), randf()) * get_viewport().size
	return true


func move():
	position = position.move_toward(target, 1)
	return position != target
