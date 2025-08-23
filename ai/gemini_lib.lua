-- gemini.lua - Gemini API Library for ComputerCraft

local gemini = {}

-- Configuration
gemini.config = {
    apiKey = nil,
    apiEndpointBase = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent",
    -- Add other default configurations here if needed
}

-- Constants
local CONTENT_TYPE_JSON = "application/json"
local HTTP_SUCCESS = 200

-- Error Handling
local function error(msg)
    return nil, "[Gemini API Error] " .. msg
end

-- Logging function
local function log(level, message)
    print(string.format("[%s] [Gemini API] %s", level:upper(), message))
end

-- Internal function to load configuration from a file
function gemini.loadConfig(path)
    local file = fs.open(path, "r")
    if file then
        local content = file.readAll()
        file.close()
        local config, err = textutils.unserializeJSON(content)
        if config then
            for k, v in pairs(config) do
                gemini.config[k] = v
            end
            log("INFO", "Configuration loaded from " .. path)
        else
            log("WARN", "Failed to load configuration from " .. path .. ": " .. (err or "Unknown error"))
        end
    else
        log("WARN", "Configuration file not found at " .. path)
    end
end

-- Internal function for making the HTTP request to Gemini
local function makeRequest(prompt)
    if not gemini.config.apiKey then
        return error("API Key not set. Please set gemini.apiKey or load configuration.")
    end

    local apiEndpoint = gemini.config.apiEndpointBase .. "?key=" .. gemini.config.apiKey

    local headers = {
        ["Content-Type"] = CONTENT_TYPE_JSON,
    }

    local data = {
        contents = {
            {
                parts = {
                    {
                        text = prompt
                    }
                }
            }
        }
    }

    local encodedData = textutils.serializeJSON(data)

    if _DEBUG then -- Add a global _DEBUG flag for development
        log("DEBUG", "API Endpoint: " .. apiEndpoint)
        log("DEBUG", "Request Body: " .. encodedData)
        log("DEBUG", "Headers: " .. textutils.serializeJSON(headers))
    end

    local response = http.post(apiEndpoint, encodedData, headers)

    if not response then
        return error("Failed to make HTTP request. Check network connection.")
    end

    local body = response.readAll()
    response.close()

    if response.getResponseCode() ~= HTTP_SUCCESS then
        return error("API Error: HTTP " .. response.getResponseCode() .. "\n" .. body)
    end

    local json, err = textutils.unserializeJSON(body)
    if not json then
        return error("Error parsing JSON response: " .. (err or ""))
    end

    return json, nil
end

-- Function to get a response from Gemini
function gemini.generateContent(prompt)
    if not prompt or #prompt == 0 then
        return error("Prompt cannot be empty.")
    end

    local jsonResponse, err = makeRequest(prompt)

    if not jsonResponse then
        return nil, err
    end

    if not jsonResponse.candidates or #jsonResponse.candidates == 0 then
        return nil, error("No valid candidates found in the response")
    end

    local firstCandidate = jsonResponse.candidates[1]

    if not firstCandidate or not firstCandidate.content or not firstCandidate.content.parts or #firstCandidate.content.parts == 0 then
        return nil, error("No content parts found in response")
    end

    local responseText = ""
    for _, part in ipairs(firstCandidate.content.parts) do
        if part.text then
            responseText = responseText .. part.text
        end
    end

    return responseText, nil
end

gemini.chat = {
    chat_str = "",
    init = function(self, system_prompt)
        self.chat_str = system_prompt .. '\n\n'
    end,
    send_message = function(self, user, message)
        self.chat_str = self.chat_str .. user .. ': ' .. message .. '\n\nYou: '
        return gemini.generateContent(self.chat_str)
    end
}

-- Function to set the API key (can still be used, overrides config file)
function gemini.setAPIKey(key)
    gemini.config.apiKey = key
    log("INFO", "API Key set programmatically.")
end

return gemini