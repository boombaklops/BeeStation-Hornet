#define EMOTE_AUDIBLE (1<<0)
#define EMOTE_ANIMATED (1<<1)

/datum/emote
	var/key = "" //What calls the emote
	var/key_third_person = "" //This will also call the emote
	var/message = "" //Message displayed when emote is used
	var/message_mime = "" //Message displayed if the user is a mime
	var/message_alien = "" //Message displayed if the user is a grown alien
	var/message_larva = "" //Message displayed if the user is an alien larva
	var/message_robot = "" //Message displayed if the user is a robot
	var/message_AI = "" //Message displayed if the user is an AI
	var/message_monkey = "" //Message displayed if the user is a monkey
	var/message_ipc = "" // Message to display if the user is an IPC
	var/message_insect = "" //Message to display if the user is a moth, apid or flyperson
	var/message_simple = "" //Message to display if the user is a simple_animal
	var/message_param = "" //Message to display if a param was given
	/// Emote flags (EMOTE_AUDIBLE and EMOTE_ANIMATED)
	var/emote_type = 0
	var/restraint_check = FALSE //Checks if the mob is restrained before performing the emote
	var/muzzle_ignore = FALSE //Will only work if the emote is EMOTE_AUDIBLE
	var/list/mob_type_allowed_typecache = /mob //Types that are allowed to use that emote
	var/list/mob_type_blacklist_typecache //Types that are NOT allowed to use that emote
	var/list/mob_type_ignore_stat_typecache
	var/stat_allowed = CONSCIOUS
	/// Sound to play when emote is called
	var/sound
	/// Volume to play the sound at
	var/sound_volume = 50
	/// Whether to vary the pitch of the sound played
	var/vary = FALSE
	var/only_forced_audio = FALSE //can only code call this event instead of the player.

	// Animated emote stuff
	// ~~~~~~~~~~~~~~~~~~~

	/// Animated emotes - Time to flick the overlay for in ticks, use SECONDS defines please.
	var/emote_length
	/// Animated emotes - pixel_x offset
	var/overlay_x_offset = 0
	/// Animated emotes - pixel_y offset
	var/overlay_y_offset = 0
	/// Animated emotes - Icon file for the overlay
	var/icon/overlay_icon = 'icons/effects/overlay_effects.dmi'
	/// Animated emotes - Icon state for the overlay
	var/overlay_icon_state

/datum/emote/New()
	if (ispath(mob_type_allowed_typecache))
		switch (mob_type_allowed_typecache)
			if (/mob)
				mob_type_allowed_typecache = GLOB.typecache_mob
			if (/mob/living)
				mob_type_allowed_typecache = GLOB.typecache_living
			else
				mob_type_allowed_typecache = typecacheof(mob_type_allowed_typecache)
	else
		mob_type_allowed_typecache = typecacheof(mob_type_allowed_typecache)
	mob_type_blacklist_typecache = typecacheof(mob_type_blacklist_typecache)
	mob_type_ignore_stat_typecache = typecacheof(mob_type_ignore_stat_typecache)

/datum/emote/proc/run_emote(mob/user, params, type_override, intentional = FALSE)
	if(!can_run_emote(user, TRUE, intentional))
		return FALSE

	if((emote_type & EMOTE_ANIMATED) && emote_length > 0)
		var/image/I = image(overlay_icon, user, overlay_icon_state, ABOVE_MOB_LAYER, 0, overlay_x_offset, overlay_y_offset)
		flick_overlay_view(I, user, emote_length)

	var/tmp_sound = get_sound(user)
	if(tmp_sound && (!only_forced_audio || !intentional))
		playsound(user, tmp_sound, sound_volume, vary)

	var/msg = select_message_type(user, intentional)
	if(params && message_param)
		msg = select_param(user, params)

	msg = replace_pronoun(user, msg)

	if(isliving(user))
		var/mob/living/L = user
		for(var/obj/item/implant/I in L.implants)
			I.trigger(key, L)

	if(!msg)
		return TRUE

	user.log_message(msg, LOG_EMOTE)

	var/space = should_have_space_before_emote(html_decode(msg)[1]) ? " " : null
	var/end = copytext(msg, length(message))
	if(!(end in list("!", ".", "?", ":", "\"", "-")))
		msg += "."

	var/dchatmsg = "<b>[user]</b>[space][msg]"

	for(var/mob/M in GLOB.dead_mob_list)
		if(!M.client || isnewplayer(M))
			continue
		var/T = get_turf(user)
		if(M.stat == DEAD && M.client && M.client.prefs.read_player_preference(/datum/preference/toggle/chat_ghostsight) && !(M in viewers(T, null)))
			if(user.mind || M.client.prefs.read_player_preference(/datum/preference/toggle/chat_followghostmindless))
				M.show_message("[FOLLOW_LINK(M, user)] [dchatmsg]")
			else
				M.show_message("[dchatmsg]")

	if(emote_type & EMOTE_AUDIBLE)
		user.audible_message(msg, audible_message_flags = list(CHATMESSAGE_EMOTE = TRUE), separation = space)
	else
		user.visible_message(msg, visible_message_flags = list(CHATMESSAGE_EMOTE = TRUE), separation = space)
	return TRUE

/datum/emote/proc/get_sound(mob/living/user)
	return sound //by default just return this var.

/datum/emote/proc/replace_pronoun(mob/user, message)
	if(findtext(message, "their"))
		message = replacetext(message, "their", user.p_their())
	if(findtext(message, "them"))
		message = replacetext(message, "them", user.p_them())
	if(findtext(message, "%s"))
		message = replacetext(message, "%s", user.p_s())
	return message

/datum/emote/proc/select_message_type(mob/user, intentional)
	. = message
	if(!muzzle_ignore && user.is_muzzled() && (emote_type & EMOTE_AUDIBLE))
		return "makes a [pick("strong ", "weak ", "")]noise."
	if(user.mind?.miming && message_mime)
		. = message_mime
	if(isalienadult(user) && message_alien)
		. = message_alien
	else if(islarva(user) && message_larva)
		. = message_larva
	else if(iscyborg(user) && message_robot)
		. = message_robot
	else if(isAI(user) && message_AI)
		. = message_AI
	else if(ismonkey(user) && message_monkey)
		. = message_monkey
	else if(isipc(user) && message_ipc)
		. = message_ipc
	else if((ismoth(user) || isapid(user) || isflyperson(user) || istype(user, /mob/living/simple_animal/mothroach)) && message_insect)
		. = message_insect
	else if(isanimal(user) && message_simple)
		. = message_simple

/datum/emote/proc/select_param(mob/user, params)
	return replacetext(message_param, "%t", params)

/datum/emote/proc/can_run_emote(mob/user, status_check = TRUE, intentional = FALSE)
	. = TRUE
	if(!is_type_in_typecache(user, mob_type_allowed_typecache))
		return FALSE
	if(is_type_in_typecache(user, mob_type_blacklist_typecache))
		return FALSE
	if(status_check && !is_type_in_typecache(user, mob_type_ignore_stat_typecache))
		if(user.stat > stat_allowed)
			if(!intentional)
				return FALSE
			switch(user.stat)
				if(SOFT_CRIT)
					to_chat(user, "<span class='notice'>You cannot [key] while in a critical condition.</span>")
				if(UNCONSCIOUS)
					to_chat(user, "<span class='notice'>You cannot [key] while unconscious.</span>")
				if(DEAD)
					to_chat(user, "<span class='notice'>You cannot [key] while dead.</span>")
			return FALSE
		if(restraint_check)
			if(isliving(user))
				var/mob/living/L = user
				if(L.IsParalyzed() || L.IsStun())
					if(!intentional)
						return FALSE
					to_chat(user, "<span class='notice'>You cannot [key] while stunned.</span>")
					return FALSE
		if(restraint_check && user.restrained())
			if(!intentional)
				return FALSE
			to_chat(user, "<span class='notice'>You cannot [key] while restrained.</span>")
			return FALSE

	if(isliving(user))
		var/mob/living/L = user
		if(HAS_TRAIT(L, TRAIT_EMOTEMUTE))
			return FALSE

/mob/proc/manual_emote(text) //Just override the song and dance
	. = TRUE
	if(stat != CONSCIOUS)
		return

	if(!text)
		CRASH("Someone passed nothing to manual_emote(), fix it")

	log_message(text, LOG_EMOTE)

	var/ghost_text = "<b>[src]</b> [text]"

	var/origin_turf = get_turf(src)
	if(client)
		for(var/mob/ghost as anything in GLOB.dead_mob_list)
			if(!ghost.client || isnewplayer(ghost))
				continue
			if(ghost.client.prefs.read_player_preference(/datum/preference/toggle/chat_ghostsight) && !(ghost in viewers(origin_turf, null)))
				if(mind || ghost.client.prefs.read_player_preference(/datum/preference/toggle/chat_followghostmindless))
					ghost.show_message("[FOLLOW_LINK(ghost, src)] [ghost_text]")
				else
					ghost.show_message("[ghost_text]")

	visible_message(text, visible_message_flags = list(CHATMESSAGE_EMOTE = TRUE))

/**
 * Returns a boolean based on whether or not the string contains a comma or an apostrophe,
 * to be used for emotes to decide whether or not to have a space between the name of the user
 * and the emote.
 *
 * Requires the message to be HTML decoded beforehand. Not doing it here for performance reasons.
 *
 * Returns TRUE if there should be a space, FALSE if there shouldn't.
 */
/proc/should_have_space_before_emote(string)
	var/static/regex/no_spacing_emote_characters = regex(@"(,|')")
	return !no_spacing_emote_characters.Find(string)
