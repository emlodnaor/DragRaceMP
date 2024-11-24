-- This Source Code Form is subject to the terms of the bCDDL, v. 1.1.
-- If a copy of the bCDDL was not distributed with this
-- file, You can obtain one at http://beamng.com/bCDDL-1.1.txt

local M = {}

----------------------------
-- Clearing and unloading --
----------------------------

local function unloadAllExtensions()
  extensions.unload('gameplay_drag_display')
  extensions.unload('gameplay_drag_times')
  extensions.unload('gameplay_drag_dragTypes_headsUpDrag')
  extensions.unload('gameplay_drag_dragTypes_dragPracticeRace')
end

local function onUpdate(dtReal, dtSim, dtRaw)
	--nil
end

M.onUpdate = onUpdate

unloadAllExtensions()

return M