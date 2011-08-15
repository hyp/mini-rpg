img_guy   = image.load("guy2.png")
grass= image.load("grassback.png")

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
	return setmetatable({ x=0,y=0,x2=32,y2=32,size=32, o={} },Node) --o(static objects)
end

function Node:fill()
	self.data=string.rep('\000',self.size*self.size*2)
	print("filling node ",self.data:len())
end

function Node:setBackground(obj,x,y)
	local i,j=0,y*self.size*2+x*2+1
	print("node b",j,"at",x,y)
	self.data=self.data:gsub(".", function(c) i=i+1; if i==j then return string.char(obj) end end)
end

function Node:setForeground(obj,x,y)
	local i,j=0,y*self.size*2+x*2+2
	print("node f",j,"at",x,y)
	self.data=self.data:gsub(".", function(c) i=i+1; if i==j then return string.char(obj) end end)
end

function Node:dump()
	for c in self.data:gmatch("..........") do
		print(c:byte(1),c:byte(2),c:byte(3),c:byte(4),c:byte(5),c:byte(6),c:byte(7),c:byte(8))
	end
end

function Node:isFree(x,y)
	local index=math.floor(y/48)*self.size*2+math.floor(x/48)*2
	return self.data:byte(index+2)==0
end

function Node:draw()
	--find out the visible boundaries
	local i,j       =math.floor(math.max(viewx-self.x,0)/48),math.floor(math.max(viewy-self.y,0)/48)
	local i2,j2,ii  =math.min(self.x2,i+9),math.min(self.y2,j+6),i
	local index,back,fore
	--5 rows
	while j<j2 do
		index=j*self.size*2+1
		i=ii
		--9 columns
		while i<i2 do
			back,fore=self.data:byte(index+i*2,index+i*2+1)
			if back~=0 then
				back=backgroundTiles[back]
				back.img:safeDraw(i*48+self.x-viewx,j*48+self.y-viewy,back.x,back.y,back.w,back.h)
			end
			if fore~=0 then
				fore=foregroundTiles[fore]
				fore.img:safeDraw(i*48+self.x-viewx,j*48+self.y-viewy,fore.x,fore.y,fore.w,fore.h)
			end
			i=i+1
		end
		j=j+1
	end
end

node=Node.new()

node:fill()

node:setForeground(1,3,2)
node:setForeground(1,5,2)


node:setBackground(1,4,1)
node:setBackground(1,4,2)
node:setBackground(1,4,3)
node:setBackground(3,4,4)
collectgarbage() --important after node modifications!
--node:dump()

roadImg=image.load("road.png");
foregroundTiles={ [1]={ img=image.load("fence.png"),x=0,y=0,w=48,h=48 } }
backgroundTiles={ [1]={img=roadImg,x=0,y=0,w=48,h=48},[2]={img=roadImg,x=48,y=0,w=48,h=48},[3]={img=roadImg,x=0,y=48,w=48,h=48} }



function Redraw()
		grass:safeDraw(0,0,48- viewx % 48,48- viewy % 48,ScreenWidth,ScreenHeight)
	
		--just debug
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
		grid()

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