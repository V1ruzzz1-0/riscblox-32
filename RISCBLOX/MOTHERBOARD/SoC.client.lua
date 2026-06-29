--!! MOTHERBOARD CENTRAL SYSTEM - SoC SILICON INTEGRATION !!--
-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local RunService = game:GetService("RunService")

--// HARDWARE COMPONENTS
local CPU = require(script:WaitForChild("CPU"))
local GPU = require(script:WaitForChild("GPU"))
local RAM = require(script:WaitForChild("RAM"))
local ROM = require(script:WaitForChild("ROM"))

--// DEBUG HARDWARE TEST
local TestMode = require(script.Parent.Parent:WaitForChild("DEBUG"):WaitForChild("Test_Mode"))

--// DISPLAY BUS
local motherboard = script.Parent
local monitorGui = motherboard:WaitForChild("MONITOR")
local tty = monitorGui:WaitForChild("TTY")
local pixelsGrid = tty:WaitForChild("PIXELS")

--// CONSTANTS
local MAX_FRAME_BUDGET = 0.012

--// POWER SEQUENCE
print("[SoC] Firing boot voltage to RISCBLOX-32 System...")

GPU.Initialize(tty, pixelsGrid)

-- Hardware POST
TestMode.Run(CPU, RAM, GPU)

-- Load firmware into RAM
ROM.Load(RAM)

-- Start CPU
CPU.PowerOn()

-- Main clock
RunService.Heartbeat:Connect(function()
	local frameStart = os.clock()

	while os.clock() - frameStart < MAX_FRAME_BUDGET do
		CPU.Cycle()
	end

	-- GPU Render Phase
	GPU.RenderFrame()
end)

print("[SoC] Silicon bus initialized and pulsing.")
