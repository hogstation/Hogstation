/obj/machinery/atmospherics/components/unary/thermomachine
	icon = 'icons/obj/atmospherics/components/thermomachine.dmi'
	icon_state = "freezer"

	name = "Thermomachine"
	desc = "Heats or cools gas in connected pipes."

	density = TRUE
	max_integrity = 300
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 100, RAD = 100, FIRE = 80, ACID = 30, ELECTRIC = 100)
	layer = OBJ_LAYER
	circuit = /obj/item/circuitboard/machine/thermomachine

	pipe_flags = PIPING_ONE_PER_TURF
	vent_movement = NONE
	quick_toggle = TRUE

	var/icon_state_off = "freezer"
	var/icon_state_on = "freezer_1"
	var/icon_state_open = "freezer-o"

	var/min_temperature = T20C //actual temperature will be defined by RefreshParts() and by the cooling var
	var/max_temperature = T20C //actual temperature will be defined by RefreshParts() and by the cooling var
	var/target_temperature = T20C
	var/heat_capacity = 0
	var/interactive = TRUE // So mapmakers can disable interaction.
	var/cooling = TRUE
	var/base_heating = 140
	var/base_cooling = 170

/obj/machinery/atmospherics/components/unary/thermomachine/Initialize(mapload)
	. = ..()
	initialize_directions = dir
	RefreshParts()
	update_appearance(UPDATE_ICON)

/obj/machinery/atmospherics/components/unary/thermomachine/proc/swap_function()
	cooling = !cooling
	if(cooling)
		icon_state_off = "freezer"
		icon_state_on = "freezer_1"
		icon_state_open = "freezer-o"
	else
		icon_state_off = "heater"
		icon_state_on = "heater_1"
		icon_state_open = "heater-o"
	target_temperature = T20C
	RefreshParts()
	update_appearance(UPDATE_ICON)

/obj/machinery/atmospherics/components/unary/thermomachine/on_construction()
	var/obj/item/circuitboard/machine/thermomachine/board = circuit
	if(board)
		piping_layer = board.pipe_layer
	..(dir, piping_layer)
	return ..(dir, piping_layer)

/obj/machinery/atmospherics/components/unary/thermomachine/RefreshParts()
	var/calculated_bin_rating
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		calculated_bin_rating += bin.rating
	heat_capacity = 5000 * ((calculated_bin_rating - 1) ** 2)
	min_temperature = T20C
	max_temperature = T20C
	if(cooling)
		var/calculated_laser_rating
		for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
			calculated_laser_rating += laser.rating
		min_temperature = max(T0C - (base_cooling + calculated_laser_rating * 15), TCMB) //73.15K with T1 stock parts
	else
		var/calculated_laser_rating
		for(var/obj/item/stock_parts/micro_laser/laser in component_parts)
			calculated_laser_rating += laser.rating
		max_temperature = T20C + (base_heating * calculated_laser_rating) //573.15K with T1 stock parts

/obj/machinery/atmospherics/components/unary/thermomachine/update_icon_state()
	. = ..()
	if(panel_open)
		icon_state = icon_state_open
	else if(on && is_operational())
		icon_state = icon_state_on
	else
		icon_state = icon_state_off

/obj/machinery/atmospherics/components/unary/thermomachine/update_overlays()
	. = ..()
	. += get_pipe_image(icon, "pipe", dir, , piping_layer)

/obj/machinery/atmospherics/components/unary/thermomachine/AltClick(mob/living/user)
	if(!can_interact(user))
		return
	if(cooling)
		target_temperature = min_temperature
		investigate_log("was set to [target_temperature] K by [key_name(user)]", INVESTIGATE_ATMOS)
		balloon_alert(user, "You minimize the target temperature on [src] to [target_temperature] K.")
	else
		target_temperature = max_temperature
		investigate_log("was set to [target_temperature] K by [key_name(user)]", INVESTIGATE_ATMOS)
		balloon_alert(user, "You maximize the target temperature on [src] to [target_temperature] K.d")

/obj/machinery/atmospherics/components/unary/thermomachine/update_layer()
	return

/obj/machinery/atmospherics/components/unary/thermomachine/update_icon_nopipes()
	cut_overlays()
	if(showpipe)
		add_overlay(get_pipe_image(icon, "scrub_cap", initialize_directions))

/obj/machinery/atmospherics/components/unary/thermomachine/examine(mob/user)
	. = ..()
	. += span_notice("The thermostat is set to [target_temperature]K ([(T0C-target_temperature)*-1]C).")
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Efficiency <b>[(heat_capacity/5000)*100]%</b>.")
		. += span_notice("Temperature range <b>[min_temperature]K - [max_temperature]K ([(T0C-min_temperature)*-1]C - [(T0C-max_temperature)*-1]C)</b>.")

/obj/machinery/atmospherics/components/unary/thermomachine/process_atmos()
	if(!on || !nodes[1])
		return
	var/datum/gas_mixture/air_contents = airs[1]

	var/air_heat_capacity = air_contents.heat_capacity()
	var/combined_heat_capacity = heat_capacity + air_heat_capacity
	var/old_temperature = air_contents.return_temperature()

	if(combined_heat_capacity > 0)
		var/combined_energy = heat_capacity * target_temperature + air_heat_capacity * air_contents.return_temperature()
		air_contents.set_temperature(combined_energy/combined_heat_capacity)

	var/temperature_delta= abs(old_temperature - air_contents.return_temperature())
	if(temperature_delta > 1)
		active_power_usage = (heat_capacity * temperature_delta) ** 1.05 / 5 + idle_power_usage
		update_parents()
	else
		active_power_usage = idle_power_usage
	return 1

/obj/machinery/atmospherics/components/unary/thermomachine/attackby(obj/item/I, mob/user, params)
	if(!on)
		if(default_deconstruction_screwdriver(user, icon_state_open, icon_state_off, I))
			change_pipe_connection(panel_open)
			return
	if(default_change_direction_wrench(user, I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/atmospherics/components/unary/thermomachine/default_change_direction_wrench(mob/user, obj/item/I)
	if(!..())
		return FALSE
	set_init_directions()
	update_icon(UPDATE_ICON)
	return TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_status(mob/user)
	if(interactive)
		return ..()
	return UI_CLOSE

/obj/machinery/atmospherics/components/unary/thermomachine/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ThermoMachine", name)
		ui.open()

/obj/machinery/atmospherics/components/unary/thermomachine/ui_data(mob/user)
	var/list/data = list()
	data["on"] = on
	data["cooling"] = cooling

	data["min"] = min_temperature
	data["max"] = max_temperature
	data["target"] = target_temperature
	data["initial"] = initial(target_temperature)

	var/datum/gas_mixture/air1 = airs[1]
	data["temperature"] = air1.return_temperature()
	data["pressure"] = air1.return_pressure()
	return data

/obj/machinery/atmospherics/components/unary/thermomachine/ui_act(action, params)

	if(..())
		return

	switch(action)
		if("power")
			on = !on
			use_power = on ? ACTIVE_POWER_USE : IDLE_POWER_USE
			investigate_log("was turned [on ? "on" : "off"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("cooling")
			swap_function()
			investigate_log("was changed to [cooling ? "cooling" : "heating"] by [key_name(usr)]", INVESTIGATE_ATMOS)
			. = TRUE
		if("target")
			var/target = params["target"]
			var/adjust = text2num(params["adjust"])
			if(target == "input")
				target = input("Set new target ([min_temperature]-[max_temperature] K):", name, target_temperature) as num|null
				if(!isnull(target))
					. = TRUE
			else if(adjust)
				target = target_temperature + adjust
				. = TRUE
			else if(text2num(target) != null)
				target = text2num(target)
				. = TRUE
			if(.)
				target_temperature = clamp(target, min_temperature, max_temperature)
				investigate_log("was set to [target_temperature] K by [key_name(usr)]", INVESTIGATE_ATMOS)

	update_appearance(UPDATE_ICON)

/obj/machinery/atmospherics/components/unary/thermomachine/freezer
	name = "Thermomachine"
	icon_state = MAP_SWITCH("freezer", "freezer_map")
	icon_state_off = "freezer"
	icon_state_on = "freezer_1"
	icon_state_open = "freezer-o"
	cooling = TRUE

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on
	on = TRUE
	icon_state = "freezer_1"

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/Initialize(mapload)
	. = ..()
	if(target_temperature == initial(target_temperature))
		target_temperature = min_temperature

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom
	name = "Thermomachine"

/obj/machinery/atmospherics/components/unary/thermomachine/freezer/on/coldroom/Initialize(mapload)
	. = ..()
	target_temperature = T0C-80
/obj/machinery/atmospherics/components/unary/thermomachine/heater
	name = "Thermomachine"
	icon_state = MAP_SWITCH("heater", "heater_map")
	icon_state_off = "heater"
	icon_state_on = "heater_1"
	icon_state_open = "heater-o"
	cooling = FALSE

/obj/machinery/atmospherics/components/unary/thermomachine/heater/on
	on = TRUE
	icon_state = "heater_1"
