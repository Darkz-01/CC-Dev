-- script made by ChloeTax

local decoder = require("cc.audio.dfpwm").make_decoder()
local speaker = peripheral.find("speaker")
local baseurl = "https://hexxytest.hexxy.media/api/ccaudio?url="
local playCount = tonumber(arg[2]) -- you could use -1 for inf looping
if not playCount then playCount = 1 end
 
local url = arg[1]
if not url then url = io.read() end
 
local data = http.get(baseurl .. url)
 
while playCount ~= 0 do
    playCount = playCount - 1
    data.seek("set", 0)
    while true do
        local chunk = data.read(8 * 1024)
        if not chunk then break end
        
        local buffer = decoder(chunk)
 
        while not speaker.playAudio(buffer) do
            os.pullEvent("speaker_audio_empty")
        end
    end
end
