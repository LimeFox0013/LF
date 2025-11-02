## Static facade with a simple OK/ERROR return.
class_name LFZip;


enum STATUS {
	ERROR,
	OK,
}

## Unpack a zip to a directory using a background worker and await completion.
##
## @param zipPath String: path to .zip
## @param dirPath String: destination directory ('' → zip's folder)
## @return int: LFZip.OK on success, LFZip.ERROR on failure
static func unpack(zipPath: String, dirPath: String) -> int:
	var worker := ZipUnpacker.new();
	var finalResult := { 'ok': false };

	# Optional: connect to progress if you want UI updates.
	# worker.unzipProgress.connect(func(done: int, total: int) -> void:
	# 	print('Unzipping: %d/%d' % [done, total]);
	# );
	worker.unzipFinished.connect(
		func(res: Dictionary) -> void:
			finalResult = res;
	);

	var started := worker.start(zipPath, dirPath, 5);
	if started != OK:
		return STATUS.ERROR;

	await worker.unzipFinished;

	return LFZip.STATUS.OK if finalResult.ok else LFZip.STATUS.ERROR;
