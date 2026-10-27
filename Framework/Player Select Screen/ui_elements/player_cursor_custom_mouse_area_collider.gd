class_name PlayerCursorCustomMouseAreaCollider extends Area2D

@export var parent_button: Node

## Run by cursors when clicked.
func clicked() -> void:
	parent_button.clicked()
