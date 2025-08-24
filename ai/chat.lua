local chatBox = peripheral.find("chatBox")

NAME = 'Robit'
NAME_CONTAINER = '{}' -- use curly brackets to easily distinguish form player '<>' and console '[]' messages

local apiKey = ... -- load the API key from the command line
if not apiKey then
    error("API key not provided. Please provide the API key as the first argument.")
end

-- clear the screen to hide the API key
term.clear()
term.setCursorPos(1, 1)

local gemini = require("gemini_lib")
gemini.setAPIKey(apiKey)

gemini.chat:init("You are a chatbot responding to messages sent in a minecraft chat, you can only see and respond to message that contain your name, when responding try not to use long messages (3 sentences+) as its hard to read in the minecraft chat, and only respond in plaintext", NAME)

while true do
    local event, username, message, user_uuid, isHidden = os.pullEvent('chat')
    if string.find(string.lower(message), string.lower(NAME)) then
        local response, err = gemini.chat:send_message(username, message)
        if response then
            chatBox.sendMessage(response:match("^%s*(.*%S?)%s*$") or "", NAME, NAME_CONTAINER)
        else
            print(err)
        end
    end
end