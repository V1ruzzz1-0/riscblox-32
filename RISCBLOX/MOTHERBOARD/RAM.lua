--!! MOTHERBOARD SUBCOMPONENT - UNIFIED PHYSICAL RAM !!--
-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local RAM = {}

local RAM_SIZE = 512 * 1024 * 1024
local MemoryBuffer = buffer.create(RAM_SIZE)

RAM.BASE_ADDRESS = 0x80000000
RAM.VRAM_OFFSET = RAM.BASE_ADDRESS + 0x10000
RAM.GPU_VRAM_SIZE = 8 * 1024 * 1024
RAM.GPU_MAX_OFFSET = RAM.VRAM_OFFSET + RAM.GPU_VRAM_SIZE

local function toBufferOffset(address)
	local offset = address - RAM.BASE_ADDRESS
	if offset < 0 or offset >= RAM_SIZE then return nil end
	return offset
end

function RAM.write32(address, value)
	local offset = toBufferOffset(address)
	if offset then buffer.writeu32(MemoryBuffer, offset, value) end
end

function RAM.read32(address)
	local offset = toBufferOffset(address)
	return offset and buffer.readu32(MemoryBuffer, offset) or 0
end

function RAM.write16(address, value)
	local offset = toBufferOffset(address)
	if offset then buffer.writeu16(MemoryBuffer, offset, value) end
end

function RAM.read16(address)
	local offset = toBufferOffset(address)
	return offset and buffer.readu16(MemoryBuffer, offset) or 0
end

function RAM.write8(address, value)
	local offset = toBufferOffset(address)
	if offset then buffer.writeu8(MemoryBuffer, offset, value) end
end

function RAM.read8(address)
	local offset = toBufferOffset(address)
	return offset and buffer.readu8(MemoryBuffer, offset) or 0
end

function RAM.GetSize()
	return RAM_SIZE
end

function RAM.Clear()
	print("[RAM] Clearing volatile memory...")
	MemoryBuffer = buffer.create(RAM_SIZE)
	print("[RAM] Memory cleared.")
end

return RAM
