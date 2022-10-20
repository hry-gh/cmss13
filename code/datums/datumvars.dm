
// reference: /client/proc/modify_variables(var/atom/O, var/param_var_name = null, var/autodetect_class = 0)

/datum/proc/is_datum_protected()
	return FALSE

/datum/proc/can_vv_get()
	return TRUE

/datum/proc/can_vv_modify()
	return TRUE

/client/can_vv_modify()
	return FALSE

/datum/proc/vv_edit_var(var_name, var_value) //called whenever a var is edited
	if(var_name == NAMEOF(src, vars))
		return FALSE
	vars[var_name] = var_value
	datum_flags |= DF_VAR_EDITED
	return TRUE

/datum/proc/vv_get_dropdown()
	. = list()
	VV_DROPDOWN_OPTION("", "---")
	VV_DROPDOWN_OPTION(VV_HK_CALLPROC, "Call Proc")
	VV_DROPDOWN_OPTION(VV_HK_MARK, "Mark Object")
	VV_DROPDOWN_OPTION(VV_HK_TAG, "Tag Datum")
	VV_DROPDOWN_OPTION(VV_HK_DELETE, "Delete")
	VV_DROPDOWN_OPTION(VV_HK_EXPOSE, "Show VV To Player")
	VV_DROPDOWN_OPTION(VV_HK_ADDCOMPONENT, "Add Component/Element")
	VV_DROPDOWN_OPTION(VV_HK_REMOVECOMPONENT, "Remove Component/Element")
	VV_DROPDOWN_OPTION(VV_HK_MASS_REMOVECOMPONENT, "Mass Remove Component/Element")

//This proc is only called if everything topic-wise is verified. The only verifications that should happen here is things like permission checks!
//href_list is a reference, modifying it in these procs WILL change the rest of the proc in topic.dm of admin/view_variables!
//This proc is for "high level" actions like admin heal/set species/etc/etc. The low level debugging things should go in admin/view_variables/topic_basic.dm incase this runtimes.
/datum/proc/vv_do_topic(list/href_list)
	if(!usr || !usr.client || !usr.client.admin_holder || !check_rights(NONE))
		return FALSE //This is VV, not to be called by anything else.
	if(SEND_SIGNAL(src, COMSIG_VV_TOPIC, usr, href_list) & COMPONENT_VV_HANDLED)
		return FALSE
	return TRUE

/datum/proc/vv_get_header()
	. = list()
	if(("name" in vars) && !isatom(src))
		. += "<b>[vars["name"]]</b><br>"

/datum/proc/vv_get_var(var_name)
	switch(var_name)
		if (NAMEOF(src, vars))
			return debug_variable(var_name, list(), 0, src)
	return debug_variable(var_name, vars[var_name], 0, src)

/datum/proc/get_vv_options()
	return list()

/atom/get_vv_options()
	. = ..()
	. += "<option value='?_src_=vars;enablepixelscaling=\ref[src]'>Enable Pixel Scaling</option>"

/turf/get_vv_options()
	. = ..()
	. += "<option value='?_src_=vars;explode=\ref[src]'>Trigger explosion</option>"
	. += "<option value='?_src_=vars;emp=\ref[src]'>Trigger EM pulse</option>"
	. += "<option value='?_src_=vars;setmatrix=\ref[src]'>Set Base Matrix</option>"

/mob/get_vv_options()
	. = ..()
	. += "<option value='?_src_=vars;explode=\ref[src]'>Trigger explosion</option>"
	. += "<option value='?_src_=vars;emp=\ref[src]'>Trigger EM pulse</option>"
	. += "<option value='?_src_=vars;setmatrix=\ref[src]'>Set Base Matrix</option>"

/obj/get_vv_options()
	. = ..()
	. += "<option value='?_src_=vars;explode=\ref[src]'>Trigger explosion</option>"
	. += "<option value='?_src_=vars;emp=\ref[src]'>Trigger EM pulse</option>"
	. += "<option value='?_src_=vars;setmatrix=\ref[src]'>Set Base Matrix</option>"
	. += "<option value>-----OBJECT-----</option>"
	. += "<option value='?_src_=vars;delall=\ref[src]'>Delete all of type</option>"

/client/proc/is_safe_variable(name)
	if(name == "step_x" || name == "step_y" || name == "bound_x" || name == "bound_y" || name == "bound_height" || name == "bound_width" || name == "bounds")
		return FALSE
	return TRUE

/client/proc/debug_variable(name, value, level, var/datum/DA = null)
	var/html = ""
	var/change = 0
	//to make the value bold if changed
	if(!(admin_holder.rights & R_DEBUG) && !is_safe_variable(name))
		return html
	if(DA)
		html += "<li style='backgroundColor:white'><a href='?_src_=vars;datumedit=\ref[DA];varnameedit=[name]'>E</a><a href='?_src_=vars;datumchange=\ref[DA];varnamechange=[name]'>C</a><a href='?_src_=vars;datummass=\ref[DA];varnamemass=[name]'>M</a> "
		if(value != initial(DA.vars[name]))
			html += "<font color='#B300B3'>"
			change = 1
	else
		html += "<li>"

	if (isnull(value))
		html += "[name] = <span class='value'>null</span>"

	else if (istext(value))
		html += "[name] = <span class='value'>\"[value]\"</span>"

	else if (isicon(value))
		#ifdef VARSICON
		var/icon/I = new/icon(value)
		var/rnd = rand(1,10000)
		var/rname = "tmp\ref[I][rnd].png"
		usr << browse_rsc(I, rname)
		html += "[name] = (<span class='value'>[value]</span>) <img class=icon src=\"[rname]\">"
		#else
		html += "[name] = /icon (<span class='value'>[value]</span>)"
		#endif

	else if (isfile(value))
		html += "[name] = <span class='value'>'[value]'</span>"

	else if (istype(value, /datum))
		var/datum/D = value
		html += "<a href='?_src_=vars;Vars=\ref[value]'>[name] \ref[value]</a> = [D.type]"

	else if (istype(value, /client))
		var/client/C = value
		html += "<a href='?_src_=vars;Vars=\ref[value]'>[name] \ref[value]</a> = [C] [C.type]"
//
	else if (istype(value, /list))
		var/list/L = value
		html += "[name] = /list ([L.len])"

		if (L.len > 0 && !(name == "underlays" || name == "overlays" || name == "vars" || L.len > 500))
			html += "<ul>"
			var/index = 1
			for (var/entry in L)
				if(istext(entry))
					html += debug_variable(entry, L[entry], level + 1)
				//html += debug_variable("[index]", L[index], level + 1)
				else
					html += debug_variable(index, L[index], level + 1)
				index++
			html += "</ul>"

	else
		html += "[name] = <span class='value'>[value]</span>"
	if(change)
		html += "</font>"

	html += "</li>"

	return html
