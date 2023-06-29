    includesfile multisprite_bankswitch.inc
    set romsize 8k
    set kernel multisprite
    set kernel_options pfcolors
    set optimization speed
    set optimization inlinerand
    set tv ntsc

__Start_Restart

    ; clear audio
    AUDV0 = 0 : AUDV1 = 0

    ;  Clears all normal variables.
    a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
    j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
    s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0 : z = 0

    ;***************************************************************
    ; Some general game state bools
    dim _Bit0_Reset_Restrainer = r
    dim _Bit1_Fire_Starter = r
    dim _Bit1_Phase_3_Init = r
    dim _Bit2_Intro_Sequence = r
    dim _Bit3_Stage_2 = r
    dim _Bit4_Bee_Death = r
    dim _Bit5_Bee_Death_Sequence = r
    dim _Bit6_Life_Loss_Reset = r
    dim _Bit7_Stage_2_Init = r
    _Bit3_Stage_2{3} = 1

    ;***************************************************************
    ;  Vars for determining various enemy movement states.
    dim _bitop_enemy_state_bools = g
    dim _bit0_enemy_state_bools_bubble_dir = g
    dim _bit1_enemy_state_bools_bug_dir = g
    dim _bit2_enemy_state_bools_mite_dir = g
    dim _bit3_enemy_state_bools_mite_attack = g 
    dim _bit4_enemy_state_bools_bubble_dead = g
    dim _bit5_enemy_state_bools_bug_dead = g
    dim _bit6_enemy_state_bools_mite_dead = g
    dim _bit7_enemy_state_bools_bug_step = g
    _bit0_enemy_state_bools_bubble_dir{0} = 1

    ; Rename them for Stage 2
    dim _bit0_enemy_state_bools_spider_dir = g
    dim _bit1_enemy_state_bools_boss_dir = g
    dim _bit2_enemy_state_bools_spider_dead = g
    dim _bit3_enemy_state_bools_boss_dead = g
    dim _bit4_enemy_state_bools_boss_mid_dead = g
    dim _bit5_enemy_state_bools_boss_low_dead = g
    dim _bit6_enemy_state_bools_boss_dir_y = g

    dim _boss_corner_countdown = y

    ; some variables for sounds (could definitely optimize this)
    dim _bubble_pop_countdown = s
    dim _bug_hit_countdown = t
    dim _boss_hit_countdown = t
    dim _mite_hit_countdown = u
    dim _spider_hit_countdown = u
    dim _fanfare_countdown = v
    dim _player_hit_countdown = b

    ; counter for 
    dim _player_flicker = x

    ; the mite is considered "dead" to start the game
    _bit6_enemy_state_bools_mite_dead{6} = 1

    ; vars to count how many times enemies have been hit
    dim _player2_hits_left = j
    dim _player2_hits_mid = l
    dim _player2_hits_right = n
    dim _player3_hits = o
    dim _player4_hits = p
    dim _boss_hits = p


    ; background color (black)
    COLUBK = $F4
    ; two-pixel wide ball and normal, and players move under playfield
    CTRLPF = $15
    scorecolor = $1C
    ; reset score
    score = 0

    ; life counter
    dim _player_lives = w
    _player_lives = 3

    ; index into arrays that determine player2 (bubble) visibility state
    dim _ns2_index = h
    _ns2_index = %00000111
    ; holds the "original" x position of player2 so it can be offset if one of them is shot
    dim _posx2 = i
    _posx2 = 60

    ; variable that determines if the stinger is in play
    dim _stinger_in_play = a

    ; variables for which game mode we're on and how long it's been since we pushed select
    dim _Select_Counter = m

    ; best practice dictates that if mode select is open for 30 seconds or so, return to Idle state
    dim _Boss_Anim_Counter = c
    dim _Mode_Select_Idle_Seconds = d

    ; variable for counting how long since you lost a life
    dim _life_loss_counter = f
    _life_loss_counter = 0

    ; bug hits
    dim _bug_hits = k

    ; variable that counts to sixty
    dim _clock = e

    ; initial position of player character
    player0x = 70
    player0y = 90

    ; initial position of missile1 (offscreen)
    missile1x = 200
    missile1y = 200

    pfheight = 1

    ; initiate lives to 3 and use the compact spacing
    ; lives vars are used by the 6lives minikernel included above
    ; we are actually using it as a health bar for this game
    ; and tracking lives separately
    dim lives_compact = 1
    lives = 96

    ; set lives sprite to a little heart
    lives:
    %00010000
    %00111000
    %01111100
    %11111110
    %11111110
    %01101100
    %00000000
    %00000000
end

    ;  Defines shape of player2 sprite (bubble)
    player2:
    %00111100
    %01111110
    %11111111
    %11111111
    %11111111
    %11011111
    %01101110
    %00111100
end

    ; Defines shape of player3 sprite (bad bug)
    player3:
    %0110000
    %0100110
    %0100010
    %0011110
    %0011100
    %0111110
    %1111111
    %1011101
    %0010100
    %0100010
    %0100010
    %0010100
end

    ; Defines shape of player4 sprite (mite)
    player4:
    %10001
    %01110
    %11111
    %01110
    %10001
end

 playfield:
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
................
..XX............
.X..............
X...............
X...............
X...............
X...............
.X..............
..XX............
.X..............
X...............
X...............
X...............
X...............
.X..............
..XX............
.X..............
X...............
X...............
X...............
X...............
.X..............
..XX............
................
................
end
 
gameloop

    ; set lives sprite to a little heart
    lives:
    %00010000
    %00111000
    %01111100
    %11111110
    %11111110
    %01101100
    %00000000
    %00000000
end

    _clock = _clock + 1
    if _clock > 59 then _clock = 0

    if _Bit5_Bee_Death_Sequence{5} then goto __End_P0_Anim

    if !_player_flicker then goto __Start_P0_Anim
    _player_flicker = _player_flicker - 3
    if !(_player_flicker & %00000111) then goto __Start_P0_Anim
    player0:
    %00000000
end
    goto __End_P0_Anim
__Start_P0_Anim
    ; because the clock and the flicker counter are synchronized in terms of parity (somehow?)
    ; I'm occasionally bumping the clock up by 1 during the flicker state *unless* it
    ; equals zero, because a lot of stuff initiates on that (lol). I can't imagine
    ; this will create any other issues.
    if _player_flicker && _clock then _clock = _clock + rand&1
    if _clock & 1 then goto __Down_Flap

    player0:
    %00011000
    %00111100
    %01000010
    %11111111
    %01000010
    %00111100
    %11011011
    %10111101
    %00111100
    %01000010
end

    goto __End_P0_Anim

__Down_Flap

    player0:
    %00011000
    %00111100
    %01000010
    %11111111
    %01000010
    %10111101
    %11011011
    %00111100
    %00111100
    %01000010
end

__End_P0_Anim

    if _Bit3_Stage_2{3} || _Bit7_Stage_2_Init{7} then goto __Stage_2_Start bank2

    ; color of playfield and ball (yellow, beehive)
    COLUPF = $18
    ; color of player (and missile) 0 (yellow, bee)
    COLUP0 = $1C
    ; 1 copy of player0 and 4 pixel wide missile
    NUSIZ0 = $20
    ; player1 doesn't actually exist in my game, but when the missile isn't on the same
    ; horizontal line as any of the p1 copies, it will assume these characteristics
    if _bit4_enemy_state_bools_bubble_dead{4} then NUSIZ1 = $30 else NUSIZ1 = ns2[_ns2_index]
    ; color of player (and missile) 1 (cyan)
    COLUP1 = $AE
    ; color of player 2 (cyan, bubble)
    COLUP2 = $AE
    ; color of player 3 (cyan if protected, red if not, bad bug)
    if !_bit4_enemy_state_bools_bubble_dead{4} then COLUP3 = $CC else COLUP3 = $48
    ; color of player 4 (black, mite)
    COLUP4 = $00
    NUSIZ4 = $30
    ; color of lives indicator (yellow)
    lifecolor = $1C

    ; make the bug's feet move once per second
    if !_clock then _bit7_enemy_state_bools_bug_step{7} = !_bit7_enemy_state_bools_bug_step{7}
    if _bit7_enemy_state_bools_bug_step{7} then NUSIZ3 = $37 else NUSIZ3 = $37 | 8

    ; fills in the side boundaries with color
    PF0 = %11110000

    drawscreen

    ;************************************************
    ; Reset character positions and things of that
    ; nature after a player respawns
    ;************************************************
    if !_Bit6_Life_Loss_Reset{6} then goto __Skip_Life_Reset
    _clock = 1
    _player_hit_countdown = 0
    _stinger_in_play = 0
    bally = 200
    missile0y = 200
    if !_bit4_enemy_state_bools_bubble_dead{4} then player2x = 65 : player2y = 44
    player3y = 32 : player3x = 65
    _bit6_enemy_state_bools_mite_dead{6} = 1
    _bit3_enemy_state_bools_mite_attack{3} = 0
    player0x = 70
    player0y = 90
    lives = 96
    _Bit6_Life_Loss_Reset{6} = 0
__Skip_Life_Reset

    ;*************************************************
    ; On initial startup, we don't want play to start
    ; until the player has pressed the fire button.
    ; When they do, the enemies will scroll onto the
    ; screen without attacking until they reach the
    ; middle. Then regular gameplay starts.
    ;*************************************************
    if !_Bit1_Fire_Starter{1} && joy0fire then _Bit2_Intro_Sequence{2} = 1
    if !_Bit2_Intro_Sequence{2} then goto __Skip_Intro
    NUSIZ2 = ns2[_ns2_index]
    if !_Bit1_Fire_Starter{1} then _Bit1_Fire_Starter{1} = 1 : player2y = 44 : player2x = 5 : player3y = 32 : player3x = 110
    if player2x < 65 then player2x = player2x + 1
    if player3x > 65 && _clock & 1 then player3x = player3x - 1 
    if player2x = 65 && player3x = 65 then _Bit2_Intro_Sequence{2} = 0 : _clock = 1
    goto __Reset_Listener
__Skip_Intro
    if !_Bit1_Fire_Starter{1} then goto gameloop

    ; something that could possibly be described as music
    if !_bit5_enemy_state_bools_bug_dead{5} then goto __Skip_Stage1_Win
    player4x = 200 : player4y = 200
    missile1x = 200 : missile1y = 200
    ; reusing this again to save vars
    if !_bug_hit_countdown then _bubble_pop_countdown = _bubble_pop_countdown + 1 : _bug_hit_countdown = 20
    
    if _bubble_pop_countdown > 5 then goto __Explode_Him
    if _bug_hit_countdown then _bug_hit_countdown = _bug_hit_countdown - 1 : AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 20 - _bug_hit_countdown else AUDV1 = 0
    ; Defines shape of player3 sprite (bad bug)
    player3:
    %0110000
    %0100110
    %0100010
    %0011110
    %0011100
    %0111110
    %1111111
    %1000001
end
    goto __Reset_Listener
__Explode_Him
    _bug_hit_countdown = _bug_hit_countdown - 1
    if _bubble_pop_countdown > 6 then goto __Fanfare
    AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 28
    player3:
    %0100100
    %1001010
    %0100010
    %1000101
    %0100010
    %1001000
    %0100001
    %0010100
end
    goto __Reset_Listener
__Fanfare
    if _fanfare_countdown > 90 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 25 : goto __Reset_Listener
    if _fanfare_countdown > 80 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 26 : goto __Reset_Listener
    if _fanfare_countdown > 70 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 25 : goto __Reset_Listener
    if _fanfare_countdown > 0 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 20 : goto __Reset_Listener
    AUDV0 = 0
    player3x = 200 : player3y = 200
    player2x = 75 : player2y = 0
    ; just in case
    _stinger_in_play = 0 : missile0x = 200 : ballx = 205 : missile0y = 200 : bally = 205
    _Bit7_Stage_2_Init{7} = 1
    goto __Reset_Listener
__Skip_Stage1_Win

    ;*********************************************
    ; little death anim/sfx for when the Bee dies
    ;*********************************************
    if _Bit5_Bee_Death_Sequence{5} then gosub __Bee_Death_Anim_Sub

    ; we can just continue to the "lives left" screen from here as long
    ; as I don't fuck up and put anything else between here

    if _Bit4_Bee_Death{4} then gosub __Bee_Death_Sub

    if _player_hit_countdown then _bubble_pop_countdown = 0 : _player_hit_countdown = _player_hit_countdown - 1 : AUDC0 = 8 : AUDV0 = 2 : AUDF0 = _player_hit_countdown : goto __End_Mite_Sound
    if _bubble_pop_countdown then _mite_hit_countdown = 0 : _bubble_pop_countdown = _bubble_pop_countdown - 1 : AUDC0 = 8 : AUDV0 = 8 : AUDF0 = 5 - _bubble_pop_countdown : goto __End_Mite_Sound
    if _mite_hit_countdown && _bit4_enemy_state_bools_bubble_dead{4} then _mite_hit_countdown = _mite_hit_countdown - 1 : AUDC0 = 7 : AUDV0 = 14 : AUDF0 = 5 - _mite_hit_countdown else AUDV0 = 0
__End_Mite_Sound
    if _bug_hit_countdown then _bug_hit_countdown = _bug_hit_countdown - 1 : AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 20 - _bug_hit_countdown else AUDV1 = 0 

    ; ****************************************************
    ; Tons of collision logic
    ; Collision checks should come right after drawscreen
    ; because they are determined using TIA registers
    ; ****************************************************

    if !collision(ball, player1) && !collision(missile0, player1) then goto __End_Collision
    if _bit4_enemy_state_bools_bubble_dead{4} then goto __Bug_Mite_Collisions
    ; ****************************************************
    ; I didn't really want to check for missile collisions
    ; but I have to for certain cases explained below
    ; ****************************************************
    if !collision(ball, player1) then goto __End_Collision
    ; when the bubbles are alive, we know the ball can only collide with two things, and they
    ; will always be on different horizontal lines (y values)
    if bally <= 33 then goto __Bug_Collision
    _player3_hits = _player3_hits + 1
    temp4 = ballx - _posx2
    ; do some fun bitmasking to determine what NUSIZ2 should be updated to
    if temp4 < 8 || temp4 > 100 then _player2_hits_left = _player2_hits_left + 1 : _bubble_pop_countdown = 1 : goto update_p2
    if temp4 < 24 then _player2_hits_mid = _player2_hits_mid + 1 : _bubble_pop_countdown = 1 : goto update_p2
    if temp4 < 40 then _player2_hits_right = _player2_hits_right + 1 : _bubble_pop_countdown = 1 : goto update_p2
update_p2
    if _player2_hits_left = 3 && _ns2_index & %00000100 then _ns2_index = _ns2_index & %11111011 : score = score + 10 : _bubble_pop_countdown = 5
    if _player2_hits_mid = 3 && _ns2_index & %00000010 then _ns2_index = _ns2_index & %11111101 : score = score + 10 : _bubble_pop_countdown = 5
    if _player2_hits_right = 3 && _ns2_index & %00000001 then _ns2_index = _ns2_index & %11111110 : score = score + 10 : _bubble_pop_countdown = 5
    if !_ns2_index then _bit4_enemy_state_bools_bubble_dead{4} = 1 : _player3_hits = 0 
    goto __Reset_Missile
__Bug_Mite_Collisions
    if bally > 34 || bally < 20 then goto __Mite_Collision
    ; ********************************************************************************************************
    ; We're defining a very generous bounding box for the beetle here, outside of which we can
    ; comfortably say the stinger has collided with a mite.
    ; If the stinger is inside that bounding box, then we check more closely to see if it's inside a
    ; tight bounding box for the mite.
    ; You may notice that we're only checking ball coordinates despite checking for missile collisions above.
    ; This is for two reasons. One: I can use arithmetic to take care of that tiny discrepancy since they're
    ; right next to each other. The other is more complicated.
    ; I didn't want to check missile collisions at all. My hand was forced because the stinger moves two
    ; units at once while the mite moves one (in the opposite direction), *and* because, when the mite shares
    ; a horizontal line with the beetle, it will only be rendered every other frame. Because the 2600 was only
    ; designed to render two player sprites, everyone who isn't the bee is secretly the same sprite (player1).
    ; Because scanlines are drawn from the top of the screen, this isn't a problem if the sprites are not on
    ; the same scanline. If they are, though, then the multisprite kernel will swap the sprite graphics each
    ; frame and render them alternatingly. Because the 2600's collision detection is based on the graphics
    ; data stored in the Television Interface Adapter registers, this means that we may be checking for
    ; collision on a frame during which the mite isn't actually rendered. During that time, the ball can
    ; move completely past the mite before it renders again. However, the missile should still (barely) be
    ; touching it when it comes back, which will capture that edge case.
    ; Make sense?
    ; ********************************************************************************************************
    if ballx < player3x - 12 then goto __Mite_Collision
    if ballx > player3x + 30 then goto __Mite_Collision
    if ballx < player4x - 5 then goto __Bug_Collision
    if ballx > player4x then goto __Bug_Collision
    if bally > player4y + 1 then goto __Bug_Collision
    if bally < player4y - 4 then goto __Bug_Collision
    goto __Mite_Collision
__Bug_Collision
    _bug_hit_countdown = 20
    _player3_hits = _player3_hits + 1
    goto __Reset_Missile
__Mite_Collision
    score = score + 5
    _mite_hit_countdown = 5
    _player4_hits = _player4_hits + 1 : player4y = 200 : _bit6_enemy_state_bools_mite_dead{6} = 1 : _bit3_enemy_state_bools_mite_attack{3} = 0
__Reset_Missile
    _stinger_in_play = 0 : missile0x = 200 : ballx = 205 : missile0y = 200 : bally = 205
__End_Collision

    ; ***********************************
    ; Player collision logic
    ; ***********************************
    if collision(player0, missile1) && !_player_flicker then lives = lives - 32 : missile1x = 200 : missile1y = 200 : _player_flicker = 120 : _player_hit_countdown = 10
    if collision(player0, player1) && !_player_flicker then lives = lives - 32 : player4y = 200 : _bit6_enemy_state_bools_mite_dead{6} = 1 : _bit3_enemy_state_bools_mite_attack{3} = 0 : _player_flicker = 120 : _player_hit_countdown = 10

    ; On losing last chunk of health, immediately kill the player, we can ignore other logic
    if lives < 32 then _player_lives = _player_lives - 1 : _bubble_pop_countdown = 60 : _Bit4_Bee_Death{4} = 1 : _Bit5_Bee_Death_Sequence{5} = 1 : goto __Reset_Listener

    gosub __Stinger_Sub

    ; ********************************************
    ; Player2 (Bubble) movement and fire behavior
    ; ********************************************
    if _bit4_enemy_state_bools_bubble_dead{4} then player2x = 200 : player2y = 200 : goto __End_Bubble
    NUSIZ2 = ns2[_ns2_index]
    if player2x - pos2[_ns2_index] > 130 then _bit0_enemy_state_bools_bubble_dir{0} = 0
    if player2x - pos2[_ns2_index] < 5 then _bit0_enemy_state_bools_bubble_dir{0} = 1
    if _bit0_enemy_state_bools_bubble_dir{0} then _posx2 = _posx2 + 1 else _posx2 = _posx2 - 1
    player2x = _posx2 + pos2[_ns2_index]

    if missile1y < 200 then goto __End_Bubble_Shoot_Spawn
    temp5 = rand
    ; increase chance to shoot every time the clock resets (and bubbles are fully in play)
    ; from about 70% to 90% as bubbles disappear
    temp4 = 0
    if _ns2_index{0} then temp4 = temp4 + 1
    if _ns2_index{1} then temp4 = temp4 + 1
    if _ns2_index{2} then temp4 = temp4 + 1
    if temp4 > 2 then temp4 = 76 : goto __Bubble_Shoot_Checks
    if temp4 > 1 then temp4 = 50 : goto __Bubble_Shoot_Checks
    temp4 = 25
__Bubble_Shoot_Checks
    if player2x < 30 || player2x > 110 then goto __End_Bubble_Shoot
    if _clock || temp5 < temp4 then goto __End_Bubble_Shoot
    missile1x = player2x + 4 : missile1y = player2y + 1

__End_Bubble_Shoot_Spawn
    missile1y = missile1y + 1
    if missile1y > 90 then missile1x = 200 : missile1y = 200

__End_Bubble_Shoot

__End_Bubble

    ; ********************************************
    ; Player3 (Goon bug) movement and fire behavior
    ; ********************************************
    if _bit4_enemy_state_bools_bubble_dead{4} && _player3_hits > 15 then score = score + 500 : _bit5_enemy_state_bools_bug_dead{5} = 1 : _fanfare_countdown = 100 : _bubble_pop_countdown = 0 : goto __Reset_Listener
    if !_bit4_enemy_state_bools_bubble_dead{4} && _player3_hits > 50 then score = score + 1000 : _bit5_enemy_state_bools_bug_dead{5} = 1 : _fanfare_countdown = 100 : _ _bubble_pop_countdown = 0 : goto __Reset_Listener
    if _bit5_enemy_state_bools_bug_dead{5} then player3x = 200 : player3y = 200 : goto __Reset_Listener
    ; only move the bug every other frame
    if _clock & 1 then goto __Skip_Frame
    if player3x > 90 then _bit1_enemy_state_bools_bug_dir{1} = 0
    if player3x < 50 then _bit1_enemy_state_bools_bug_dir{1} = 1
    if _bit1_enemy_state_bools_bug_dir{1} then player3x = player3x + 1 else player3x = player3x - 1
__Skip_Frame

    ; the beetle only shoots if his drone bubbles are dead
    if !_bit4_enemy_state_bools_bubble_dead{4} then goto __End_Bug_Shoot
    if missile1y < 200 then goto __End_Bug_Shoot_Spawn
    temp5 = rand
    ; roughly 90% chance to shoot every time the clock resets
    if _clock || temp5 > 230 then goto __End_Bug_Shoot
    temp5 = rand
    if temp5 > 128 then missile1x = player3x - 1 else missile1x = player3x + 10
    missile1y = player3y - 4

__End_Bug_Shoot_Spawn
    if _clock & 1 then missile1y = missile1y + 1 else missile1y = missile1y + 2
    if missile1y > 90 then missile1x = 200 : missile1y = 200

__End_Bug_Shoot

__End_Bug

    ; ********************************************
    ; Player4 (Mite) movement
    ; ********************************************
    ; Mite only comes out if bubbles are gone due to 2600 technical
    ; limitations that I don't want to deal with (lol)
    ; I'm also only spawning this bastard 50 times since he's worth points
    ; and I don't want people to just grind points off of him.
    if !_bit4_enemy_state_bools_bubble_dead{4} || _player4_hits > 49 then goto __End_Mite
    if !_bit6_enemy_state_bools_mite_dead{6} then goto __End_Mite_Spawn
    temp5 = rand
    if _clock || temp5 > 230 then goto __End_Mite
    if temp5 > 115 then player4x = 5 : player4y = 14 : _bit2_enemy_state_bools_mite_dir{2} = 1 : _bit6_enemy_state_bools_mite_dead{6} = 0 : goto __End_Mite_Spawn
    player4x = 140 : player4y = 14 : _bit2_enemy_state_bools_mite_dir{2} = 0 : _bit6_enemy_state_bools_mite_dead{6} = 0
__End_Mite_Spawn
    ; Mite moves slightly to the opposite side of the bee from the one it spawned on and dives towards him
    if _bit3_enemy_state_bools_mite_attack{3} then player4y = player4y + 1 : goto __End_Mite_Movement
    if _bit2_enemy_state_bools_mite_dir{2} then goto __End_Mite_Move_Left
    if player4x > player0x then player4x = player4x - 2 else _bit3_enemy_state_bools_mite_attack{3} = 1
    goto __End_Mite_Movement
__End_Mite_Move_Left
    if player4x < player0x + 13 then player4x = player4x + 2 else _bit3_enemy_state_bools_mite_attack{3} = 1
__End_Mite_Movement
    ; "kill" the mite if it passes the bee
    if player4y > 90 then player4y = 200 : _bit6_enemy_state_bools_mite_dead{6} = 1 : _bit3_enemy_state_bools_mite_attack{3} = 0
__End_Mite

__Reset_Listener

    ; ********************************************
    ; The usual reset switch logic at the end of
    ; the game loop where it belongs.
    ; ********************************************
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto gameloop
    if _Bit0_Reset_Restrainer{0} then goto gameloop
    goto __Start_Restart

__Game_Over_Loop
    drawscreen
    ; mute sounds
    AUDC0 = 0 : AUDV0 = 0 : AUDF0 = 0
    AUDC0 = 0 : AUDV0 = 0 : AUDF0 = 0
    ; wait for a button press to return to gameplay.
    if joy0fire then goto __Start_Restart
    ; reset check
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto __Game_Over_Loop
    if _Bit0_Reset_Restrainer{0} then goto __Game_Over_Loop
    goto __Start_Restart

__Stinger_Sub
    ; ***********************************
    ; Player control logic
    ; ***********************************
    if joy0left && player0x > 20 then player0x = player0x - 1
    if joy0right && player0x < 130 then player0x = player0x + 1

    ; ****************************************************
    ; Stinger movement logic
    ;
    ; The stinger is composed of the ball and missile0.
    ; This is because using a player sprite would make
    ; collision detection much more annoying.
    ; ****************************************************
    if _stinger_in_play = 0 then goto __End_Stinger_Movement
    missile0y = missile0y - 2 : bally = bally - 2
    if missile0y < 5 then _stinger_in_play = 0 : missile0x = 200 : ballx = 200 : missile0y = 200 : bally = 200
    goto __End_Stinger
__End_Stinger_Movement

    if !joy0fire then goto __End_Stinger
    _stinger_in_play = 1
    missile0x = player0x + 3
    missile0y = player0y - 8
    ballx = player0x + 4
    bally = player0y - 9

__End_Stinger
    return

__Bee_Death_Anim_Sub
    AUDV0 = 0
    _bubble_pop_countdown = _bubble_pop_countdown - 1
    if _bubble_pop_countdown < 40 then goto __Bee_Death_Frame_2
    AUDC1 = 4 : AUDV1 = 4 : AUDF1 = 10
    player0:
    %00011000
    %00111100
    %01000010
    %11111111
    %01000010
    %00111100
    %00111100
    %00111100
    %01000010
end
    goto __End_Bee_Death_Anim_Frames
__Bee_Death_Frame_2
    if _bubble_pop_countdown < 20 then goto __Bee_Death_Frame_3
    AUDC1 = 4 : AUDV1 = 4 : AUDF1 = 15
    player0:
    %00111100
    %00111100
    %00000000
    %00000000
    %00000000
    %00000000
end
    goto __End_Bee_Death_Anim_Frames
__Bee_Death_Frame_3
    AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 28
    player0:
    %10000001
    %01000010
    %00100100
    %00000000
    %00000000
    %11100111
    %00000000
    %00000000
    %00100100
    %01000010
    %10000001
end
__End_Bee_Death_Anim_Frames
    if _bubble_pop_countdown then pop : goto __Reset_Listener
    AUDV1 = 0
    if _player_lives < 1 then pop : goto __Game_Over_Loop
    _Bit5_Bee_Death_Sequence{5} = 0
    return

__Bee_Death_Sub
    _stinger_in_play = 0 : missile0x = 200 : ballx = 200 : missile0y = 200 : bally = 200
    _player_flicker = 0
    NUSIZ1 = $30
    player2y = 200
    player3y = 200
    player4y = 200
    missile0y = 200
    missile1y = 200
    bally = 200
    player4y = 200
    ; reusing this var because I'm running out lol
    _bubble_pop_countdown = _bubble_pop_countdown - 1

    ;  Defines shape of player1 sprite (a one)
    if _player_lives > 1 then goto __Skip_One
    player1:
    %11111110
    %00010000
    %00010000
    %00010000
    %10010000
    %01010000
    %00110000
end

    goto __Skip_Two
__Skip_One

    ;  Defines shape of player1 sprite (a two)
    player1:
    %11111110
    %10000000
    %10000000
    %11111110
    %00000010
    %00000010
    %11111110
end

__Skip_Two

    player0x = 65
    player0y = 55
    player1x = player0x + 25
    player1y = player0y - 5

    if _bubble_pop_countdown then pop : goto __Reset_Listener
    player1x = 200
    player1y = 200
    _Bit4_Bee_Death{4} = 0
    _Bit6_Life_Loss_Reset{6} = 1
    pop : goto __Reset_Listener
    ; guess it shouldn't ever be possible to get here? lol?
    return

    ; data table containing values to set NUSIZ2 to after a collision with the stinger
    ; depending on which sprite copy was hit
    data ns2
    $20, $20, $20, $21, $20, $22, $21, $23
end

    ; data table containing values to offset player2 position by depending on
    ; if any of the sprite dupes have been shot so far
    data pos2
    $00, $20, $10, $10, $00, $00, $00, $00
end
    ; ******************************
    ; We're bankswitching, baby!
    ; This is pretty much just here
    ; to hold graphics and things of
    ; that nature, but it sure saves
    ; a lot of space for bank 1
    ; ******************************
    bank 2
    inline 6lives.asm

        ;********************************************************
    ; Here's where Stage 2 game logic goes
    ; You will probably notice some duplicated
    ; code. That's because I thought it would
    ; be easier than trying to weave stage 2
    ; logic into stage 1 logic, especially since
    ; some variables are borrowed and things of
    ; that nature. Maybe I could've used subroutines idk
    ; But we're racing the beam here, so cycles are precious!
    ;********************************************************
__Stage_2_Start

    _Boss_Anim_Counter = _Boss_Anim_Counter + 1
    if _Boss_Anim_Counter > 10 then _Boss_Anim_Counter = 0

    if _boss_hits > 11 then goto __Mid_Boss_Sprites

    if _Boss_Anim_Counter > 5 then goto __Boss_Anim_Frame_2

    player2:
    %10000001
    %01111110
    %11111111
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01010010
    %10001001
    %10010001
    %01001010
    %00111100
end
    goto __End_Boss_Anim

__Boss_Anim_Frame_2 

    player2:
    %10000001
    %01111110
    %11111111
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01011010
    %10100101
    %10100101
    %01000010
    %00100100
end
    goto __End_Boss_Anim

__Mid_Boss_Sprites

    if _boss_hits > 23 then goto __End_Boss_Sprites

    if _Boss_Anim_Counter > 5 then goto __Mid_Boss_Anim_Frame_2

    player2:
    %10000001
    %01111110
    %11111111
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01010010
    %10001001
    %10010001
    %01001010
    %00111100
end
    goto __End_Boss_Anim

__Mid_Boss_Anim_Frame_2

    player2:
    %10000001
    %01111110
    %11111111
    %11111111
    %11111111
    %11111111
    %01111110
    %10111101
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01011010
    %10100101
    %10100101
    %01000010
    %00100100
end
    goto __End_Boss_Anim

__End_Boss_Sprites

    if _Boss_Anim_Counter > 5 then goto __End_Boss_Anim_Frame_2

    player2:
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01010010
    %10001001
    %10010001
    %01001010
    %00111100
end
    goto __End_Boss_Anim
__End_Boss_Anim_Frame_2

    player2:
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
    %00111100
    %01011010
    %10100101
    %10100101
    %01000010
    %00100100
end

__End_Boss_Anim

    if _bit3_enemy_state_bools_boss_dead{3} then goto __Spider_Skip
    ; Spider grunt sprite
    player3:
    %10011001
    %10100101
    %01111110
    %01011010
    %00111100
    %01011010
    %11000010
    %00000001
end

__Spider_Skip

    if _bubble_pop_countdown < 6 || !_bit3_enemy_state_bools_boss_dead{3} then goto __Skip_Sprite_Swap
    player2:
    %01111110
    %11111111
    %11011011
    %10111101
    %01111110
end

    player3:
    %00111100
    %01011010
    %10100101
    %10100101
    %01000010
    %00100100
end

__Skip_Sprite_Swap

    ; Boss projectile sprite
    player4:
    %01000010
    %11000011
    %11000011
    %11100111
    %11011111
    %01101110
    %00111100
end
    ; Crown Sprite
    player5:
    %01111110
    %11111111
    %10100101
    %01011010
    %00011000
end

    ; color of playfield and ball (yellow, beehive)
    COLUPF = $18
    ; 1 copy of player0 and 4 pixel wide missile
    NUSIZ0 = $20
    NUSIZ1 = $30
    ; color of missile (purple to match spider)
    COLUP1 = $4C
    ; color of boss (black)
    COLUP2 = $00
    ; color of player 3 (spider, purple)
    COLUP3 = $4C
    ; color of player4 (boss attack, white)
    COLUP4 = $0E
    ; color of player5 (crown, same as bee)
    COLUP5 = $1C
    NUSIZ2 = $35
    if _clock & 1 then NUSIZ3 = $30 else NUSIZ3 = $30 | 8
    if _bit3_enemy_state_bools_boss_dead{3} then NUSIZ3 = $35 : COLUP3 = $00
    NUSIZ4 = $30

    ; color of lives indicator (yellow)
    lifecolor = $1C

    ; fills in the side boundaries with color
    PF0 = %11110000

    drawscreen

    if !_Bit7_Stage_2_Init{7} then goto __Skip_Init
    _bubble_pop_countdown = 0
    _bitop_enemy_state_bools = 0
    if player2y < 30 then player2y = player2y + (_clock & 1) : goto __Reset_Listener bank1
    _Bit7_Stage_2_Init{7} = 0
    _clock = 1
    _Bit3_Stage_2{3} = 1
__Skip_Init

    ;************************************************
    ; Reset character positions and things of that
    ; nature after a player respawns
    ;************************************************
    if !_Bit6_Life_Loss_Reset{6} then goto __Skip_Life_Reset_Stage_2
    _clock = 1
    _player_hit_countdown = 0
    _stinger_in_play = 0 : missile0x = 200 : ballx = 205 : missile0y = 200 : bally = 205
    bally = 200
    missile0y = 200
    if !_bit5_enemy_state_bools_boss_low_dead{5} then player2x = 65 : player2y = 44 else player2x = 77 : player2y = 12
    player3y = 200 : player3x = 200
    _bit2_enemy_state_bools_spider_dead{2} = 1
    player0x = 70
    player0y = 90
    lives = 96
    _Bit6_Life_Loss_Reset{6} = 0
__Skip_Life_Reset_Stage_2

    ;*********************************************
    ; little death anim/sfx for when the Bee dies
    ;*********************************************
    if _Bit5_Bee_Death_Sequence{5} then gosub __Bee_Death_Anim_Sub bank1

    ; we can just continue to the "lives left" screen from here as long
    ; as I don't fuck up and put anything else between here

    if _Bit4_Bee_Death{4} then gosub __Bee_Death_Sub bank1

    if !_bit3_enemy_state_bools_boss_dead{3} then goto __Skip_Boss_Death
    player4x = 200 : player4y = 200
    ; reusing this again to save vars
    if !_boss_hit_countdown then _bubble_pop_countdown = _bubble_pop_countdown + 1 : _boss_hit_countdown = 20
    
    if _bubble_pop_countdown > 5 then goto __Explode_Him_Stage_2
    if _boss_hit_countdown then _boss_hit_countdown = _boss_hit_countdown - 1 : AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 20 - _boss_hit_countdown else AUDV1 = 0
    goto __Reset_Listener bank1
__Explode_Him_Stage_2
    _bug_hit_countdown = _bug_hit_countdown - 1
    AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 20 - _boss_hit_countdown
    if _bubble_pop_countdown > 5 && _bubble_pop_countdown < 7 then player3x = player2x : player3y = player2y + 5 : player5x = player2x : player5y = player2y
    if player2y > 0 then player2y = player2y - 1
    if player3y < 100 then player3y = player3y + 2
    if player2y > 0 || player3y < 100 then goto __Reset_Listener bank1
__Collect_Crown
    AUDV1 = 0
    if player0x < player5x - 8 then player0x = player0x + 1 : goto __Reset_Listener bank1
    if player0x > player5x - 8 then player0x = player0x - 1 : goto __Reset_Listener bank1
    if player0y > player5y - 2 then player0y = player0y - 1 : goto __Reset_Listener bank1
    if _fanfare_countdown > 90 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 25 : goto __Reset_Listener bank1
    if _fanfare_countdown > 80 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 26 : goto __Reset_Listener bank1
    if _fanfare_countdown > 70 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 25 : goto __Reset_Listener bank1
    if _fanfare_countdown > 0 then _fanfare_countdown = _fanfare_countdown - 1 : AUDC0 = 4 : AUDV0 = 4 : AUDF0 = 20 : goto __Reset_Listener bank1
    AUDV0 = 0
    player3x = 200 : player3y = 200
    player2x = 75 : player2y = 0
    ; just in case
    _Bit3_Stage_2{3} = 0
    ; todo add loop bool
    goto __Reset_Listener bank1
__Skip_Boss_Death

    if _player_hit_countdown then _spider_hit_countdown = 0 : _player_hit_countdown = _player_hit_countdown - 1 : AUDC0 = 8 : AUDV0 = 2 : AUDF0 = _player_hit_countdown : goto __End_Spider_Sound
    if _spider_hit_countdown then _spider_hit_countdown = _spider_hit_countdown - 1 : AUDC0 = 7 : AUDV0 = 14 : AUDF0 = 5 - _spider_hit_countdown else AUDV0 = 0
__End_Spider_Sound
    if _boss_hit_countdown then _boss_hit_countdown = _boss_hit_countdown - 1 : AUDC1 = 8 : AUDV1 = 2 : AUDF1 = 20 - _boss_hit_countdown else AUDV1 = 0 

    ; **************************
    ; Collision logic
    ; **************************
    if !collision(ball, player1) then goto __Skip_Stage_2_Collision
    ; like above, we're gonna try to make the edge cases the very last
    ; things we check. If there's only one thing it could've hit, that's
    ; what it hit!
    if bally <= player2y + 1 then goto __Boss_Collision
    if player4y > 199 && _bit2_enemy_state_bools_spider_dead{2} then goto __Boss_Collision
    if player4y < 90 && !_bit2_enemy_state_bools_spider_dead{2} then goto __Annoying_Check
    if player4y > 199 && !_bit2_enemy_state_bools_spider_dead{2} then goto __Spider_Boss_Check
    ; if we're here, then the situation is that the only two enemy sprites on the screen
    ; are the boss and his attack. If this is the case, the above y check will have satisfied
    ; whether or not it hit the boss. It hasn't, and the stinger should just pass through
    ; the attack, so we can skip.
    goto __Skip_Stage_2_Collision
__Spider_Boss_Check
    if bally < 35 then goto __Boss_Collision else goto __Spider_Collision
__Annoying_Check
    ; if we're here, then everything's alive, so BUT we're not at or below the top of the boss, so
    ; we know it is either hitting the boss's attack or the spider, so just check the spider's bounding box
    ; also, since the stinger should just pass through the boss's attack, there aren't significant
    ; ramifications of getting this wrong. A subsequent check should get it right.
    if bally <= player3y - 7 then goto __Skip_Stage_2_Collision
    if bally >= player3y + 2 then goto __Skip_Stage_2_Collision
    if ballx <= player3x - 9 then goto __Skip_Stage_2_Collision
    if ballx >= player3x + 1 then goto __Skip_Stage_2_Collision
    ; if none of those are true, then it hit the spider
__Spider_Collision
    score = score + 50
    _spider_hit_countdown = 10
    player3x = 200 : player3y = 200 : _bit2_enemy_state_bools_spider_dead{2} = 1
    goto __Reset_Stinger_Stage_2
__Boss_Collision
    _boss_hit_countdown = 20
    _boss_hits = _boss_hits + 1
    if _boss_hits > 11 && !_bit4_enemy_state_bools_boss_mid_dead{4} then _bit4_enemy_state_bools_boss_mid_dead{4} = 1 : score = score + 250
    ; could make this fancier, but for now initiating phase 3 as a one-liner
    if _boss_hits > 23 && !_bit5_enemy_state_bools_boss_low_dead{5} then _bit5_enemy_state_bools_boss_low_dead{5} = 1 : player2x = 77 : player2y = 12 : player3x = 200 : player3y = 200 : score = score + 500
    ; if we beat the boss, we will immediately go to the victory sequence. If he got the last hit against the player at the same time, the tie goes to the player. :)
    ; killing the boss is the only thing that increments the ones digit of the score, so players can more easily track how many loops they've completed.
    if _boss_hits > 36 then _bit3_enemy_state_bools_boss_dead{3} = 1 : score = score + 1001 : _fanfare_countdown = 100 : goto __Reset_Listener bank1
__Reset_Stinger_Stage_2
    _stinger_in_play = 0 : missile0x = 200 : ballx = 205 : missile0y = 200 : bally = 205
__Skip_Stage_2_Collision

    if collision(player0, missile1) && !_player_flicker then lives = lives - 32 : missile1x = 200 : missile1y = 200 : _player_flicker = 120 : _player_hit_countdown = 10
    if collision(player0, player1) && !_player_flicker then lives = lives - 32 : player4y = 200 : _player_flicker = 120 : _player_hit_countdown = 10

    if lives < 32 then _player_lives = _player_lives - 1 : _bubble_pop_countdown = 60 : _Bit4_Bee_Death{4} = 1 : _Bit5_Bee_Death_Sequence{5} = 1 : goto __Reset_Listener bank1

    gosub __Stinger_Sub bank1

    if missile1y < 90 then missile1y = missile1y + 1 else missile1y = 200
    if player4y > 90 then player4y = 200 : goto __Skip_Boss_Attack
    if !(_clock & 1) then goto __Skip_Boss_Attack
    player4y = player4y + 3
    ; this is equivalent to some sort of modulo I think
    if !(_clock & %00000110) then goto __Skip_Boss_Attack
    if player4x < player0x + 3 then player4x = player4x + 1
    if player4x > player0x + 3 then player4x = player4x - 1
__Skip_Boss_Attack

    ; ********************************************
    ; Player4 (Spider) movement
    ; ********************************************
    ; Spider flies across the screen and shoots
    ; when he is directly under the player
    if _boss_hits > 23 then goto __End_Spider ; spider won't spawn during boss's final phase
    if !_bit2_enemy_state_bools_spider_dead{2} then goto __End_Spider_Spawn
    temp5 = rand
    if _clock || temp5 > 130 then goto __End_Spider
    if temp5 > 65 then player3x = 5 : player3y = 44 : _bit0_enemy_state_bools_spider_dir{0} = 1 : _bit2_enemy_state_bools_spider_dead{2} = 0 : goto __End_Spider_Spawn
    player3x = 147 : player3y = 44 : _bit0_enemy_state_bools_spider_dir{0} = 0 : _bit2_enemy_state_bools_spider_dead{2} = 0
__End_Spider_Spawn
    ; Spider moves to side of bee and shoots
    if _bit0_enemy_state_bools_spider_dir{0} then goto __End_Spider_Move_Left
    player3x = player3x - 2
    if player3x < player0x - 3 && player3x > 20 && missile1y > 90 then missile1x = player3x - 2 : missile1y = player3y
    goto __End_Spider_Movement
__End_Spider_Move_Left
    player3x = player3x + 2
    if player3x > player0x + 13 && player3x < 130 && missile1y > 90 then missile1x = player3x - 2 : missile1y = player3y
__End_Spider_Movement
    if player3x < 5 || player3x > 147 then _bit2_enemy_state_bools_spider_dead{2} = 1
__End_Spider

    if _boss_hits < 24 then goto __Early_Phases
    if _boss_corner_countdown then _boss_corner_countdown = _boss_corner_countdown - 1 : goto __Reset_Listener bank1
    ; move in a diamond shape and shoot at each corner
    temp5 = (rand & %00000010)
    temp4 = (rand & %01000000)
    if !_bit1_enemy_state_bools_boss_dir{1} && player2x < 48 then player2x = 48 : _boss_corner_countdown = 20 : player4x = player2x + 3 : player4y = player2y : _bit1_enemy_state_bools_boss_dir{1} = 1 : _bit6_enemy_state_bools_boss_dir_y ^ temp4 : goto __Reset_Listener bank1
    if _bit1_enemy_state_bools_boss_dir{1} && player2x > 106 then player2x = 106 : _boss_corner_countdown = 20 : player4x = player2x + 3 : player4y = player2y : _bit1_enemy_state_bools_boss_dir{1} = 0 : _bit6_enemy_state_bools_boss_dir_y ^ temp4 : goto __Reset_Listener bank1
    if _bit6_enemy_state_bools_boss_dir_y{6} && player2y > 70 then player2y = 70 : _boss_corner_countdown = 20 : player4x = player2x + 3 : player4y = player2y : _bit6_enemy_state_bools_boss_dir_y{6} = 0 : _bit1_enemy_state_bools_boss_dir ^ temp5 : goto __Reset_Listener bank1
    if !_bit6_enemy_state_bools_boss_dir_y{6} && player2y < 12 then player2y = 12 : _boss_corner_countdown = 20 : player4x = player2x + 3 : player4y = player2y : _bit6_enemy_state_bools_boss_dir_y{6} = 1 : _bit1_enemy_state_bools_boss_dir ^ temp5 : goto __Reset_Listener bank1
    if _bit1_enemy_state_bools_boss_dir{1} then player2x = player2x + 1 else player2x = player2x - 1
    if _bit6_enemy_state_bools_boss_dir_y{6} then player2y = player2y + 1 else player2y = player2y - 1
    goto __Reset_Listener bank1
__Early_Phases

    ; *************************************
    ; Boss movement and fire behavior
    ; Boss exists in three phases, during which
    ; the segments of his body are removed
    player2y = 30 ; todo add offset
    if _boss_hits > 11 then player2y = player2y - 6
    if player2x < 55 then _bit1_enemy_state_bools_boss_dir{1} = 1
    if player2x > 100 then _bit1_enemy_state_bools_boss_dir{1} = 0
    if _clock & 1 && _boss_hits < 12 then goto _Skip_Boss_Move ; boss speeds up when he is made of a head and one body segment
    if _bit1_enemy_state_bools_boss_dir{1} then player2x = player2x + 1 else player2x = player2x - 1
_Skip_Boss_Move
    temp5 = rand
    if _clock > 29 && _clock < 31 && temp5 < 150 && player4y > 90 then player4x = player2x : player4y = player2y
__End_Boss_Move
    goto __Reset_Listener bank1