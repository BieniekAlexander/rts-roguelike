class_name AU

static func comp_value(a, b) -> bool:
	return (a["value"]<b["value"])

static func sort_on_key(arr, k: Callable) -> Array:
	var arr_keyed = arr.map(func(a): return {"item": a, "value": k.call(a)})
	arr_keyed.sort_custom(comp_value)
	return arr_keyed.map(func(a): return a["item"])
