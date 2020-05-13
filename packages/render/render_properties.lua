local ecs = ...
local world = ecs.world
local renderpkg = import_package "ant.render"
local fbmgr = renderpkg.fbmgr
local camerautil = renderpkg.camera
local shadowutil = renderpkg.shadow

local mathpkg = import_package "ant.math"
local mc, mu = mathpkg.constant, mathpkg.util

local math3d = require "math3d"

local m = ecs.interface "render_properties"
local render_properties = {}
function m.data()
	return render_properties
end

local function add_directional_light_properties(world, uniform_properties)
	local dlight = world:singleton_entity "directional_light"
	if dlight then
		uniform_properties["directional_lightdir"][1].v 	= dlight.direction
		uniform_properties["directional_color"][1].v 	= dlight.directional_light.color
		uniform_properties["directional_intensity"][1].v = {dlight.directional_light.intensity, 0.28, 0, 0}
	end
end

local mode_type = {
	factor = 0,
	color = 1,
	gradient = 2,
}

--add ambient properties
local function add_ambient_light_propertices(world, uniform_properties)
	local le = world:singleton_entity "ambient_light"
	if le then
		local ambient = le.ambient_light
		uniform_properties["ambient_mode"][1].v			= {mode_type[ambient.mode], ambient.factor, 0, 0}
		uniform_properties["ambient_skycolor"][1].v		= ambient.skycolor
		uniform_properties["ambient_midcolor"][1].v		= ambient.midcolor
		uniform_properties["ambient_groundcolor"][1].v	= ambient.groundcolor
	end
end 

local function load_lighting_properties(world, render_properties)
	local uniforms = assert(render_properties.uniforms)

	add_directional_light_properties(world, uniforms)
	add_ambient_light_propertices(world, uniforms)

	local camera = camerautil.main_queue_camera(world)
	uniforms["u_eyepos"][1].v = camera.eyepos
end

local function calc_viewport_crop_matrix(csm_idx)
	local ratios = shadowutil.get_split_ratios()
	local numsplit = #ratios
	local spiltunit = 1 / numsplit

	local offset = spiltunit * (csm_idx - 1)

	return math3d.matrix(
		spiltunit, 0.0, 0.0, 0.0,
		0.0, 1.0, 0.0, 0.0, 
		0.0, 0.0, 1.0, 0.0,
		offset, 0.0, 0.0, 1.0)
end

local function load_shadow_properties(world, render_properties)
	local uniforms, textures = render_properties.uniforms, render_properties.textures

	--TODO: shadow matrix consist of lighting matrix, crop matrix and viewport offset matrix
	-- but crop matrix and viewport offset matrix only depend csm split ratios
	-- we can detect csm split ratios changed, and update those matrix two matrices, and combine as bias matrix
	local csm_matrixs = uniforms.u_csm_matrix
	local split_distances = {0, 0, 0, 0}
	for _, eid in world:each "csm" do
		local se = world[eid]
		local csm = se.csm

		local camera = world[se.camera_eid].camera

		local idx = csm.index
		local split_distanceVS = csm.split_distance_VS
		if split_distanceVS then
			split_distances[idx] = split_distanceVS
			local vp = mu.view_proj(camera)
			vp = math3d.mul(shadowutil.shadow_crop_matrix(), vp)
			local viewport_cropmatrix = calc_viewport_crop_matrix(idx)
			csm_matrixs[csm.index].m = math3d.mul(viewport_cropmatrix, vp)
		end
	end

	uniforms["u_csm_split_distances"][1].v = split_distances

	local shadowentity = world:singleton_entity "shadow"
	if shadowentity then
		local fb = fbmgr.get(shadowentity.fb_index)
		local sm = textures["s_shadowmap"]
		sm.stage = world:interface "ant.render|uniforms".system_uniform("s_shadowmap").stage
		sm.handle = fbmgr.get_rb(fb[1]).handle

		uniforms["u_depth_scale_offset"][1].v = shadowutil.shadow_depth_scale_offset()
		local shadow = shadowentity.shadow
		uniforms["u_shadow_param1"][1].v = {shadow.bias, shadow.normal_offset, 1/shadow.shadowmap_size, 0}
		local shadowcolor = shadow.color or {0, 0, 0, 0}
		uniforms["u_shadow_param2"][1].v = shadowcolor
	end
end

local function load_postprocess_properties(world, render_properties)
	local mq = world:singleton_entity "main_queue"
	local fbidx = mq.render_target.fb_idx
	if fbidx then
		local fb = fbmgr.get(fbidx)
		local rendertex = fbmgr.get_rb(fb[1]).handle
		local mainview_name = "s_mainview"
		local stage = assert(world:interface "ant.render|uniforms".system_uniform(mainview_name)).stage
		local textures = render_properties.textures
		local mv = textures[mainview_name]
		mv.stage = stage
		mv.handle = rendertex
	end
end

local load_properties_sys = ecs.system "load_properties_system"

function  load_properties_sys:init()
	local rp = world:interface "ant.render|render_properties".data()

	rp.uniforms = {
	--lighting
		directional_lightdir 	= world.component:uniform{type="v4", 	mc.T_ZERO},
		directional_color 		= world.component:uniform{type="color",mc.T_ZERO},
		directional_intensity 	= world.component:uniform{type="v4", 	mc.T_ZERO},

		ambient_mode 			= world.component:uniform{type="v4", 	 mc.T_ZERO},
		ambient_skycolor 		= world.component:uniform{type="color", mc.T_ZERO},
		ambient_midcolor 		= world.component:uniform{type="color", mc.T_ZERO},
		ambient_groundcolor 	= world.component:uniform{type="color", mc.T_ZERO},

		u_eyepos				= world.component:uniform{type="v4", mc.T_ZERO_PT},

		-- shadow
		u_csm_matrix 			= world.component:uniform{type="m4_array", mc.T_IDENTITY_MAT, mc.T_IDENTITY_MAT, mc.T_IDENTITY_MAT, mc.T_IDENTITY_MAT},
		u_csm_split_distances	= world.component:uniform{type="v4", mc.T_ZERO},

		u_depth_scale_offset	= world.component:uniform{type="v4", mc.T_ZERO},
		u_shadow_param1			= world.component:uniform{type="v4", mc.T_ZERO},
		u_shadow_param2			= world.component:uniform{type="v4", mc.T_ZERO},
	}
	rp.textures = {
		s_shadowmap = {type="texture", },
		s_mainview = {type="texture", },
	}
end

function load_properties_sys:load_render_properties()
	local rp = world:interface "ant.render|render_properties".data()
	load_lighting_properties(world, rp)
	load_shadow_properties(world, rp)
	load_postprocess_properties(world, rp)
end
