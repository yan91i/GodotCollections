class_name Coven
extends Resource
## Analagous to a Faction in creation kit games, where a Coven is a group of Entities that behave a certain way.
## Entities must have a [CovensComponent] to be a part of a coven.
## Entities are automatically added to a group with the coven's ID when they are a part of a coven, so to get all entities part of a coven, you can get all of group.
## Unlike Creation Kit, Entties are assigned to a coven on the SKEntity side- the Coven just holds information.
## To give them a default response to the player, create a "Player" coven, and give them a default reaction to that.


@export_category("Information")
## ID for this coven. Also used as a key in translations. See [member coven_name].
@export var coven_id:StringName
## The opinion this coven has of other covens. The dictionary shopuld be of StringName:int.
@export var other_coven_opinions:Dictionary
## Whether the player should see this in the menu if they are a part of the coven.
@export var hidden_from_player:bool
## The ranks of this coven. Shape is int:String, where key is the rank, and value is the translation key for the rank.
@export var ranks:Dictionary
@export_category("Crime")
## Whether members of this coven ignore crimes perpetrated to other members.
@export var ignore_crimes_against_others:bool = false
## Whether members care abourt crimes done against their own members.
@export var ignore_crimes_against_members:bool = false
## Whether this coven remembers crimes done against it.
@export var track_crime:bool = true


## Translated coven name.
var coven_name:String:
	get:
		return tr(coven_id)


## Get the translated name of a rank.
func rank_name(rank:int) -> String:
	return tr(ranks[rank]) if ranks.has(rank) else ""


## Returns a list of the opinions it has of a list of covens.
func get_coven_opinions(covens:Array) -> Array[int]:
	var opinion_list:Array[int] = []
	
	for coven in covens:
		if other_coven_opinions.has(coven):
			opinion_list.append(other_coven_opinions[coven])
		else:
			opinion_list.append(0)
	
	return opinion_list


## Get the crime opinion modifier for an entity against this coven.
## The formula is [code]max_crime_severity * -10[/code].
func get_crime_modifier(who:StringName) -> int:
	return CrimeMaster.max_crime_severity(who, coven_id) * -10


func get_debug_info() -> String:
	return """
[b]%s[/b]
	Opinions: %s
	Hidden from player: %s
	Ranks: %s
	Ignores crimes against others: %s
	Ignores crimes against members: %s
	Track Crime: %s
	""" % [
		coven_id,
		JSON.stringify(other_coven_opinions),
		hidden_from_player,
		JSON.stringify(ranks),
		ignore_crimes_against_others,
		ignore_crimes_against_members,
		track_crime
	]
