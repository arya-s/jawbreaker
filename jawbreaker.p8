pico-8 cartridge // http://www.pico-8.com
version 30
__lua__
function _init()
	t=0
	init_game()
end

function _draw()
	_drw()
--	print(cur_event.id)
--	print(rnd_cnt)
	for txt in all(debug) do
		print(txt)
	end
end

function _update60()
	t+=1
	_upd()
end
-->8
--game
function init_game()
	cur_event=get_event("story_intro")
	
	dirx={-1,1,0,0,1,1,-1,-1}
	diry={0,0,-1,1,-1,1,1,-1}
	
	itm_name={"butter knife","swiss knife","tracksuit","baseball bat","milk","bread","cannoli","sfogliatella","colt m1911"}
	itm_type={"wep","wep","arm","wep","fud","fud","fud","fud","wep"}
	itm_stat1={1,1,0,2,1,1,1,1,3}
	itm_stat2={0,0,1,0,1,2,2,3,0}
	
	lvl=1
	lvlmax=48
	
	rnd_cnt=0
	
	player_typ=nil
	player={
		typ="player",
		ani={48,49,50,51},
		hp=5,
		hpmax=5,
		atk=1,
		defmin=0,
		defmax=0,
		x=32,
		y=111,
		ox=0,
		oy=0,
		t=0,
	}
	
	selection=0
	
	inv,eqp={},{}
	--eqp[1] - weapon
	--eqp[2] - armor
	--inv[1-6] - equipment

	windows={}
	floats={}
	debug={}
	
	_drw=draw_game
	_upd=update_game
end

function draw_game()
	cls()
 oprint("jawbreaker",46,50,8,1)
 print("a game for ld48/48",30,60,8)
 draw_button("❎",62,70)
	print("by arya-s",88,120,1)
end

function update_game()
	if btnp(❎) then
		init_event()
	end
end
-->8
--event
function init_event()
	if cur_event.typ=="random_event" or
		cur_event.typ=="random_event_adult" or
		cur_event.typ=="random_event_adult_2" then
		rnd_cnt+=1
	end
	
	set_player_stats()
	enemy=generate_enemy()
	intro=get_intro()
	player.ani=ent_sprites[cur_event.entities[1]]
	event_actions=cur_event.actions
	rewards=cur_event.reward
	cur_act=nil
	
	take_reward()
	
	event_sprites={}
	for act in all(event_actions) do
		add(
			event_sprites,
			act_sprites[act]
		)
	end
	
	can_select=true
	fleeing=false
	
	_drw=draw_event
	_upd=update_event
	
	_event_drw=draw_postround
	_event_upd=update_postround
end

function set_player_stats()
	if not cur_event.entities then
		return
	end
	
	local plyr=cur_event.entities[1]
	
	-- we didnt upgrade so early return
	if player_typ==plyr then
		return
	end
	
	player_typ=plyr
	local stats=ent_stats[plyr]
	
	player.hp=stats.hp
	player.hpmax=stats.hpmax
end

function get_intro()
	if sub(cur_event.typ,1,#"random_event")=="random_event" then
		return choice(cur_event.intro)
	end
	
	return cur_event.intro
end

function generate_enemy()
	if not cur_event.entities then
		return nil
	end
	
	local typ=cur_event.entities[2]
	local enemy=cur_event.entities[2]
	local estats={
		hp=5,
		hpmax=5,
		atk=5
	}
	
	if typ=="random_enemy" or
				typ=="random_enemy_tough" or
				typ=="random_enemy_toughest" then
		enemy=choice(random_enemies)
	end
	
	if enemy!=nil then
	 estats=ent_stats[enemy]
	 print("estats "..estats.hp)
	 
		if typ=="random_enemy_tough" then
			estats.hp+=flr(rnd(3))+1
		elseif typ=="random_enemy_toughest" then
			estats.hp+=flr(rnd(5))+1
		end
	end
	
	return {
		typ="enemy",
		ani=ent_sprites[enemy],
		hp=estats.hp,	
		hpmax=estats.hp,
		atk=estats.atk,
		defmin=0,
		defmax=0,
		shirt=choice({8,9,10,11}),
		pants=choice({1,2,3,6}),
		x=64,
		y=111,
		ox=0,
		oy=0,
		t=0
	}
end

function take_reward()
	for reward in all(rewards) do		
		if reward=="random_reward" then
			-- spawn random reward
			if rnd()>0.40 then
				take_item(rndrng(1,#itm_name))
			end
		else
			take_item(get_idx(itm_name, reward))
		end
		sfx(2)
	end
end

function draw_event()
	cls()
	_event_drw()
	draw_dialog(0,0)
	draw_actions(0,60,can_select)
	draw_world(0,100)
	draw_floats()
	draw_windows()
end

function draw_dialog(x,y)
	local i=0
 for s in all(intro) do
 	print(s,x+8,y+8+(i*6),8)
 	i+=1
 end
	--oprint("what will you do?",x+32,y+12,8,1)
end

function draw_actions(x,y,is_interactive)

	local cnt=#event_actions
	if cnt==1 then
		draw_box(
			x+48,
			y,
			event_actions[1],
			event_sprites[1],
			is_interactive
		)
	elseif cnt==2 then
		draw_box(
			x+27,
			y,
			event_actions[1],
			event_sprites[1],
			is_interactive and selection==0
		)
		draw_box(
			x+69,
			y,
			event_actions[2],
			event_sprites[2],
			is_interactive and selection==1
		)
	elseif cnt==3 then
		draw_box(
			x+6,
			y,
			event_actions[1],
			event_sprites[1],
			is_interactive and selection==0
		)
		draw_box(
			x+48,
			y,
			event_actions[2],
			event_sprites[2],
			is_interactive and selection==1
		)
		draw_box(
			x+90,
			y,
			event_actions[3],
			event_sprites[3],
			is_interactive and selection==2
		)
	end
end

function draw_hp(ent,x,y,col)
	if ent.hpmax==99 then
		return
	end
	
	local hp,hpmax=ent.hp,ent.hpmax
	
	print(hp.."/"..hpmax,x,y,col)
end

function draw_world(x,y)
		map(0,0,x,y,16,4)
		
		draw_player()
		if enemy.ani!=nil then
			draw_ent(enemy,true)
		end
end

function draw_player()
	local name=cur_event.entities[1]
	local sprites=player.ani

	if name=="player_ya" and itm_name[eqp[2]]=="tracksuit" then
		sprites=ent_sprites["player_yasuit"]
	end
		
	pal(12,0)
	spr(sprites[1],player.x,player.y)
	spr(sprites[2],player.x+8,player.y)
	spr(sprites[3],player.x,player.y+8)
	spr(sprites[4],player.x+8,player.y+8)
	pal()
	
	draw_hp(player,player.x,player.y-4,3)
end

function draw_ent(ent,is_enemy)
	if is_enemy then
		pal(0,enemy.shirt)
		pal(14,enemy.pants)
	end
	
	local sprites=ent.ani
	pal(12,0)
	spr(ent.ani[1],ent.x,ent.y)
	spr(ent.ani[2],ent.x+8,ent.y)
	spr(ent.ani[3],ent.x,ent.y+8)
	spr(ent.ani[4],ent.x+8,ent.y+8)
	pal()
			
	draw_hp(ent,ent.x,ent.y-4,is_enemy and 8 or 3)
end

function draw_floats()
	for f in all(floats) do
		oprint(f.txt,f.x,f.y,f.c,0)
	end
end

function update_floats()
	for f in all(floats) do
		f.y+=(f.tar_y-f.y)/10
		f.t+=1
		--disappears after 70 frames
		if f.t>70	then
			del(floats,f)
		end
	end
end

function update_event()
	_event_upd()
	
	if can_select then
		if btnp(0) then
			selection=(selection-1)%#event_actions
		elseif btnp(1) then
			selection=(selection+1)%#event_actions
		end
	end
	
	update_floats()
end

function hit(atkm,defm)
	local dmg=atkm.atk
	local def=defm.defmin+flr(rnd(defm.defmax-defm.defmin+1))
	dmg-=min(def,dmg)
	
	add_float("-"..dmg,defm.x+3,defm.y+4,8,0)
	
	if atkm.typ=="player" and eqp[1]==9 then
		sfx(4)
	else
		sfx(0)
	end
	
	defm.hp=max(0,defm.hp-dmg)
end

function heal(ent,hp)
	local amount=min(ent.hpmax-ent.hp,hp)
	
	if amount>0then
		ent.hp+=amount
		add_float("+"..amount,ent.x+3,ent.y+4,11,0)
		sfx(1)
		return true
	end
	
	return false
end

function eat(itm,ent)
	local effect=itm_stat1[itm]
	
	if effect==1 then	
		return	heal(ent,itm_stat2[itm])
	end
	
	return false
end

function die()
	sfx(3)
end

function completed()
	return fleeing or enemy.hp==0
end

--player turn
function do_pturn()
	can_select=false
	_event_drw=draw_pturn
	_event_upd=update_pturn
end

function draw_pturn()
--spr(1,player.x,player.y-50)
end

function update_pturn()
	player.t+=1
	
	if player.t>70 then
		do_aiturn()
	end
end

--ai turn
function do_aiturn()
	_event_drw=draw_aiturn
	_event_upd=update_aiturn
	
	if not fleeing then
		if enemy.hp==0 then
			die(enemy)
		else
			hit(enemy,player)
		end
	end
end

function draw_aiturn()
--spr(1,enemy.x,enemy.y-50)
end

function update_aiturn()
	enemy.t+=1
	
	if enemy.t>70 then
		_event_drw=draw_postround
		_event_upd=update_postround
	end
end


function update_postround()
	player.t,enemy.t=0,0
	can_select=true
	
	if completed() then
		-- go to next event
		next_event(cur_act)
	elseif player.hp==0 then
		sfx(3)
		cur_event=get_event("gameover_generic")
		init_gameover()
	else
		if btnp(❎) then
			local act=event_actions[selection+1]
			cur_act=act
		
			if act=="fight" or act=="steal" then
				can_select=false
				hit(player,enemy)
				do_pturn()	
			elseif act=="equip" then
				can_select=false
				init_inventory()
			elseif act=="flee" then
				fleeing=true
			elseif act=="continue" or act=="talk" then
				next_event(act)										
			elseif act=="home" then
				cur_event=get_event(cur_event.nxt[act])
				init_gameover()				
			end
		end
	end
end

function draw_postround()
	
end

function next_event(act)
	cur_event=get_event(cur_event.nxt[act])
	
	if cur_event.typ=="gameover" then
		init_gameover()
	else
		init_event()
	end
end
-->8
function init_gameover()
	_drw=draw_gameover
	_upd=update_gameover
	go_t=0
	shot=false
	is_win=false
end

function draw_gameover()
	cls()
	
	local x,y=48,40
	oprint("game over",x,y,8,1)
	y+=4
	
	if cur_event.typ=="gameover" then
		intro=cur_event.intro
		
		if cur_event.id=="gameover_success" then
			is_win=true
		end
	else
		intro={
			"you died in battle."
		}		
	end

 for s in all(intro) do
 	y+=6
 	print(s,16,y,8)
 end
 y+=20
  
 if is_win then
	 if shot then
			draw_button("❎",62,y,10,1)
		end
	else
		draw_button("❎",62,y,10,1)
	end
end

function update_gameover()
	go_t+=1
	
	if go_t>600 and cur_event.id=="gameover_success" and not shot then
		sfx(4)
		go_t=0
		shot=true
	end
	
	if is_win then
		if shot and btnp(❎) then
			init_game()
			cur_event=get_event("story_intro")
		end
	else
		if btnp(❎) then
			init_game()
			cur_event=get_event("story_intro")
		end
	end
end
-->8
--inventory
function init_inventory()
	local txt,itm,eqt={}
	
	for i=1,2 do
		itm=eqp[i]
		if itm then
			eqt=itm_name[itm]
		else
			eqt=i==1 and "[weapon]" or "[armor]"
		end
		add(txt,eqt)
	end
	add(txt,"……………………")
	for i=1,6 do
		local itm=inv[i]
		if itm then
			add(txt,itm_name[itm])
		else
			add(txt,"...")
		end
	end
	
	inv_window=add_window(
		5,17,84,62,txt)
	inv_window.cur=3
	inv_window.has_button=true
	
	stat_window=add_window(
		5,5,84,13,{
			"atk:  "..player.atk.."  def: "..player.defmin.."-"..player.defmax
	})

		
	active_window=inv_window

	_upd=update_inventory
end

function init_invuse()
	local itm=inv_window.cur<3 and eqp[inv_window.cur] or inv[inv_window.cur-3] 
	
	if not itm then
		return
	end
	
	local typ,txt=itm_type[itm],{}
	
	if (typ=="wep" or typ=="arm") and inv_window.cur>3 then
		add(txt,"equip")
	end
	
	if typ=="fud" then
		add(txt,"eat")
	end
	
	if typ=="thr" then
		add(txt,"throw")
	end
	
	add(txt,"trash")
	
	invuse_window=add_window(
		84,inv_window.cur*6+11,36,7+#txt*6,txt)
	invuse_window.cur=1
	
	active_window=invuse_window
end

function update_inventory()
	update_cursor(active_window)
	if btnp(4) then
		if active_window==inv_window then
			_upd=update_event
			inv_window.dur=0
			stat_window.dur=0
		elseif active_window==invuse_window then
			invuse_window.dur=0
			active_window=inv_window
		end
	elseif btnp(5) then
		if active_window==inv_window and inv_window.cur!=3 then
			init_invuse()
		elseif active_window==invuse_window then
			use()
		end
	end
end

function take_item(itm)
	local i=free_invslot()
	if i==0 then
		return fasle
	end
	
	inv[i]=itm
	return true
end

function free_invslot()
	for i=1,6 do
		if not inv[i] then
			return i
		end
	end
	
	return 0
end

function use()
	local act,i=invuse_window.txt[invuse_window.cur],inv_window.cur
	local itm=i<3 and eqp[i] or inv[i-3]
	local after="back"
	local consumes_turn=false
	
	if act=="trash" then
		if i<3 then
			eqp[i]=nil
		else
			inv[i-3]=nil
		end
	elseif act=="equip" then
		local slot=2
		if itm_type[itm]=="wep" then
			slot=1
		end
		inv[i-3]=eqp[slot]
		eqp[slot]=itm
	elseif act=="eat" then
		local consumed=eat(itm,player)
		
		if consumed then
			inv[i-3]=nil
		end
		
		after="quit"
	elseif act=="throw" then
		after="quit"
	end

	update_stats()
	
	if after=="back" then
		invuse_window.dur=0
		active_window=inv_window
		del(windows,inv_window)
		del(windows,stat_window)
		init_inventory()
		inv_window.cur=i
	elseif after=="quit" then	
		invuse_window.dur=0
		inv_window.dur=0
		stat_window.dur=0
		can_select=true
		_upd=update_event
		
		if consumes_turn then
			do_pturn()
		end
	end
end

function update_stats()
	local atk,defmin,defmax=1,0,0
	
	if eqp[1] then
		atk+=itm_stat1[eqp[1]]
	end
	
	if eqp[2] then
		defmin+=itm_stat1[eqp[2]]
		defmax+=itm_stat2[eqp[2]]
	end
	
	player.atk=atk
	player.defmin=defmin
	player.defmax=defmax
end
-->8
--windows
function draw_windows()
	for w in all(windows) do
		--this saves tokens because . costs tokens
		local wx,wy,ww,wh=w.x,w.y,w.w,w.h
		rectfill2(wx,wy,ww,wh,0)
		rect(wx+1,wy+1,wx+ww-2,wy+wh-2,1)		
		wx+=4
		wy+=4
	
		clip(wx,wy,ww-8,wh-8)		
		
		if w.cur then
			wx+=7
		end
		
		for i=1,#w.txt do
			local txt,c=w.txt[i],1
			
			if w.col and w.col[i] then
				c=w.col[i]
			end
			
			if w.cur==i and i!=3then
				c=8
			end
			
			print(txt,wx,wy,c)
			
			--render cursor
			if i==w.cur then
				spr(255,wx-6+sin(time()*2),wy)
			end
			
				-- linebreak
			wy+=6
		end
		-- reset clipping
		clip()
		
		if w.dur then
			w.dur-=1
			if w.dur<=0 then
					local dif=wh/4
					w.y+=dif/2
					w.h-=dif
					if wh<3 then			
						del(windows,w)
					end
			end
		else
			if w.has_button then
				draw_button("🅾️",wx+ww-22,wy+1-0.9)
			end
		end
	end
end

function add_window(x,y,w,h,txt)
 local w={x=x,
          y=y,
          w=w,
          h=h,
          txt=txt}
 add(windows,w)
 return w
end

function update_cursor(window)
	if btnp(⬇️) then
		window.cur=max(1,(window.cur+1)%(#window.txt+1))
	elseif btnp(⬆️) then
		local n=(window.cur-1)%(#window.txt+1)
		if n==0 then
			n=#window.txt
		end
		window.cur=n
	end
end
-->8
--helprs
function oprint(txt,x,y,txt_col,outline_col)
	-- prints text with an outline
	for i=1,8 do
		print(txt,x+dirx[i],y+diry[i],outline_col)
	end
	print(txt,x,y,txt_col)		
end

function zspr(n,w,h,dx,dy,dz,fx,fy)
	--n: standard sprite number
	--w: number of sprite blocks wide to grab
	--h: number of sprite blocks high to grab
	--dx: destination x coordinate
	--dy: destination y coordinate
	--dz: destination scale/zoom factor
 sspr(8*(n%16),8*flr(n/16),8*w,8*h,dx,dy,8*w*dz,8*h*dz,fx,fy)
end

function get_frame(ani)
	return ani[flr(t/15)%#ani+1]
end

function choice(arr)
	return arr[1+flr(rnd(#arr))]
end

function rndrng(lo,hi)
	return flr(rnd()*(hi-lo))+lo
end

function draw_box(x,y,action,sprite,is_selected)
	if is_selected then
		pal(1,2)
	end
	
	local n,column,row=64,x,y
	for i=0,3 do
		for j=0,3 do
			spr(n+j,column+(j*8),row+(i*8))
		end
		n+=16
	end	
	pal()
	
	zspr(sprite,1,1,x+8,y+8,2)
	
	if is_selected and inventory_window==nil then
		draw_button("❎",x+13,y+28)		
	end
end

function draw_button(button,x,y)
	oprint(button,x,y,1,2)
	oprint(button,x,y+0.5*(sin(time())+0.1),8,1)
end

function rectfill2(x,y,w,h,c)
 rectfill(x,y,x+max(w-1,0),y+max(h-1,0),c)
end

function add_float(txt,x,y,c)
	add(floats,
		{
			txt=txt,
			x=x,
			y=y,
			c=c,
			tar_y=y-10,
			t=0
	})
end

function get_idx(arr,val)
	for i=1,#arr do
		if arr[i]==val then
			return i
		end
	end
	
	return 0
end

function get_event(id)
	if cur_event and (
	   cur_event.typ=="random_event" or
				cur_event.typ=="random_event_adult" or
				cur_event.typ=="random_event_adult_2") then
		if rnd_cnt<cur_event.times then
			return cur_event
		end
	end
		
	rnd_cnt=0
	
	for ev in all(story_events) do
		if id==ev.id then
			return ev
		end
	end
end
-->8
story_events={
	{
	 id="story_intro",
	 typ="story",
	 intro={
	  "your name is dino.you're",
	  "7 years old.you were the",
	  "first of your italian",
	  "family to be born in",
	  "america."
	 },
	 actions={"continue"},
	 nxt={continue="npc_mom_1"},
	 entities={"player_kid"},
	 bg="home"    
	},
	{
	 id="npc_mom_1",
	 typ="npc",
	 intro={
	  "you are playing with your",
      "toy car when you hear your",
      "mother approach."
	 },
	 actions={"talk"},
	 nxt={talk="npc_mom_2"},
	 entities={"player_kid","npc_mom"},
	 bg="home",
	 fade=false
	},
	{
		id="npc_mom_2",
		typ="npc",
		intro={
		 "mom:dino, heres 50 cents.",
		 "go down to the store and",
         "get a chicken and two",
         "tomatos."
		},
		actions={"continue"},
		nxt={continue="story_shop"},
		entities={"player_kid","npc_mom"},
		bg="home"
	},
	{
		id="story_shop",
		typ="story",
		intro={
		 "you arrive at di palo's.",
		 "as you wait in line at",
		 "the cashier you spot a",
		 "jawbreaker that you buy",
		 "instead of the tomatos." 
		},
		actions={"continue"},
		nxt={continue="event_postshop"},
		entities={"player_kid"},
		bg="shop"
	},
	{
		id="event_postshop",
		typ="event",
		intro={
		 "as you walk home you",
		 "remember the beating",
		 "you received last time",
		 "for buying sweets",
         "instead of groceries.",
		 "you see a small kid in",
         "the street."
		},
		actions={"steal", "home"},
		nxt={steal="story_postfight",home="gameover_mom"},
		entities={"player_kid","enemy_1_kid"},
		bg="street_1_day"
	},
	{
		id="gameover_mom",
		typ="gameover",
		intro={
		 "you went home without the",
		 "tomatos. your mom gives",
         "you the beating of a",
         "lifetime."
		}
	},
	{
		id="story_postfight",
		typ="story",
		intro={
		 "you took that kid's money",
		 "and went back to the shop",
		 "to get the tomatos."
		},
		entities={"player_kid"},
		actions={"continue"},
		nxt={continue="story_timeskip"},
        bg="shop"
	},
	{
		id="story_timeskip",
		typ="story",
		intro={
			"some time has passed since",
			"that day.",
			"you get appraoched by a",
            "guy who introduces himself",
            "as tony."
		},
		entities={"player_kid", "tony"},
		actions={"talk"},
		nxt={talk="story_tony_appoach"},
        bg="street_1_day"
	},
	{
		id="story_tony_appoach",
		typ="story",
		intro={
			"tony:hey kiddo",
			"you got quite the rep-",
            "utation around the",
            "block.wanna make some",
            "extra cash?"
		},
		entities={"player_kid", "tony"},
		actions={"talk", "home"},
		nxt={talk="story_tony_errand", home="gameover_tony_flee"},
        bg="street_1_day"
	},
    {
        id="story_tony_errand",
		typ="story",
		intro={
			"tony:it's real simple.",
            "take this note over to",
            "pescatoni's.ask for",
            "joe.tell him tony",
            "sends his regards."
		},
		entities={"player_kid", "tony"},
		actions={"continue"},
		nxt={continue="story_tony_errand_done"},
        bg="street_1_day"
    },
    {
        id="story_tony_errand_done",
		typ="story",
		intro={
			"you did what tony asked",
            "of you.",
            "tony rewards you with a",
            "brand new tracksuit."
		},
		entities={"player_kid"},
		actions={"continue", "equip"},
		nxt={continue="event_timeskip_pescatoni"},
        bg="restaurant",
        reward={"tracksuit"}
    },
    {
        id="event_timeskip_pescatoni",
		typ="event",
		intro={
            "as the years go by you do",
            "more and more jobs for",
            "tony."
        },
		entities={"player_ya", "random_enemy"},
		actions={"fight", "equip", "flee"},
		nxt={fight="random_event",flee="random_event"},
        reward={"milk"},
        bg="street_1_day"
    },
    {
        id="random_event",
        typ="random_event",
        intro={
            {
                "you run into a guy owing",
                "you money."
            },
            {
                "after hitting on a girl",
                "you make acquaintance",
                "with her boyfriend."
            },
            {
                "a guy approaches you",
                "asking about tony."
            },
            {
                "you accidentally venture",
                "into the wrong turf."
            },
            {
                "you try to jack someone's",
                "car."
            }
        },
        times=3,
        actions={"fight", "equip", "flee"},
        nxt={fight="story_tony_hitjob",flee="story_tony_hitjob"},
        entities={"player_ya", "random_enemy"},
        reward={"random_reward"},
        bg="streey_1_day"
    },
    {
        id="story_tony_hitjob",
        typ="story",
        intro={
            "tony:dino,c'mere kid.",
            "listen,i got a special",
            "job for ya.take this iron.",
            "be at amsterdam ave 227nd",
            "60th tomorrow, 9am sharp."
        },
        actions={"continue", "equip", "home"},
        nxt={continue="event_hitjob",home="gameover_tony_flee"},
        entities={"player_ya", "tony"},
        reward={"colt m1911"},
        bg="bronx_cafe"
    },
    {
        id="event_hitjob",
        typ="event",
        intro={
            "you get clear instructions",
            "to clip this guy.",
            "the quicker the better."
        },
        actions={"fight", "equip"},
        nxt={fight="story_past_hitjob"},
        entities={"player_ya", "random_enemy_tough"},
        reward={"bread","bread"},
        bg="hitjob_car"
    },
    {
        id="story_past_hitjob",
        typ="story",
        intro={
            "years pass as you do more",
            "and more jobs for tony."
        },
        actions={"continue"},
        nxt={continue="random_event_adult"},
        entities={"player_ad"},
        reward={"cannoli"},
        remove_reward={"colt m1911"},
        bg="night_bar"
    },
    {
        id="random_event_adult",
        typ="random_event_adult",
        times=4,
        intro={
            {
                "you run into a guy owing",
                "you money."
            },
            {
                "you make out with a broad.",
                "her husband comes chasing",
                "after you."
            },
            {
                "a guy approaches you",
                "asking about tony."
            },
            {
                "tony sends you to",
                "collect some money."
            },
            {
                "tony sends you to",
                "strike at a local",
                "construction site.",
                "security is chasing",
                "you."
            }
        },
        actions={"fight","equip","flee"},
        entities={"player_ad", "random_enemy_tough"},
        nxt={fight="story_tony_disagreement", flee="story_tony_disagreement"},
        bg="night_street"
    },
    {
        id="story_tony_disagreement",
        typ="story",
        intro={
            "as you grow old, you grow",
            "impatient with tony's",
            "refusal to acknowledge",
            "your contributions",
            "to the organization."
        },
        actions={"talk"},
        entities={"player_old", "tony_final_1"},
        nxt={talk="event_tony_disagreement_fight"},
        bg="tony_home"
    },
    {
        id="event_tony_disagreement_fight",
        typ="event",
        intro={
            "tony refuses to hear you out",
            "you start a fight with him."
        },
        actions={"fight", "equip"},
        entities={"player_old", "tony_final_1"},
        nxt={fight="story_post_tony_fight"},
        reward={"sfogliatella"},
        bg="night_street"
    },
    {
        id="story_post_tony_fight",
        typ="story",
        intro={
            "you broke tony's jaw, but",
            "rumors on the street are",
            "he recovered and is ready",
            "to get rid of you.",
            "you better get ready."
        },
        actions={"continue"},
        entities={"player_old"},
        nxt={continue="random_event_adult_2"}
    },
    {
        id="random_event_adult_2",
        typ="random_event_adult_2",
        times=3,
        intro={
            {
                "you run into a guy owing",
                "you money."
            },
            {
                "a guy approaches you",
                "asking about tony."
            },
            {
                "one of your guys gets",
                "mugged on your turf.",
                "you investigate."
            },
            {
                "two kids jump you at",
                "night.one realizes who",
                "you are and bounces."
            }
        },
        actions={"fight","equip","flee"},
        entities={"player_old", "random_enemy_toughest"},
        reward={'random_reward"'},
        nxt={fight="fight_tony_final", flee="fight_tony_final"},
        bg="night_street"
    },
    {
        id="fight_tony_final",
        typ="event",
        intro={
            "tony:i give you to the",
            "count of ten before i",
            "pump your guts full of",
            "led kid."
        },
        actions={"fight", "equip"},
        entities={"player_old", "tony_final_2"},
        nxt={fight="gameover_success"},
        bg="tony_home"
    },
	{
		id="gameover_tony_flee",
		typ="gameover",
		intro={
		 "you tried to run away, but",
		 "tony easily catches you."
		}
	},
	{
		id="gameover_generic",
		typ="gameover",
		intro={
         "you died.",
		 "thanks for playing"
		}
	},
    {
        id="gameover_success",
        typ="gameover",
        intro={
            "you defeated tony.",
            "after years of doing",
            "the dirty work yourself",
            "you are the boss now.",
            "you sit back and relax",
            "grabbing one of your",
            "favorite jawbreakers..."
        }
    }
}
-->8
--maps
ent_sprites={
	player_kid={32,33,48,49},
	player_ya={44,45,60,61},
	player_yasuit={2,3,18,19},
	player_ad={4,5,20,21},
	player_old={6,7,22,23},
	npc_mom={36,37,52,53},
	enemy_1_kid={34,35,50,51},
	enemy_1={8,9,24,25},
	enemy_2={10,11,26,27},
	enemy_3={12,13,28,29},
	tony={38,39,54,55},
	tony_final_1={40,41,56,57},
	tony_final_2={42,43,58,59}
}

ent_stats={
	player_kid={atk=1,hp=2,hpmax=2},
	player_ya={atk=1,hp=5,hpmax=5},
	player_ad={atk=1,hp=7,hpmax=7},
	player_yasuit={atk=1,hp=7,hpmax=7},
	player_old={atk=2,hp=12,hpmax=12},
	npc_mom={atk=999,hp=99,hpmax=99},
	enemy_1_kid={atk=1,hp=1,hpmax=1},
	enemy_1={atk=1,hp=3,hpmax=3},
	enemy_2={atk=1,hp=3,hpmax=3},
	enemy_3={atk=1,hp=3,hpmax=3},
	tony={atk=999,hp=99,hpmax=99},
	tony_final_1={atk=3,hp=12,hpmax=12},
	tony_final_2={atk=5,hp=14,hpmax=14}
}

random_enemies={"enemy_1","enemy_2","enemy_3"}

act_sprites={
	eat=130,
	fight=128,
	talk=131,
	flee=132,
	equip=133,
	continue=134,
	home=135,
	steal=136
}
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000ccc0000000000000ccc0000000000000ccc000000000000ccc0000000000000cccc000000000000ccc00000000000000000000000
0007700000000000000000c444c00000000000c444c00000000000c444c0000000000c6d6c00000000000c1111c0000000000c555c0000000000000000000000
000770000000000000000c44444c000000000c44444c000000000c44444c00000000c6d6d6c000000000c11111c000000000c55555c000000000000000000000
00700700000000000000c4444444c0000000c4444444c0000000c4444444c0000000cd6d6d6c00000000c111111c00000000c555555c00000000000000000000
00000000000000000000c444fffc00000000c444fffc00000000c444fffc00000000cfffff6c00000000c11ff11c00000000c444445c00000000000000000000
00000000999999990000c4fffffc00000000c4f4fffc00000000c4f4fffc00000000cddffffc00000000cffff1c000000000c444444c00000000000000000000
000000000000000000000cffffc0000000000cffffc0000000000cff44c0000000000cffffc0000000000cfffc00000000000c4444c000000000000000000000
00000000000000000000c22ff22c00000000cdd66ddc00000000c111f11c00000000cfeffefc00000000ceeeeec0000000000ceeeec000000000000000000000
0000000000000000000c28888882c000000cddd66dddc000000c11114111c000000cfeeeeeefc000000cfe0e0efc00000000ceeeeeec00000000000000000000
0000000000000000000cf222222fc000000cfdd66ddfc000000c11116111c000000cfeeeeeefc000000cfee0eefc00000000c4eeee4c00000000000000000000
00000000000000000000cf1111fc00000000cfd66dfc00000000cf1161fc00000000cfeeeefc00000000cfeeefc0000000000c4ee4c000000000000000000000
00000000000000000000c282222c00000000c222222c00000000c555555c00000000c000000c00000000c00000c0000000000c0000c000000000000000000000
00000000000000000000c822c22c00000000c222c22c00000000c555c55c00000000c00c000c00000000c00c00c0000000000c0000c000000000000000000000
00000000000000000000c2dcc2dc00000000c2dcc2dc00000000c5dcc5dc00000000c50cc50c00000000c60c60c0000000000c9090c000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000cccc0000000000000ccc0000000000000ccc0000000000000ccc00000000000000ccc0000000000000000000000
000000000000000000000000000000000000c1111c00000000000cfffc00000000000cfffc00000000000cfffc000000000000c444c000000000000000000000
00000000000000000000000000000000000c111111c000000000c4fff4c000000000c6fff7c000000000c6fff7c0000000000c44444c00000000000000000000
0000000cc00000000000000000000000000c111111c00000000c4fff444c0000000c7fff776c0000000c7fff776c00000000c4444444c0000000000000000000
000000c44c0000000000000000000000000c1fff11c000000000cffff44c00000000cffff77c00000000cffff77c00000000c444fffc00000000000000000000
00000c4444c0000000000000000000000000cfff11c00000000cffffff4c0000000cffffff7c0000000cffffff7c00000000c4fffffc00000000000000000000
00000c4fffc000000000000cc00000000000cfff111c0000000cffffffc00000000cffffffc00000000cffffffc0000000000cffffc000000000000000000000
000000cfffc00000000000c55c00000000000c2f211c00000000cfffffc000000000cfffffcc0000000ccfffffc000000000c333333c00000000000000000000
000000cffc00000000000c5555c000000000c2222f11c00000cf74ff77fc00000000cdd11ddc000000cdcddd444c0000000c33333333c0000000000000000000
00000c333c00000000000cfff5c000000000cf22fccc000000cf774777fc0000000cfddfdddc00000cdddddd4444c000000cf333333fc0000000000000000000
00000cf99fc00000000000cffc00000000000c222c000000000cf7777fc000000000cdd11ddc000000cc4f111f444c000000cf1111fc00000000000000000000
00000c111c000000000000feefc0000000000c2222c0000000007777777c00000000c111111c0000000c4111111cc0000000c111111c00000000000000000000
00000cfcfc000000000000c000c0000000000c22222c00000000c33c333c00000000c11c111c00000000c11c111c00000000c111c11c00000000000000000000
00000cfcfc000000000000cfcfc0000000000c5cc5c000000000cb3ccb3c00000000cd1ccd1c00000000cd1ccd1c00000000c1dcc1dc00000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
11100000000000000000000000000111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111555555555555555555555555555555550000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000022022000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066000000099990000066600000000000000000021221200000400000000000000000000000000000000000000000000000000000000000000000000
011fff000656000009999990006666600ff00000000550000212212004444400011fff9000000000000000000000000000000000000000000000000000000000
011fff000065600000888800007676700222200000544c000021221244444440011fff0900000000000000000000000000000000000000000000000000000000
011ff0000006440004b44b40066666600622220000644c000212212006666600011ff09000000000000000000000000000000000000000000000000000000000
00000000000044400b9bb9b005566650011111000044400021221200064606000000000000000000000000000000000000000000000000000000000000000000
00000000000004400999999000055500000000000000000022022000064666000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018810000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000011111111111111111111111111111111111111111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000018881888181818881888188818881818188818881000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000011811818181818181818181118181818181118181000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000001811888181818811881188118881881188118811000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000011811818188818181818181118181818181118181000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000018811818188818881818188818181818188818181000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000011111111111111111111111111111111111111111000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000088800000088088808880888000008880088088800000800088008080888000808080888000000000000000000000000000
00000000000000000000000000000080800000800080808880800000008000808080800000800080808080808008008080808000000000000000000000000000
00000000000000000000000000000088800000800088808080880000008800808088000000800080808880888008008880888000000000000000000000000000
00000000000000000000000000000080800000808080808080800000008000808080800000800080800080808008000080808000000000000000000000000000
00000000000000000000000000000080800000888080808080888000008000880080800000888088800080888080000080888000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001188888110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001881818810000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001888188810000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001881818810000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000001188888110000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000111111100000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110101000001110111010101110000001100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010101000001010101010101010000010000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100111000001110110011101110111011100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010001000001010101000101010000000100000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110111000001010101011101010000011000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
4445464744454647444546474445464700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5455565754555657545556575455565700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
6465666764656667646566676465666700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7475767774757677747576777475767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0001000005500095000650008500100500b05008050070500405003050010500005013000005000a5000850004500165002b50028500215001c500135000f5000d5003550019500055000050007500075000e000
00100000000000e500135001c50019550155501c55019500155001c5001b500285002c5000c0001c0001d0001f000220002500027000290002b0002e000300003200000000000000000000000000000000000000
000600000000000000000000d0501b05027050240501300000000000000e000240001d0001b000110000d0000d000000000000000000000000000000000000000000000000000000000000000000000000000000
000800000000000000060500305001050000000100002000020000200001000010000200000000000000000012000130001600015000000000000000000000000000000000000000000000000000000000000000
0002000023660226601f6501d6501c6501a6401864016640156401464012640116300f6300e6300e6300d6300c6200b6200a62009620076200561003610026100010000100001000010000100001000010000100
