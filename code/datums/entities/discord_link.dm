/datum/entity/discord_link
	var/player_id
	var/discord_id

/datum/entity_meta/discord_link
	entity_type = /datum/entity/discord_link
	table_name = "discord_links"
	key_field = "discord_id"

	field_types = list(
		"player_id" = DB_FIELDTYPE_BIGINT,
		"discord_id" = DB_FIELDTYPE_STRING_MEDIUM,
	)

/datum/entity_link/player_to_discord
	parent_entity = /datum/entity/player
	child_entity = /datum/entity/discord_link
	child_field = "player_id"

	parent_name = "player"
	child_name = "discord_link_id"


