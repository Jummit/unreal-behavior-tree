tool
extends Control

signal resource_edited(resource)

var tree : BehaviorTree setget set_behavior_tree

var undo_redo : UndoRedo
var copied_nodes : Array
var copy_offset : Vector2
var connecting_from := -1
var from_position : Vector2
var search_dialog : ConfirmationDialog
var adding_attachment_to : BehaviorNode
var server := WebSocketServer.new()
var debug_connections : Array
var connections_by_id : Dictionary
var connections_by_tree : Dictionary
var current_connection : DebugConnection setget set_current_connection
var skip_breakpoints : bool
var breakpoints : Dictionary

class DebugConnection:
	var client_id : int
	var current_node : int
	var active_nodes : PoolIntArray
	var stopped : bool
	var tree : BehaviorTree
	var node_name : String
	func _init(_tree : BehaviorTree, _node_name : String,
			_client_id : int) -> void:
		tree = _tree
		node_name = _node_name
		client_id = _client_id

const Comment = preload("../resources/comment.gd")
const BehaviorGraphNode = preload("behavior_graph_node/behavior_graph_node.gd")
const CommentGraphNode = preload("comment_graph_node.gd")

onready var graph_edit : GraphEdit = $VBoxContainer/GraphEdit
onready var continue_button : Button = $VBoxContainer/DebugPanel/HBoxContainer/ContinueButton
onready var breakpoint_button : Button = $VBoxContainer/DebugPanel/HBoxContainer/BreakpointButton
onready var skip_breakpoints_button : Button = $VBoxContainer/DebugPanel/HBoxContainer/SkipBreakpointsButton
onready var step_button : Button = $VBoxContainer/DebugPanel/HBoxContainer/StepButton
onready var break_button : Button = $VBoxContainer/DebugPanel/HBoxContainer/BreakButton
onready var node_option_button : OptionButton = $VBoxContainer/DebugPanel/HBoxContainer/NodeOptionButton

func _ready():
	server.listen(7777)
	server.connect("client_connected", self,
			"_on_WebSocketServer_client_connected")
	server.connect("client_disconnected", self,
			"_on_WebSocketServer_client_disconnected")
	server.connect("data_received", self,
			"_on_WebSocketServer_data_received")
	
	var create_node_button := Button.new()
	create_node_button.text = "Add Node..."
	create_node_button.flat = true
	create_node_button.hint_tooltip = "Open the node creation dialog"
	create_node_button.connect("pressed", self, "_on_CreateNodeButton_pressed")
	graph_edit.get_zoom_hbox().add_child(create_node_button)
	graph_edit.get_zoom_hbox().move_child(create_node_button, 0)
	
	breakpoint_button.icon = get_icon("DebugSkipBreakpointsOff", "EditorIcons")
	skip_breakpoints_button.icon = get_icon("DebugSkipBreakpointsOff", "EditorIcons")
	break_button.icon = get_icon("Pause", "EditorIcons")
	step_button.icon = get_icon("DebugNext", "EditorIcons")
	continue_button.icon = get_icon("DebugContinue", "EditorIcons")
	
	search_dialog.connect("node_selected", self,
			"_on_SearchDialog_node_selected")
	search_dialog.connect("attachment_selected", self,
			"_on_SearchDialog_attachment_selected")


func _input(event : InputEvent) -> void:
	if event is InputEventKey and event.scancode == KEY_F9:
		mark_breakpoints()


func _process(_delta : float) -> void:
	if server.get_connection_status() !=\
			NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		server.poll()


func set_behavior_tree(to) -> void:
	tree = to
	if current_connection and current_connection.tree != tree and\
			tree in connections_by_tree:
		set_current_connection(connections_by_tree[tree].front())
	update_graph()
	update_node_dropdown()


func set_current_connection(connection : DebugConnection) -> void:
	current_connection = connection
	if tree != connection.tree:
		set_behavior_tree(connection.tree)
	break_button.disabled = connection.stopped
	step_button.disabled = not connection.stopped
	continue_button.disabled = not connection.stopped


func add_node(node : BehaviorNode, id : int, position : Vector2) -> void:
	node.position = position
	tree.nodes[id] = node


func remove_node(id : int) -> void:
	tree.nodes.erase(id)


func add_attachment(node : BehaviorNode, attachment : BehaviorAttachment,
		position : int) -> void:
	node.attachments.insert(position, attachment)


func remove_attachment(node : BehaviorNode, attachment : BehaviorAttachment) -> void:
	node.attachments.erase(attachment)


func add_comment(comment : Comment) -> void:
	tree.comments.append(comment)


func remove_comment(comment : Comment) -> void:
	tree.comments.erase(comment)


func move_node(node : BehaviorNode, to : Vector2) -> void:
	node.position = to
	update_node_order()


class NodeYSorter:
	var tree : BehaviorTree
	func sort(a : int, b : int) -> bool:
		return tree.nodes[a].position.y < tree.nodes[b].position.y


func update_node_order() -> void:
	for node in tree.nodes:
		var sorter := NodeYSorter.new()
		sorter.tree = tree
		tree.nodes[node].connections.sort_custom(sorter, "sort")


func connect_nodes(from : int, to : int) -> void:
	if not to in tree.nodes[from].connections:
		tree.nodes[from].connections.append(to)


func disconnect_nodes(from : int, to : int) -> void:
	var connections := Array(tree.nodes[from].connections)
	connections.erase(to)
	tree.nodes[from].connections = connections


func update_graph() -> void:
	var selected := []
	for node in graph_edit.get_children():
		if node is GraphNode:
			if node.selected:
				selected.append(int(node.name))
			node.free()
	for comment in tree.comments:
		var node : CommentGraphNode = preload("comment_graph_node.tscn").instance()
		graph_edit.add_child(node)
		node.init(comment)
		node.set_meta("comment", comment)
		node.connect("comment_changed", self,
				"_on_CommentGraph_node_comment_changed", [comment])
		node.connect("resize_request", self,
				"_on_CommentGraph_resize_request", [node])
		node.connect("dragged", self, "_on_GraphNode_dragged",
			[node])
	for node_id in tree.nodes:
		var node : BehaviorNode = tree.nodes[node_id]
		var graph_node : BehaviorGraphNode = preload(\
				"behavior_graph_node/behavior_graph_node.tscn").instance()
		graph_node.name = str(node_id)
		graph_edit.add_child(graph_node)
		graph_node.node = node
		if current_connection and node_id in Array(current_connection.breakpoints):
			graph_node.overlay = GraphNode.OVERLAY_BREAKPOINT
		if current_connection and node_id == current_connection.current_node:
			graph_node.overlay = GraphNode.OVERLAY_POSITION
		graph_node.selected = node_id in selected
		graph_node.connect("dragged", self, "_on_GraphNode_dragged",
			[graph_node])
		graph_node.connect("attachment_edited", self,
				"_on_BehaviorGraphNode_attachment_edited")
		graph_node.connect("attachment_removed", self,
				"_on_BehaviorGraphNode_attachment_removed", [node])
		graph_node.connect("attachment_added", self,
				"_on_BehaviorGraphNode_attachment_added", [node])
		graph_node.connect("raise_request", self,
				"_on_BehaviorGraphNode_raise_request", [node])
	update_graph_connections()


func mark_breakpoints() -> void:
	if not tree in breakpoints:
		breakpoints[tree] = []
	for node in graph_edit.get_children():
		if node is GraphNode and node.selected:
			if int(node.name) in breakpoints[tree]:
				breakpoints[tree].erase(int(node.name))
			else:
				breakpoints[tree].append(int(node.name))
	send_breakpoints()
	update_graph()


func send_breakpoints():
	send_message({
		"type": "breakpoints",
		"breakpoints": [] if skip_breakpoints else breakpoints[tree],
	}, true)


func update_graph_connections() -> void:
	graph_edit.clear_connections()
	for node in graph_edit.get_children():
		if node is GraphNode and node.overlay == GraphNode.OVERLAY_POSITION:
			node.overlay = GraphNode.OVERLAY_BREAKPOINT
	for node_id in tree.nodes:
		var node : BehaviorNode = tree.nodes[node_id]
		for to in node.connections:
			graph_edit.connect_node(str(node_id), 0, str(to), 0)
			if current_connection and\
					to in Array(current_connection.active_nodes):
				graph_edit.set_connection_activity(str(node_id), 0, str(to),
						0, 100)


func send_message(message : Dictionary, to_all := false) -> void:
	if server.get_connection_status() ==\
			NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		return
	for connection in debug_connections if to_all else [current_connection]:
		if connection.tree == tree:
			server.get_peer(connection.client_id).put_var(message)


func _on_BehaviorGraphNode_raise_request(node : BehaviorNode) -> void:
	emit_signal("resource_edited", node)


func _on_GraphEdit_popup_request(position : Vector2) -> void:
	_show_create_dialog()
	from_position = (get_local_mouse_position() + graph_edit.scroll_offset) /\
			graph_edit.zoom


func _on_SearchDialog_node_selected(node : BehaviorNode) -> void:
	undo_redo.create_action("Add Node")
	var id := tree.get_available_id()
	undo_redo.add_do_method(self, "add_node", node, id, from_position)
	if connecting_from != -1:
		undo_redo.add_do_method(self, "connect_nodes", connecting_from, id)
		undo_redo.add_undo_method(self, "disconnect_nodes", connecting_from, id)
		connecting_from = -1
	undo_redo.add_undo_method(self, "remove_node", id)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_GraphEdit_connection_request(from : String, _from_slot : int,
		to : String, _to_slot : int) -> void:
	undo_redo.create_action("Connect Nodes")
	undo_redo.add_do_method(self, "connect_nodes", int(from), int(to))
	undo_redo.add_undo_method(self, "disconnect_nodes", int(from), int(to))
	undo_redo.add_do_method(self, "update_graph_connections")
	undo_redo.add_undo_method(self, "update_graph_connections")
	undo_redo.commit_action()


func _on_GraphEdit_delete_nodes_request() -> void:
	undo_redo.create_action("Remove Node(s)")
	for node in graph_edit.get_children():
		if not (node is GraphNode and node.selected):
			continue
		if node is BehaviorGraphNode:
			undo_redo.add_do_method(self, "remove_node", int(node.name))
			undo_redo.add_undo_method(self, "add_node", node.node,
					int(node.name), node.offset)
		elif node is CommentGraphNode:
			undo_redo.add_do_method(self, "remove_comment", node.comment_data)
			undo_redo.add_undo_method(self, "add_comment", node.comment_data)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_GraphEdit_begin_node_move() -> void:
	undo_redo.create_action("Move Node(s)")


func _on_GraphNode_dragged(from : Vector2, to : Vector2,
		node : GraphNode) -> void:
	undo_redo.add_do_method(self, "move_node", node.node, to)
	undo_redo.add_undo_method(self, "move_node", node.node, from)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")


func _on_GraphEdit_end_node_move() -> void:
	undo_redo.commit_action()


func _on_GraphEdit_connection_to_empty(from : String, _from_slot : int,
		release_position : Vector2) -> void:
	connecting_from = int(from)
	from_position = (release_position + graph_edit.scroll_offset) /\
			graph_edit.zoom
	_show_create_dialog(true)


func _on_GraphEdit_disconnection_request(from : String, _from_slot : int,
		to : String, _to_slot: int) -> void:
	undo_redo.create_action("Disconnect Node")
	undo_redo.add_do_method(self, "disconnect_nodes", int(from), int(to))
	undo_redo.add_undo_method(self, "connect_nodes", int(from), int(to))
	undo_redo.add_do_method(self, "update_graph_connections")
	undo_redo.add_undo_method(self, "update_graph_connections")
	undo_redo.commit_action()


func _on_GraphEdit_paste_nodes_request() -> void:
	undo_redo.create_action("Paste Nodes")
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_GraphEdit_copy_nodes_request() -> void:
	pass


func _on_GraphEdit_duplicate_nodes_request() -> void:
	undo_redo.create_action("Duplicate Nodes")
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_CommentGraph_node_comment_changed(to : String,
		comment) -> void:
	yield(get_tree(), "idle_frame")
	undo_redo.create_action("Edit Comment")
	undo_redo.add_do_property(comment, "text", to)
	undo_redo.add_undo_property(comment, "text", comment.text)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_CommentGraph_resize_request(new_min_size : Vector2,
		node : GraphNode) -> void:
	undo_redo.create_action("Resize Comment")
	undo_redo.add_do_property(node.comment_data, "size", new_min_size)
	undo_redo.add_undo_property(node.comment_data, "size", node.comment_data.size)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_SearchDialog_attachment_selected(attachment : BehaviorAttachment) -> void:
	do_add_attachment(adding_attachment_to, attachment)


func do_add_attachment(node : BehaviorNode,
		attachment : BehaviorAttachment) -> void:
	undo_redo.create_action("Add Attachment")
	undo_redo.add_do_method(self, "add_attachment", node,
			attachment, node.attachments.size())
	undo_redo.add_undo_method(self, "remove_attachment", node, attachment)
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _show_create_dialog(on_mouse := true,
		mode := search_dialog.Mode.Nodes) -> void:
	search_dialog.mode = mode
	search_dialog.popup()
	if on_mouse:
		search_dialog.rect_position = get_viewport().get_mouse_position()
		from_position = (get_local_mouse_position() + graph_edit.scroll_offset) /\
				graph_edit.zoom


func _on_CreateNodeButton_pressed() -> void:
	_show_create_dialog(false)


func _on_BehaviorGraphNode_attachment_edited(
		attachment : BehaviorAttachment) -> void:
	emit_signal("resource_edited", attachment)


func _on_BehaviorGraphNode_attachment_removed(attachment : BehaviorAttachment,
		node : BehaviorNode) -> void:
	yield(get_tree(), "idle_frame")
	undo_redo.create_action("Remove Attachment")
	undo_redo.add_do_method(self, "remove_attachment", node, attachment)
	undo_redo.add_undo_method(self, "add_attachment", node, attachment,
			node.attachments.find(attachment))
	undo_redo.add_do_method(self, "update_graph")
	undo_redo.add_undo_method(self, "update_graph")
	undo_redo.commit_action()


func _on_BehaviorGraphNode_attachment_added(attachment : BehaviorAttachment,
		node : BehaviorNode) -> void:
	if attachment:
		yield(get_tree(), "idle_frame")
		do_add_attachment(node, attachment)
	else:
		adding_attachment_to = node
		_show_create_dialog(false, search_dialog.Mode.Attachments)


func _on_WebSocketServer_client_connected(id : int, protocol : String) -> void:
	server.set_block_signals(true)
	while true:
		var packet_id : int = yield(server, "data_received")
		if packet_id == id:
			var info : Dictionary = server.get_peer(id).get_var()
			var client_tree = load(info.tree)
			if not client_tree in connections_by_tree:
				connections_by_tree[client_tree] = []
			var new := DebugConnection.new(client_tree, info.name, id)
			debug_connections.append(new)
			connections_by_id[id] = new
			connections_by_tree[client_tree].append(new)
			break
	server.set_block_signals(false)
	send_breakpoints()


func _on_WebSocketServer_client_disconnected(id : int, was_clean_close : bool) -> void:
	var debug_connection : DebugConnection
	for connected_tree in debug_connections:
		for connection in debug_connections[connected_tree]:
			if connection.client_id == id:
				debug_connection = connection
				break
		if debug_connection:
			break
	update_graph()


func _on_WebSocketServer_data_received(id : int) -> void:
	var packet : Dictionary = server.get_peer(id).get_var()
	match packet.type:
		"send_running":
			connections_by_id[id].active_nodes = packet.nodes
			update_graph()
		"stopped":
			connections_by_id[id].stopped = true
			set_current_connection(connections_by_id[id])


func update_node_dropdown():
	var show : bool = tree in connections_by_tree and\
			connections_by_tree[tree].size()
	node_option_button.visible = show
	if show:
		node_option_button.clear()
		var id := 0
		for connection in connections_by_tree[tree]:
			node_option_button.add_item(connection.name, id)
			if connection == current_connection:
				node_option_button.selected = id
			id += 1


func _on_BreakpointButton_pressed() -> void:
	mark_breakpoints()


func _on_SkipBreakpointsButton_pressed() -> void:
	skip_breakpoints = not skip_breakpoints
	skip_breakpoints_button.icon = get_icon("DebugSkipBreakpointsOn" if\
			skip_breakpoints else "DebugSkipBreakpointsOff", "EditorIcons")
	send_breakpoints()


func _on_BreakButton_pressed() -> void:
	if server.get_connection_status() ==\
			NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED or\
			not current_connection:
		return
	step_button.disabled = false
	continue_button.disabled = false
	send_message({
		"type": "break",
	})


func _on_ContinueButton_pressed() -> void:
	step_button.disabled = true
	continue_button.disabled = true
	current_connection.stopped = false
	send_message({
		"type": "continue",
	})


func _on_StepButton_pressed() -> void:
	send_message({
		"type": "next",
	})


func _on_NodeOptionButton_item_selected(index : int) -> void:
	pass # Replace with function body.
