Hologram = Hologram or {}
Hologram.EntsCache = Hologram.EntsCache or {} -- fuck fuck fuck fuck

local allowedClasses = {
	["prop_physics"] = true,
	["prop_dynamic"] = true,
}

hook.Add("InitPostEntity","Hologram.InitialTableCache",function()
	for k, v in ipairs(ents.GetAll()) do
		if not IsValid(v) then continue end
		if not v:EntIndex() or v:EntIndex() < 0 then continue end --serverside/client only entities can go to hell
		
		if allowedClasses[v:GetClass()] or ( v:IsWeapon() or v:IsNPC() or ( v:IsPlayer() and v:Alive() ) or v:IsNextBot() or v:IsVehicle() or v:IsRagdoll() or v:IsScripted() ) then
			Hologram.EntsCache[v:EntIndex()] = nil --By default, nothing is a hologram
		end
	end
end)

hook.Add("OnEntityCreated","Hologram.AddNewEntsToTable",function(ent)
	Hologram.EntsCache[ent:EntIndex()] = nil --By default, nothing is a hologram
end)

hook.Add("EntityRemoved","Hologram.RemovedEntsFromTable",function(ent)
	Hologram.EntsCache[ent:EntIndex()] = nil --Using entindexes as keys rather than the ents themselves bc less expensive I hope
end)

hook.Add("PlayerInitialSpawn","Hologram.NetworkHologramTableOnSpawn",function(ply)
	Hologram.EntsCache = Hologram.EntsCache or {}
end)


if CLIENT then
	Hologram = Hologram or {}

	Hologram.EntsCache = Hologram.EntsCache or {}

	
	net.Receive("Hologram.Tool.UpdateEntity", function(len,ply)
		local index = net.ReadUInt(16)
		local bIsHologram = net.ReadBool()
		if bIsHologram then
			Hologram.EntsCache[index] = true
		else
			Hologram.EntsCache[index] = nil
		end

	end)


	local Clr_holo_Ents = 
	{
		[ "$pp_colour_addr" ] 		= 0,
		[ "$pp_colour_addg" ] 		= 0.3,
		[ "$pp_colour_addb" ] 		= 1,
		[ "$pp_colour_brightness" ] = 0,
		[ "$pp_colour_contrast" ]	= 1,
		[ "$pp_colour_colour" ] 	= 1,
		[ "$pp_colour_mulr" ] 		= 0,
		[ "$pp_colour_mulg" ] 		= 0,
		[ "$pp_colour_mulb" ] 		= 0
	}

	local Clr_normal =
	{
		[ "$pp_colour_addr" ] 		= 0,
		[ "$pp_colour_addg" ] 		= 0,
		[ "$pp_colour_addb" ] 		= 0,
		[ "$pp_colour_brightness" ] = 0,
		[ "$pp_colour_contrast" ]	= 1,
		[ "$pp_colour_colour" ] 	= 1,
		[ "$pp_colour_mulr" ] 		= 0,
		[ "$pp_colour_mulg" ] 		= 0,
		[ "$pp_colour_mulb" ] 		= 0
	}
	local holomat = Material("ace/sw/hologram")

	hook.Add("PreDrawEffects", "HologramDraw", function(isDrawingDepth, isDrawingSkybox)

		--if isDrawingDepth then return true end --Fuck if i know whether or not I need this
		-- Reset everything to known good

		render.SetStencilWriteMask( 0xFF )
		render.SetStencilTestMask( 0xFF )
		render.SetStencilReferenceValue( 0 )
		render.SetStencilCompareFunction( STENCIL_ALWAYS )
		render.SetStencilPassOperation( STENCIL_KEEP )
		render.SetStencilFailOperation( STENCIL_KEEP )
		render.SetStencilZFailOperation( STENCIL_KEEP )
		render.ClearStencil()


		--this whole bit draws models to the first stencil buffer, i think
		render.OverrideDepthEnable(false, true)
		render.SetStencilEnable(true)
		render.SetStencilFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
		render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
		render.SetStencilReferenceValue(44)

		--this is probably a really shit way to do this, but it's fine for now
		for index, bHologram in pairs ( Hologram.EntsCache ) do
			local ent = ents.GetByIndex(index)
			if IsValid(ent) and bHologram then
				--this if statement is stupid but i dont really care, since it works and performance impact isnt too bad i think
				if ( (!ent:IsWorld() and !ent:IsWeapon())) then --and ( ent:IsNPC() or (ent:IsPlayer() and ent:Alive()) or ( ent:GetClass() == "prop_physics" || "prop_dynamic") ) and bHologram ) then
					if not ent:IsEffectActive(EF_NODRAW) then --we do this as a dumb check to see if something is dead or not
						render.SuppressEngineLighting(true)
							ent:DrawModel() --draw model to stencil buffer
						render.SuppressEngineLighting(false)
					end
				end
			end
		end
			
		render.SuppressEngineLighting(true) --why???

		--Setup stencil for drawing only shit that matches stencil reference value 1 or something
		render.SetStencilReferenceValue(45)
		render.SetStencilCompareFunction( STENCILCOMPARISONFUNCTION_EQUAL )
		render.SetStencilPassOperation( STENCILOPERATION_REPLACE )
		render.SetStencilReferenceValue(44)
		DrawColorModify(Clr_holo_Ents)

		--cool shit that makes holograms look good
		render.OverrideBlend(true, BLEND_DST_COLOR, BLEND_SRC_COLOR, BLENDFUNC_ADD, BLEND_ONE, BLEND_ONE, BLENDFUNC_ADD)
		render.SetColorMaterialIgnoreZ()
		render.SetMaterial(holomat)

		render.DrawScreenQuad(true) --draws hologram material to whole screen but only the parts matching the stencil buffer

		--reset everything to how it should be i think
		render.OverrideBlend(false)
		render.SuppressEngineLighting(false)
		render.SetStencilEnable( false )
		--render.DepthRange(0.0,1.0) --not sure what this does

		DrawColorModify(Clr_normal)
	end)

end
