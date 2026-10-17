extends RefCounted
## Fixed slot paths; user labels never become filesystem paths.
const INTERVAL := 3000 # Five simulated minutes.
static func base_path(path: String) -> String:
	var base := path.trim_suffix(".bak").trim_suffix(".auto.json")
	for index in range(1, 4): base = base.trim_suffix(".slot%d.json" % index)
	return base
static func slot_path(base: String, index: int) -> String:
	return base if index == 0 else base + ".slot%d.json" % clampi(index, 1, 3)
static func index_for(path: String) -> int:
	var base := base_path(path)
	for index in range(4):
		if slot_path(base, index) == path.trim_suffix(".bak").trim_suffix(".auto.json"): return index
	return 0
static func settings(base: String) -> ConfigFile:
	var config := ConfigFile.new()
	config.load(base_path(base) + ".slots.cfg")
	return config
static func label(base: String, index: int) -> String:
	var value = settings(base).get_value("names", str(index), "Main factory" if index == 0 else "Factory %d" % index)
	var title := str(value).strip_edges().left(40)
	return title if not title.is_empty() else ("Main factory" if index == 0 else "Factory %d" % index)
static func rename(base: String, index: int, title: String) -> Error:
	var config := settings(base)
	config.set_value("names", str(index), title.strip_edges().left(40))
	return config.save(base_path(base) + ".slots.cfg")
static func autosave_enabled(path: String) -> bool:
	return settings(path).get_value("autosave", str(index_for(path)), false) == true
static func set_autosave(path: String, enabled: bool) -> Error:
	var config := settings(path)
	config.set_value("autosave", str(index_for(path)), enabled)
	return config.save(base_path(path) + ".slots.cfg")
