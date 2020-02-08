local animation = {}

function animation:load(loveframes, lx, ly)
	local frame = loveframes.Create("frame")
	frame:SetName("Animation")
	frame:SetSize(600, 300)
	frame:SetScreenLocked(true)

	frame:SetResizable(true)
	frame:SetMaxWidth(1000)
	frame:SetMaxHeight(1000)
	frame:SetMinWidth(200)
	frame:SetMinHeight(200)

	frame:SetDockable(true)

	local panel = loveframes.Create("panel", frame)
	panel:SetPos(4, 28)
	panel:SetSize(frame:GetWidth()-8, frame:GetHeight()-28-4)

	panel.Draw = function(object)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(
			canvas,
			object:GetX(),
			object:GetY(),
			0,
			(object:GetWidth())/canvas:getWidth(),
			(object:GetHeight())/canvas:getHeight()
		)
		local lx, ly = canvas:getDimensions()
		love.graphics.setColor(0, 0, 0)
		love.graphics.print(lx.."x"..ly.." FPS: "..love.timer.getFPS(), object:GetX()+5+1, object:GetY()+5+1)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(lx.."x"..ly.." FPS: "..love.timer.getFPS(), object:GetX()+5, object:GetY()+5)
	end

	panel.Update = function(object)
		object:SetSize(frame:GetWidth()-8, frame:GetHeight()-28-4)
	end


end

return animation