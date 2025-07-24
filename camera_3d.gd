extends Camera3D
#
#var camera_ratio = 1152 / 20 # Screen width px over meters
#
#func _ready():
	#size = int(get_viewport().size.y / camera_ratio)
## This needs to be set on an overriden window class
#func _notification(what: int) -> void:
	#if what == NOTIFICATION_WM_SIZE_CHANGED:
		#breakpoint
		#size = int(get_viewport().size.y / camera_ratio)
##
##func _on_resize(delta):
	##breakpoint
	##size = int(get_viewport().size.y / camera_ratio)
