/*
//////////////////////////////////////

Dizziness

	Hidden.
	Lowers resistance considerably.
	Decreases stage speed.
	Reduced transmittability
	Intense Level.

Bonus
	Shakes the affected mob's screen for short periods.

//////////////////////////////////////
*/

/datum/symptom/dizzy // Not the egg

	name = "Dizziness"
	stealth = 2
	resistance = -2
	stage_speed = -3
	transmittable = -1
	level = 4

/datum/symptom/dizzy/Activate(var/datum/disease/advance/A)
	..()
	if(prob(GLOB.SYMPTOM_ACTIVATION_PROB))
		var/mob/living/M = A.affected_mob
		switch(A.stage)
			if(1, 2, 3, 4)
				to_chat(M, SPAN_NOTICE("[pick("You feel dizzy.", "Your head starts spinning.")]"))
			else
				to_chat(M, SPAN_NOTICE("You are unable to look straight!"))
				M.make_dizzy(5)
	return
