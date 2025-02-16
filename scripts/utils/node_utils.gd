class_name NU


static func add_parent_child(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.set_owner(parent)
