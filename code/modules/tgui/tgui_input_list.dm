/* Copyright 2020 bobbahbrown (https://github.com/bobbahbrown), watermelon914 (https://github.com/watermelon914)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software
 * and associated documentation files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

/**
 * Creates a TGUI input list window and returns the user's response.
 *
 * This proc should be used to create alerts that the caller will wait for a response from.
 * Arguments:
 * * user - The user to show the input box to.
 * * message - The content of the input box, shown in the body of the TGUI window.
 * * title - The title of the input box, shown on the top of the TGUI window.
 * * items - The options that can be chosen by the user, each string is assigned a button on the UI.
 * * default - If an option is already preselected on the UI. Current values, etc.
 * * timeout - The timeout of the input box, after which the menu will close and qdel itself. Set to zero for no timeout.
 */
/proc/tgui_input_list(mob/user, message, title = "Select", list/items, default, timeout = 0, theme)
	if (!user)
		user = usr
	if(!length(items))
		return
	if (!istype(user))
		if (istype(user, /client))
			var/client/client = user
			user = client.mob
		else
			return
/*	/// Client does NOT have tgui_input on: Returns regular input
	if(!user.client.prefs.read_preference(/datum/preference/toggle/tgui_input))
		return input(user, message, title, default) as null|anything in items */
	var/datum/tgui_list_input/input = new(user, message, title, items, default, timeout, theme)
	input.tgui_interact(user)
	input.wait()
	if (input)
		. = input.choice
		qdel(input)

/**
 * # tgui_list_input
 *
 * Datum used for instantiating and using a TGUI-controlled list input that prompts the user with
 * a message and shows a list of selectable options
 */
/datum/tgui_list_input
	/// The title of the TGUI window
	var/title
	/// The textual body of the TGUI window
	var/message
	/// The list of items (responses) provided on the TGUI window
	var/list/items
	/// Buttons (strings specifically) mapped to the actual value (e.g. a mob or a verb)
	var/list/items_map
	/// The button that the user has pressed, null if no selection has been made
	var/choice
	/// The default button to be selected
	var/default
	/// The time at which the tgui_list_input was created, for displaying timeout progress.
	var/start_time
	/// The lifespan of the tgui_list_input, after which the window will close and delete itself.
	var/timeout
	/// Boolean field describing if the tgui_list_input was closed by the user.
	var/closed
	/// String field for the theme to use
	var/ui_theme

/datum/tgui_list_input/New(mob/user, message, title, list/items, default, timeout, theme)
	src.title = title
	src.message = message
	src.items = list()
	src.items_map = list()
	src.default = default
	src.ui_theme = theme
	var/list/repeat_items = list()
	// Gets rid of illegal characters
	var/static/regex/whitelistedWords = regex(@{"([^\u0020-\u8000]+)"})
	for(var/i in items)
		if(!i)
			continue
		var/string_key = whitelistedWords.Replace("[i]", "")
		//avoids duplicated keys E.g: when areas have the same name
		string_key = avoid_assoc_duplicate_keys(string_key, repeat_items)
		src.items += string_key
		src.items_map[string_key] = i
	if (timeout)
		src.timeout = timeout
		start_time = world.time
		QDEL_IN(src, timeout)

/datum/tgui_list_input/Destroy(force, ...)
	SStgui.close_uis(src)
	QDEL_NULL(items)
	return ..()

/**
 * Waits for a user's response to the tgui_list_input's prompt before returning. Returns early if
 * the window was closed by the user.
 */
/datum/tgui_list_input/proc/wait()
	while (!choice && !closed)
		stoplag(1)

/datum/tgui_list_input/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ListInputModal")
		ui.open()

/datum/tgui_list_input/ui_close(mob/user)
	. = ..()
	closed = TRUE

/datum/tgui_list_input/ui_state(mob/user)
	return GLOB.always_state

/datum/tgui_list_input/ui_static_data(mob/user)
	var/list/data = list()
	data["init_value"] = default || items[1]
	data["items"] = items
//	data["large_buttons"] = user.client.prefs.read_preference(/datum/preference/toggle/tgui_input_large)
	data["message"] = message
//	data["swapped_buttons"] = user.client.prefs.read_preference(/datum/preference/toggle/tgui_input_swapped)
	data["title"] = title
	data["theme"] = ui_theme
	return data

/datum/tgui_list_input/ui_data(mob/user)
	var/list/data = list()
	if(timeout)
		data["timeout"] = clamp((timeout - (world.time - start_time) - 1 SECONDS) / (timeout - 1 SECONDS), 0, 1)
	return data

/datum/tgui_list_input/ui_act(action, list/params)
	. = ..()
	if (.)
		return
	switch(action)
		if("submit")
			if (!(params["entry"] in items))
				return
			set_choice(items_map[params["entry"]])
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE
		if("cancel")
			closed = TRUE
			SStgui.close_uis(src)
			return TRUE

/datum/tgui_list_input/proc/set_choice(choice)
	src.choice = choice
