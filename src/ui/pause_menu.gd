extends Control

signal resume_pressed()
signal main_menu_pressed()

func _ready() -> void:
	visible = false

func show_menu() -> void:
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	visible = false
	get_tree().paused = false

func _on_resume_button_pressed() -> void:
	hide_menu()
	resume_pressed.emit()

func _on_main_menu_button_pressed() -> void:
	hide_menu()
	main_menu_pressed.emit()

func _on_quit_button_pressed() -> void:
	get_tree().quit()
