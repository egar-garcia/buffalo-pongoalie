  rem Buffalo Pongoalie (Extended)
  rem Author: Egar Garcia
  rem Last Revision 2024-06-18

  include div_mul.asm
  include div_mul16.asm

  set kernel_options player1colors playercolors pfcolors
  set tv ntsc
  set romsize 8k
  set smartbranching on


  const INITIALIZING          =   0
  const SELECT_PRESSED        =   1
  const RESET_PRESSED         =   2
  const MODE_SELECT           =   3
  const IN_PROGRESS           =   4
  const ENDED                 =   5

  const MIN_BALLX             =  22
  const MAX_BALLX             = 141
  const MIN_BALLY             =  16
  const MAX_BALLY             =  79

  const MID_BALLX             =  81
  const MID_BALLY             =  48

  const POWERBALLCYCLES       =  50

  const MIN_PX                =  21
  const MAX_PX                = 133
  const MIN_PY                =  27
  const MAX_PY                =  80

  const P_WIDTH               =   8
  const P_HEIGHT              =  12

  const INIT_P0X              =  31
  const INIT_P0Y              =  54
  const INIT_P1X              = 123
  const INIT_P1Y              =  54

  const P_MAX_FIRECYCLES      =  30

  const P_COLLISION_TOLERANCE =   3
  const PUSH_DISPLACEMENT     =   1
  const HIT_DISPLACEMENT      =   5

  const CPU_ADVACE_RANDOMNESS =   7
  const CPU_ADVACE_THESHOLD   =   5
  const CPU_DISTANCE_HIT      =   5

  const FORWARD               = $01
  const BACKWARD              = $FF
  const NO_MOVE               = $00

  const GOAL_NO_CYCLES        =  90

  const KICKOFF_DIST          =  15

  const NUM_MAX_SCORE_MODES   =   7
  const NUM_GOAL_SIZE_MODES   =   4


  dim   gamestate             =   a

  dim   max_score_mode        =   b
  dim   goal_size_mode        =   c

  dim   max_score             =   d

  dim   goalcyclecounter      =   e

  dim   balldx                =   f
  dim   balldy                =   g
  dim   powerballcycle        =   h

  dim   p0dx                  =   i
  dim   p0dy                  =   j
  dim   p0firecycle           =   k
  dim   p0frm                 =   l
  dim   p0score               =   m

  dim   p1dx                  =   n
  dim   p1dy                  =   o
  dim   p1firecycle           =   p
  dim   p1frm                 =   q
  dim   p1score               =   r

  dim   playerkickoff         =   s

  dim   aud0timer             =   t
  dim   aud1timer             =   u

  dim   tmp0                  =   v
  dim   tmp1                  =   w

  dim   param0                =   x
  dim   param1                =   y
  dim   param2                =   z


  data max_scores
    5, 7, 9, 11, 21, 1, 3
end

  data min_goal_limits
  40, 32, 24, 16
end

  data max_goal_limits
  55, 63, 71, 79 
end


  rem Going to the title screen
  goto title_screen bank2


  rem ************************************************************
  rem * MAIN GAME
  rem ************************************************************

main_game
  gosub clear_sounds
  gosub stop_game
  gamestate = INITIALIZING
  max_score_mode = 0
  goal_size_mode = 0
  gosub set_mode


main_loop
  gosub handle_sounds
  if gamestate = INITIALIZING then gosub handle_initializing : goto mainloop_draw_screen
  if gamestate = SELECT_PRESSED then gosub handle_select_pressed : goto mainloop_draw_screen
  if gamestate = RESET_PRESSED then gosub handle_reset_pressed : goto mainloop_draw_screen
  if switchselect then gosub handle_select_action : goto mainloop_draw_screen
  if gamestate = IN_PROGRESS then gosub handle_active_game else gosub handle_stopped_game
mainloop_draw_screen
  gosub draw_screen bank2
  goto main_loop


handle_initializing
  if switchselect || switchreset then return
  if joy0fire || joy1fire then return
  gamestate = MODE_SELECT
  return


handle_select_pressed
  if switchselect then return
  gamestate = MODE_SELECT
  return


handle_reset_pressed
  if switchreset then return
  gamestate = IN_PROGRESS
  return


handle_select_action
  if gamestate = MODE_SELECT then max_score_mode = max_score_mode + 1
  if gamestate = IN_PROGRESS then gosub clear_sounds : gosub stop_game

  if max_score_mode >= NUM_MAX_SCORE_MODES then max_score_mode = 0 : goal_size_mode = goal_size_mode + 1
  if goal_size_mode >= NUM_GOAL_SIZE_MODES then goal_size_mode = 0

  gosub set_mode
  gamestate = SELECT_PRESSED
  return


handle_active_game
  rem Pause Game
  if switchbw then return

  rem Restart Game
  if switchreset then gosub clear_sounds : gosub start_game : gamestate = RESET_PRESSED : return

  if goalcyclecounter > 0 then gosub handle_goal : return
  gosub check_for_goal : if goalcyclecounter > 0 then return

  rem Collision handling
  if collision(ball, player0)    then param0 = player0x : param1 = player0y : param2 = p0firecycle : gosub process_collision_ball_player
  if collision(ball, player1)    then param0 = player1x : param1 = player1y : param2 = p1firecycle : gosub process_collision_ball_player
  if collision(ball, playfield)  then gosub process_collision_ball_playfield
  if collision(player0, player1) then gosub process_players_collision

  rem Player0 movement
  if switchleftb then gosub set_p0_player_movement else gosub set_p0_cpu_movement
  gosub perform_p0_movement

  rem Player1 movement
  if switchrightb then gosub set_p1_player_movement else gosub set_p1_cpu_movement
  gosub perform_p1_movement

  gosub process_ball_movement

  return


handle_stopped_game
  if switchreset then gosub start_game : gamestate = RESET_PRESSED : return
  if joy0fire || joy1fire then gosub start_game : gamestate = IN_PROGRESS
  return


  rem ************************************************************
  rem * HANDLE COLLISION OF BALL WITH PLAYFIELD
  rem ************************************************************

process_collision_ball_playfield
  if ballx < MIN_BALLX then balldx = FORWARD
  if ballx > MAX_BALLX then balldx = BACKWARD
  if bally < MIN_BALLY then balldy = FORWARD
  if bally > MAX_BALLY then balldy = BACKWARD
  gosub play_ball_bounce_sound
  return


  rem ************************************************************
  rem * HANDLE COLLISION OF BALL WITH PLAYERS
  rem ************************************************************
 
process_collision_ball_player
  rem PARAM: param0 - The player's X position
  rem PARAM: param1 - The player's Y position
  rem PARAM: param2 - The player's firecycle
  if 0 < param2 && param2 < P_MAX_FIRECYCLES then powerballcycle = powerballcycle + POWERBALLCYCLES : gosub play_hit_sound
  tmp0 = param0 + P_COLLISION_TOLERANCE
  tmp1 = param0 + P_WIDTH - P_COLLISION_TOLERANCE
  if ballx <= tmp0 then balldx = BACKWARD
  if ballx >= tmp1 then balldx = FORWARD
  tmp0 = param1 - P_HEIGHT + P_COLLISION_TOLERANCE
  tmp1 = param1 - P_COLLISION_TOLERANCE
  if bally <= tmp0 then balldy = BACKWARD
  if bally >= tmp1 then balldy = FORWARD
  gosub play_ball_bounce_sound
  return


  rem ************************************************************************
  rem * HANDLE COLLISION BETWEEN PLAYERS
  rem ************************************************************************

process_players_collision
  tmp0 = PUSH_DISPLACEMENT
  tmp1 = PUSH_DISPLACEMENT
  if p0firecycle > 0 && p0firecycle < P_MAX_FIRECYCLES then tmp0 = HIT_DISPLACEMENT
  if p1firecycle > 0 && p1firecycle < P_MAX_FIRECYCLES then tmp1 = HIT_DISPLACEMENT

  if player0x < player1x then player0x = player0x - tmp1 : player1x = player1x + tmp0
  if player0x > player1x then player0x = player0x + tmp1 : player1x = player1x - tmp0
  if player0y < player1y then player0y = player0y - tmp1 : player1y = player1y + tmp0
  if player0y > player1y then player0y = player0y + tmp1 : player1y = player1y - tmp0

  if tmp0 >= HIT_DISPLACEMENT || tmp1 >= HIT_DISPLACEMENT then gosub play_hit_sound else gosub play_ball_bounce_sound
  return


  rem ************************************************************
  rem * BALL MOVEMENT
  rem ************************************************************

process_ball_movement
  if powerballcycle > 0 then gosub process_single_ball_movement : powerballcycle = powerballcycle - 1
  gosub process_single_ball_movement
  return

process_single_ball_movement
  ballx = ballx + balldx
  bally = bally + balldy
  return


  rem ************************************************************
  rem * MODE SELECTION
  rem ************************************************************

set_mode
  max_score = max_scores[max_score_mode]
  gosub set_playfield
  return


set_playfield
  if goal_size_mode = 0 then playfield:
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    X..............................X
    X..............................X
    X..............................X
    ................................
    ................................
    X..............................X
    X..............................X
    X..............................X
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
  if goal_size_mode = 1 then playfield:
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    X..............................X
    X..............................X
    ................................
    ................................
    ................................
    ................................
    X..............................X
    X..............................X
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
  if goal_size_mode = 2 then playfield:
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    X..............................X
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    X..............................X
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
  if goal_size_mode = 3 then playfield:
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    ................................
    XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
end
  return


  rem ************************************************************
  rem * STOP GAME
  rem ************************************************************

stop_game
  balldx = NO_MOVE
  balldy = NO_MOVE
  gosub set_ball_mid_position
  gosub set_players_init_positions

  pfcolors:
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
end
  player0color:
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
end
  player1color:
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
    $06
end
  return


  rem ************************************************************
  rem * INITIAL POSITIONS
  rem ************************************************************

set_ball_mid_position
  ballx = MID_BALLX
  bally = MID_BALLY
  return


set_players_init_positions
  player0x = INIT_P0X
  player0y = INIT_P0Y
  p0dx = NO_MOVE
  p0dy = NO_MOVE
  p0firecycle = 0
  p0frm = 0

  player1x = INIT_P1X
  player1y = INIT_P1Y
  p1dx = NO_MOVE
  p1dy = NO_MOVE
  p1firecycle = 0
  p1frm = 0

  player0:
    %01000010
    %11111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01101010
    %01101010
    %01111110
    %10000001
    %10000001
end
  player1:
    %01000010
    %01111111
    %01111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01010110
    %01010110
    %01111110
    %10000001
    %10000001
end
  return


  rem ************************************************************
  rem * START GAME
  rem ************************************************************

start_game
  goalcyclecounter = 0
  p0score = 0
  p1score = 0

  gosub set_players_init_positions

  playerkickoff = rand &01
  gosub kickoff

  pfcolors:
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
end
  player0color:
    $08
    $AA
    $AA
    $AA
    $AA
    $AA
    $AA
    $AA
    $AA
    $AA
    $0F
    $0F
end
  player1color:
    $08
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $0F
    $0F
end

  return


  rem ************************************************************
  rem * KICKOFF
  rem ************************************************************

kickoff
  powerballcycle = 0
  bally = MID_BALLY

  if playerkickoff = 0 then ballx = player0x + P_WIDTH + 1 : balldx = FORWARD else ballx = player1x - 1 : balldx = BACKWARD

  tmp0 = rand &01
  if tmp0 > 0 then balldy = FORWARD else balldy = BACKWARD

  return


  rem ************************************************************
  rem * GOAL CHECKING
  rem ************************************************************

check_for_goal
  if bally < min_goal_limits[goal_size_mode] || bally > max_goal_limits[goal_size_mode] then return
  if ballx >= MIN_BALLX && ballx <= MAX_BALLX then return
  if ballx < MIN_BALLX then gosub record_p1_goal
  if ballx > MAX_BALLX then gosub record_p0_goal
  goalcyclecounter = GOAL_NO_CYCLES
  gosub play_goal_sound
  return


  rem ************************************************************
  rem * GOAL HANDLING
  rem ************************************************************

handle_goal
  goalcyclecounter = goalcyclecounter - 1
  if goalcyclecounter > 0 then return

  if p0score >= max_score || p1score >= max_score then gosub stop_game : gamestate = ENDED : return

  pfcolors:
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
    $0F
end
  gosub set_players_init_positions
  gosub kickoff
  return

record_p0_goal
  playerkickoff = 1
  p0score = p0score + 1
  pfcolors:
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
    $AE
end
  return


record_p1_goal
  playerkickoff = 0
  p1score = p1score + 1
  pfcolors:
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
    $FA
end
  return


  rem ************************************************************
  rem * PLAYER 0 MOVEMENT
  rem ************************************************************

set_p0_player_movement
  p0dx = NO_MOVE
  p0dy = NO_MOVE
  if joy0fire  then p0firecycle = p0firecycle + 1 else p0firecycle = 0
  if joy0left  then p0dx = BACKWARD
  if joy0right then p0dx = FORWARD
  if joy0up    then p0dy = BACKWARD
  if joy0down  then p0dy = FORWARD
  return


set_p0_cpu_movement
  p0dx = NO_MOVE
  p0dy = NO_MOVE
  param0 = player0y - P_WIDTH / 2

  if balldx = BACKWARD then param1 = rand : param2 = rand : gosub set_p0_cpu_intercept_ball : return

  tmp0 = player0x + P_WIDTH
  if ballx < tmp0 && bally > param0 then p0dy = BACKWARD : return
  if ballx < tmp0 && bally < param0 then p0dy = FORWARD  : return

  if player0x > INIT_P0X then p0dx = BACKWARD
  if player0x < INIT_P0X then p0dx = FORWARD
  if player0y > INIT_P0Y then p0dy = BACKWARD
  if player0y < INIT_P0Y then p0dy = FORWARD
  return


set_p0_cpu_intercept_ball
  tmp0 = player0x + P_WIDTH
  if ballx >= tmp0 && bally > param0 then p0dy = FORWARD
  if ballx >= tmp0 && bally < param0 then p0dy = BACKWARD

  tmp0 = param1 & CPU_ADVACE_RANDOMNESS
  if tmp0 >= CPU_ADVACE_THESHOLD then p0dx = FORWARD

  if p0firecycle > P_MAX_FIRECYCLES then p0firecycle = 0 : return
  if p0firecycle > 0 then p0firecycle = p0firecycle + 1 : return

  tmp0 = param2 & CPU_ADVACE_RANDOMNESS
  tmp1 = ballx - player0x - P_WIDTH
  if tmp0 >= CPU_ADVACE_THESHOLD && tmp1 = CPU_DISTANCE_HIT then p0firecycle = p0firecycle + 1 else p0firecycle = 0
  return


perform_p0_movement
  player0x = player0x + p0dx
  player0y = player0y + p0dy
  if player0x < MIN_PX then player0x = MIN_PX
  if player0x > MAX_PX then player0x = MAX_PX
  if player0y < MIN_PY then player0y = MIN_PY
  if player0y > MAX_PY then player0y = MAX_PY

  if p0firecycle > 0 && p0firecycle <= P_MAX_FIRECYCLES then tmp0 = 1 else tmp0 = 0
  if tmp0 = 1 then player0:
    %01000010
    %11111110
    %01111110
    %01111110
    %01110110
    %11110111
    %01111110
    %01101010
    %01101010
    %01111110
    %10000001
    %10000001
end
  if tmp0 = 1 then return

  if p0dx <> NO_MOVE || p0dy <> NO_MOVE then p0frm = p0frm + 1
  if p0frm >= 20 then p0frm = 0
  if p0frm < 10 then player0:
    %00100010
    %11111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01101010
    %01101010
    %01111110
    %10000001
    %10000001
end
  if p0frm >= 10 then player0:
    %01000100
    %01111110
    %11111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01101010
    %01101010
    %01111110
    %10000001
    %10000001
end
  return


  rem ************************************************************
  rem * PLAYER 1 MOVEMENT
  rem ************************************************************

set_p1_player_movement
  p1dx = NO_MOVE
  p1dy = NO_MOVE
  if joy1fire  then p1firecycle = p1firecycle + 1 else p1firecycle = 0
  if joy1left  then p1dx = BACKWARD
  if joy1right then p1dx = FORWARD
  if joy1up    then p1dy = BACKWARD
  if joy1down  then p1dy = FORWARD
  return


set_p1_cpu_movement
  p1dx = NO_MOVE
  p1dy = NO_MOVE
  param0 = player1y - P_WIDTH / 2

  if balldx = FORWARD then param1 = rand : param2 = rand : gosub set_p1_cpu_intercept_ball : return

  if ballx > player1x && bally > param0 then p1dy = BACKWARD : return
  if ballx > player1x && bally < param0 then p1dy = FORWARD  : return

  if player1x > INIT_P1X then p1dx = BACKWARD
  if player1x < INIT_P1X then p1dx = FORWARD
  if player1y > INIT_P1Y then p1dy = BACKWARD
  if player1y < INIT_P1Y then p1dy = FORWARD
  return


set_p1_cpu_intercept_ball
  if ballx <= player1x && bally > param0 then p1dy = FORWARD
  if ballx <= player1x && bally < param0 then p1dy = BACKWARD

  tmp0 = param1 & CPU_ADVACE_RANDOMNESS
  if tmp0 >= CPU_ADVACE_THESHOLD then p1dx = BACKWARD

  if p1firecycle > P_MAX_FIRECYCLES then p1firecycle = 0 : return
  if p1firecycle > 0 then p1firecycle = p1firecycle + 1 : return

  tmp0 = param2 & CPU_ADVACE_RANDOMNESS
  tmp1 = player1x - ballx
  if tmp0 >= CPU_ADVACE_THESHOLD && tmp1 = CPU_DISTANCE_HIT then p1firecycle = p1firecycle + 1 else p1firecycle = 0
  return


perform_p1_movement
  player1x = player1x + p1dx
  player1y = player1y + p1dy
  if player1x < MIN_PX then player1x = MIN_PX
  if player1x > MAX_PX then player1x = MAX_PX
  if player1y < MIN_PY then player1y = MIN_PY
  if player1y > MAX_PY then player1y = MAX_PY

  if p1firecycle > 0 && p1firecycle <= P_MAX_FIRECYCLES then tmp0 = 1 else tmp0 = 0
  if tmp0 = 1 then player1:
    %01000010
    %01111111
    %01111110
    %01111110
    %01101110
    %11101111
    %01111110
    %01010110
    %01010110
    %01111110
    %10000001
    %10000001
end
  if tmp0 = 1 then return

  if p1dx <> NO_MOVE || p1dy <> NO_MOVE then p1frm = p1frm + 1
  if p1frm >= 20 then p1frm = 0
  if p1frm < 10 then player1:
    %01000100
    %01111111
    %01111110
    %01111110
    %01111110
    %01111110
    %01111110
    %01010110
    %01010110
    %01111110
    %10000001
    %10000001
end
  if p1frm >= 10 then player1:
    %00100010
    %01111110
    %01111111
    %01111110
    %01111110
    %01111110
    %01111110
    %01010110
    %01010110
    %01111110
    %10000001
    %10000001
end
  return


  rem ************************************************************
  rem * SOUND HANDLING
  rem ************************************************************

handle_sounds
  if aud0timer > 1 then aud0timer = aud0timer - 1
  if aud0timer = 1 then aud0timer = 0 : gosub clear_sound0
  if aud1timer > 1 then aud1timer = aud1timer - 1
  if aud1timer = 1 then aud1timer = 0 : gosub clear_sound1
  return


clear_sounds
  gosub clear_sound0
  gosub clear_sound1
  return


clear_sound0
  AUDV0 = 0
  AUDC0 = 0
  AUDF0 = 0
  return


clear_sound1
  AUDV1 = 0
  AUDC1 = 0
  AUDF1 = 0
  return


play_ball_bounce_sound
  AUDV0 = 5
  AUDC0 = 10
  AUDF0 = 20
  aud0timer = 5
  return


play_hit_sound
  AUDV1 = 15
  AUDC1 = 15
  AUDF1 = 31
  aud1timer = 10
  return


play_goal_sound
  AUDV1 = 15
  AUDC1 = 10
  AUDF1 = 5
  aud1timer = 20
  return


  rem ************************************************************
  rem * 2ND BANK
  rem ************************************************************
  bank 2

  data scores_display_map
    $A0, $A1, $A2, $A3, $A4, $A5, $A6, $A7, $A8, $A9,
    $10, $11, $12, $13, $14, $15, $16, $17, $18, $19,
    $20, $21
end

  rem ************************************************************
  rem * DRAW SCREEN
  rem ************************************************************

draw_screen
  rem Setting score colors
  if gamestate = IN_PROGRESS then player0scorecolor = $AA : player1scorecolor = $FA else player0scorecolor = $06 : player1scorecolor = $06

  rem Displaying scores
  if gamestate = IN_PROGRESS || gamestate = ENDED then player0score = scores_display_map[p0score] : player1score = scores_display_map[p1score] : goto draw_screen_performing bank2
  if gamestate = MODE_SELECT || gamestate = SELECT_PRESSED then player0score = scores_display_map[max_score] : player1score = $AA : goto draw_screen_performing bank2
  player0score = $AA
  player1score = $AA

draw_screen_performing
  drawscreen
  return otherbank

  rem ************************************************************************
  rem * PLAYER SCORES MINIKERNEL
  rem ************************************************************************
  inline include/player_scores.asm


  rem ************************************************************************
  rem * TITLE SCREEN
  rem ************************************************************************
title_screen
  inline include/title_screen.asm
  goto main_game bank1
  inline include/title_screen_bitmaps.asm
