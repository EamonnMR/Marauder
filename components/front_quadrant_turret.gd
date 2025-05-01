extends Node3D

func add_graphics(graphics):
	$ElevationPivot.add_child(graphics)

func get_emerge_point():
	return $ElevationPivot/Graphics/EmergePoint

func _process(delta):
	var rotate_self, rotate_pivot $EulerAimHelper.do the thing
