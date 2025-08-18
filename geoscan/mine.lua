Unlimited_works = false

DEBUG = true -- Use this to enable debug prints (you don't really see the console much anyway)
turtle.facing = 1 -- 0 = -Z/north, 1 = +X/east, 2 = +Z/south, 3 = -X/west

Scanner = peripheral.find("geoScanner")

if Unlimited_works then
    Scanner = peripheral.find("universal_scanner") -- different mod, different name and syntax
end

function Scan(distance)
    --[[
        Uses either the advancedPeripherals geoScanner or the universalPeripherals universal_scanner to get a table of surrounding blocks

        args:
            distance: the distance to scan in blocks (scans in a cube with side length 2*distance + 1 centered on the turtle)

        returns:
            a table of blocks
            {
                {
                    name: the name of the block
                    x: the x coordinate of the block realitive to the turtle
                    y: the y coordinate of the block realitive to the turtle
                    z: the z coordinate of the block realitive to the turtle
                    ... (more data, not particularly important in this case)
                },
                ...
            }
    ]]
    if Unlimited_works then
        return Scanner.scan("block", distance) -- different mod, different name and syntax
    end

    return Scanner.scan(distance)
end


-- for whatever reason unlimited works returns coords relative to the turtle's facing direction
function JustifyWorksScan(block)
    local x, z = block.x, block.z -- store x and z for later

    if turtle.facing == 1 then -- east (lines up with default axes)
        return block
    elseif turtle.facing == 3 then -- west (negatives of default axes)
        block.x = x * -1
        block.z = z * -1
        return block
    elseif turtle.facing == 2 then -- south (funky)
        block.x = z * -1
        block.z = x
        return block
    elseif turtle.facing == 0 then -- north (also funky)
        block.x = z
        block.z = x * -1
        return block
    end
end


local function main(target, targetAmount, y_offset, facing)
    if target == "-h"  or target == "--help" then -- help override
        print("Usage: mine <target> <targetAmount> <y_offset> <facing>")
        print("target: the block to mine")
        print("targetAmount: how many of the target to mine")
        print("y_offset: how many blocks down to start")
        print("facing: which direction to face (0 = -Z/north, 1 = +X/east, 2 = +Z/south, 3 = -X/west)")
        return
    end

    turtle.refuel()

    if y_offset ~= nil then
        y_offset = -1 * tonumber(y_offset) -- offset downwards
        if y_offset % 1 ~= 0 then
            print("y_offset must be an integer")
            return
        end
        GoTo(0, y_offset, 0)
    else
        y_offset = 0
    end

    if facing ~= nil then
        facing = tonumber(facing)
        if facing < 0 or facing > 3 or facing % 1 ~= 0 then
            print("facing must be 0, 1, 2, or 3")
            return
        end
        turtle.facing = facing
    end

    if turtle.getFuelLevel() < 1000 then
        print("You need at least 1000 units of fuel to start mining")
        return
    end

    if target == nil then
        print("Must provide a target")
        return
    elseif targetAmount == nil then
        print("must provide an amount of", target, "to mine")
        return
    elseif tonumber(targetAmount) == nil then
        print(targetAmount, "is not a NUMBER")
    end

    targetAmount = tonumber(targetAmount)

    local obtained = 0
    local traveled = {
        x = 0,
        y = 0,
        z = 0
    }

    local scanDistance = 1

    while obtained < targetAmount and turtle.getFuelLevel() > 2 * GetDistance(traveled) do
        local block = Find(target)
        if block ~= nil then
            if DEBUG then
                print("Found", block.name, "at", block.x, block.y, block.z)
            end

            if Unlimited_works then
                block = JustifyWorksScan(block)
            end

            GoTo(block.x, block.y, block.z)
            traveled = AddDistance(traveled, block)
            obtained = obtained + 1
            scanDistance = 1 -- set scan distance to 1 so if another block is close it will be found faster
        elseif scanDistance < 8 then
            scanDistance = scanDistance * 2
        elseif traveled.y == 0 then
            GoTo(9, 0, 0)
            traveled = AddDistance(traveled, {
                x = 9,
                y = 0,
                z = 0
            })
        else
            GoTo(0, -(traveled.y), 0)
            traveled.y = 0
        end
    end
    GoTo(-traveled.x, -traveled.y, -traveled.z)
    GoTo(0, -y_offset, 0)
end


-- Go to a realitive x y z
function GoTo(x, y, z)
    if debug then
        print("Going to", x, y, z)
        print("Facing", turtle.facing)
    end

    if x > 0 then
        if turtle.facing ~= 1 then -- Check if already facing +X
            if turtle.facing == 0 then
                turtle.turnRight()
            elseif turtle.facing == 2 then
                turtle.turnLeft()
            elseif turtle.facing == 3 then
                turtle.turnLeft()
                turtle.turnLeft()
            end
            turtle.facing = 1
        end
        Forward(x)
    elseif x < 0 then
        if turtle.facing ~= 3 then -- Check if already facing -X
            if turtle.facing == 0 then
                turtle.turnLeft()
            elseif turtle.facing == 1 then
                turtle.turnLeft()
                turtle.turnLeft()
            elseif turtle.facing == 2 then
                turtle.turnRight()
            end
            turtle.facing = 3
        end
        Forward(math.abs(x))
    end

    if DEBUG then
        print("Now facing", turtle.facing)
    end

    if z > 0 then
        if turtle.facing ~= 2 then
            if turtle.facing == 0 then
                turtle.turnLeft()
                turtle.turnLeft()
            elseif turtle.facing == 1 then
                turtle.turnRight()
            elseif turtle.facing == 3 then
                turtle.turnLeft()
            end
        end
        turtle.facing = 2
        Forward(z)
    elseif z < 0 then
        if turtle.facing ~= 0 then
            if turtle.facing == 1 then
                turtle.turnLeft()
            elseif turtle.facing == 2 then
                turtle.turnLeft()
                turtle.turnLeft()
            elseif turtle.facing == 3 then
                turtle.turnRight()
            end
        end
        turtle.facing = 0
        Forward(math.abs(z))
    end

    if DEBUG then
        print("Now facing", turtle.facing)
    end
    
    if y > 0 then
        for i = 1, y do
            while not turtle.up() do
                turtle.digUp()
            end
        end
    elseif y < 0 then
        for i = 1, -y do
            while not turtle.down() do
                turtle.digDown()
            end
        end
    end
end


function AddDistance(coords, otherCoords)
    coords.x = coords.x + otherCoords.x
    coords.y = coords.y + otherCoords.y
    coords.z = coords.z + otherCoords.z

    return coords
end


function Forward(n)
    for i = 1, n do
        while not turtle.forward() do
            turtle.dig()
        end
    end
end


function Find(target, distance)
    if distance == nil then distance = 8 end

    local blocks = Scan(distance)
    
    while blocks == nil do
        blocks = Scan(distance)
        sleep(0.75)
    end

    local dis = math.huge
    local closestBlock

    for i, block in pairs(blocks) do
        if GetDistance(block) < dis and string.find(block.name, target) then
            closestBlock = block
            dis = GetDistance(block)
        end
    end

    return closestBlock
end


function GetDistance(block)
    return (math.abs(block.x) + math.abs(block.y) + math.abs(block.z))
end


main(...)
