pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

sprite_defs={}
sprite_defs[1]={40,0,16,16} -- corn
sprite_defs[2]={56,0,16,16} -- berry
sprite_defs[3]={72,0,16,16} -- carrot
sprite_defs[4]={88,0,16,16} -- potato

corn_sprite=1
strawberry_sprite=2
carrot_sprite=3
potato_sprite=4

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
    sprite_counter=0
    sprite_map={}
    player:init()
    add_sprite(5,5,corn_sprite)
end

function _update()
    player:input()
    if player.moving then
        player:move()
    end
end

function draw_stars()
	for i=1,#star_list do
		pset((-player.d*0.03*508+star_list[i].x),star_list[i].y,7)
	end
end

function draw_3d()
    local fov = 0.1
    local v={}
    local objects_seen={}
    v.x0 = cos(player.d+fov)
    v.y0 = sin(player.d+fov)
    v.x1 = cos(player.d-fov)
    v.y1 = sin(player.d-fov)

    for screenx=0,127 do
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

        local edge_x,edge_y
        
        if dirx > 0 then
            edge_x = 1-(x%1) 
        else
            edge_x = (x%1) 
        end
        if diry > 0 then
            edge_y = 1-(y%1) 
        else
            edge_y = (y%1) 
        end

        dist_x = edge_x * skip_x
        dist_y = edge_y * skip_y

        local casting = true
        local is_active_tile
        local offset

        while (casting) do
            if (dist_x < dist_y) then
                ix = ix+dirx
                dist_y = dist_y - dist_x
                distance_from_player = distance_from_player + dist_x
                dist_x = skip_x
                offset=dist_y%1
            else
                iy = iy+diry
                dist_x = dist_x - dist_y
                distance_from_player = distance_from_player + dist_y
                dist_y = skip_y
                offset=dist_x%1
            end

            local seen_sprite = get_sprite(ix,iy)
            if seen_sprite and not objects_seen[seen_sprite.id] then
                printh(offset)
                objects_seen[seen_sprite.id]={
                    screenx=screenx,
                    ix=ix,
                    iy=iy,
                    sprite=seen_sprite,
                    offset=offset
                }
            end
            -- drawing each ground tile in the current column
            if (distance_from_player > 0.1) then
                local screeny1 = 5
                screeny1 = (screeny1 * map_size)/distance_from_player
                screeny1 = screeny1 + horizon_height --horizon

                -- draw line for current ground color
                line(screenx,screeny1-1, 
                     screenx,screeny, 
                     current_ground_color)

                -- if active, draw border color on line ends
                if is_active_tile then
                    local border_color = current_ground_color==12 and 8 or 11
                    pset(screenx,screeny1+2,border_color)
                    pset(screenx,screeny-2,border_color)
                end

                -- increment screeny for the next pass
                screeny=screeny1
            end

            current_ground_color,is_active_tile=get_color(ix,iy)
            current_height = get_height(ix, iy)
            if current_height == -1 then 
                casting=false 
            end
        end -- while (skip) do
    end -- for screenx etc
    draw_objects_seen(objects_seen)
end

function add_sprite(x,y,sprite_offset)
    sprite_counter+=1
    sprite_map[x]=sprite_map[x] or {}
    sprite_map[x][y]={offset=sprite_offset,id=sprite_counter}
end

--function remove_sprite(x,y)
--    sprite_map[x][y] = {}
--    sprite_counter-=1
--end

function plant_thing(x,y)
    if sprite_map[x] and sprite_map[x][y] then return end
    add_sprite(x,y,1)
end

--function harvest_thing(x,y)
--    if not (sprite_map[x] and sprite_map[x][y]) then return end
--    remove_sprite(x,y,1)
--end

function get_sprite(x,y)
    if not sprite_map[x] then
        return
    end
    return sprite_map[x][y]
end
 
function draw_objects_seen(objects)
    for object in all(objects) do
        local dx=object.ix-player.x+.5
        local dy=object.iy-player.y+.5
        local distance=sqrt(dx^2+dy^2)
        local offset=object.offset

        local sprite = sprite_defs[object.sprite.offset]
        local height = sprite[4] * map_size / distance * .5
        local screeny = 5
        screeny = (screeny * map_size)/distance + horizon_height
        screeny-=height

        local screenx = object.screenx
        local width = (sprite[3] * map_size / distance *.5)
        sspr(
        sprite[1],sprite[2], -- sprite x y
        sprite[3],sprite[4], -- sprite w h
        screenx-offset*width,screeny, -- screen x y
        width,height -- screen w h
        )
    end
end


sprites={}

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
    local tile = mget(celx,cely)
    local is_active_tile=player.selected_tile_x==celx and player.selected_tile_y==cely
    return ground_colors[tile],is_active_tile
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
    self.moving=false
    self.moving_speed=0.1
    self.target_x=0
    self.target_y=0

    self:set_selected_tile()
end

function player:move_to(celx,cely)
    if self.moving then
        return false
    end

    if celx < 0 or celx > map_size or cely < 0 or cely > map_size then
        self.moving=false
        return false
    end

    self.target_x=celx
    self.target_y=cely
    self.moving=true
end

function player:move()
    if self.x < self.target_x then 
        self.x = min(self.x+self.moving_speed,self.target_x)
    elseif self.x > self.target_x then 
        self.x = max(self.x-self.moving_speed,self.target_x) 
    end


    if self.y < self.target_y then 
        self.y = min(self.y+self.moving_speed,self.target_y)
    elseif self.y > self.target_y then 
        self.y = max(self.y-self.moving_speed,self.target_y) 
    end

    if self.x==self.target_x and self.y==self.target_y then
        self.moving=false
    end
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
    if (btn(0)) then self.d=(self.d+0.01)%1 end
    if (btn(1)) then self.d=(self.d+0.99)%1 end

    if btnp(2) and not self.moving then
        self:move_to(self.selected_tile_x+0.5,self.selected_tile_y+0.5)
    end
    if btnp(3) and not self.moving then
        local behind_x=flr(self.x - cos(self.d))
        local behind_y=flr(self.y - sin(self.d))
        self:move_to(behind_x+0.5, behind_y+0.5)
    end

    if btnp(4) then
        plant_thing(self.selected_tile_x, self.selected_tile_y)
    end

--    if btnp(5) then
--        harvest_thing(self.selected_tile_x, self.selected_tile_y)
--    end
        
end

draw_map=false
menuitem(1,"draw map",function() draw_map = not draw_map end)

__gfx__
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000ffffffff44444444cccccccc555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700ffffffff44444444cccccccc555555550000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000ffffffff44444444cccccccc555555550000000b00000000000000000000000000000000b00000000000000000000000000000000000000000000000
00077000ffffffff44444444cccccccc55555555000000ab0000000000000000000000000000000b000000000000000400000000000000000000000000000000
00700700ffffffff44444444cccccccc5555555500000aab00000000000000000000000000000000b00000000000004440000000000000000000000000000000
00000000ffffffff44444444cccccccc5555555500000aab0000000000000000000000000000000bb00000000000044444000000000000000000000000000000
00000000ffffffff44444444cccccccc5555555500000abbb0000000000000000000000000000099990000000000414444400000000000000000000000000000
0000000000000000000000000000000000000000000000bbaa000000000000000000000000000099990000000000444441400000000000000000000000000000
0000000000000000000000000000000000000000000000bbaa000000000000000000000000000099990000000000441444440000000000000000000000000000
00000000000000000000000000000000000000000000000baa000000000000000bbbb88000000099990000000000444444440000000000000000000000000000
00000000000000000000000000000000000000000000000bb00000000000b88bbbbbb88000000009900000000000044444440000000000000000000000000000
00000000000000000000000000000000000000000000000bb00000000000b88bbbbbbbb000000009900000000000044444400000000000000000000000000000
00000000000000000000000000000000000000000000000bb0000000000bbbbbbb88bb0000000009900000000000004440000000000000000000000000000000
00000000000000000000000000000000000000000000000bb000000000bbbbbbbb88bb0000000000900000000000000400000000000000000000000000000000
00000000000000000000000000000000000000000000000bb000000000bbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000
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
