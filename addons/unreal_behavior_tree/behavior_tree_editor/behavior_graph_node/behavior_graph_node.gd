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
	for attachment in node.attachments:
		var item := attachments.create_item(root)
		item.custom_minimum_height = 30
		item.set_text(0, attachment.name + " " + attachment.get_info())
		item.add_button(1, get_icon("Edit"))
		item.add_button(2, get_icon("Remove"))
	var left := not node is StartNode
	var right := not node is BehaviorTask
	set_slot(0, left, 0, Color.white, right, 0, Color.white)
	$AddAttachmentButton.visible = not node is StartNode


func _on_AttachmentInfo_edited(info : PanelContainer) -> void:
	emit_signal("attachment_edited", info.attachment)


func _on_AddAttachmentButton_pressed() -> void:
	emit_signal("attachment_added")


func _on_AttachmentInfo_removed(info : PanelContainer) -> void:
	emit_signal("attachment_removed", info.attachment)
