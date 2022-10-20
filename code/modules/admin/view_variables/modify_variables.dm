GLOBAL_LIST_INIT(VVlocked, list("vars", "datum_flags", "client", "mob")) //Requires DEBUG
GLOBAL_PROTECT(VVlocked)
GLOBAL_LIST_INIT(VVicon_edit_lock, list("icon", "icon_state", "overlays", "underlays")) //Requires DEBUG or ADMIN
GLOBAL_PROTECT(VVicon_edit_lock)
GLOBAL_LIST_INIT(VVckey_edit, list("key", "ckey")) //Requires DEBUG or SPAWN
GLOBAL_PROTECT(VVckey_edit)
GLOBAL_LIST_INIT(VVpixelmovement, list("bound_x", "bound_y", "step_x", "step_y", "step_size", "bound_height", "bound_width", "bounds")) //No editing ever.
GLOBAL_PROTECT(VVpixelmovement)

/client/proc/vv_parse_text(O, new_var)
	if(O && findtext(new_var,"\["))
		var/process_vars = tgui_alert(usr,"\[] detected in string, process as variables?","Process Variables?",list("Yes","No"))
		if(process_vars == "Yes")
			. = string2listofvars(new_var, O)

//do they want you to include subtypes?
//FALSE = no subtypes, strict exact type pathing (or the type doesn't have subtypes)
//TRUE = Yes subtypes
//NULL = User cancelled at the prompt or invalid type given
/client/proc/vv_subtype_prompt(type)
	if (!ispath(type))
		return null
	var/list/subtypes = subtypesof(type)
	if (!length(subtypes))
		return FALSE

	switch(alert("Strict object type detection?", "Type detection", "Strictly this type","This type and subtypes", "Cancel"))
		if("Strictly this type")
			return FALSE
		if("This type and subtypes")
			return TRUE

/client/proc/vv_reference_list(type, subtypes)
	. = list()
	var/list/types = list(type)
	if (subtypes)
		types = typesof(type)

	var/list/fancytypes = make_types_fancy(types)

	for(var/fancytype in fancytypes) //swap the assoication
		types[fancytypes[fancytype]] = fancytype

	var/things = get_all_of_type(type, subtypes)

	var/i = 0
	for(var/thing in things)
		var/datum/D = thing
		i++
		//try one of 3 methods to shorten the type text:
		//	fancy type,
		//	fancy type with the base type removed from the begaining,
		//	the type with the base type removed from the begaining
		var/fancytype = types[D.type]
		if (findtext(fancytype, types[type]))
			fancytype = copytext(fancytype, length(types[type]) + 1)
		var/shorttype = copytext("[D.type]", length("[type]") + 1)
		if (length_char(shorttype) > length_char(fancytype))
			shorttype = fancytype
		if (!length(shorttype))
			shorttype = "/"

		.["[D]([shorttype])[REF(D)]#[i]"] = D

/client/proc/mod_list_add_ass() //haha
	var/class = "text"

	var/list/possible_classes = list("text","num","type","reference","mob reference","icon","file","list")
	if(LAZYLEN(stored_matrices))
		possible_classes += "matrix"
	if(admin_holder && admin_holder.marked_datums.len)
		possible_classes += "marked datum"
	possible_classes += "edit referenced object"
	possible_classes += "restore to default"

	class = tgui_input_list(usr, "What kind of variable?","Variable Type", possible_classes)
	if(!class)
		return

	var/var_value = null

	switch(class)

		if("text")
			var_value = input("Enter new text:","Text") as null|text

		if("num")
			var_value = tgui_input_real_number(src, "Enter new number:","Num")

		if("type")
			var_value = tgui_input_list(usr, "Enter type:","Type", typesof(/obj,/mob,/area,/turf))

		if("reference")
			var_value = input("Select reference:","Reference") as null|mob|obj|turf|area in world

		if("mob reference")
			var_value = input("Select reference:","Reference") as null|mob in GLOB.mob_list

		if("file")
			var_value = input("Pick file:","File") as null|file

		if("icon")
			var_value = input("Pick icon:","Icon") as null|icon

		if("matrix")
			var/matrix_name = tgui_input_list(usr, "Choose a matrix", "Matrix", (stored_matrices + "Cancel"))
			if(!matrix_name || matrix_name == "Cancel")
				return

			var/matrix/M = LAZYACCESS(stored_matrices, matrix_name)
			if(!M)
				return

			var_value = M

		if("marked datum")
			var/datum/D = input_marked_datum(admin_holder.marked_datums)
			var_value = D

	if(!var_value) return

	return var_value


/client/proc/mod_list_add(var/list/L)

	var/class = "text"

	var/list/possible_classes = list("text","num","type","reference","mob reference","icon","file","list")
	if(LAZYLEN(stored_matrices))
		possible_classes += "matrix"
	if(admin_holder && admin_holder.marked_datums.len)
		possible_classes += "marked datum"
	possible_classes += "edit referenced object"
	possible_classes += "restore to default"

	class = tgui_input_list(usr, "What kind of variable?","Variable Type", possible_classes)
	if(!class)
		return

	if(!class)
		return

	var/var_value = null

	switch(class)

		if("text")
			var_value = input("Enter new text:","Text") as text

		if("num")
			var_value = tgui_input_real_number(usr, "Enter new number:","Num")

		if("type")
			var_value = tgui_input_list(usr, "Enter type:","Type", typesof(/obj,/mob,/area,/turf))

		if("reference")
			var_value = input("Select reference:","Reference") as mob|obj|turf|area in world

		if("mob reference")
			var_value = input("Select reference:","Reference") as mob in GLOB.mob_list

		if("file")
			var_value = input("Pick file:","File") as file

		if("icon")
			var_value = input("Pick icon:","Icon") as icon

		if("matrix")
			var/matrix_name = tgui_input_list(usr, "Choose a matrix", "Matrix", (stored_matrices + "Cancel"))
			if(!matrix_name || matrix_name == "Cancel")
				return

			var/matrix/M = LAZYACCESS(stored_matrices, matrix_name)
			if(!M)
				return

			var_value = M

		if("marked datum")
			var/datum/D = input_marked_datum(admin_holder.marked_datums)
			var_value = D

	if(!var_value) return

	switch(alert("Would you like to associate a var with the list entry?",,"Yes","No"))
		if("Yes")
			L += var_value
			L[var_value] = mod_list_add_ass() //haha
		if("No")
			L += var_value

	message_staff("[key_name_admin(src)] added a new element to a list with a key of '[var_value]' and an associated value of [isnum(var_value)? "null" : L[var_value]]", 1)

/client/proc/mod_list(list/L, atom/O, original_name, objectvar, index, autodetect_class = FALSE)
	if(!check_rights(R_VAREDIT))
		return
	if(!istype(L, /list))
		to_chat(src, "Not a List.", confidential = TRUE)
		return

	if(L.len > 1000)
		var/confirm = tgui_alert(usr, "The list you're trying to edit is very long, continuing may crash the server.", "Warning", list("Continue", "Abort"))
		if(confirm != "Continue")
			return

	var/is_normal_list = IS_NORMAL_LIST(L)
	var/list/names = list()
	for (var/i in 1 to L.len)
		var/key = L[i]
		var/value
		if (is_normal_list && !isnum(key))
			value = L[key]
		if (value == null)
			value = "null"
		names["#[i] [key] = [value]"] = i
	if (!index)
		var/variable = input("Which var?","Var") as null|anything in names + "(ADD VAR)" + "(CLEAR NULLS)" + "(CLEAR DUPES)" + "(SHUFFLE)"

		if(variable == null)
			return

		if(variable == "(ADD VAR)")
			mod_list_add(L, O, original_name, objectvar)
			return

		if(variable == "(CLEAR NULLS)")
			L = L.Copy()
			list_clear_nulls(L)
			if (!O.vv_edit_var(objectvar, L))
				to_chat(src, "Your edit was rejected by the object.", confidential = TRUE)
				return
			log_world("### ListVarEdit by [src]: [O.type] [objectvar]: CLEAR NULLS")
			log_admin("[key_name(src)] modified [original_name]'s [objectvar]: CLEAR NULLS")
			message_admins("[key_name_admin(src)] modified [original_name]'s list [objectvar]: CLEAR NULLS")
			return

		if(variable == "(CLEAR DUPES)")
			L = uniquelist(L)
			if (!O.vv_edit_var(objectvar, L))
				to_chat(src, "Your edit was rejected by the object.", confidential = TRUE)
				return
			log_world("### ListVarEdit by [src]: [O.type] [objectvar]: CLEAR DUPES")
			log_admin("[key_name(src)] modified [original_name]'s [objectvar]: CLEAR DUPES")
			message_admins("[key_name_admin(src)] modified [original_name]'s list [objectvar]: CLEAR DUPES")
			return

		if(variable == "(SHUFFLE)")
			L = shuffle(L)
			if (!O.vv_edit_var(objectvar, L))
				to_chat(src, "Your edit was rejected by the object.", confidential = TRUE)
				return
			log_world("### ListVarEdit by [src]: [O.type] [objectvar]: SHUFFLE")
			log_admin("[key_name(src)] modified [original_name]'s [objectvar]: SHUFFLE")
			message_admins("[key_name_admin(src)] modified [original_name]'s list [objectvar]: SHUFFLE")
			return

		index = names[variable]


	var/assoc_key
	if (index == null)
		return
	var/assoc = 0
	var/prompt = tgui_alert(usr, "Do you want to edit the key or its assigned value?", "Associated List", list("Key", "Assigned Value", "Cancel"))
	if (prompt == "Cancel")
		return
	if (prompt == "Assigned Value")
		assoc = 1
		assoc_key = L[index]
	var/default
	var/variable
	var/old_assoc_value //EXPERIMENTAL - Keep old associated value while modifying key, if any
	if(is_normal_list)
		if (assoc)
			variable = L[assoc_key]
		else
			variable = L[index]
			//EXPERIMENTAL - Keep old associated value while modifying key, if any
			if(IS_VALID_ASSOC_KEY(variable))
				var/found = L[variable]
				if(!isnull(found))
					old_assoc_value = found
			//

	default = vv_get_class(objectvar, variable)

	to_chat(src, "Variable appears to be <b>[uppertext(default)]</b>.", confidential = TRUE)

	to_chat(src, "Variable contains: [variable]", confidential = TRUE)

	if(default == VV_NUM)
		var/dir_text = ""
		var/tdir = variable
		if(tdir > 0 && tdir < 16)
			if(tdir & 1)
				dir_text += "NORTH"
			if(tdir & 2)
				dir_text += "SOUTH"
			if(tdir & 4)
				dir_text += "EAST"
			if(tdir & 8)
				dir_text += "WEST"

		if(dir_text)
			to_chat(usr, "If a direction, direction is: [dir_text]", confidential = TRUE)

	var/original_var = variable

	if (O)
		L = L.Copy()
	var/class
	if(autodetect_class)
		if (default == VV_TEXT)
			default = VV_MESSAGE
		class = default
	var/list/LL = vv_get_value(default_class = default, current_value = original_var, restricted_classes = list(VV_RESTORE_DEFAULT), extra_classes = list(VV_LIST, "DELETE FROM LIST"))
	class = LL["class"]
	if (!class)
		return
	var/new_var = LL["value"]

	if(class == VV_MESSAGE)
		class = VV_TEXT

	switch(class) //Spits a runtime error if you try to modify an entry in the contents list. Dunno how to fix it, yet.
		if(VV_LIST)
			mod_list(variable, O, original_name, objectvar)

		if("DELETE FROM LIST")
			L.Cut(index, index+1)
			if (O)
				if (O.vv_edit_var(objectvar, L))
					to_chat(src, "Your edit was rejected by the object.", confidential = TRUE)
					return
			log_world("### ListVarEdit by [src]: [O.type] [objectvar]: REMOVED=[html_encode("[original_var]")]")
			log_admin("[key_name(src)] modified [original_name]'s [objectvar]: REMOVED=[original_var]")
			message_admins("[key_name_admin(src)] modified [original_name]'s [objectvar]: REMOVED=[original_var]")
			return

		if(VV_TEXT)
			var/list/varsvars = vv_parse_text(O, new_var)
			for(var/V in varsvars)
				new_var = replacetext(new_var,"\[[V]]","[O.vars[V]]")


	if(is_normal_list)
		if(assoc)
			L[assoc_key] = new_var
		else
			L[index] = new_var
			if(!isnull(old_assoc_value) && IS_VALID_ASSOC_KEY(new_var))
				L[new_var] = old_assoc_value
	if (O)
		if (O.vv_edit_var(objectvar, L) == FALSE)
			to_chat(src, "Your edit was rejected by the object.", confidential = TRUE)
			return
	log_world("### ListVarEdit by [src]: [(O ? O.type : "/list")] [objectvar]: [original_var]=[new_var]")
	log_admin("[key_name(src)] modified [original_name]'s [objectvar]: [original_var]=[new_var]")
	message_staff("[key_name_admin(src)] modified [original_name]'s varlist [objectvar]: [original_var]=[new_var]")


/client/proc/modify_variables(var/atom/O, var/param_var_name = null, var/autodetect_class = 0)
	if(!check_rights(R_VAREDIT))	return

	var/list/locked = list("vars", "key", "ckey", "client", "icon")

	if(O.is_datum_protected())
		to_chat(usr, SPAN_WARNING("This datum is protected. Access Denied"))
		return

	if(!O.can_vv_modify() && !(admin_holder.rights & R_DEBUG))
		to_chat(usr, "You can't modify this object! You require debugging permission")
		return

	for(var/p in forbidden_varedit_object_types)
		if( istype(O,p) )
			to_chat(usr, SPAN_DANGER("It is forbidden to edit this object's variables."))
			return

	var/class
	var/variable
	var/var_value

	if(param_var_name)
		if(!(param_var_name in O.vars))
			to_chat(src, "A variable with this name ([param_var_name]) doesn't exist in this atom ([O])")
			return

		if(param_var_name == "admin_holder" || (param_var_name in locked))
			if(!check_rights(R_DEBUG))	return

		variable = param_var_name

		var_value = O.vars[variable]

		if(autodetect_class)
			if(isnull(var_value))
				to_chat(usr, "Unable to determine variable type.")
				class = null
				autodetect_class = null
			else if(isnum(var_value))
				to_chat(usr, "Variable appears to be <b>NUM</b>.")
				class = "num"
				dir = 1

			else if(istext(var_value))
				to_chat(usr, "Variable appears to be <b>TEXT</b>.")
				class = "text"

			else if(isloc(var_value))
				to_chat(usr, "Variable appears to be <b>REFERENCE</b>.")
				class = "reference"

			else if(isicon(var_value))
				to_chat(usr, "Variable appears to be <b>ICON</b>.")
				var_value = "\icon[var_value]"
				class = "icon"

			else if(istype(var_value,/matrix))
				to_chat(usr, "Variable appears to be <b>MATRIX</b>.")
				class = "matrix"

			else if(istype(var_value,/atom) || istype(var_value,/datum))
				to_chat(usr, "Variable appears to be <b>TYPE</b>.")
				class = "type"

			else if(istype(var_value,/list))
				to_chat(usr, "Variable appears to be <b>LIST</b>.")
				class = "list"

			else if(istype(var_value,/client))
				to_chat(usr, "Variable appears to be <b>CLIENT</b>.")
				class = "cancel"
			else
				to_chat(usr, "Variable appears to be <b>FILE</b>.")
				class = "file"

	else

		var/list/names = list()
		for (var/V in O.vars)
			names += V

		names = sortList(names)

		variable = tgui_input_list(usr, "Which var?","Var", names)
		if(!variable)	return
		var_value = O.vars[variable]

		if(variable == "admin_holder" || (variable in locked))
			if(!check_rights(R_DEBUG))	return

	if(!autodetect_class)

		var/dir
		if(isnull(var_value))
			to_chat(usr, "Unable to determine variable type.")

		else if(isnum(var_value))
			to_chat(usr, "Variable appears to be <b>NUM</b>.")

			dir = 1

		else if(istext(var_value))
			to_chat(usr, "Variable appears to be <b>TEXT</b>.")


		else if(isloc(var_value))
			to_chat(usr, "Variable appears to be <b>REFERENCE</b>.")


		else if(isicon(var_value))
			to_chat(usr, "Variable appears to be <b>ICON</b>.")
			var_value = "\icon[var_value]"


		else if(istype(var_value,/matrix))
			to_chat(usr, "Variable appears to be <b>MATRIX</b>.")
			class = "matrix"

		else if(istype(var_value,/atom) || istype(var_value,/datum))
			to_chat(usr, "Variable appears to be <b>TYPE</b>.")


		else if(istype(var_value,/list))
			to_chat(usr, "Variable appears to be <b>LIST</b>.")


		else if(istype(var_value,/client))
			to_chat(usr, "Variable appears to be <b>CLIENT</b>.")


		else
			to_chat(usr, "Variable appears to be <b>FILE</b>.")


		to_chat(usr, "Variable contains: [var_value]")
		if(dir)
			switch(var_value)
				if(1)
					dir = "NORTH"
				if(2)
					dir = "SOUTH"
				if(4)
					dir = "EAST"
				if(8)
					dir = "WEST"
				if(5)
					dir = "NORTHEAST"
				if(6)
					dir = "SOUTHEAST"
				if(9)
					dir = "NORTHWEST"
				if(10)
					dir = "SOUTHWEST"
				else
					dir = null
			if(dir)
				to_chat(usr, "If a direction, direction is: [dir]")


		var/list/possible_classes = list("text","num","type","reference","mob reference","icon","file","list")
		if(LAZYLEN(stored_matrices))
			possible_classes += "matrix"
		if(admin_holder && admin_holder.marked_datums.len)
			possible_classes += "marked datum"
		possible_classes += "edit referenced object"
		possible_classes += "restore to default"

		class = tgui_input_list(usr, "What kind of variable?","Variable Type", possible_classes)
		if(!class)
			return

	var/original_name

	if (!istype(O, /atom))
		original_name = "\ref[O] ([O])"
	else
		original_name = O:name

	switch(class)

		if("list")
			mod_list(O.vars[variable])
			return

		if("restore to default")
			O.vars[variable] = initial(O.vars[variable])

		if("edit referenced object")
			return .(O.vars[variable])

		if("text")
			var/var_new = input("Enter new text:","Text",O.vars[variable]) as null|text
			if(var_new==null) return
			O.vars[variable] = var_new

		if("num")
			if(variable=="luminosity")
				var/var_new = tgui_input_real_number(src, "Enter new number:","Num", O.vars[variable])
				if(var_new == null) return
				O.SetLuminosity(var_new)
			else if(variable=="stat")
				var/var_new = tgui_input_real_number(src, "Enter new number:","Num", O.vars[variable])
				if(var_new == null) return
				if((O.vars[variable] == 2) && (var_new < 2))//Bringing the dead back to life
					GLOB.dead_mob_list -= O
					GLOB.alive_mob_list += O
				if((O.vars[variable] < 2) && (var_new == 2))//Kill he
					GLOB.alive_mob_list -= O
					GLOB.dead_mob_list += O
				O.vars[variable] = var_new
			else
				var/var_new =  tgui_input_real_number(src, "Enter new number:","Num", O.vars[variable])
				if(var_new==null) return
				O.vars[variable] = var_new

		if("type")
			var/var_new = tgui_input_list(usr, "Enter type:","Type", typesof(/obj,/mob,/area,/turf))
			if(var_new==null) return
			O.vars[variable] = var_new

		if("reference")
			var/var_new = input("Select reference:","Reference",O.vars[variable]) as null|mob|obj|turf|area in world
			if(var_new==null) return
			O.vars[variable] = var_new

		if("mob reference")
			var/var_new = input("Select reference:","Reference",O.vars[variable]) as null|mob in GLOB.mob_list
			if(var_new==null) return
			O.vars[variable] = var_new

		if("file")
			var/var_new = input("Pick file:","File",O.vars[variable]) as null|file
			if(var_new==null) return
			O.vars[variable] = var_new

		if("icon")
			var/var_new = input("Pick icon:","Icon",O.vars[variable]) as null|icon
			if(var_new==null) return
			O.vars[variable] = var_new

		if("matrix")
			var/matrix_name = tgui_input_list(usr, "Choose a matrix", "Matrix", (stored_matrices + "Cancel"))
			if(!matrix_name || matrix_name == "Cancel")
				return

			var/matrix/M = LAZYACCESS(stored_matrices, matrix_name)
			if(!M)
				return

			O.vars[variable] = M

			world.log << "### VarEdit by [key_name(src)]: [O.type] '[variable]': [var_value] => matrix \"[matrix_name]\" with columns ([M.a], [M.b], [M.c]), ([M.d], [M.e], [M.f])"
			message_staff("[key_name_admin(src)] modified [original_name]'s '[variable]': [var_value] => matrix \"[matrix_name]\" with columns ([M.a], [M.b], [M.c]), ([M.d], [M.e], [M.f])", 1)

		if("marked datum")
			var/datum/D = input_marked_datum(admin_holder.marked_datums)
			O.vars[variable] = D

	if(class != "matrix")
		world.log << "### VarEdit by [key_name(src)]: [O.type] '[variable]': [var_value] => [html_encode("[O.vars[variable]]")]"
		message_staff("[key_name_admin(src)] modified [original_name]'s '[variable]': [var_value] => [O.vars[variable]]", 1)
