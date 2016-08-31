extends Node
var skip_test_scene = false #set this to true before final export
var scenes_path = "res://scenes"
var loader
var wait_frames
var time_max = 100
var current_scene
var animation_node
var progress_node
var root_node
var scenes_node
var loading_node
var choice_node
var back_btn_node

func _ready():
	loading_node = get_node("Loading")
	animation_node = get_node("Loading/Animation")
	progress_node = get_node("Loading/Progress")
	scenes_node = get_node("Scenes")
	choice_node = get_node("Choice")
	back_btn_node = get_node("Back_btn")
	root_node = get_tree().get_root()
	current_scene = weakref(scenes_node.get_child(root_node.get_child_count() -1))
	var scenes = read_root_dir(scenes_path)
	choice_node.on_selected = funcref(self, "on_scene_selected")
	for scene_data in scenes:
		var name = scene_data.name
		if(name == 'Test' && skip_test_scene):
			pass
		else:
			var path = scene_data.path
			var title
			if scene_data.info.title:
				title = scene_data.info.title
			else:
				title = scene_data.name
			choice_node.add_button(title,path)
	back_to_choice()

func on_scene_selected(path):
	goto_scene(path)

func free_current_scene():
	if current_scene && current_scene.get_ref():
		current_scene.get_ref().queue_free()

func goto_scene(path):
	loader = ResourceLoader.load_interactive(path)
	
	if loader == null:
		show_error()
		return
		
	set_process(true)
	
	free_current_scene()
	loading_node.show();
	scenes_node.hide();
	back_btn_node.show();
	progress_node.set_val(0)
	animation_node.play("loading")
	
	wait_frames = 1

func _process(time):
	if loader == null:
		set_process(false)
		return
	
	if wait_frames > 0:
		wait_frames -= 1
		return
	
	var t = OS.get_ticks_msec()
	while OS.get_ticks_msec() < t + time_max:

		var err = loader.poll()
		
		if err == ERR_FILE_EOF:
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			break
		elif err == OK:
			update_progress()
		else:
			show_error()
			loader = null
			break

func update_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	progress_node.set_val(progress)
	var len = animation_node.get_current_animation_length()
	
	# call this on a paused animation. use "true" as the second parameter to force the animation to update
	animation_node.seek(progress * len, true)

func set_new_scene(scene_resource):
	current_scene = weakref(scene_resource.instance())
	scenes_node.add_child(current_scene.get_ref())
	scenes_node.show();
	choice_node.hide();
	loading_node.hide();

func back_to_choice():
	free_current_scene();
	loading_node.hide();
	scenes_node.hide();
	choice_node.show();
	back_btn_node.hide();

func read_dir(path,when_dir,when_file):
	var dir = Directory.new()
	var results = []
	if dir.open(path) == OK:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while (file_name != ""):
			if(file_name != "." && file_name != ".."):
				var file_path = path+"/"+file_name
				var ret;
				if dir.current_is_dir() && when_dir:
					ret = self.call(when_dir,file_path,file_name);
					if(ret!=null):
						results.push_back(ret)
				elif when_file:
					var ext = file_name.extension().to_lower()
					var basename = file_name.basename()
					ret = self.call(when_file,file_path,basename,ext);
					if(ret!=null):
						results.push_back(ret)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.");
	if(results.size()):
			return results;
	return results
	
func parse_json(path):
	var file_buffer = File.new();
	file_buffer.open(path,File.READ)
	var json_str = file_buffer.get_as_text()
	var data = {}
	data.parse_json(json_str)
	return data;
	
func read_root_dir(path):
	return read_dir(path,"read_scene_dir","")

func read_scene_dir(path,scene_name):
	var scene = {
		"name":scene_name
	}
	var files = read_dir(path,"","read_scene_file");
	var needed = 2;
	for file in files:
		if(needed<=0):
			break;
		if(file.name == scene_name):
			scene.path = file.path
			needed-=1
		elif(file.name == "info" && file.extension == "json"):
			var info = parse_json(file.path)
			scene.info = info
			needed-=1
			pass
	if(needed > 0):
		return null
	else:
		return scene
	
func read_scene_file(path,file_name,ext):
	if(ext != 'xml' && ext != 'scn' && ext != "json"):
		return null
	else:
		return {"path":path,"name":file_name,"extension":ext}

func _on_Back_btn_pressed():
	back_to_choice()
