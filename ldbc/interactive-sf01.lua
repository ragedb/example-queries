-- Interactive Query 1
local ldbc_snb_iq01 = function(person_id, firstName)

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
      person["otherPerson.creationDate"] = date(person["otherPerson.creationDate"]):fmt("${iso}Z")
      table.insert(results, person)
    end

    return results
  
end

ldbc_snb_iq01("1129", "Chen")

-- Interactive Query 2

local ldbc_snb_iq02 = function(person_id, maxDate)

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
          if a["message.creationDate"] > b["message.creationDate"] then
              return true
          end
          if (a["message.creationDate"] == b["message.creationDate"]) then
              return (a["message.id"] < b["message.id"] )
          end
      end)

    local smaller = table.move(results, 1, 20, 1, {})

      for i = 1, #smaller do
          smaller[i]["message.creationDate"] = date(smaller[i]["message.creationDate"]):fmt("${iso}Z")
      end

      return smaller
end

ldbc_snb_iq02("1129", date("2022-05-20T18:55:55.595+0000Z"))

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

-- Interactive Query 14