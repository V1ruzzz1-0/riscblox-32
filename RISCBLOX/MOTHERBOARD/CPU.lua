--!! SoC CORE PROCESSOR - RISCBLOX-32 RV32I EMULATOR !!--
-- SPDX-License-Identifier: AGPL-3.0-only
-- Copyright (C) 2026 v1ruzzz1_0
local CPU = {}
local RAM = require(script.Parent:WaitForChild("RAM"))
local X = table.create(32, 0)
local PC = 0x80000000
local PRIV_MACHINE = 3
	local CSR = { mcause = 0, mepc = 0 }

local function signExtend(val, bits)
	local sign = bit32.lshift(1, bits - 1)
	return bit32.band(val, sign) ~= 0 and bit32.bor(val, bit32.lshift(0xFFFFFFFF, bits)) or val
end

local function toSigned32(v)
	return v >= 0x80000000 and (v - 0x100000000) or v
end

local function writeRegister(rd, val)
	if rd > 1 then X[rd] = bit32.band(val, 0xFFFFFFFF) end
end

local OP_IMM_OPS = {
	[0] = function(rs1, imm, rd) writeRegister(rd, X[rs1] + imm) end,
	[1] = function(rs1, imm, rd) writeRegister(rd, bit32.lshift(X[rs1], bit32.band(imm, 0x1F))) end,
	[2] = function(rs1, imm, rd) writeRegister(rd, (toSigned32(X[rs1]) < toSigned32(imm)) and 1 or 0) end,
	[3] = function(rs1, imm, rd) writeRegister(rd, (X[rs1] < bit32.band(imm, 0xFFFFFFFF)) and 1 or 0) end,
	[4] = function(rs1, imm, rd) writeRegister(rd, bit32.bxor(X[rs1], imm)) end,
	[6] = function(rs1, imm, rd) writeRegister(rd, bit32.bor(X[rs1], imm)) end,
	[7] = function(rs1, imm, rd) writeRegister(rd, bit32.band(X[rs1], imm)) end
}

function CPU.ResetState()
	for i = 1, 32 do X[i] = 0 end
	PC = 0x80000000
	print("[CPU] Execution state reset.")
end

function CPU.PowerOn()
	CPU.ResetState()
	X[3] = 0x80020000 
	print("[RISCBLOX-32] CPU core online.")
end

function CPU.Cycle()
	if PC == 0 then return end
	local inst = RAM.read32(PC)
	if inst == 0 then
		CSR.mcause = 2; CSR.mepc = PC; PC = 0; return
	end
	local opcode = bit32.band(inst, 0x7F)
	local rd = bit32.band(bit32.rshift(inst, 7), 0x1F) + 1
	local f3 = bit32.band(bit32.rshift(inst, 12), 0x07)
	local rs1 = bit32.band(bit32.rshift(inst, 15), 0x1F) + 1
	local rs2 = bit32.band(bit32.rshift(inst, 20), 0x1F) + 1
	local f7 = bit32.rshift(inst, 25)
	local nextPC = PC + 4
	local executed = false

	if opcode == 0x13 then -- OP-IMM
		local imm = signExtend(bit32.rshift(inst, 20), 12)
		if f3 == 5 then
			if bit32.band(f7, 0x20) == 0 then writeRegister(rd, bit32.rshift(X[rs1], bit32.band(imm, 0x1F)))
			else writeRegister(rd, bit32.arshift(X[rs1], bit32.band(imm, 0x1F))) end
		else OP_IMM_OPS[f3](rs1, imm, rd) end
		executed = true
	elseif opcode == 0x03 then -- LOADS
		local imm = signExtend(bit32.rshift(inst, 20), 12)
		local addr = bit32.band(X[rs1] + imm, 0xFFFFFFFF)
		if f3 == 0 then writeRegister(rd, signExtend(RAM.read8(addr), 8))
		elseif f3 == 1 then writeRegister(rd, signExtend(RAM.read16(addr), 16))
		elseif f3 == 2 then writeRegister(rd, RAM.read32(addr))
		elseif f3 == 4 then writeRegister(rd, RAM.read8(addr))
		elseif f3 == 5 then writeRegister(rd, RAM.read16(addr)) end
		executed = true
	elseif opcode == 0x33 then -- OP-REGISTER
		local v1, v2 = X[rs1], X[rs2]
		if f3 == 0 then writeRegister(rd, (f7 == 0) and (v1 + v2) or (v1 - v2))
		elseif f3 == 1 then writeRegister(rd, bit32.lshift(v1, bit32.band(v2, 0x1F)))
		elseif f3 == 2 then writeRegister(rd, (toSigned32(v1) < toSigned32(v2)) and 1 or 0)
		elseif f3 == 3 then writeRegister(rd, (v1 < v2) and 1 or 0)
		elseif f3 == 4 then writeRegister(rd, bit32.bxor(v1, v2))
		elseif f3 == 5 then writeRegister(rd, (f7 == 0) and bit32.rshift(v1, bit32.band(v2, 0x1F)) or bit32.arshift(v1, bit32.band(v2, 0x1F)))
		elseif f3 == 6 then writeRegister(rd, bit32.bor(v1, v2))
		elseif f3 == 7 then writeRegister(rd, bit32.band(v1, v2)) end
		executed = true
	elseif opcode == 0x23 then -- STORES
		local imm = bit32.bor(bit32.lshift(bit32.rshift(inst, 25), 5), bit32.band(bit32.rshift(inst, 7), 0x1F))
		local addr = bit32.band(X[rs1] + signExtend(imm, 12), 0xFFFFFFFF)
		if addr == 0x10000000 then print(string.char(bit32.band(X[rs2], 0xFF)))
		elseif f3 == 0 then RAM.write8(addr, bit32.band(X[rs2], 0xFF))
		elseif f3 == 1 then RAM.write16(addr, bit32.band(X[rs2], 0xFFFF))
		elseif f3 == 2 then RAM.write32(addr, X[rs2]) end
		executed = true
	elseif opcode == 0x63 then -- BRANCHES
		local imm = signExtend(bit32.bor(bit32.lshift(bit32.band(bit32.rshift(inst, 31), 1), 12), bit32.lshift(bit32.band(bit32.rshift(inst, 7), 1), 11), bit32.lshift(bit32.band(bit32.rshift(inst, 25), 0x3F), 5), bit32.lshift(bit32.band(bit32.rshift(inst, 8), 0xF), 1)), 13)
		local match = (f3==0 and X[rs1]==X[rs2]) or (f3==1 and X[rs1]~=X[rs2]) or (f3==4 and toSigned32(X[rs1])<toSigned32(X[rs2])) or (f3==5 and toSigned32(X[rs1])>=toSigned32(X[rs2])) or (f3==6 and X[rs1]<X[rs2]) or (f3==7 and X[rs1]>=X[rs2])
		if match then nextPC = PC + imm end
		executed = true
	elseif opcode == 0x37 then -- LUI
		writeRegister(rd, bit32.band(inst, 0xFFFFF000)); executed = true
	elseif opcode == 0x17 then -- AUIPC
		writeRegister(rd, PC + bit32.band(inst, 0xFFFFF000)); executed = true
	elseif opcode == 0x6F then -- JAL
		local imm = signExtend(bit32.bor(bit32.lshift(bit32.band(bit32.rshift(inst, 31), 1), 20), bit32.lshift(bit32.band(bit32.rshift(inst, 12), 0xFF), 12), bit32.lshift(bit32.band(bit32.rshift(inst, 20), 1), 11), bit32.lshift(bit32.band(bit32.rshift(inst, 21), 0x3FF), 1)), 21)
		writeRegister(rd, PC + 4); nextPC = PC + imm; executed = true
	elseif opcode == 0x67 then -- JALR
		writeRegister(rd, PC + 4); nextPC = bit32.band(X[rs1] + signExtend(bit32.rshift(inst, 20), 12), 0xFFFFFFFE); executed = true
	elseif opcode == 0x73 then -- SYSTEM
		if f3 == 0 then CSR.mcause = 8; CSR.mepc = PC; PC = 0 end
		executed = true
	end
	if executed then PC = bit32.band(nextPC, 0xFFFFFFFF) end
end

return CPU
