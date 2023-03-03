#define UPLINK_WY "Weyland-Yutani Quantum Relay (tm)"
#define UPLINK_USCM "USCM High Command Quantum Relay"

#define NETWORK_HC "USCM High Command"
#define NETWORK_PROVOST "USCM Provost Office"
#define NETWORK_WY "Weyland-Yutani Corporate Affairs"

#define USCM_NETWORK "USCM"
#define WY_NETWORK "Weyland-Yutani"

GLOBAL_DATUM_INIT(communications_network, /datum/communications_network, new)

/datum/communications_network/proc/send_fax(sent, sent_name, mob/sender, target_department, network, obj/structure/machinery/faxmachine/origin, datum/uplink/authoriser)
	var/local_network_faxes = LAZYACCESS(local_networks, network)
	if(!local_network_faxes)
		return

	for(var/obj/structure/machinery/faxmachine/receiving as anything in local_network_faxes)
		if(receiving.department == target_department && receiving != origin)
			receiving.receive_fax(sent, sent_name, authoriser)
			return

	var/remote_uplinks = LAZYACCESS(uplinks, origin.uplink)
	for(var/datum/uplink/uplink as anything in remote_uplinks)
		for(var/remote_network in uplink.networks)
			if(remote_network == target_department)
				uplink.handle_incoming_fax(sent, sent_name, sender, remote_network, origin)
				break

/datum/communications_network
	/// All uplinks available, uplink name -> uplink
	var/list/uplinks
	/// All faxes, network name -> fax
	var/list/local_networks

/datum/communications_network/New()
	for(var/datum/uplink/linking as anything in subtypesof(/datum/uplink))
		linking = new linking()
		LAZYADDASSOC(uplinks, linking.name, linking)

/datum/communications_network/proc/get_available_departments(network, uplink)
	if(!network || !uplink)
		return FALSE

	var/department_networks = LAZYACCESS(local_networks, network)
	var/remote_networks = LAZYACCESS(uplinks, uplink)

	var/list/departments = list(network = department_networks, uplink = remote_networks)

	return departments

/datum/communications_network/proc/register_department(obj/structure/machinery/faxmachine/registering_fax)
	LAZYADDASSOCLIST(local_networks, registering_fax.network, registering_fax)

/datum/communications_network/proc/announce_fax(msg_admin, msg_ghost)
	log_admin(msg_admin) //Always irked me the replies do show up but the faxes themselves don't
	for(var/client/C in GLOB.admins)
		if((R_ADMIN|R_MOD) & C.admin_holder.rights)
			if(msg_admin)
				to_chat(C, msg_admin)
			else
				to_chat(C, msg_ghost)
			SEND_SOUND(C, 'sound/effects/sos-morse-code.ogg')
	if(msg_ghost)
		for(var/i in GLOB.observer_list)
			var/mob/dead/observer/g = i
			if(!g.client)
				continue
			var/client/C = g.client
			if(C && C.admin_holder)
				if((R_ADMIN|R_MOD) & C.admin_holder.rights) //staff don't need to see the fax twice
					continue
			to_chat(C, msg_ghost)
			SEND_SOUND(C, 'sound/effects/sos-morse-code.ogg')

/datum/communications_network/proc/admin_fax(mob/user, mob/replying_to, obj/structure/machinery/faxmachine/origin, datum/uplink/from_uplink, from_network)
	if(!from_uplink)
		var/options = tgui_input_list(user, "Which uplink to appear from?", "Available Uplinks", uplinks)
		if(!options)
			return
		from_uplink = uplinks[options]

	if(!from_network)
		from_network = tgui_input_list(user, "Which network to appear from?", "Available Networks", from_uplink.networks)
		if(!from_network)
			return

	var/list/template_choices = from_uplink.template_choices.Copy()
	template_choices += "Custom"

	var/template_choice = tgui_input_list(user, "Use which template, or roll your own?", "Fax Templates", template_choices)
	if(!template_choice)
		return

	var/fax_message
	if(template_choice == "Custom")
		fax_message = tgui_input_text(user, "Enter a message to reply to [key_name(replying_to)]. Note: Only use HTML tags here.", "Message from [from_uplink.name]", encode = FALSE, multiline = TRUE)

	if(!fax_message)
		var/subject_line = tgui_input_text(user, "Enter subject line")
		if(!subject_line)
			return

		var/addressed_to
		if(replying_to)
			addressed_to = tgui_alert(user, "Address it to the sender or custom?", buttons = list("Sender", "Custom"))
			if(!addressed_to)
				return
			if(addressed_to == "Sender")
				addressed_to = replying_to.real_name
			else
				addressed_to = tgui_input_text(user, "Who should it be addressed to?")
		else
			addressed_to = tgui_input_text(user, "Who should it be sent to?")

		var/message_body = tgui_input_text(user, "Enter message body - HTML is allowed here.", encode = FALSE, multiline = TRUE)
		if(!message_body)
			return

		var/sent_by = tgui_input_text(user, "Enter the name and rank you are sending from.")
		if(!sent_by)
			return

		fax_message = from_uplink.generate_template(addressed_to, subject_line, message_body, sent_by, template_choice)

	show_browser(user, "<body class='paper'>[fax_message]</body>", "clfaxpreview", "size=500x400")
	var/send_choice = tgui_input_list(user, "Send this fax?", "Fax Confirmation", list("Send", "Cancel"))
	if(send_choice != "Send")
		return

	var/customname = input(user, "Pick a title for the report", "Title") as text|null
	if(!customname)
		return

	from_uplink.handle_incoming_fax(fax_message, customname, network = from_network)
	origin.receive_fax(fax_message, customname, from_uplink)

/datum/received_fax
	var/sent
	var/sent_name
	var/received_time
	var/datum/weakref/sender
	var/datum/weakref/origin_fax
	var/datum/weakref/uplink
	var/network

/datum/received_fax/New(sent_paper, sent_name, sender, origin, uplink, network)
	src.sent = sent_paper
	src.sent_name = sent_name
	src.network = network
	if(sender)
		src.sender = WEAKREF(sender)
	if(origin)
		src.origin_fax = WEAKREF(origin)
	if(uplink)
		src.uplink = WEAKREF(uplink)

	received_time = world.time

/datum/received_fax/proc/view_fax(mob/user)
	show_browser(user, "<body class='paper'>[sent]</body>", "Fax Message", "Fax Message")

/datum/received_fax/proc/reply(mob/user)
	var/mob/living/carbon/human/replying_to = sender.resolve()
	var/obj/structure/machinery/faxmachine/origin = origin_fax.resolve()
	var/datum/uplink/sent_to_uplink = uplink.resolve()

	GLOB.communications_network.admin_fax(user, replying_to, origin, sent_to_uplink, network)

/datum/uplink
	var/name
	var/list/networks
	var/list/incoming_faxes
	var/stamp_icon
	var/ghost_color
	var/list/template_choices

/datum/uplink/proc/handle_incoming_fax(sent, sent_name, sender, network, origin)
	var/datum/received_fax/abstract_incoming = new(sent, sent_name, sender, origin, src, network)
	LAZYADDASSOCLIST(incoming_faxes, network, abstract_incoming)

	var/msg_admin = SPAN_NOTICE("<b><font color='[ghost_color]'>[network] FAX: </font>[sender ? key_name(sender, 1) : "REPLY"] ")
	if(sender)
		msg_admin += "(<A HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];ahelp=mark=\ref[sender]'>Mark</A>) (<A HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];adminplayeropts=\ref[sender]'>PP</A>) "
		msg_admin += "(<A HREF='?_src_=vars;Vars=\ref[sender]'>VV</A>) (<A HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];subtlemessage=\ref[sender]'>SM</A>) "
		msg_admin += "(<A HREF='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];adminplayerobservejump=\ref[sender]'>JMP</A>) "
		msg_admin += "(<a href='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];fax_reply=\ref[abstract_incoming]'>RPLY</a>)</b>: "
	msg_admin += "Receiving '[sent_name]' via secure connection ... <a href='?fax_view=\ref[abstract_incoming]'>view message</a>"

	var/msg_ghost = SPAN_NOTICE("<b><font color='[ghost_color]'>[network] FAX: </font></b>")
	msg_ghost += "Receiving '[sent_name]' via secure connection ... <a href='?fax_view=\ref[abstract_incoming]'>view message</a>"

	GLOB.communications_network.announce_fax(msg_admin, msg_ghost)


/datum/uplink/proc/view_all_faxes(mob/user)

	var/faxes = tgui_input_list(user, "Which incoming faxes?", buttons = incoming_faxes)

	var/body = "<body>"

	for(var/datum/received_fax/fax as anything in incoming_faxes[faxes])
		body += "<a href='?fax_view=\ref[fax]'>VIEW</a>"
		body += "<a href=?_src=admin_holder;[HrefToken(forceGlobal = TRUE)];fax_reply=\ref[fax]'>REPLY</a>"
		body += " [fax.sent_name ? fax.sent_name : "ADMIN REPLY"] received at [worldtime2text(time = fax.received_time)]"
		body += "<br><br>"

	body += "<br><br></body>"
	show_browser(user, body, "Faxes to [name]", "faxviewer", "size=300x600")

/datum/uplink/weyland_yutani
	name = UPLINK_WY
	networks = list(NETWORK_WY)
	stamp_icon = "paper_stamp-wy"
	ghost_color = "#1F66A0"

	template_choices = list("Weyland-Yutani")

/datum/uplink/uscm
	name = UPLINK_USCM
	networks = list(NETWORK_HC, NETWORK_PROVOST)
	stamp_icon = "paper_stamp-uscm"
	ghost_color = "#006100"

	template_choices = list("USCM High Command", "Office of the Provost General")

/datum/uplink/proc/generate_template(addressed_to, subject, message_body, sent_by, sent_title)
	return

/datum/uplink/uscm/generate_template(addressed_to, subject, message_body, sent_by, sent_title)
	return generate_templated_fax(FALSE, "USCM CENTRAL COMMAND", subject, addressed_to, message_body,sent_by, sent_title, "United States Colonial Marine Corps")

/datum/uplink/weyland_yutani/generate_template(addressed_to, subject, message_body, sent_by, sent_title)
	return generate_templated_fax(TRUE, "WEYLAND-YUTANI CORPORATE AFFAIRS - [MAIN_SHIP_NAME]", subject, addressed_to, message_body, sent_by, "Corporate Affairs Director", "Weyland-Yutani")


//This fax machine will become a colonial one after I have mapped it onto the Almayer.
/obj/structure/machinery/faxmachine
	name = "General Purpose Fax Machine"
	icon = 'icons/obj/structures/machinery/library.dmi'
	icon_state = "fax"
	anchored = TRUE
	density = TRUE
	use_power = USE_POWER_IDLE
	idle_power_usage = 30
	active_power_usage = 200
	power_channel = POWER_CHANNEL_EQUIP

	var/obj/item/card/id/scan = null // identification
	var/authenticated = FALSE

	var/obj/item/paper/tofax = null // what we're sending

	///Our department
	var/department = "General Public"

	///Target department
	var/target_department

	/// Network this fax machine is connected to
	var/network = USCM_NETWORK

	/// Network this fax machine uplinks to
	var/uplink = UPLINK_WY

	var/list/available_departments

	///storer var for cooldown on sending faxes
	var/fax_cooldown = 300
	COOLDOWN_DECLARE(send_cooldown)

/obj/structure/machinery/faxmachine/Initialize(mapload, ...)
	. = ..()
	update_departments()

/obj/structure/machinery/faxmachine/Destroy()
	LAZYREMOVE(GLOB.communications_network.local_networks[network], src)
	. = ..()

/obj/structure/machinery/faxmachine/initialize_pass_flags(datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_can_pass_all = PASS_HIGH_OVER_ONLY|PASS_AROUND|PASS_OVER_THROW_ITEM


/obj/structure/machinery/faxmachine/attack_remote(mob/user as mob)
	return attack_hand(user)

/obj/structure/machinery/faxmachine/attack_hand(mob/user)
	tgui_interact(user)

/obj/structure/machinery/faxmachine/attackby(obj/item/O as obj, mob/user as mob)
	if(istype(O, /obj/item/paper))
		if(!tofax)
			user.drop_inv_item_to_loc(O, src)
			tofax = O
			to_chat(user, SPAN_NOTICE("You insert the paper into \the [src]."))
			flick("faxsend", src)
			updateUsrDialog()
		else
			to_chat(user, SPAN_NOTICE("There is already something in \the [src]."))

	else if(istype(O, /obj/item/card/id))

		var/obj/item/card/id/idcard = O
		if(!scan)
			user.drop_inv_item_to_loc(idcard, src)
			scan = idcard
			to_chat(usr, SPAN_NOTICE("You put \the [scan] into \the [src]."))
			playsound(src, 'sound/machines/pda_button1.ogg', 15, TRUE)

	else if(HAS_TRAIT(O, TRAIT_TOOL_WRENCH))
		playsound(loc, 'sound/items/Ratchet.ogg', 25, 1)
		anchored = !anchored
		to_chat(user, SPAN_NOTICE("You [anchored ? "wrench" : "unwrench"] \the [src]."))
	return

/obj/structure/machinery/faxmachine/verb/eject_id()
	set category = "Object"
	set name = "Eject ID Card"
	set src in view(1)

	if(!usr || usr.stat || usr.lying) return

	if(ishuman(usr) && scan)
		to_chat(usr, "You remove \the [scan] from \the [src].")
		playsound(src, 'sound/machines/terminal_eject.ogg', 15, TRUE)
		scan.forceMove(get_turf(src))
		if(!usr.get_active_hand() && istype(usr,/mob/living/carbon/human))
			usr.put_in_hands(scan)
		scan = null
		authenticated = FALSE
	else
		to_chat(usr, "There is nothing to remove from \the [src].")
	return

/obj/structure/machinery/faxmachine/proc/update_departments()
	available_departments = GLOB.communications_network.get_available_departments(network, uplink)
	GLOB.communications_network.register_department(src)

/obj/structure/machinery/faxmachine/proc/receive_fax(sent, sent_name, authoriser)
	if(inoperable())
		return

	flick("faxreceive", src)
	addtimer(CALLBACK(src, PROC_REF(print_paper), sent, sent_name, authoriser), 2 SECONDS)

/obj/structure/machinery/faxmachine/proc/print_paper(sent, sent_name, datum/uplink/authoriser)
	var/obj/item/paper/printed = new (src.loc)
	printed.name = "[sent_name]"
	printed.info = "[sent]"

	if(authoriser)
		var/image/stampoverlay = image('icons/obj/items/paper.dmi')
		stampoverlay.icon_state = authoriser.stamp_icon
		LAZYADD(printed.stamped, /obj/item/tool/stamp)
		printed.overlays += stampoverlay
		printed.stamps += "<HR><i>This paper has been stamped by the [authoriser.name].</i>"

	printed.update_icon()
	playsound(src, "sound/items/polaroid1.ogg", 15, 1)

// TGUI SHIT \\

/obj/structure/machinery/faxmachine/tgui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "FaxMachine", "[src.name]")
		ui.open()

/obj/structure/machinery/faxmachine/ui_state(mob/user)
	return GLOB.not_incapacitated_and_adjacent_state

/obj/structure/machinery/faxmachine/ui_status(mob/user, datum/ui_state/state)
	. = ..()
	if(inoperable())
		return UI_CLOSE

/obj/structure/machinery/faxmachine/ui_static_data(mob/user)
	var/list/data = list()

	data["department"] = department
	data["network"] = network

	return data

/obj/structure/machinery/faxmachine/ui_data(mob/user)
	var/list/data = list()

	data["idcard"] = scan
	data["paper"] = tofax
	if(tofax)
		data["paper_name"] = tofax.name

	data["authenticated"] = authenticated
	data["target_department"] = target_department

	data["worldtime"] = world.time
	data["nextfaxtime"] = send_cooldown
	data["faxcooldown"] = fax_cooldown

	return data

/obj/structure/machinery/faxmachine/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("send")
			if(tofax)
				COOLDOWN_START(src, send_cooldown, fax_cooldown)
				GLOB.communications_network.send_fax(tofax.info, tofax.name, usr, target_department, network, src)
				to_chat(usr, "Message transmitted successfully.")
				. = TRUE

		if("ejectpaper")
			if(tofax)
				if(!ishuman(usr))
					to_chat(usr, SPAN_WARNING("You can't do it."))
				else
					tofax.forceMove(usr.loc)
					usr.put_in_hands(tofax)
					to_chat(usr, SPAN_NOTICE("You take \the [tofax] out of \the [src]."))
					tofax = null
				. = TRUE

		if("insertpaper")
			var/obj/item/I = usr.get_active_hand()
			if(istype(I, /obj/item/paper))
				usr.drop_inv_item_to_loc(I, src)
				tofax = I
				to_chat(usr, SPAN_NOTICE("You put \the [tofax] into \the [src]."))
			. = TRUE

		if("ejectid")
			if(scan)
				if(ishuman(usr))
					scan.forceMove(usr.loc)
					if(!usr.get_active_hand())
						usr.put_in_hands(scan)
					scan = null
				else
					scan.forceMove(src.loc)
					scan = null
				to_chat(usr, SPAN_NOTICE("You take \the [scan] out of \the [src]."))
				authenticated = FALSE
				playsound(src, 'sound/machines/terminal_eject.ogg', 15, TRUE)
				. = TRUE

		if("select")
			var/last_target_department = target_department
			target_department = tgui_input_list(usr, "Which department?", "Choose a department", available_departments)
			if(!target_department) target_department = last_target_department
			. = TRUE

		if("auth")
			if ( (!( authenticated ) && (scan)) )
				if (check_access(scan))
					authenticated = TRUE
					playsound(src, 'sound/machines/terminal_on.ogg', 20, FALSE)
				. = TRUE

		if("logout")
			authenticated = FALSE
			. = TRUE

	add_fingerprint(usr)

/obj/structure/machinery/faxmachine/vv_get_dropdown()
	. = ..()
	. += "<option value>-----FAX-----</option>"
	. += "<option value='?_src_=admin_holder;[HrefToken(forceGlobal = TRUE)];send_to_fax=\ref[usr];originfax=\ref[src]'>Send fax message</option>"

/obj/structure/machinery/faxmachine/corporate
	name = "W-Y Corporate Fax Machine"
	department = "W-Y Local Office"
	network = "Weyland-Yutani Secure Network"

/obj/structure/machinery/faxmachine/corporate/liaison
	department = "W-Y Liaison"

/*
/obj/structure/machinery/faxmachine/corporate/highcom
	department = DEPARTMENT_WY
	target_department = "W-Y Liaison"
	network = "Weyland-Yutani Quantum Relay"
*/

/obj/structure/machinery/faxmachine/uscm
	name = "USCM Military Fax Machine"
	department = "USCM Local Operations"
	network = "USCM Encrypted Network"

/obj/structure/machinery/faxmachine/uscm/command
	department = "CIC"

/obj/structure/machinery/faxmachine/uscm/command/capt
	department = "Commanding Officer"

/*
/obj/structure/machinery/faxmachine/uscm/command/highcom
	department = DEPARTMENT_HC
	target_department = "Commanding Officer"
	network = "USCM High Command Quantum Relay"
*/

/obj/structure/machinery/faxmachine/uscm/brig
	name = "USCM Provost Fax Machine"
	department = "Brig"

/obj/structure/machinery/faxmachine/uscm/brig/chief
	department = "Chief MP"

/*
/obj/structure/machinery/faxmachine/uscm/brig/provost
	department = DEPARTMENT_PROVOST
	target_department = "Brig"
	network = "USCM High Command Quantum Relay"
*/
