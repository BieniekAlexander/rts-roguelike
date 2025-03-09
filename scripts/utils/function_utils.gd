class_name FU

static func default_evaluate(ev0: Callable, ev1: Callable) -> Callable:
	var ret = func(c, t):
		var result: Variant = ev0.call(c, t)
		return result if result!=null else ev1.call(c, t)
		
	return ret
