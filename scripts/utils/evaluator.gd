class_name Pattern

var condition: Callable
var result: Variant

static func eval(
	a_patterns: Array,
	a_evalution_input: Variant,
	a_default: Variant = null
) -> Variant:
	for pattern: Pattern in a_patterns:
		if pattern.condition.call(a_evalution_input):
			return pattern.result
	
	return a_default


func _init(a_condition: Callable, a_result: Variant) -> void:
	# A tuple which pairs a condition with a potential result, to be returned if the condition is true
	condition = a_condition
	result = a_result
