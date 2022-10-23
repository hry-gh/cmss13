/datum/entity/discord_link
	var/ckey

	var/playerid
	var/datum/entity/player/player

	var/one_time_password
	var/discordid
	var/timestamp

/datum/entity_meta/discord_link
	entity_type = /datum/entity/discord_link
	table_name = "discord_link"
	key_field = "ckey"
	field_types = list("ckey" = DB_FIELDTYPE_STRING_MEDIUM,
		"one_time_password" = DB_FIELDTYPE_STRING_LARGE,
		"discordid" = DB_FIELDTYPE_BIGINT,
		"timestamp" = DB_FIELDTYPE_DATE,
		"playerid"=DB_FIELDTYPE_BIGINT)

/datum/entity_link/discord_link_to_player
	parent_entity = /datum/entity/player
	child_entity = /datum/entity/discord_link
	child_field = "playerid"

	parent_name = "player"
	child_name = "linked_discord"

/datum/entity_meta/discord_link/on_read(var/datum/entity/discord_link/link)
	if(link.playerid)
		link.player = DB_ENTITY(/datum/entity/player, link.playerid)

/datum/entity/discord_link/proc/generate_one_time_password()
	one_time_password = trim("[pick(operation_prefixes)]-[pick(operation_prefixes)]-[pick(operation_prefixes)]-[pick(operation_prefixes)]-[pick(operation_prefixes)]-[pick(operation_prefixes)]", 100)
	return(one_time_password)
