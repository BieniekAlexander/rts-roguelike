class_name AU

static func comp_value(a, b) -> bool:
	return (a["value"]<b["value"])

static func sort_on_key(a_key: Callable, a_array: Array) -> Array:
	var arr_keyed = a_array.map(func(a): return {"item": a, "value": a_key.call(a)})
	arr_keyed.sort_custom(comp_value)
	return arr_keyed.map(func(a): return a["item"])

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
	
