SEND_PORT = 57
RECV_PORT = 58

-- NOTES
-- subCat is a string with the category name and sub-category name seperated by ':'
-- wordDesc is a string with the word and description seperated by ':'

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


modem.transmit(SEND_PORT, RECV_PORT, {action='init_addTo'})
local _, _, _, _, initData, _ = os.pullEvent('modem_message')

-- initData = {[categories], [subCats]}

local actions = {'Add Word', 'Get Words', 'Edit Word', 'Remove Word', 'Add Sub-Category', 'Remove Sub-Category', 'Rename Sub-Category'}

while true do
    local action = user_choose(actions)
    print() -- spacing

    local category, sub_category

    if action ~= 'Add Sub-Category' then
        print('Sub-Category to ' .. action .. ':')
        local subCat = user_choose(initData.subCats) -- get the sub-category to do action on
        print()
    
        local split = string.find(subCat, ':')
    
        category = string.sub(subCat, 1, split-1)
        sub_category = string.sub(subCat, split+1, #subCat)
    
        if sub_category == '1' then sub_category = 1 end -- override for default category (no sub category)
    else
        print('Category to ' .. action .. ':')
        category = user_choose(initData.categories) -- get the category to add the new sub-category to
        print()
    end

    if action == 'Add Word' then
        print('Word to add:')
        local word = io.read()
        print()

        print('Description of word')
        local desc = io.read()
        print()

        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'add',
            word = word,
            desc = desc,
            category = category,
            sub_category = sub_category
        })
    elseif action == 'Remove Word' then
        modem.transmit(SEND_PORT, RECV_PORT, {action='get_words', category=category, sub_category=sub_category})
        local _, _, _, _, wordDescs, _ = os.pullEvent('modem_message')

        local wordDesc = user_choose(wordDescs)
        local split = string.find(wordDesc, ':')
        local word = string.sub(wordDesc, 1, split-1)
        
        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'remove',
            word = word,
            category = category,
            sub_category = sub_category
        })

    elseif action == 'Get Words' then
        modem.transmit(SEND_PORT, RECV_PORT, {action='get_words', category=category, sub_category=sub_category})
        local _, _, _, _, wordDescs, _ = os.pullEvent('modem_message')
        
        print()
        for i, wordDesc in ipairs(wordDescs) do
            local split = string.find(wordDesc, ':')
            local word = string.sub(wordDesc, 1, split-1)
            local desc = string.sub(wordDesc, split+1, #wordDesc)
            
            print(word .. ' - ' .. desc)
        end
    elseif action == 'Edit Word' then
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
    elseif action == 'Add Sub-Category' then
        print('Name of new sub-category:')
        local sub_category = io.read()
        
        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'add_sub',
            category = category,
            sub_category = sub_category
        })
    elseif action == 'Remove Sub-Category' then
        print('Sub-Category to remove:')
        local sub_category = user_choose(initData.subCats)
        local split = string.find(sub_category, ':')
        sub_category = string.sub(sub_category, split+1, #sub_category)
        
        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'remove_sub',
            category = category,
            sub_category = sub_category
        })
    elseif action == 'Rename Sub-Category' then
        print('New name for sub-category:')
        local new_name = io.read()
        
        modem.transmit(SEND_PORT, RECV_PORT, {
            action = 'rename_sub',
            category = category,
            sub_category = sub_category,
            new_name = new_name
        })
    end

    if string.find(action, 'Sub-Category') then -- refresh initData if sub-category action
        modem.transmit(SEND_PORT, RECV_PORT, {action='init_addTo'})
        local _, _, _, _, initData_new, _ = os.pullEvent('modem_message')
        initData = initData_new
    end
end