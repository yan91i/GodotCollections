@tool
extends EditorPlugin
## Replaces each selected node in the Scene with an instance of the selected
## PackedScene from the FileSystem.
##
## The instantiated PackedScene inherits transform information from the node it
## replaces. Exactly one PackedScene should be selected in the FileSystem and
## at least one node should be selected in the Scene.
##
## * Undo/redo is currently not supported for this command.
##
## * Assumes that the selected PackedScene path, and selected nodes all
##	 have a Node3D as their root, skips selected nodes otherwise.

var utilities = SceneBuilderToolbox.new()

func execute():
	var undo_redo: EditorUndoRedoManager = get_undo_redo()
	var current_scene: Node = EditorInterface.get_edited_scene_root()
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array[Node] = selection.get_selected_nodes()
	var selected_paths: PackedStringArray = EditorInterface.get_selected_paths()

	# Verify that only one FileSystem path is selected
	if selected_paths.size() != 1:
		print("[Swap Nodes] Please select exactly one PackedScene in the FileSystem.")
		return

	# Verify that selected Filesystem item is a PackedScene
	var selected_path = selected_paths[0]
	var resource = load(selected_path)
	if not resource or not resource is PackedScene:
		print("[Swap Nodes] The selected path is not a PackedScene.")
		return

	# Verify selected nodes
	if selected_nodes.is_empty():
		print("[Swap Nodes] Select at least one node in the Scene.")
		return

	undo_redo.create_action("Swap selected nodes with a single selected node in FileSystem")

	for node in selected_nodes:
		var instance: Node3D = resource.instantiate()
		instance.transform = node.transform

		var parent = node.get_parent()
		if parent and instance and node:
			undo_redo.add_do_method(parent, "add_child", instance)
			undo_redo.add_do_method(instance, "set_owner", current_scene)
			undo_redo.add_do_method(instance, "set_name", utilities.get_unique_name(instance.name, parent))
			undo_redo.add_do_method(node, "queue_free")

			undo_redo.add_undo_method(instance, "queue_free")
			undo_redo.add_undo_method(self, "print_message", "Nodes cleared from memory, undo unavailable")

			print("[Swap Nodes] Node has been swapped: " + node.name)
		else:
			printerr("[Swap Nodes] parent not found for node: " + node.name)

	undo_redo.commit_action()

func print_message(message: String):
	print(message)
