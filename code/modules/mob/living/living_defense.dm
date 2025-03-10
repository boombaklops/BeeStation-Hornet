/// Runs an armour check against a mob and returns the armour value to use.
/// 0 represents 0% protection, while 100 represents 100% protection.
/// The return value for this proc can be negative, indicating that the damage values should be increased.
/// A message will be thrown to the user if their armour protects them, unless the silent flag is set.
/mob/living/proc/run_armor_check(def_zone = null, attack_flag = MELEE, absorb_text = null, soften_text = null, armour_penetration, penetrated_text, silent=FALSE)
	var/armor = getarmor(def_zone, attack_flag, penetration = armour_penetration)

	if(armor <= 0)
		return armor

	// This equation will reach a max value of 75
	armor = STANDARDISE_ARMOUR(armor)

	if(silent)
		return armor

	//the if "armor" check is because this is used for everything on /living, including humans
	if(armour_penetration)
		if(penetrated_text)
			to_chat(src, "<span class='userdanger'>[penetrated_text]</span>")
		else
			to_chat(src, "<span class='userdanger'>Your armor was penetrated!</span>")
	else if(armor >= 100)
		if(absorb_text)
			to_chat(src, "<span class='notice'>[absorb_text]</span>")
		else
			to_chat(src, "<span class='notice'>Your armor absorbs the blow!</span>")
	else
		if(soften_text)
			to_chat(src, "<span class='warning'>[soften_text]</span>")
		else
			to_chat(src, "<span class='warning'>Your armor softens the blow!</span>")
	return armor

/// Get the armour value for a specific damage type, targetting a particular zone.
/// def_zone: The body zone to get the armour for. Null indicates no body zone and will calculate an average armour value instead.
/// type: The damage type to test for. Must not be null.
/// penetration: The amount of penetration to add. A value of 20 will reduce the effectiveness of each individual armour piece by 80%.
/// Returns: An integer value with 0 representing 0% protection and 100 representing 100% protection.
/// - The return value can be negative which indicates additional armour, but will never exceed 100.
/// - Armour penetration should not be applied on the return value of this proc, due to its upper bound of 100.
/mob/living/proc/getarmor(def_zone, type, penetration = 0)
	return 0

//this returns the mob's protection against eye damage (number between -1 and 2) from bright lights
/mob/living/proc/get_eye_protection()
	return 0

//this returns the mob's protection against ear damage (0:no protection; 1: some ear protection; 2: has no ears)
/mob/living/proc/get_ear_protection()
	return 0

/mob/living/proc/is_mouth_covered(head_only = 0, mask_only = 0)
	return FALSE

/mob/living/proc/is_eyes_covered(check_glasses = 1, check_head = 1, check_mask = 1)
	return FALSE

/mob/living/proc/on_hit(obj/projectile/P)
	return BULLET_ACT_HIT

/mob/living/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	SEND_SIGNAL(src, COMSIG_ATOM_BULLET_ACT, P, def_zone)
	var/armor = run_armor_check(def_zone, P.armor_flag, "","",P.armour_penetration)
	if(!P.nodamage)
		apply_damage(P.damage, P.damage_type, def_zone, armor)
		if(P.dismemberment)
			check_projectile_dismemberment(P, def_zone)
	return P.on_hit(src, armor, piercing_hit)? BULLET_ACT_HIT : BULLET_ACT_BLOCK

/mob/living/proc/check_projectile_dismemberment(obj/projectile/P, def_zone)
	return 0

/obj/item/proc/get_volume_by_throwforce_and_or_w_class()
		if(throwforce && w_class)
				return CLAMP((throwforce + w_class) * 5, 30, 100)// Add the item's throwforce to its weight class and multiply by 5, then clamp the value between 30 and 100
		else if(w_class)
				return CLAMP(w_class * 8, 20, 100) // Multiply the item's weight class by 8, then clamp the value between 20 and 100
		else
				return 0

/mob/living/hitby(atom/movable/AM, skipcatch, hitpush = TRUE, blocked = FALSE, datum/thrownthing/throwingdatum)
	if(istype(AM, /obj/item))
		var/obj/item/I = AM
		var/zone = ran_zone(BODY_ZONE_CHEST, 65)//Hits a random part of the body, geared towards the chest
		var/dtype = BRUTE
		var/volume = I.get_volume_by_throwforce_and_or_w_class()
		var/nosell_hit = SEND_SIGNAL(I, COMSIG_MOVABLE_IMPACT_ZONE, src, zone, throwingdatum) // TODO: find a better way to handle hitpush and skipcatch for humans
		if(nosell_hit)
			skipcatch = TRUE
			hitpush = FALSE

		if(blocked)
			return TRUE

		if (I.throwforce > 0) //If the weapon's throwforce is greater than zero...
			if (I.throwhitsound) //...and throwhitsound is defined...
				playsound(loc, I.throwhitsound, volume, 1, -1) //...play the weapon's throwhitsound.
			else if(I.hitsound) //Otherwise, if the weapon's hitsound is defined...
				playsound(loc, I.hitsound, volume, 1, -1) //...play the weapon's hitsound.
			else if(!I.throwhitsound) //Otherwise, if throwhitsound isn't defined...
				playsound(loc, 'sound/weapons/genhit.ogg',volume, 1, -1) //...play genhit.ogg.

		else if(!I.throwhitsound && I.throwforce > 0) //Otherwise, if the item doesn't have a throwhitsound and has a throwforce greater than zero...
			playsound(loc, 'sound/weapons/genhit.ogg', volume, 1, -1)//...play genhit.ogg
		if(!I.throwforce)// Otherwise, if the item's throwforce is 0...
			playsound(loc, 'sound/weapons/throwtap.ogg', 1, volume, -1)//...play throwtap.ogg.
		if(!blocked)
			visible_message("<span class='danger'>[src] is hit by [I]!</span>", \
							"<span class='userdanger'>You're hit by [I]!</span>")
			var/armor = run_armor_check(zone, MELEE, "Your armor has protected your [parse_zone(zone)].", "Your armor has softened hit to your [parse_zone(zone)].",I.armour_penetration)
			apply_damage(I.throwforce, dtype, zone, armor)

			var/mob/thrown_by = I.thrownby?.resolve()
			if(thrown_by)
				log_combat(thrown_by, src, "threw and hit", I)
			if(!incapacitated(FALSE, TRUE)) // physics says it's significantly harder to push someone by constantly chucking random furniture at them if they are down on the floor.
				hitpush = FALSE
		else
			return 1
	else
		playsound(loc, 'sound/weapons/genhit.ogg', 50, 1, -1)
	..(AM, skipcatch, hitpush, blocked, throwingdatum)


/mob/living/mech_melee_attack(obj/mecha/M)
	if(M.occupant.a_intent == INTENT_HARM)
		M.do_attack_animation(src)
		if(M.damtype == BRUTE)
			step_away(src,M,15)
		switch(M.damtype)
			if(BRUTE)
				Knockdown(20)
				take_overall_damage(rand(M.force/2, M.force))
				playsound(src, 'sound/weapons/punch4.ogg', 50, 1)
			if(BURN)
				take_overall_damage(0, rand(M.force/2, M.force))
				playsound(src, 'sound/items/welder.ogg', 50, 1)
			if(TOX)
				M.mech_toxin_damage(src)
			else
				return
		updatehealth()
		visible_message("<span class='danger'>[M.name] hits [src]!</span>", \
						"<span class='userdanger'>[M.name] hits you!</span>", null, COMBAT_MESSAGE_RANGE)
		log_combat(M.occupant, src, "attacked", M, "(INTENT: [uppertext(M.occupant.a_intent)]) (DAMTYPE: [uppertext(M.damtype)])")
	else
		step_away(src,M)
		log_combat(M.occupant, src, "pushed", M)
		visible_message("<span class='warning'>[M] pushes [src] out of the way.</span>", \
						"<span class='warning'>[M] pushes you out of the way.</span>", null, 5)

/mob/living/fire_act()
	adjust_fire_stacks(3)
	IgniteMob()

/mob/living/proc/grabbedby(mob/living/carbon/user, supress_message = FALSE)
	if(user == src || anchored || !isturf(user.loc))
		return FALSE
	if(!user.pulling || user.pulling != src)
		user.start_pulling(src, supress_message = supress_message)
		return

	if(!(status_flags & CANPUSH) || HAS_TRAIT(src, TRAIT_PUSHIMMUNE))
		to_chat(user, "<span class='warning'>[src] can't be grabbed more aggressively!</span>")
		return FALSE

	if(user.grab_state >= GRAB_AGGRESSIVE && HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, "<span class='notice'>You don't want to risk hurting [src]!</span>")
		return FALSE
	grippedby(user)

//proc to upgrade a simple pull into a more aggressive grab.
/mob/living/proc/grippedby(mob/living/carbon/user, instant = FALSE)
	if(user.grab_state < GRAB_KILL)
		user.changeNext_move(CLICK_CD_GRABBING)
		var/sound_to_play = 'sound/weapons/thudswoosh.ogg'
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(H.dna.species.grab_sound)
				sound_to_play = H.dna.species.grab_sound
		playsound(src.loc, sound_to_play, 50, 1, -1)

		if(user.grab_state) //only the first upgrade is instantaneous
			var/old_grab_state = user.grab_state
			var/grab_upgrade_time = instant ? 0 : 30
			visible_message("<span class='danger'>[user] starts to tighten [user.p_their()] grip on [src]!</span>", \
				"<span class='userdanger'>[user] starts to tighten [user.p_their()] grip on you!</span>")
			switch(user.grab_state)
				if(GRAB_AGGRESSIVE)
					log_combat(user, src, "attempted to neck grab", addition="neck grab")
				if(GRAB_NECK)
					log_combat(user, src, "attempted to strangle", addition="kill grab")
			if(!do_after(user, grab_upgrade_time, src))
				return 0
			if(!user.pulling || user.pulling != src || user.grab_state != old_grab_state)
				return 0
			if(user.a_intent != INTENT_GRAB)
				to_chat(user, "<span class='notice'>You must be on grab intent to upgrade your grab further!</span>")
				return 0
		user.setGrabState(user.grab_state + 1)
		switch(user.grab_state)
			if(GRAB_AGGRESSIVE)
				var/add_log = ""
				if(HAS_TRAIT(user, TRAIT_PACIFISM))
					visible_message("<span class='danger'>[user] firmly grips [src]!</span>",
									"<span class='danger'>[user] firmly grips you!</span>")
					add_log = " (pacifist)"
				else
					visible_message("<span class='danger'>[user] grabs [src] aggressively!</span>", \
									"<span class='userdanger'>[user] grabs you aggressively!</span>")
				stop_pulling()
				log_combat(user, src, "grabbed", addition="aggressive grab[add_log]")
			if(GRAB_NECK)
				log_combat(user, src, "grabbed", addition="neck grab")
				visible_message("<span class='danger'>[user] grabs [src] by the neck!</span>",\
								"<span class='userdanger'>[user] grabs you by the neck!</span>")
				update_mobility() //we fall down
				if(!buckled && !density)
					Move(user.loc)
			if(GRAB_KILL)
				log_combat(user, src, "strangled", addition="kill grab")
				visible_message("<span class='danger'>[user] is strangling [src]!</span>", \
								"<span class='userdanger'>[user] is strangling you!</span>")
				update_mobility() //we fall down
				if(!buckled && !density)
					Move(user.loc)
		user.set_pull_offsets(src, grab_state)
		return 1


/mob/living/attack_slime(mob/living/simple_animal/slime/M)
	if(!SSticker.HasRoundStarted())
		to_chat(M, "You cannot attack people before the game has started.")
		return

	if(M.buckled)
		if(M in buckled_mobs)
			M.Feedstop()
		return // can't attack while eating!

	if(HAS_TRAIT(M, TRAIT_PACIFISM))
		to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
		return FALSE

	if(stat != DEAD)
		log_combat(M, src, "attacked")
		M.do_attack_animation(src)
		visible_message("<span class='danger'>\The [M.name] glomps [src]!</span>", \
				"<span class='userdanger'>\The [M.name] glomps you!</span>", null, COMBAT_MESSAGE_RANGE)
		return TRUE

/mob/living/attack_animal(mob/living/simple_animal/M)
	M.face_atom(src)
	if(M.melee_damage == 0)
		visible_message("<span class='notice'>\The [M] [M.friendly] [src]!</span>", \
						"<span class='notice'>\The [M] [M.friendly] you!</span>", null, COMBAT_MESSAGE_RANGE)
		return FALSE
	if(HAS_TRAIT(M, TRAIT_PACIFISM))
		to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
		return FALSE

	if(M.attack_sound)
		playsound(loc, M.attack_sound, 50, 1, 1)
	M.do_attack_animation(src)
	visible_message("<span class='danger'>\The [M] [M.attacktext] [src]!</span>", \
					"<span class='userdanger'>\The [M] [M.attacktext] you!</span>", null, COMBAT_MESSAGE_RANGE)
	log_combat(M, src, "attacked")
	return TRUE


/mob/living/attack_paw(mob/living/carbon/monkey/M)
	if(isturf(loc) && istype(loc.loc, /area/start))
		to_chat(M, "No attacking people at spawn, you jackass.")
		return FALSE

	if (M.a_intent == INTENT_HARM)
		if(HAS_TRAIT(M, TRAIT_PACIFISM))
			to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
			return FALSE

		if(M.is_muzzled() || M.is_mouth_covered(FALSE, TRUE))
			to_chat(M, "<span class='warning'>You can't bite with your mouth covered!</span>")
			return FALSE
		M.do_attack_animation(src, ATTACK_EFFECT_BITE)
		log_combat(M, src, "attacked")
		playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
		visible_message("<span class='danger'>[M.name] bites [src]!</span>", \
						"<span class='userdanger'>[M.name] bites you!</span>", null, COMBAT_MESSAGE_RANGE)
		return TRUE
	return FALSE

/mob/living/attack_larva(mob/living/carbon/alien/larva/L)
	switch(L.a_intent)
		if("help")
			visible_message("<span class='notice'>[L.name] rubs its head against [src].</span>", \
							"<span class='notice'>[L.name] rubs its head against you.</span>")
			return FALSE

		else
			if(HAS_TRAIT(L, TRAIT_PACIFISM))
				to_chat(L, "<span class='notice'>You don't want to hurt anyone!</span>")
				return

			L.do_attack_animation(src)
			if(prob(90))
				log_combat(L, src, "attacked")
				visible_message("<span class='danger'>[L.name] bites [src]!</span>", \
								"<span class='userdanger'>[L.name] bites you!</span>", null, COMBAT_MESSAGE_RANGE)
				playsound(loc, 'sound/weapons/bite.ogg', 50, 1, -1)
				return TRUE
			else
				visible_message("<span class='danger'>[L.name]'s bite misses [src]!</span>", \
								"<span class='userdanger'>[L.name]'s bite misses you!</span>", null, COMBAT_MESSAGE_RANGE)
	return FALSE

/mob/living/attack_alien(mob/living/carbon/alien/humanoid/M)
	SEND_SIGNAL(src, COMSIG_MOB_ATTACK_ALIEN, M)
	switch(M.a_intent)
		if ("help")
			visible_message("<span class='notice'>[M] caresses [src] with its scythe-like arm.</span>", \
				"<span class='notice'>[M] caresses you with its scythe-like arm.</span>")
			return FALSE
		if ("grab")
			grabbedby(M)
			return FALSE
		if("harm")
			if(HAS_TRAIT(M, TRAIT_PACIFISM))
				to_chat(M, "<span class='notice'>You don't want to hurt anyone!</span>")
				return FALSE
			M.do_attack_animation(src)
			return TRUE
		if("disarm")
			M.do_attack_animation(src, ATTACK_EFFECT_DISARM)
			return TRUE

/mob/living/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return
	..()

//Looking for irradiate()? It's been moved to radiation.dm under the rad_act() for mobs.

/mob/living/acid_act(acidpwr, acid_volume)
	take_bodypart_damage(acidpwr * min(1, acid_volume * 0.1))
	return 1

/mob/living/proc/electrocute_act(shock_damage, source, siemens_coeff = 1, safety = 0, tesla_shock = 0, illusion = 0, stun = TRUE)
	SEND_SIGNAL(src, COMSIG_LIVING_ELECTROCUTE_ACT, shock_damage, source, siemens_coeff, safety, tesla_shock, illusion, stun)
	if(tesla_shock && (flags_1 & TESLA_IGNORE_1))
		return FALSE
	if(HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE
	if(shock_damage > 0)
		if(!illusion)
			adjustFireLoss(shock_damage)
		visible_message(
			"<span class='danger'>[src] was shocked by \the [source]!</span>", \
			"<span class='userdanger'>You feel a powerful shock coursing through your body!</span>", \
			"<span class='italics'>You hear a heavy electrical crack.</span>" \
		)
		return shock_damage

/mob/living/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_CONTENTS)
		return
	for(var/obj/O in contents)
		O.emp_act(severity)

/mob/living/singularity_act()
	var/gain = 20


	if (client)
		client.give_award(/datum/award/achievement/misc/singularity_death, client.mob)


	investigate_log("([key_name(src)]) has been consumed by the singularity.", INVESTIGATE_ENGINES) //Oh that's where the clown ended up!
	gib()
	return(gain)

/mob/living/narsie_act()
	if(status_flags & GODMODE || QDELETED(src))
		return
	if(GLOB.cult_narsie && GLOB.cult_narsie.souls_needed[src])
		GLOB.cult_narsie.souls_needed -= src
		GLOB.cult_narsie.souls += 1
		if((GLOB.cult_narsie.souls == GLOB.cult_narsie.soul_goal) && (GLOB.cult_narsie.resolved == FALSE))
			GLOB.cult_narsie.resolved = TRUE
			sound_to_playing_players('sound/machines/alarm.ogg')
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(cult_ending_helper), 1), 120)
			addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ending_helper)), 270)
	if(client)
		makeNewConstruct(/mob/living/simple_animal/hostile/construct/harvester, src, cultoverride = TRUE)
	else
		switch(rand(1, 6))
			if(1)
				new /mob/living/simple_animal/hostile/construct/armored/hostile(get_turf(src))
			if(2)
				new /mob/living/simple_animal/hostile/construct/wraith/hostile(get_turf(src))
			if(3 to 6)
				new /mob/living/simple_animal/hostile/construct/builder/hostile(get_turf(src))
	spawn_dust()
	gib()
	return TRUE


//called when the mob receives a bright flash
/mob/living/proc/flash_act(intensity = 1, override_blindness_check = 0, affect_silicon = 0, visual = 0, type = /atom/movable/screen/fullscreen/flash)
	if(get_eye_protection() < intensity && (override_blindness_check || !is_blind()))
		overlay_fullscreen("flash", type)
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "flash", 25), 25)
		return TRUE
	return FALSE

//called when the mob receives a loud bang
/mob/living/proc/soundbang_act()
	return 0

//to damage the clothes worn by a mob
/mob/living/proc/damage_clothes(damage_amount, damage_type = BRUTE, damage_flag = 0, def_zone)
	return


/mob/living/do_attack_animation(atom/A, visual_effect_icon, obj/item/used_item, no_effect)
	if(!used_item)
		used_item = get_active_held_item()
	..()
	setMovetype(movement_type & ~FLOATING) // If we were without gravity, the bouncing animation got stopped, so we make sure we restart the bouncing after the next movement.

/mob/living/extrapolator_act(mob/user, var/obj/item/extrapolator/E, scan = TRUE)
	if(istype(E) && diseases.len)
		if(scan)
			E.scan(src, diseases, user)
		else
			E.extrapolate(src, diseases, user)
		return TRUE
	else
		return FALSE

/mob/living/proc/sethellbound()
	if(mind)
		mind.hellbound = TRUE
		med_hud_set_status()
		return TRUE
	return FALSE

/mob/living/proc/ishellbound()
	return mind?.hellbound

/mob/living/proc/force_hit_projectile(obj/projectile/projectile)
	return FALSE
