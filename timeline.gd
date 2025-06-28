extends HBoxContainer

var bar = load("res://stick.tscn");
@onready var root = get_tree().root.get_child(1) 
@onready var circle = preload("res://circle.tscn")

var beatmap

var timer = 0

var circles = []

var screen_width
var screen_height

func setup():	
	screen_width = get_window().size.x
	screen_height = get_window().size.y
	var scene = bar.instantiate()
	add_child(scene);
	scene.position.x = get_window().size.x / 2
	scene.position.y = get_window().size.y / 2 - scene.get_child(0).texture.get_height()/2
	beatmap = root.beatmap.duplicate(false)

func _process(delta: float) -> void:
	if (root.is_playing):
		_render_circles()
	
func get_position_x(w, t, ti, s):
	var res = ((ti/1000 - t) * w / 10 / s) + w/2
	return res

func _render_circles():
	if beatmap:
		while len(circles):
			circles[0].queue_free();
			circles.remove_at(0);
			
		while (get_position_x(screen_width, root.music_point, beatmap[0], root.timeline_scale) < 0):
			beatmap.remove_at(0)
		var i = 0
		while ((get_position_x(screen_width, root.music_point, beatmap[i], root.timeline_scale) < screen_width) and i < len(beatmap) - 1):
			circles.append(circle.instantiate())
			circles[-1].position.y = screen_height / 2 
			circles[-1].position.x = get_position_x(screen_width, root.music_point, beatmap[i], root.timeline_scale)
			circles[-1].timing = beatmap[i]
			add_child(circles[i])
			i += 1
