class_name PlayerCursorCustomMouseArea extends Area2D

var player_number: int = 1

var highlighted_area: PlayerCursorCustomMouseAreaCollider

func _on_area_entered(area: Area2D) -> void:
	if area is PlayerCursorCustomMouseAreaCollider:
		highlighted_area = area as PlayerCursorCustomMouseAreaCollider


func _on_area_exited(area: Area2D) -> void:
	if area == highlighted_area:
		highlighted_area = null


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed(CoopInput.get_player(player_number).A) and highlighted_area != null:
		highlighted_area.clicked()
