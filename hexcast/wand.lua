codex = require('codex') -- require the codex for iota translation (and hermes)

hermes = codex.translate_to_iota(codex.hermes) -- get the hermes pattern iota

wand = peripheral.find('wand') -- needed to hexcast with hextweaks

if not wand then
    print('No wand found! Please equip a wand to the turtle/pocket computer.') -- hex tweaks only supports wand on turtle and pocket computer
    return
end

-- from magic.lua
function cast(spell, delay)
    spell = codex.translate_to_iota(spell, true) -- translate the spell to an iota, specifying that it is for hex tweaks

    if delay == nil then delay = 0 end
    sleep(delay)
    
    wand.pushStack(spell) -- push the spell to the stack
    wand.runPattern(hermes) -- run the hermes pattern
end


function load_iota(file) -- loads an iota from a .iota file (just text)
    local f = io.open(file, 'r') -- open the file
    if not f then return nil end -- if the file doesn't exist, return nil

    local iota_string = f:read('*all') -- read the entire file
    f:close() -- close the file

    iota_table = textutils.unserialise(iota_string)
    iota = codex.translate_to_iota(iota_table, true)
    return iota
end

function cast_file(file, delay)
    local iota = load_iota(file)
    if iota then
        cast(iota, delay)
    end
end