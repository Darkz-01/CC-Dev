SEND_PORT = 57
RECV_PORT = 58

modem = peripheral.find('modem')

modem.closeAll()
modem.open(RECV_PORT)

function user_choose(options)
    for i, option in ipairs(options) do
        print('[' .. tostring(i) .. '] - ' .. option)
    end
    
    choice = -1
    
    repeat
        tmp = io.read()
        choice = tonumber(tmp)
        if choice == nil then choice = -1 end
    until options[choice] ~= nil
    
    return options[choice]
end


modem.transmit(SEND_PORT, RECV_PORT, {action='get_subcat'})
local _, _, _, _, subCats, _ = os.pullEvent('modem_message')

actions = {'add', 'get', 'edit', 'remove'}

while true do
    local action = user_choose(actions)
    local subCat = user_choose(subCats)
    
    local split = string.find(subCat, '-')
    
    local category = string.sub(subCat, 1, split-1)
    local sub_category = string.sub(subCat, split+1, #subCat)
    
    print(action .. ' ' .. subCat)
    
    if action == 'add' then
        print('Word to add:')
        local word = io.read()
        
        print('Description of word')
        local desc = io.read()
        
        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'add',
            word = word,
            desc = desc,
            category = category,
            sub_category = sub_category
        })
    elseif action == 'remove' then
        modem.transmit(SEND_PORT, RECV_PORT, {action='get_words', category=category, sub_category=sub_category})
        local _, _, _, _, wordChoices, _ = os.pullEvent('modem_message')

        local word = user_choose(wordChoices)

        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'remove',
            word = word,
            category = category,
            sub_category = sub_category
        })

    elseif action == 'get' then
        modem.transmit(SEND_PORT, RECV_PORT, {action='get_words', category=category, sub_category=sub_category})
        local _, _, _, _, wordDescs, _ = os.pullEvent('modem_message')
        
        for i, wordDesc in ipairs(wordDescs) do
            local split = string.find(wordDesc, ':')
            local word = string.sub(wordDesc, 1, split-1)
            local desc = string.sub(wordDesc, split+1, #wordDesc)
            
            print(word .. ' - ' .. desc)
        end
    elseif action == 'edit' then
        modem.transmit(SEND_PORT, RECV_PORT, {action='get_words', category=category, sub_category=sub_category})
        local _, _, _, _, wordDescs, _ = os.pullEvent('modem_message')

        local wordChoices = {}
        local mini_tbl = {}
        for i, wordDesc in ipairs(wordDescs) do
            local split = string.find(wordDesc, ':')
            local word = string.sub(wordDesc, 1, split-1)
            local desc = string.sub(wordDesc, split+1, #wordDesc)
            
            table.insert(wordChoices, word)
            mini_tbl[word] = desc
        end
        
        local chosen_word = user_choose(wordChoices)
        local chosen_desc = mini_tbl[chosen_word]

        print('Current word: ' .. chosen_word)
        print('New word (leave blank to keep current):')
        local new_word = io.read()
        local rename = false
        if new_word ~= '' then
            rename = true
        else
            new_word = chosen_word
        end
        
        print('Current description: ' .. chosen_desc)
        print('New description (leave blank to keep current):')
        local new_desc = io.read()
        if new_desc == '' then
            new_desc = chosen_desc
        end

        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'edit',
            word = chosen_word,
            new_word = new_word,
            new_desc = new_desc,
            rename = rename,
            category = category,
            sub_category = sub_category
        })
    end
end