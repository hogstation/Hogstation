/datum/surgery/brain_surgery
	name = "Brain surgery"
	desc = "This procedure cures all severe and basic traumas and reduces brain damage by a large amount. Failing to fix the brain causes hefty brain damage."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "brain"
	steps = list(
	/datum/surgery_step/incise,
	/datum/surgery_step/retract_skin,
	/datum/surgery_step/saw,
	/datum/surgery_step/clamp_bleeders,
	/datum/surgery_step/fix_brain,
	/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_HEAD)

/datum/surgery/brain_surgery/mechanic
	steps = list(/datum/surgery_step/mechanic_open,
				/datum/surgery_step/open_hatch,
				/datum/surgery_step/mechanic_unwrench,
				/datum/surgery_step/prepare_electronics,
				/datum/surgery_step/fix_brain,
				/datum/surgery_step/mechanic_wrench,
				/datum/surgery_step/mechanic_close)
	requires_bodypart_type = BODYPART_ROBOTIC

/datum/surgery/brain_surgery/mechanic/positron
	name = "Positronic Brain Recalibration"
	desc = "Recalibrate a positronic brain, fixing all severe and basic traumas while repairing it significantly. Failing to fix the brain causes further damage." 
	icon = 'icons/obj/assemblies.dmi'
	icon_state = "posibrain-ipc"
	steps = list(/datum/surgery_step/mechanic_open,
				/datum/surgery_step/open_hatch,
				/datum/surgery_step/mechanic_unwrench,
				/datum/surgery_step/prepare_electronics,
				/datum/surgery_step/fix_brain/positron,
				/datum/surgery_step/mechanic_wrench,
				/datum/surgery_step/mechanic_close)
	possible_locs = list(BODY_ZONE_CHEST)

/datum/surgery_step/fix_brain
	name = "fix brain"
	implements = list(TOOL_HEMOSTAT = 85, TOOL_SCREWDRIVER = 35, /obj/item/pen = 15) //don't worry, pouring some alcohol on their open brain will get that chance to 100
	difficulty = EXP_MASTER // do NOT attempt this without experience!
	repeatable = TRUE
	time = 12 SECONDS //long and complicated
	preop_sound = 'sound/surgery/hemostat1.ogg'
	success_sound = 'sound/surgery/hemostat1.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'
	fuckup_damage = 20

/datum/surgery/brain_surgery/can_start(mob/user, mob/living/carbon/target)
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B)
		return FALSE
	return !istype(target.getorganslot(ORGAN_SLOT_BRAIN), /obj/item/organ/brain/positron)

/datum/surgery/brain_surgery/mechanic/positron/can_start(mob/user, mob/living/carbon/target)
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B)
		return FALSE
	return istype(target.getorganslot(ORGAN_SLOT_BRAIN), /obj/item/organ/brain/positron)

/datum/surgery_step/fix_brain/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You begin to fix [target]'s brain..."),
		"[user] begins to fix [target]'s brain.",
		"[user] begins to perform surgery on [target]'s brain.")

/datum/surgery_step/fix_brain/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(target.mind && target.mind.has_antag_datum(/datum/antagonist/brainwashed))
		target.mind.remove_antag_datum(/datum/antagonist/brainwashed)
	target.setOrganLoss(ORGAN_SLOT_BRAIN, target.getOrganLoss(ORGAN_SLOT_BRAIN) - 60)	//we set damage in this case in order to clear the "failing" flag
	target.cure_all_traumas(TRAUMA_RESILIENCE_SURGERY)
	var/msg = "You succeed in fixing [target]'s brain"
	if(target.getOrganLoss(ORGAN_SLOT_BRAIN) > 0)
		msg += ", though it looks like it could be repaired further"
	display_results(user, target, span_notice(msg + "."),
		"[user] successfully fixes [target]'s brain!",
		"[user] completes the surgery on [target]'s brain.")
	return TRUE

/datum/surgery_step/fix_brain/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(target.getorganslot(ORGAN_SLOT_BRAIN))
		display_results(user, target, span_warning("You screw up, causing more damage!"),
			span_warning("[user] screws up, causing brain damage!"),
			"[user] completes the surgery on [target]'s brain.")
		target.adjustOrganLoss(ORGAN_SLOT_BRAIN, 60)
		target.gain_trauma_type(BRAIN_TRAUMA_SEVERE, TRAUMA_RESILIENCE_LOBOTOMY)
	else
		user.visible_message("<span class='warning'>[user] suddenly notices that the brain [user.p_they()] [user.p_were()] working on is not there anymore.", span_warning("You suddenly notice that the brain you were working on is not there anymore."))
	return FALSE

/datum/surgery_step/fix_brain/positron
	name = "recalibrate brain"
	implements = list(TOOL_MULTITOOL = 100, TOOL_SCREWDRIVER = 40, TOOL_HEMOSTAT = 25) //sterilizine doesn't work on IPCs so they get 100% chance, besides it's likely easier than fixing an organic brain
	preop_sound = 'sound/items/tape_flip.ogg'
	success_sound = 'sound/items/taperecorder_close.ogg'
	failure_sound = 'sound/machines/defib_zap.ogg'

/datum/surgery_step/fix_brain/positron/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	. = ..()
	if(. && user.skill_check(SKILL_TECHNICAL, EXP_MASTER)) // not really any chance 
		target.cure_all_traumas(TRAUMA_RESILIENCE_LOBOTOMY)
