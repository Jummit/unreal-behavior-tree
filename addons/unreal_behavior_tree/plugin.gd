tool
extends EditorPlugin

var button : ToolButton

onready var behavior_tree_editor : Control = preload(\
		"behavior_tree_editor/behavior_tree_editor.tscn").instance()
var search_dialog := preload("behavior_tree_editor/search_dialog/search_dialog.tscn").instance()

func _ready() -> void:
	get_editor_interface().get_base_control().add_child(search_dialog)
	behavior_tree_editor.search_dialog = search_dialog
	behavior_tree_editor.undo_redo = get_undo_redo()
	behavior_tree_editor.hide()
	behavior_tree_editor.connect("resource_edited", self,
			"_on_BehaviorTreeEditor_resource_edited")
	button = add_control_to_bottom_panel(behavior_tree_editor, "Behavior Tree")
	get_editor_interface().get_inspector().connect("property_edited", self,
			"_on_Inspector_property_edited")
	button.hide()
	get_editor_interface().get_selection().connect("selection_changed", self,
			"_on_selection_changed")


func _on_selection_changed():
	var selected := get_editor_interface().get_selection().\
			get_selected_nodes()
	var player_selected := (not selected.empty()) and\
			selected.front() is BehaviorTreePlayer
	button.visible = player_selected
	if player_selected:
		make_bottom_panel_item_visible(behavior_tree_editor)
	else:
		hide_bottom_panel()


func _exit_tree() -> void:
	remove_control_from_bottom_panel(behavior_tree_editor)
	behavior_tree_editor.queue_free()


func handles(object : Object) -> bool:
	return object is BehaviorTree


func edit(object : Object) -> void:
	button.show()
	behavior_tree_editor.tree = object
	make_bottom_panel_item_visible(behavior_tree_editor)


func clear() -> void:
	behavior_tree_editor.hide()


func _on_BehaviorTreeEditor_resource_edited(resource : Resource) -> void:
	get_editor_interface().edit_resource(resource)


func _on_Inspector_property_edited(_property : String) -> void:
	if behavior_tree_editor.is_visible_in_tree():
		behavior_tree_editor.update_graph()
