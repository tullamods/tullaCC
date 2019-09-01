local AddonName, Addon = ...

do
    local eventHandler = CreateFrame('Frame')

    eventHandler:Hide()

    eventHandler:SetScript("OnEvent", function(self, event, ...)
        local f = Addon[event]
        if type(f) == "function" then
            f(Addon, event, ...)
        end
    end)

    Addon.eventHandler = eventHandler
end

function Addon:OnEvent(event, ...)
    local f = self[event]
    if type(f) == "function" then
        f(self, event, ...)
    end
end

function Addon:ADDON_LOADED(event, name)
    if name ~= AddonName then return end

    self.eventHandler:UnregisterEvent(event)
    self.Cooldown:SetupHooks()
end

_G[AddonName] = Addon
