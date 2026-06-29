--!! RISCBLOX-32 ROM LOADER !!--
-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local ROM = {}

local FLASH = require(
	script.Parent.Parent.Parent
		:WaitForChild("BIN")
		:WaitForChild("BIOS")
		:WaitForChild("FLASH")
)

local ROM_BASE = 0x80000000

function ROM.Load(RAM)

	print("[ROM] Loading firmware into memory...")

	for i = 1, #FLASH do

		RAM.write8(
			ROM_BASE + (i - 1),
			string.byte(FLASH, i)
		)

	end

	print(string.format(
		"[ROM] %d bytes copied to 0x%08X",
		#FLASH,
		ROM_BASE
		))

end

return ROM
