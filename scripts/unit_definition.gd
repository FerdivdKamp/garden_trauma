class_name UnitDefinition
extends Resource

var id: String
var name: String
var health: float
var speed: float
var reward: int
var armor: Dictionary
var tags: PackedStringArray


func armor_for(damage_type: String) -> float:
	return float(armor.get(damage_type, 0.0))
