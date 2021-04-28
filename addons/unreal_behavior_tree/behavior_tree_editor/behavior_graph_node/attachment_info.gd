tool
extends PanelContainer

signal edited
signal removed

var attachment : BehaviorAttachment setget set_attachment

func set_attachment(_attachment : BehaviorAttachment) -> void:
	attachment = _attachment
	$HBoxContainer/NameLabel.text = attachment.name + " " + attachment.get_info()


func _on_Button_pressed() -> void:
	emit_signal("edited")


func _on_RemoveButton_pressed() -> void:
	emit_signal("removed")
