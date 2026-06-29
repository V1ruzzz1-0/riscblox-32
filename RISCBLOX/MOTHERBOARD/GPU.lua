--!! SoC INTEGRATED COMPONENT - RISCBLOX-32 GPU CO-PROCESSOR !!--
-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local GPU = {}
local RAM = require(script.Parent:WaitForChild("RAM"))

-- Logical framebuffer resolution
local WIDTH = 600
local HEIGHT = 480
local SCALE = 8

local DISPLAY_WIDTH = math.floor(WIDTH / SCALE)
local DISPLAY_HEIGHT = math.floor(HEIGHT / SCALE)

local pixelObjects = {}
local dirtyBlocks = {}

function GPU.Initialize(tty, pixelsGrid)
	table.clear(pixelObjects)
	table.clear(dirtyBlocks)

	pixelsGrid.CellSize = UDim2.new(1 / DISPLAY_WIDTH, 0, 1 / DISPLAY_HEIGHT, 0)

	for y = 0, DISPLAY_HEIGHT - 1 do
		for x = 0, DISPLAY_WIDTH - 1 do
			local pixel = Instance.new("Frame")
			pixel.BorderSizePixel = 0
			pixel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			pixel.Name = string.format("BLOCK_%d_%d", x, y)
			pixel.Parent = tty

			local index = y * DISPLAY_WIDTH + x
			pixelObjects[index] = pixel
		end
	end
	print(string.format("[GPU] Display initialized %dx%d logical / %dx%d physical", WIDTH, HEIGHT, DISPLAY_WIDTH, DISPLAY_HEIGHT))
end

local function decodeRGB565(rgb565)
	local r = bit32.band(bit32.rshift(rgb565, 11), 0x1F) * 8
	local g = bit32.band(bit32.rshift(rgb565, 5), 0x3F) * 4
	local b = bit32.band(rgb565, 0x1F) * 8
	return Color3.fromRGB(r, g, b)
end

function GPU.WritePixel(x, y, color16bit)
	if x < 0 or x >= WIDTH or y < 0 or y >= HEIGHT then return end

	local address = RAM.VRAM_OFFSET + ((y * WIDTH + x) * 2)
	if address >= RAM.GPU_MAX_OFFSET then return end

	RAM.write16(address, color16bit)

	local blockX = math.floor(x / SCALE)
	local blockY = math.floor(y / SCALE)
	local blockIndex = blockY * DISPLAY_WIDTH + blockX
	dirtyBlocks[blockIndex] = true
end

function GPU.RenderFrame()
	for blockIndex, _ in pairs(dirtyBlocks) do
		local blockX = blockIndex % DISPLAY_WIDTH
		local blockY = math.floor(blockIndex / DISPLAY_WIDTH)

		local totalR, totalG, totalB, samples = 0, 0, 0, 0

		for y = 0, SCALE - 1 do
			for x = 0, SCALE - 1 do
				local px = blockX * SCALE + x
				local py = blockY * SCALE + y
				local address = RAM.VRAM_OFFSET + ((py * WIDTH + px) * 2)

				local color = RAM.read16(address)
				local decoded = decodeRGB565(color)

				totalR += decoded.R
				totalG += decoded.G
				totalB += decoded.B
				samples += 1
			end
		end

		local finalColor = Color3.new(totalR / samples, totalG / samples, totalB / samples)
		local displayPixel = pixelObjects[blockIndex]

		if displayPixel then
			displayPixel.BackgroundColor3 = finalColor
		end
	end
	table.clear(dirtyBlocks)
end

function GPU.Flush()
	GPU.RenderFrame()
end

function GPU.TestPattern()
	print("[GPU] Drawing framebuffer test pattern...")
	for y = 0, HEIGHT - 1 do
		for x = 0, WIDTH - 1 do
			local r = bit32.band(x * 31 / WIDTH, 0x1F)
			local g = bit32.band(y * 63 / HEIGHT, 0x3F)
			local b = bit32.band(x + y, 0x1F)
			local color565 = bit32.bor(bit32.lshift(r, 11), bit32.lshift(g, 5), b)
			GPU.WritePixel(x, y, color565)
		end
	end
	GPU.Flush()
	print("[GPU] Framebuffer pattern loaded.")
	return true
end

function GPU.GetResolution()
	return WIDTH, HEIGHT
end

function GPU.ClearScreen()
	print("[GPU] Clearing framebuffer...")
	for y = 0, HEIGHT - 1 do
		for x = 0, WIDTH - 1 do
			local address = RAM.VRAM_OFFSET + ((y * WIDTH + x) * 2)
			RAM.write16(address, 0)
		end
	end

	for _, pixel in pairs(pixelObjects) do
		pixel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	end
	table.clear(dirtyBlocks)
	print("[GPU] Framebuffer cleared.")
end

return GPU
