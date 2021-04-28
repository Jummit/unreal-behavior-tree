tool
extends GraphNode

signal changed(to)

const Comment = preload("../resources/comment.gd")

var comment_data : Comment setget set_comment_data

onready var comment_label : Label = $CommentLabel
onready var comment_edit : TextEdit = $CommentLabel/CommentEdit

func set_comment_data(comment_node : Comment) -> void:
	offset = comment_node.position
	comment_label.text = comment_node.text
	comment_edit.text = comment_node.text
	rect_size = comment_node.size


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		comment_label.rect_size.y = rect_size.y


func _on_TextEdit_focus_exited() -> void:
	emit_signal("comment_changed", comment_edit.text)
	comment_edit.hide()


func _on_CommentLabel_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and\
			event.button_index == BUTTON_LEFT:
		comment_edit.show()
		comment_edit.call_deferred("grab_focus")
