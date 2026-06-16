-- =============================================================================
-- modoverrides.lua — Enable and configure Workshop mods
-- =============================================================================
-- Reference: https://forums.kleientertainment.com/forums/topic/64552-dedicated-server-settings-guide/
--
-- This file is read by both the Master and Caves shards. Mods listed here
-- must also be set up for download in data/mods/dedicated_server_mods_setup.lua
-- (and have been downloaded via the mod-updater service).
--
-- To find a mod's Workshop ID, look at its Steam Workshop URL:
--   https://steamcommunity.com/sharedfiles/filedetails/?id=378160973
--                                           ^^^^^^^^^
-- The ID is 378160973. Prefix it with "workshop-" as shown below.
--
-- To find configuration_options for a mod, look at its modinfo.lua file
-- for the "configuration_options" table — each entry's "name" and "data"
-- values map to Lua keys and values here.
-- =============================================================================


return {
  -- ── Popular QoL mods (uncomment to enable) ─────────────────────────────

  -- ["workshop-378160973"] = {    -- Global Positions
  --   enabled = true,
  --   configuration_options = {
  --     SHOWFIREICONS = true,
  --     SHAREMINIMAPPROGRESS = true,
  --   },
  -- },

  -- ["workshop-375859599"] = {    -- Health Info
  --   enabled = true,
  -- },

  -- ["workshop-376333686"] = {    -- Combined Status
  --   enabled = true,
  -- },

  -- ["workshop-351325790"] = {    -- Geometric Placement
  --   enabled = true,
  -- },
}
