@tool
extends EditorPlugin

var properties := []

var settings: Control
var settings_content

var config = ConfigFile.new()

var dock_runbar
var dock_files
var dock_script
var dock_scene
var dock_inspector
var dock_node

var script_bottom
var error_label: Label

func _enter_tree():
	config.load("res://addons/editor_minimal/plugin.cfg")
	
	settings = load("res://addons/editor_minimal/settings.tscn").instantiate()
	settings_content = settings.get_node("%Content")
	
	add_control_to_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings)
	
	# ⭐ Runbar
	# these probably don't work in different languages but i didnt find a better way
	create_option("runbar", "run project", find_by_tooltip("Play the project"))
	create_option("runbar", "pause running", find_by_tooltip("Pause the running"))
	create_option("runbar", "stop running", find_by_tooltip("Stop the currently"))
	create_option("runbar", "play edited", find_by_tooltip("Play the edited"))
	create_option("runbar", "run specific scene", find_by_tooltip("Play a custom scene"))
	create_option("runbar", "movie maker", find_by_tooltip("Enable Movie Maker"))
	
	# ⭐ Script
	dock_script = EditorInterface.get_script_editor()
	
	var node_help = find_button_with_text(dock_script, "Search Help")
	create_option("script", "docs", find_button_with_text(dock_script, "Online Docs"))
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
	
	script_bottom = dock_script.get_child(0).get_child(1).get_child(1).get_child(0).get_child(0).get_child(0).get_child(0).get_child(1)
	
	error_label = script_bottom.get_child(1).get_child(0)
	
	# ⭐ Files
	
	# Rename tab
	dock_files = EditorInterface.get_file_system_dock()
	dock_files.name = "Files"
	
	create_option("file_system", "path section", dock_files.get_child(0).get_child(0))
	
	create_option("file_system", "previous/next", [
			dock_files.get_child(0).get_child(0).get_child(0),
			dock_files.get_child(0).get_child(0).get_child(1)
		])
	create_option("file_system", "path", [
			dock_files.get_child(0).get_child(0).get_child(2)
		])
	
	# ⭐ Inspector
	dock_inspector = get_tree().root.find_child("Inspector", true, false)
	
	create_option("inspector", "top section", dock_inspector.get_child(0))
	create_option("inspector", "documentation", dock_inspector.get_child(1).get_child(1))
	
	# ⭐ Scene
	dock_scene = get_tree().root.find_child("Scene", true, false)
	
	
	# ⭐ Node
	dock_node = dock_files.get_parent().get_parent().get_parent().find_child("Node", true, false)
	
	
	update_visible(true)

func _exit_tree():
	for property in properties:
		property.visible = true
	remove_control_from_container(CONTAINER_PROJECT_SETTING_TAB_RIGHT, settings)
	settings.queue_free()
	dock_files.name = "FileSystem"

func _process(delta):
	script_bottom.visible = error_label.text != ""

func create_option(category: String, name: String, node):
	if not node:
		print(name.capitalize(), " not found")
		return
	
	var category_node = settings.find_child(category, true, false)
	if not category_node:
		category_node = VBoxContainer.new()
		category_node.name = category
		category_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		if settings_content.get_child_count() > 0:
			var seperator = VSeparator.new()
			settings_content.add_child(seperator)
		settings_content.add_child(category_node)
		
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

func find_button_with_text(root, term: String):
	for child in root.get_children():
		if child is Button:
			if term in child.text:
				return child
		else:
			var match_in_child = find_button_with_text(child, term)
			if match_in_child:
				return match_in_child

func find_by_tooltip(term: String, node = null):
	if node == null:
		node = get_tree().root
	for child in node.get_children():
		if "tooltip_text" in child and term in child.tooltip_text:
			return child
		
		var match_in_child = find_by_tooltip(term, child)
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
