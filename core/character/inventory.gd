# res://core/character/inventory.gd
extends Node
class_name Inventory

signal item_added(item: Equipment)
signal item_removed(item: Equipment)
signal inventory_cleared()
signal inventory_full()

var items: Array[Equipment] = []
var max_size: int = 30

func get_item_at(index: int) -> Equipment:
	if index >= 0 and index < items.size():
		return items[index]
	return null

func get_item_by_id(item_id: String) -> Equipment:
	for item in items:
		if item.item_id == item_id:
			return item
	return null

func get_all_items() -> Array[Equipment]:
	return items.duplicate()

func get_items_of_type(equip_type: int) -> Array[Equipment]:
	var filtered: Array[Equipment] = []
	for item in items:
		if item.equip_type == equip_type:
			filtered.append(item)
	return filtered

func is_full() -> bool:
	return items.size() >= max_size

func add(item: Equipment) -> void:
	if is_full():
		emit_signal("inventory_full")
		push_warning("Inventory is full. Cannot add %s." % item.item_id)
		return
	items.append(item)
	emit_signal("item_added", item)

func remove(item: Equipment) -> void:
	if item in items:
		items.erase(item)
		emit_signal("item_removed", item)

func contains(item: Equipment) -> bool:
	return item in items

func size() -> int:
	return items.size()

func capacity() -> int:
	return max_size

func clear_inventory() -> void:
	items.clear()
	emit_signal("inventory_cleared")
