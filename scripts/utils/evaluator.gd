class_name PatternEvaluator

var _spec: Array = []
var _default: Variant = null

func _init(a_pattern_spec: Array[Array], a_default: Variant = null) -> void:
	# assert that pattern specs are of the format:
	# [
	#	[evaluator_callable, Variant]
	# ]
	assert(
		a_pattern_spec.all(func(p): return p.size()==2 and p[0] is Callable and p[1] is Variant),
		"malformed pattern spec"
	)
	
	_spec = a_pattern_spec
	_default = a_default

func eval(a_evalutor_input: Variant) -> Variant:
	for pair in _spec:
		if pair[0].call(a_evalutor_input):
			return pair[1]
	
	print("Uncovered target for this interaction %s" % a_evalutor_input)
	return _default
