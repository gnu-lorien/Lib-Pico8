-- will contain functions for
-- various forms of pathfinding,
-- such as distance-based (see
-- distance.lua), and A*

-- for now it's only breath-first path finding

-- Contributors: sulai

---
-- Breadth-first path finding.
-- Example usage
-- targets = find_path_breadth(startx, starty, 10,
-- 				function(cx,cy)
--                  -- make the path finder step on tiles with index>16 only
--					return mget(cx,cy)>16
--				end,
--				function(tx,ty)
--					-- accept tile index 20 as targets
--					return mget(tx,ty)==20
-- 				end)
-- -- now use the result of the path finding
-- for t in all(targets) do
-- 		mset(t.x, t.y, 0)
-- end
--
-- @param x coordinate to start path finding at
-- @param y coordinate to start path finding at
-- @param limit stop if this amount of targets were found
-- @param accept_child  callback method (x,y), return true if you accept this child
-- @param accept_target callback method (x,y), return true if you accept this as target
-- @return a table of coordinates matching what ever is defined in the callbacks.
-- The result might look something like this
-- {{x=...,y=...},...}
function find_path_breadth(x, y, limit, accept_child, accept_target)

	local targets = {} -- list od coordinates {x}{y} as result of this function
	local visited = {}

	local stack = {}
	local read = 0
	local write = 0
	write=write + 1  stack[write] = {x,y} -- push
	visited[x..","..y] = true
	local dir={{x=-1,y=0},{x=1,y=0},{x=0,y=-1},{x=0,y=1} }

	while write > read do

		-- pull currently visited node
		read=read + 1  local coord = stack[read]  -- pull
		local vx = coord[1]
		local vy = coord[2]

		-- position matching all criteria?
		if accept_target(vx,vy) then
			add(targets,{x=vx, y=vy })
			if #targets==limit then
				return targets
			end
		end

		-- go visit neighboars
		for d in all(dir) do

			-- child position
			local cx = (vx+d.x)%48 -- map wrap
			local cy = (vy+d.y)%48
			if not visited[cx..","..cy] then
				visited[cx..","..cy]=true
				if accept_child(cx,cy) then
					write=write + 1  stack[write] = { cx, cy } -- push
				end
			end
		end
	end

	return targets
end

-- @param x coordinate to start path finding at
-- @param y coordinate to start path finding at
-- @param tx x coordinate of the path target
-- @param ty y coordinate of the path target
-- @param accept_child  callback method (x,y), return true if you accept this child
-- @param no_path_func  callback method (path), return the starting pv when we fail to find one for target
-- @return a table of coordinates matching what ever is defined in the callbacks.
-- The result might look something like this
-- {{x=...,y=...},...}
function find_shortest_path_breadth(x, y, tx, ty, accept_child, no_path_func)

	local visited = {}
	local path = {}

	local queue = {}
	local read = 0
	local write = 0
	write=write + 1  queue[write] = {x,y,0} -- push
	visited[x..","..y] = true
	path[x..","..y] = {to=nil, cost=0}
	local dir={{x=-1,y=0},{x=1,y=0},{x=0,y=-1},{x=0,y=1} }

	-- build table of path costs
	while write > read do

		-- pull currently visited node
		read=read + 1  local coord = queue[read]  -- pull
		local vx = coord[1]
		local vy = coord[2]
		local newcost = coord[3] + 1

		-- go visit neighboars
		for d in all(dir) do

			-- child position
			local cx = (vx+d.x)%48 -- map wrap
			local cy = (vy+d.y)%48
			if visited[cx..","..cy] == nil then
				visited[cx..","..cy] = true
				if accept_child(cx,cy) then
					path[cx..","..cy] = {to={x=vx, y=vy}, cost=newcost}
					if cx == tx and cy == ty then
						read = write + 1
					else
						write=write + 1  queue[write] = { cx, cy, newcost } -- push
					end
				else
				end
			end
		end
	end

	-- build reverse path
	local reversed = {{x=tx, y=ty}}
	local pv = path[tx..","..ty]
	if pv == nil then
		if no_path_func != nil then
			pv = no_path_func(path)
			if pv == nil then
				return nil
			end
			reversed = {}
		else
			return nil
		end
	end
	while true do
		if pv.to == nil then
			break
		end
		if pv.to.x == x and pv.to.y == y then
			break
		end
		add(reversed, pv.to)
		pv = path[e]
		if pv == nil then
			break
		end
	end

	-- return forward path
	for i=1,#reversed\2 do
		reversed[i],reversed[#reversed-i+1]=reversed[#reversed-i+1],reversed[i]
	end
	return reversed
end

-- @param x coordinate to start path finding at
-- @param y coordinate to start path finding at
-- @param limit stop once we've checked up to this distance
-- @param accept_child  callback method (x,y), return true if you accept this child
-- @param accept_target callback method (x,y), return true if you accept this as target
-- @return a table of paths to accepted targets
function find_targets_breadth(x, y, limit, accept_child, accept_target)

	local visited = {}
	local path = {}
	local targets = {}

	local queue = {}
	local read = 0
	local write = 0
	write=write + 1  queue[write] = {x,y,0} -- push
	visited[x..","..y] = true
	path[x..","..y] = {to=nil, cost=0}
	local dir={{x=-1,y=0},{x=1,y=0},{x=0,y=-1},{x=0,y=1} }

	-- build table of path costs
	while write > read do

		-- pull currently visited node
		read=read + 1  local coord = queue[read]  -- pull
		local vx = coord[1]
		local vy = coord[2]
		local newcost = coord[3] + 1

		-- position matching all criteria?
		if accept_target(vx,vy) then
			add(targets,{x=vx, y=vy })
		end

		-- go visit neighboars
		for d in all(dir) do

			-- child position
			local cx = (vx+d.x)%48 -- map wrap
			local cy = (vy+d.y)%48
			if visited[cx..","..cy] == nil then
				visited[cx..","..cy] = true
				if accept_child(cx,cy) then
					path[cx..","..cy] = {to={x=vx, y=vy}, cost=newcost}
					if newcost <= limit then
						write=write + 1  queue[write] = { cx, cy, newcost } -- push
					end
				end
			end
		end
	end

	for target in all(targets) do
		local tx, ty = target.x, target.y
	end

	local targets_with_paths = {}
	for target in all(targets) do
		-- build reverse path
		local tx, ty = target.x, target.y
		local reversed = {{x=tx, y=ty}}
		local pv = path[tx..","..ty]
		if pv.to != nil then
			while true do
				if pv.to.x == x and pv.to.y == y then
					break
				end
				add(reversed, pv.to)
				pv = path[pv.to.x..","..pv.to.y]
			end

			-- return forward path
			for i=1,#reversed\2 do
				reversed[i],reversed[#reversed-i+1]=reversed[#reversed-i+1],reversed[i]
			end
			targets_with_paths[target] = reversed
		end
	end
	return targets_with_paths
end
