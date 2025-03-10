/datum/antagonist/obsessed
	name = "Obsessed"
	show_in_antagpanel = TRUE
	antagpanel_category = "Other"
	banning_key = ROLE_OBSESSED
	show_name_in_check_antagonists = TRUE
	roundend_category = "obsessed"
	count_against_dynamic_roll_chance = FALSE
	silent = TRUE //not actually silent, because greet will be called by the trauma anyway.
	var/datum/brain_trauma/special/obsessed/trauma

/datum/antagonist/obsessed/admin_add(datum/mind/new_owner,mob/admin)
	var/mob/living/carbon/C = new_owner.current
	if(!istype(C))
		to_chat(admin, "[roundend_category] comes from a brain trauma, so they need to at least be a carbon!")
		return
	if(!C.getorgan(/obj/item/organ/brain)) // If only I had a brain
		to_chat(admin, "[roundend_category] comes from a brain trauma, so they need to HAVE A BRAIN.")
		return
	message_admins("[key_name_admin(admin)] made [key_name_admin(new_owner)] into [name].")
	log_admin("[key_name(admin)] made [key_name(new_owner)] into [name].")
	//PRESTO FUCKIN MAJESTO
	C.gain_trauma(/datum/brain_trauma/special/obsessed)//ZAP

/datum/antagonist/obsessed/greet()
	if(!trauma?.obsession)
		return
	owner.current.playsound_local(get_turf(owner.current), 'sound/ambience/antag/creepalert.ogg', 100, FALSE, pressure_affected = FALSE, use_reverb = FALSE)
	to_chat(owner, "<span class='userdanger'>You are the Obsessed!</span>")
	to_chat(owner, "<B>The Voices have reached out to you, and are using you to complete their evil deeds.</B>")
	to_chat(owner, "<B>You don't know their connection, but The Voices compel you to stalk [trauma.obsession], forcing them into a state of constant paranoia.</B>")
	to_chat(owner, "<B>The Voices will retaliate if you fail to complete your tasks or spend too long away from your target.</B>")
	to_chat(owner, "<span class='boldannounce'>This role does NOT enable you to otherwise surpass what's deemed creepy behavior per the rules.</span>")//ironic if you know the history of the antag
	owner.announce_objectives()
	owner.current.client?.tgui_panel?.give_antagonist_popup("Obsession",
		"Stalk [trauma.obsession] and force them into a constant state of paranoia.")

/datum/antagonist/obsessed/Destroy()
	if(trauma)
		qdel(trauma)
	. = ..()

/datum/antagonist/obsessed/apply_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_obsession_icons_added(M)

/datum/antagonist/obsessed/remove_innate_effects(mob/living/mob_override)
	var/mob/living/M = mob_override || owner.current
	update_obsession_icons_removed(M)

/datum/antagonist/obsessed/proc/forge_objectives(datum/mind/obsessionmind)
	var/list/objectives_left = list("spendtime", "polaroid", "hug")
	var/datum/objective/assassinate/obsessed/kill = new
	kill.owner = owner
	kill.set_target(obsessionmind)
	var/datum/quirk/family_heirloom/family_heirloom

	if(obsessionmind.has_quirk(family_heirloom))//oh, they have an heirloom? Well you know we have to steal that.
		objectives_left += "heirloom"

	if(obsessionmind.assigned_role && obsessionmind.assigned_role != JOB_NAME_CAPTAIN)
		objectives_left += "jealous"//if they have no coworkers, jealousy will pick someone else on the station. this will never be a free objective, nice.

	for(var/i in 1 to 3)
		var/chosen_objective = pick(objectives_left)
		objectives_left.Remove(chosen_objective)
		switch(chosen_objective)
			if("spendtime")
				var/datum/objective/spendtime/spendtime = new
				spendtime.owner = owner
				spendtime.set_target(obsessionmind)
				objectives += spendtime
				log_objective(owner, spendtime.explanation_text)
			if("polaroid")
				var/datum/objective/polaroid/polaroid = new
				polaroid.owner = owner
				polaroid.set_target(obsessionmind)
				objectives += polaroid
				log_objective(owner, polaroid.explanation_text)
			if("hug")
				var/datum/objective/hug/hug = new
				hug.owner = owner
				hug.set_target(obsessionmind)
				objectives += hug
				log_objective(owner, hug.explanation_text)
			if("heirloom")
				var/datum/objective/steal/heirloom_thief/heirloom_thief = new
				heirloom_thief.owner = owner
				heirloom_thief.set_target(obsessionmind)//while you usually wouldn't need this for stealing, we need the name of the obsession
				heirloom_thief.steal_target = family_heirloom.heirloom
				objectives += heirloom_thief
				log_objective(owner, heirloom_thief.explanation_text)
			if("jealous")
				var/datum/objective/assassinate/jealous/jealous = new
				jealous.owner = owner
				jealous.obsession = obsessionmind
				jealous.find_target()//will reroll into a coworker on the objective itself
				objectives += jealous
				log_objective(owner, jealous.explanation_text)

	objectives += kill//finally add the assassinate last, because you'd have to complete it last to greentext.
	log_objective(owner, kill.explanation_text)
	for(var/datum/objective/O in objectives)
		O.update_explanation_text()

/datum/antagonist/obsessed/roundend_report_header()
	return 	"<span class='header'>Someone became obsessed!</span><br>"

/datum/antagonist/obsessed/roundend_report()
	var/list/report = list()

	if(!owner)
		CRASH("antagonist datum without owner")

	report += "<b>[printplayer(owner)]</b>"

	var/objectives_complete = TRUE
	if(objectives.len)
		report += printobjectives(objectives)
		for(var/datum/objective/objective in objectives)
			if(!objective.check_completion())
				objectives_complete = FALSE
				break
	if(trauma)
		if(trauma.total_time_creeping > 0)
			report += "<span class='greentext'>The [name] spent a total of [DisplayTimeText(trauma.total_time_creeping)] being near [trauma.obsession]!</span>"
		else
			report += "<span class='redtext'>The [name] did not go near their obsession the entire round! That's extremely impressive, but you are a shit [name]!</span>"
	else
		report += "<span class='redtext'>The [name] had no trauma attached to their antagonist ways! Either it bugged out or an admin incorrectly gave this good samaritan antag and it broke! You might as well show yourself!!</span>"

	if(objectives.len == 0 || objectives_complete)
		report += "<span class='greentext big'>The [name] was successful!</span>"
	else
		report += "<span class='redtext big'>The [name] has failed!</span>"

	return report.Join("<br>")

//////////////////////////////////////////////////
///CREEPY objectives (few chosen per obsession)///
//////////////////////////////////////////////////

/datum/objective/assassinate/obsessed //just a creepy version of assassinate

/datum/objective/assassinate/obsessed/update_explanation_text()
	..()
	if(target && target.current)
		explanation_text = "Murder [target.name], the [!target_role_type ? target.assigned_role : target.special_role]."
	else
		message_admins("WARNING! [ADMIN_LOOKUPFLW(owner)] obsessed objectives forged without an obsession!")
		explanation_text = "Free Objective"

/datum/objective/assassinate/obsessed/on_target_cryo()
	qdel(src) //trauma will give replacement objectives

/datum/objective/assassinate/jealous //assassinate, but it changes the target to someone else in the obsession's department. cool, right?
	var/datum/mind/obsession //the target the coworker is picked from.

/datum/objective/assassinate/jealous/update_explanation_text()
	..()
	if(obsession && target?.current)
		explanation_text = "Murder [target.name], [obsession]'s coworker."
	else if(target?.current)
		explanation_text = "Murder [target.name]."
	else
		explanation_text = "Free Objective"

/datum/objective/assassinate/jealous/find_target(list/dupe_search_range, list/blacklist)//returning null = free objective
	if(!obsession?.assigned_role)
		set_target(null)
		update_explanation_text()
		return
	var/list/viable_coworkers = list()
	var/list/all_coworkers = list()
	var/list/chosen_department
	//note that command and sillycone are gone because borgs can't be obsessions and the heads have their respective department. Sorry cap, your place is more with centcom or something
	if(obsession.assigned_role in GLOB.security_positions)
		chosen_department = GLOB.security_positions
	else if(obsession.assigned_role in GLOB.engineering_positions)
		chosen_department = GLOB.engineering_positions
	else if(obsession.assigned_role in GLOB.medical_positions)
		chosen_department = GLOB.medical_positions
	else if(obsession.assigned_role in GLOB.science_positions)
		chosen_department = GLOB.science_positions
	else if(obsession.assigned_role in GLOB.supply_positions)
		chosen_department = GLOB.supply_positions
	else if(obsession.assigned_role in (GLOB.civilian_positions | GLOB.gimmick_positions))
		chosen_department = GLOB.civilian_positions | GLOB.gimmick_positions
	else
		set_target(null)
		update_explanation_text()
		return
	for(var/datum/mind/possible_target as() in get_crewmember_minds())
		if(!SSjob.GetJob(possible_target.assigned_role) || possible_target == obsession || possible_target.has_antag_datum(/datum/antagonist/obsessed) || (possible_target in blacklist))
			continue //the jealousy target has to have a job, and not be the obsession or obsessed.
		all_coworkers += possible_target
		if(possible_target.assigned_role in chosen_department)
			viable_coworkers += possible_target

	if(viable_coworkers.len)//find someone in the same department
		set_target(pick(viable_coworkers))
	else if(all_coworkers.len)//find someone who works on the station
		set_target(pick(all_coworkers))
	else
		set_target(null)
	update_explanation_text()
	return target

/datum/objective/spendtime //spend some time around someone, handled by the obsessed trauma since that ticks
	name = "spendtime"
	var/timer = 1800 //5 minutes

/datum/objective/spendtime/update_explanation_text()
	if(timer == initial(timer))//just so admins can mess with it
		timer += pick(-600, 0)
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(target && target.current && creeper)
		creeper.trauma.attachedobsessedobj = src
		explanation_text = "Spend [DisplayTimeText(timer)] around [target.name] while they're alive."
	else
		explanation_text = "Free Objective"

/datum/objective/spendtime/check_completion()
	return timer <= 0 || explanation_text == "Free Objective" || ..()

/datum/objective/spendtime/on_target_cryo()
	qdel(src)

/datum/objective/hug//this objective isn't perfect. hugging the correct amount of times, then switching bodies, might fail the objective anyway. maybe i'll come back and fix this sometime.
	name = "hugs"
	var/hugs_needed

/datum/objective/hug/update_explanation_text()
	..()
	if(!hugs_needed)//just so admins can mess with it
		hugs_needed = rand(4,6)
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(target && target.current && creeper)
		explanation_text = "Hug [target.name] [hugs_needed] times while they're alive."
	else
		explanation_text = "Free Objective"

/datum/objective/hug/check_completion()
	var/datum/antagonist/obsessed/creeper = owner.has_antag_datum(/datum/antagonist/obsessed)
	if(!creeper || !creeper.trauma || !hugs_needed)
		return TRUE//free objective
	return (creeper.trauma.obsession_hug_count >= hugs_needed) || ..()

/datum/objective/hug/on_target_cryo()
	qdel(src)

/datum/objective/polaroid //take a picture of the target with you in it.
	name = "polaroid"

/datum/objective/polaroid/update_explanation_text()
	..()
	if(target && target.current)
		explanation_text = "Take a photo of [target.name] while they're alive."
	else
		explanation_text = "Free Objective"

/datum/objective/polaroid/check_completion()
	var/list/datum/mind/owners = get_owners()
	for(var/datum/mind/M in owners)
		if(!isliving(M.current))
			continue
		var/list/all_items = M.current.GetAllContents()	//this should get things in cheesewheels, books, etc.
		for(var/obj/I in all_items) //Check for wanted items
			if(istype(I, /obj/item/photo))
				var/obj/item/photo/P = I
				if(P.picture && (target.current in P.picture.mobs_seen) && !(target.current in P.picture.dead_seen)) //Does the picture exist and is the target in it and is the target not dead
					return TRUE
	return ..()

/datum/objective/polaroid/on_target_cryo()
	qdel(src)

/datum/objective/steal/heirloom_thief //exactly what it sounds like, steal someone's heirloom.
	name = "heirloomthief"

/datum/objective/steal/heirloom_thief/update_explanation_text()
	..()
	if(steal_target)
		explanation_text = "Steal [target.name]'s family heirloom, [steal_target] they cherish."
	else
		explanation_text = "Free Objective"

/datum/antagonist/obsessed/proc/update_obsession_icons_added(var/mob/living/carbon/human/obsessed)
	var/datum/atom_hud/antag/creephud = GLOB.huds[ANTAG_HUD_OBSESSED]
	creephud.join_hud(obsessed)
	set_antag_hud(obsessed, "obsessed")

/datum/antagonist/obsessed/proc/update_obsession_icons_removed(var/mob/living/carbon/human/obsessed)
	var/datum/atom_hud/antag/creephud = GLOB.huds[ANTAG_HUD_OBSESSED]
	creephud.leave_hud(obsessed)
	set_antag_hud(obsessed, null)
