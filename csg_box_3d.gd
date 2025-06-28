extends CSGBox3D

@onready var Player = get_node("PlayerController").get_child(0)

func _process(delta):
	self.transform.origin.y = -3;
	self.transform.origin.x = Player.transform.x;
	self.transform.origin.z = Player.transform.z;
	
