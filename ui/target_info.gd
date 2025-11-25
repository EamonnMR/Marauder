extends ColorRect

func _ready():
	Client.player_target_updated.connect(func _update_target(target):
		if Client.player_target:
			$StaticLabel.text = target.data.make + " " + target.data.name
	)

func _process(delta):
	if Client.player_target:
		$DynamicLabel.text = Client.player_target.display_state()
