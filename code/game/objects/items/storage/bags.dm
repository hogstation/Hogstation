/*
 *	These absorb the functionality of the plant bag, ore satchel, etc.
 *	They use the use_to_pickup, quick_gather, and quick_empty functions
 *	that were already defined in weapon/storage, but which had been
 *	re-implemented in other classes.
 *
 *	Contains:
 *		Trash Bag
 *		Mining Satchel
 *		Plant Bag
 *		Sheet Snatcher
 *		Book Bag
 *      Biowaste Bag
 *
 *	-Sayu
 */

//  Generic non-item
/obj/item/storage/bag
	slot_flags = ITEM_SLOT_BELT

/obj/item/storage/bag/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.allow_quick_gather = TRUE
	STR.allow_quick_empty = TRUE
	STR.display_numerical_stacking = TRUE
	STR.click_gather = TRUE

// -----------------------------
//          Trash bag
// -----------------------------
/obj/item/storage/bag/trash
	name = "trash bag"
	desc = "It's the heavy-duty black polymer kind. Time to take out the trash!"
	icon = 'yogstation/icons/obj/janitor.dmi' // yogs -- Janitor icons
	icon_state = "trashbag"
	item_state = "trashbag"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'

	w_class = WEIGHT_CLASS_BULKY
	var/insertable = TRUE

/obj/item/storage/bag/trash/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.max_combined_w_class = 30
	STR.max_items = 30
	STR.set_holdable(null, list(/obj/item/disk/nuclear))

/obj/item/storage/bag/trash/suicide_act(mob/user)
	user.visible_message(span_suicide("[user] puts [src] over [user.p_their()] head and starts chomping at the insides! Disgusting!"))
	playsound(loc, 'sound/items/eatfood.ogg', 50, 1, -1)
	return (TOXLOSS)

/obj/item/storage/bag/trash/update_icon_state()
	. = ..()
	//yogs start
	if(icon_state == "[initial(icon_state)]_broken")
		return
	//yogs end
	if(contents.len == 0)
		icon_state = "[initial(icon_state)]"
	else if(contents.len < 12)
		icon_state = "[initial(icon_state)]1"
	else if(contents.len < 21)
		icon_state = "[initial(icon_state)]2"
	else
		icon_state = "[initial(icon_state)]3"

/obj/item/storage/bag/trash/cyborg
	insertable = FALSE

/obj/item/storage/bag/trash/proc/janicart_insert(mob/user, obj/structure/janitorialcart/J)
	if(insertable)
		J.put_in_cart(src, user)
		J.mybag=src
		J.update_appearance(UPDATE_ICON)
	else
		to_chat(user, span_warning("You are unable to fit your [name] into the [J.name]."))
		return

/obj/item/storage/bag/trash/bluespace
	name = "trash bag of holding"
	desc = "The latest and greatest in custodial convenience, a trashbag that is capable of holding vast quantities of garbage."
	icon_state = "bluetrashbag"
	item_state = "bluetrashbag"
	lefthand_file = 'icons/mob/inhands/equipment/custodial_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/custodial_righthand.dmi'
	item_flags = NO_MAT_REDEMPTION

/obj/item/storage/bag/trash/bluespace/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 60
	STR.max_items = 60

/obj/item/storage/bag/trash/bluespace/cyborg
	insertable = FALSE

// -----------------------------
//        Mining Satchel
// -----------------------------

/obj/item/storage/bag/ore
	name = "mining satchel"
	desc = "This little bugger can be used to store and transport ores."
	icon = 'icons/obj/mining.dmi'
	icon_state = "satchel"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack
	var/spam_protection = FALSE //If this is TRUE, the holder won't receive any messages when they fail to pick up ore through crossing it
	var/mob/listeningTo

/obj/item/storage/bag/ore/Initialize(mapload)
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.set_holdable(list(/obj/item/stack/ore))
	STR.max_w_class = WEIGHT_CLASS_HUGE
	STR.max_items = 50

/obj/item/storage/bag/ore/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(Pickup_ores))
	listeningTo = user

/obj/item/storage/bag/ore/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

/obj/item/storage/bag/ore/proc/Pickup_ores(mob/living/user)
	var/show_message = FALSE
	var/obj/structure/ore_box/box
	var/mob/living/simple_animal/hostile/mining_drone/drone
	var/turf/tile = user.loc
	if (!isturf(tile))
		return
	if (istype(user.pulling, /obj/structure/ore_box))
		box = user.pulling
	else if (istype(user.pulling, /mob/living/simple_animal/hostile/mining_drone))
		drone = user.pulling

	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/A in tile)
			if (!is_type_in_typecache(A, STR.can_hold))
				continue
			if (box || drone)
				user.transferItemToLoc(A, box || drone)
				show_message = TRUE
			else if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, span_warning("Your [name] is full and can't hold any more!"))
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		if (box)
			user.visible_message(span_notice("[user] offloads the ores beneath [user.p_them()] into [box]."), \
			span_notice("You offload the ores beneath you into your [box]."))
		if (drone)
			user.visible_message(span_notice("[user] offloads the ores beneath [user.p_them()] into [drone]."), \
			span_notice("You offload the ores beneath you into [drone]."))
		else
			user.visible_message(span_notice("[user] scoops up the ores beneath [user.p_them()]."), \
				span_notice("You scoop up the ores beneath you with your [name]."))
	spam_protection = FALSE

/obj/item/storage/bag/ore/cyborg
	name = "cyborg mining satchel"

/obj/item/storage/bag/ore/holding //miners, your messiah has arrived
	name = "mining satchel of holding"
	desc = "A revolution in convenience, this satchel allows for huge amounts of ore storage. It's been outfitted with anti-malfunction safety measures."
	icon_state = "satchel_bspace"

/obj/item/storage/bag/ore/holding/Initialize(mapload)
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_items = INFINITY
	STR.max_combined_w_class = INFINITY

/obj/item/storage/bag/gem
	name = "gem satchel"
	desc = "You thought it would be more like what those cartoon robbers wear."
	icon = 'icons/obj/mining.dmi'
	icon_state = "gem_satchel"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete
	var/spam_protection = FALSE //If this is TRUE, the holder won't receive any messages when they fail to pick up ore through crossing it
	var/mob/listeningTo

/obj/item/storage/bag/gem/Initialize(mapload)
	. = ..()
	var/datum/component/storage/concrete/STR = GetComponent(/datum/component/storage/concrete)
	STR.allow_quick_empty = TRUE
	STR.set_holdable(list(/obj/item/gem))
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 48
	STR.max_items = 48

/obj/item/storage/bag/gem/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(pickup_gems))
	listeningTo = user

/obj/item/storage/bag/gem/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

/obj/item/storage/bag/gem/proc/pickup_gems(mob/living/user)
	var/show_message = FALSE
	var/turf/tile = user.loc
	if (!isturf(tile))
		return
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/A in tile)
			if (!is_type_in_typecache(A, STR.can_hold))
				continue
			else if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, span_warning("Your [name] is full and can't hold any more!"))
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		user.visible_message(span_notice("[user] scoops up the gems beneath [user.p_them()]."), \
		span_notice("You scoop up the gems beneath you with your [name]."))
	spam_protection = FALSE

/obj/item/storage/bag/gem/cyborg
	name = "cyborg gem satchel"
// -----------------------------
//          Plant bag
// -----------------------------

/obj/item/storage/bag/plants
	name = "plant bag"
	icon = 'icons/obj/hydroponics/equipment.dmi'
	icon_state = "plantbag"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/plants/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 100
	STR.max_items = 100
	STR.set_holdable(list(/obj/item/reagent_containers/food/snacks/grown, /obj/item/seeds, /obj/item/grown, /obj/item/reagent_containers/honeycomb))
////////

/obj/item/storage/bag/plants/portaseeder
	name = "portable seed extractor"
	desc = "For the enterprising botanist on the go. Less efficient than the stationary model, it creates one seed per plant."
	icon_state = "portaseeder"

/obj/item/storage/bag/plants/portaseeder/verb/dissolve_contents()
	set name = "Activate Seed Extraction"
	set category = "Object"
	set desc = "Activate to convert your plants into plantable seeds."
	if(usr.incapacitated())
		return
	for(var/obj/item/O in contents)
		seedify(O, 1, null, usr)

// -----------------------------
//        Stack Snatcher
// -----------------------------
// Because it stacks stacks, this doesn't operate normally.
// However, making it a storage/bag allows us to reuse existing code in some places. -Sayu

/obj/item/storage/bag/sheetsnatcher
	name = "stack snatcher"
	desc = "A patented Nanotrasen storage system designed for any kind of stacks. This is geared towards sheets, rods, and tiles."
	icon = 'icons/obj/mining.dmi'
	icon_state = "sheetsnatcher"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_POCKETS
	var/spam_protection = FALSE //If this is TRUE, the holder won't receive any messages when they fail to pick up ore through crossing it
	var/mob/listeningTo

	var/capacity = 500; //the number of sheets it can carry.
	w_class = WEIGHT_CLASS_NORMAL
	component_type = /datum/component/storage/concrete/stack

/obj/item/storage/bag/sheetsnatcher/Initialize(mapload)
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.allow_quick_empty = TRUE
	STR.set_holdable(list(/obj/item/stack/sheet, /obj/item/stack/tile, /obj/item/stack/rods))
	STR.max_items = 500

/obj/item/storage/bag/sheetsnatcher/proc/pickup_sheets(mob/living/user)
	var/show_message = FALSE
	var/turf/tile = user.loc
	if (!isturf(tile))
		return
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	if(STR)
		for(var/A in tile)
			if (!is_type_in_typecache(A, STR.can_hold))
				continue
			else if(SEND_SIGNAL(src, COMSIG_TRY_STORAGE_INSERT, A, user, TRUE))
				show_message = TRUE
			else
				if(!spam_protection)
					to_chat(user, span_warning("Your [name] is full and can't hold any more!"))
					spam_protection = TRUE
					continue
	if(show_message)
		playsound(user, "rustle", 50, TRUE)
		user.visible_message(span_notice("[user] scoops up the sheets beneath [user.p_them()]."), \
		span_notice("You scoop up the sheets beneath you with your [name]."))
	spam_protection = FALSE

/obj/item/storage/bag/sheetsnatcher/equipped(mob/user)
	. = ..()
	if(listeningTo == user)
		return
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(pickup_sheets))
	listeningTo = user

/obj/item/storage/bag/sheetsnatcher/dropped()
	. = ..()
	if(listeningTo)
		UnregisterSignal(listeningTo, COMSIG_MOVABLE_MOVED)
		listeningTo = null

// -----------------------------
//    Stack Snatcher (Cyborg)
// -----------------------------

/obj/item/storage/bag/sheetsnatcher/borg
	name = "stack snatcher 9000"
	desc = ""
	capacity = 1000//Borgs get more because >specialization

/obj/item/storage/bag/sheetsnatcher/borg/Initialize(mapload)
	. = ..()
	var/datum/component/storage/concrete/stack/STR = GetComponent(/datum/component/storage/concrete/stack)
	STR.max_items = 1000

// -----------------------------
//           Book bag
// -----------------------------

/obj/item/storage/bag/books
	name = "book bag"
	desc = "A bag for books."
	icon = 'icons/obj/library.dmi'
	icon_state = "bookbag"
	w_class = WEIGHT_CLASS_BULKY //Bigger than a book because physics
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/books/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_w_class = WEIGHT_CLASS_NORMAL
	STR.max_combined_w_class = 21
	STR.max_items = 7
	STR.display_numerical_stacking = FALSE
	STR.set_holdable(list(/obj/item/book, /obj/item/storage/book, /obj/item/spellbook))

/*
 * Trays - Agouri
 */
/obj/item/storage/bag/tray
	name = "tray"
	icon = 'icons/obj/food/containers.dmi'
	icon_state = "tray"
	desc = "A metal tray to lay food on."
	force = 5
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_BULKY
	flags_1 = CONDUCT_1
	materials = list(/datum/material/iron=3000)

/obj/item/storage/bag/tray/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 8 // Can hold two plates!
	STR.set_holdable(list(
		/obj/item/kitchen,
		/obj/item/plate,
		/obj/item/reagent_containers/food, // Includes drinking glasses, as they are a subtype
		/obj/item/trash
	), list(
		/obj/item/plate/oven_tray
	))
	STR.insert_preposition = "on"

/obj/item/storage/bag/tray/attack(mob/living/M, mob/living/user)
	. = ..()
	// Drop all the things. All of them.
	var/list/obj/item/oldContents = contents.Copy()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.quick_empty()
	// Make each item scatter a bit
	for(var/obj/item/I in oldContents)
		spawn()
			for(var/i = 1, i <= rand(1,2), i++)
				if(I)
					step(I, pick(NORTH,SOUTH,EAST,WEST))
					sleep(rand(0.2 SECONDS, 0.4 SECONDS))

	if(prob(50))
		playsound(M, 'sound/items/trayhit1.ogg', 50, 1)
	else
		playsound(M, 'sound/items/trayhit2.ogg', 50, 1)

	update_appearance(UPDATE_ICON)

/obj/item/storage/bag/tray/update_overlays()
	. = ..()
	for(var/obj/item/I in contents)
		. += new /mutable_appearance(I)

/obj/item/storage/bag/tray/Entered()
	. = ..()
	update_appearance(UPDATE_ICON)

/obj/item/storage/bag/tray/Exited()
	. = ..()
	update_appearance(UPDATE_ICON)

/*
 *	Chemistry bag
 */

/obj/item/storage/bag/chemistry
	name = "chemistry bag"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "bag"
	desc = "A bag for storing pills, patches, and bottles."
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/chemistry/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 50
	STR.max_items = 40
	STR.insert_preposition = "in"
	STR.set_holdable(list(/obj/item/reagent_containers/pill, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/medspray, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/dropper, /obj/item/reagent_containers/autoinjector/medipen, /obj/item/reagent_containers/gummy))

/*
 *  Biowaste bag (mostly for xenobiologists)
 */

/obj/item/storage/bag/bio
	name = "bio bag"
	icon = 'icons/obj/chemical.dmi'
	icon_state = "biobag"
	desc = "A bag for the safe transportation and disposal of biowaste and other biological materials."
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/bio/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 100
	STR.max_items = 25
	STR.insert_preposition = "in"
	STR.set_holdable(list(/obj/item/slime_extract, /obj/item/reagent_containers/syringe, /obj/item/reagent_containers/dropper, /obj/item/reagent_containers/glass/beaker, /obj/item/reagent_containers/glass/bottle, /obj/item/reagent_containers/blood, /obj/item/reagent_containers/food/snacks/deadmouse, /obj/item/reagent_containers/food/snacks/monkeycube, /obj/item/organ, /obj/item/bodypart))

/*
 *  Construction bag (for engineering, holds stock parts and electronics)
 */

/obj/item/storage/bag/construction
	name = "construction bag"
	icon = 'icons/obj/tools.dmi'
	icon_state = "construction_bag"
	desc = "A bag for storing small construction components."
	w_class = WEIGHT_CLASS_SMALL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/construction/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 50
	STR.max_items = 40
	STR.max_w_class = WEIGHT_CLASS_SMALL
	STR.insert_preposition = "in"
	STR.set_holdable(list(/obj/item/stack/ore/bluespace_crystal, /obj/item/assembly, /obj/item/stock_parts, /obj/item/reagent_containers/glass/beaker, /obj/item/stack/cable_coil, /obj/item/circuitboard, /obj/item/electronics, /obj/item/modular_computer, /obj/item/computer_hardware))


/obj/item/storage/bag/construction/admin/full/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 1000
	STR.max_items = 100

/obj/item/storage/bag/construction/admin/full/PopulateContents()
	new /obj/item/stack/cable_coil(src,MAXCOIL,"red")
	for(var/i in 1 to 10)
		new /obj/item/stock_parts/capacitor/quadratic(src)
		new /obj/item/stock_parts/scanning_module/triphasic(src)
		new /obj/item/stock_parts/manipulator/femto(src)
		new /obj/item/stock_parts/micro_laser/quadultra(src)
		new /obj/item/stock_parts/matter_bin/bluespace(src)
		new /obj/item/stock_parts/cell/infinite(src)

/*
 *	Medicinal Pouch, mostly for ashwalkers
 */

/obj/item/storage/bag/medpouch
	name = "medicinal pouch"
	icon = 'icons/obj/storage.dmi'
	icon_state = "pouch"
	desc = "A small pouch for holding plants, poultices, resin, and pestles."
	w_class = WEIGHT_CLASS_NORMAL
	resistance_flags = FLAMMABLE

/obj/item/storage/bag/medpouch/Initialize(mapload)
	. = ..()
	var/datum/component/storage/STR = GetComponent(/datum/component/storage)
	STR.max_combined_w_class = 50
	STR.max_items = 40
	STR.insert_preposition = "in"
	STR.set_holdable(list(/obj/item/reagent_containers/food/snacks/grown, /obj/item/stack/medical/poultice, /obj/item/stack/sheet/ashresin, /obj/item/pestle))
