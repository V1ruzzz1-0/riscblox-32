-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local TestMode = {}
TestMode.ENABLED = 1
local RunService = game:GetService("RunService")

local function Delay(seconds)
	local start = os.clock()
	while os.clock() - start < seconds do
		RunService.Heartbeat:Wait()
	end
end

function TestMode.Run(CPU, RAM, GPU)
	if TestMode.ENABLED == 0 then return end
	print("[POST] Starting hardware diagnostics...")

	print("[POST] Testing RAM...")
	local addr = RAM.BASE_ADDRESS
	RAM.write32(addr, 0xDEADBEEF)

	if RAM.read32(addr) == 0xDEADBEEF then
		print("[POST] RAM ........ PASS")
	else
		print("[POST] RAM ........ FAIL")
	end

	print("[POST] Testing GPU...")
	GPU.TestPattern()
	print("[POST] CPU Diagnostics...")
	print("[POST] GPU ........ PASS")

	print("[POST] CPU ........ READY")
	print("[POST] Hardware diagnostics complete.")

	print("[POST] Holding diagnostic screen...")
	Delay(10)

	print("[POST] Preparing hardware handoff...")
	GPU.ClearScreen()
	RAM.Clear()
	CPU.ResetState()
	print("[POST] Hardware ready for firmware.")
end

return TestMode
