tool
extends GraphNode

signal attachment_edited(attachment)
signal attachment_removed(attachment)
signal attachment_added

var node : BehaviorNode setget set_node

const StartNode = preload("res://addons/unreal_behavior_tree/resources/start_node.gd")

onready var attachments : Tree = $Attachments

func set_node(_node : BehaviorNode) -> void:
	node = _node
	offset = node.position
	title = node.get_name() + " " + node.get_info()
	var root := attachments.create_item()
	attachments.set_column_expand(0, true)
	attachments.visible = not node.attachments.empty()
	if not node.attachments.empty():
		attachments.rect_min_size = Vector2(200, 8)
	for attachment in node.attachments:
		var item := attachments.create_item(root)
		item.custom_minimum_height = 20
		item.set_metadata(0, attachment)
		item.set_text(0, attachment.name + " " + attachment.get_info())
		item.add_button(0, get_icon("Edit", "EditorIcons"))
		item.add_button(0, get_icon("Remove", "EditorIcons"))
		attachments.rect_min_size.y += 26
	var left := not node is StartNode
	var right := not node is BehaviorTask
	set_slot(0, left, 0, Color.white, right, 0, Color.white)
	$AddAttachmentButton.visible = not node is StartNode


func _input(event : InputEvent) -> void:
	attachments.scroll_to_item(attachments.get_root())


func _on_AddAttachmentButton_pressed() -> void:
	emit_signal("attachment_added")


func _on_Attachments_button_pressed(item : TreeItem, _column : int,
		id : int) -> void:
	if id == 0:
		emit_signal("attachment_edited", item.get_metadata(0))
	else:
		emit_signal("attachment_removed", item.get_metadata(0))
