    set romsize 4k
    set kernel multisprite
    set kernel_options pfcolors
    set optimization speed
    set optimization inlinerand
    set tv ntsc

__Start_Restart

    ; clear audio
    AUDV0 = 0 : AUDV1 = 0

    ;  Clears all normal variables and the extra 9.
    ;  We don't clear z because it's used for the RNG
    a = 0 : b = 0 : c = 0 : d = 0 : e = 0 : f = 0 : g = 0 : h = 0 : i = 0
    j = 0 : k = 0 : l = 0 : m = 0 : n = 0 : o = 0 : p = 0 : q = 0 : r = 0
    s = 0 : t = 0 : u = 0 : v = 0 : w = 0 : x = 0 : y = 0

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

    ; background color (black)
    COLUBK = $F4
    ; two-pixel wide ball and normal, and players move under playfield
    CTRLPF = $15
    scorecolor = $1C
    ; reset score
    score = 0

    ; require the fire button to be pressed to start the game
    dim _game_started = w

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

    ; variable for toggling wing flap
    dim _flap = e

    ; initial position of player character
    player0x = 70
    player0y = 90

    ; TODO: set offscreen
    player2x = 60
    player2y = 44

    ; TODO: set offscreen
    player3x = 100
    player3y = 32

    pfheight = 1

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
    %0110110
    %0100010
    %0100010
    %0011100
    %0010100
    %0100010
    %1111111
    %1011101
    %0010100
    %0100010
    %0100010
    %0010100
end

    ; Defines shape of player4 sprite (stinger)
    player4:
    %001100
    %011110
    %111111
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

    if _flap > 0 then goto __Down_Flap

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

    _flap = 1

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

    _flap = 0

__End_P0_Anim

    ; color of playfield and ball (pink)
    COLUPF = $18
    ; color of player (and missile) 0 (yellow, bee)
    COLUP0 = $1C
    ; 1 copy of player0 and 4 pixel wide missile
    NUSIZ0 = $20
    ; 1 copy of player0 and 2 pixel wide missile
    NUSIZ1 = $30
    ; color of player (and missile) 1 (grayish)
    COLUP1 = $1C
    ; color of player 2 (cyan, bubble)
    COLUP2 = $AE
    ; color of player 3 (green, bad bug)
    COLUP3 = $C8
    ; color of player 4 (yellow, stinger)
    COLUP4 = $1C

    PF0 = %11110000

    drawscreen

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
    
    NUSIZ3 = $05

    ; ********************************************
    ; Tons of collision logic
    ; ********************************************
    if !collision(ball, player1) && !collision(missile0, player1) then goto __No_Collision
    if bally < 40  || bally > 43 then goto __No_Collision
    ;score = score + 1
    temp4 = ballx - _posx2
    ; do some fun bitmasking to determine what NUSIZ2 should be updated to
    if temp4 < 8 || temp4 > 100 then _ns2_index = _ns2_index & %11111011 : goto update_p2
    if temp4 < 24 then _ns2_index = _ns2_index & %11111101 : goto update_p2
    if temp4 < 40 then _ns2_index = _ns2_index & %11111110 : goto update_p2
update_p2
    _stinger_in_play = 0 : missile0x = 200 : ballx = 200 : missile0y = 200 : bally = 200
    if !_ns2_index then score = score + 1 : _bit4_enemy_state_bools_bubble_dead{4} = 1 

__No_Collision

    ; ********************************************
    ; Player2 (Bubble) movement
    ; ********************************************
    if _bit4_enemy_state_bools_bubble_dead{4} then player2x = 200 : player2y = 200 : goto __End_Bubble
    NUSIZ2 = ns2[_ns2_index]
    if player2x - pos2[_ns2_index] > 130 then _bit0_enemy_state_bools_bubble_dir{0} = 0
    if player2x - pos2[_ns2_index] < 5 then _bit0_enemy_state_bools_bubble_dir{0} = 1
    if _bit0_enemy_state_bools_bubble_dir{0} then _posx2 = _posx2 + 1 else _posx2 = _posx2 - 1
    player2x = _posx2 + pos2[_ns2_index]

__End_Bubble

    goto gameloop

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