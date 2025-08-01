-- script made by ChloeTax

local decoder = require("cc.audio.dfpwm").make_decoder()
local speaker = peripheral.find("speaker")
local baseurl = "https://hexxytest.hexxy.media/api/ccaudio?url="
local playCount = tonumber(arg[2]) -- you could use -1 for inf looping
if not playCount then playCount = 1 end
local volume  = tonumber(arg[3])
if volume == nil then volume = 1
elseif volume > 3 then volume = 3
elseif volume < 0.1 then volume = 0.1 end
 
local url = arg[1]
if not url then url = io.read() end

local function get_random_url()
    -- Open the file for reading. Replace 'random.txt' with your file's name.
    local file = io.open("random.txt", "r")

    -- Check if the file was successfully opened.
    if not file then
        error("Could not open the file 'random.txt'")
    end

    local lines = {}
    local lineCount = 0

    -- Read all lines from the file into a table.
    for line in file:lines() do
        lineCount = lineCount + 1
        lines[lineCount] = line
    end

    -- Close the file.
    file:close()

    -- Make sure there's at least one line to choose from.
    if lineCount == 0 then
        print("The file is empty.")
    else
        -- Generate a random number between 1 and the total number of lines.
        local randomIndex = math.random(1, lineCount)

        -- Get the line at the random index.
        local randomLine = lines[randomIndex]

        -- Print the random line.
        print(randomLine)
        return randomLine
    end
end

local random = false
if url == 'random' then random = true end


while playCount ~= 0 do
    if random then url = get_random_url() end
    local data = http.get(baseurl .. url)
    playCount = playCount - 1
    data.seek("set", 0)
    while true do
        local chunk = data.read(8 * 1024)
        if not chunk then break end
        
        local buffer = decoder(chunk)
 
        while not speaker.playAudio(buffer, volume) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end
