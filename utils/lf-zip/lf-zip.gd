class_name LFZip;
extends RefCounted;


static func createExtractor(pathToZip := '' , pathToExtract := '') -> LFZipExtractor:
	var outDir := LFFile.toAbsolute(pathToExtract.get_base_dir());
	var extractor := LFZipExtractor.new();
	extractor.pathToZip = LFFile.toAbsolute(pathToZip);
	extractor.pathToExtract = outDir;
	return extractor;


static func extract(pathToZip: String, pathToExtract: String = ''):
	var extractor := createExtractor(pathToZip, pathToExtract);
	extractor.start();
	return await extractor.finished;
