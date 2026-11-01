@tool
extends EditorPlugin
## Forest Map Kit - editor plugin. Adds "Project > Tools > Forest Map Kit: Import map or world..." which turns a map.json
## (one map) or a world.json (a grid of maps) exported by the Random Map Generator into scenes under res://forest_maps/.

const MENU := "Forest Map Kit: Import map or world..."
const OUT_DIR := "res://forest_maps"
var _dialog: EditorFileDialog


func _enter_tree() -> void:
	add_tool_menu_item(MENU, _open_dialog)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU)
	if _dialog != null:
		_dialog.queue_free()
		_dialog = null


func _open_dialog() -> void:
	if _dialog == null:
		_dialog = EditorFileDialog.new()
		_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_dialog.filters = PackedStringArray(["*.json ; map.json or world.json from the Random Map Generator"])
		_dialog.title = "Forest Map Kit: pick a map.json or world.json (inside this project, next to the ForestMapKit folder)"
		_dialog.file_selected.connect(_on_file_selected)
		get_editor_interface().get_base_control().add_child(_dialog)
	_dialog.popup_centered_ratio(0.6)


func _on_file_selected(path: String) -> void:
	var built := ForestMapKitImporter.import_any(path, OUT_DIR)
	if built.is_empty():
		push_error("Forest Map Kit: nothing was built (see the errors above).")
		return
	get_editor_interface().get_resource_filesystem().scan()
	print("Forest Map Kit: built ", built)
	get_editor_interface().open_scene_from_path(built)
