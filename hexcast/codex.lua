local codex = {} -- a table of angles for useful patterns

codex.hermes = 'deaqq' -- the execution pattern, great to have hardcoded
codex.consideration = 'qqqaw' -- lets you put non-pattern iotas in spells

codex.minds_ref = 'qaq'

local function make_pattern_iota(angles, isHexTweaks)
    pattern = {
        angles = angles,
        startDir = "EAST"
    }

    if isHexTweaks then
        patterns ["iota$serde"] = 'pattern' -- tell hex tweaks that this is a pattern iota
    end
end


return codex, make_pattern_iota