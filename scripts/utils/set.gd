class_name Set
extends Resource

## STORAGE
# Provides amortized O(1) adding, removing, and presence-checking.
var hash_set: Dictionary
const DUMMY_VALUE = null
	
## UPDATING
func add_all(elements) -> Set:
	for element in elements:
		add(element)

	return self

func add(element) -> Set:
	hash_set[element] = DUMMY_VALUE
	return self

func remove(element) -> Set:
	hash_set.erase(element)
	return self

func remove_all(elements) -> Set:
	for element in elements:
		remove(element)
	
	return self

func clear()  -> Set:
	hash_set.clear()
	return self


## LIST COMPREHENSION
func filter(condition: Callable) -> Set:
	for element in hash_set.keys():
		if !condition.call(element):
			remove(element)
	
	return self
	
func map(function: Callable) -> Set:
	var new_hash_set: Dictionary = {}
	for element in hash_set.keys():
		new_hash_set[function.call(element)] = DUMMY_VALUE
	
	hash_set = new_hash_set
	return self


## MEMBERSHIP
func contains(element) -> bool:
	return hash_set.has(element)

func get_values() -> Array:
	return hash_set.keys()


## STATE
func is_empty() -> bool:
	return hash_set.is_empty()

func size() -> int:
	return hash_set.size()


## ARITHMETIC
func union(other_set: Set) -> Set:
	var ret: Set = Set.new(get_values())
	ret.add_all(other_set.get_values())
	return ret

func intersection(other_set: Set) -> Set:
	var ret: Set = Set.new()
	
	for v in get_values():
		if other_set.contains(v):
			ret.add(v)
	
	return ret

func difference(other_set: Set) -> Set:
	var ret: Set = Set.new(get_values())
	ret.remove_all(other_set.get_values())
	return ret


## NODE
func _init(values: Array = []) -> void:
	hash_set = Dictionary()
	
	if !values.is_empty():
		add_all(values)
