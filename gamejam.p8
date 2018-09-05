pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

function _init()
	star_list={}
	for i=1,150 do
		star_list[i]={}
		star_list[i].x=rnd(508)
		star_list[i].y=rnd(55)
	end

    map_size = 16
    horizon_height = 32
    game_over=false
    turns=0
    player:init()
end

function _update()
    player:input()
end

function draw_stars()
	for i=1,#star_list do
		pset((-player.d*0.03*508+star_list[i].x),star_list[i].y,15)
	end
end

function draw_3d()
    local fov = 0.1
    local v={}
    v.x0 = cos(player.d+fov)
    v.y0 = sin(player.d+fov)
    v.x1 = cos(player.d-fov)
    v.y1 = sin(player.d-fov)

    for screenx=0,127 do
        if screenx==64 then
            printh("DRAWING")
        end
        local screeny=127
        local x=player.x
        local y=player.y
        local z=player.z
        player:set_selected_tile()

        local ix=flr(x)
        local iy=flr(y)

        local distance_from_player=0
        local current_height = get_height(ix,iy)
        local current_ground_color = get_color(ix,iy)

        local percent=screenx/127
        local vecx = v.x0 * (1-percent) + v.x1 * percent
        local vecy = v.y0 * (1-percent) + v.y1 * percent
        local dirx = sgn(vecx)
        local diry = sgn(vecy)

        local skip_x = 1/abs(vecx)
        local skip_y = 1/abs(vecy)

        local dist_x
        local dist_y
        if (sgn(vecx) > 0) then
            dist_x = 1-(x%1) else
            dist_x =   (x%1) end
        if (sgn(vecy) > 0) then
            dist_y = 1-(y%1) else
            dist_y =   (y%1) end

        dist_x = dist_x * skip_x
        dist_y = dist_y * skip_y

        local skip = true
        local skips = 0

        while (skip) do
            skips = skips + 1
            if (dist_x < dist_y) then
                ix = ix+dirx
                dist_y = dist_y - dist_x
                distance_from_player = distance_from_player + dist_x
                dist_x = skip_x
            else
                iy = iy+diry
                dist_x = dist_x - dist_y
                distance_from_player = distance_from_player + dist_y
                dist_y = skip_y
            end

            -- prev height properties
            local previous_height = current_height
            current_height = get_height(ix, iy)

            local previous_ground_color = current_ground_color
            current_ground_color = get_color(ix,iy)

            if screenx==64 then
                printh("skip:"..skips.." mget:"..mget(ix,iy))
            end

            if current_height == -1 then skip=false end

            if (distance_from_player > 0.5) then
                local screeny1 = 5
                screeny1 = (screeny1 * map_size)/distance_from_player
                screeny1 = screeny1 + horizon_height --horizon

                -- local screeny1 = 64-distance_from_player
                --draw ground to new point
                if previous_ground_color then
                    printh("drawing color "..previous_ground_color.." from "..screenx..","..(screeny1-1).." to "..screenx..","..screeny)
                    line(
                    screenx,screeny1-1, 
                    screenx,screeny, 
                    previous_ground_color)
                end
                screeny=screeny1
            end
        end -- while (skip) do
    end -- for screenx etc
end

ground_colors={}
ground_colors[1]=15 -- barren land
ground_colors[2]=4 -- fertile land
ground_colors[3]=12 -- water
ground_colors[4]=5 -- stone



function get_height(celx, cely)
    local tile = mget(celx,cely)
    if (not tile) or (tile == 0) then
        return -1
    end
    return 0
end

function get_color(celx,cely)
    if player.selected_tile_x==celx and player.selected_tile_y==cely then
        return 8
    end
    local tile = mget(celx,cely)
    return ground_colors[tile]
end

function _draw()
    cls()
    rectfill(0,0,127,127,1)
    draw_stars()
    draw_3d()
    if draw_map then
        map(0,0, 0,0, 16,16)
       -- player:draw_on_map()
       pset(player.x*8,player.y*8,12)
       pset(player.x*8+cos(player.d)*2,player.y*8+sin(player.d)*2,13)
    end
end

player={}

function player:init()
    self.x=3
    self.y=3
    self.z=0
    self.d=0.5
    self.speed=0.05

    self:set_selected_tile()
end

function player:set_selected_tile()
    self.selected_tile_x=flr(self.x + cos(self.d))
    self.selected_tile_y=flr(self.y + sin(self.d))
end

function player:draw_on_map()
    --circfill(self.x + 3,self.y + 3, 4, 10)
    circfill(self.x,self.y,2,10)
end

function player:input()
    if (btn(0)) then player.d=(player.d+0.02)%1 end
    if (btn(1)) then player.d=(player.d+0.98)%1 end

    if (btn(2) or btn(3)) then
        if (btn(2)) then m=self.speed else m=-self.speed end
        local dx = cos(player.d)*m
        local dy = sin(player.d)*m
        player.x=player.x+cos(player.d)*m
        player.y=player.y+sin(player.d)*m
    end
end

draw_map=false
menuitem(1,"draw map",function() draw_map = not draw_map end)

__gfx__
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101030101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202010103030301010201010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103030301010201010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103030301010201010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103030301010202010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010102010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010101010101010102010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101020101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010103030301010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
