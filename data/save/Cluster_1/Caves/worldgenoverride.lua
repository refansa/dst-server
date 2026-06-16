-- =============================================================================
-- Caves/worldgenoverride.lua — Caves/Underground generation settings
-- =============================================================================
-- Reference: https://forums.kleientertainment.com/forums/topic/900508-worldgenoverridelua-documentation/
--
-- This file controls how the Caves world is generated. The preset MUST be
-- "DST_CAVE" to generate an underground world. Like the Overworld counterpart,
-- this only applies to new worlds (first start or after deleting save/).
-- =============================================================================


return {
	override_enabled = true,
	worldgen_preset = "DST_CAVE",
	settings_preset = "DST_CAVE",
	overrides = {
		-- Below are common cave-specific overrides.
		-- Uncomment and change values as desired.

		-- World size
		-- world_size = "default",          -- small | medium | default | large | huge

		-- Monsters
		-- bats = "default",                -- bat swarm frequency
		-- bunnymen = "default",
		-- fissure = "default",             -- nightmare fissures
		-- lichen = "default",
		-- lightfliers = "default",
		-- monkeys = "default",
		-- mushgnome = "default",
		-- mushtree = "default",
		-- nightmarecreatures = "default",  -- crawling horrors / terrorbeaks
		-- pondfish = "default",
		-- rock = "default",
		-- rocky = "default",
		-- slurtles = "default",
		-- snurtles = "default",
		-- spider_dropper = "default",      -- cave spiders that drop from ceiling
		-- spider_hider = "default",        -- hidden cave spiders

		-- Resources
		-- cave_fern = "default",
		-- cave_pond = "default",
		-- cave_rock = "default",
		-- flint = "default",
		-- grass = "default",
		-- lightbulb = "default",          -- light flowers
		-- marshbush = "default",
		-- reed = "default",
		-- regrowth = "default",
		-- sapling = "default",
		-- twigs = "default",

		-- Rifts / lunar
		-- archive = "default",
		-- brightmarecreatures = "default",
		-- mutated_hounds = "default",
		-- rifts = "default",
	},
}
