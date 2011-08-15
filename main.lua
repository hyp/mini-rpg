img_guy   = image.load("guy2.png")
grass= image.load("grassback.png")
GuyDirX,GuyDirY=0,0
DlgBcgColor=color.new(0,153,51)
function Main()
	local oldOrientation=screen.orientation()
	screen.orientation(0)
	ScreenWidth =screen.width()
	ScreenHeight=screen.height()
	
	
		
	Loop()
	screen.orientation(oldOrientation)
end


guy= { x=192,y=96,frame=1,dir=0,img=img_guy }

viewx,viewy=0,0

function createCharacter(cx,cy,image)
	return {x=cx,y=cy,frame=1,dir=0,img=image}
end

enemy= createCharacter(192,144,image.load("enemy2.png"))

function drawCharacter(char)
	char.img:safeDraw(char.x-viewx,char.y-viewy-4,char.frame*48,char.dir*48,48,48)
end

function moveCharacter(char,x,y)
	if not node:isFree(char.x+x,char.y+y) then Redraw();popup("Can't go there!");return end
	--print("move character "..char.x..","..char.y)
	char.frame=2
	char.x=char.x+x/3
	char.y=char.y+y/3
	viewx=viewx+x/3
	viewy=viewy+y/3
	Redraw()
	os.sleep(15)
	char.frame=0
	char.x=char.x+x/3
	char.y=char.y+y/3
	viewx=viewx+x/3
	viewy=viewy+y/3
	Redraw()
	os.sleep(15)	
	char.frame=1
	char.x=char.x+x/3
	char.y=char.y+y/3
	viewx=viewx+x/3
	viewy=viewy+y/3
	Redraw()
	--print(" done"..char.x..","..char.y)
end

function popup(msg)
	local white=color.new(32,32,32,200)
	local t=color.new(255,255,255)
	local b=color.new(0,0,0)
	screen.fillrect(0,ScreenHeight-48,ScreenWidth,48,white)
	screen.drawrect(0,ScreenHeight-48,ScreenWidth-1,ScreenHeight-1,b)
	text.size(18)
	text.color(t)
	text.draw(48,ScreenHeight-44,msg)
	--text.draw(48,ScreenHeight-24,"AAargh!!!")
	guy.img:safeDraw(8,ScreenHeight-40,57,0,32,32)
	screen.drawrect(8,ScreenHeight-40,40,ScreenHeight-8,b)
	
	screen.update()
	
	os.sleep(70)
	Redraw()
end

function image:safeDraw(x,y,sx,sy,sw,sh)
	-- if x<0 or y<0 then
		-- -- negative coords bug? crop
		-- local nsx,nsy	=sx,sy
		-- if x<0 then
			-- nsx=sx-x
			-- if sw+x<=0 then return end
			-- x=0			
		-- end
		-- if y<0 then
			-- nsy=sy-y
			-- if sh+y<=0 then return end
			-- y=0			
		-- end
		-- self:draw(x-nsx,y-nsy,x,y,sw,sh)
	-- else

		self:draw(x-sx,y-sy,x,y,sw,sh)
	--end
end



Node = { }
Node.__index=Node

function Node.new()
	return setmetatable({ x=0,y=0,x2=16,y2=16,size=16, o={} , },Node) --o(static objects)
end

function Node:add(obj,x,y)
	local index=math.floor(y/48)*self.size*2+math.floor(x/48)*2
	--print("node index at "..x..","..y.." is "..index)
	self.o[index]=obj
	--print(self.o[index])
end

function Node:isFree(x,y)
	local index=math.floor(y/48)*self.size*2+math.floor(x/48)*2
	--if self.o[index]~=nil then return false end
	return true
end

function Node:draw()
	--find out the visible boundaries --to fix
	local minx,miny=math.floor((viewx-self.x)/48),math.floor((viewy-self.y)/48)
	local maxx,maxy,x,y=math.min(self.x2,minx+9),math.min(self.y2,miny+6),minx,miny
	--5 rows
	while y<maxy do
		x=minx
		--9 columns
		while x<maxx do
			local obj=self.o[y*self.size*2+x*2]
			--print("drawing index "..y*self.size*2+x*2 .." at "..x..","..y)
			if obj~=nil then
				--print(" obj not nil")
				objects[obj].img:safeDraw(x*48+self.x-viewx,y*48+self.y-viewy,objects[obj].x,objects[obj].y,objects[obj].w,objects[obj].h)
			end
			x=x+1
		end
		y=y+1
	end
end

node=Node.new()

objects={ [0]={ img=image.load("tree.png"),x=0,y=0,w=96,h=96 },[1]={ img=image.load("fence.png"),x=0,y=0,w=48,h=48 },
[2]={ img=image.load("road.png"),x=0,y=0,w=48,h=48 },[3]={ img=image.load("road.png"),x=48,y=0,w=48,h=48 },
[4]={ img=image.load("road.png"),x=0,y=48,w=48,h=48 } }
node:add(0,48,48)
node:add(0,48,96)
node:add(0,48,144)

node:add(1,144,96)
node:add(1,240,96)
node:add(0,48,144)

node:add(2,192,96)
node:add(2,192,48)
node:add(2,192,144)

node:add(4,192,192)
node:add(3,288,192)
node:add(3,144,192)
node:add(3,240,192)

for x = 0,15 do
	node:add(1,x*48,0)
	node:add(1,x*48,15*48)
end



function Redraw()
		--screen.fillrect(0,0,ScreenWidth,ScreenHeight,DlgBcgColor)
		

		grass:safeDraw(0,0,48- viewx % 48,48- viewy % 48,ScreenWidth,ScreenHeight)

			
		
		function grid()
			local lc=color.new(255,0,0)
			local x,y=0,0
			while x<ScreenWidth do
				screen.drawline(x,0,x,ScreenHeight,lc,1);x=x+48
			end
			while y<ScreenHeight do
				screen.drawline(0,y,ScreenWidth,y,lc,1);y=y+48
			end
		end 
		
		--grid()

		node:draw()
		
		drawCharacter(enemy)
		drawCharacter(guy)


		screen.update()
end
	


function Loop()
	Redraw()
	local SwipeX,SwipeY,CurX,CurY,moving=false
	while 1 do
		--input
		if control.read()==1 then
			if control.isTouch()==1 then
				CurX,CurY=touch.pos()
				if touch.down()==1 then
					SwipeX=CurX-(guy.x-viewx)
					SwipeY=CurY-(guy.y-viewy)
					if math.abs(SwipeY)>math.abs(SwipeX) then
						if SwipeY<0 then guy.dir=3;SwipeY=-48 else guy.dir=0;SwipeY=48 end
						SwipeX=0
					else
						if SwipeX<0 then guy.dir=1;SwipeX=-48 else guy.dir=2;SwipeX=48 end
						SwipeY=0
					end
					moveCharacter(guy,SwipeX,SwipeY)
				end
			elseif control.isButton()==1 then
				return
			end
		else
			os.sleep(5)
		end
	end
	-- Redraw()
	-- local SwipeX,SwipeY,CurX,CurY,moving
	-- moving=0
	-- while 1 do
		-- if control.read()==1 then
			-- if control.isTouch()==1 then
				-- CurX,CurY=touch.pos()
				-- if touch.click()==1 then
					-- --GuyX,GuyY=touch.pos()
					-- Redraw()
				-- -- elseif touch.move()==1 and CurX<bulletStartX and CurY>bulletStartY then
					-- -- if bulletLaunching then
						-- -- bulletX,bulletY=CurX,CurY
						-- -- Redraw()
					-- -- else
						-- -- bulletX,bulletY=CurX,CurY
						-- -- bulletLaunching=true
					-- -- end
				-- -- elseif touch.up()==1 then
					-- -- bulletLaunching=false
				-- -- end
					-- elseif touch.move()==1 then
						-- SwipeX=CurX-GuyX
						-- SwipeY=CurY-GuyY
						-- magn=math.sqrt(SwipeX*SwipeX+SwipeY*SwipeY)
						-- SwipeX=SwipeX/magn;SwipeY=SwipeY/magn --normalized dir vector
						-- print ("s "..SwipeX..","..SwipeY)
						-- GuyDirY=SwipeY;GuyDirX=SwipeX
						-- GuyX=GuyX+SwipeX*3
						-- GuyY=GuyY+SwipeY*3
						-- Redraw()
				-- end
			-- --buttons
			-- elseif control.isButton()==1 then
				-- if button.click() == 1 then
					-- --if button.home()==1 then
						-- --ScrollDown(1)
					-- --else
						-- return						
					-- --end
				-- end
			-- end    
		-- else
			-- os.sleep(5)
		-- end
	-- end
end

Main()