extends Node
class_name BehaviorTreePlayer, "../icon.svg"

export var tree : BehaviorTree
export var state : Dictionary

onready var subject := get_parent()
var client : WebSocketClient
var breakpoints : Array
var stopped := false
var stop_on_next := false

var stack : PoolIntArray

# Used so decorators can call `run` without having to worry about if the node
# is another decorator or the actuall task/composite.
class DecoratorTaskProxy:
	# The decorator to be executed.
	var current
	# Could be another proxy or the actuall node.
	var next
	
	func _init(_current = null) -> void:
		current = _current
	
	func run(subject : BehaviorTreePlayer) -> bool:
		if current is BehaviorDecorator:
			var result = current.run(next, subject)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
			return result
		else:
			var result = current.run(subject)
			if result is GDScriptFunctionState:
				result = yield(result, "completed")
			return result


func _ready() -> void:
	if OS.is_debug_build():
		client = WebSocketClient.new()
		client.connect_to_url("localhost:7777")
		client.connect("connection_established", self, "_on_WebSocketClient_connection_established")
		client.connect("connection_closed", self, "_on_WebSocketClient_connection_closed")
		client.connect("connection_error", self, "_on_WebSocketClient_connection_error")
		client.connect("data_received", self, "_on_WebSocketClient_data_received")
	for node_id in tree.nodes:
		for attachment in tree.nodes[node_id].attachments:
			if attachment is BehaviorService:
				var timer := Timer.new()
				timer.wait_time = attachment.interval
				timer.autostart = true
				timer.connect("timeout", self, "_on_ServiceTimer_timeout",
						[attachment, node_id])
				add_child(timer)
	while true:
		var result = execute_node(tree.nodes[0].connections[0])
		if result is GDScriptFunctionState:
			result = yield(result, "completed")


func _process(_delta : float) -> void:
	if client and client.get_connection_status() !=\
			NetworkedMultiplayerPeer.CONNECTION_DISCONNECTED:
		client.poll()
	for node in stack:
		pass
		# TODO: terminate if service says to do so


func execute_node(node : int):
	stack.append(node)
	if client and client.get_connection_status() ==\
			NetworkedMultiplayerPeer.CONNECTION_CONNECTED:
		client.get_peer(1).put_var({
			type = "stack_update",
			stack = stack,
		})
	if node in breakpoints or stop_on_next:
		stopped = true
	if stopped:
		client.get_peer(1).put_var({
			type = "stopped",
		})
	while stopped:
		yield(client, "data_received")
	var root_proxy : DecoratorTaskProxy
	var current_proxy : DecoratorTaskProxy
	for attachment in tree.nodes[node].attachments:
		if attachment is BehaviorDecorator:
			var new_proxy := DecoratorTaskProxy.new(attachment)
			if not root_proxy:
				current_proxy = new_proxy
				root_proxy = new_proxy
			else:
				current_proxy.next = new_proxy
				current_proxy = new_proxy
		elif attachment is BehaviorService:
			pass
	var result
	if root_proxy:
		current_proxy.next = DecoratorTaskProxy.new(tree.nodes[node])
		result = root_proxy.run(self)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
	else:
		result = tree.nodes[node].run(self)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
	stack.remove(stack.size() - 1)
	yield(get_tree().create_timer(0.5), "timeout")
	return result


func _on_WebSocketClient_connection_established(protocol : String) -> void:
	pass


func _on_WebSocketClient_connection_closed(was_clean_close : bool) -> void:
	print("clo")


func _on_WebSocketClient_connection_error() -> void:
	print("err")


func _on_WebSocketClient_data_received() -> void:
	var data : Dictionary = client.get_peer(1).get_var()
	match data.type:
		"breakpoints":
			breakpoints = data.breakpoints
		"break":
			stopped = true
		"continue":
			stopped = false
			stop_on_next = false
		"next":
			stopped = false
			stop_on_next = true


func _on_ServiceTimer_timeout(service : BehaviorService, node : int) -> void:
	if node in Array(stack):
		service.run(self)
