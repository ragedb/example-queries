
-- Interactive Short 2 - NodeGetNeighbors
ldbc_snb_is02 = function(person_id)

    local person = NodeGet("Person", person_id)
    local messages = NodeGetNeighbors(person:getId(), Direction.IN, "HAS_CREATOR")
    table.sort(messages, function(a, b)
        if a:getProperty("creationDate") > b:getProperty("creationDate") then
            return true
        elseif a:getProperty("creationDate") == b:getProperty("creationDate") then
            return a:getProperty("id") > b:getProperty("id")
        end
        end)
    local smaller = table.move(messages, 1, 10, 1, {})

    results = {}
    for i, message in pairs(smaller) do
        local properties = message:getProperties()

        local result = {
            ["message.id"] = properties["id"],
            ["message.creationDate"] = date(properties["creationDate"]):fmt("${iso}Z")
        }

        if (properties["content"] == '') then
            result["message.imageFile"] = properties["imageFile"]
        else
            result["message.content"] = properties["content"]
        end

        if (properties["type"] == "post") then
            result["post.id"] = properties["id"]
            result["originalPoster.id"] = person:getProperty("id")
            result["originalPoster.firstName"] = person:getProperty("firstName")
            result["originalPoster.lastName"] = person:getProperty("lastName")
        else
            local node_id = message:getId()
            local hasReply = NodeGetLinks(node_id, Direction.OUT, "REPLY_OF")
            while (#hasReply > 0) do
                node_id = hasReply[1]:getNodeId()
                hasReply = NodeGetLinks(node_id, Direction.OUT, "REPLY_OF")
            end
            local poster = NodeGetNeighbors(node_id, Direction.OUT, "HAS_CREATOR")[1]
            local post_id = NodeGetProperty(node_id, "id")
            result["post.id"] = post_id
            result["originalPoster.id"] = poster:getProperty("id")
            result["originalPoster.firstName"] = poster:getProperty("firstName")
            result["originalPoster.lastName"] = poster:getProperty("lastName")
        end
        table.insert(results, result)
    end

    return results
end

-- Interactive Short 2 - NodesGetProperties
ldbc_snb_is02 = function(person_id)
    local person = NodeGet("Person", person_id)
    local person_properties = person:getProperties()
    local message_ids = NodeGetNeighborIds(person:getId(), Direction.IN, "HAS_CREATOR")
    local messages = NodesGetProperties(message_ids)
    for i, properties in pairs(messages) do
        properties["node_id"] = message_ids[i]
    end

        table.sort(messages, function(a, b)
        local adate = a["creationDate"]
        local bdate = b["creationDate"]
        if adate > bdate then
            return true
        elseif adate == bdate then
            return a["id"] > b["id"]
        end
        end)
    local smaller = table.move(messages, 1, 10, 1, {})

   results = {}
    for i, properties in pairs(smaller) do

        local result = {
            ["message.id"] = properties["id"],
            ["message.creationDate"] = date(properties["creationDate"]):fmt("${iso}Z")
        }

        if (properties["content"] == '') then
            result["message.imageFile"] = properties["imageFile"]
        else
            result["message.content"] = properties["content"]
        end

        if (properties["type"] == "post") then
            result["post.id"] = properties["id"]
            result["originalPoster.id"] = person_properties["id"]
            result["originalPoster.firstName"] = person_properties["firstName"]
            result["originalPoster.lastName"] = person_properties["lastName"]
        else
            -- removing the chase gives me an extra 100 req/s
            local node_id = properties["node_id"]
            local hasReply = NodeGetLinks(node_id, Direction.OUT, "REPLY_OF")
            while (#hasReply > 0) do
                node_id = hasReply[1]:getNodeId()
                hasReply = NodeGetLinks(node_id, Direction.OUT, "REPLY_OF")
            end
            local poster = NodeGetNeighbors(node_id, Direction.OUT, "HAS_CREATOR")[1]
            local poster_properties = poster:getProperties()
            local post_id = NodeGetProperty(node_id, "id")
            result["post.id"] = post_id
            result["originalPoster.id"] = poster_properties["id"]
            result["originalPoster.firstName"] = poster_properties["firstName"]
            result["originalPoster.lastName"] = poster_properties["lastName"]
        end
        table.insert(results, result)
    end

    return results
end