local AddonName, Addon = ...

do
    local eventHandler = CreateFrame("Frame")

    eventHandler:Hide()

    eventHandler:SetScript(
        "OnEvent",
        function(self, event, ...)
            local f = Addon[event]
            if type(f) == "function" then
                f(Addon, event, ...)
            end
        end
    )

    Addon.eventHandler = eventHandler
end

function Addon:OnEvent(event, ...)
    local f = self[event]
    if type(f) == "function" then
        f(self, event, ...)
    end
end

function Addon:PLAYER_LOGIN()
    self:SetupDatabase()
    self.Cooldown:SetupHooks()
end

function Addon:PLAYER_LOGOUT()
    self:CleanupDatabase()
end

Addon.eventHandler:RegisterEvent("PLAYER_LOGIN")
Addon.eventHandler:RegisterEvent("PLAYER_LOGOUT")

-- luacheck: push ignore 122
_G[AddonName] = Addon
-- luacheck: pop
