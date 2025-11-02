class_name LFThread;
extends Resource;

func _ready():
	get_tree().auto_accept_quit = false  # so the app doesn’t quit before we handle it

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		# cleanup / ask “Are you sure?”, etc.
		get_tree().quit()
