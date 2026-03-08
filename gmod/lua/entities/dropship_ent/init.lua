--[[----------------------------------------------------------------------

	████████╗░█████╗░░█████╗░██████╗░
	╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗
	░░░██║░░░██║░░██║██║░░██║██║░░██║
	░░░██║░░░██║░░██║██║░░██║██║░░██║
	░░░██║░░░╚█████╔╝╚█████╔╝██████╔╝
	░░░╚═╝░░░░╚════╝░░╚════╝░╚═════╝░

	Support: discord.gg/YSzU6MY2Yb

	If you touch anything in this file and it breaks then ALL support is void.
	If you don't know what you're doing then don't touch it.

--]]----------------------------------------------------------------------

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )

-- Vars
local npc_class
local npc_model
local npc_weapon
local npc_health
local npc_amount
local min_spawn
local max_spawn
local npc_relations
local npc_prof
local dship_model
local dship_health
local dship_speed
local dship_remove
local dship_hover

local dist = 600
local step = 30
local area = Vector( 16, 16, 0 )
local ns = Vector( 0, 0, 0 )
local ew = Vector( 0, 0, 0 )
local ud = Vector( 0, 0, 0 )
local exclude = 300
local rand = 0.75

local function IsEmpty( vec, ignore, origin, exclusion_zone )

    if origin && vec:Distance( origin ) < exclusion_zone then
        return false
    end

    local point = util.PointContents( vec )
    local a = point ~= CONTENTS_SOLID 
    and point ~= CONTENTS_MOVEABLE 
    and point ~= CONTENTS_LADDER 
    and point ~= CONTENTS_PLAYERCLIP 
    and point ~= CONTENTS_MONSTERCLIP

    local b = true

    for k, v in ipairs( ents.FindInSphere( vec, 35 ) ) do 
        if ( v:IsNPC() || v:IsPlayer() || v:GetClass() == "prop_physics" ) and not v != ignore then
            b = false
            break
        end
    end
    return b
end

local function FindEmpty( pos, ignore, exclusion_zone )

    local off = Vector( math.random( -step, step ) * rand, math.random( -step, step ) * rand, math.random( -25, 25 ) * rand )
    local rand_pos = pos + off

    if IsEmpty( rand_pos, ignore, pos, exclusion_zone ) and IsEmpty( rand_pos + area, ignore, pos, exclusion_zone ) then
        return rand_pos
    end

    for j = step, dist, step do
        for i = -1, 1, 2 do -- alternate in direction
            local k = j * i

            local ns_off = Vector( k * math.random(), 0, 0 )
            local ew_off = Vector( 0, k * math.random(), 0 )
            local ud_off = Vector( 0, 0, k * math.random() )

            if IsEmpty( pos + Vector( k * math.random(), 0, 0 ), ignore, pos, exclusion_zone ) and IsEmpty( pos + Vector( k * math.random(), 0, 0 ) + area, ignore, pos, exclusion_zone ) then
                return pos + Vector( k * math.random(), 0, 0 )
            end

            -- Look East/West
            if IsEmpty( pos + Vector( 0, k * math.random(), 0 ), ignore, pos, exclusion_zone ) and IsEmpty( pos + Vector( 0, k * math.random(), 0 ) + area, ignore, pos, exclusion_zone ) then
                return pos + Vector( 0, k * math.random(), 0 )
            end

            -- Look Up/Down
            if math.abs( k ) <= 5 then -- Don't check too high
                if IsEmpty( pos + Vector( 0, 0, 1 ), ignore, pos, exclusion_zone ) and IsEmpty( pos + Vector( 0, 0, 1 ) + area, ignore, pos, exclusion_zone ) then
                    return pos + Vector( 0, 0, 1 )
                end
            end
        end
    end
    return pos
end

-- Could probably do this in a loop but oh well.
function ENT:KeyValue( key, value )
    if key == "npc_class" then
        npc_class = value
    end
    if key == "npc_model" then
        npc_model = value
    end
    if key == "npc_weapon" then
        npc_weapon = value
    end
    if key == "npc_health" then
        npc_health = value
    end
    if key == "npc_amount" then
        npc_amount = value
    end
    if key == "min_spawn" then
        min_spawn = value
    end
    if key == "max_spawn" then
        max_spawn = value
    end
    if key == "npc_relations" then
        npc_relations = value
    end
    if key == "npc_prof" then
        npc_prof = value
    end
    if key == "dship_model" then
        dship_model = value
    end
    if key == "dship_health" then
        self:SetHealth( value )
        self:SetMaxHealth( value )
    end
    if key == "dship_speed" then
        dship_speed = value
    end
    if key == "dship_remove" then
        dship_remove = value
    end
    if key == "dship_hover" then
        dship_hover = value
    end
end

function ENT:Initialize()
    self:SetModel( dship_model )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetHealth( self:GetMaxHealth() )
    self:SetMaxHealth( self:GetMaxHealth() )
    
    self.save_yaw = self:GetAngles().yaw
    self.recover_roll = false
    self.avoid_roll = 0
    self.start_pos = self:GetPos()
    self.spawning_finished = false
    self.is_crashing = false
    self.crash_dir = nil
    self.rope_1 = nil
    self.rope_2 = nil
    self.is_hovered = false

    local phys = self:GetPhysicsObject()
    if !IsValid( phys ) then return end
    phys:Wake()
    self:EnableConstraints( true )
    
    self:SetGravity( 0 )
    self:SetSpeed( dship_speed )
end

function ENT:SetTargetPosition( pos )
    self.target_pos = pos + Vector( 0, 0, 10 )
    if dship_hover == "1" then
        self.target_pos.z = self.target_pos.z + 550
        self.hover_z = pos.z
    end
    self.landing = false
    self.final_z = pos.z -- Need this as a fallback because self.target_pos changes.
    local curr = self:GetPos()
    local dir = ( self.target_pos - curr ):GetNormalized()
    self.save_yaw = dir:Angle().yaw
    self:SetAngles( Angle( 0, self.save_yaw, 0 ) )
end

function ENT:Think()
    if not self.target_pos and not self.returning and not self.is_crashing then return end
    local curr = self:GetPos()

    local target_pos = self.target_pos
    if self.returning then
        target_pos = self.start_pos
    end

    local dir = ( target_pos - curr ):GetNormalized()
    local dist = curr:Distance( target_pos )

    if not self.landing and not self.save_yaw then
        self.save_yaw = dir:Angle().yaw
    end

    if self.is_crashing then
        local crash_dir = dir
        if self.crash_dir == "left" then
            crash_dir = Vector( dir.x - 0.4, dir.y, -0.5 ):GetNormalized()
        elseif self.crash_dir == "right" then
            crash_dir = Vector( dir.x + 0.4, dir.y, -0.5 ):GetNormalized()
        elseif self.crash_dir == "forward" then
            crash_dir = Vector( dir.x, dir.y, -0.5 ):GetNormalized()
        end

        local crash_ang = crash_dir:Angle()
        local smooth = LerpAngle( FrameTime() * 2, self:GetAngles(), crash_ang )
        local crash_pos = curr + crash_dir * self:GetSpeed() * FrameTime()
        self:SetPos( self:GetForward() + crash_pos )
        self:WatchAngles( crash_ang )
        local tr_data = {}
        tr_data.start = curr
        tr_data.endpos = crash_pos
        tr_data.mins = self:OBBMins()
        tr_data.maxs = self:OBBMaxs()
        tr_data.filter = self
        local tr = util.TraceHull( tr_data )
        if tr.Hit then
            self:DoImpact( tr.HitPos )
            self.is_crashing = false
            self:SetMoveType( MOVETYPE_NONE )
            return true
        end
        self:NextThink( CurTime() )
        return true
    end

    local collide, new_dir, avoid_roll = self:CheckPath( curr, dir, dist )
    if collide then
        dir = new_dir
        self.avoid_roll = avoid_roll
        self.recover_roll = false
    else
        if not self.recover_roll and self.avoid_roll ~= 0 then
            self.recover_roll = true
        end
        if self.recover_roll then
            self.avoid_roll = math.Approach( self.avoid_roll, 0, FrameTime() * 50 )
            if math.abs( self.avoid_roll ) < 0.1 then
                self.avoid_roll = 0
                self.recover_roll = false
            end
        end
    end
    
    if dist > 300 then
        if self.returning then
            if curr.z < self.final_z + 100 then
                self:SetPos( Vector( curr.x, curr.y, curr.z + 1 * 100 * FrameTime() ) )
                self:SetAngles( self:GetAngles() )
            else
                self:SetPos( curr + dir * dship_speed * FrameTime() )
                local ang = dir:Angle()
                ang.roll = self.avoid_roll
                self:WatchAngles( ang )
            end
        else
            self:SetPos( curr + dir * self:GetSpeed() * FrameTime() )
            local ang = dir:Angle()
            ang.roll = self.avoid_roll
            self:WatchAngles( ang )
        end
    else
        if self.returning then
            self:Remove()
        else
            if dship_hover == "1" then
                self:Hover()
            else
                self:Land()
            end
        end
    end

    if self.spawning_finished and not self.returning then
        self.returning = true 
        SafeRemoveEntity( self.rope_1 )
        SafeRemoveEntity( self.rope_2 )
        self.is_hovered = nil
        self.target_pos = nil
    end

    self:NextThink( CurTime() )
    return true
end

function ENT:DoSpawning( class, amount )
    local all = list.Get( "NPC" )
    local check_class = all[class]
    if !check_class then return end
    local spawned = 0
    for i = 1, amount do
        timer.Simple( math.random( min_spawn, max_spawn ), function() 
            if IsValid( self ) then
                local spawn_npc = ents.Create( check_class.Class )
                if !IsValid( spawn_npc ) || self.is_crashing then return end
                spawn_npc:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
                if dship_hover == "1" then
                    local pos = math.random( 1, 2 ) == 1 && self.rope_1 || self.rope_2
                    if pos then
                        spawn_npc:SetPos( pos:GetPos() + Vector( 0, 0, -85 ) )
                    end
                else
                    spawn_npc:SetPos( FindEmpty( self:GetPos(), self, exclude ) )
                end
                if npc_model != "" then
                    spawn_npc:SetModel( npc_model )
                else
                    if check_class.Model then
                        spawn_npc:SetModel( check_class.Model )
                    end
                end
                timer.Simple( 1, function()
                    spawn_npc:SetHealth( npc_health )
                end )
                local wep
                if npc_weapon != "" then
                    wep = npc_weapon
                else
                    if check_class.Weapons then
                        wep = table.Random( check_class.Weapons )
                    else
                        wep = "weapon_ar2"
                    end
                end
                spawn_npc:Give( wep )
                spawn_npc:SetCurrentWeaponProficiency( npc_prof )
                spawn_npc:Spawn()
                spawn_npc:Activate()
                local newpos = spawn_npc:GetPos() + Vector( math.random( -100, 100 ), math.random( -100, 100 ), 0 )
                timer.Simple( 0.1, function()
                    spawn_npc:SetLastPosition( newpos )
                    spawn_npc:SetSchedule( SCHED_FORCED_GO_RUN )
                end )
                for _, ply in ipairs( player.GetAll() ) do 
                    if npc_relations == "1" then
                        spawn_npc:AddEntityRelationship( ply, D_HT, 99 )
                    elseif npc_relations == "3" then
                        spawn_npc:AddEntityRelationship( ply, D_LI, 99 )
                    end
                end
                spawned = spawned + 1
                if spawned >= tonumber( amount ) then
                    self.spawning_finished = true
					self.landing = false
                end
            end
        end )
    end
    return true
end

function ENT:Hover()
    if self.is_hovered then return end
    if !self.is_hovering then
        self.is_hovering = true
        self:SetSpeed( 0 )
    end

    local curr = self:GetPos()
        
    if curr.z < self.hover_z then
        local asc = Vector( curr.x, curr.y, curr.z + 1 * 50 * FrameTime() )
        self:SetPos(asc)
    else
        self:SetPos( Vector( curr.x, curr.y, self.hover_z + 30 ) )
        self:SetSpeed( 0 )
        self:SetMoveType( MOVETYPE_NONE )
        local ang = self:GetAngles()
        self:SetAngles( Angle( 0, ang.yaw, 0 ) ) -- It rotates when it lands so need to set this.
        local hover_pos = self:GetPos()
        local tr_data = {}
        tr_data.start = hover_pos
        tr_data.endpos = hover_pos - Vector( 0, 0, 500 )
        tr_data.filter = self
        local tr = util.TraceLine( tr_data )
        local gpos = tr.HitPos
        local length = ( gpos - curr ):Length()
        if self.rope_created then return end
        self.rope_1 = constraint.Rope( self, game.GetWorld(), 0, 0, Vector( 0, 50, -15 ), gpos + Vector( 0, 100, 0 ), length * 1.5, -100, 0, 10, "cable/cable2", false, Color( 0, 0, 0, 255 ) )
        self.rope_2 = constraint.Rope( self, game.GetWorld(), 0, 0, Vector( 0, -50, -15 ), gpos + Vector( 0, -100, 0 ), length * 1.5, -100, 0, 10, "cable/cable2", false, Color( 0, 0, 0, 255 ) )
        self.rope_created = true
        local class = npc_class
        self:DoSpawning( class, npc_amount )
        self.is_hovered = true
    end
end

function ENT:Land()
    if self.has_landed then return end
    if !self.landing then
        self.landing = true
        self:SetSpeed( 50 )
    end

    local curr = self:GetPos()
    
    if curr.z > self.final_z + 50 then
        local desc = Vector( curr.x, curr.y, curr.z -2 * self:GetSpeed() * FrameTime() )
        self:SetPos( desc )
    else
        --self:DropToFloor()
        self:SetPos( self:GetPos() )
        self:SetSpeed( 0 )
        self:SetMoveType( MOVETYPE_NONE )
        local ang = self:GetAngles()
        self:SetAngles( Angle( 0, ang.yaw, 0 ) ) -- It rotates when it lands so need to set this.
        local class = npc_class
        self:DoSpawning( class, npc_amount )
        self.has_landed = true
    end
end

function ENT:SetSpeed( value )
    self.speed = value
end

function ENT:GetSpeed()
    return self.speed || 200 -- Default.
end

-- TRY and move around buildings, entities etc.
-- This kinda does what I need it to do, very little, but it does it.
function ENT:CheckPath( curr_pos, direction, dist )
    local tr_data = {}
    tr_data.start = curr_pos
    tr_data.endpos = curr_pos + direction * 3000
    tr_data.filter = self
    tr_data.ignoreworld = false
    tr_data.mins = Vector( -400, -400, -0 )
    tr_data.maxs = Vector( 400, 400, 200 )

    local trace = util.TraceHull( tr_data )
    local avoid_roll = 0
    local avoid_pitch = 0
    if trace.Hit then
        local normal = trace.HitNormal
        local hit_pos = trace.HitPos
        local right_vec = self:GetRight()
        local up_vec = self:GetUp()
        local to_hit = ( hit_pos - curr_pos ):GetNormalized()
        local side = right_vec:Dot( to_hit )
        local up = up_vec:Dot( to_hit )
        local avoid_dir = Vector( 0, 0, 0 )
        if math.abs( normal.z ) < 0.7 then
            if side > 0 then
                avoid_dir = -right_vec
                avoid_roll = -25
            else
                avoid_dir = right_vec
                avoid_roll = 25
            end
            if dist > 600 then
                if up < 0.3 then
                    avoid_dir = avoid_dir + up_vec
                else
                    avoid_dir = avoid_dir + -up_vec
                end
            end
        else
            avoid_dir = Vector( 0, 0, 0 )
        end
        avoid_dir = ( direction + avoid_dir * 0.5 ):GetNormalized()
        return true, avoid_dir, avoid_roll
    end
    return false, direction, 0
end

function ENT:WatchAngles( ang )
    local curr = self:GetAngles()
    local target
    if self.is_crashing then
        target = Angle( ang.pitch, ang.yaw, ang.roll )
    else
        target = Angle( curr.pitch, ang.yaw, ang.roll )
    end
    local smooth = LerpAngle( FrameTime() * 2, curr, target )
    self:SetAngles( smooth )
end

function ENT:OnTakeDamage( dmg )
    self:TakePhysicsDamage( dmg )
    if self:Health() <= 0 then return end
    if self.is_hovered then return end
    self:SetHealth( math.Clamp( self:Health() - dmg:GetDamage(), 0, self:GetMaxHealth() ) )
    if self:Health() <= 0 then
        if self.is_crashing then return end
        self.is_crashing = true
        local speed = 2000
        self:SetSpeed( speed )
        local rand = math.random( 1, 3 )
        self.crash_dir = ( rand == 1 && "left" ) || ( rand == 2 && "right" ) || "forward"
        local splode = ents.Create( "env_explosion" )
        splode:SetKeyValue( "iMagnitude", 15 )
        splode:SetPos( dmg:GetDamagePosition() )
        splode:Spawn()
        splode:Fire( "explode", "", 0 )
        if not IsValid(self.smoke_trail) then
            self.smoke_trail = ents.Create( "env_smokestack" )
            if IsValid( self.smoke_trail ) then
                self.smoke_trail:SetPos( dmg:GetDamagePosition() )
                self.smoke_trail:SetKeyValue( "InitialState", "1" )
                self.smoke_trail:SetKeyValue( "BaseSpread", "30" )
                self.smoke_trail:SetKeyValue( "SpreadSpeed", "15" )
                self.smoke_trail:SetKeyValue( "Speed", "80" )
                self.smoke_trail:SetKeyValue( "StartSize", "80" )
                self.smoke_trail:SetKeyValue( "EndSize", "100" )
                self.smoke_trail:SetKeyValue( "Rate", "200" )
                self.smoke_trail:SetKeyValue( "JetLength", "60" )
                self.smoke_trail:SetKeyValue( "twist", "5" )
                self.smoke_trail:SetKeyValue( "SmokeMaterial", "particle/smokesprites_0001" )
                self.smoke_trail:Spawn()
                self.smoke_trail:Activate()
                self.smoke_trail:SetParent( self )
            end
        end
        SafeRemoveEntity( self.rope_1 )
        SafeRemoveEntity( self.rope_2 )
    end
end

function ENT:DoImpact( pos )
    local crash_effect = EffectData()
    crash_effect:SetOrigin( pos )
    crash_effect:SetEntity( self )
    crash_effect:SetScale( 2.5 )
    crash_effect:SetMagnitude( 15 )
    util.Effect( "m9k_gdcw_s_boom", crash_effect )
    util.ScreenShake( self:GetPos(), 16, 250, 1, 512 )
    self:EmitSound( "boom_sounds/impact_" .. tostring( math.random( 1, 3 ) .. ".ogg" ), 150, math.Rand( 80, 120 ) )
    local fire_positions = {
        pos,
        pos + Vector( 100, 0, 0 ),
        pos + Vector( -100, 0, 0 ),
        pos + Vector( 0, 100, 0 ),
        pos + Vector( 0, -100, 0 )
    }
    for _, new_pos in pairs( fire_positions ) do
        self.fire = ents.Create( "env_fire" )
        if IsValid( self.fire ) then
            self.fire:SetPos( new_pos )
            self.fire:SetKeyValue( "health", tostring( dship_remove -2 ) )
            self.fire:SetKeyValue( "firesize", "250" )
            self.fire:SetKeyValue( "fireattack", "1" )
            self.fire:SetKeyValue( "damagescale", "4.0" )
            self.fire:SetKeyValue( "spawnflags", "128" )
            self.fire:SetKeyValue( "ignitionpoint", "0" )
            self.fire:SetKeyValue( "StartDisabled", "0" )
            self.fire:Spawn()
            self.fire:Activate()
            self.fire:Fire( "StartFire", "", 0 )
            self.fire:SetParent( self )
        end
    end
    if IsValid( self.smoke_trail ) then
        SafeRemoveEntity( self.smoke_trail )
    end
    timer.Simple( dship_remove, function() 
        if IsValid( self.fire ) then
            SafeRemoveEntity( self.fire )
        end
        if !IsValid( self ) then return end
        local boom_effect = EffectData()
        boom_effect:SetOrigin( pos )
        boom_effect:SetEntity( self )
        boom_effect:SetScale( 3.5 )
        boom_effect:SetMagnitude( 20 )
        util.Effect( "dropship_explosion", boom_effect )
        local gpos = self:GetPos()
        util.ScreenShake( gpos, 16, 250, 1, 512 )
        self:EmitSound( "boom_sounds/ship_explode.wav", 120, math.Rand( 80, 120 ) )
        SafeRemoveEntity( self )
    end )
end