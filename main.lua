--tileSize
tileSize=48

--timers
timer = { n=0,maxn=5,times={},cb={} }

function timer.new(ms,cb)
	if timer.n>=timer.maxn then print("out of timers")
	else
		timer.times[timer.n]=ms
		timer.cb[timer.n]=cb
		timer.n=timer.n+1
	end
end

function timer.update(ms)
	--decrease counters
	for i=0,timer.n-1 do
		timer.times[i]=timer.times[i]-ms
		if timer.times[i]<=0 then
			timer.cb[i]()
			--bring down the other counters
			for j=i+1,timer.n-1 do
				timer.times[j-1]=timer.times[j]
				timer.cb[j-1]=timer.cb[j]
			end
			timer.n=timer.n-1
		end
	end
end

--how many frames we still need to draw
redrawCount=1

function redraw(frames)
	if frames==nil then frames=1 end
	if redrawCount<frames then redrawCount=frames end
end

-- not really safe but rather argument fixing
function image:safeDraw(x,y,sx,sy,sw,sh)
	self:draw(x-sx,y-sy,x,y,sw,sh)
end

--ui + hud
dialogTextColor,dialogBackColor,dialogOutColor,dialogRedTextColor=color.new(255,255,255),color.new(32,32,32,200),color.new(0,0,0),color.new(200,0,0)
healthbarColor=color.new(232,0,0)

dialogVisible,dialogWho,dialogWhat=false,nil,nil

function popup(who,msg)
	dialogVisible=true
	dialogWho=who
	dialogWhat=msg
	timer.new(1000,function() dialogVisible=false;redraw() end)
	redraw()
end

function dialogDraw()
	screen.fillrect(0,ScreenHeight-48,ScreenWidth,48,dialogBackColor)
	screen.drawrect(0,ScreenHeight-48,ScreenWidth-1,ScreenHeight-1,dialogOutColor)
	text.size(18)
	text.color(dialogTextColor)
	text.draw(48,ScreenHeight-44,dialogWhat)
	dialogWho.img:safeDraw(8,ScreenHeight-40,57,0,32,32)
	screen.drawrect(8,ScreenHeight-40,40,ScreenHeight-8,dialogOutColor)
end

function drawBar(x,y,w,h,v,c)
	screen.fillrect(x,y,w,h,dialogBackColor)
	screen.fillrect(x,y,v*w,h,c)
	screen.drawrect(x,y,x+w-1,y+h-1,dialogOutColor)
end

function drawHud()
	drawBar(4,4,90,10,hero.hp/100,healthbarColor)
	
	--dbg
	text.size(15)
	text.color(dialogTextColor)
	text.draw(0,16,renderTime..','..globalTime)
	text.draw(0,32,gcinfo())
	
	if dialogVisible then dialogDraw() end
end

function showLoadingScreen()
	screen.fillrect(0,0,ScreenWidth,ScreenHeight,dialogOutColor)
	text.size(22)
	text.color(dialogTextColor)
	text.draw(0,ScreenHeight/2-11,"Loading...","center",ScreenWidth)
	screen.update()
end

function showDeathScreen()
	screen.fillrect(0,0,ScreenWidth,ScreenHeight,dialogBackColor)
	text.size(28)
	text.color(dialogRedTextColor)
	text.draw(0,ScreenHeight/2-14,"You've died!","center",ScreenWidth)
	screen.update()
	os.wait(1500)
	
end

--world is a level/area in game
Environment = { }
Environment.__index=Environment

function Environment.currentWorld(filename)
	--clear up prev world
	if world~=nil then
		world:clear()
		world=nil
	end
	world=setmetatable(dofile("worlds/"..filename),Environment)
	world:load()
	collectgarbage()
end

function Environment:load()
	self.backgroundImg=image.load(self.background) --??
	
	local f=io.open("worlds/"..self.dataFile,"rb")
	self.data=f:read(self.w*self.h*2)
	f:close()
end

function Environment:clear()
	self.backgroundImg:clear()
	self.data=nil
end

--our world
function Environment:xyToTileIndex(x,y)
	return math.floor(y/tileSize)*self.w+math.floor(x/tileSize)
end

function Environment:draw()
	local vx,vy,b=viewx,viewy,self.backgroundImg
	--find out the i and j indeces for the first visible tile
	local i,j       =math.floor(math.max(vx,0)/tileSize),math.floor(math.max(vy,0)/tileSize)
	--from i and j calculate the flat index of the first visible tile
	local ix1=j*self.w*2+i*2+1
	--calculate the position of first tile in screen coordinates
	local x1,y=i*tileSize-vx,j*tileSize-vy
	--find out the visible boundaries
	local xm,ym=math.min(self.w,i+9)*tileSize-vx,math.min(self.h,j+6)*tileSize-vy
	local l,h,x,ix
	while y<ym do
		x=x1
		ix=ix1
		while x<xm do
			l,h=self.data:byte(ix,ix+1)
			b:safeDraw(x,y,0,0,48,48)
			td[h*256+l](x,y)
			x=x+tileSize;ix=ix+2		
		end
		y=y+tileSize
		ix1=ix1+self.w*2 --next row index
	end
end

function Environment:canMove(x,y,dir,x2,y2)
	--can we move from current tile in a given direction?
	local index=math.floor(y/tileSize)*self.w*2+math.floor(x/tileSize)*2
	local l,h=self.data:byte(index+1,index+2)
	if tm[h*256+l]~= nil then
		if tm[h*256+l]==dir then return false end
	end
	--can we move onto a new tile?
	index=math.floor(y2/tileSize)*self.w*2+math.floor(x2/tileSize)*2
	l,h=self.data:byte(index+1,index+2)
	return tf[h*256+l]
	-- if can==true then
		-- if self.static[self:xyToTileIndex(x2,y2)]~=nil then
			-- self.static[self:xyToTileIndex(x2,y2)](self)
		-- end
	-- end
	-- return can
end

function Environment:set(obj,x,y)
	local i,j,l,h=0,y*self.w*2+x*2+2,obj%256,obj/256
	--print("node set",j,"at",x,y,l,h)
	self.data=self.data:gsub("..", function(c) i=i+2; if i==j then return string.char(l,h) end end)
end

function Environment:addStaticEvent(i,j,e)
	self.static[j*self.w+i]=e
end

function Environment:removeStaticEvent(i,j)
	self.static[j*self.w+i]=nil
end

--current world
Environment.currentWorld("terra.lua")

--current world view offset
viewx,viewy=0,0

--dbg
globalTime,renderTime=0,0

--characters
Character= {}
Character.__index=Character

function createCharacter(cx,cy,image)
	return setmetatable({x=cx,y=cy,frame=1,dir=0,img=image,hp=75},Character)
end

function drawCharacter(char)
	char.img:safeDraw(char.x-viewx,char.y-viewy-4,char.frame*tileSize,char.dir*tileSize,tileSize,tileSize)
end

function Character:die()
	if self.onDeath~=nil then
		self.onDeath()
	else
		--todo
		print("enemy dead")
	end
end

function Character:changeHp(diff)
	self.hp=self.hp+diff
	if self.hp<=0 then
		self:die()
	elseif self.hp>100 then
		self.hp=100
	end
end

hero = createCharacter(tileSize*4,tileSize*2,image.load("gfx/monsters/s.png"))

function hero.onDeath()
	showDeathScreen()
	print("you died!")
end

enemy= createCharacter(240,96,image.load("gfx/npc2.png"))

popup(hero,"hi")

function moveCharacter(char,x,y)
	if not world:canMove(char.x,char.y,char.dir,char.x+x,char.y+y) then hero:changeHp(-5);popup(char,"Can't go there!");return end
	--print("move character "..char.x..","..char.y)
	redraw(3)
	local dx,dy=x/3,y/3
	char.frame=0
	char.x=char.x+dx
	char.y=char.y+dy
	viewx=viewx+dx
	viewy=viewy+dy
	update()
	char.frame=0
	char.x=char.x+dx
	char.y=char.y+dy
	viewx=viewx+dx
	viewy=viewy+dy
	update()
	char.frame=1
	char.x=char.x+dx
	char.y=char.y+dy
	viewx=viewx+dx
	viewy=viewy+dy
	update()
	print(" done"..char.x..","..char.y)
end



grassImg=image.load("gfx/tileset.png");
houseImg=image.load("gfx/houses/house1.png");
trImg=image.load("gfx/tree.png");

--tiles tables
td={ [0]=function(x,y)  end }
tf={ [0]=true } --available to stand?
tm={ } --movement restrictions

function tiledImage(img,imgs,index)
	local x,y,w,h,r=0,0,img:width(),img:height(),""	
	while y<h do
		x=0
		while x<w do
			r=r.."td["..index.."]=function(x,y) "..imgs..":safeDraw(x,y,"..x..","..y..",tileSize,tileSize) end;"
			x=x+tileSize
			index=index+1
		end
		y=y+tileSize
	end
	return r
end

fenceTiles=image.load("gfx/fence.png")
loadstring(tiledImage(fenceTiles,"fenceTiles",10))()
tf[14],tf[15]=true,true;tm[14],tm[15]=1,2
waterTiles=image.load("gfx/water.png")
loadstring(tiledImage(waterTiles,"waterTiles",20))()

function genIsland(size)
	for i=0,size-1 do
		world:set(25,0,i)
		world:set(25,1,i)
		world:set(25,2,i)
		world:set(25,size-3,i)
		world:set(25,size-2,i)
		world:set(25,size-1,i)
	end
	for i=3,size-4 do
		world:set(25,i,0)
		world:set(25,i,size-1)
		world:set(29,i,1)
		world:set(21,i,size-2)
	end
	for i=2,size-3 do
		world:set(26,3,i)
		world:set(24,size-4,i)
	end
	--edges
	world:set(23,3,1)
	world:set(27,3,size-2)
	world:set(31,size-4,1)
	world:set(35,size-4,size-2)
end

--updates the game world
--if needed, re-renders the game
--rendered frame must be 120 ms / 40ms for idle update for better timing
function update()
	local dt=40
	if redrawCount>0 then
		local clk=os.ostime()
		---------------------------
		---- rendering ------
		world:draw()	
		drawCharacter(enemy)
		drawCharacter(hero)
		drawHud()
		screen.update()
		---------------------------
		renderTime=os.ostime()-clk
		--print("renderTime",renderTime)
		if renderTime<120 then os.wait(120-renderTime-1);dt=120
		else dt=renderTime end
		
		redrawCount=redrawCount-1
	else
		os.wait(40)
	end
	
	--update timers
	globalTime=globalTime+dt
	timer.update(dt)
end

oldOrientation=screen.orientation()
screen.orientation(0)
ScreenWidth =screen.width()
ScreenHeight=screen.height()
--main loop--	
while true do	
	--process input
	if control.read()==1 then
		if control.isTouch()==1 then
			CurX,CurY=touch.pos()
			if touch.down()==1 then
				SwipeX=CurX-(hero.x-viewx)
				SwipeY=CurY-(hero.y-viewy)
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
			SwipeX,SwipeY=0,0
			if hero.dir==0 then SwipeY=tileSize*10; elseif hero.dir==3 then SwipeY=-tileSize*10; end
			if hero.dir==2 then SwipeX=tileSize*10; elseif hero.dir==1 then SwipeX=-tileSize*10; end
			moveCharacter(hero,SwipeX,SwipeY)
			--break
		end
	end
	update()
end
-------------
screen.orientation(oldOrientation)