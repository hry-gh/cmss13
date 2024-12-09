/datum/asset/simple/icon_states/lobby
	icon = 'icons/lobby/icon.dmi'
	prefix = FALSE

/datum/asset/simple/lobby_art/register()
	var/icon = SSlobby_art.selected_file_name

	if(!icon)
		return

	var/asset = icon("config/lobby_art/[icon].png")
	if (!asset)
		return

	asset = fcopy_rsc(asset) //dedupe
	var/asset_name = sanitize_filename("[icon].png")

	SSassets.transport.register_asset(asset_name, asset)
	assets[asset_name] = asset

/datum/asset/simple/lobby_sound
	assets = list(
		"load" = file('sound/lobby/lobby_load.mp3'),
		"interact" = file('sound/lobby/lobby_interact.mp3')
	)
