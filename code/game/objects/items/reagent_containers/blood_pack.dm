/obj/item/reagent_container/blood
	name = "BloodPack"
	desc = "Contains blood used for transfusion."
	icon = 'icons/obj/items/bloodpack.dmi'
	icon_state = "empty"
	volume = 200
	matter = list("plastic" = 500)
	flags_atom = CAN_BE_SYRINGED
	transparent = TRUE

	var/blood_type = null

/obj/item/reagent_container/blood/Initialize()
	. = ..()
	if(blood_type != null)
		name = "BloodPack [blood_type]"
		reagents.add_reagent("blood", 200, list("viruses"=null,"blood_type"=blood_type,"resistances"=null))
		update_icon()

/obj/item/reagent_container/blood/on_reagent_change()
	update_icon()

/obj/item/reagent_container/blood/update_icon()
	var/percent = round((reagents.total_volume / volume) * 100)
	switch(percent)
		if(0 to 9) icon_state = "empty"
		if(10 to 50) icon_state = "half"
		if(51 to INFINITY) icon_state = "full"

/obj/item/reagent_container/blood/APlus
	blood_type = "A+"

/obj/item/reagent_container/blood/AMinus
	blood_type = "A-"

/obj/item/reagent_container/blood/BPlus
	blood_type = "B+"

/obj/item/reagent_container/blood/BMinus
	blood_type = "B-"

/obj/item/reagent_container/blood/OPlus
	blood_type = "O+"

/obj/item/reagent_container/blood/OMinus
	blood_type = "O-"

/obj/item/reagent_container/blood/empty
	name = "Empty BloodPack"
	desc = "Seems pretty useless... Maybe if there were a way to fill it?"
	icon_state = "empty"
