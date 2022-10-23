/client/verb/get_one_time_password()
	set name = "Get One Time Password"
	set category = "OOC"

	var/datum/entity/player/P = player_data
	if(P.linked_discord)
		to_chat(src, SPAN_BOLD("DISCORD: You are already linked - delink your record first."))
		return

	var/datum/entity/discord_link/new_link
	new_link = new /datum/entity/discord_link
	new_link.ckey = src.key
	new_link.player = P

	new_link.generate_one_time_password()
	new_link.save()
	P.linked_discord = new_link
	var/one_time_password = P.linked_discord.one_time_password
	to_chat(src, SPAN_BOLD("DISCORD: Your One Time Password is [one_time_password], use the command \"[CONFIG_GET(string/discord_prefix)] link [one_time_password]\" to complete verification."))

/datum/tgs_chat_command/link
	name = "link"
	help_text = "Use this command with the One Time Password retrived from CM-SS13 and your CKEY to link your accounts."

/datum/tgs_chat_command/link/Run(datum/tgs_chat_user/sender, params)
	var/list/all_params = splittext(params, " ")

	var/one_time_password = all_params[1]
	var/datum/entity/player/player = get_player_from_one_time_password(one_time_password)
	if(player)
		player.linked_discord.discordid = sender.id
		player.linked_discord.timestamp = "[time2text(world.realtime, "YYYY-MM-DD hh:mm:ss")]"
		player.linked_discord.save()
		return "You've been linked to CKEY: [player.ckey]. You can now get the Verified role!"

/proc/get_player_from_one_time_password(token)
	var/datum/entity/discord_link/link = DB_EKEY(/datum/entity/discord_link, token)
	return link.player
