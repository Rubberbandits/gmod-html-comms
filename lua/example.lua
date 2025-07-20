function example()
    local panel = vgui.Create("DPanel")
    panel:SetSize(ScrW(), ScrH())
    panel:SetPos(0, 0)
    function panel:Paint(w, h)
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, w, h)
    end

    local html = vgui.Create("AHTML", panel)
    html:Dock(FILL)
    html:OpenURL("https://google.com/")
    html:MakePopup()

    -- This is the best example of why this helper was created, it removes a lot of boilerplate around trying to notify the browser of some long running operation.
    -- For example, I have a function that creates a character. We send the client's input like the character name to the server, then the server replies with another message, in which we call our callback in createSomethingOnServer.
    -- Returning a function from the function passed as the second argument to AHTML:Expose tells the browser it needs to setup a callback, which the Lua state will call with QueueJavascript.
    html:Expose("longRunningOperation", function(data)
        return function(callback)
            createSomethingOnServer(data, function(err, returnedData, errMsg)
                if err then
                    callback({error = errMsg})
                    return
                end

                callback(returnedData)
            end)
        end
    end)
end
