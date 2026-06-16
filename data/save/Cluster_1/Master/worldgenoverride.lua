-- =============================================================================
-- Master/worldgenoverride.lua — Overworld generation settings
-- =============================================================================
-- Reference: https://forums.kleientertainment.com/forums/topic/900508-worldgenoverridelua-documentation/
--
-- This file controls how the Overworld is generated. It only takes effect
-- when a NEW world is created (first start, or after deleting the save/
-- directory). Changing it on an existing world does nothing.
--
-- Common override values:
--   "never" / "rare" / "default" / "often" / "always"
--   "none" / "few" / "default" / "many" / "max"
--   "small" / "medium" / "default" / "large" / "huge"
--   "none" / "low" / "default" / "high" / "max"
--
-- Set override_enabled = false to disable all overrides and use defaults.
-- =============================================================================


return {
	override_enabled = true,
	worldgen_preset = "SURVIVAL_TOGETHER",
	settings_preset = "SURVIVAL_TOGETHER",
	overrides = {
		-- World size
		world_size = "huge",

		-- Season / weather
		-- season_start = "default",        -- autumn | winter | spring | summer
		-- spring = "default",
		-- summer = "default",
		-- autumn = "default",
		-- winter = "default",
		-- day = "default",                  -- day segment length

		-- Resources & regrowth
		boons = "often",                     -- skeleton setpieces
		-- flint = "default",
		-- grass = "default",
		-- twigs = "default",
		-- berrybush = "default",
		-- carrots_regrowth = "default",
		-- flowers_regrowth = "default",
		-- evergreen_regrowth = "default",
		-- deciduoustree_regrowth = "default",

		-- Mobs & bosses
		-- deerclops = "default",
		-- bearger = "default",
		-- dragonfly = "default",
		-- beequeen = "default",
		-- klaus = "default",
		-- antliontribute = "default",
		-- crabking = "default",
		-- malbatross = "default",
		-- eyeofterror = "default",

		-- Spiders / hounds / depth worms
		-- spiders = "default",
		-- hounds = "default",
		-- hound_mounds = "default",

		-- Environment
		-- lightning = "default",
		-- frograin = "default",
		-- wildfire = "default",
		-- meteorshowers = "default",

		-- Quality of life
		spawnprotection = "always",          -- prevent spawn-camping
		touchstone = "often",                -- revival points
		ghostsanitydrain = "none",           -- disable sanity drain while ghost
		-- portalresurection = "always",     -- allow unlimited respawn at portal
		-- resettime = "none",               -- disable world reset timer
	},
}
