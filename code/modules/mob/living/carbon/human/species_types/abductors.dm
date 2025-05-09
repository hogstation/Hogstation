/datum/species/abductor
	name = "Abductor"
	id = SPECIES_ABDUCTOR
	monitor_icon = "question-circle"
	monitor_color = "#d40db9"
	say_mod = "gibbers"
	possible_genders = list(PLURAL)
	species_traits = list(NOBLOOD,NOEYESPRITES)
	inherent_traits = list(TRAIT_VIRUSIMMUNE,TRAIT_NOGUNS,TRAIT_NOHUNGER,TRAIT_NOBREATH,TRAIT_RADIMMUNE,TRAIT_GENELESS)
	mutanttongue = /obj/item/organ/tongue/abductor
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT

/datum/species/abductor/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.show_to(C)

/datum/species/abductor/on_species_loss(mob/living/carbon/C)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.hide_from(C)

/datum/species/abductor/get_butt_sprite()
	return BUTT_SPRITE_GREY
