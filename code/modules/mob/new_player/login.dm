/mob/new_player/Login()
	if(!mind)
		mind = new /datum/mind(key, ckey)
		mind.active = 1
		mind.current = src
		mind_initialize()

	if(length(GLOB.newplayer_start))
		forceMove(get_turf(pick(GLOB.newplayer_start)))
	else
		forceMove(locate(1,1,1))
	lastarea = get_area(src.loc)

	sight |= SEE_TURFS

	. = ..()

	new_player_panel()
	addtimer(CALLBACK(src, PROC_REF(lobby)), 4 SECONDS)

/mob/new_player/proc/lobby()
	if(!client)
		return

	client.playtitlemusic()

	// To show them the full lobby art. This fixes itself on a mind transfer so no worries there.
	client.view_size.add(15)
	// Credit the lobby art author
	if(GLOB.displayed_lobby_art != -1)
		var/list/lobby_authors = CONFIG_GET(str_list/lobby_art_authors)
		var/author = lobby_authors[GLOB.displayed_lobby_art]
		if(author != "Unknown")
			to_chat(src, SPAN_ROUNDBODY("<hr>This round's lobby art is brought to you by [author]<hr>"))
	if(GLOB.current_tms)
		to_chat(src, SPAN_BOLDANNOUNCE(GLOB.current_tms))
	if(GLOB.join_motd)
		to_chat(src, "<div class=\"motd\">[GLOB.join_motd]</div>")
