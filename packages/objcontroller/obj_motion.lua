local ecs = ...
local world = ecs.world

local math3d = require "math3d"
local mu     = import_package "ant.math".util
local mc     = import_package "ant.math".constant

local iobj_motion = ecs.interface "obj_motion"
local icamera = world:interface "ant.camera|camera"

function iobj_motion.get_position(eid)
    return math3d.index(world[eid]._rendercache.srt, 4)
end

function iobj_motion.set_position(eid, pos)
    world[eid]._rendercache.srt[4] = pos
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.get_direction(eid)
    return math3d.index(world[eid]._rendercache.srt, 3)
end

function iobj_motion.set_direction(eid, dir)
    local e = world[eid]
    local rc = e._rendercache
    local srt = rc.srt
    if e.camera then
        srt.id = math3d.inverse(math3d.lookto(math3d.index(srt, 4), dir, rc.updir))
    else
        srt.r = math3d.torotation(dir)
    end
    
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.srt(eid)
    return world[eid]._rendercache.srt
end

function iobj_motion.set_srt(eid, srt)
    world[eid]._rendercache.srt.m = srt
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.set_view(eid, pos, dir, updir)
    local e = world[eid]
    local rc = e._rendercache
    local srt = rc.srt
    if e.camera then
        srt.id = math3d.inverse(math3d.lookto(pos, dir, updir or rc.updir))
    else
        local s = math3d.matrix_scale(srt)
        srt.id = math3d.matrix{s=s, r=math3d.torotation(dir), t=pos}
    end

    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.set_scale(eid, scale)
    world[eid]._rendercache.srt.s = scale
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.get_scale(eid)
    return math3d.matrix_scale(world[eid]._rendercache.srt)
end

function iobj_motion.set_rotation(eid, rot)
    local e = world[eid]
    local rc = e._rendercache
    local srt = rc.srt
    if e.camera then
        local viewdir = math3d.todirection(rot)
        srt.id = math3d.inverse(math3d.lookto(math3d.index(srt, 4), viewdir, rc.updir))
    else
        srt.r = rot
    end
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.get_rotation(eid)
    --torotation is more efficient than srt.r
    return world[eid]._rendercache.srt.r
    --return math3d.torotation(math3d.index(world[eid]._rendercache.srt, 3))
end

function iobj_motion.worldmat(eid)
    return world[eid]._rendercache.worldmat
end

function iobj_motion.lookto(eid, eyepos, viewdir, updir)
    local e = world[eid]
    local rc = e._rendercache
    if e.camera then
        rc.updir = updir
    end
    rc.srt.id = math3d.inverse(math3d.lookto(eyepos, viewdir, updir))
    world:pub{"component_changed", "transform", eid}
end

function iobj_motion.move_delta(eid, delta_vec)
    local srt = world[eid]._rendercache.srt
    local pos = math3d.add(math3d.index(srt, 4), delta_vec)
    iobj_motion.set_position(eid, pos)
end

function iobj_motion.move_along_axis(eid, axis, delta)
    local p = iobj_motion.get_position(eid)
    iobj_motion.set_position(eid, math3d.muladd(axis, delta, p))
end

function iobj_motion.move(eid, v)
    local srt = world[eid]._rendercache.srt
    local p = math3d.index(srt, 4)
    for i=1, 3 do
        p = math3d.muladd(v[i], math3d.index(srt, i), p)
    end
    iobj_motion.set_position(eid, p)
end

function iobj_motion.set_lock_target(eid, lt)
    local nlt = {}; for k, v in pairs(lt) do nlt[k] = v end
    world[eid]._rendercache.lock_target = nlt
    world:pub{"component_changed", "lock_target", eid}
end

local function calc_rotation(srt, rotateX, rotateY, threshold)
    rotateX = rotateX or 0
    rotateY = rotateY or 0

    threshold = threshold or 10e-6

    local q = srt.r
    local nq = math3d.mul(math3d.mul(
        math3d.quaternion{axis=math3d.index(srt, 1), r=rotateX},
        math3d.quaternion{axis=math3d.index(srt, 2), r=rotateY}), q)

    local v = math3d.transform(nq, mc.ZAXIS, 0)
    
    if mu.iszero(math3d.dot(v, mc.NZAXIS), threshold) or mu.iszero(math3d.dot(v, mc.ZAXIS), threshold) then
        return q
    end

    return nq
end

function iobj_motion.rotate(eid, rotateX, rotateY)
    if rotateX or rotateY then
        local srt = world[eid]._rendercache.srt
        iobj_motion.set_rotation(eid, calc_rotation(srt, rotateX, rotateY))
    end
end

function iobj_motion.rotate_around_point(eid, targetpt, distance, dx, dy, threshold)
    local srt = world[eid]._rendercache.srt
    local q = calc_rotation(srt, -dx, -dy, threshold)

    local dir = math3d.normalize(math3d.inverse(math3d.transform(q, mc.ZAXIS, 0)))
    local p = math3d.muladd(distance, dir, targetpt)
    iobj_motion.set_view(eid, p, dir)
end

local function main_queue_viewport_size()
    local mq = world:singleton_entity "main_queue"
    local vp_rt = mq.render_target.view_rect
    return {w=vp_rt.w, h=vp_rt.h}
end

function iobj_motion.ray(eid, pt2d, vp_size)
    vp_size = vp_size or main_queue_viewport_size()

    local ndc_near, ndc_far = mu.NDC_near_far_pt(mu.pt2D_to_NDC(pt2d, vp_size))

    local viewproj = icamera.calc_viewproj(eid)
    local invviewproj = math3d.inverse(viewproj)
    local pt_near_WS = math3d.transformH(invviewproj, ndc_near, 1)
    local pt_far_WS = math3d.transformH(invviewproj, ndc_far, 1)

    local dir = math3d.normalize(math3d.sub(pt_far_WS, pt_near_WS))
    return {
        origin = pt_near_WS,
        dir = dir,
    }
end

local function calc_worldmat(eid, c_mt)
    if not eid then
        return math3d.matrix()
    end
    local srt = world[eid]._rendercache.srt
    local wm
    if srt then
        wm = c_mt and math3d.mul(srt, c_mt) or math3d.matrix(srt)
    else
        wm = c_mt
    end

	local e = world[eid]
	if e.parent then
		return calc_worldmat(e.parent, wm)
	end
	return wm
end

function iobj_motion.calc_worldmat(eid)
    return calc_worldmat(eid)
end