love.filesystem.setRequirePath("?.lua;?/init.lua;lib/?.lua")


local LEDsController     = require("lib.LEDsController")
local loveframes         = require("lib.loveframes")
local json               = require("lib.json")

local frame_animation    = require("frame.animation")
local frame_network_scan = require("frame.network_scan")
local frame_pixel_map    = require("frame.pixel_map")
local frame_network_map  = require("frame.network_map")
local frame_player       = require("frame.player")

local timer = 0
local debug = false
local sync = false
local counter = 0

local time = 0


require("lib/color")

function love.load(arg)

	local os = love.system.getOS()
	if os == "Android" or  os == "iOS" then
		love.window.setMode( 411, 838, {resizable = false} )
	end

	love.filesystem.createDirectory("ressource/music")
	love.filesystem.createDirectory("ressource/shader")
	love.filesystem.createDirectory("ressource/script")
	love.filesystem.createDirectory("ressource/video")

	local thread = love.thread.newThread("thread_led_controller.lua")

	shaders = {}
	shaders_param = {
		speed = 1,
		density = 1,
		bright = 1
	}
	shader_nb = 1

	local list = love.filesystem.getDirectoryItems("ressource/shader/")
	print("Compile shader:")
	for k,v in ipairs(list) do
		print("    "..v)
		shaders[k] = {}
		shaders[k].shader = love.graphics.newShader("ressource/shader/"..v)
		shaders[k].name = v
	end

	love.graphics.setDefaultFilter("nearest", "nearest", 0)

	thread:start(sync, debug)

	local mapping = json.decode(love.filesystem.read("ressource/map/map_42.json"))
	lx = mapping.lx
	ly = mapping.ly
	fps = mapping.fps

	canvas = love.graphics.newCanvas(lx, ly, {dpiscale = 1, mipmaps = "none"})
	canvas_test = love.graphics.newCanvas(lx, ly, {dpiscale = 1, mipmaps = "none"})
	canvas:setFilter("nearest", "nearest")
	canvas_test:setFilter("nearest", "nearest")

	-- loveframes.SetActiveSkin("Orange")
	loveframes.SetActiveSkin("Spectre")
	-- loveframes.SetActiveSkin("Blue")
	-- loveframes.SetActiveSkin("Default red")
	-- loveframes.SetActiveSkin("Dark red")

	frame_animation:load(loveframes)
	-- node_list = frame_network_scan:load(loveframes)
	-- frame_pixel_map:load(loveframes)
	local frame_network_map_frame, network_map = frame_network_map:load(loveframes)
	frame_player_frame = frame_player:load(loveframes)

	love.thread.getChannel("data"):push({
		type = "mapping",
		data = mapping
	})

	for k,v in ipairs(mapping.nodes) do
		network_map:AddRow(
			v.net,
			v.uni,
			v.ip,
			v.port,
			v.protocol,
			v.rgbw,
			v.led_nb
		)
	end

	spectre_img = love.graphics.newImage("ressource/image/spectre.png")
	spectre_img:setFilter("linear", "linear")
	logo_font = love.graphics.newFont("ressource/font/jd_led3.ttf", 150)
	-- logo_font:setFilter("nearest", "nearest")

	local image = love.graphics.newImage("ressource/image/bg.png")
	image:setWrap("repeat", "repeat")
	local width = love.graphics.getWidth()
	local height = love.graphics.getHeight()
	bgquad = love.graphics.newQuad(0, 0, width, height, image:getWidth(), image:getHeight())
	bgimage = image
end

function love.joystickpressed( joystick, button )
	print(joystick, button)

end

function love.draw()
	love.graphics.setColor(1,1,1,1)
	love.graphics.draw(bgimage, bgquad, 0, 0)

	local r,g,b = hslToRgb(time/4%1,1,0.9)
	love.graphics.setColor(r,g,b)
	local lx,ly = love.graphics.getDimensions()
	local sx,sy = spectre_img:getDimensions()
	local kx = lx / (sx*1.5)
	local ky = ly / (sy*1.5)
	local k = math.min(kx,ky)
	sx, sy = sx*k, sy*k
	love.graphics.draw(spectre_img, lx/2-sx/2, ly/3-sy/2, 0, k, k)
	love.graphics.setFont(logo_font)

	local sx = logo_font:getWidth("LED Master")
	local k = lx / (sx*1.5)
	sx = sx * k
	love.graphics.print("LED Master", lx/2-sx/2, ly/3 + sy/2, 0, k, k)

	loveframes.draw()

	-- local width, height = love.window.getDesktopDimensions(1)
	-- local tx, ty =love.window.getMode()
	-- local pixelwidth, pixelheight = love.graphics.getPixelDimensions()
	-- local gx, gy = love.graphics.getDimensions()
	-- local x,y,sx, sy = love.window.getSafeArea()
	-- --
	-- love.graphics.print("getDesktopDimensions: "..width.."x"..height, 10, 50)
	-- love.graphics.print("getMode: "..tx.."x"..ty, 10, 70)
	-- love.graphics.print("getPixelDimensions: "..pixelwidth.."x"..pixelheight, 10, 90)
	-- love.graphics.print("getDimensions: "..gx.."x"..gy, 10, 110)
	-- love.graphics.print("getSafeArea: "..x.."x"..y..", "..sx.."x"..sy, 10, 130)
	-- love.graphics.print("getDPIScale: "..love.graphics.getDPIScale(), 10, 150)
end

local channel_img = love.thread.getChannel('img')
local last_id = nil

function love.update(dt)
	timer = timer + dt
	time = time + (dt * shaders_param.speed)
	-- print(1/dt)

	if timer > 1 / fps then
		local data = canvas:newImageData()
		if last_id then channel_img:hasRead(last_id) end
		last_id = channel_img:push(data)

		timer = 0
	end

	if shaders[shader_nb] then
		if shaders[shader_nb].shader:hasUniform('iResolution') then
			local lx, ly = canvas:getDimensions()
			shaders[shader_nb].shader:send('iResolution', { lx, ly, 1 })
		end
		if shaders[shader_nb].shader:hasUniform('iTime') then
			shaders[shader_nb].shader:send('iTime', time)
		end
		if shaders[shader_nb].shader:hasUniform('iMouse') then
			local lx, ly = love.graphics.getDimensions()
			local lx, ly = canvas:getDimensions()
			shaders[shader_nb].shader:send('iMouse', { lx/love.mouse.getX(), ly/love.mouse.getY()})
		end
		for k,v in pairs(shaders_param) do
			if shaders[shader_nb].shader:hasUniform(k) then
				shaders[shader_nb].shader:send(k,v)
			end
		end
	end

	local info = love.thread.getChannel('node'):pop()
	if info then
		node_list:AddRow(
		info.short_name,
		info.ip[1].."."..info.ip[2].."."..info.ip[3].."."..info.ip[4],
		info.port,
		info.net,
		info.subnet,
		info.nb_port,
		info.bindIndex,
		info.status
	)
	end


	--
	loveframes.update(dt)
end

function love.mousepressed(x, y, button)
	loveframes.mousepressed(x, y, button)
end


function love.mousereleased(x, y, button)
	loveframes.mousereleased(x, y, button)
end

function love.keypressed( key, scancode, isrepeat )
	-- print(key)
	local lx, ly = canvas:getDimensions()
	loveframes.keypressed(key, unicode)
	if key == "up" then
		ly = ly + 1
	elseif key == "down" and canvas:getHeight() > 1 then
		ly = ly - 1
	elseif key == "left" and canvas:getWidth() > 1 then
		lx = lx - 1
	elseif key == "right" then
		lx = lx + 1
	else
		return
	end
	canvas = love.graphics.newCanvas(lx, ly, {dpiscale = 1, mipmaps = "none"})
	canvas_test = love.graphics.newCanvas(lx, ly, {dpiscale = 1, mipmaps = "none"})
	canvas:setFilter("nearest", "nearest")
	canvas_test:setFilter("nearest", "nearest")
end

function love.keyreleased(key)
	loveframes.keyreleased(key)
end

function love.wheelmoved(x, y)
	loveframes.wheelmoved(x, y)
end

function love.resize(w, h)
	bgquad = love.graphics.newQuad(0, 0, w, h, bgimage:getWidth(), bgimage:getHeight())
end

function love.textinput(text)
	loveframes.textinput(text)
end

function love.filedropped(file)
	local path, filename, extention = file:getFilename():match("^(.-)([^\\/]-%.([^\\/%.]-))%.?$")
	print("Drop '"..path.."'  '"..filename.."'  "..extention)
	if extention == "wav" or extention == "mp3" or extention == "ogg" or extention == "oga" or extention == "flac" then
		print("load music")
		file:open("r")
		local data = file:read()
		print(love.filesystem.write( "ressource/music/"..filename, data))
		frame_player_frame:Remove()
		frame_player_frame = frame_player:load(loveframes)
	elseif extention == "glsl" then
		print("load shader")
	elseif extention == "lua" then
		print("load script")
	else
		print("can't load "..extention.." file")
	end
end
