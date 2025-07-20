local PANEL = {}

local function cast_from(any)
    // We always want a table for typecasting, as we expect some information about the type to be passed from JavaScript.
    if not istable(any) then
        return any
    end

    if any.type == "player" then
        // any.value should be UserID
        return Player(any.value)
    elseif any.type == "entity" then
        // any.value should be EntIndex
        return Entity(any.value)
    elseif any.type == "vector" then
        return Vector(any.value.x, any.value.y, any.value.z)
    elseif any.type == "angle" then
        return Angle(any.value.p, any.value.y, any.value.r)
    elseif any.type == "color" then
        return Color(any.value.r, any.value.g, any.value.b, any.value.a or 255)
    else
        return any
    end
end

local function cast_to(any)
    if type(any) == "Player" then
        return { type = "player", value = any:UserID() }
    elseif type(any) == "Entity" then
        return { type = "entity", value = any:EntIndex() }
    elseif type(any) == "Vector" then
        return { type = "vector", value = { x = any.x, y = any.y, z = any.z } }
    elseif type(any) == "Angle" then
        return { type = "angle", value = { p = any.p, y = any.y, r = any.r } }
    elseif type(any) == "Color" then
        return { type = "color", value = { r = any.r, g = any.g, b = any.b, a = any.a or 255 } }
    else
        return any
    end
end

function PANEL:Init()
    self.exposed = {}

    self:SetAllowLua(true)

    self:Expose("Player.GetLocalPlayer", LocalPlayer)
    self:Expose("Player.GetName", function(ply)
        if IsValid(ply) then
            return ply:Name()
        end
        return "Unknown Player"
    end)
end

function PANEL:OnBeginLoadingDocument()
    self:AddFunction("gmod", "call", function(unique, key, ...)
        local any = self.exposed[key]
        if not any then
            return {error = "Invalid key: " .. key}
        end

        local casted = {}
        // Make recursive
        for _, v in ipairs({...}) do
            casted[#casted + 1] = cast_from(v)
        end

        if isfunction(any) then
            local returns = any(unpack(casted))
            if not returns then
                return
            end

            // If returns is a function, we know that we are using a callback in our exposed function.
            if isfunction(returns) then
                returns(function(...)
                    local results = {...}
                    // Make recursive
                    for i, v in ipairs(results) do
                        results[i] = cast_to(v)
                    end

                    local javascript = Format("window.callbacks[\"%s\"](\"%s\");", unique, string.Replace(util.TableToJSON(results), "\"", "\\\""))
                    self:QueueJavascript(javascript)
                end)

                return {callback = true}
            end

            if not istable(returns) then
                returns = { returns }
            end

            // Make recursive
            for i, v in ipairs(returns) do
                returns[i] = cast_to(v)
            end
            
            return returns
        end

        // Make recursive
        return cast_to(any)
    end)
end

function PANEL:Emit(channel, event, ...)
    if not self:IsValid() then return end
    self:QueueJavascript("window." .. channel .. ".emit(\"" .. event .. "\", \"" .. string.Replace(util.TableToJSON({...}), "\"", "\\\"") .. "\");")
end

function PANEL:Expose(key, any)
    self.exposed[key] = any
end

vgui.Register("AHTML", PANEL, "DHTML")
