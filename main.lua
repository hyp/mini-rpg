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
dialogTextColor,dialogBackColor,dialogOutColor=color.new(255,255,255),color.new(32,32,32,200),color.new(0,0,0)
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

function showLoadingScreen()
	screen.fillrect(0,0,0,0,dialogOutColor)
	text.size(22)
	text.color(dialogTextColor)
	text.draw(0,ScreenHeight/2-11,"Loading...","center",ScreenWidth)
	screen.update()
end

--world is a level/area in game
Environment = {}
Environment.__index=Environment

--sets current world
function Environment.currentWorld(w)
	--clear up prev world
	if world~=nil then
		world:clear()
		world=nil
		--collectgarbage()
	end
	world=w
	--load new world
	world:load()
end

function Environment:load()
	self.backgroundImg=image.load(self.background) --??
end

function Environment:clear()
	
end

function Environment:draw()
	self[0]:draw(viewx,viewy,self.backgroundImg) --1st node
end

function Environment:canMove(x,y,dir,x2,y2)
	return self[0]:canMove(x,y,dir,x2,y2)
end



--current world
world = setmetatable({ background="grass.png",w=1,h=1 },Environment)
Environment.currentWorld(world)

--current world view offset
viewx,viewy=0,0

--dbg
globalTime,renderTime=0,0

--characters
function createCharacter(cx,cy,image)
	return {x=cx,y=cy,frame=1,dir=0,img=image,hp=75}
end

function drawCharacter(char)
	char.img:safeDraw(char.x-viewx,char.y-viewy-4,char.frame*tileSize,char.dir*tileSize,tileSize,tileSize)
end

hero = createCharacter(tileSize*4,tileSize*2,image.load("gfx/monsters/s.png"))
enemy= createCharacter(240,96,image.load("gfx/npc2.png"))

popup(hero,"hi")

function moveCharacter(char,x,y)
	if not world:canMove(char.x,char.y,char.dir,char.x+x,char.y+y) then hero.hp=hero.hp-5;popup(char,"Can't go there!");return end
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
	--print(" done"..char.x..","..char.y)
end



-- node is a 32x32 array of tiles stored as 2 bytes each representing an index of tile from globalt tile table
Node = { }
Node.__index=Node

function Node.new()
	return setmetatable({ x=0,y=0,size=32,msize=64 },Node)
end

function Node:fill()
	self.data=string.rep('\000',self.size*self.size*2)
	print("filling node ",self.data:len())
end

function Node:load(file)
	self.data=io.read(self.size*self.size*2)
	print("node loaded!")
end

function Node:set(obj,x,y)
	local i,j,l,h=0,y*self.size*2+x*2+2,obj%256,obj/256
	--print("node set",j,"at",x,y,l,h)
	self.data=self.data:gsub("..", function(c) i=i+2; if i==j then return string.char(l,h) end end)
end

function Node:dump()
	for c in self.data:gmatch("..........") do
		print(c:byte(1),c:byte(2),c:byte(3),c:byte(4),c:byte(5),c:byte(6),c:byte(7),c:byte(8))
	end
end

function Node:canMove(x,y,dir,x2,y2)
	--can we move from current tile in a given direction?
	local index=math.floor(y/tileSize)*self.size*2+math.floor(x/tileSize)*2
	local l,h=self.data:byte(index+1,index+2)
	if tm[h*256+l]~= nil then
		if tm[h*256+l]==dir then return false end
	end
	--can we move onto a new tile?
	index=math.floor(y2/tileSize)*self.size*2+math.floor(x2/tileSize)*2
	l,h=self.data:byte(index+1,index+2)
	return tf[h*256+l]	
end

-- v(x,y) = view coordinates, b = background tile
function Node:draw(vx,vy,b)
	--find out the i and j indeces for the first visible tile
	local i,j       =math.floor(math.max(vx-self.x,0)/tileSize),math.floor(math.max(vy-self.y,0)/tileSize)
	--from i and j calculate the flat index of the first visible tile
	local ix1=j*self.size*2+i*2+1
	--calculate the position of first tile in screen coordinates
	local x1,y=i*tileSize+(self.x-vx),j*tileSize+self.y-vy
	--find out the visible boundaries
	local xm,ym=math.min(self.size,i+9)*tileSize+(self.x-vx),math.min(self.size,j+6)*tileSize+(self.y-vy)
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
		ix1=ix1+self.size*2 --next row index
	end
end

node=Node.new()

world[0]=node --our world is just 1 node

node:fill()

node:set(6,2,3)
node:set(2,3,3)
node:set(3,5,3)
node:set(1,6,3)
node:set(2,5,4)
node:set(3,6,4)
node:set(4,2,1)
node:set(4,2,2)


for i=0,31 do
	node:set(1,i,0)
	--node:set(1,i,31)
	--node:set(1,31,i)
end
node:set(5,2,0)
node:set(7,6,0)
node:set(8,6,1)
node:set(8,6,2)
node:set(9,6,3)
node:set(12,3,7)
for i=0,29 do
node:set(10,7,i)
node:set(11,8,i)

end

--node:set(8,6,2)
--node:set(7,6,2)
collectgarbage() --important after node modifications!

fenceImg=image.load("fence.png");

roadImg=image.load("gfx/apple.png");
grassImg=image.load("grasspack.png");
treeImg=image.load("gfx/water.png");
grassImg=image.load("gfx/tileset.png");
houseImg=image.load("gfx/houses/house1.png");
trImg=image.load("gfx/tree.png");

--tiles tables
td={ [0]=function(x,y)  end,[1]=function(x,y) fenceImg:safeDraw(x,y,0,0,48,48) end,[2]=function(x,y) fenceImg:safeDraw(x,y,0,48,48,48)  end ,
[3]=function(x,y) fenceImg:safeDraw(x,y,0,96,48,48)  end,[4]=function(x,y) fenceImg:safeDraw(x,y,48,48,48,48) end,[5]=function(x,y) fenceImg:safeDraw(x,y,48,0,48,48) end,
[6]=function(x,y) fenceImg:safeDraw(x,y,48,96,48,48) end,[7]=function(x,y) fenceImg:safeDraw(x,y,96,0,48,48) end,[8]=function(x,y) fenceImg:safeDraw(x,y,96,48,48,48) end,
[9]=function(x,y) fenceImg:safeDraw(x,y,96,96,48,48) end,[10]=function(x,y) treeImg:safeDraw(x,y,0,48,48,48) end,[11]=function(x,y) treeImg:safeDraw(x,y,96,48,48,48) end,
[12]=function(x,y) treeImg:safeDraw(x,y,144,0,48,48);treeImg:safeDraw(x+48,y,48,96,48,48);treeImg:safeDraw(x,y+48,96,48,48,48);treeImg:safeDraw(x,y+96,144,48,48,48);treeImg:safeDraw(x+48,y+96,48,0,48,48);treeImg:safeDraw(x+96,y+96,144,144,48,48);treeImg:safeDraw(x+96,y+48,0,48,48,48);treeImg:safeDraw(x+144,y+48,96,48,48,48);treeImg:safeDraw(x+96,y,144,96,48,48); end
}
tf={ [0]=true,[4]=true,[8]=true} --available to stand?
tm={ [4]=1,[8]=2 }

td[13]=function(x,y) houseImg:safeDraw(x,y,0,0,48,48);houseImg:safeDraw(x+48,y,0,48,48,48) end
node:set(13,3,6)
td[14]=function(x,y) trImg:safeDraw(x,y,0,0,48,48); end
td[15]=function(x,y) trImg:safeDraw(x,y,0,48,48,48); end
node:set(14,5,6)
node:set(15,5,7)

function Redraw()
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

	world:draw()
	
		
	drawCharacter(enemy)
	drawCharacter(hero)
	

	
	drawBar(4,4,90,10,hero.hp/100,healthbarColor)
	
	--dbg
	text.size(15)
	text.color(dialogTextColor)
	text.draw(0,16,renderTime..','..globalTime)
	text.draw(0,32,gcinfo())
	
	if dialogVisible then dialogDraw() end

	screen.update()
end
	
function osms() 
	return os.ostime() --return os.clock()*1000
end

--updates the game world
--if needed, re-renders the game
--rendered frame must be 120 ms / 30ms for idle update for better timing
function update()
	local dt=30
	if redrawCount>0 then
		local clk=osms()
		---------------------------
		---- world rendering ------
		Redraw()
		---------------------------
		renderTime=osms()-clk
		--print("renderTime",renderTime)
		if renderTime<120 then os.wait(120-renderTime-1);dt=120
		else dt=renderTime end
		
		redrawCount=redrawCount-1
	else
		os.wait(30)
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
			break
		end
	end
	update()
end
-------------
screen.orientation(oldOrientation)