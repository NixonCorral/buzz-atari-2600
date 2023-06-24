    include 6lives.asm
    set romsize 4k
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
    ;  Var for reset switch that allows us to prevent constant
    ;  resets if the switch is held for multiple frames
    ;  A second bit is used to determine if fire has been
    ;  pressed to start the game
    dim _Bit0_Reset_Restrainer = r
    dim _Bit1_Fire_Starter = r

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

    ; the mite is considered "dead" to start the game
    _bit6_enemy_state_bools_mite_dead{6} = 1

    ; vars to count how many times 
    dim _player2_hits_left = j
    dim _player2_hits_mid = l
    dim _player2_hits_right = n
    dim _player3_hits = o
    dim _player4_hits = p

    ; background color (black)
    COLUBK = $F4
    ; two-pixel wide ball and normal, and players move under playfield
    CTRLPF = $15
    scorecolor = $1C
    ; reset score
    score = 0

    ; require the fire button to be pressed to start the game
    dim _game_started = w
    _game_started = w

    ; index into arrays that determine player2 (bubble) visibility state
    dim _ns2_index = h
    _ns2_index = %00000111
    ; holds the "original" x position of player2 so it can be offset if one of them is shot
    dim _posx2 = i
    _posx2 = 60

    ; variable for time since fire was released (so players can't spam)
    dim _stinger_in_play = a

    ; variables for which game mode we're on and how long it's been since we pushed select
    dim _Mode_Val = b
    dim _Select_Counter = m

    ; best practice dictates that if mode select is open for 30 seconds or so, return to Idle state
    dim _Mode_Select_Idle_Frames = c
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

    ; TODO: set offscreen
    player2x = 60
    player2y = 44

    ; TODO: set offscreen
    player3x = 50
    player3y = 32

    pfheight = 1

    ; initiate lives to 3 and use the compact spacing
    ; lives vars are used by the 6lives minikernel included above
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
    %0010100
    %0100010
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

    _clock = _clock + 1
    if _clock > 59 then _clock = 0

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

    ; color of playfield and ball (pink)
    COLUPF = $18
    ; color of player (and missile) 0 (yellow, bee)
    COLUP0 = $1C
    ; 1 copy of player0 and 4 pixel wide missile
    NUSIZ0 = $20
    ; 1 copy of player1 and 2 pixel wide missile
    if _bit4_enemy_state_bools_bubble_dead{4} then NUSIZ1 = $30 else NUSIZ1 = ns2[_ns2_index]
    ; color of player (and missile) 1 (cyan)
    COLUP1 = $AE
    ; color of player 2 (cyan, bubble)
    COLUP2 = $AE
    ; color of player 3 (green if protected, red if not, bad bug)
    if !_bit4_enemy_state_bools_bubble_dead{4} then COLUP3 = $CC else COLUP3 = $36
    ; color of player 4 (black, mite)
    COLUP4 = $00
    NUSIZ4 = $30
    ; color of lives indicator (yellow)
    lifecolor = $1C

    ; fills in the side boundaries with color
    PF0 = %11110000

    drawscreen

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
    if temp4 < 8 || temp4 > 100 then _player2_hits_left = _player2_hits_left + 1 : goto update_p2
    if temp4 < 24 then _player2_hits_mid = _player2_hits_mid + 1 : goto update_p2
    if temp4 < 40 then _player2_hits_right = _player2_hits_right + 1 : goto update_p2
update_p2
    if _player2_hits_left = 3 then _ns2_index = _ns2_index & %11111011
    if _player2_hits_mid = 3 then _ns2_index = _ns2_index & %11111101
    if _player2_hits_right = 3 then _ns2_index = _ns2_index & %11111110
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
    _player3_hits = _player3_hits + 1
    goto __Reset_Missile
__Mite_Collision
    _player4_hits = _player4_hits + 1 : player4y = 200 : _bit6_enemy_state_bools_mite_dead{6} = 1 : _bit3_enemy_state_bools_mite_attack{3} = 0
__Reset_Missile
    _stinger_in_play = 0 : missile0x = 200 : ballx = 205 : missile0y = 200 : bally = 205
__End_Collision

    ; ***********************************
    ; Player collision logic
    ; ***********************************
    if collision(player0, missile1) then lives = lives - 32 : missile1x = 200 : missile1y = 200 ; todo: damage animation/flicker? invincible frames?
    if collision(player0, player1) then lives = lives - 32 : player4y = 200 : _bit6_enemy_state_bools_mite_dead{6} = 1 : _bit3_enemy_state_bools_mite_attack{3} = 0

    ; TODO death sequence/game over on player death


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
    ; roughly 35% chance to shoot every time the clock resets and bubbles are fully in play
    if player2x < 30 || player2x > 110 then goto __End_Bubble_Shoot
    if _clock || temp5 < 166 then goto __End_Bubble_Shoot
    missile1x = player2x + 4 : missile1y = player2y + 1

__End_Bubble_Shoot_Spawn
    missile1y = missile1y + 1
    if missile1y > 90 then missile1x = 200 : missile1y = 200

__End_Bubble_Shoot

__End_Bubble

    ; ********************************************
    ; Player3 (Big bug) movement and fire behavior
    ; ********************************************
    if _bit4_enemy_state_bools_bubble_dead{4} && _player3_hits > 10 then player3x = 200 : player3y = 200 : goto __End_Bug ; todo make this actually end Stage 1
    if !_bit4_enemy_state_bools_bubble_dead{4} && _player3_hits > 50 then player3x = 200 : player3y = 200 : goto __End_Bug
    if _bit5_enemy_state_bools_bug_dead{5} then player3x = 200 : player3y = 200 : goto __End_Bug
    ; make the bug's feet move once per second
    if !_clock then _bit7_enemy_state_bools_bug_step{7} = !_bit7_enemy_state_bools_bug_step{7}
    if _bit7_enemy_state_bools_bug_step{7} then NUSIZ3 = $37 else NUSIZ3 = $37 | 8
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
    ; roughly 65% chance to shoot every time the clock resets
    if _clock || temp5 > 166 then goto __End_Bug_Shoot
    temp5 = rand
    if temp5 > 128 then missile1x = player3x - 4 else missile1x = player3x + 18
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

    ; ********************************************
    ; The usual reset switch logic at the end of
    ; the game loop where it belongs.
    ; ********************************************
    if !switchreset then _Bit0_Reset_Restrainer{0} = 0 : goto gameloop
    if _Bit0_Reset_Restrainer{0} then goto gameloop
    goto __Start_Restart

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