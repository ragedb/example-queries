--ALL
-- Interactive Query 1
ldbc_snb_iq01 = function(person_id, firstName)

    local node_id = NodeGetId("Person", person_id)
    local people = NodeGetLinks(node_id, "KNOWS")
    local seen1 = Roar.new()

    seen1:addNodeIds(people)
    local named1 = FilterNodes(seen1:getIds(), "Person", "firstName", Operation.EQ, firstName)
    local named2 = {}
    local named3 = {}

    if(#named1 < 20) then 
      local seen2 = Roar.new()

      local people2 = LinksGetLinks(people, "KNOWS")
      for i,links in pairs(people2) do 
        seen2:addNodeIds(links)
      end  
      seen2:inplace_difference(seen1)
      seen2:remove(node_id)

      named2 = FilterNodes(seen2:getIds(), "Person", "firstName", Operation.EQ, firstName)

      if((#named1 + #named2) < 20) then 

        local seen3 = Roar.new()
        local people3 = LinksGetLinks(seen2:getNodeHalfLinks(), "KNOWS") 
        for i,links2 in pairs(people3) do 
            seen3:addNodeIds(links2) 
        end
        seen3:inplace_difference(seen2)
        seen3:inplace_difference(seen1)
        seen3:remove(node_id)

        named3 = FilterNodes(seen3:getIds(), "Person", "firstName", Operation.EQ, firstName)
      end
    end

    local known = {}
    local found = {named1, named2, named3}

    for i = 1, #found do
      if (#found[i] > 0) then
        for j, person in pairs(found[i]) do
          local properties = person:getProperties()
          otherPerson = {
            ["otherPerson.id"] = properties["id"],
            ["otherPerson.lastName"] = properties["lastName"],
            ["otherPerson.birthday"] = properties["birthday"],
            ["otherPerson.creationDate"] = properties["creationDate"],
            ["otherPerson.gender"] = properties["gender"],
            ["otherPerson.browserUsed"] = properties["browserUsed"],
            ["otherPerson.locationIP"] = properties["locationIP"],
            ["otherPerson.email"] = properties["email"],
            ["otherPerson.speaks"] = properties["speaks"],
            ["distanceFromPerson"] = i
          }
          table.insert(known, otherPerson)
        end
      end
    end

    function sort_on_values(t,...)
      local a = {...}
      table.sort(t, function (u,v)
        for i = 1, #a do
          if u[a[i]] > v[a[i]] then return false end
          if u[a[i]] < v[a[i]] then return true end
        end
      end)
    end

    sort_on_values(known,"distanceFromPerson","otherPerson.lastName", "otherPerson.id")
    local smaller = table.move(known, 1, 20, 1, {})

    local results = {}
    for j, person in pairs(smaller) do
        local studied_list = {}
        local worked_list = {} 
        local studied = NodeGetRelationships("Person", tostring(person["otherPerson.id"]), Direction.OUT, "STUDY_AT" )
        local worked = NodeGetRelationships("Person", tostring(person["otherPerson.id"]), Direction.OUT, "WORK_AT" )
     
        for s = 1, #studied do
            table.insert(studied_list, NodeGetProperty(studied[s]:getEndingNodeId(), "name"))
            table.insert(studied_list, RelationshipGetProperty(studied[s]:getId(), "classYear"))
        end
        
       for s = 1, #worked do
          table.insert(worked_list, NodeGetProperty(worked[s]:getEndingNodeId(), "name"))
          table.insert(worked_list, RelationshipGetProperty(worked[s]:getId(), "workFrom"))
       end
      
      person["universities"] = table.concat(studied_list, ", ")
      person["companies"] = table.concat(worked_list, ", ")
      person["otherPerson.creationDate"] = DateToISO(person["otherPerson.creationDate"])
      table.insert(results, person)
    end

    return results
  
end

-- Interactive Query 2
ldbc_snb_iq02_orig = function(person_id, maxDate)

    local node_id = NodeGetId("Person", person_id)
    local friends = NodeGetNeighbors(node_id, "KNOWS")
    local results = {}
      for i, friend in pairs(friends) do
          local properties = friend:getProperties()
          local messages = NodeGetNeighbors(friend:getId(), Direction.IN, "HAS_CREATOR")
          for j, message in pairs(messages) do
            local msg_properties = message:getProperties()
            if (date(msg_properties["creationDate"]) < maxDate) then
                local result = {
                    ["friend.id"] = properties["id"],
                    ["friend.firstName"] = properties["firstName"],
                    ["friend.lastName"] = properties["lastName"]
                }
                result["message.id"] = msg_properties["id"]
                if (msg_properties["content"] == '') then
                    result["message.imageFile"] = msg_properties["imageFile"]
                else
                    result["message.content"] = msg_properties["content"]
                end
                result["message.creationDate"] = msg_properties["creationDate"]
                table.insert(results, result)
            end
          end
      end

      table.sort(results, function(a, b)
          local adate = a["message.creationDate"]
          local bdate = b["message.creationDate"]
          if adate > bdate then
              return true
          end
          if (adate == bdate) then
              return (a["message.id"] < b["message.id"] )
          end
      end)

    local smaller = table.move(results, 1, 20, 1, {})

      for i = 1, #smaller do
          smaller[i]["message.creationDate"] = DateToISO(smaller[i]["message.creationDate"])
      end

      return smaller
end

--ALL
ldbc_snb_iq02 = function(person_id, maxDate)
    local node_id = NodeGetId("Person", person_id)
    local friends = NodeGetLinks(node_id, "KNOWS")
    local friend_properties = LinksGetNodeProperties(friends)
    local messages = LinksGetNeighborIds(friends, Direction.IN, "HAS_CREATOR")

    local results = {}
    local friend_properties_map = {}
    for id, properties in pairs(friend_properties) do
      friend_properties_map[id] = properties
    end

    for link, user_message_ids in pairs(messages) do
         local properties = friend_properties_map[link:getNodeId()]
         local messages_props = FilterNodeProperties(user_message_ids, "Message", "creationDate", Operation.LT, maxDate, 0, 10000000)
         for j, msg_properties in pairs(messages_props) do
               local result = {
                  ["friend.id"] = properties["id"],
                  ["friend.firstName"] = properties["firstName"],
                  ["friend.lastName"] = properties["lastName"]
              }
              result["message.id"] = msg_properties["id"]
              if (msg_properties["content"] == '') then
                  result["message.imageFile"] = msg_properties["imageFile"]
              else
                  result["message.content"] = msg_properties["content"]
              end
              result["message.creationDate"] = msg_properties["creationDate"]
              table.insert(results, result)
        end
    end
      table.sort(results, function(a, b)
          local adate = a["message.creationDate"]
          local bdate = b["message.creationDate"]
          if adate > bdate then
              return true
          end
          if (adate == bdate) then
              return (a["message.id"] < b["message.id"] )
          end
      end)

        local smaller = table.move(results, 1, 20, 1, {})

          for i = 1, #smaller do
              smaller[i]["message.creationDate"] = DateToISO(smaller[i]["message.creationDate"])
          end

    return smaller
end



-- Interactive Query 3

-- Interactive Query 4

-- Interactive Query 5

-- Interactive Query 6

-- Interactive Query 7

-- Interactive Query 8

-- Interactive Query 9

-- Interactive Query 10

-- Interactive Query 11

-- Interactive Query 12

-- Interactive Query 13

local ldbc_snb_iq13 = function(person1_id, person2_id)
    if (person1_id == person2_id) then return 0 end
    local length = 1
    local node1_id = NodeGetId("Person", person1_id)
    local node2_id = NodeGetId("Person", person2_id)
    local left_people = {}
    local right_people = {}

    local seen_left = Roar.new()
    local seen_right = Roar.new()
    local next_left = Roar.new()
    local next_right = Roar.new()

    seen_left:add(node1_id)
    seen_right:add(node2_id)
    next_left:add(node1_id)
    next_right:add(node2_id)

    while ((next_left:cardinality() + next_right:cardinality()) > 0) do
        if(next_left:cardinality() > 0) then
            left_people = NodeIdsGetNeighborIds(next_left:getIds(), "KNOWS")
            next_left:clear()
            next_left:addIds(left_people)
            next_left:inplace_difference(seen_left)
            if (next_left:intersection(next_right):cardinality() > 0) then return length end
            length = length + 1
            seen_left:inplace_union(next_left)
        end
        if(next_right:cardinality() > 0) then
            right_people = NodeIdsGetNeighborIds(next_right:getIds(), "KNOWS")
            next_right:clear()
            next_right:addIds(right_people)
            next_right:inplace_difference(seen_right)
            if (next_right:intersection(next_left):cardinality() > 0) then return length end
            length = length + 1
            seen_right:inplace_union(next_right)
        end
    end

    return -1
end

-- Interactive Query 14