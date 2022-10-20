
/datum/admins
	var/datum/marked_datum

/proc/input_bitfield(mob/User, title, bitfield, current_value, nwidth = 350, nheight = 350, nslidecolor, allowed_edit_list = null)
	if(!User || !(bitfield in GLOB.bitfields))
		return
	var/list/pickerlist = list()
	for(var/i in GLOB.bitfields[bitfield])
		var/can_edit = 1
		if(!isnull(allowed_edit_list) && !(allowed_edit_list & GLOB.bitfields[bitfield][i]))
			can_edit = 0
		if(current_value & GLOB.bitfields[bitfield][i])
			pickerlist += list(list("checked" = 1, "value" = GLOB.bitfields[bitfield][i], "name" = i, "allowed_edit" = can_edit))
		else
			pickerlist += list(list("checked" = 0, "value" = GLOB.bitfields[bitfield][i], "name" = i, "allowed_edit" = can_edit))
	var/list/result = presentpicker(User, "", title, Button1="Save", Button2 = "Cancel", Timeout=FALSE, values = pickerlist, width = nwidth, height = nheight, slidecolor = nslidecolor)
	if(islist(result))
		if(result["button"] == 2) // If the user pressed the cancel button
			return
		. = 0
		for(var/flag in result["values"])
			. |= GLOB.bitfields[bitfield][flag]
	else
		return

/proc/pick_closest_path(value, list/matches = get_fancy_list_of_atom_types())
	if(value == FALSE) //nothing should be calling us with a number, so this is safe
		value = input("Enter type to find (blank for all, cancel to cancel)", "Search for type") as null|text
		if(isnull(value))
			return
	value = trim(value)
	if(!isnull(value) && value != "")
		matches = filter_fancy_list(matches, value)

	if(!length(matches))
		return

	var/chosen
	if(length(matches) == 1)
		chosen = matches[1]
	else
		chosen = tgui_input_list(usr, "Select a type", "Pick Type", matches)
		if(!chosen)
			return
	chosen = matches[chosen]
	return chosen

/proc/get_fancy_list_of_datum_types()
	var/static/list/pre_generated_list
	if(!pre_generated_list) //init
		pre_generated_list = make_types_fancy(sortList(typesof(/datum) - typesof(/atom)))
	return pre_generated_list

/proc/make_types_fancy(list/types)
	if(ispath(types))
		types = list(types)
	. = list()
	for(var/type in types)
		var/typename = "[type]"
		var/static/list/TYPES_SHORTCUTS = list(
			/obj/effect/decal/cleanable = "CLEANABLE",
			/obj/item/device/radio/headset = "HEADSET",
			/obj/item/reagent_container/food/drinks = "DRINK", //longest paths comes first
			/obj/item/reagent_container/food = "FOOD",
			/obj/item/reagent_container = "REAGENT_CONTAINERS",
			/obj/item/organ = "ORGAN",
			/obj/item = "ITEM",
			/obj/structure/machinery = "MACHINERY",
			/obj/effect = "EFFECT",
			/obj = "O",
			/datum = "D",
			/turf/open = "OPEN",
			/turf/closed = "CLOSED",
			/turf = "T",
			/mob/living/carbon/human = "HUMAN",
			/mob/living/carbon = "CARBON",
			/mob/living/simple_animal = "SIMPLE",
			/mob/living = "LIVING",
			/mob = "M"
		)
		for (var/tn in TYPES_SHORTCUTS)
			if(copytext(typename, 1, length("[tn]/") + 1) == "[tn]/" /*findtextEx(typename,"[tn]/",1,2)*/ )
				typename = TYPES_SHORTCUTS[tn] + copytext(typename, length("[tn]/"))
				break
		.[typename] = type


/proc/get_all_of_type(T, subtypes = TRUE)
	var/list/typecache = list()
	typecache[T] = 1
	if(subtypes)
		typecache = typecacheof(typecache)
	. = list()
	if(ispath(T, /mob))
		for(var/mob/thing in GLOB.mob_list)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /obj/structure/machinery/door))
		for(var/obj/structure/machinery/door/thing in global.machines)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /obj/structure/machinery))
		for(var/obj/structure/machinery/thing in global.machines)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /obj))
		for(var/obj/thing in world)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /atom/movable))
		for(var/atom/movable/thing in world)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /turf))
		for(var/turf/thing in world)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /atom))
		for(var/atom/thing in world)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /client))
		for(var/client/thing in GLOB.clients)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else if(ispath(T, /datum))
		for(var/datum/thing)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

	else
		for(var/datum/thing in world)
			if(typecache[thing.type])
				. += thing
			CHECK_TICK

/proc/presentpicker(mob/User,Message, Title, Button1="Ok", Button2, Button3, StealFocus = 1,Timeout = 6000,list/values, inputtype = "checkbox", width, height, slidecolor)
	if(!istype(User))
		if(istype(User, /client/))
			var/client/C = User
			User = C.mob
		else
			return
	var/datum/browser/modal/listpicker/A = new(User, Message, Title, Button1, Button2, Button3, StealFocus,Timeout, values, inputtype, width, height, slidecolor)
	A.open()
	A.wait()
	if(A.selectedbutton)
		return list("button" = A.selectedbutton, "values" = A.valueslist)

/proc/get_fancy_list_of_atom_types()
	var/static/list/pre_generated_list
	if(!pre_generated_list) //init
		pre_generated_list = make_types_fancy(typesof(/atom))
	return pre_generated_list

/proc/filter_fancy_list(list/L, filter as text)
	var/list/matches = new
	for(var/key in L)
		var/value = L[key]
		if(findtext("[key]", filter) || findtext("[value]", filter))
			matches[key] = value
	return matches

/datum/browser/modal
	var/opentime = 0
	var/timeout
	var/selectedbutton = 0
	var/stealfocus


/datum/browser/modal/New(nuser, nwindow_id, ntitle = 0, nwidth = 0, nheight = 0, atom/nref = null, StealFocus = TRUE, Timeout = 6000)
	. = ..()
	stealfocus = StealFocus
	if(!StealFocus)
		window_options += "focus=false;"
	timeout = Timeout


/datum/browser/modal/close()
	. = ..()
	opentime = 0


/datum/browser/modal/open()
	set waitfor = FALSE
	opentime = world.time

	if(stealfocus)
		. = ..(use_onclose = 1)
	else
		var/focusedwindow = winget(user, null, "focus")
		. = ..(use_onclose = 1)

		//waits for the window to show up client side before attempting to un-focus it
		//winexists sleeps until it gets a reply from the client, so we don't need to bother sleeping
		for(var/i in 1 to 10)
			if(user && winexists(user, window_id))
				if(focusedwindow)
					winset(user, focusedwindow, "focus=true")
				else
					winset(user, "mapwindow", "focus=true")
				break
	if(timeout)
		addtimer(CALLBACK(src, .proc/close), timeout)


/datum/browser/modal/proc/wait()
	while (opentime && selectedbutton <= 0 && (!timeout || opentime+timeout > world.time))
		stoplag(1)


/datum/browser/modal/listpicker
	var/valueslist = list()


/datum/browser/modal/listpicker/New(User,Message,Title,Button1="Ok",Button2,Button3,StealFocus = 1, Timeout = FALSE,list/values,inputtype="checkbox", width, height, slidecolor)
	if(!User)
		return

	var/output =  {"<form><input type="hidden" name="src" value="[REF(src)]"><ul class="sparse">"}
	if(inputtype == "checkbox" || inputtype == "radio")
		for(var/i in values)
			var/div_slider = slidecolor
			if(!i["allowed_edit"])
				div_slider = "locked"
			output += {"<li>
						<label class="switch">
							<input type="[inputtype]" value="1" name="[i["name"]]"[i["checked"] ? " checked" : ""][i["allowed_edit"] ? "" : " onclick='return false' onkeydown='return false'"]>
								<div class="slider [div_slider ? "[div_slider]" : ""]"></div>
									<span>[i["name"]]</span>
						</label>
						</li>"}
	else
		for(var/i in values)
			output += {"<li><input id="name="[i["name"]]"" style="width: 50px" type="[type]" name="[i["name"]]" value="[i["value"]]">
			<label for="[i["name"]]">[i["name"]]</label></li>"}
	output += {"</ul><div style="text-align:center">
		<button type="submit" name="button" value="1" style="font-size:large;float:[( Button2 ? "left" : "right" )]">[Button1]</button>"}

	if(Button2)
		output += {"<button type="submit" name="button" value="2" style="font-size:large;[( Button3 ? "" : "float:right" )]">[Button2]</button>"}

	if(Button3)
		output += {"<button type="submit" name="button" value="3" style="font-size:large;float:right">[Button3]</button>"}

	output += {"</form></div>"}
	..(User, ckey("[User]-[Message]-[Title]-[world.time]-[rand(1,10000)]"), Title, width, height, src, StealFocus, Timeout)
	set_content(output)


/datum/browser/modal/listpicker/Topic(href,href_list)
	if(href_list["close"] || !user || !user.client)
		opentime = 0
		return
	if(href_list["button"])
		var/button = text2num(href_list["button"])
		if(button <= 3 && button >= 1)
			selectedbutton = button
	for(var/item in href_list)
		switch(item)
			if("close", "button", "src")
				continue
			else
				valueslist[item] = href_list[item]
	opentime = 0
	close()
