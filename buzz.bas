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

    dim _Bit0_Reset_Restrainer = r

    ; background color (black)
    COLUBK = $01
    ; two-pixel wide ball and normal, single-color batariBasic playfield
    CTRLPF = $11
    scorecolor = $1C
    ; reset score
    score = 0


    ; require the fire button to be pressed to start the game
    dim _game_started = w

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
    player2x = 25
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
    %0111111
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
    COLUPF = $16
    ; color of player (and missile) 0 (yellow, bee)
    COLUP0 = $1C
    ; color of player (and missile) 1 (grayish)
    COLUP1 = $0A
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

    if joy0left then player0x = player0x - 1
    if joy0right then player0x = player0x + 1

    if _stinger_in_play = 0 then goto __End_Stinger_Movement
    player4y = player4y - 1
    if player4y < 5 then _stinger_in_play = 0 : player4x = 5
    goto __End_Stinger
__End_Stinger_Movement

    if !joy0fire then goto __End_Stinger
    _stinger_in_play = 1
    player4x = player0x + 7
    player4y = player0y - 8
    goto __End_Stinger

__End_Stinger

    if player0x < 20 then player0x = 20
    if player0x > 130 then player0x = 130

    ; ********************************************
    ; Player2 (Bubble) Spawn/Behavior Routine
    ; ********************************************
    NUSIZ2 = $03
    ;player2x = player2x + 1
    NUSIZ3 = $05

__End_Bubble

    goto gameloop