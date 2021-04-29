tool
extends GraphNode

signal attachment_edited(attachment)
signal attachment_removed(attachment)
signal attachment_added(attachment)

var node : BehaviorNode setget set_node

const StartNode = preload("res://addons/unreal_behavior_tree/resources/start_node.gd")

onready var attachments : Tree = $Attachments

func _ready() -> void:
	attachments.set_drag_forwarding(self)


func can_drop_data_fw(_position : Vector2, data, _control : Control) -> bool:
	if data is Dictionary and "files" in data:
		var resource := load(data.files[0])
		return resource is Script and resource.new() is BehaviorAttachment
	return false


func drop_data_fw(_position : Vector2, data, _control : Control) -> void:
	emit_signal("attachment_added", load(data.files[0]).new())


func set_node(_node : BehaviorNode) -> void:
	node = _node
	offset = node.position
	title = node.get_text()
	var root := attachments.create_item()
	attachments.set_column_expand(0, true)
	attachments.visible = not node.attachments.empty()
	if not node.attachments.empty():
		attachments.rect_min_size = Vector2(200, 8)
	for attachment in node.attachments:
		var item := attachments.create_item(root)
		item.custom_minimum_height = 20
		item.set_metadata(0, attachment)
		item.set_custom_bg_color(0, Color.red if attachment is BehaviorService else Color.blue)
		item.set_text(0, attachment.get_text())
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
	emit_signal("attachment_added", null)


func _on_Attachments_button_pressed(item : TreeItem, _column : int,
		id : int) -> void:
	if id == 0:
		emit_signal("attachment_edited", item.get_metadata(0))
	else:
		emit_signal("attachment_removed", item.get_metadata(0))
