/// Handles map insertions sequentially and updating the game to match map insertions
/datum/nmtask/scheduler/mapload
	name = "mapload scheduler"
	/// Map boundaries tainted by children nightmare tasks to be handled
	var/list/tainted_bounds = list()

/datum/nmtask/scheduler/mapload/execute()
	. = ..()
	makepowernets()
	repopulate_sorted_areas()

/datum/nmtask/scheduler/mapload/add_task(datum/nmtask/task)
	. = ..()
	RegisterSignal(task, COMSIG_NIGHTMARE_TAINTED_BOUNDS, .proc/register_tainted_bounds)

/datum/nmtask/scheduler/mapload/proc/register_tainted_bounds(datum/nmtask/task, list/bounds)
	tainted_bounds.len++
	tainted_bounds[tainted_bounds.len] = bounds
