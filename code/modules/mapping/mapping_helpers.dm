/// Mapping helper placed on turfs to remove the turf after a specified duration.
/// It's best to group these durations, as to not spam all players every minute
/obj/effect/timed_scrapeaway
	icon = 'icons/landmarks.dmi'
	icon_state = "o_red"

	var/static/list/notification_areas = list()

	/// How long to wait until this turf should be scraped away and replaced with the turf below.
	/// This value is in minutes, not deciseconds
	var/time

/obj/effect/timed_scrapeaway/Initialize(mapload, ...)
	. = ..()

	icon = null

	if(isnull(time))
		stack_trace("[type] (x: [x], y: [y], z: [z]) was created without a time.")
		return INITIALIZE_HINT_QDEL

	SSticker.OnRoundstart(CALLBACK(src, PROC_REF(handle_round_start)))

/obj/effect/timed_scrapeaway/proc/handle_round_start()
	var/turf/to_be_scraped = get_turf(src)

	var/actual_time = time MINUTES

	addtimer(CALLBACK(to_be_scraped, TYPE_PROC_REF(/turf, ScrapeAway)), actual_time)

	if(notification_areas["[actual_time]"])
		LAZYDISTINCTADD(notification_areas["[actual_time]"], get_area(src))
	else
		addtimer(CALLBACK(src, PROC_REF(announce_geological_shifts), actual_time), actual_time)
		LAZYDISTINCTADD(notification_areas["[actual_time]"], get_area(src))

/obj/effect/timed_scrapeaway/proc/announce_geological_shifts(time_to_grab)
	var/announcement_areas = english_list(notification_areas["[time_to_grab]"])

	var/marine_announcement_text = SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_IN_SPACE] \
		? "Structural collapse detected in [announcement_areas]. Be advised that new routes may be accessible." \
		: "Geological shifts detected in [announcement_areas]. Be advised that new routes may be accessible."

	marine_announcement(marine_announcement_text, "Priority Announcement")

	var/xeno_announcement_text = SSmapping.configs[GROUND_MAP].environment_traits[ZTRAIT_IN_SPACE] \
		? "The shattered metal of this place has collapsed, providing new routes in [announcement_areas]." \
		: "The ground of this world trembles, and new routes are accessible in [announcement_areas]."

	xeno_announcement(xeno_announcement_text, "everything", XENO_GENERAL_ANNOUNCE)
