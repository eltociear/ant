local ecs = ...
local world = ecs.world

local math3d = require "math3d"

local imaterial = world:interface "ant.asset|imaterial"

local dm = ecs.action "decal_mount"
function dm.init(prefab, idx, value)
    local eid = prefab[idx]
    local e = world[eid]
    local rc = e._rendercache
    rc.decaled_eid = value
    local de = world[value]
    rc.vb = de.vb
    rc.ib = de.ib

    -- update decal relate propertey
    imaterial.set_property(eid, "u_decal_viewproj", rc.viewprojmat)
end

local dt = ecs.transform "decal_transform"
local function update_decal(e)
    local _rc = e._rendercache
    local decal = e.decal
    local hw, hh = decal.w * 0.5, decal.h * 0.5
    _rc.viewmat = math3d.ref(math3d.inverse(_rc.srt))
    local frustum = {
        l = -hw, r = hw,
        b = -hh, t = hh,
        n = 0, f = 1,
        ortho = true,
    }
    _rc.viewprojmat = math3d.ref(math3d.mul(math3d.projmat(frustum), _rc.viewmat))
end
function dt.process_entity(e)
    update_decal(e)
end

local ds = ecs.system "decal_system"

local decal_register_mb = world:sub{"component_register", "decal"}
local decal_entity_remove_mb = world:sub{"entity_remove", "decal"}

local decal_changed_mb = {}
local decal_transform_mb = {}
function ds.data_changed()
    for _, _, eid in decal_register_mb:unpack() do
        decal_changed_mb[eid] = world:sub{"component_changed", "decal", eid}
        decal_transform_mb[eid] = world:sub{"component_changed", "transform", eid}
    end

    for _, _, eid in decal_entity_remove_mb:unpack() do
        decal_changed_mb[eid] = nil
        decal_transform_mb[eid] = nil
    end

    for eid, mb in pairs(decal_changed_mb) do
        for _, _, eid in mb:unpack() do
            update_decal(world[eid])
        end
    end

    for eid, mb in pairs(decal_transform_mb) do
        for _, _, eid in mb:unpack() do
            update_decal(world[eid])
        end
    end
end