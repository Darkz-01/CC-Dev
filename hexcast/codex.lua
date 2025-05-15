local codex = {} -- a table of angles for useful patterns

codex.hermes = 'PAT deaqq' -- the execution pattern, great to have hardcoded
codex.consideration = 'PAT qqqaw' -- lets you put non-pattern iotas in spells

codex.minds_ref = 'PAT qaq'

-- exists for translate_to_iota
local function make_pattern_iota(angles, isHexTweaks)
    if string.find(angles, "PAT") then
        angles = string.sub(angles, 5) -- cut off the PAT indicator
    end

    pattern = {
        angles = angles,
        startDir = "EAST" -- start dir doesn't actually matter for the function of a pattern, it is purely visual
    }

    if isHexTweaks then
        patterns ["iota$serde"] = 'pattern' -- tell hex tweaks that this is a pattern iota
    end
end

-- uses iota$serde for hex tweaks to specify iota type
local function translate_to_iota(to_translate, isHexTweaks)
    if type(to_translate) == "table" then -- vectors, patterns, entities, lists
        if to_translate.x and to_translate.y and to_translate.z then -- vectors
            iota = {
                x = to_translate.x,
                y = to_translate.y,
                z = to_translate.z
            }

            if isHexTweaks then
                iota["iota$serde"] = 'vec3'
            end
            
            return iota
        
        elseif to_translate.angles then -- patterns
            iota = make_pattern_iota(to_translate.angles, isHexTweaks)
            
            if to_translate.startDir then -- mantain any specified startDir
                iota.startDir = to_translate.startDir
            end

            return iota
        
        elseif to_translate.uuid and to_translate.name then -- entities
            return nil -- Todo: entity iotas, generally these are only stored in the already translated form
        
        else -- lists
            iota = {}
            for k, v in pairs(to_translate) do
                table.insert(iota, k, translate_to_iota(v, isHexTweaks)) -- might have to shift this to be 0 indexed
            end

            if isHexTweaks then
                iota["iota$serde"] = 'list'
            end
            
            return iota 
        end
    elseif type(to_translate) == "string" then -- strings and patterns if has PAT indicator
        if string.find(to_translate, "PAT") then
            return make_pattern_iota(to_translate, isHexTweaks)
        else
            return to_translate
        end
    else
        return to_translate
    end
end


codex.translate_to_iota = translate_to_iota

return codex