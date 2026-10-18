extends RefCounted
## Presentation profiles; landmarks and gameplay remain owned by Frontier and regional projects.
const REGIONS := {
 "marsh":{"index":3,"name":"Reedwater Marsh","radius":19.0,"blend":6.0,"ground":"526f67","tree":"72968a","description":"Reed-lined pools and a maintenance lodge cut off by water."},
 "orchard":{"index":1,"name":"Oldbridge Farmlands","radius":25.0,"blend":7.0,"ground":"8a8058","tree":"91a866","description":"Blossom terraces and gardens waiting for their keepers."},
 "quarry":{"index":2,"name":"Greybank Highlands","radius":22.0,"blend":7.0,"ground":"7b8580","tree":"668782","description":"Wind-worn slate and a road the masons are rebuilding."}
}
static func by_index(index: int) -> Dictionary:
	for definition in REGIONS.values():
		if definition.index == index: return definition
	return {}
