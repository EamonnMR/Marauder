extends ColorRect

var enabled: bool = true

func _process(_delta):
	if Input.is_action_just_pressed("toggle_sharpen"):
		if enabled:
			material.set_shader_parameter("blur_sharp", 0)
			material.set_shader_parameter("pixel", 1)
			enabled = false
		else:
			material.set_shader_parameter("blur_sharp", -5)
			material.set_shader_parameter("pixel", 1)
			enabled = true
