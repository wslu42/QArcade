pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- qpong
-- by qiskitters

----------------------------------------------------------------------
-- QPong PICO-8 version
-- Source code: https://github.com/HuangJunye/QPong-PICO-8
-- Made during Qiskit Hackathon Taiwan
-- Authors: Jian J-Lee, Lee Yi, Lee Yu-Chieh, Zuo Tso-Yen
-- Coaches: Huang Junye, Leung Shek Lun

-- Original QPong Python version
-- Source code: https://github.com/HuangJunye/QPong
-- Made during Qiskit Camp Flagship 2019
-- Authors: Huang Junye, Jarrod Reilly, Anastasia Jeffery
-- Coach: James Weaver
----------------------------------------------------------------------

-- math.p8
-- This code is part of Qiskit.
-- Copyright IBM 2020
-- Custom math table for compatibility with the Pico8

math = {}
math.pi = 3.14159
math.max = max
math.sqrt = sqrt
math.floor = flr
function math.random()
  return rnd(1)
end
function math.cos(theta)
  return cos(theta/(2*math.pi))
end
function math.sin(theta)
  return -sin(theta/(2*math.pi))
end
function math.randomseed(time)
end
os = {}
function os.time()
end

-- MicroQiskit.lua
-- This code is part of Qiskit.
-- Copyright IBM 2020

math.randomseed(os.time())

function QuantumCircuit ()

  local qc = {}

  local function set_registers (n,m)
    qc.num_qubits = n
    qc.num_clbits = m or 0
  end
  qc.set_registers = set_registers

  qc.data = {}

  function qc.initialize (ket)
    ket_copy = {}
    for j, amp in pairs(ket) do
      if type(amp)=="number" then
        ket_copy[j] = {amp, 0}
      else
        ket_copy[j] = {amp[0], amp[1]}
      end
    end
    qc.data = {{'init',ket_copy}}
  end

  function qc.add_circuit (qc2)
    qc.num_qubits = math.max(qc.num_qubits,qc2.num_qubits)
    qc.num_clbits = math.max(qc.num_clbits,qc2.num_clbits)
    for g, gate in pairs(qc2.data) do
      qc.data[#qc.data+1] = ( gate )
    end
  end

  function qc.x (q)
    qc.data[#qc.data+1] = ( {'x',q} )
  end

  function qc.rx (theta,q)
    qc.data[#qc.data+1] = ( {'rx',theta,q} )
  end

  function qc.h (q)
    qc.data[#qc.data+1] = ( {'h',q} )
  end

  function qc.cx (s,t)
    qc.data[#qc.data+1] = ( {'cx',s,t} )
  end

  function qc.measure (q,b)
    qc.data[#qc.data+1] = ( {'m',q,b} )
  end

  function qc.rz (theta,q)
    qc.h(q)
    qc.rx(theta,q)
    qc.h(q)
  end

  function qc.ry (theta,q)
    qc.rx(math.pi/2,q)
    qc.rz(theta,q)
    qc.rx(-math.pi/2,q)
  end

  function qc.z (q)
    qc.rz(math.pi,q)
  end

  function qc.y (q)
    qc.z(q)
    qc.x(q)
  end

  return qc

end

function simulate (qc, get, shots)

  if not shots then
    shots = 1024
  end

  function as_bits (num,bits)
    -- returns num converted to a bitstring of length bits
    -- adapted from https://stackoverflow.com/a/9080080/1225661
    local bitstring = {}
    for index = bits, 1, -1 do
        b = num - math.floor(num/2)*2
        num = math.floor((num - b) / 2)
        bitstring[index] = b
    end
    return bitstring
  end

  function get_out (j)
    raw_out = as_bits(j-1,qc.num_qubits)
    out = ""
    for b=0,qc.num_clbits-1 do
      if outputnum_clbitsap[b] then
        out = raw_out[qc.num_qubits-outputnum_clbitsap[b]]..out
      end
    end
    return out
  end


  ket = {}
  for j=1,2^qc.num_qubits do
    ket[j] = {0,0}
  end
  ket[1] = {1,0}

  outputnum_clbitsap = {}

  for g, gate in pairs(qc.data) do

    if gate[1]=='init' then

      for j, amp in pairs(gate[2]) do
          ket[j] = {amp[1], amp[2]}
      end

    elseif gate[1]=='m' then

      outputnum_clbitsap[gate[3]] = gate[2]

    elseif gate[1]=="x" or gate[1]=="rx" or gate[1]=="h" then

      j = gate[#gate]

      for i0=0,2^j-1 do
        for i1=0,2^(qc.num_qubits-j-1)-1 do
          b1=i0+2^(j+1)*i1 + 1
          b2=b1+2^j

          e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}

          if gate[1]=="x" then
            ket[b1] = e[2]
            ket[b2] = e[1]
          elseif gate[1]=="rx" then
            theta = gate[2]
            ket[b1][1] = e[1][1]*math.cos(theta/2)+e[2][2]*math.sin(theta/2)
            ket[b1][2] = e[1][2]*math.cos(theta/2)-e[2][1]*math.sin(theta/2)
            ket[b2][1] = e[2][1]*math.cos(theta/2)+e[1][2]*math.sin(theta/2)
            ket[b2][2] = e[2][2]*math.cos(theta/2)-e[1][1]*math.sin(theta/2)
          elseif gate[1]=="h" then
            for k=1,2 do
              ket[b1][k] = (e[1][k] + e[2][k])/math.sqrt(2)
              ket[b2][k] = (e[1][k] - e[2][k])/math.sqrt(2)
            end
          end

        end
      end

    elseif gate[1]=="cx" then

      s = gate[2]
      t = gate[3]

      if s>t then
        h = s
        l = t
      else
        h = t
        l = s
      end

      for i0=0,2^l-1 do
        for i1=0,2^(h-l-1)-1 do
          for i2=0,2^(qc.num_qubits-h-1)-1 do
            b1 = i0 + 2^(l+1)*i1 + 2^(h+1)*i2 + 2^s + 1
            b2 = b1 + 2^t
            e = {{ket[b1][1],ket[b1][2]},{ket[b2][1],ket[b2][2]}}
            ket[b1] = e[2]
            ket[b2] = e[1]
          end
        end
      end

    end

  end

  if get=="statevector" then
    return ket
  else

    probs = {}
    for j,amp in pairs(ket) do
      probs[j] = amp[1]^2 + amp[2]^2
    end

    if get=="expected_counts" then

      c = {}
      for j,p in pairs(probs) do
        out = get_out(j)
        if c[out] then
          c[out] = c[out] + probs[j]*shots
        else
          if out then -- in case of pico8 weirdness
            c[out] = probs[j]*shots
          end
        end
      end
      return c

    else

      m = {}
      for s=1,shots do
        cumu = 0
        un = true
        r = math.random()
        for j,p in pairs(probs) do
          cumu = cumu + p
          if r<cumu and un then
            m[s] = get_out(j)
            un = false
          end
        end
      end

      if get=="memory" then
        return m

      elseif get=="counts" then
        c = {}
        for s=1,shots do
          if c[m[s]] then
            c[m[s]] = c[m[s]] + 1
          else
            if m[s] then -- in case of pico8 weirdness
              c[m[s]] = 1
            else
              if c["error"] then
                c["error"] = c["error"]+1
              else
                c["error"] = 1
              end
            end
          end
        end
        return c

      end

    end

  end

end

----------------------------------------------------------------------
-- QPong
----------------------------------------------------------------------


----------------
-- init
----------------
function _init()
  set_scene("title")
  init_menu()
  -- use gameboy palette
  gb_palette()
end

function set_scene(s)
  if s == "title" then
    _update60 = update_title
    _draw = draw_title
  elseif s == "game" then
    _update60 = update_game
    _draw = draw_game
  elseif s == "game_over" then
    _update60 = update_game_over
    _draw = draw_game_over
  elseif s == "credits" then
    _update60 = update_credits
    _draw = draw_credits
  end
end

----------------
-- title
----------------
function update_title()
 update_cursor()
 if sub_mode==0 then
  if btnp(4) and
  menu_timer>1 then
   if menu.options[menu.sel]=="start" then
    new_game()
   elseif menu.options[menu.sel]=="colors" then
    init_settings()
   elseif menu.options[menu.sel]=="credits" then
    set_scene("credits")
   end
  end
 end

 if (sub_mode==1) update_settings()
 col1=7
 col2=0
 menu_timer+=1
end

function draw_title()
  cls()
  draw_game_logo()
  draw_options()
end

function draw_game_logo()
  sspr(0,32,64,16,32,30)
  print("made by qiskitters with", 4*3, 120, 6)
  print("qiskitters", 4*11, 120, 12)
  print("\135", 4*27, 120, 8)
end

----------------
-- game
----------------
function draw_game()
  cls()
  --court
  rect(court.left,court.top,court.right,court.bottom,court.color)

  --dashed center line
  repeat
      line(dash_line.x,dash_line.y,dash_line.x,dash_line.y+dash_line.length,dash_line.color)
      dash_line.y += dash_line.length*2
  until dash_line.y > court.bottom-1
  dash_line.y = 0 --reset

  --circuit composer
  rectfill(composer.left,composer.top,composer.right,composer.bottom,composer.color)
  --qubit lines
  repeat
      line(qubit_line.x,qubit_line.y,qubit_line.x+qubit_line.length,qubit_line.y,qubit_line.color)
      qubit_line.y += qubit_line.separation
  until qubit_line.y > composer.bottom-1
  qubit_line.y = 90 --reset

  for slot = 1, 8 do
      for wire = 1, 3 do
          gnum = gates[wire][slot] - 2
          if gnum != -1 then
              spr(gnum,
                  qubit_line.x + (slot - 1) * qubit_line.separation - 4,
                  qubit_line.y + (wire - 1) * qubit_line.separation - 4)
          end
      end
  end

  --cursor
  cursor.x=qubit_line.x+cursor.column*qubit_line.separation-4
  cursor.y=qubit_line.y+cursor.row*qubit_line.separation-4
  spr(cursor.sprite,cursor.x,cursor.y)

  for x=0,7 do
      spr(6, 94, 10 * x + 2)
      a=x%2
      b=flr(x/2)%2
      c=flr(x/4)%2
      spr(c+4, 97, 10 * x + 2)
      spr(b+4, 102, 10 * x + 2)
      spr(a+4, 107, 10 * x + 2)
      spr(7, 111, 10 * x + 2)
  end

  --player
  for y=0,7 do
      local color
      local prob = probs[y + 1] --supposed to be inverse power of 2 but I'm allowing .01 error
      if prob > .99 then
          color = 7
      elseif prob > .49 then
          color = 6
      elseif prob > .24 then
          color = 13
      elseif prob > .11 then
          color = 5
      else
          color = 0
      end

      rectfill(
          player.x,
          10 * y + 1,
          player.x + player.width,
          10 * y + player.height,
          color
      )
  end

  --ball
  rectfill(
      ball.x,
      ball.y,
      ball.x + ball.width,
      ball.y + ball.width,
      ball.color
  )

  --computer
  rectfill(
      com.x,
      com.y,
      com.x + com.width,
      com.y + com.height,
      com.color
  )

  --scores
  print(player_points,66,2,player.color)
  print(com_points,58,2,com.color)
end

function update_game()
  if btnp(2) and cursor.row > 0 then
      cursor.row -= 1
  end
  if btnp(3) and cursor.row < 2 then
      cursor.row += 1
  end
  if btnp(0) and cursor.column > 0 then
      cursor.column -= 1
  end
  if btnp(1) and cursor.column < 7  then
      cursor.column += 1
  end
  if btnp(5) then
    cur_gate = gates[cursor.row+1][cursor.column+1]
    if cur_gate==2 then
      gates[cursor.row+1][cursor.column+1]=1
    else
      gates[cursor.row+1][cursor.column+1]=2
    end
    sim_cir()
  end
  if btnp(4) then
    cur_gate = gates[cursor.row+1][cursor.column+1]
    if cur_gate==5 then
      gates[cursor.row+1][cursor.column+1]=1
    else
      gates[cursor.row+1][cursor.column+1]=5
    end
    sim_cir()
  end

  --computer controls
  com.y += com.speed
  com.y = max(com.y, 1)
  com.y = min(com.y, 70)

  local mid_com = com.y + (com.height/2)
  local r = rnd()
  if ball.y - mid_com > 0 then
      if r < .5 then
          com.speed = min(com.speed + .05, .6)
      elseif r > .75 then
          com.speed = max(com.speed - .05, -.6)
      end
  else
      if r < .5 then
          com.speed = max(com.speed - .05, -.6)
      elseif r > .75 then
          com.speed = min(com.speed + .05, .6)
      end
  end

  --score
  win_score = 7
  if ball.x > court.right then
      com_points += 1
      scored = "com"
      if com_points < win_score then
          new_round()
      else
          set_scene("game_over")
      end
  end
  if ball.x < court.left then
      player_points += 1
      scored = "player"
      if player_points < win_score then
          new_round()
      else
          set_scene("game_over")
      end
  end
  --collide with court
  if ball.y + ball.width >= court.bottom - 1
  or ball.y <= court.top+1 then
      ball.dy = -ball.dy
      sfx(2)
  end

  --collide with com
  if ball.dx < 0
      and ball.x <= com.x+com.width
      and ball.x >com.x
      and ((ball.y+ball.width<=com.y+com.height and ball.y+ball.width>=com.y)or(ball.y<=com.y+com.height and ball.y>=com.y))
  then
      ball.dy -= ball.speedup*2
      --flip ball DX and add speed
      ball.dx = -(ball.dx - ball.speedup)
      sfx(1)
  end
  --TODO: when ball collide on edge--> measure
  --UNTEST
  if ball.x > court.edge and counter==0 then
      counter=30
      meas_prob()
      for i=1,8 do
          if probs[i] == 1 then
              beg = 10 * (i - 1)
              player.y = beg
          end
      end
  elseif ball.x < court.edge and counter > 0 then
    counter-=1
    if counter==0 then
      sim_cir()
    end
  end
  ------------------------

  --collide with player
  if ball.dx > 0
      and ball.x <= player.x+player.width
      and ball.x> player.x
      and ((ball.y+ball.width<=player.y+player.height and ball.y+ball.width>=player.y)or(ball.y<=player.y+player.height and ball.y>=player.y))
  then
      ball.dy -= ball.speedup*2
      --flip ball DX and add speed
      ball.dx = -(ball.dx - ball.speedup)
      sfx(1)
  end
  --ball movement
  ball.x += ball.dx
  ball.y += ball.dy
end

function new_game()
    set_scene("game")
    player_points = 0
    com_points = 0
    scored = ""
    blink_timer = 0

    --variables
    counter=0
    player={
        x = 117,
        y = 63,
        color = 7,
        width = 2,
        height = 10,
        speed = 1
    }
    com={
        x = 8,
        y = 63,
        color = 7,
        width = 2,
        height = 10,
        speed = 0
    }
    gate_type={
        x = 0,
        y = 1,
        z = 2,
        h = 3
    }
    gate_seq={
      I=1,
      X=2,
      Y=3,
      Z=4,
      H=5
    }
    gates={
        {1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1},
        {1,1,1,1,1,1,1,1}
    }
    -- Relative frequency of the measurement results
    -- Obtained from simulator
    probs = {1, 0, 0, 0, 0, 0, 0, 0}
  --probs={0.5, 0.5, 0, 0, 0, 0, 0, 0}
  --meas_probs={1, 0, 0, 0, 0, 0, 0, 0}

    -- How many updates left does the paddle stays measured
    measured_timer = 0

    cursor = {
        row=0,
        column=0,
        x=0,
        y=0,
        sprite=16
    }
    --sound
    if scored=="player" then
        sfx(3)
    elseif scored=="com" then
        sfx(4)
    else
        sfx(5)
    end
    --court
    court={
        left=0,
        right=127,
        top=0,
        bottom=82,
        edge=107, --when ball collide this line, measure the circuit
        color=5
    }
    --court center line
    dash_line={
        x=63,
        y=0,
        length=1.5,
        color=5
    }
    --circuit composer
    composer={
        left=0,
        right=127,
        top=82,
        bottom=127,
        color=6
    }
    qubit_line={
        x=10,
        y=90,
        length=108,
        separation=15,
        color=5
    }
    new_round()
end

function new_round()
  if scored == "player" then
      ball={
          x = 30,
          y = 30 + rnd(5),
          color = 7,
          width = 2,
          dx = 0.6,
          dy = rnd() - 0.5,
          speed = 1,
          speedup = 0.05
      }
  else
      ball={
          x = 98,
          y = 30 + rnd(5),
          color = 7,
          width = 2,
          dx = -0.6,
          dy = rnd() - 0.5,
          speed = 1,
          speedup = 0.05
      }
  end
end

----------------
-- game over
----------------
function update_game_over()
  if btnp(4) then new_game() end
end

function draw_game_over()
  cls()

  blink_timer = (blink_timer + 1) % 60

  if scored == "player" then
    --player win
    print("you demostrated", 8, 28, 8)
    -- quantum advantgage
    sspr(0,80,80,16,24,40)
    -- cat
    sspr(16,64,16,16,2,94,32,32)

    draw_qiskit_logo(100,10)

    print("for the first time ",44,58,8)
    print("in human history!",56,66,8)
  else
    --com win
    print("classical computers",8,28,8)
    print("still rule the world!",40,50,8)
    --cat
    sspr(0,64,16,16,2,94,32,32)

    --computer
    sspr(32,64,16,16,96,4,32,32)
  end

  --restart
  if blink_timer < 40 then
      print("press z/\142 to restart", 24, 80, 10)
  end
end

----------------
-- credits
----------------
function update_credits()
  if btnp(4) then set_scene("title") end
end

function draw_credits()
  cls()
  print("made during", 4, 8, 9)
  print("qiskit hackathon taiwan 2020", 4*2, 8*2, 7)
  print("by", 4, 8*4, 9)
  authors = {"jian j-lee", "lee yi", "lee yu-chieh", "zuo tso-yen"}
  coaches = {"huang junye", "leung shek lun"}
  xoffset = 4*2
  yoffset = 8*5
  print("team members", xoffset, yoffset, 12)
  for i, name in ipairs(authors) do print(name, xoffset+4, yoffset+i*8, 7) end

  print("coaches", xoffset, yoffset+44, 12)
  for i, name in ipairs(coaches) do print(name, xoffset+4, yoffset+44+i*8, 7) end

  draw_qiskit_logo(90,50)
end

function draw_qiskit_logo(x,y)
  sspr(48,64,16,16,x,y)
  print("qiskit", x-3, y+19, 6)
end

----------------
-- quantum circuits
----------------
function sim_cir()
    qc = QuantumCircuit()
    qc.set_registers(3,3)
    for slots = 1,8 do
      for wires = 1,3 do
       if (gates[wires][slots] == 2) then
          qc.x(wires-1)

        elseif (gates[wires][slots] == 3) then
          qc.y(wires-1)

        elseif (gates[wires][slots] == 4) then
          qc.z(wires-1)

        elseif (gates[wires][slots] == 5) then
          qc.h(wires-1)
        end
      end
    end

    qc.measure(0,0)
    qc.measure(1,1)
    qc.measure(2,2)

    result = simulate(qc,'expected_counts',1)

    for key, value in pairs(result) do
      print(key,value)
      idx = tonum('0b'..key) + 1
      probs[idx]=value
    end
end

function meas_prob()
    idx = -1
    math.randomseed(os.time())
    r=math.random()
    --r =0.2
    --print(r)
    num =0
    for i = 1,8 do

        if (r > probs[i]) then
            num=r-probs[i]
            r=num

        elseif (r<=probs[i]) then
            idx = i
            break
        end
    end
    for i = 1,8 do
        if i==idx then
            probs[i]=1
        else
            probs[i]=0
        end
    end
    return idx
end

----------------
-- menu
-- Inspired by PixelCode
-- Source code: https://www.lexaloffle.com/bbs/?tid=27725
----------------
function lerp(startv,endv,per)
 return(startv+per*(endv-startv))
end

function update_cursor()
 if (btnp(2)) menu.sel-=1 cx=menu.x sfx(0)
 if (btnp(3)) menu.sel+=1 cx=menu.x sfx(0)
 if (btnp(4)) cx=menu.x sfx(1)
 if (btnp(5)) sfx(2)
 if (menu.sel>menu.amt) menu.sel=1
 if (menu.sel<=0) menu.sel=menu.amt

 cx=lerp(cx,menu.x+5,0.5)
end

function draw_options()
 for i=1, menu.amt do
  oset=i*8
  if i==menu.sel then
   rectfill(cx,menu.y+oset-1,cx+4*7,menu.y+oset+5,col1)
   print(menu.options[i],cx+1,menu.y+oset,col2)
  else
   print(menu.options[i],menu.x,menu.y+oset,col1)
  end
 end
end

function init_menu()
 menu={}
 menu.x=50
 cx=menu.x
 menu.y=70
 menu.options={"start","colors",
            "credits"}
 menu.amt=0
 for i in all(menu.options) do
  menu.amt+=1
 end
 menu.sel=1
 sub_mode=0
 menu_timer=0
end

function init_settings()
 menu.sel=1
 menu.options={"gameboy", "pico-8"}
 menu.amt=0
 for i in all(menu.options) do
  menu.amt+=1
 end
 sub_mode=1
 menu_timer=0
end

function update_settings()
 if (btnp(5)) init_menu()
 if btnp(4) and
 menu_timer>1 then
  if menu.options[menu.sel]=="gameboy" then
    gb_palette()
  elseif menu.options[menu.sel]=="pico-8" then
    pico8_palette()
  end
 end
end

----------------
-- color palette
-- Inspired by @TheUnproPro
-- Source code: https://twitter.com/TheUnproPro/status/1168665614896062468
----------------
function gb_palette()
  -- gameboy color palette

  green_0 = 0xf1 -- darkest green
  green_1 = 0x93 -- dark green
  green_2 = 0x23 -- light green
  green_3 = 0xfb -- lightest green

  poke(0x5f10+0, green_0)
  poke(0x5f10+1, green_1)
  poke(0x5f10+2, green_2)
  poke(0x5f10+3, green_2)
  poke(0x5f10+4, green_0)
  poke(0x5f10+5, green_1)
  poke(0x5f10+6, green_2)
  poke(0x5f10+7, green_3)
  poke(0x5f10+8, green_1)
  poke(0x5f10+9, green_1)
  poke(0x5f10+10, green_3)
  poke(0x5f10+11, green_1)
  poke(0x5f10+12, green_1)
  poke(0x5f10+13, green_1)
  poke(0x5f10+14, green_2)
  poke(0x5f10+15, green_3)

end

function pico8_palette()
  -- pico-8 original palette

  for i = 0, 15 do
    poke(0x5f10+i, i)
  end
end

__gfx__
77777771777777717777777177777771000000000000000010000000010000000000000000000000000000000000000000000000000000000000000000000000
71777171717771717111117171777171011000000010000010000000001000000000000000000000000000000000000000000000000000000000000000000000
77171771771717717777177171777171100100000110000010000000001000000000000000000000000000000000000000000000000000000000000000000000
77717771777177717771777171111171100100000010000010000000000100000000000000000000000000000000000000000000000000000000000000000000
77171771777177717717777171777171100100000010000010000000000100000000000000000000000000000000000000000000000000000000000000000000
71777171777177717111117171777171011000000010000010000000001000000000000000000000000000000000000000000000000000000000000000000000
77777771777777717777777177777771000000000000000010000000001000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111000000000000000010000000010000000000000000000000000000000000000000000000000000000000000000000000
c0c0c0c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0c0c0c0c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000000ccc00000007777770000000007770000007700007770000777777700000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ccccccc000007777777770000777777700007770007770007777777770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc000ccc00007770007770007770007770007777007770007770000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc000ccc00007777777770007770007770007777777770007770777770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc000ccc00007777770000007770007770007777777770007770777770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000ccc000ccc00007770000000007770007770007770077770007770007770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000ccccccc000007770000000000777777700007770007770007777777770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000ccccccc0007770000000000007770000007770000770000777777700000000000000000000000000000000000000000000000000000000000000000000
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
00000000000b00000000000000000000000000000000000000077077770770000000000000000000000000000000000000000000000000000000000000000000
0000000b00000b0b0000000000000000000000000000000000777700007777000000000000000000000000000000000000000000000000000000000000000000
00000000000b000b0000000000070700000000000000000007777777777777700000000000000000000000000000000000000000000000000000000000000000
00000000b0b00b000000777000077700011111111110000077099000000000770000000000000000000000000000000000000000000000000000000000000000
000000000b0b00b00100007777707000017777777710000070799777777777070000000000000000000000000000000000000000000000000000000000000000
00070070000000000010000077770000017777777710000007777977777777700000000000000000000000000000000000000000000000000000000000000000
000777700b00bb0b0001000070070000017977779710000070777797777777070000000000000000000000000000000000000000000000000000000000000000
00077770000000000001000700700000017979979710000077000009000000770000000000000000000000000000000000000000000000000000000000000000
00077770333333339000010000000000017999999710000077777777977777770000000000000000000000000000000000000000000000000000000000000000
00077770333333339000100010110000011111111110000077000000090000770000000000000000000000000000000000000000000000000000000000000000
00077770333383339000000100000000011111111110000070777777779777070000000000000000000000000000000000000000000000000000000000000000
000777703338a83399999900000000000dddddddddd0000007777777777997700000000000000000000000000000000000000000000000000000000000000000
770777703388a88399999900000000000d06060606d0000070777777777997070000000000000000000000000000000000000000000000000000000000000000
070777703888888899999900000000000d60606060d0d60007000000000000700000000000000000000000000000000000000000000000000000000000000000
077777708888a88899999900000000000d06060606d0660000777777777777000000000000000000000000000000000000000000000000000000000000000000
000777703333333399999900000000000dddd77dddd0660000077700007770000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0aaaaaa00000000000000000000000000000000000aa000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000a0000000000000000000000000000000000a00a000a0000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000a0000000000000000000000000000000000a00a000a0000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0000a0000000000000a00000000000000000000a00a000a0000000000000a00000000000000000000000000000000000000000000000000000000000000000
0a00a0a0a0a0aaa0aaa0aa0a0a0aaaaa000000000aaaa0aaa0a0a0aaa0aaa0aa0aaa0aaa0aaa0000000000000000000000000000000000000000000000000000
0a000aa0a0a0a0a0a0a0a00a0a0a0a0a000000000a00a0a0a0a0a0a0a0a0a0a00a0a0a0a0a0a0000000000000000000000000000000000000000000000000000
0aaaaaaaaaaaaaaaa0aaaaaaaaaa0a0a000000000a00a0aaa00a00aaaaa0aaaaaaaaaa0aaaaa0000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000a0a000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000aaa0aaa0000000000000000000000000000000000000000000000000000