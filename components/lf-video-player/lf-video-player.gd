class_name LFVideoPlayer;
extends VideoStreamPlayer;

# ToDo: I dont need ms here ?

func startAt(
	ms := 0.0,
	forceUnpause := false,
):
	stream_position = ms / 1000.0;
	play();
	if forceUnpause:
		paused = false;
	return self;


func pause():
	paused = true;
	return self;


func unpause():
	paused = false;
	return self;


func playFor(playTimeMs := 0.0, fromMs := stream_position * 1000.0):
	startAt(fromMs, true);
	await LFUtils.timeout(playTimeMs);
	return self;
