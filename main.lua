--tileSize
tileSize=48

--ui + hud
dialogTextColor,dialogBackColor,dialogOutColor=color.new(255,255,255),color.new(32,32,32,200),color.new(0,0,0)
healthbarColor=color.new(232,0,0)

--current world(level/room)
--x,y : view offset
world={ x=0,y=0,background=image.load("gfx/grassback.png"),prev=nil }

--dbg
renderTime=0

--characters
function createCharacter(cx,cy,image)
	return {x=cx,y=cy,frame=1,dir=0,img=image,hp=75}
end

function drawCharacter(char)
	char.img:safeDraw(char.x-world.x,char.y-world.y-4,char.frame*tileSize,char.dir*tileSize,tileSize,tileSize)
end

hero = createCharacter(tileSize*4,tileSize*2,image.load("guy2.png"))
enemy= createCharacter(240,92,image.load("enemy2.png"))


function moveCharacter(char,x,y)
	if not node:isFree(char.x+x,char.y+y) then Redraw();popup(hero,"Can't go there!");return end
	--print("move character "..char.x..","..char.y)
	char.frame=2
	char.x=char.x+x/3
	char.y=char.y+y/3
	world.x=world.x+x/3
	world.y=world.y+y/3
	Redraw()
	os.sleep(15)
	char.frame=0
	char.x=char.x+x/3
	char.y=char.y+y/3
	world.x=world.x+x/3
	world.y=world.y+y/3
	Redraw()
	os.sleep(15)	
	char.frame=1
	char.x=char.x+x/3
	char.y=char.y+y/3
	world.x=world.x+x/3
	world.y=world.y+y/3
	Redraw()

	--print(" done"..char.x..","..char.y)
end

function popup(who,msg)

	screen.fillrect(0,ScreenHeight-48,ScreenWidth,48,dialogBackColor)
	screen.drawrect(0,ScreenHeight-48,ScreenWidth-1,ScreenHeight-1,dialogOutColor)
	text.size(18)
	text.color(dialogTextColor)
	text.draw(48,ScreenHeight-44,msg)
	who.img:safeDraw(8,ScreenHeight-40,57,0,32,32)
	screen.drawrect(8,ScreenHeight-40,40,ScreenHeight-8,dialogOutColor)
	
	screen.update()
	
	os.sleep(70)
	Redraw()
end

function image:safeDraw(x,y,sx,sy,sw,sh)
	self:draw(x-sx,y-sy,x,y,sw,sh)
end



Node = { }
Node.__index=Node

function Node.new()
	return setmetatable({ x=0,y=0,x2=32,y2=32,size=32 },Node)
end

function Node:fill()
	self.data=string.rep('\000',self.size*self.size*2)
	print("filling node ",self.data:len())
end

function Node:setBackground(obj,x,y)
	local i,j=0,y*self.size*2+x*2+1
	--print("node b",j,"at",x,y)
	self.data=self.data:gsub(".", function(c) i=i+1; if i==j then return string.char(obj) end end)
end

function Node:setForeground(obj,x,y)
	local i,j=0,y*self.size*2+x*2+2
	--print("node f",j,"at",x,y)
	self.data=self.data:gsub(".", function(c) i=i+1; if i==j then return string.char(obj) end end)
end

function Node:dump()
	for c in self.data:gmatch("..........") do
		print(c:byte(1),c:byte(2),c:byte(3),c:byte(4),c:byte(5),c:byte(6),c:byte(7),c:byte(8))
	end
end

function Node:isFree(x,y)
	local index=math.floor(y/tileSize)*self.size*2+math.floor(x/tileSize)*2
	local fore=self.data:byte(index+2)
	return fore==0 or fore>149
end

function Node:draw()
	--find out the visible boundaries
	local i,j       =math.floor(math.max(world.x-self.x,0)/tileSize),math.floor(math.max(world.y-self.y,0)/tileSize)
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
				back.img:safeDraw(i*tileSize+self.x-world.x,j*tileSize+self.y-world.y,back.x,back.y,back.w,back.h)
			end
			if fore~=0 then
				fore=foregroundTiles[fore]
				if fore.w~=tileSize then
					fore.img:safeDraw(i*tileSize+self.x-world.x+(tileSize-fore.w)/2,j*tileSize+self.y-world.y+(tileSize-fore.h)/2,fore.x,fore.y,fore.w,fore.h)
				else
					fore.img:safeDraw(i*tileSize+self.x-world.x,j*tileSize+self.y-world.y,fore.x,fore.y,fore.w,fore.h)
				end
			end
			i=i+1
		end
		j=j+1
	end
end

node=Node.new()

node:fill()

node:setForeground(1,3,3)
node:setForeground(1,5,3)
node:setForeground(150,5,4)
node:setForeground(2,3,2)
node:setBackground(4,3,3)
node:setBackground(5,3,4)

for i=0,31 do
	node:setForeground(1,i,0)
end

node:setBackground(1,4,1)
node:setBackground(1,4,2)
node:setBackground(1,4,3)
node:setBackground(3,4,4)
collectgarbage() --important after node modifications!
--node:dump()

roadImg=image.load("road.png");
grassImg=image.load("grasspack.png");
foregroundTiles={ [1]={ img=image.load("fence.png"),x=0,y=0,w=tileSize,h=tileSize },[2]={ img=image.load("bush2.png"),x=0,y=0,w=tileSize,h=tileSize },[150]={ img=image.load("apples.png"),x=0,y=0,w=24,h=24 } }
backgroundTiles={ [1]={img=roadImg,x=0,y=0,w=tileSize,h=tileSize},[2]={img=roadImg,x=tileSize,y=0,w=tileSize,h=tileSize},[3]={img=roadImg,x=0,y=tileSize,w=tileSize,h=tileSize} ,
[4]={img=grassImg,x=0,y=0,w=tileSize,h=tileSize},[5]={img=grassImg,x=tileSize,y=0,w=tileSize,h=tileSize}}



function Redraw()
	local clk=os.clock()
	world.background:safeDraw(0,0,tileSize- world.x % tileSize,tileSize- world.y % tileSize,ScreenWidth,ScreenHeight)
	
	--just debug
	function grid()
		local lc=color.new(255,0,0)
		local x,y=0,0
		while x<ScreenWidth do
			screen.drawline(x,0,x,ScreenHeight,lc,1);x=x+tileSize
		end
		while y<ScreenHeight do
			screen.drawline(0,y,ScreenWidth,y,lc,1);y=y+tileSize
		end
	end 
	--grid()

	node:draw()
		
	drawCharacter(enemy)
	drawCharacter(hero)
	
	function bar(x,y,w,h,v,c)
		screen.fillrect(x,y,w,h,dialogBackColor)
		screen.fillrect(x,y,v*w,h,c)
		screen.drawrect(x,y,x+w-1,y+h-1,dialogOutColor)
	end
	
	bar(4,4,64,10,hero.hp/100,healthbarColor)
	
	print(renderTime,gcinfo())
	text.size(15)
	text.color(dialogTextColor)
	--text.draw(0,0,renderTime)
	--text.draw(0,16,gcinfo())

	screen.update()
	renderTime=os.clock()-clk
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
					SwipeX=CurX-(hero.x-world.x)
					SwipeY=CurY-(hero.y-world.y)
					if math.abs(SwipeY)>math.abs(SwipeX) then
						if SwipeY<0 then hero.dir=3;SwipeY=-tileSize else hero.dir=0;SwipeY=tileSize end
						SwipeX=0
					else
						if SwipeX<0 then hero.dir=1;SwipeX=-tileSize else hero.dir=2;SwipeX=tileSize end
						SwipeY=0
					end
					moveCharacter(hero,SwipeX,SwipeY)
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
					-- --heroX,heroY=touch.pos()
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
						-- SwipeX=CurX-heroX
						-- SwipeY=CurY-heroY
						-- magn=math.sqrt(SwipeX*SwipeX+SwipeY*SwipeY)
						-- SwipeX=SwipeX/magn;SwipeY=SwipeY/magn --normalized dir vector
						-- print ("s "..SwipeX..","..SwipeY)
						-- heroDirY=SwipeY;heroDirX=SwipeX
						-- heroX=heroX+SwipeX*3
						-- heroY=heroY+SwipeY*3
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

oldOrientation=screen.orientation()
screen.orientation(0)
ScreenWidth =screen.width()
ScreenHeight=screen.height()	
Loop()
screen.orientation(oldOrientation)