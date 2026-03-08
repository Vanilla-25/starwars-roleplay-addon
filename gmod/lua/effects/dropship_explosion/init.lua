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

-- Explosion attempt.

function EFFECT:Init( data )
    local pos = data:GetOrigin()
    local norm = data:GetNormal() || Vector( 0, 0, 1 )

    for i = 1, 15 do 
        local smoke = ParticleEmitter( pos )
        local particle = smoke:Add( "particle/smokesprites_000" .. math.random( 1, 9 ), pos )
        if particle then
            particle:SetVelocity( VectorRand() * 850 )
            particle:SetLifeTime( 0 )
            particle:SetDieTime( 2 + math.random() * 3 )
            particle:SetStartAlpha( 255 )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( 200 )
            particle:SetEndSize( 300 )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -2, 2) )
            particle:SetColor( 60, 60, 60 )
            particle:SetAirResistance( 200 )
            particle:SetGravity( Vector( 0, 0, 50 ) )
        end
        smoke:Finish()
    end

    -- Fire particles
    for i = 1, 7 do
        local fire = ParticleEmitter( pos )
        local particle = fire:Add( "particles/flamelet" .. math.random( 1, 5 ), pos )
        
        if particle then
            particle:SetVelocity( VectorRand() * 650 + Vector( 0, 0, math.random( 50, 100 ) ) )
            particle:SetLifeTime( 0 )
            particle:SetDieTime( math.Rand( 2, 3 ) )
            particle:SetStartAlpha( 255 )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( 200 )
            particle:SetEndSize( 300 )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -2, 2 ) )
            particle:SetColor( 255, 150, 100 )
            particle:SetAirResistance( 100 )
            particle:SetGravity( Vector( 0, 0, 100 ) )
        end

        fire:Finish()
    end

    -- Debris particles
    for i = 1, 8 do
        local debris = ParticleEmitter( pos )
        local particle = debris:Add( "effects/fleck_cement" .. math.random( 1, 2 ), pos )
        
        if particle then
            particle:SetVelocity( VectorRand() * 400 + Vector( 0, 0, 200 ) )
            particle:SetLifeTime( 0 )
            particle:SetDieTime( math.Rand( 1, 2 ) )
            particle:SetStartAlpha( 255 )
            particle:SetEndAlpha( 0 )
            particle:SetStartSize( 5 )
            particle:SetEndSize( 0 )
            particle:SetRoll( math.Rand( 0, 360 ) )
            particle:SetRollDelta( math.Rand( -1, 1 ) )
            particle:SetColor( 100, 100, 100 )
            particle:SetAirResistance( 50 )
            particle:SetGravity( Vector( 0, 0, -600 ) )
        end

        debris:Finish()
    end
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
    -- Don't need this as we only use particles.
end