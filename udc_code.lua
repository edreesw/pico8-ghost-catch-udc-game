--author: edrees wahezi
--ghost catch
--aka
--underworld death collector
--aka
--parachute clone

function _init()
	-- set the initial delay before (button hold) repeating. 255 means never repeat, 0 is default.
	poke(0x5f5c, 255)
	-- set the repeating delay (button hold).
	poke(0x5f5d, 255) 
	
	--upate this to match update()/update60() 
	fps = 60

	--play area x axis limits:
	left_limit = 40
	right_limit = 72
	
	--how many pixels a button press moves the player
	player_move_unit = 16
	
	fall_speed = 60/fps --0.75
	
	--x coordinate column starting pixels (where ghosts and enemies fall)
	column_1 = 48
	column_2 = 64
	column_3 = 80
	
	--number to help determine ghost/enemy spawn rates and fall speeds
	action_timer = 0
	
	--timer to track animations
	animation_timer = 0
	
	player = {
		x=56,
		y=104,
		sprite=17
		}
		
	ghost_list = {}
		
		
	level = 1
		
	score = 0
		
	miss = 0
	
	ghost_list = {}
	
	music(0)
end


function _update60()
	
	if(miss==3) then
		music(-1)
		return
	end
	
	action_timer = action_timer+1
	
	player_movement()
	
	ghost_movement()
	
	--spawn logic (based on timer)
	spawn()
	
	--check player/ghost/enemy interaction and
		--update score/miss values/enemy list, level, and fall speed
	check_catch_miss()
	
	update_sprites_anim()
	
end


function _draw()

	cls()
	map()
	
	--draw ghosts
	for i = 1, #ghost_list do
		spr(ghost_list[i].sprite, ghost_list[i].x, ghost_list[i].y)
	end
	
	--draw player
	spr(player.sprite, player.x, player.y, 2, 1)
	
	end_print = print("score: ", 0, 0, 7)
	end_print = print(score, end_print, 0, 7)
	end_print = print("level: ", 50, 0, 2)
	end_print = print(level, end_print, 0, 2)
	end_print = print("miss: ", 100, 0, 7)
	print(miss, 120, 0, 8)
	
	
	--game over text
	if(miss==3) then
		print("game over", 48, 64, 7)
	end
	
end


function player_movement()
	if(btnp(⬅️) and player.x != left_limit) then
		player.x -= player_move_unit
		sfx(1)
	elseif(btnp(➡️) and player.x != right_limit) then
		player.x += player_move_unit
		sfx(1)
	end
end


function ghost_movement() 
	--ghost movement
	for i = 1, #ghost_list do
		if ghost_list[i].ready_del==false then
			ghost_list[i].y += fall_speed
		end
	end
end


function check_catch_miss()
	for i = 1, #ghost_list do
		
		--handle ghost that's in the process of being deleted/animated
		if(ghost_list[i].ready_del==true) then
			if(ghost_list[i].animation_countdown==0) then
				del(ghost_list, ghost_list[i])
			else
				ghost_list[i].animation_countdown -= 1
			end
			break
		end
	
	
		--logic to see if ghost is caught by player sprite or hits the water
		if(ghost_list[i].ready_del==false and 
					abs((player.x+8)-ghost_list[i].x)<4 and
					abs(player.y-ghost_list[i].y)<4) then
			
			--if enemy ghost, catch counts as miss
			if(ghost_list[i].evil) then
				miss=miss+1
				sfx(2)
				update_ghost_del_sprite(ghost_list[i], 35)
			else --successful catch
				score = score+1
				update_level()
				sfx(0)
				update_ghost_del_sprite(ghost_list[i], 34)
			end
			
			--del(ghost_list, ghost_list[i])
			break
			
		--else if ghost hits water:	
		elseif(abs(player.y-ghost_list[i].y)<2) then
			--only count as miss if ghost not evil
			if(not ghost_list[i].evil) then
				miss=miss+1
				sfx(2)
			end
			
			update_ghost_del_sprite(ghost_list[i], 20)				
			--del(ghost_list, ghost_list[i])
			break
		end
	end
end


function update_ghost_del_sprite(ghost, sprite_num)
	ghost.sprite=sprite_num
	ghost.ready_del=true
	ghost.animation_countdown=fps/10
	ghost.y=player.y --to play the animation at player height
end


function update_level()
	if(level >= 9) then
		return
	end
	
	if(score % 50 == 0) then
		level = level+1
		fall_speed = fall_speed+0.30
	end
end


function spawn()
		--need to mess with these numbers to get balance/speed/difficulty right for spawn and fall rates...
		if (action_timer >= (fps/level + fps/5)) then
			action_timer = 0
			
			--check if enemy or ghost spawn
				--todo
			
			--choose a column, 1-3
			column = flr(rnd(3))	
			
			x=0
			
			if(column == 0) then
				x=column_1
			elseif(column == 1) then
				x=column_2
			elseif(column == 2) then
				x=column_3
			end
			
			y=8
			
			--determine if spawn should be evil ghost/enemy
			evil_rate = flr(rnd(10))
			is_evil=false
			if(evil_rate==6) then
				is_evil=true
			end
				
			
			--create and add to list
			new_ghost = create_ghost(x, y, is_evil)
			
			add(ghost_list, new_ghost)
		end
end


function create_ghost(gx, gy, is_evil) 
	ghost_sprite = 0
	if is_evil then
		ghost_sprite=33
	else
		ghost_sprite=19
	end
	
	ghost = {
		x=gx,
		y=gy,
		sprite=ghost_sprite,
		evil=is_evil,
		ready_del=false,
		animation_countdown=0
	}
	return ghost
end


function update_sprites_anim()
	animation_timer += 1
	
	if animation_timer > fps/3 then
		animation_timer = 0
		
		--update player animation/sprite
		if player.sprite == 17 then
			player.sprite = 38
		else 
			player.sprite = 17
		end
		
		--update ghost animation/sprites
		for i = 1, #ghost_list do
		
			--first check if ghost is being deleted
			if ghost_list[i].ready_del then
				break
			end
			
			if ghost_list[i].evil == false then
				if ghost_list[i].sprite == 19 then
					ghost_list[i].sprite = 36
				else 
					ghost_list[i].sprite = 19
				end
			else
				if ghost_list[i].sprite == 33 then
					ghost_list[i].sprite = 37
				else 
					ghost_list[i].sprite = 33
				end
			end 
		end
		
	end

end