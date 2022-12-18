//The effect when you wrap a dead body in gift wrap
/obj/effect/spresent
	name = "strange present"
	desc = "It's a ... present?"
	icon = 'icons/obj/items/items.dmi'
	icon_state = "strangepresent"
	density = 1
	anchored = 0






/obj/effect/mark
	var/mark = ""
	icon = 'icons/old_stuff/mark.dmi'
	icon_state = "blank"
	anchored = 1
	layer = 99
	mouse_opacity = 0
	unacidable = TRUE//Just to be sure.

/obj/effect/beam
	name = "beam"
	unacidable = TRUE//Just to be sure.
	var/def_zone

/obj/effect/beam/initialize_pass_flags(var/datum/pass_flags_container/PF)
	..()
	if (PF)
		PF.flags_pass = PASS_OVER|PASS_THROUGH


/obj/effect/begin
	name = "begin"
	icon = 'icons/obj/structures/props/stationobjs.dmi'
	icon_state = "begin"
	anchored = 1.0
	unacidable = TRUE




/obj/effect/list_container
	name = "list container"

/obj/effect/list_container/mobl
	name = "mobl"
	var/master = null

	var/list/container = list(  )

/obj/effect/projection
	name = "Projection"
	desc = "This looks like a projection of something."
	anchored = 1.0


/obj/effect/shut_controller
	name = "shut controller"
	var/moving = null
	var/list/parts = list(  )




//Exhaust effect
/obj/effect/engine_exhaust
	name = "engine exhaust"
	icon = 'icons/effects/effects.dmi'
	icon_state = "exhaust"
	anchored = 1

/obj/effect/engine_exhaust/New(var/turf/nloc, var/ndir, var/temp)
	setDir(ndir)
	..(nloc)

	spawn(20)
		moveToNullspace()

/obj/effect/dummy/lighting_obj
	name = "lighting fx obj"
	desc = "Tell a coder if you're seeing this."
	icon_state = "nothing"
	light_system = MOVABLE_LIGHT
	light_range = MINIMUM_USEFUL_LIGHT_RANGE
	light_color = COLOR_WHITE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	blocks_emissive = NONE

/obj/effect/dummy/lighting_obj/Initialize(mapload, _range, _power, _color, _duration)
	. = ..()
	if(!isnull(_range))
		set_light_range(_range)
	if(!isnull(_power))
		set_light_power(_power)
	if(!isnull(_color))
		set_light_color(_color)
	if(_duration)
		QDEL_IN(src, _duration)

/obj/effect/dummy/lighting_obj/moblight
	name = "mob lighting fx"

/obj/effect/dummy/lighting_obj/moblight/Initialize(mapload, _color, _range, _power, _duration)
	. = ..()
	if(!ismob(loc))
		return INITIALIZE_HINT_QDEL

