tool
extends ConfirmationDialog

"""
Dialog to search and choose nodes to add to the graph
"""

signal node_selected(node)
signal attachment_selected(attachment)

var services := [
	preload("../../services/call_function.gd"),
]

var composites := [
	preload("../../composites/parallel.gd"),
	preload("../../composites/selector.gd"),
	preload("../../composites/sequence.gd"),
]

var tasks := [
	preload("../../tasks/finish.gd"),
	preload("../../tasks/run_behavior.gd"),
	preload("../../tasks/wait.gd"),
	preload("../../tasks/call_function.gd"),
	preload("../../tasks/emit_signal.gd"),
]

var decorators := [
	preload("../../decorators/always_succeed.gd"),
	preload("../../decorators/check_condition.gd"),
	preload("../../decorators/cooldown.gd"),
	preload("../../decorators/loop.gd"),
	preload("../../decorators/time_limit.gd"),
	preload("../../decorators/call_function.gd"),
]

enum Mode {
	Nodes,
	Attachments,
}

var mode : int

onready var search_edit : LineEdit = $VBoxContainer/SearchEdit
onready var list : Tree = $VBoxContainer/List

func _ready() -> void:
	search_edit.right_icon = get_icon("Search", "EditorIcons")


func update_list(search_term := "") -> void:
	list.clear()
	var root := list.create_item()
	var roots := {}
	for item in decorators + services if mode == Mode.Attachments else composites + tasks:
		var type := get_type(item.new())
		if search_term and not search_term.to_lower().strip_edges() in item.new().name.to_lower():
			continue
		if not type in roots:
			var root_item := list.create_item(root)
			root_item.set_text(0, type)
			root_item.set_selectable(0, false)
			roots[type] = root_item
		var tree_item := list.create_item(roots[type])
		tree_item.set_metadata(0, item)
		tree_item.set_text(0, item.new().name)
	root.get_prev_visible(true).select(0)


func get_type(item) -> String:
	if item  is BehaviorComposite:
		return "Composite"
	elif item is BehaviorDecorator:
		return "Decorator"
	elif item is BehaviorService:
		return "Service"
	elif item is BehaviorTask:
		return "Task"
	return ""


func _on_NodeList_item_activated() -> void:
	var item = list.get_selected().get_metadata(0).new()
	emit_signal("node_selected" if mode == Mode.Nodes else "attachment_selected",
		item)
	hide()


func _on_SearchEdit_text_changed(new_text : String) -> void:
	update_list(new_text)


func _on_about_to_show() -> void:
	update_list()
	yield(get_tree(), "idle_frame")
	search_edit.clear()
	search_edit.grab_focus()


func _on_SearchEdit_text_entered(new_text: String) -> void:
	if not list.get_selected():
		return
	emit_signal("node_selected", list.get_selected().get_metadata(0))
	hide()
