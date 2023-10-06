@tool
extends EditorPlugin

var properties := []

var settings: Control

var config = ConfigFile.new()

var dock_scene
var dock_inspector
var dock_node

func _enter_tree():
	
	config.load("res://addons/editor_minimal/plugin.cfg")
	
	settings = Control.new()
	settings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.name = "Editor Features"
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings.add_child(vbox)
	
	add_control_to_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings)
	
	var node_help = find_button_with_text(EditorInterface.get_script_editor(), "Search Help")
	create_option("script", "docs", find_button_with_text(EditorInterface.get_script_editor(), "Online Docs"))
	create_option("script", "help", node_help)
	var script_seperator1 = node_help.get_parent().get_child(node_help.get_index() + 1)
	create_option("script", "seperator 1", script_seperator1)
	var script_previous = node_help.get_parent().get_child(node_help.get_index() + 2)
	var script_next = node_help.get_parent().get_child(node_help.get_index() + 3)
	create_option("script", "previous/next", [script_previous, script_next])
	var script_seperator2 = node_help.get_parent().get_child(node_help.get_index() + 4)
	create_option("script", "seperator 2", script_seperator2)
	var script_popout = node_help.get_parent().get_child(node_help.get_index() + 5)
	create_option("script", "popout", script_popout)
	
	
	create_option("file_system", "path section", EditorInterface.get_file_system_dock().get_child(0).get_child(0))
	
	create_option("file_system", "previous/next", [
			EditorInterface.get_file_system_dock().get_child(0).get_child(0).get_child(0),
			EditorInterface.get_file_system_dock().get_child(0).get_child(0).get_child(1)
		])
	create_option("file_system", "path", [
			EditorInterface.get_file_system_dock().get_child(0).get_child(0).get_child(2)
		])
	EditorInterface.get_file_system_dock().name = "Files"
	dock_scene = EditorInterface.get_file_system_dock().get_parent().get_parent().get_parent().find_child("Scene", true, false)
	dock_node = EditorInterface.get_file_system_dock().get_parent().get_parent().get_parent().find_child("Node", true, false)
	dock_inspector = EditorInterface.get_file_system_dock().get_parent().get_parent().get_parent().find_child("Inspector", true, false)
	
	update_visible(true)


func create_option(category: String, name: String, node):
	if not node:
		print(node, " not found")
		return
	
	var category_node = settings.find_child(category, true, false)
	if not category_node:
		category_node = VBoxContainer.new()
		category_node.name = category
		category_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if settings.get_child(0).get_child_count() > 0:
			var seperator = VSeparator.new()
			settings.get_child(0).add_child(seperator)
		settings.get_child(0).add_child(category_node)
		
		var label = Label.new()
		label.text = category.capitalize()
		category_node.add_child(label)
	
	var button := CheckButton.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = name.capitalize()
	button.button_pressed = config.get_value(category, name, false)
	button.pressed.connect(option_toggled)
	category_node.add_child(button)
	var property = Property.new(name, category, node, button)
	properties.push_back(property)

func option_toggled():
	update_visible()

func update_visible(force := false):
	for property in properties:
		if property.update(force):
			config.set_value(property.category, property.name, property.button.button_pressed)
	config.save("res://addons/editor_minimal/plugin.cfg")

func _exit_tree():
	for property in properties:
		property.visible = true
	remove_control_from_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings)
	settings.queue_free()
	get_editor_interface().get_file_system_dock().name = "FileSystem"
	dock_scene.name = "Scene"
	dock_inspector.name = "Inspector"
	dock_node.name = "Node"

func find_button_with_text(root, term: String):
	for child in root.get_children():
		if child is Button:
			if term in child.text:
				return child
		else:
			var match_in_child = find_button_with_text(child, term)
			if match_in_child:
				return match_in_child

class Property:
	var name: String
	var category: String
	var nodes: Array
	var button
	
	var visible: bool:
		get:
			return visible
		set(value):
			visible = value
			for node in nodes:
				node.visible = value
	
	func _init(p_name, p_category, p_nodes, p_button):
		name = p_name
		category = p_category
		if p_nodes is Array:
			nodes = p_nodes
		else:
			nodes = [p_nodes]
		button = p_button
	
	func update(force := false):
		if force:
			visible = button.button_pressed
			return false
		
		if visible == button.button_pressed:
			return false
		visible = button.button_pressed
		return true
