local function main(process, file, delay, expectReturn, channel)
    if process == "read" then
        local iota = readIota(file)
        print(textutils.serialise(iota))
    elseif process == "load" then
        local iota = readIota(file)
        local port = peripheral.find("focal_port")
        if port == nil then
            error("no port")
        else
            if port.canWriteIota() then
                port.writeIota(iota)
            else
                error("can't write iota")
            end
        end
    elseif process == "write" then
        writeIota(file)
    elseif process == "cast" then
        local spell = readIota(file)
        
        require("magic")
        delay = tonumber(delay)
        channel = tonumber(channel)
        
        out = cast(spell, nil, delay, expectReturn, channel)
        if expectReturn then
            if type(out) ~= table then
                print(tostring(out))
            else
                print(textutils.serialise(out))
            end
        end
    end
end


function writeIota(file, iota, folder)
    if iota == nil then
        local port = peripheral.find("focal_port")
        if port then
            iota = port.readIota()
        else
            error("no port")
        end
    end
    
    if folder == nil then folder = "disk/iotas" end
    io.output(folder .. "/" .. file .. ".hexIota")
    
    if type(iota) == "table" then
        io.write(textutils.serialise(iota))
    else
        io.write(tostring(iota))
    end
end


function readIota(file, folder)
    if folder == nil then folder = "disk/iotas" end
    
    if not pcall(function () io.input(folder .. "/" .. file .. ".hexIota") end ) then
        return nil
    end

    return textutils.unserialise(io.read())
end


main(...)