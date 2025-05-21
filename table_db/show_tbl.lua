RECV_PORT = 57

HEADER = {
    'NOTE: entries in this table may randomly shuffle around',
    'Also the descriptions kinda suck'
}

local file = ...
file = file .. '.tbl'

monitor = peripheral.find('monitor')
modem = peripheral.find('modem')

monitor.clear()
modem.closeAll()

modem.open(RECV_PORT)
local width, height = monitor.getSize()

io.input(file)
local text = io.read('*all')
local tbl = textutils.unserialize(text)

function get_lines(tbl_db)
    lines = {}
    for i, header in ipairs(HEADER) do
        table.insert(lines, header)
    end
    
    for section, contents in pairs(tbl) do
        for sub_section, sub_tbl in pairs(contents) do
            if sub_section == 1 then
                table.insert(lines, '')
                table.insert(lines, '--- ' .. section .. ' ---')
                table.insert(lines, '')
            else
                table.insert(lines, '')
                table.insert(lines, '--- ' .. section .. ' - ' .. sub_section .. ' ---')
                table.insert(lines, '')
            end
            
            for word, desc in pairs(sub_tbl) do
                table.insert(lines, word .. ' - ' .. desc)
            end
        end
    end
    
    return lines
end

lines = get_lines(tbl)

for i, line in pairs(lines) do
    monitor.setCursorPos(1, i)
    monitor.write(line)
end

local pos = 0
while true do
    local eventData = {os.pullEvent()}
    
    if eventData[1] == 'monitor_touch' then
        local event, side, x, y = unpack(eventData)
        
        if y - 5 < 1 then -- top: scroll up
            pos = pos - 1
            monitor.scroll(-1)
            if lines[pos] then
                monitor.setCursorPos(1, 1)
                monitor.write(lines[pos+1])
            end
        elseif y + 5 > height then
            pos = pos + 1
            monitor.scroll(1)
            if lines[pos + height] then
                monitor.setCursorPos(1, height)
                monitor.write(lines[pos+height])
            end
        end
    
    elseif eventData[1] == 'modem_message' then
        local event, side, channel, replyChannel, message, distance = unpack(eventData)
        
        if message.action == 'get_subcat' then
            subCats = {}
        
            for category, contents in pairs(tbl) do
                for sub_category, _ in pairs(contents) do
                    table.insert(subCats, category .. '-' .. sub_category)
                end
            end            
        
            modem.transmit(replyChannel, RECV_PORT, subCats)
        elseif message.action == 'get_words' then
            words = {}
            for word, desc in pairs(tbl[message.category][message.sub_category]) do
                table.insert(words, word .. ':' .. desc)
            end
            
            modem.transmit(replyChannel, RECV_PORT, words)
            
        else
            if message.action == 'add' then
                tbl[message.category][message.sub_category][message.word] = message.desc
            
            elseif message.action == 'remove' then
                tbl[message.category][message.sub_category][message.word] = nil

            elseif message.action == 'edit' then
                if message.rename then
                    tbl[message.category][message.sub_category][message.word] = nil
                end
                tbl[message.category][message.sub_category][message.new_word] = message.new_desc
            
            else
                print('Unknown action: ' .. message.action)
            end
            
            local text = textutils.serialize(tbl)
            local fileHandle = io.output(file)
            fileHandle:write(text)
            fileHandle:close()
            
            lines = get_lines(tbl)

            monitor.clear()
            for i, line in pairs(lines) do
                monitor.setCursorPos(1, i - pos) -- offset re-render by pos
                monitor.write(line)
            end
        end
    end
end
