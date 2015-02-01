local movePath = {}
movePath[1] = { x=200, y=0 }
movePath[2] = { x=200, y=200 }
movePath[3] = { x=0, y=200, time=500 }
movePath[4] = { x=200, y=300, time=500 }
movePath[5] = { x=150, y=200, time=250 }
movePath[6] = { x=200, y=100, time=2000 }
movePath[7] = { x=100, y=200, time=500 }
movePath[8] = { x=0, y=0, time=500, easingMethod=easing.outQuad }

local function distBetween( x1, y1, x2, y2 )
	local xFactor = x2 - x1
	local yFactor = y2 - y1
	local dist = math.sqrt((xFactor*xFactor) + (yFactor*yFactor))
	return dist
end

local circle1 = display.newCircle( 60, 100, 15 )
circle1:setFillColor( 1, 0, 0.4 )
local circle2 = display.newCircle( 120, 100, 15 )
circle2:setFillColor( 1, 0.8, 0.4 )

local function setPath( object, path, params )

	local delta = params.useDelta or nil
	local deltaX = 0
	local deltaY = 0
	local constant = params.constantTime or nil
	local ease = params.easingMethod or easing.linear
	local tag = params.tag or nil
	local delay = params.delay or 0
	local speedFactor = 1

	if ( delta and delta == true ) then
		deltaX = object.x
		deltaY = object.y
	end

	if ( constant ) then
		local dist = distBetween( object.x, object.y, deltaX+path[1].x, deltaY+path[1].y )
		speedFactor = constant/dist
	end

	for i = 1,#path do

		local segmentTime = 500

		--if "constant" is defined, refactor transition time based on distance between points
		if ( constant ) then
			local dist
			if ( i == 1 ) then
				dist = distBetween( object.x, object.y, deltaX+path[i].x, deltaY+path[i].y )
			else
				dist = distBetween( path[i-1].x, path[i-1].y, path[i].x, path[i].y )
			end
			segmentTime = dist*speedFactor
		else
			--if this path segment has a custom time, use it
			if ( path[i].time ) then segmentTime = path[i].time end
		end

		--if this segment has custom easing, override the default method (if any)
		if ( path[i].easingMethod ) then ease = path[i].easingMethod end

		transition.to( object, { tag=tag, time=segmentTime, x=deltaX+path[i].x, y=deltaY+path[i].y, delay=delay, transition=ease } )
		delay = delay + segmentTime
	end
end

setPath( circle1, movePath, { useDelta=true, constantTime=1200, easingMethod=easing.inOutQuad, delay=200, tag="moveObject" } )
setPath( circle2, movePath, { useDelta=true, constantTime=1200, easingMethod=easing.inOutQuad, tag="moveObject" } )

local function cancelAll()
	transition.cancel( "moveObject" )
end
--timer.performWithDelay( 2800, cancelAll )




display.setStatusBar( display.HiddenStatusBar )

local segMents = {};
local coordsTable = {}
local endCaps = {};
local tempCaps = {};
local tempBG = {};
local handleDot = {};

local FALSE = 0;
local TRUE  = 1;
local moved = FALSE;
local numPoints = 0
local numPathPoints = 200
local gSegments;

local PIE = 3.14159265358

local bbg = nil;




local mainGroup = display.newGroup()
local textGroup = display.newGroup()

local numHandlePoints = 0
local visualHandlePoints = {}
local visualHandleLines = {}
local instructionText

local visualBezierLine



----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------
		
local function destroyBezierSegment()	

	segMents = nil;
	segMents = {};
	handleDot = nil
	handleDot = {};
end

----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function drawBezierSegment( granularity, r, g, b )

	if ( visualBezierLine ) then display.remove( visualBezierLine ) end

	local ct = coordsTable
	visualBezierLine = display.newLine( ct[1].x, ct[1].y, ct[2].x, ct[2].y )
	for i = 3,granularity do visualBezierLine:append( ct[i].x, ct[i].y ) end
	visualBezierLine:setStrokeColor( 1 )
	visualBezierLine.strokeWidth = 1
	ct = nil
end


----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function setupBezierSegment(granularity)
	
	local inc = (1.0 / granularity)

	for i = 1,#visualHandlePoints,4 do

	local t = 0;
	local t1 = 0;
	local i = 1;

	for j = 1,granularity do

			t1 = 1.0 - t;
	
			local t1_3 = t1*t1*t1
			local t1_3a = (3*t)*(t1*t1)
			local t1_3b = (3*(t*t))*t1;
			local t1_3c = (t * t * t )
	
			local p1 = visualHandlePoints[i];
			local p2 = visualHandlePoints[i+1];
			local p3 = visualHandlePoints[i+2];
			local p4 = visualHandlePoints[i+3];
	
			local 	x = t1_3  * p1.x;
			x = 	x + t1_3a * p2.x;
			x = 	x + t1_3b * p3.x;
			x =		x + t1_3c * p4.x

			local 	y = t1_3  * p1.y;
			y = 	y + t1_3a * p2.y;
			y = 	y + t1_3b * p3.y;
			y =		y + t1_3c * p4.y;

			coordsTable[j].x = x;
			coordsTable[j].y = y;
			t = t + inc;

		end
	end
end 
----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function drawBezierHandles()

	if ( gSegments ) then
		gSegments:removeSelf()
	end

	gSegments = display.newGroup()
	
	for i = 1,#endCaps,2 do 
		local line = display.newLine(endCaps[i].x,endCaps[i].y,endCaps[i+1].x,endCaps[i+1].y);
		line:setStrokeColor(128,128,128);
		line.strokeWidth=1;
		gSegments:insert( line )
		table.insert(segMents,line);
	end 
	
end


----------------------------------------------------------------------------------------
-- 
--  moveAlongThesegment self explanatory  
--
--
----------------------------------------------------------------------------------------

local prevX = 1;
local prevY = 1;
local prevAngle = 1;
local bFirst = true;
local plane = nil;
	
	
local function moveAlongThesegment( inc )

	
	if  (bFirst == true )  then 
		plane = display.newImage("f15.png",-100,-100);
		prevX = coordsTable[1].x;
		prevY = coordsTable[1].y;
		bFirst = false;
		return;
	end 
	
	local p = {};
	
	p.x = coordsTable[inc].x;
	p.y = coordsTable[inc].y;
		
	local angle = math.atan2( p.y - prevY, p.x - prevX)
	angle = angle * 180 / PIE

	plane.x = p.x;
	plane.y = p.y;

	plane:rotate(angle-prevAngle);
		
			
	prevAngle = angle;
		
	prevY = p.y;
	prevX = p.x;
	
end 

----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function setupBezier( granularity ,r,g,b)

	-- 1st draw anchor points and handles 
	drawBezierHandles();
	
	-- 2nd setupBezierSegment
	setupBezierSegment(numPathPoints)

	-- 3rd draw the segment 
	drawBezierSegment(numPathPoints,r,g,b);
	
	-- 4th destroy the segment
	destroyBezierSegment();
	
	
end
----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local pointInc = 2;
local function draw (event )
	if ( moved == TRUE ) then	
		setupBezier(50,128,128,128)
		pointInc = 2;
		bFirst = false;
		return true;
	elseif (moved == FALSE  ) then 
		if ( pointInc < #coordsTable ) then 
			moveAlongThesegment(pointInc);
			pointInc = pointInc + 1;
		end 
	end 
end

----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function dragHandles( event )

	local t = event.target

	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		local parent = t.parent
		parent:insert( t )
		display.getCurrentStage():setFocus( t )

		t.isFocus = true

		t.x0 = event.x - t.x
		t.y0 = event.y - t.y

		elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			t.x = event.x - t.x0
			t.y = event.y - t.y0
			
			moved = TRUE;
			
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
			moved = FALSE;
			setupBezier(100,255,128,0);
		end
	end

	return true
	
end

----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function addListeners()

	for i = 1,#visualHandlePoints do
		visualHandlePoints[i]:addEventListener( "touch", dragHandles )
	end
end

----------------------------------------------------------------------------------------
-- 
-- 
----------------------------------------------------------------------------------------

local function addPoints ( event )
	
	numPoints = numPoints + 1

	if ( numPoints <= 4) then
	
	 local point = {}
	 point.x = event.x;
	 point.y = event.y;
	 
	 local c = display.newCircle(point.x, point.y,10);
	 c:setFillColor(255,0,0);
	 table.insert (endCaps,c);

	end 
	
	if (numPoints == 4 ) then 
		Runtime:removeEventListener("tap",addPoints)
		addListeners()
		setupBezier(100,255,128,0);
		Runtime:addEventListener("enterFrame",draw);
	end
end










local function drawHandles( event )

	local function drawCircle( x, y )
		numHandlePoints = numHandlePoints+1
		local point = display.newCircle( x, y, 5 )
		visualHandlePoints[#visualHandlePoints+1] = point
		if ( #visualHandlePoints == 1 or #visualHandlePoints == 3 ) then point:setFillColor( 1, 0, 0.4 )
		else point:setFillColor( 1, 0.8, 0.4 ) end
		point = nil
	end
	
	local function drawLine( handle, startX, startY, endX, endY )
		if ( visualHandleLines[handle] ) then display.remove(visualHandleLines[handle]) end
		local line = display.newLine( startX, startY, endX, endY )
		line:toBack() ; line:setStrokeColor( 0.4 ) ; line.strokeWidth = 2
		visualHandleLines[handle] = line
		line = nil
	end

	if ( event.phase == "began" ) then

		if ( numHandlePoints < 4 ) then drawCircle( event.x, event.y ) end

	elseif ( event.phase == "moved" ) then

		if ( numHandlePoints == 1 or numHandlePoints == 3 ) then
			drawCircle( event.x, event.y )
			if ( numHandlePoints == 1 ) then
				drawLine( 1, visualHandlePoints[1].x, visualHandlePoints[1].y, event.x, event.y )
			elseif ( numHandlePoints == 3 ) then
				drawLine( 2, visualHandlePoints[3].x, visualHandlePoints[3].y, event.x, event.y )
			end

		elseif ( numHandlePoints == 2 or numHandlePoints == 4 ) then
			visualHandlePoints[numHandlePoints].x = event.x
			visualHandlePoints[numHandlePoints].y = event.y
			if ( numHandlePoints == 2 ) then
				drawLine( 1, visualHandlePoints[1].x, visualHandlePoints[1].y, event.x, event.y )
			elseif ( numHandlePoints == 4 ) then
				drawLine( 2, visualHandlePoints[3].x, visualHandlePoints[3].y, event.x, event.y )
				
				setupBezier(100,255,128,0)
			end
		end
		
	elseif ( event.phase == "ended" ) then
	
		if ( numHandlePoints == 2 ) then
			if ( instructionText.trans ) then transition.cancel( instructionText.trans ) ; instructionText.trans = nil end
			instructionText.trans = transition.to( instructionText, { time=500*instructionText.alpha, alpha=0,
				onComplete=function()
					transition.cancel( instructionText.trans )
					instructionText.text = "Click and drag end point"
					instructionText.trans = transition.to( instructionText, { time=500, delay=150, alpha=1 } )
				end
			} )
		elseif ( numHandlePoints == 4 ) then
			Runtime:removeEventListener( "touch", drawHandles )
			addListeners()
		end
	end
end



local function start()

	numHandlePoints = 0
	for i=#visualHandlePoints,1,-1 do display.remove( visualHandlePoints[i] ) ; visualHandlePoints[i] = nil end
	for j=#visualHandleLines,1,-1 do display.remove( visualHandleLines[j] ) ; visualHandleLines[j] = nil end

	instructionText = display.newText( textGroup, "Click and drag handle 1", display.contentCenterX, 30, "HelveticaNeue-UltraLight", 20 )
	instructionText.alpha = 0 ; instructionText.trans = transition.to( instructionText, { time=500, delay=150, alpha=1 } )

	local ct = coordsTable
	for j = 1,numPathPoints do ct[j] = { x=0, y=0 } end

	--Runtime:addEventListener( "tap", addPoints )
	Runtime:addEventListener( "touch", drawHandles )
end


start()
