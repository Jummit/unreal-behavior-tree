tool
extends BehaviorDecorator

export var seconds := 1.0
var finished : Array
var timers : Dictionary

func get_name() -> String:
	return "Time Limit"


func get_text() -> String:
	return "Take max. %ss" % seconds


func should_abort(player : Node) -> bool:
	return player in finished


func run(node, player : Node) -> bool:
	if player in timers:
		timers[player].disconnect("timeout", self, "_on_Timer_timeout")
		finished.erase(player)
	var timer := player.get_tree().create_timer(seconds)
	timer.connect("timeout", self, "_on_Timer_timeout", [player])
	timers[player] = timer
	return true


func _on_Timer_timeout(player : Node) -> void:
	finished.append(player)
	timers.erase(player)
