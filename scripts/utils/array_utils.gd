class_name AU

## Higher Order Functions
static func comp_value(a, b) -> bool:
	return (a["value"]<b["value"])

static func sort_on_key(a_key: Callable, a_array: Array) -> Array:
	var arr_keyed = a_array.map(func(a): return {"item": a, "value": a_key.call(a)})
	arr_keyed.sort_custom(comp_value)
	return arr_keyed.map(func(a): return a["item"])

## Data Structures
static func priority_queue_push(a_key: Callable, a_item: Variant, a_queue: Array) -> int:
	## push into an array as a priority queue, returning the index at which it was inserted
	# O(n) implementation because I'm lazy
	var item_key: Variant = a_key.call(a_item)
	
	for i in range(0, a_queue.size()):
		if item_key < a_key.call(a_queue[i]):
			a_queue.insert(i, a_item)
			return i
	
	a_queue.append(a_item)
	return a_queue.size()-1
	
static func concat(a1: Array, a2: Array) -> Array:
	var ret: Array = a1.duplicate()
	
	for item in a2:
		ret.append(item)
	
	return ret

## Statistics
static func sum(a_array: Array) -> float:
	var ret: float = 0
	
	for a in a_array:
		ret += a
		
	return ret

static func median(a_array: Array) -> float:
	# TODO write a faster implementation of this
	var array_sorted: Array = a_array.duplicate()
	array_sorted.sort()
	
	if array_sorted.size()%2==1:
		return array_sorted[array_sorted.size()/2]
	else:
		return (array_sorted[array_sorted.size()/2]+array_sorted[array_sorted.size()/2])/2.0

static func mean(a_array: Array) -> float:
	return AU.sum(a_array)*1.0/a_array.size()
