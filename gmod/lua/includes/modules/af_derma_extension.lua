-- DermaMenu hook extension by Zaurzo
-- idk why i had to do this just to add one derma button

-- I put this file in includes/modules so you can only require it once so the 'DMenu:Open()' detour doesn't stack
-- If you want to use this hook, make sure this file is in includes/modules, and put this somewhere in your code:
--
-- if CLIENT then
--     require('af_derma_extension') 
-- end

-- ^^^ thank you Zaurzo, this is a dream

local type = type
local debug_getupvalue = debug.getupvalue

timer.Simple(0, function()
    local DMenu = vgui.GetControlTable('DMenu')
    local Open = DMenu.Open

    function DMenu:Open(...)
        Open(self, ...)

        local options, contentIcon = self:GetChildren()[1]

        if IsValid(options) then
            options = options:GetChildren()

            if options then
                for k, option in ipairs(options) do
                    local func = option.DoClick
        
                    if func then
                        for i = 1, 10 do
                            local k, v = debug_getupvalue(func, i)
                            if not k then break end
        
                            if type(v) == 'Panel' and IsValid(v) then
                                local name = v:GetName()

                                if name == 'ContentIcon' or name == 'SpawnIcon' then
                                    contentIcon = v
                                    break
                                end
                            end
                        end
        
                        if contentIcon then
                            hook.Run('AF.ContentIconMenuExtraOpened', contentIcon, self)
                            break
                        end
                    end
                end
            end
        end
    end
end)