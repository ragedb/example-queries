-- Interactive Short 1
local ldbc_snb_is01 = function(person_id)

    local properties = NodeGetProperties("Person", person_id)
    local city = NodeGetNeighbors("Person", person_id, Direction.OUT, "IS_LOCATED_IN")[1]
    local result = {
        ["person.firstName"] = properties["firstName"],
        ["person.lastName"] = properties["lastName"],
        ["person.birthday"] = properties["birthday"],
        ["person.locationIP"] = properties["locationIP"],
        ["person.browserUsed"] = properties["browserUsed"],
        ["city.id"] = city:getProperty("id"),
        ["person.gender"] = properties["gender"],
        ["person.creationDate"] = date(properties["creationDate"]):fmt("${iso}Z")
    }

    return result
end

ldbc_snb_is01("933")

-- Interactive Short 2

local ldbc_snb_is02 = function(person_id)

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
            result["message.imageFile"] =  properties["imageFile"]
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

ldbc_snb_is02("21990232564424")

-- Interactive Short 3
local ldbc_snb_is03 = function(person_id)

local knows = NodeGetLinks("Person", person_id, "KNOWS")
local friendships = {}
for i, know in pairs(knows) do
  creation = RelationshipGetProperty(know:getRelationshipId(),"creationDate")
  friend = NodeGetProperties(know:getNodeId())
  friendship = {
    ["friend.id"] = friend["id"],
    ["friend.firstName"] = friend["firstName"],
    ["friend.lastName"] = friend["lastName"],
    ["knows.creationDate"] = creation
  }
  table.insert(friendships, friendship)
end

table.sort(friendships, function(a, b)
  if a["knows.creationDate"] > b["knows.creationDate"] then
      return true
  end
  if (a["knows.creationDate"] == b["knows.creationDate"]) then
     return (a["friend.id"] < b["friend.id"] )
  end
end)

for i = 1, #friendships do
  friendships[i]["knows.creationDate"] = date(friendships[i]["knows.creationDate"]):fmt("${iso}Z")
end


    return friendships
end

ldbc_snb_is03("933")

-- Interactive Short 4
local ldbc_snb_is04 = function(message_id)

    local properties = NodeGetProperties("Message", message_id)
    local result = {
        ["message.creationDate"] = date(properties["creationDate"]):fmt("${iso}Z")
    }

    if (properties["content"] == '') then
        result["message.imageFile"] =  properties["imageFile"]
    else
        result["message.content"] = properties["content"]
    end

    return result
end

ldbc_snb_is04("3")

-- Interactive Short 5
local ldbc_snb_is05 = function(message_id)

    local person = NodeGetNeighbors("Message", message_id, Direction.OUT, "HAS_CREATOR")[1]
    local result = {
        ["person.id"] = person:getProperty("id"),
        ["person.firstName"] = person:getProperty("firstName"),
        ["person.lastName"] = person:getProperty("lastName")
    }

    return result
end

ldbc_snb_is05("3")

-- Interactive Short 6
local ldbc_snb_is06 = function(message_id)

    local node_id = NodeGetId("Message", message_id)
    local links = NodeGetLinks(node_id, Direction.IN, "CONTAINER_OF")
    while (#links == 0) do
        links = NodeGetLinks(node_id, Direction.OUT, "REPLY_OF")
        node_id = links[1]:getNodeId()
        links = NodeGetLinks(node_id , Direction.IN, "CONTAINER_OF")
    end
    node_id = links[1]:getNodeId()
    local forum = NodeGet(node_id)
    local moderator = NodeGetNeighbors(node_id, Direction.OUT, "HAS_MODERATOR")[1]
    local properties = moderator:getProperties()
    local result = {
        ["forum.id"] = forum:getProperty("id"),
        ["forum.title"] = forum:getProperty("title"),
        ["moderator.id"] = properties["id"],
        ["moderator.firstName"] = properties["firstName"],
        ["moderator.lastName"] = properties["lastName"]
        }

    return result
end

ldbc_snb_is06("3")

-- Interactive Short 7

local ldbc_snb_is07 = function(message_id)

    local message_node_id = NodeGetId("Message", message_id)
    local author = NodeGetNeighbors(message_node_id, Direction.OUT, "HAS_CREATOR")[1]
    local knows = NodeGetLinks(author:getId(), "KNOWS")
    local knows_ids = {}
    for i, know in pairs (knows) do
        table.insert(knows_ids, know:getNodeId())
    end

    local comments = {}
    local replies = NodeGetNeighbors(message_node_id, Direction.IN, "REPLY_OF")
    for i, reply in pairs (replies) do
        local replyAuthor = NodeGetNeighbors(reply:getId(), Direction.OUT, "HAS_CREATOR")[1]
        local properties = replyAuthor:getProperties()
        local comment = {
            ["replyAuthor.id"] = properties["id"],
            ["replyAuthor.firstName"] = properties["firstName"],
            ["replyAuthor.lastName"] = properties["lastName"],
            ["knows"] = not knows_ids[replyAuthor:getId()] == nil,
            ["comment.id"] = reply:getProperty("id"),
            ["comment.content"] = reply:getProperty("content"),
            ["comment.creationDate"] = reply:getProperties()["creationDate"]
        }
    table.insert(comments, comment)
    end

    table.sort(comments, function(a, b)
        if a["comment.creationDate"] > b["comment.creationDate"] then
            return true
        end
        if (a["comment.creationDate"] == b["comment.creationDate"]) then
            return (a["replyAuthor.id"] < b["replyAuthor.id"] )
        end
    end)

    for i = 1, #comments do
        comments[i]["comment.creationDate"] = date(comments[i]["comment.creationDate"]):fmt("${iso}Z")
    end

    return comments
end

ldbc_snb_is07("1236950581248")