/** Creates a thinking indicator over the mob. */
/mob/proc/create_thinking_indicator()
	return

/** Removes the thinking indicator over the mob. */
/mob/proc/remove_thinking_indicator()
	return

/** Creates a typing indicator over the mob. */
/mob/proc/create_typing_indicator()
	return

/** Removes the typing indicator over the mob. */
/mob/proc/remove_typing_indicator()
	return

/** Removes any indicators and marks the mob as not speaking IC. */
/mob/proc/remove_all_indicators()
	return

/mob/Logout()
	remove_all_indicators()
	return ..()

/client/verb/typing_indicator()
	set name = "Show/Hide Typing Indicator"
	set category = "Preferences.Chat"
	set desc = "Toggles showing an indicator when you are typing emote or say message."
	prefs.toggles_chat ^= SHOW_TYPING
	prefs.save_preferences()
	to_chat(src, "You will [(prefs.toggles_chat & SHOW_TYPING) ? "no longer" : "now"] display a typing indicator.")

	if(prefs.toggles_chat & SHOW_TYPING)
		typing_indicators = FALSE
	else
		typing_indicators = TRUE

/** Sets the mob as "thinking" - with indicator and variable thinking_IC */
/datum/tgui_say/proc/start_thinking()
	if(!window_open || !client.typing_indicators)
		return FALSE
	client.mob.thinking_IC = TRUE
	client.mob.create_thinking_indicator()

/** Removes typing/thinking indicators and flags the mob as not thinking */
/datum/tgui_say/proc/stop_thinking()
	client.mob?.remove_all_indicators()

/**
 * Handles the user typing. After a brief period of inactivity,
 * signals the client mob to revert to the "thinking" icon.
 */
/datum/tgui_say/proc/start_typing()
	client.mob.remove_thinking_indicator()
	if(!window_open || !client.typing_indicators || !client.mob.thinking_IC)
		return FALSE
	client.mob.create_typing_indicator()
	addtimer(CALLBACK(src, .proc/stop_typing), 5 SECONDS, TIMER_UNIQUE | TIMER_OVERRIDE | TIMER_STOPPABLE)

/**
 * Callback to remove the typing indicator after a brief period of inactivity.
 * If the user was typing IC, the thinking indicator is shown.
 */
/datum/tgui_say/proc/stop_typing()
	if(!client?.mob)
		return FALSE
	client.mob.remove_typing_indicator()
	if(!window_open || !client.typing_indicators || !client.mob.thinking_IC)
		return FALSE
	client.mob.create_thinking_indicator()

/// Overrides for overlay creation
/mob/living/create_thinking_indicator()
	if(active_thinking_indicator || active_typing_indicator || !thinking_IC || stat != CONSCIOUS )
		return FALSE
	active_thinking_indicator = mutable_appearance('icons/mob/effects/talk.dmi', "[bubble_icon]3", TYPING_LAYER)
	overlays += active_thinking_indicator

/mob/living/remove_thinking_indicator()
	if(!active_thinking_indicator)
		return FALSE
	overlays -= active_thinking_indicator
	active_thinking_indicator = null

/mob/living/create_typing_indicator()
	if(active_typing_indicator || active_thinking_indicator || !thinking_IC || stat != CONSCIOUS)
		return FALSE
	active_typing_indicator = mutable_appearance('icons/mob/effects/talk.dmi', "[bubble_icon]0", TYPING_LAYER)
	overlays += active_typing_indicator

/mob/living/remove_typing_indicator()
	if(!active_typing_indicator)
		return FALSE
	overlays -= active_typing_indicator
	active_typing_indicator = null

/mob/living/remove_all_indicators()
	thinking_IC = FALSE
	remove_thinking_indicator()
	remove_typing_indicator()

