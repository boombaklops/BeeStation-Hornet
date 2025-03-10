#define TRAIT_STATUS_EFFECT(effect_id) "[effect_id]-trait"

//Largely negative status effects go here, even if they have small benificial effects
//STUN EFFECTS
/datum/status_effect/incapacitating
	tick_interval = 0
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/needs_update_stat = FALSE

/datum/status_effect/incapacitating/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	if(isnum_safe(set_duration))
		duration = set_duration
	. = ..()
	if(.)
		if(updating_canmove)
			owner.update_mobility()
			if(needs_update_stat || issilicon(owner))
				owner.update_stat()

/datum/status_effect/incapacitating/on_remove()
	owner.update_mobility()
	if(needs_update_stat || issilicon(owner)) //silicons need stat updates in addition to normal canmove updates
		owner.update_stat()
	return ..()

//STUN
/datum/status_effect/incapacitating/stun
	id = "stun"

/datum/status_effect/incapacitating/stun/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/stun/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()

//KNOCKDOWN
/datum/status_effect/incapacitating/knockdown
	id = "knockdown"

//IMMOBILIZED
/datum/status_effect/incapacitating/immobilized
	id = "immobilized"

/datum/status_effect/incapacitating/paralyzed
	id = "paralyzed"

/datum/status_effect/incapacitating/paralyzed/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/paralyzed/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()

//UNCONSCIOUS
/datum/status_effect/incapacitating/unconscious
	id = "unconscious"
	needs_update_stat = TRUE

/datum/status_effect/incapacitating/unconscious/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/incapacitating/unconscious/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	return ..()

/datum/status_effect/incapacitating/unconscious/tick()
	if(owner.getStaminaLoss())
		owner.adjustStaminaLoss(-0.3) //reduce stamina loss by 0.3 per tick, 6 per 2 seconds

//SLEEPING
/datum/status_effect/incapacitating/sleeping
	id = "sleeping"
	alert_type = /atom/movable/screen/alert/status_effect/asleep
	needs_update_stat = TRUE
	var/mob/living/carbon/carbon_owner
	var/mob/living/carbon/human/human_owner

/datum/status_effect/incapacitating/sleeping/on_creation(mob/living/new_owner, updating_canmove)
	. = ..()
	if(.)
		if(iscarbon(owner)) //to avoid repeated istypes
			carbon_owner = owner
		if(ishuman(owner))
			human_owner = owner

/datum/status_effect/incapacitating/sleeping/Destroy()
	carbon_owner = null
	human_owner = null
	return ..()

/datum/status_effect/incapacitating/sleeping/tick()
	if(owner.maxHealth)
		var/health_ratio = owner.health / owner.maxHealth
		if(health_ratio > 0.8)
			var/healing = -0.2
			if((locate(/obj/structure/bed) in owner.loc))
				healing -= 0.3
			else
				if((locate(/obj/structure/table) in owner.loc))
					healing -= 0.1
			owner.adjustBruteLoss(healing)
			owner.adjustFireLoss(healing)
			owner.adjustToxLoss(healing * 0.5, TRUE, TRUE)
			owner.adjustStaminaLoss(healing)
	if(human_owner?.drunkenness)
		human_owner.drunkenness *= 0.997 //reduce drunkenness by 0.3% per tick, 6% per 2 seconds
	if(prob(20))
		if(carbon_owner)
			carbon_owner.handle_dreams()
		if(prob(10) && owner.health > owner.crit_threshold)
			owner.emote("snore")

/atom/movable/screen/alert/status_effect/asleep
	name = "Asleep"
	desc = "You've fallen asleep. Wait a bit and you should wake up. Unless you don't, considering how helpless you are."
	icon_state = "asleep"

//STASIS
/datum/status_effect/grouped/stasis
	id = "stasis"
	duration = -1
	tick_interval = 10
	alert_type = /atom/movable/screen/alert/status_effect/stasis
	var/last_dead_time

/datum/status_effect/grouped/stasis/proc/update_time_of_death()
	if(last_dead_time)
		var/delta = world.time - last_dead_time
		var/new_timeofdeath = owner.timeofdeath + delta
		owner.timeofdeath = new_timeofdeath
		owner.tod = station_time_timestamp(wtime=new_timeofdeath)
		last_dead_time = null
	if(owner.stat == DEAD)
		last_dead_time = world.time

/datum/status_effect/grouped/stasis/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	if(.)
		update_time_of_death()
		owner.reagents?.end_metabolization(owner, FALSE)
		owner.update_mobility()

/* Mobility refactor
/datum/status_effect/grouped/stasis/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
*/

/datum/status_effect/grouped/stasis/tick()
	update_time_of_death()

/datum/status_effect/grouped/stasis/on_remove()
	/* Mobility refactor
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_HANDS_BLOCKED, TRAIT_STATUS_EFFECT(id))
	*/
	owner.update_mobility()
	update_time_of_death()
	return ..()

/atom/movable/screen/alert/status_effect/stasis
	name = "Stasis"
	desc = "Your biological functions have halted. You could live forever this way, but it's pretty boring."
	icon_state = "stasis"

//GOLEM GANG

//OTHER DEBUFFS
/datum/status_effect/strandling //get it, strand as in durathread strand + strangling = strandling hahahahahahahahahahhahahaha i want to die
	id = "strandling"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/strandling

/datum/status_effect/strandling/on_apply()
	ADD_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/datum/status_effect/strandling/on_remove()
	REMOVE_TRAIT(owner, TRAIT_MAGIC_CHOKE, "dumbmoron")
	return ..()

/atom/movable/screen/alert/status_effect/strandling
	name = "Choking strand"
	desc = "A magical strand of Durathread is wrapped around your neck, preventing you from breathing! Click this icon to remove the strand."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/status_effect/strandling/Click(location, control, params)
	. = ..()
	if(usr != owner)
		return
	to_chat(owner, "<span class='notice'>You attempt to remove the durathread strand from around your neck.</span>")
	if(do_after(owner, 35, target = owner, timed_action_flags = IGNORE_HELD_ITEM))
		if(isliving(owner))
			var/mob/living/L = owner
			to_chat(owner, "<span class='notice'>You successfuly remove the durathread strand.</span>")
			L.remove_status_effect(STATUS_EFFECT_CHOKINGSTRAND)

/datum/status_effect/syringe
	id = "syringe"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null
	var/obj/item/reagent_containers/syringe/syringe
	var/injectmult = 1

/datum/status_effect/syringe/on_creation(mob/living/new_owner, obj/item/reagent_containers/syringe/origin, mult)
	syringe = origin
	injectmult = mult
	return ..()

/datum/status_effect/syringe/on_apply()
	. = ..()
	var/amount = syringe.initial_inject
	syringe.reagents.reaction(owner, INJECT)
	syringe.reagents.trans_to(owner, max(3.1, amount * injectmult))
	owner.throw_alert("syringealert", /atom/movable/screen/alert/syringe)

/datum/status_effect/syringe/tick()
	. = ..()
	var/amount = syringe.units_per_tick
	syringe.reagents.reaction(owner, INJECT, amount / 10)//so the slow drip-feed of reagents isn't exploited
	syringe.reagents.trans_to(owner, amount * injectmult)


/atom/movable/screen/alert/syringe
	name = "Embedded Syringe"
	desc = "A syringe has embedded itself into your body, injecting its reagents! click this icon to carefully remove the syringe."
	icon_state = "drugged"
	alerttooltipstyle = "hisgrace"

/atom/movable/screen/alert/syringe/Click(location, control, params)
	. = ..()
	if(usr != owner)
		return
	if(owner.incapacitated())
		return
	var/list/syringes = list()
	if(iscarbon(owner))
		var/mob/living/carbon/C = owner
		for(var/datum/status_effect/syringe/S in C.status_effects)
			syringes += S
		if(!syringes.len)
			return
		var/datum/status_effect/syringe/syringestatus = pick_n_take(syringes)
		if(istype(syringestatus, /datum/status_effect/syringe))
			var/obj/item/reagent_containers/syringe/syringe = syringestatus.syringe
			to_chat(owner, "<span class='notice'>You begin carefully pulling the syringe out.</span>")
			if(do_after(C, 20, target = owner, timed_action_flags = IGNORE_HELD_ITEM))
				to_chat(C, "<span class='notice'>You succesfuly remove the syringe.</span>")
				syringe.forceMove(C.loc)
				C.put_in_hands(syringe)
				qdel(syringestatus)
			else
				to_chat(C, "<span class='userdanger'>You screw up, and inject yourself with more chemicals by mistake!</span>")
				var/amount = syringe.initial_inject
				syringe.reagents.reaction(C, INJECT)
				syringe.reagents.trans_to(C, amount)
				syringe.forceMove(C.loc)
				qdel(syringestatus)
		if(!C.has_status_effect(STATUS_EFFECT_SYRINGE))
			C.clear_alert("syringealert")



/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum_safe(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

//OTHER DEBUFFS
/datum/status_effect/pacify
	id = "pacify"
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	duration = 100
	alert_type = null

/datum/status_effect/pacify/on_creation(mob/living/new_owner, set_duration)
	if(isnum_safe(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/pacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "status_effect")
	return ..()

/datum/status_effect/pacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "status_effect")

/datum/status_effect/his_wrath //does minor damage over time unless holding His Grace
	id = "his_wrath"
	duration = -1
	tick_interval = 4
	alert_type = /atom/movable/screen/alert/status_effect/his_wrath

/atom/movable/screen/alert/status_effect/his_wrath
	name = "His Wrath"
	desc = "You fled from His Grace instead of feeding Him, and now you suffer."
	icon_state = "his_grace"
	alerttooltipstyle = "hisgrace"

/datum/status_effect/his_wrath/tick()
	for(var/obj/item/his_grace/HG in owner.held_items)
		qdel(src)
		return
	owner.adjustBruteLoss(0.1)
	owner.adjustFireLoss(0.1)
	owner.adjustToxLoss(0.2, TRUE, TRUE)

/datum/status_effect/cultghost //is a cult ghost and can't use manifest runes
	id = "cult_ghost"
	duration = -1
	alert_type = null

/datum/status_effect/cultghost/on_apply()
	owner.see_invisible = SEE_INVISIBLE_SPIRIT
	owner.see_in_dark = 2
	return ..()

/datum/status_effect/cultghost/tick()
	if(owner.reagents)
		owner.reagents.del_reagent(/datum/reagent/water/holywater) //can't be deconverted

/datum/status_effect/crusher_mark
	id = "crusher_mark"
	duration = 300 //if you leave for 30 seconds you lose the mark, deal with it
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	var/mutable_appearance/marked_underlay
	var/obj/item/kinetic_crusher/hammer_synced

/datum/status_effect/crusher_mark/on_creation(mob/living/new_owner, obj/item/kinetic_crusher/new_hammer_synced)
	. = ..()
	if(.)
		hammer_synced = new_hammer_synced

/datum/status_effect/crusher_mark/on_apply()
	if(owner.mob_size >= MOB_SIZE_LARGE)
		marked_underlay = mutable_appearance('icons/effects/effects.dmi', "shield2")
		marked_underlay.pixel_x = -owner.pixel_x
		marked_underlay.pixel_y = -owner.pixel_y
		owner.underlays += marked_underlay
		return TRUE
	return FALSE

/datum/status_effect/crusher_mark/Destroy()
	hammer_synced = null
	if(owner)
		owner.underlays -= marked_underlay
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/crusher_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/datum/status_effect/saw_bleed
	id = "saw_bleed"
	duration = -1 //removed under specific conditions
	tick_interval = 6
	alert_type = null
	var/mutable_appearance/bleed_overlay
	var/mutable_appearance/bleed_underlay
	var/bleed_amount = 3
	var/bleed_buildup = 3
	var/delay_before_decay = 5
	var/bleed_damage = 200
	var/needs_to_bleed = FALSE

/datum/status_effect/saw_bleed/Destroy()
	if(owner)
		owner.cut_overlay(bleed_overlay)
		owner.underlays -= bleed_underlay
	QDEL_NULL(bleed_overlay)
	return ..()

/datum/status_effect/saw_bleed/on_apply()
	if(owner.stat == DEAD)
		return FALSE
	bleed_overlay = mutable_appearance('icons/effects/bleed.dmi', "bleed[bleed_amount]")
	bleed_underlay = mutable_appearance('icons/effects/bleed.dmi', "bleed[bleed_amount]")
	var/icon/I = icon(owner.icon, owner.icon_state, owner.dir)
	var/icon_height = I.Height()
	bleed_overlay.pixel_x = -owner.pixel_x
	bleed_overlay.pixel_y = FLOOR(icon_height * 0.25, 1)
	bleed_overlay.transform = matrix() * (icon_height/world.icon_size) //scale the bleed overlay's size based on the target's icon size
	bleed_underlay.pixel_x = -owner.pixel_x
	bleed_underlay.transform = matrix() * (icon_height/world.icon_size) * 3
	bleed_underlay.alpha = 40
	owner.add_overlay(bleed_overlay)
	owner.underlays += bleed_underlay
	return ..()

/datum/status_effect/saw_bleed/tick()
	if(owner.stat == DEAD)
		qdel(src)
	else
		add_bleed(-1)

/datum/status_effect/saw_bleed/proc/add_bleed(amount)
	owner.cut_overlay(bleed_overlay)
	owner.underlays -= bleed_underlay
	bleed_amount += amount
	if(bleed_amount)
		if(bleed_amount >= 10)
			needs_to_bleed = TRUE
			qdel(src)
		else
			if(amount > 0)
				tick_interval += delay_before_decay
			bleed_overlay.icon_state = "bleed[bleed_amount]"
			bleed_underlay.icon_state = "bleed[bleed_amount]"
			owner.add_overlay(bleed_overlay)
			owner.underlays += bleed_underlay
	else
		qdel(src)

/datum/status_effect/saw_bleed/on_remove()
	if(needs_to_bleed)
		var/turf/T = get_turf(owner)
		new /obj/effect/temp_visual/bleed/explode(T)
		for(var/d in GLOB.alldirs)
			new /obj/effect/temp_visual/dir_setting/bloodsplatter(T, d)
		playsound(T, "desecration", 200, 1, -1)
		owner.adjustBruteLoss(bleed_damage)
	else
		new /obj/effect/temp_visual/bleed(get_turf(owner))

/datum/status_effect/neck_slice
	id = "neck_slice"
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = null
	duration = -1

/datum/status_effect/neck_slice/tick()
	var/mob/living/carbon/human/H = owner
	if(H.stat == DEAD || H.bleed_rate <= 8)
		H.remove_status_effect(/datum/status_effect/neck_slice)
	if(prob(10))
		H.emote(pick("gasp", "gag", "choke"))

/mob/living/proc/apply_necropolis_curse(set_curse)
	var/datum/status_effect/necropolis_curse/C = has_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE)
	if(!set_curse)
		set_curse = pick(CURSE_BLINDING, CURSE_SPAWNING, CURSE_WASTING, CURSE_GRASPING)
	if(QDELETED(C))
		apply_status_effect(STATUS_EFFECT_NECROPOLIS_CURSE, set_curse)
	else
		C.apply_curse(set_curse)
		C.duration += 3000 //additional curses add 5 minutes

/datum/status_effect/necropolis_curse
	id = "necrocurse"
	duration = 6000 //you're cursed for 10 minutes have fun
	tick_interval = 50
	alert_type = null
	var/curse_flags = NONE
	var/effect_last_activation = 0
	var/effect_cooldown = 100
	var/obj/effect/temp_visual/curse/wasting_effect = new

/datum/status_effect/necropolis_curse/on_creation(mob/living/new_owner, set_curse)
	. = ..()
	if(.)
		apply_curse(set_curse)

/datum/status_effect/necropolis_curse/Destroy()
	if(!QDELETED(wasting_effect))
		qdel(wasting_effect)
		wasting_effect = null
	return ..()

/datum/status_effect/necropolis_curse/on_remove()
	remove_curse(curse_flags)

/datum/status_effect/necropolis_curse/proc/apply_curse(set_curse)
	curse_flags |= set_curse
	if(curse_flags & CURSE_BLINDING)
		owner.overlay_fullscreen("curse", /atom/movable/screen/fullscreen/curse, 1)

/datum/status_effect/necropolis_curse/proc/remove_curse(remove_curse)
	if(remove_curse & CURSE_BLINDING)
		owner.clear_fullscreen("curse", 50)
	curse_flags &= ~remove_curse

/datum/status_effect/necropolis_curse/tick()
	if(owner.stat == DEAD)
		return
	if(curse_flags & CURSE_WASTING)
		wasting_effect.forceMove(owner.loc)
		wasting_effect.setDir(owner.dir)
		wasting_effect.transform = owner.transform //if the owner has been stunned the overlay should inherit that position
		wasting_effect.alpha = 255
		animate(wasting_effect, alpha = 0, time = 32)
		playsound(owner, 'sound/effects/curse5.ogg', 20, 1, -1)
		owner.adjustFireLoss(0.75)
	if(effect_last_activation <= world.time)
		effect_last_activation = world.time + effect_cooldown
		if(curse_flags & CURSE_SPAWNING)
			var/turf/spawn_turf
			var/sanity = 10
			while(!spawn_turf && sanity)
				spawn_turf = locate(owner.x + pick(rand(10, 15), rand(-10, -15)), owner.y + pick(rand(10, 15), rand(-10, -15)), owner.z)
				sanity--
			if(spawn_turf)
				var/mob/living/simple_animal/hostile/asteroid/curseblob/C = new (spawn_turf)
				C.set_target = owner
				C.GiveTarget()
		if(curse_flags & CURSE_GRASPING)
			var/grab_dir = turn(owner.dir, pick(-90, 90, 180, 180)) //grab them from a random direction other than the one faced, favoring grabbing from behind
			var/turf/spawn_turf = get_ranged_target_turf(owner, grab_dir, 5)
			if(spawn_turf)
				grasp(spawn_turf)

/datum/status_effect/necropolis_curse/proc/grasp(turf/spawn_turf)
	set waitfor = FALSE
	new/obj/effect/temp_visual/dir_setting/curse/grasp_portal(spawn_turf, owner.dir)
	playsound(spawn_turf, 'sound/effects/curse2.ogg', 80, 1, -1)
	var/turf/ownerloc = get_turf(owner)
	var/obj/projectile/curse_hand/C = new (spawn_turf)
	C.preparePixelProjectile(ownerloc, spawn_turf)
	C.fire()

/obj/effect/temp_visual/curse
	icon_state = "curse"

/obj/effect/temp_visual/curse/Initialize(mapload)
	. = ..()
	deltimer(timerid)

/datum/status_effect/gonbolaPacify
	id = "gonbolaPacify"
	status_type = STATUS_EFFECT_MULTIPLE
	tick_interval = -1
	alert_type = null

/datum/status_effect/gonbolaPacify/on_apply()
	ADD_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	ADD_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	ADD_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")
	to_chat(owner, "<span class='notice'>You suddenly feel at peace and feel no need to make any sudden or rash actions.</span>")
	return ..()

/datum/status_effect/gonbolaPacify/on_remove()
	REMOVE_TRAIT(owner, TRAIT_PACIFISM, "gonbolaPacify")
	REMOVE_TRAIT(owner, TRAIT_MUTE, "gonbolaMute")
	REMOVE_TRAIT(owner, TRAIT_JOLLY, "gonbolaJolly")

/datum/status_effect/trance
	id = "trance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 300
	tick_interval = 10
	examine_text = "<span class='warning'>SUBJECTPRONOUN seems slow and unfocused.</span>"
	alert_type = /atom/movable/screen/alert/status_effect/trance
	var/stun = TRUE
	var/hypnosis_type = /datum/brain_trauma/hypnosis

/atom/movable/screen/alert/status_effect/trance
	name = "Trance"
	desc = "Everything feels so distant, and you can feel your thoughts forming loops inside your head."
	icon_state = "high"

/datum/status_effect/trance/tick()
	if(stun)
		owner.Stun(60, TRUE, TRUE)
	owner.dizziness = 20

/datum/status_effect/trance/on_apply()
	if(!iscarbon(owner))
		return FALSE
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(hypnotize))
	ADD_TRAIT(owner, TRAIT_MUTE, "trance")
	if(!owner.has_quirk(/datum/quirk/monochromatic))
		owner.add_client_colour(/datum/client_colour/monochrome)
	owner.visible_message("[stun ? "<span class='warning'>[owner] stands still as [owner.p_their()] eyes seem to focus on a distant point.</span>" : ""]", \
	"<span class='warning'>[pick("You feel your thoughts slow down.", "You suddenly feel extremely dizzy.", "You feel like you're in the middle of a dream.","You feel incredibly relaxed.")]</span>")
	return TRUE

/datum/status_effect/trance/on_creation(mob/living/new_owner, _duration, _stun = TRUE)
	duration = _duration
	stun = _stun
	return ..()

/datum/status_effect/trance/on_remove()
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)
	REMOVE_TRAIT(owner, TRAIT_MUTE, "trance")
	owner.dizziness = 0
	if(!owner.has_quirk(/datum/quirk/monochromatic))
		owner.remove_client_colour(/datum/client_colour/monochrome)
	to_chat(owner, "<span class='warning'>You snap out of your trance!</span>")

/datum/status_effect/trance/proc/hypnotize(datum/source, list/hearing_args, list/spans, list/message_mods = list())
	SIGNAL_HANDLER

	if(!owner.can_hear())
		return
	if(hearing_args[HEARING_SPEAKER] == owner)
		return
	var/mob/living/carbon/C = owner
	C.cure_trauma_type(/datum/brain_trauma/hypnosis, TRAUMA_RESILIENCE_SURGERY) //clear previous hypnosis
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living/carbon, gain_trauma), hypnosis_type, TRAUMA_RESILIENCE_SURGERY, hearing_args[HEARING_RAW_MESSAGE]), 10)
	addtimer(CALLBACK(C, TYPE_PROC_REF(/mob/living, Stun), 60, TRUE, TRUE), 15) //Take some time to think about it
	qdel(src)

/// "Hardened" trance variant, used by hypnoflashes.
/// Only difference is the resulting trauma can't be cured via nanites.
/datum/status_effect/trance/hardened
	hypnosis_type = /datum/brain_trauma/hypnosis/hardened

/datum/status_effect/spasms
	id = "spasms"
	status_type = STATUS_EFFECT_MULTIPLE
	alert_type = null

/datum/status_effect/spasms/tick()
	if(prob(15))
		switch(rand(1,5))
			if(1)
				if((owner.mobility_flags & MOBILITY_MOVE) && isturf(owner.loc))
					to_chat(owner, "<span class='warning'>Your leg spasms!</span>")
					step(owner, pick(GLOB.cardinals))
			if(2)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				if(I)
					to_chat(owner, "<span class='warning'>Your fingers spasm!</span>")
					owner.log_message("used [I] due to a Muscle Spasm", LOG_ATTACK)
					I.attack_self(owner)
			if(3)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM

				var/range = 1
				if(istype(owner.get_active_held_item(), /obj/item/gun)) //get targets to shoot at
					range = 7

				var/list/mob/living/targets = list()
				for(var/mob/living/M in oview(range, owner))
					targets += M
				if(LAZYLEN(targets))
					to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
					owner.log_message(" attacked someone due to a Muscle Spasm", LOG_ATTACK) //the following attack will log itself
					owner.ClickOn(pick(targets))
				owner.a_intent = prev_intent
			if(4)
				var/prev_intent = owner.a_intent
				owner.a_intent = INTENT_HARM
				to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
				owner.log_message("attacked [owner.p_them()]self to a Muscle Spasm", LOG_ATTACK)
				owner.ClickOn(owner)
				owner.a_intent = prev_intent
			if(5)
				if(owner.incapacitated())
					return
				var/obj/item/I = owner.get_active_held_item()
				var/list/turf/targets = list()
				for(var/turf/T in oview(3, get_turf(owner)))
					targets += T
				if(LAZYLEN(targets) && I)
					to_chat(owner, "<span class='warning'>Your arm spasms!</span>")
					owner.log_message("threw [I] due to a Muscle Spasm", LOG_ATTACK)
					owner.throw_item(pick(targets))

/datum/status_effect/convulsing
	id = "convulsing"
	duration = 	150
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/convulsing

/datum/status_effect/convulsing/on_creation(mob/living/zappy_boy)
	. = ..()
	to_chat(zappy_boy, "<span class='boldwarning'>You feel a shock moving through your body! Your hands start shaking!</span>")

/datum/status_effect/convulsing/tick()
	var/mob/living/carbon/H = owner
	if(prob(40))
		var/obj/item/I = H.get_active_held_item()
		if(I && H.dropItemToGround(I))
			H.visible_message("<span class='notice'>[H]'s hand convulses, and they drop their [I.name]!</span>","<span class='userdanger'>Your hand convulses violently, and you drop what you were holding!</span>")
			H.jitteriness += 5

/atom/movable/screen/alert/status_effect/convulsing
	name = "Shaky Hands"
	desc = "You've been zapped with something and your hands can't stop shaking! You can't seem to hold on to anything."
	icon_state = "convulsing"

/datum/status_effect/dna_melt
	id = "dna_melt"
	duration = 600
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/dna_melt
	var/kill_either_way = FALSE //no amount of removing mutations is gonna save you now

/datum/status_effect/dna_melt/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	to_chat(new_owner, "<span class='boldwarning'>My body can't handle the mutations! I need to get my mutations removed fast!</span>")

/datum/status_effect/dna_melt/on_remove()
	if(!owner.has_dna())
		owner.gib() //fuck you in particular
		return
	var/mob/living/carbon/C = owner
	C.something_horrible(kill_either_way)

/atom/movable/screen/alert/status_effect/dna_melt
	name = "Genetic Breakdown"
	desc = "I don't feel so good. Your body can't handle the mutations! You have one minute to remove your mutations, or you will be met with a horrible fate."
	icon_state = "dna_melt"

/datum/status_effect/go_away
	id = "go_away"
	duration = 100
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/go_away
	var/direction

/datum/status_effect/go_away/on_creation(mob/living/new_owner, set_duration, updating_canmove)
	. = ..()
	direction = pick(NORTH, SOUTH, EAST, WEST)
	new_owner.setDir(direction)

/datum/status_effect/go_away/tick()
	owner.AdjustStun(1, ignore_canstun = TRUE)
	var/turf/T = get_step(owner, direction)
	owner.forceMove(T)

/atom/movable/screen/alert/status_effect/go_away
	name = "TO THE STARS AND BEYOND!"
	desc = "I must go, my people need me!"
	icon_state = "high"

//Clock cult
/datum/status_effect/interdiction
	id = "interdicted"
	duration = 25
	status_type = STATUS_EFFECT_REFRESH
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/interdiction
	var/running_toggled = FALSE

/datum/status_effect/interdiction/tick()
	if(owner.m_intent == MOVE_INTENT_RUN)
		owner.toggle_move_intent(owner)
		if(owner.confused < 10)
			owner.confused = 10
		running_toggled = TRUE
		to_chat(owner, "<span class='warning'>You know you shouldn't be running here.</span>")
	owner.add_movespeed_modifier(MOVESPEED_ID_INTERDICTION, multiplicative_slowdown=1.5)

/datum/status_effect/interdiction/on_remove()
	owner.remove_movespeed_modifier(MOVESPEED_ID_INTERDICTION)
	if(running_toggled && owner.m_intent == MOVE_INTENT_WALK)
		owner.toggle_move_intent(owner)

/atom/movable/screen/alert/status_effect/interdiction
	name = "Interdicted"
	desc = "I don't think I am meant to go this way."
	icon_state = "inathneqs_endowment"

/datum/status_effect/fake_virus
	id = "fake_virus"
	duration = 1800//3 minutes
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 1
	alert_type = null
	var/msg_stage = 0//so you dont get the most intense messages immediately

/datum/status_effect/fake_virus/tick()
	var/fake_msg = ""
	var/fake_emote = ""
	switch(msg_stage)
		if(0 to 300)
			if(prob(1))
				fake_msg = pick("<span class='warning'>[pick("Your head hurts.", "Your head pounds.")]</span>",
				"<span class='warning'>[pick("You're having difficulty breathing.", "Your breathing becomes heavy.")]</span>",
				"<span class='warning'>[pick("You feel dizzy.", "Your head spins.")]</span>",
				"<span notice='warning'>[pick("You swallow excess mucus.", "You lightly cough.")]</span>",
				"<span class='warning'>[pick("Your head hurts.", "Your mind blanks for a moment.")]</span>",
				"<span class='warning'>[pick("Your throat hurts.", "You clear your throat.")]</span>")
		if(301 to 600)
			if(prob(2))
				fake_msg = pick("<span class='warning'>[pick("Your head hurts a lot.", "Your head pounds incessantly.")]</span>",
				"<span class='warning'>[pick("Your windpipe feels like a straw.", "Your breathing becomes tremendously difficult.")]</span>",
				"<span class='warning'>You feel very [pick("dizzy","woozy","faint")].</span>",
				"<span class='warning'>[pick("You hear a ringing in your ear.", "Your ears pop.")]</span>",
				"<span class='warning'>You nod off for a moment.</span>")
		else
			if(prob(3))
				if(prob(50))// coin flip to throw a message or an emote
					fake_msg = pick("<span class='userdanger'>[pick("Your head hurts!", "You feel a burning knife inside your brain!", "A wave of pain fills your head!")]</span>",
					"<span class='userdanger'>[pick("Your lungs hurt!", "It hurts to breathe!")]</span>",
					"<span class='warning'>[pick("You feel nauseated.", "You feel like you're going to throw up!")]</span>")
				else
					fake_emote = pick("cough", "sniff", "sneeze")

	if(fake_emote)
		owner.emote(fake_emote)
	else if(fake_msg)
		to_chat(owner, fake_msg)

	msg_stage++

/datum/status_effect/heretic_mark
	id = "heretic_mark"
	duration = 15 SECONDS
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	on_remove_on_mob_delete = TRUE
	///underlay used to indicate that someone is marked
	var/mutable_appearance/marked_underlay
	///path for the underlay
	var/effect_icon = 'icons/effects/heretic.dmi'
	/// icon state for the underlay
	var/effect_icon_state = "emark_RING_TEMPLATE"

/datum/status_effect/heretic_mark/on_creation(mob/living/new_owner, ...)
	marked_underlay = mutable_appearance(effect_icon, effect_icon_state,BELOW_MOB_LAYER)
	return ..()

/datum/status_effect/heretic_mark/on_apply()
	if(owner.mob_size >= MOB_SIZE_HUMAN)
		owner.add_overlay(marked_underlay)
		owner.update_overlays()
		return TRUE
	return FALSE

/datum/status_effect/heretic_mark/on_remove()
	owner.update_overlays()
	return ..()

/datum/status_effect/heretic_mark/Destroy()
	if(owner)
		owner.cut_overlay(marked_underlay)
	QDEL_NULL(marked_underlay)
	return ..()

/datum/status_effect/heretic_mark/be_replaced()
	owner.underlays -= marked_underlay //if this is being called, we should have an owner at this point.
	..()

/**
  * What happens when this mark gets poppedd
  *
  * Adds actual functionality to each mark
  */
/datum/status_effect/heretic_mark/proc/on_effect()
	SHOULD_CALL_PARENT(TRUE)

	playsound(owner, 'sound/magic/repulse.ogg', 75, TRUE)
	qdel(src) //what happens when this is procced.

//Each mark has diffrent effects when it is destroyed that combine with the mansus grasp effect.
/datum/status_effect/heretic_mark/flesh
	effect_icon_state = "emark1"

/datum/status_effect/heretic_mark/flesh/on_effect()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/H = owner
	H.bleed_rate += 5
	return ..()

/datum/status_effect/heretic_mark/ash
	id = "ash_mark"
	effect_icon_state = "emark2"
	///Dictates how much damage and stamina loss this mark will cause.
	var/repetitions = 1

/datum/status_effect/heretic_mark/ash/on_creation(mob/living/new_owner, repetition = 5)
	. = ..()
	src.repetitions = min(1,repetition)

/datum/status_effect/heretic_mark/ash/on_effect()
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.adjustStaminaLoss(6 * repetitions)
		carbon_owner.adjustFireLoss(3 * repetitions)
		for(var/mob/living/carbon/victim in ohearers(1,carbon_owner))
			if(IS_HERETIC(victim))
				continue
			victim.apply_status_effect(type,repetitions-1)
			break
	return ..()

/datum/status_effect/heretic_mark/rust
	effect_icon_state = "emark3"

/datum/status_effect/heretic_mark/rust/on_effect()
	if(!iscarbon(owner))
		return
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		var/static/list/organs_to_damage = list(
			ORGAN_SLOT_BRAIN,
			ORGAN_SLOT_EARS,
			ORGAN_SLOT_EYES,
			ORGAN_SLOT_LIVER,
			ORGAN_SLOT_LUNGS,
			ORGAN_SLOT_STOMACH,
			ORGAN_SLOT_HEART,
		)

		// Roughly 75% of their organs will take a bit of damage
		for(var/organ_slot in organs_to_damage)
			if(prob(75))
				carbon_owner.adjustOrganLoss(organ_slot, 20)

		// And roughly 75% of their items will take a smack, too
		for(var/obj/item/thing in carbon_owner.get_all_gear())
			if(!QDELETED(thing) && prob(75))
				thing.take_damage(100)
	return ..()

/datum/status_effect/corrosion_curse
	id = "corrosion_curse"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	tick_interval = 4 SECONDS

/datum/status_effect/corrosion_curse/on_creation(mob/living/new_owner, ...)
	. = ..()
	to_chat(owner, "<span class='userdanger'>Your body starts to break apart!</span>")

/datum/status_effect/corrosion_curse/tick()
	. = ..()
	if(!ishuman(owner))
		return
	var/mob/living/carbon/human/human_owner = owner
	if (human_owner.IsSleeping())
		return
	var/chance = rand(0,100)
	var/message = "Coder did fucky wucky U w U"
	switch(chance)
		if(0 to 10)
			message = "<span class='warning'>You feel a lump build up in your throat.</span>"
			human_owner.vomit()
		if(20 to 30)
			message = "<span class='warning'>You feel feel very well.</span>"
			human_owner.Dizzy(50)
			human_owner.Jitter(50)
		if(30 to 40)
			message = "<span class='warning'>You feel a sharp sting in your side.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_LIVER, 5)
		if(40 to 50)
			message = "<span class='warning'>You feel pricking around your heart.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_HEART, 5, 90)
		if(50 to 60)
			message = "<span class='warning'>You feel your stomach churning.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_STOMACH, 5)
		if(60 to 70)
			message = "<span class='warning'>Your eyes feel like they're on fire.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_EYES, 10)
		if(70 to 80)
			message = "<span class='warning'>You hear ringing in your hears.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_EARS, 10)
		if(80 to 90)
			message = "<span class='warning'>Your ribcage feels tighter.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_LUNGS, 10)
		if(90 to 100)
			message = "<span class='warning'>You feel your skull pressing down on your brain.</span>"
			human_owner.adjustOrganLoss(ORGAN_SLOT_BRAIN, 20, 190)
	if(prob(33)) //so the victim isn't spammed with messages every 3 seconds
		to_chat(human_owner,message)

/datum/status_effect/ghoul
	id = "ghoul"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	examine_text = "<span class='warning'>SUBJECTPRONOUN has a blank, catatonic like stare.</span>"
	alert_type = /atom/movable/screen/alert/status_effect/ghoul

/datum/status_effect/ghoul/get_examine_text()
	var/mob/living/carbon/human/H = owner
	var/obscured = H.check_obscured_slots()
	if(!(obscured & ITEM_SLOT_EYES) && !H.glasses) //The examine text is only displayed if the ghoul's eyes are not obscured
		return examine_text

/atom/movable/screen/alert/status_effect/ghoul
	name = "Flesh Servant"
	desc = "You are a Ghoul! A eldritch monster reanimated to serve its master."
	icon_state = "mind_control"

/datum/status_effect/spanish
	id = "spanish"
	duration = 120 SECONDS
	alert_type = null

/datum/status_effect/spanish/on_apply(mob/living/new_owner, ...)
	. = ..()
	to_chat(owner, "<span class='warning'>Alert: Vocal cords are malfunctioning.</span>")
	owner.add_blocked_language(subtypesof(/datum/language/) - /datum/language/uncommon, LANGUAGE_EMP)
	owner.grant_language(/datum/language/uncommon, FALSE, TRUE, LANGUAGE_EMP)

/datum/status_effect/spanish/on_remove()
	owner.remove_blocked_language(subtypesof(/datum/language/), LANGUAGE_EMP)
	owner.remove_language(/datum/language/uncommon, TRUE, TRUE, LANGUAGE_EMP)
	to_chat(owner, "<span class='warning'>Alert: Vocal cords restored to normal function.</span>")
	return ..()

/datum/status_effect/ipc/emp
	id = "ipc_emp"
	examine_text = "<span class='warning'>SUBJECTPRONOUN is buzzing and twitching!</span>"
	duration = 120 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/emp
	status_type = STATUS_EFFECT_REFRESH
/atom/movable/screen/alert/status_effect/emp
	name = "Electro-Magnetic Pulse"
	desc = "You've been hit with an EMP! You're malfunctioning!"
	icon_state = "hypnosis"

/datum/status_effect/slimegrub
	id = "grub_infection"
	duration = 60 SECONDS //a redgrub infestation in a slime
	status_type = STATUS_EFFECT_UNIQUE
	tick_interval = 1
	alert_type = /atom/movable/screen/alert/status_effect/grub
	var/adult = FALSE
	var/spawnbonus = 0
	var/deathcounter = 300
	var/list/diseases = list()

/datum/status_effect/slimegrub/on_apply(mob/living/new_owner, ...)
	. = ..()
	if(isslime(new_owner))
		var/mob/living/simple_animal/slime/S = new_owner
		if(S.is_adult)
			adult = TRUE
			duration = world.time + 120 SECONDS
			if(S.amount_grown >= 9)
				S.amount_grown = 8 //can't split or evolve
		deathcounter = (300 + (300 * adult))

/datum/status_effect/slimegrub/tick()
	if(isslime(owner))
		var/mob/living/simple_animal/slime/S = owner
		if(S.amount_grown >= 9)
			S.amount_grown = 8
		if((S.reagents.has_reagent(/datum/reagent/consumable/capsaicin) || S.bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT)) //redgrubs don't like heat. heating them up for too long kills them
			if(prob(10))
				qdel(src)
		else //don't tick while being cured
			deathcounter -= 2
			if(deathcounter <= 0)
				var/spawns = rand(1, 3 + (adult * 3))
				for(var/I in 1 to (spawns + spawnbonus))
					var/mob/living/simple_animal/hostile/redgrub/grub = new(S.loc)
					grub.grubdisease = diseases
					grub.food += 15
				playsound(S, 'sound/effects/attackblob.ogg', 60, 1)
				S.visible_message("<span class='warning'>[S] is eaten from the inside by [spawns] red grubs, leaving no trace!</span>")
				S.gib()
	else
		qdel(src)//no effect on nonslimes

/atom/movable/screen/alert/status_effect/grub
	name = "Infected"
	desc = "You have a redgrub infection, and can't reproduce or grow! If you don't find a source of heat, you will die!"
	icon_state = "grub"

/datum/status_effect/heretic_mark/void
	effect_icon_state = "emark4"

/datum/status_effect/heretic_mark/void/on_effect()
	var/turf/open/turfie = get_turf(owner)
	turfie.TakeTemperature(-40)
	owner.adjust_bodytemperature(-20)
	if(iscarbon(owner))
		var/mob/living/carbon/carbon_owner = owner
		carbon_owner.silent += 4
	return ..()

/datum/status_effect/amok
	id = "amok"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	duration = 10 SECONDS
	tick_interval = 1 SECONDS

/datum/status_effect/amok/on_apply(mob/living/afflicted)
	. = ..()
	to_chat(owner, "<span class='boldwarning'>You feel filled with a rage that is not your own!</span>")

/datum/status_effect/amok/tick()
	. = ..()
	var/prev_intent = owner.a_intent
	owner.a_intent = INTENT_HARM

	var/list/mob/living/targets = list()
	for(var/mob/living/potential_target in oview(owner, 1))
		if(IS_HERETIC(potential_target) || potential_target.mind?.has_antag_datum(/datum/antagonist/heretic_monster))
			continue
		targets += potential_target
	if(LAZYLEN(targets))
		owner.log_message(" attacked someone due to the amok debuff.", LOG_ATTACK) //the following attack will log itself
		owner.ClickOn(pick(targets))
	owner.a_intent = prev_intent

/datum/status_effect/cloudstruck
	id = "cloudstruck"
	status_type = STATUS_EFFECT_REPLACE
	duration = 3 SECONDS
	on_remove_on_mob_delete = TRUE
	///This overlay is applied to the owner for the duration of the effect.
	var/mutable_appearance/mob_overlay

/datum/status_effect/cloudstruck/on_creation(mob/living/new_owner, set_duration)
	if(isnum(set_duration))
		duration = set_duration
	. = ..()

/datum/status_effect/cloudstruck/on_apply()
	mob_overlay = mutable_appearance('icons/effects/heretic.dmi', "cloud_swirl", ABOVE_MOB_LAYER)
	owner.overlays += mob_overlay
	owner.update_icon()
	ADD_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	return TRUE

/datum/status_effect/cloudstruck/on_remove()
	. = ..()
	if(QDELETED(owner))
		return
	REMOVE_TRAIT(owner, TRAIT_BLIND, "cloudstruck")
	if(owner)
		owner.overlays -= mob_overlay
		owner.update_icon()

/datum/status_effect/cloudstruck/Destroy()
	. = ..()
	QDEL_NULL(mob_overlay)

/datum/status_effect/smoke
	id = "smoke"
	duration = -1
	tick_interval = 10
	status_type = STATUS_EFFECT_REFRESH
	alert_type = /atom/movable/screen/alert/status_effect/smoke

/datum/status_effect/smoke/on_apply()
	owner.add_movespeed_modifier(MOVESPEED_ID_SMOKE, multiplicative_slowdown=1.5)
	RegisterSignal(owner, COMSIG_MOVABLE_MOVED, PROC_REF(check_deletion))
	return TRUE

/datum/status_effect/smoke/on_remove()
	owner.remove_movespeed_modifier(MOVESPEED_ID_SMOKE)

/datum/status_effect/smoke/tick()
	check_deletion()

/datum/status_effect/smoke/proc/check_deletion()
	SIGNAL_HANDLER
	var/turf/location = get_turf(owner)
	if (!(locate(/obj/effect/particle_effect/smoke) in location))
		qdel(src)

/atom/movable/screen/alert/status_effect/smoke
	name = "Smoke"
	desc = "There is a thick cloud of smoke here, breathing it could have consequences!"
	icon_state = "smoke"

/datum/status_effect/ling_transformation
	id = "ling_transformation"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = null
	/// The DNA that the status effect transforms the target into.
	var/datum/dna/target_dna
	/// The target's original DNA, which will be restored upon 'curing' them.
	var/datum/dna/original_dna
	/// How much "charge" the transformation has left. It's randomly set upon creation,
	/// and ticks down every second if there's mutadone in the target's system.
	var/charge_left
	/// Whether the transformation has already been applied or not (i.e is this a new transformation, or an old one being transferred?)
	var/already_applied = FALSE

/datum/status_effect/ling_transformation/on_creation(mob/living/new_owner, datum/dna/target_dna, datum/dna/original_dna, already_applied = FALSE)
	if(!iscarbon(new_owner) || QDELETED(target_dna))
		qdel(src)
		return
	src.target_dna = new target_dna.type
	target_dna.copy_dna(src.target_dna)
	charge_left = rand(45, 90)
	if(original_dna)
		src.original_dna = new original_dna.type
		original_dna.copy_dna(src.original_dna)
	src.already_applied = already_applied
	return ..()

/datum/status_effect/ling_transformation/on_apply()
	. = ..()
	if(!target_dna)
		qdel(src)
		return
	var/mob/living/carbon/carbon_owner = owner
	if(original_dna?.compare_dna(target_dna)) // Cleanly handle someone being transform stung back into their original identity
		qdel(src)
		return
	else if(!original_dna)
		original_dna = new carbon_owner.dna.type
		carbon_owner.dna.copy_dna(original_dna)
	RegisterSignal(owner, COMSIG_CARBON_TRANSFORMED, PROC_REF(on_transformation))
	if(!already_applied)
		apply_dna(target_dna)
		to_chat(owner, "<span class='warning'>You don't feel like yourself anymore...</span>")

/datum/status_effect/ling_transformation/on_remove()
	. = ..()
	if(QDELETED(owner) || !original_dna)
		return
	apply_dna(original_dna)
	to_chat(owner, "<span class='notice'>You feel like yourself again!</span>")
	UnregisterSignal(owner, COMSIG_CARBON_TRANSFORMED)

/datum/status_effect/ling_transformation/tick()
	. = ..()
	if(owner.reagents.has_reagent(/datum/reagent/medicine/clonexadone))
		charge_left--
		if(prob(4))
			to_chat(owner, "<span class='notice'>You begin to feel slightly more like yourself...</span>")
	if(charge_left <= 0)
		qdel(src)

/datum/status_effect/ling_transformation/proc/apply_dna(datum/dna/dna)
	var/mob/living/carbon/carbon_owner = owner
	if(!carbon_owner || !istype(carbon_owner))
		return
	dna.transfer_identity(carbon_owner, transfer_SE = TRUE)
	carbon_owner.real_name = carbon_owner.dna.real_name
	carbon_owner.updateappearance(mutcolor_update = TRUE)
	carbon_owner.domutcheck()

/datum/status_effect/ling_transformation/proc/on_transformation(mob/living/carbon/source, mob/living/carbon/new_body)
	SIGNAL_HANDLER
	if(!istype(source) || !istype(new_body))
		return
	var/datum/status_effect/ling_transformation/new_effect = new_body.apply_status_effect(/datum/status_effect/ling_transformation, target_dna, original_dna, TRUE)
	if(new_effect)
		new_effect.charge_left = charge_left
