--tileSize
tileSize=48

--how many frames we still need to draw
redrawCount=1

function redraw()
	if redrawCount==0 then redrawCount=1 end
end

--ui + hud
dialogTextColor,dialogBackColor,dialogOutColor=color.new(255,255,255),color.new(32,32,32,200),color.new(0,0,0)
healthbarColor=color.new(232,0,0)

dialogVisible,dialogWho,dialogWhat,dialogTime,dialogDuration=false,nil,nil,0,0

function popup(who,msg)
	dialogVisible=true
	dialogWho=who
	dialogWhat=msg
	dialogTime=0
	dialogDuration=1000
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

--current world(level/room)
--x,y : view offset
world={ x=0,y=0,background=image.load("gfx/grassback.png"),prev=nil }

--dbg
globalTime,renderTime=0,0

--characters
function createCharacter(cx,cy,image)
	return {x=cx,y=cy,frame=1,dir=0,img=image,hp=75}
end

function drawCharacter(char)
	char.img:safeDraw(char.x-world.x,char.y-world.y-4,char.frame*tileSize,char.dir*tileSize,tileSize,tileSize)
end

hero = createCharacter(tileSize*4,tileSize*2,image.load("guy2.png"))
enemy= createCharacter(240,96,image.load("gfx/npc2.png"))

popup(hero,"hi")

function moveCharacter(char,x,y)
	if not node:isFree(char.x+x,char.y+y) then popup(char,"Can't go there!");return end
	--print("move character "..char.x..","..char.y)
	redrawCount=3
	local dx,dy=x/3,y/3
	char.frame=2
	char.x=char.x+dx
	char.y=char.y+dy
	world.x=world.x+dx
	world.y=world.y+dy
	update()
	char.frame=0
	char.x=char.x+dx
	char.y=char.y+dy
	world.x=world.x+dx
	world.y=world.y+dy
	update()
	char.frame=1
	char.x=char.x+dx
	char.y=char.y+dy
	world.x=world.x+dx
	world.y=world.y+dy
	update()
	--print(" done"..char.x..","..char.y)
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

function Node:isFree(x,y)
	local index=math.floor(y/tileSize)*self.size*2+math.floor(x/tileSize)*2
	l,h=self.data:byte(index+1,index+2)
	return tf[h*256+l]	
end

function Node:draw()
	--find out the visible boundaries
	local i,j       =math.floor(math.max(world.x-self.x,0)/tileSize),math.floor(math.max(world.y-self.y,0)/tileSize)
	local i2,j2,ii  =math.min(self.x2,i+9),math.min(self.y2,j+6),i
	local dx,dy = self.x-world.x,self.y-world.y
	local index,l,h
	--5 rows
	while j<j2 do
		i=ii
		index=j*self.size*2+i*2+1
		--9 columns
		while i<i2 do
			l,h=self.data:byte(index,index+1)
			td[h*256+l](i*tileSize+dx,j*tileSize+dy)
			i=i+1;index=index+2
		end
		j=j+1
	end
end

node=Node.new()

node:fill()

node:set(6,2,3)
node:set(2,3,3)
node:set(3,5,3)
node:set(1,6,3)
node:set(2,5,4)
node:set(3,6,4)
node:set(4,2,1)
node:set(4,2,2)


for i=2,5 do
	node:set(1,i,0)
end
node:set(5,2,0)
node:set(7,6,0)
node:set(8,6,1)
node:set(8,6,2)
node:set(9,6,3)

for i=0,31 do
node:set(10,6,i)
node:set(11,7,i)

end

--node:set(8,6,2)
--node:set(7,6,2)
collectgarbage() --important after node modifications!

fenceImg=image.load("fence.png");

roadImg=image.load("gfx/apple.png");
grassImg=image.load("grasspack.png");
treeImg=image.load("gfx/water.png");
grassImg=image.load("gfx/tileset.png");

--tiles tables
td={ [0]=function(x,y)  end,[1]=function(x,y) fenceImg:safeDraw(x,y,0,0,48,48) end,[2]=function(x,y) fenceImg:safeDraw(x,y,0,48,48,48)  end ,
[3]=function(x,y) fenceImg:safeDraw(x,y,0,96,48,48)  end,[4]=function(x,y) fenceImg:safeDraw(x,y,48,48,48,48) end,[5]=function(x,y) fenceImg:safeDraw(x,y,48,0,48,48) end,
[6]=function(x,y) fenceImg:safeDraw(x,y,48,96,48,48) end,[7]=function(x,y) fenceImg:safeDraw(x,y,96,0,48,48) end,[8]=function(x,y) fenceImg:safeDraw(x,y,96,48,48,48) end,
[9]=function(x,y) fenceImg:safeDraw(x,y,96,96,48,48) end,[10]=function(x,y) treeImg:safeDraw(x,y,0,48,48,48) end,[11]=function(x,y) treeImg:safeDraw(x,y,96,48,48,48) end
}
tf={ [0]=true,[1]=false,[2]=true ,[4]=true}


function Redraw()
	
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
	
	bar(4,4,90,10,hero.hp/100,healthbarColor)
	
	--print(renderTime,gcinfo())
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
	if dialogVisible==true then
		dialogTime=dialogTime+dt
		--print(dialogTime)
		if dialogTime>=dialogDuration then dialogVisible=false;redraw() end
	end
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
			break
		end
	end
	update()
end
-------------
screen.orientation(oldOrientation)