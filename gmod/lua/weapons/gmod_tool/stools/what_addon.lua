
TOOL.Category = "Stoneman"
TOOL.Name = "Addon Finder"


if CLIENT then
	language.Add( "tool.what_addon.name", "Addon Finder" )
	language.Add( "tool.what_addon.desc", "What addon is this model from?" )
	language.Add( "tool.what_addon.0", "Left click to find what addon something is from." )
else
    AddCSLuaFile("includes/modules/af_derma_extension.lua")
end

TOOL.ClientConVar[ "item_name" ] = "100"

// It seems like we have to do it for each fucking category for fuck sake
if CLIENT then
    local function DownloadPreviewImage(wsid, AddonIcon)
        steamworks.FileInfo( wsid, function( result )
            steamworks.Download( result.previewid, true, function( name )
                if not name then return end
                if not AddonIcon then return end
                AddonIcon:SetMaterial( AddonMaterial( name ) )
            end) 
        end)
    end

    local function SearchAddonsFrom(target, wildcard)
        // Open a new vgui for addon info!!!
        local AddonFrame = vgui.Create( "DFrame" )
        AddonFrame:SetSize( 750, 500 )
        AddonFrame:Center()
        AddonFrame:MakePopup()
        AddonFrame:SetTitle( "Addon Finder" )
        AddonFrame:SetVisible( true )
        AddonFrame:SetDraggable( true )
        AddonFrame:ShowCloseButton( true )
        // Make it blur background
        AddonFrame:SetBackgroundBlur( true )
        AddonFrame.Paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 200 ) )
        end

        // Addon's icon!
        local AddonIcon = vgui.Create( "DImage", AddonFrame )
        AddonIcon:SetSize( 128, 128 )
        AddonIcon:Center()
        AddonIcon:SetPos( AddonIcon:GetX(), 32)
        AddonIcon:SetImage( "icon16/box.png" )

        // A bunch of data for the prop, and addon..
        local AddonName = vgui.Create( "DLabel", AddonFrame )
        AddonName:SetSize( 750, 32 )
        AddonName:SetPos( 32, AddonIcon:GetY() + 128 + 32 )
        AddonName:SetFont( "Trebuchet24" )
        AddonName:SetText( "Addon Name: Not Found!" )
        
        local FilePath = vgui.Create( "DLabel", AddonFrame )
        FilePath:SetSize( 750, 32 )
        FilePath:SetPos( 32, AddonName:GetY() + 32 )
        FilePath:SetFont( "Trebuchet24" )
        FilePath:SetText( "File Path: Not Found!" )

        local FileSize = vgui.Create( "DLabel", AddonFrame )
        FileSize:SetSize( 750, 32 )
        FileSize:SetPos( 32, FilePath:GetY() + 32 )
        FileSize:SetFont( "Trebuchet24" )
        FileSize:SetText( "File Size: Not Found!" )

        local GMAFile = vgui.Create( "DLabel", AddonFrame )
        GMAFile:SetSize( 750, 32 )
        GMAFile:SetPos( 32, FileSize:GetY() + 32 )
        GMAFile:SetFont( "Trebuchet24" )
        GMAFile:SetText( "GMA File: Not Found!" )

        // If it's not found, then it must be mounted from the addon folder.
        if FileSize:GetText() == "File Size: Not Found!" then
            AddonName:SetText( "Addon Name: Unknown" )
            FilePath:SetText( "File Path: " .. target )
            FileSize:SetText( "File Size: " .. file.Size( target, "GAME" ) / 1000000 .. " MB" )
        end

        // Button to visit the addon's page
        local VisitAddon = vgui.Create( "DButton", AddonFrame )
        VisitAddon:SetSize( 128, 32 )
        VisitAddon:Center()
        VisitAddon:SetY( AddonFrame:GetTall() - 64 )
        VisitAddon:SetText( "Open Workshop Page" )

        local result = StonemanAddonSearcherCache[target]

        // If you can't find it, but it's an entity, search for model instead!
        if result == nil and wildcard == "entity" then
            local npc = list.Get( "NPC" )[target]
            if npc then
                local model = npc.Model
                if model then model = string.lower( model ) end
                
                result = StonemanAddonSearcherCache[model]
            end

            if result == nil then
                local vehicle = list.Get( "Vehicles" )[target]
                if not vehicle then return end
                local model = vehicle.Model
                if model then model = string.lower( model ) end

                result = StonemanAddonSearcherCache[model]
            end
        end

        for _, addon in pairs( engine.GetAddons() ) do
            if result == addon.title then
                DownloadPreviewImage(addon.wsid, AddonIcon)
                AddonName:SetText( "Addon Name: " .. addon.title )
                FilePath:SetText( "File Path:" )
                // Make another label for file path
                local FilePathName = vgui.Create( "DLabel", AddonFrame )
                FilePathName:SetSize( 750, 32 )
                FilePathName:SetPos( FilePath:GetX() + 128, FilePath:GetY() )
                FilePathName:SetFont( "Trebuchet18" )
                FilePathName:SetText( target )

                if wildcard == "entity" then
                    FilePath:SetText( "Entity Name: " )
                elseif wildcard == "model" then
                    FilePath:SetText( "Model Path: " )
                elseif wildcard == "weapon" then
                    FilePath:SetText( "Weapon: " )
                elseif wildcard == "map" then
                    FilePath:SetText( "Map: " )
                end

                // Directly under the filepathname is a secret invisible button that copies the file path to clipboard
                local CopyFilePath = vgui.Create( "DButton", AddonFrame )
                CopyFilePath:SetSize( 750, 32 )
                CopyFilePath:SetPos( FilePathName:GetX(), FilePathName:GetY() )
                CopyFilePath:SetText( "" )
                CopyFilePath:SetToolTip( "Copy file path to clipboard")
                CopyFilePath.DoClick = function()
                    SetClipboardText( target )
                end
                CopyFilePath.Paint = function( self, w, h )
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
                end

                // File size, we translate to megabytes! (10^6)
                FileSize:SetText( "File Size: " .. addon.size / 1000000 .. " MB" )
                GMAFile:SetText( "GMA File: ")
                // Make another label for GMA File Name
                local GMAFileName = vgui.Create( "DLabel", AddonFrame )
                GMAFileName:SetSize( 750, 32 )
                GMAFileName:SetPos( GMAFile:GetX() + 128, GMAFile:GetY() )
                GMAFileName:SetFont( "Trebuchet18" )
                GMAFileName:SetText( addon.file )

                // Directly under the GMAFileName is a secret invisible button that copies the file path to clipboard
                local CopyGMAFile = vgui.Create( "DButton", AddonFrame )
                CopyGMAFile:SetSize( 750, 32 )
                CopyGMAFile:SetPos( GMAFileName:GetX(), GMAFileName:GetY() )
                CopyGMAFile:SetText( "" )
                CopyGMAFile:SetToolTip( "Copy GMA file name to clipboard")
                CopyGMAFile.DoClick = function()
                    SetClipboardText( addon.file )
                end
                CopyGMAFile.Paint = function( self, w, h )
                    draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 0, 0, 0 ) )
                end
                
                VisitAddon.DoClick = function()
                    gui.OpenURL( "http://steamcommunity.com/sharedfiles/filedetails/?id=" .. addon.wsid )
                end
                return
            end
        end
    end

    concommand.Add("stoneman_search_addons", function(ply, cmd, args)
        local target = args[1]
        local wildcard = args[2]
        SearchAddonsFrom(target, wildcard)
    end)

    -- SilkIcons
    local egs_icon = "icon16/egs.png"
    local creator_icon = "icon16/wand.png"
    local delete_icon = "icon16/cross.png"
    local copy_icon = "icon16/page_copy.png"
    local search_icon = "icon16/magnifier.png"
    -- Prop Launcher compatability
    local pl_icon = "icon16/prop_launcher.png"

    local function CheckInstalledEGS()
        if file.Exists( "addons/entity_group_spawner_951638840.gma", "GAME" ) == true then
            return true
        elseif file.Exists( "weapons/gmod_tool/stools/egs.lua", "LUA") == true then
            return true
        else
            return false
        end
    end

    local function AddRecursive(addon, folder, wildcard)
        local files, folders = file.Find( folder .. "*", addon )
        if ( !files ) then MsgN( "Warning! Not opening '" .. folder .. "' because we cannot search in it!"  ) return false end
    
        for k, v in pairs( files ) do
            if wildcard == "weapon" or wildcard == "entity" then
                if ( !string.EndsWith( v, ".lua" ) ) then continue end
                local found = v
                
                // Remove the .lua extension
                found = string.gsub(found, ".lua", "")
                found = string.lower(found)
                StonemanAddonSearcherCache[found] = addon

                continue
            else
                if ( !string.EndsWith( v, ".mdl" ) ) then continue end
                local found = folder..v
                found = string.lower(found)
                StonemanAddonSearcherCache[found] = addon

                continue
            end
        end
    
        for k, v in pairs( folders ) do 
            if wildcard == "weapon" or wildcard == "entity" then
                local found = v
                found = string.lower(found)
                StonemanAddonSearcherCache[found] = addon

                continue
            else
                AddRecursive( addon, folder .. v .. "/", wildcard )
            end
        end
    end

    local function SearchForMaps(addon)
        local files, folders = file.Find(  "maps/".. "*", addon )
        for k, v in pairs( files ) do
            if ( !string.EndsWith( v, ".bsp" ) ) then continue end
            local found = v
            found = string.gsub(found, ".bsp", "")
            StonemanAddonSearcherCache[found] = addon
        end
    end
    
    local function BeginSearching()
        // Put all models into a table. Every last one.
        for _, addon in SortedPairsByMemberValue( engine.GetAddons(), "title" ) do
            if addon.mounted and addon.downloaded then
                AddRecursive(addon.title, "models/", "model")
                AddRecursive(addon.title, "lua/weapons/", "weapon")
                AddRecursive(addon.title, "lua/entities/", "entity")
                SearchForMaps(addon.title)
            end
        end
    end
    
    hook.Add("InitPostEntity", "StonemanAddonSearcher:Cache", function()
        StonemanAddonSearcherCache = {}
        BeginSearching()
    end)
    
    concommand.Add("stoneman_search_addons_reload", function()
        StonemanAddonSearcherCache = {}
        BeginSearching()
    end)

    require('af_derma_extension')

    local validContentTypes = {
        ['weapon'] = true,
        ['entity'] = true,
        ['npc'] = true,
        ['vehicle'] = true
    }

    hook.Add('AF.ContentIconMenuExtraOpened', 'addon_finder_option', function(contentIcon, dmenu)
        if not isfunction(contentIcon.GetContentType) then
            dmenu:AddOption('Find Addon', function()
                RunConsoleCommand("stoneman_search_addons", contentIcon:GetModelName(), "model")
            end):SetImage('icon16/magnifier.png')
        else
            local ContentType = contentIcon:GetContentType()

            if ContentType and validContentTypes[ContentType] then
                dmenu:AddOption('Find Addon', function()
                    if ContentType == "weapon" then
                        RunConsoleCommand("stoneman_search_addons", contentIcon:GetSpawnName(), "weapon")
                    else
                        RunConsoleCommand("stoneman_search_addons", contentIcon:GetSpawnName(), "entity")
                    end
                end):SetImage('icon16/magnifier.png')
            end
        end
    end)
end

function TOOL.BuildCPanel( CPanel )
	CPanel:AddControl("Header", { Text = "#tool.what_addon.name", Description = "#tool.what_addon.desc" })
	// a text fill that accepts stuff
	local TextEntrys = vgui.Create("DTextEntry")
	TextEntrys:SetSize(200, 30)
	TextEntrys:SetText("")
	TextEntrys.OnEnter = function(self)
		// If it doesn't end with .mdl, nothing happens
		local text = self:GetValue()
		if not string.EndsWith(text, ".mdl") then return end
		RunConsoleCommand("stoneman_search_addons", self:GetValue(), ".mdl")
	end

	CPanel:AddItem(TextEntrys)

	// Reset / Refresh button!
	local button = vgui.Create("DButton")
	button:SetText("Search!")
	button:SetSize(200, 30)
	button.DoClick = function()
		RunConsoleCommand("stoneman_search_addons", TextEntrys:GetValue(), ".mdl")
	end

    CPanel:AddItem(button)
    // Get current map button!
    local button2 = vgui.Create("DButton")
    button2:SetText("Search for current map!")
    button2:SetSize(200, 30)
    button2.DoClick = function()
        RunConsoleCommand("stoneman_search_addons", game.GetMap(), "map")
    end

    CPanel:AddItem(button2)
end

local DisallowedEntities = {
    "prop_physics",
    "prop_physics_multiplayer",
    "prop_physics_respawnable",
    "prop_ragdoll",
    "prop_dynamic",
    "prop_dynamic_ornament",
    "prop_dynamic_override",
    "func_brush",
}

local function CheckForValidTrace(tr)
	// See what entity something is from
	if not tr.Entity then return end
	if not tr.Entity:IsValid() then return end
	if tr.Entity:IsWorld() then return end
    if tr.Entity:IsWeapon() then
	    RunConsoleCommand("stoneman_search_addons", tr.Entity:GetClass(), "weapons")
    elseif tr.Entity:IsNPC() or tr.Entity:IsNextBot() or tr.Entity:IsScripted() then
        RunConsoleCommand("stoneman_search_addons", tr.Entity:GetClass(), "entity")
    else
        RunConsoleCommand("stoneman_search_addons", tr.Entity:GetModel(), "models")
    end
end

function TOOL:LeftClick(tr)
    if not IsFirstTimePredicted() then return end
    if game.SinglePlayer() then
        CheckForValidTrace(tr)
    end
    
    if SERVER then return end

    CheckForValidTrace(tr)
	return false
end