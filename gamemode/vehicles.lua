
function MakeVehicle( Pos, Ang, Model, Class, VName, VTable, team )

--	if (!gamemode.Call( "PlayerSpawnVehicle", Player, Model, VName, VTable )) then return end

	local Ent = ents.Create( Class )
	if (!Ent) then return NULL end
	
	Ent:SetModel( Model )
	
	-- Fill in the keyvalues if we have them
	if ( VTable && VTable.KeyValues ) then
		for k, v in pairs( VTable.KeyValues ) do
			Ent:SetKeyValue( k, v )
		end		
	end

	Ent:SetNWInt( "Team", team or -1 )
		
	Ent:SetAngles( Ang )
	Ent:SetPos( Pos )

--	DoPropSpawnedEffect( Ent )
	Ent:SetSpawnEffect( true )
	
	Ent:Spawn()
	Ent:Activate()
	
	Ent.VehicleName 	= VName
	Ent.VehicleTable 	= VTable
	
	-- We need to override the class in the case of the Jeep, because it 
	-- actually uses a different class than is reported by GetClass
	Ent.ClassOverride 	= Class
	
--	if ( IsValid( Player ) ) then
--		gamemode.Call( "PlayerSpawnedVehicle", Player, Ent )
--	end
	SpawnedVehicle(nil, Ent)
	
	return Ent	
	
end

function SpawnVehicle(pos, ang, vname, team)

	if ( !vname ) then return end

	local VehicleList = list.Get( "Vehicles" )
	local vehicle = VehicleList[ vname ]
	
	-- Not a valid vehicle to be spawning..
	if ( !vehicle ) then return end

	local Ent = MakeVehicle( pos, ang, vehicle.Model, vehicle.Class, vname, vehicle, team ) 
	if ( !IsValid( Ent ) ) then return end
	
	if ( vehicle.Members ) then
		table.Merge( Ent, vehicle.Members )
	end
	
	return Ent
	
end





function SpawnedVehicle(player, vehicle)
	local localpos = vehicle:GetPos() local localang = vehicle:GetAngles()
				----Add passenger seats
	if vehicle.VehicleTable then
		if vehicle.VehicleTable.Passengers then		
			vehicle.Passengers = {}
			-----Grab the data for the extra seats, we do want the lovely sitting anim dont we.
			local SeatName = vehicle.VehicleTable.SeatType
			
			local seatdata = list.Get( "Vehicles" )[ SeatName ]
			
			-----Repeat for each seat.
			for a,b in pairs(vehicle.VehicleTable.Passengers) do
				local SeatName = vehicle.VehicleTable.Passengers[a].SeatType or SeatName
				local seatdata = list.Get( "Vehicles" )[ SeatName ]
			
				local SeatPos = localpos + ( localang:Forward() * b.Pos.x) + ( localang:Right() * b.Pos.y) + ( localang:Up() * b.Pos.z)
				local Seat = ents.Create( "prop_vehicle_prisoner_pod" )
				Seat:SetModel( seatdata.Model )
				Seat:SetKeyValue( "vehiclescript" , "scripts/vehicles/prisoner_pod.txt" )
				Seat:SetAngles( localang + b.Ang )
				Seat:SetPos( SeatPos )
				Seat:SetNWInt( "Team", vehicle:GetNWInt( "Team" ) )
				Seat:Spawn()
				Seat:Activate()
				Seat:SetParent(vehicle)
				if vehicle.VehicleTable.Passengers[a].HideSeats then
					Seat:SetColor(Color(255,255,255,1))
					Seat:SetRenderMode(RENDERMODE_TRANSALPHA)
				end
				if ( seatdata.Members ) then
				table.Merge( Seat, seatdata.Members )
				end
				if ( seatdata.KeyValues ) then
					for k, v in pairs( seatdata.KeyValues ) do
					Seat:SetKeyValue( k, v )
					end		
				end
				Seat.VehicleName = "Jeep Seat"
				Seat.VehicleTable = seatdata
				Seat.VehicleTable.AllowWeapons = b.AllowWeapons
				Seat.ID = a
				Seat.VehicleParent = vehicle
				Seat.ClassOverride = "prop_vehicle_prisoner_pod"
				Seat:DeleteOnRemove( vehicle )
				----------- Replace the position with the ent so we can find it later.
				vehicle.VehicleTable.Passengers[a].Ent = Seat
				vehicle.Passengers[a] = Seat
			end
		end
		if vehicle.VehicleTable.Health then
			vehicle:SetNWInt( "Health", vehicle.VehicleTable.Health )
		end
		
//		if vehicle.VehicleTable.Members and vehicle.VehicleTable.Members.HandleAnimation then
//			vehicle.HandleAnimation = vehicle.VehicleTable.Members.HandleAnimation
//		end
	end
end

local NormalExits = { "exit1","exit2","exit3","exit4","exit5","exit6"}
local function GetVehicleExit(player,vehicle)
	if vehicle.VehicleTable then
		if vehicle.VehicleTable.Customexits then
			for a,b in pairs(vehicle.VehicleTable.Customexits) do
			----------------Calculate actual postion ------------------
			local localpos = vehicle:GetPos() local localang = vehicle:GetAngles()
			localpos = localpos + ( localang:Forward() * b.x) + ( localang:Right() * b.y) + ( localang:Up() * b.z)
			-----------Trace to see if we can get out there------
			if vehicle:VisibleVec(localpos) then
			player:SetPos(localpos)
			return
			end
			end
		end
		for a,b in pairs(NormalExits) do
			local angpos = vehicle:GetAttachment( vehicle:LookupAttachment( b ) )
			if angpos != nil then
			if 	vehicle:VisibleVec( angpos.Pos ) then
			player:SetPos( angpos.Pos )
			return
			end
			end
		end
	end
end

local function DoVehicleExit( player ) 
	if player.AllowWeaponsInVehicle then
		player:AllowWeaponsInVehicle(false)
	end
	
	local vehicle = player:GetVehicle()
	----i need to make sure the player is deffinately out of the car.
	if player:InVehicle() then
	player:ExitVehicle()
	end
	----by now we should be out of the car, we better check this just to prevent any errors
	if !player:InVehicle() then
		if vehicle.VehicleTable then
		if vehicle:GetParent():IsValid() then
		local parent = vehicle:GetParent()
			if parent:IsVehicle() then
				if parent.VehicleTable.Passengers then
					GetVehicleExit(player,parent)
				end
			end
		elseif vehicle.VehicleTable.Customexits then
			GetVehicleExit(player,vehicle)
		end
		end
		
	end
end

-------The "PlayerUse" seems to repeat about 3 times, i better stop this.
local function GetInCar( player , vehicle )	
   ------Seat trace, allows you to access seats inside a car.
	if vehicle:IsVehicle() then 
		if vehicle.VehicleTable && vehicle.VehicleTable.Passengers then
			-----trace trough the car and see if your looking at a seat----
			local Start = player:GetShootPos() local Forward = player:GetAimVector()
			local trace = {} trace.start = player:GetShootPos() trace.endpos = Start + (Forward * 90)
			trace.filter = { player , vehicle } local trace = util.TraceLine( trace ) 
			-----did we hit a seat? if so, can we get in it?
			if trace.Entity:IsValid() && trace.Entity:IsVehicle() then
			player:EnterVehicle( trace.Entity )
			end 
		end
	end
end

local function EnteredVehicle( player, vehicle, role )
	if vehicle.VehicleTable and vehicle.VehicleTable.AllowWeapons then
		if player.AllowWeaponsInVehicle then
			player:AllowWeaponsInVehicle(true)
		end
	end
end 

local function ExitingCar ( player, key )
	if key == IN_USE and player:InVehicle() then
		DoVehicleExit(player)
		---now i need to set the position after i get out of the car... so instead of waiting for this to pass, ill forse it myself
		return false
	end
end

local function ChangeSeats ( ply, btn )
	if !ply:InVehicle() then return end
	local veh = ply:GetVehicle()
	if btn == KEY_0 then	-- You want to sit in the drivers seat
		if ply:GetVehicle().VehicleParent then	-- If we are in a seat and not the drivers seat
			if !IsValid(veh.VehicleParent:GetDriver()) then
				ply:ExitVehicle()
				ply:EnterVehicle(veh.VehicleParent)
			end
		end
	else
		local seats = {}
		if veh.VehicleParent and veh.VehicleParent.Passengers then
			seats = veh.VehicleParent.Passengers
		elseif veh.Passengers then
			seats = veh.Passengers
		else 
			//return
		end
--		MsgN("Seats")
--		PrintTable(seats)
		if seats[btn-1] then
			if !IsValid(seats[btn-1]:GetDriver()) then
				ply:ExitVehicle()
				ply:EnterVehicle(seats[btn-1])
			end
		end
	end
end

function VehicleTakeDamage( vehicle, dmginfo )
	if dmginfo:GetAttacker().NoDamage then
		dmginfo:SetDamage(0)
		return dmginfo
	end
	
//	print(vehicle,dmginfo:GetAttacker(),dmginfo:GetDamage())
	
	if vehicle:IsVehicle() and vehicle:GetNWInt("Health",-999) != -999 then
		vehicle:SetNWInt("Health",vehicle:GetNWInt("Health") - dmginfo:GetDamage())
		if vehicle:GetNWInt("Health") < 0 then
			vehicle:Remove()
		elseif vehicle:GetNWInt("Health") < 60 then
			if !vehicle.EngineFire then
				local localpos = vehicle:GetPos() local localang = vehicle:GetAngles() local pos = vehicle.VehicleTable.EnginePos
				localpos = localpos + ( localang:Forward() * pos.x) + ( localang:Right() * pos.y) + ( localang:Up() * pos.z)
				vehicle.EngineFire = ents.Create( "env_fire" )
				vehicle.EngineFire.NoDamage = true
				vehicle.EngineFire:SetKeyValue( "spawnflags" , 285 )
				vehicle.EngineFire:SetPos( localpos )
				vehicle.EngineFire:Spawn()
				vehicle.EngineFire:Activate()
				vehicle.EngineFire:SetParent( vehicle )
				vehicle.EngineFire:DeleteOnRemove( vehicle )
			end
			vehicle.EngineFire:SetKeyValue( "firesize" , (60-vehicle:GetNWInt("Health"))*4 )	-- doesn't seem to work the way i would like
		end
		return dmginfo
	end
	
    

end

function CanEnterVehicle( ply, veh, srole )
	if veh:GetNWInt( "Team", -1 ) == -1 then return true end
	if veh:GetNWInt( "Team" ) == ply:Team() then return true end
	return false
end


if SERVER then
hook.Add( "KeyPress", "ExitingCar", ExitingCar ) 
end
hook.Add( "PlayerSpawnedVehicle", "SpawnedVehicle", SpawnedVehicle )
hook.Add( "PlayerEnteredVehicle", "EnteredVehicle", EnteredVehicle )
hook.Add( "PlayerUse", "GetInCar", GetInCar ) 
hook.Add( "PlayerButtonDown", "PlayerPressButton", ChangeSeats ) 
hook.Add( "EntityTakeDamage", "VehicleTakeDamage", VehicleTakeDamage )
hook.Add( "CanPlayerEnterVehicle", "CanEnterVehicle", CanEnterVehicle )






--[[---------------------------------------------------------
   Name: CCSpawnVehicle
   Desc: Player attempts to spawn vehicle
-----------------------------------------------------------
function Spawn_Vehicle( Player, vname, tr )

	if ( !vname ) then return end

	local VehicleList = list.Get( "Vehicles" )
	local vehicle = VehicleList[ vname ]
	
	-- Not a valid vehicle to be spawning..
	if ( !vehicle ) then return end
	
	if ( !tr ) then
		tr = Player:GetEyeTraceNoCursor()
	end
	
	local Angles = Player:GetAngles()
		Angles.pitch = 0
		Angles.roll = 0
		Angles.yaw = Angles.yaw + 180
	
	local Ent = MakeVehicle( tr.HitPos, Angles, vehicle.Model, vehicle.Class, vname, vehicle ) 
	if ( !IsValid( Ent ) ) then return end
	
	if ( vehicle.Members ) then
		table.Merge( Ent, vehicle.Members )
		duplicator.StoreEntityModifier( Ent, "VehicleMemDupe", vehicle.Members )
	end
	
	undo.Create( "Vehicle" )
		undo.SetPlayer( Player )
		undo.AddEntity( Ent )
		undo.SetCustomUndoText( "Undone "..vehicle.Name )
	undo.Finish( "Vehicle ("..tostring( vehicle.Name )..")" )
	
	Player:AddCleanup( "vehicles", Ent )
	
end

concommand.Add( "gm_spawnvehicle", function( ply, cmd, args ) Spawn_Vehicle( ply, args[1] ) end )--]]
local V = { 	
				Name = "Jeep2", 
				Class = "prop_vehicle_jeep_old",
				Category = "VU-MOD",
				Author = "Nova[X]",
				Information = "The regular old jeep, with an extra seat",
				Model = "models/buggy.mdl",
				Health = 1000,
				Passengers  = { passenger1 = { Pos = Vector(16,37,19), Ang = Angle(0,0,0) } }, -------Set Up passenger seats!
				SeatType = "Seat_Jeep", ----if were not hideing the seat you probably want to choose a seat.
				HideSeats = false, -----Hide the passenger seats?
				EnginePos = Vector(0,50,30),
				KeyValues = {
								vehiclescript	=	"scripts/vehicles/jeep_test.txt",
								EnableGun = 1
							}
			}
list.Set( "Vehicles", "2SeatJeep", V )

local V = { 	
				Name = "Airboat", 
				Class = "prop_vehicle_airboat",
				Category = "VU-MOD",
				Author = "Nova[X]",
				Health = 100,
				Passengers  = { [1] = { Pos = Vector(32,22,18), Ang = Angle(0,-90,00),	SeatType = "Seat_Airboat",	HideSeat = false,	AllowWeapons = true },		
								[2] = { Pos = Vector(-32,22,18), Ang = Angle(0,90,00),	SeatType = "Seat_Airboat",	HideSeat = false,	AllowWeapons = true },
								[3] = { Pos = Vector(32,-0,18), Ang = Angle(0,-90,0),	SeatType = "Seat_Airboat",	HideSeat = false,	AllowWeapons = true },		
								[4] = { Pos = Vector(-32,-0,18), Ang = Angle(0,90,0),	SeatType = "Seat_Airboat",	HideSeat = false,	AllowWeapons = true },
								[5] = { Pos = Vector(0,50,68), Ang = Angle(0,0,0),		SeatType = "Seat_Jalopy",	HideSeat = false,	AllowWeapons = true }				
							},--left/right ,forward/back ,up/down
				SeatType = "Seat_Airboat", ----if were not hideing the seat you probably want to choose a seat.
				HideSeats = false, -----Hide the passenger seats?
				EnginePos = Vector(0,50,50),
				Information = "Airboat from Half-Life 2",
				Model = "models/airboat.mdl",
				KeyValues = {
								vehiclescript	=	"scripts/vehicles/airboat.txt",
								EnableGun = 1
							}
			}
list.Set( "Vehicles", "AirboatTank", V )


local V = { 	
				Name = "Jalopy", 
				Class = "prop_vehicle_jeep",
				Category = "VU-MOD",
				Author = "Nova[X]",
				Information = "Jalopy, With a working passanger seat!",
				Model = "models/vehicle.mdl",
				Passengers  = { passenger1 = { Pos = Vector(22,24,22), Ang = Angle(0,0,0),	SeatType = "Seat_Jeep",	HideSeat = true } }, -------Set Up passenger seats!
				Customexits = { Vector(-90,36,22), Vector(82,36,22), Vector(22,24,90) ,Vector(2,100,30) },
				SeatType = "Seat_Jeep",
				HideSeats = true, -----Hide the passenger seats?
				KeyValues = {vehiclescript	=	"scripts/vehicles/jalopy.txt"}
			}
list.Set( "Vehicles", "2SeatJalopy", V )

local function FixDamage(target,  dmginfo)
	if ( dmginfo:GetInflictor():IsVehicle() && dmginfo:GetDamage() < 1) then
		if dmginfo:GetAmmoType() == 18 then 
			dmginfo:SetDamage(15)
		elseif(dmginfo:GetAmmoType() == 20) then
			dmginfo:SetDamage(3)
		end
	end
end
hook.Add("EntityTakeDamage","VehicleNPCDamageFix", FixDamage)