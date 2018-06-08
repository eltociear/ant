local ecs = ...

local hierarchy = require "hierarchy"

local eh = ecs.component "editable_hierarchy"{
    root = {
        type = "userdata", 
        default = function() 
            return hierarchy.new() 
        end,
        save = function(v, arg)
            assert(type(v) == "userdata")

            local function to_table(node, t)                
                local children = {}
                for _, cnode in ipairs(node) do
                    to_table(cnode, t)

                    table.insert(children,
                     {name = cnode.name, transform = cnode.transform})
                end

                if next(children) then
                    t.children = children
                end
            end

            local tree = {}
            to_table(v, tree)
            return tree
        end,
        load = function(v, arg)
            assert(type(v) == "table")
            local hie = hierarchy.new()
            local function to_hierarchy(hie, tree)
                for idx, v in ipairs(tree) do
                    local children = v.children
                    local child = hie[idx]
                    if next(children) then
                        to_hierarchy(child, children)
                    end
                    
                    child.name = v.name
                    child.transform = v.transform
                end
            end

            to_hierarchy(hie, v)
            return hie
        end
    }
}

