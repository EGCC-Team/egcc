extends Node2D
var root
var on_selected;
var paths = [];

func _ready():
	root = get_node("Buttons")

func add_button(name,path):
	root.add_button(name)
	paths.push_back(path);
	return root.get_button_count() - 1

func _on_Buttons_button_selected(idx):
	var path = paths[idx];
	if(on_selected):
		on_selected.call_func(path)
	else:
		print("I really dunno what to do with this click")