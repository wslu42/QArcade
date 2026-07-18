pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--------- microqiskit ---------
-- math.p8
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
-------------------------------
------- microqiskit.lua -------
-- this code is part of qiskit.
-- copyright ibm 2020
math.randomseed(os.time())
function quantumcircuit ()

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
--------- router engine ---------
num_qubits=3
circuit_depth=4
shots=16
world_speed=0.75
approach_x=74
approach_speed=0.5
collect_x=26
states={"000","001","010","011","100","101","110","111"}

-- centralized layout contract
--
-- coordinate rule:
-- top-level block.x/y + local element offset
layout={
  controller={
    x=0,
    y=0,
    w=37,
    h=51,

    grid={
      x=1,
      y=3,
      cell_w=8,
      cell_h=8,
      col_pitch=10,
      row_pitch=9
    },

    depth_index={
      x=31,
      y=3,
      text_dy=2
    },

    depth_flow={
      x=31,
      y=4,
      gap_dy=-2
    },

    qubit_index={
      x=2,
      y=40
    },

    qubit_selector={
      x=4,
      y=46,
      w=3,
      h=2,
      style="pixel_caret"
    }
  },

  key_map={
    x=37,
    y=0,
    w=91,
    h=19,

    items={
      {text="❎ x",x=15,y=1},
      {text="🅾️ h",x=49,y=1},
      {text="hold ❎+⬅️/➡️ cx",x=7,y=9},
      {text="⬆️ run",x=15,y=17},
      {text="⬇️ clr",x=49,y=17}
    }
  },

  operation_feedback={
    x=37,
    y=19,
    w=91,
    h=6
  },

  mission={
    x=37,
    y=25,
    w=91,
    h=26
  },

  -- full response canvas: x=0..127, y=51..127.
  response={
    x=0,
    y=51,
    w=128,
    h=77,

    legend={
      x=2,
      y=20,
      w=128,
      h=6,

      target={
        box_x=3,
        text_x=10
      },

      measured={
        box_x=53,
        text_x=60
      }
    },

    canvas={
      x=4,
      y=30,
      w=126,
      h=17,

      base_y=16,
      first_state_x=0,
      state_pitch=16
    },

    state_index={
      x=4,
      y=51,
      w=127,
      h=6,
      state_pitch=16
    }
  }
}

function blank_grid()
  local grid={}
  for q=0,num_qubits-1 do
    grid[q+1]={}
    for d=1,circuit_depth do
      grid[q+1][d]="-"
    end
  end
  return grid
end

function blank_counts()
  local counts={}
  for s in all(states) do
    counts[s]=0
  end
  return counts
end

function gate_options(q)
  local options={"-","x","h"}
  for target=0,num_qubits-1 do
    if target~=q then
      add(options,"c"..target)
    end
  end
  return options
end

function cycle_gate(grid,q,d)
  local options=gate_options(q)
  local current=grid[q+1][d]
  local index=1
  for i=1,#options do
    if options[i]==current then
      index=i
    end
  end
  index=index%#options+1
  grid[q+1][d]=options[index]
end


-- 𝘢 qubit is busy at a depth if it has its own gate or is
-- the target of a 𝘤𝘹 stored in another qubit's cell.
function qubit_busy(grid,q,d)
  if grid[q+1][d]!="-" then
    return true
  end

  for control=0,num_qubits-1 do
    local gate=grid[control+1][d]
    if sub(gate,1,1)=="c" then
      local target=tonum(sub(gate,2,2))
      local low=min(control,target)
      local high=max(control,target)
      if q>=low and q<=high then return true end
    end
  end

  return false
end

-- 𝘧ind the first legal time slice from 𝘥1 to 𝘥3.
-- 𝘹/𝘩 occupy one qubit. 𝘤𝘹 occupies both control and target.
-- 𝘳eturn 0 when no legal depth exists; never shift old gates.
function find_gate_depth(grid,q,gate)
  local target=-1

  if sub(gate,1,1)=="c" then
    target=tonum(sub(gate,2,2))
  end

  for d=1,circuit_depth do
    local free=not qubit_busy(grid,q,d)

    if target>=0 then
      local low=min(q,target)
      local high=max(q,target)
      for span_q=low,high do
        free=free and not qubit_busy(grid,span_q,d)
      end
    end

    if free then
      return d
    end
  end

  return 0
end

function append_gate(grid,q,gate)
  local d=find_gate_depth(grid,q,gate)
  if d>0 then grid[q+1][d]=gate end
  return d
end

-- 𝘤lear every operation involving the selected qubit, whether it is
-- a single-qubit gate, 𝘤𝘹 control, or 𝘤𝘹 target.
function clear_qubit_gates(grid,q)
  for d=1,circuit_depth do
    grid[q+1][d]="-"

    for control=0,num_qubits-1 do
      local gate=grid[control+1][d]
      if (
        sub(gate,1,1)=="c" and
        tonum(sub(gate,2,2))==q
      ) then
        grid[control+1][d]="-"
      end
    end
  end
end

function compile_grid(grid)
  local qc=quantumcircuit()
  qc.set_registers(num_qubits,num_qubits)

  -- 𝘤ompile by circuit depth, not by qubit row.
  -- 𝘵his preserves the left-to-right circuit order shown to students.
  for d=1,circuit_depth do
    for q=num_qubits-1,0,-1 do
      local gate=grid[q+1][d]
      if gate=="x" then
        qc.x(q)
      elseif gate=="h" then
        qc.h(q)
      elseif sub(gate,1,1)=="c" then
        qc.cx(q,tonum(sub(gate,2,2)))
      end
    end
  end

  for q=0,num_qubits-1 do
    qc.measure(q,q)
  end
  return qc
end

function run_grid(grid)
  local measured=simulate(compile_grid(grid),"counts",shots)
  local counts=blank_counts()
  for state,count in pairs(measured) do
    if counts[state]~=nil then
      counts[state]=count
    end
  end
  return counts
end

function distribution_score(counts,target)
  local distance=0
  for state in all(states) do
    distance=distance+abs(counts[state]-(target[state] or 0))
  end
  return shots-flr(distance/2)
end
------ student-editable levels ------
-- mission text is supplied by each level below.

-- target counts must add up to 16.
-- state strings are q2 q1 q0.
game_title="photon runner"

levels={
  {
    name="1 single guide",
    target={ ["001"]=16 },
    hint="route photon to 001"
  },
  {
    name="2 beam split",
    target={ ["000"]=8,["001"]=8 },
    hint="light 000 + 001"
  },
  {
    name="3 linked guides",
    target={ ["000"]=8,["011"]=8 },
    hint="link 000 + 011"
  },
  {
    name="4 quantum uplink",
    target={ ["000"]=8,["111"]=8 },
    hint="link 000 + 111"
  },
  {
    name="5 reroute",
    target={ ["101"]=16 },
    hint="route photon to 101"
  },
  {
    name="6 photon rush",
    target={ ["010"]=8,["110"]=8 },
    hint="light 010 + 110"
  }
}
--------- quantum router game ---------
function reset_controller()
  grid=blank_grid()
  fresh_q=-1
  fresh_d=0
  fresh_gate=""
  fresh_timer=0
  blocked_q=-1
  blocked_target=-1
  blocked_text=""
  blocked_timer=0
end

function reset_input_state()
  x_was_down=false
  z_was_down=false
  left_was_down=false
  right_was_down=false
  cx_control=-1
  cx_target=-1
  cx_moved=false
  h_q=-1
end

function active_photon_count()
  local total=0
  for state in all(states) do
    if photons[state] then total+=1 end
  end
  return total
end

function project_circuit()
  counts=run_grid(grid)
  local next_photons={}
  local stable=0

  for state in all(states) do
    if (counts[state] or 0)>=4 then
      next_photons[state]=true
      stable+=1
    end
  end

  if stable>0 then
    photons=next_photons
    signal_text=stable.." stable pulse"
    if stable>1 then signal_text=stable.." stable pulses" end
    signal_color=11
  else
    signal_text="unstable projection"
    signal_color=8
  end

  signal_timer=45
  projection_timer=10
  reset_controller()
end

function visual_q(q)
  return q
end

function gate_label(gate)
  if gate=="x" then
    return "x"
  elseif gate=="h" then
    return "h"
  elseif sub(gate,1,1)=="c" then
    return "cx"
  end
  return "-"
end

function cx_target_of(gate)
  if sub(gate,1,1)=="c" then
    return tonum(sub(gate,2,2))
  end
  return -1
end

function cx_control_for(q,d)
  for control=0,num_qubits-1 do
    local gate=grid[control+1][d]
    if (
      sub(gate,1,1)=="c" and
      cx_target_of(gate)==q
    ) then
      return control
    end
  end
  return -1
end

function draw_control_dot(x,y,color)
  circfill(x+4,y+4,2,color)
end

function draw_target_plus(x,y,color)
  circ(x+4,y+4,2,color)
  line(x+2,y+4,x+6,y+4,color)
  line(x+4,y+2,x+4,y+6,color)
end

function mark_fresh_gate(q,d,gate)
  fresh_q=q
  fresh_d=d
  fresh_gate=gate
  fresh_timer=42
  blocked_timer=0
end

function mark_blocked(q,target)
  blocked_q=q
  blocked_target=target
  blocked_timer=36
  fresh_timer=0

  if target>=0 then
    blocked_text=
      "no free d q"..visual_q(q)..
      ">q"..visual_q(target)
  else
    blocked_text="no free d q"..visual_q(q)
  end
end

function try_add_gate(q,gate)
  local d=append_gate(grid,q,gate)

  if d>0 then
    mark_fresh_gate(q,d,gate)
    return true
  end

  mark_blocked(q,cx_target_of(gate))
  return false
end

function lane_y(index)
  return layout.response.y+5+(index-1)*9
end

function init_stars()
  stars={}
  for i=1,20 do
    add(stars,{
      x=rnd(113)+15,
      y=rnd(72)+layout.response.y+1,
      speed=rnd(1.25)+0.25,
      color=rnd(1)<0.75 and 5 or 6
    })
  end
end

function spawn_wave(index)
  level_index=index
  level=levels[level_index]
  objects={}
  for lane=1,#states do
    local state=states[lane]
    local kind=(level.target[state] or 0)>0 and "energy" or "block"
    add(objects,{x=132,lane=lane,kind=kind,hit=false})
  end
end

function restart_game()
  cursor_q=2
  counts=blank_counts()
  photons={ ["000"]=true }
  score=0
  shields=3
  waves_cleared=0
  level_index=1
  level=levels[1]
  objects={}
  wave_gap=0
  scroll_speed=0.75
  guide_scroll=0
  signal_text="build circuit + run"
  signal_color=6
  signal_timer=90
  projection_timer=0
  game_complete=false
  game_over=false
  reset_controller()
  reset_input_state()
  init_stars()
  spawn_wave(1)
end

function update_world()
  local move_speed=scroll_speed*world_speed
  guide_scroll=(guide_scroll+move_speed)%12

  for star in all(stars) do
    star.x-=star.speed*world_speed
    if star.x<15 then
      star.x=127
      star.y=rnd(72)+layout.response.y+1
    end
  end

  for object in all(objects) do
    local object_speed=move_speed
    if object.x<=approach_x then
      object_speed*=approach_speed
    end
    object.x-=object_speed
    local state=states[object.lane]

    if (
      object.kind=="energy" and
      not object.collected and
      not object.hit and
      object.x<=collect_x and
      photons[state]
    ) then
      object.collected=true
      object.fade=6
      object.fade_x=object.x
      score+=10
    end

    if not object.hit and object.x<=22 then
      object.hit=true

      if photons[state] then
        if object.kind=="block" then
          photons[state]=nil
        end
      end

      if object.lane==#states then
        waves_cleared+=1
        if active_photon_count()==0 then
          shields-=1
          photons["000"]=true
          signal_text="signal lost"
          signal_color=8
          signal_timer=45
        end

        if shields<=0 then
          game_over=true
        elseif waves_cleared>=#levels then
          game_complete=true
        else
          wave_gap=50
        end
      end
    end

    if object.fade then
      object.fade-=1
      if object.fade<=0 then object.hidden=true end
    end

    if object.x<14 then del(objects,object) end
  end

  if wave_gap>0 then
    wave_gap-=1
    if wave_gap==0 and waves_cleared<#levels then
      spawn_wave(waves_cleared+1)
      scroll_speed=min(1.25,scroll_speed+0.08)
    end
  end
end

function _init()
  restart_game()
end

-- 𝘳otated composer:
-- qubits are columns; d1 begins at the bottom and depth grows upward.
-- 𝘵he selected qubit column is highlighted because depth now fills
-- automatically, matching the original 𝘲ilin gate queue.
function _update()
  if (fresh_timer>0) fresh_timer-=1
  if (blocked_timer>0) blocked_timer-=1
  if (signal_timer>0) signal_timer-=1
  if (projection_timer>0) projection_timer-=1

  if game_complete or game_over then
    if btnp(4) then restart_game() end
    return
  end

  update_world()

  local x_down=btn(5)
  local z_down=btn(4)
  local left_down=btn(0)
  local right_down=btn(1)
  local x_pressed=x_down and not x_was_down
  local x_released=x_was_down and not x_down
  local z_pressed=z_down and not z_was_down
  local z_released=z_was_down and not z_down
  local left_pressed=left_down and not left_was_down
  local right_pressed=right_down and not right_was_down

  if x_pressed then
    h_q=-1
    cx_control=cursor_q
    cx_target=cursor_q
    cx_moved=false
  end

  if z_pressed and not x_down then
    h_q=cursor_q
  end

  if x_down then
    if left_pressed then
      cx_target=(cx_target+1)%num_qubits
      cx_moved=true
    elseif right_pressed then
      cx_target=(cx_target-1)%num_qubits
      cx_moved=true
    end
  else
    if left_pressed then
      cursor_q=mid(0,cursor_q+1,num_qubits-1)
    elseif right_pressed then
      cursor_q=mid(0,cursor_q-1,num_qubits-1)
    end
  end

  if x_released then
    if not cx_moved then
      try_add_gate(cx_control,"x")
    elseif cx_target!=cx_control then
      try_add_gate(cx_control,"c"..cx_target)
    else
      blocked_text="cx cancelled"
      blocked_timer=30
    end
    cx_control=-1
    cx_target=-1
    cx_moved=false
  end

  if z_released then
    if h_q>=0 and not x_down then
      try_add_gate(h_q,"h")
    end
    h_q=-1
  end

  if btnp(2) and not x_down then
    project_circuit()
  elseif btnp(3) and not x_down then
    clear_qubit_gates(grid,cursor_q)
    fresh_timer=0
    blocked_timer=0
  end

  x_was_down=x_down
  z_was_down=z_down
  left_was_down=left_down
  right_was_down=right_down
end

function draw_circuit()
  local controller=layout.controller
  local grid_layout=controller.grid
  local depth_index=controller.depth_index
  local depth_flow=controller.depth_flow
  local qubit_index=controller.qubit_index
  local qubit_selector=controller.qubit_selector

  local controller_x=controller.x
  local controller_y=controller.y
  local grid_x=controller_x+grid_layout.x
  local grid_y=controller_y+grid_layout.y

  -- qubit index + qubit selector
  for visual_col=0,num_qubits-1 do
    local q=num_qubits-1-visual_col
    local x=grid_x+visual_col*grid_layout.col_pitch
    local selected=(q==cursor_q)
    local blocked=(
      blocked_timer>0 and
      (q==blocked_q or q==blocked_target)
    )
    local label="q"..q
    local label_color=6

    if selected then
      label_color=10
    end

    if blocked then
      label_color=8
    end

    print(
      label,
      controller_x+qubit_index.x+
        visual_col*grid_layout.col_pitch,
      controller_y+qubit_index.y,
      label_color
    )

    if selected then
      print(
        "^",
        controller_x+qubit_selector.x+
          visual_col*grid_layout.col_pitch,
        controller_y+qubit_selector.y,
        label_color
      )
    end
  end

  -- depth flow indicator
  local depth_flow_x=controller_x+depth_flow.x
  local depth_flow_y=controller_y+depth_flow.y

  for visual_row=1,circuit_depth-1 do
    local marker_y=
      depth_flow_y+
      visual_row*grid_layout.row_pitch+
      depth_flow.gap_dy

    print("^",depth_flow_x,marker_y,6)
  end

  -- controller grid + depth index
  local depth_index_x=controller_x+depth_index.x
  local depth_index_y=controller_y+depth_index.y

  for visual_row=0,circuit_depth-1 do
    local d=circuit_depth-visual_row
    local y=grid_y+visual_row*grid_layout.row_pitch

    print(
      d,
      depth_index_x,
      depth_index_y+
        visual_row*grid_layout.row_pitch+
        depth_index.text_dy,
      6
    )

    for visual_col=0,num_qubits-1 do
      local q=num_qubits-1-visual_col
      local x=grid_x+visual_col*grid_layout.col_pitch
      local gate=grid[q+1][d]
      local target=cx_target_of(gate)
      local incoming=cx_control_for(q,d)
      local is_control=(target>=0)
      local is_target=(incoming>=0)
      local fresh_target=cx_target_of(fresh_gate)

      local is_fresh_pair=(
        fresh_timer>0 and
        d==fresh_d and
        fresh_target>=0 and
        (q==fresh_q or q==fresh_target)
      )

      local is_fresh_single=(
        fresh_timer>0 and
        d==fresh_d and
        q==fresh_q and
        fresh_target<0
      )

      local symbol_color=1
      local border_color=1

      if is_fresh_pair or is_fresh_single then
        symbol_color=13
        border_color=13
      end

      rectfill(
        x,
        y,
        x+grid_layout.cell_w,
        y+grid_layout.cell_h,
        6
      )

      rect(
        x,
        y,
        x+grid_layout.cell_w,
        y+grid_layout.cell_h,
        border_color
      )

      if is_control then
        draw_control_dot(x,y,symbol_color)
      elseif is_target then
        draw_target_plus(x,y,symbol_color)
      else
        local shown=gate_label(gate)

        if shown!="-" then
          local text_x=x+3
          if #shown>1 then text_x=x+1 end
          print(shown,text_x,y+2,symbol_color)
        end
      end

    end

    -- connect committed cnots across their reserved spans.
    for control=0,num_qubits-1 do
      local gate=grid[control+1][d]
      local target=cx_target_of(gate)

      if target>=0 then
        local control_x=grid_x+
          (num_qubits-1-control)*grid_layout.col_pitch
        local target_x=grid_x+
          (num_qubits-1-target)*grid_layout.col_pitch
        local color=1

        if (
          fresh_timer>0 and
          d==fresh_d and
          control==fresh_q
        ) then
          color=13
        end

        line(control_x+4,y+4,target_x+4,y+4,color)
        draw_control_dot(control_x,y,color)
        draw_target_plus(target_x,y,color)
      end
    end
  end

  -- preview the cnot that x release will commit.
  if btn(5) and cx_moved and cx_target!=cx_control then
    local gate="c"..cx_target
    local d=find_gate_depth(grid,cx_control,gate)

    if d>0 then
      local visual_row=circuit_depth-d
      local y=grid_y+visual_row*grid_layout.row_pitch
      local control_x=grid_x+
        (num_qubits-1-cx_control)*grid_layout.col_pitch
      local target_x=grid_x+
        (num_qubits-1-cx_target)*grid_layout.col_pitch

      line(control_x+4,y+4,target_x+4,y+4,13)
      draw_control_dot(control_x,y,13)
      draw_target_plus(target_x,y,13)
    end
  end

end

function print_centered_in_region(text,x,y,w,color)
  local text_x=x+flr((w-#text*4)/2)
  if text_x<x then text_x=x end
  print(text,text_x,y,color)
end

function print_centered(text,y,color)
  print_centered_in_region(text,0,y,128,color)
end

function draw_prompt_line(text,color)
  local mission=layout.mission
  local title={x=0,y=0,w=mission.w}
  local instruction={x=0,y=10,w=mission.w}

  print_centered_in_region(
    level.name,
    mission.x+title.x,
    mission.y+title.y,
    title.w,
    10
  )

  print_centered_in_region(
    text,
    mission.x+instruction.x,
    mission.y+instruction.y,
    instruction.w,
    color
  )
end

function draw_status()
  local mission=layout.mission
  local feedback={x=0,y=19,w=mission.w}
  local feedback_x=mission.x+feedback.x
  local feedback_y=mission.y+feedback.y

  draw_prompt_line(level.hint,6)
  print_centered_in_region(
    "score "..score.." shield "..shields,
    feedback_x,feedback_y,feedback.w,11
  )
end

function draw_energy(x,y,fade)
  local color=10
  local radius=2

  if fade then
    if fade<=4 then color=9 end
    if fade<=2 then
      color=5
      radius=1
    end
    if fade<=1 then
      color=1
      radius=0
    end
  end

  circfill(x,y,radius,color)
  if not fade or fade>4 then pset(x,y,7) end
end

function draw_blocker(x,y)
  rectfill(x-2,y-3,x+2,y+3,8)
  line(x-2,y-2,x+2,y+2,2)
  line(x+2,y-2,x-2,y+2,2)
end

function draw_photon(y,state)
  local flash=projection_timer>0 and 10 or 11
  line(17,y,23,y,flash)
  circfill(22,y,2,flash)
  pset(22,y,7)
end

function draw_waveguides()
  local response=layout.response
  clip(response.x,response.y,response.w,response.h)
  rectfill(response.x,response.y,127,127,0)

  for star in all(stars) do
    pset(star.x,star.y,star.color)
    if star.speed>1.1 then pset(star.x+1,star.y,star.color) end
  end

  for i=1,#states do
    local state=states[i]
    local y=lane_y(i)
    print(state,1,y-2,6)
    line(14,y,127,y,1)

    for x=14-guide_scroll,127,12 do
      if x>=14 then pset(x,y,5) end
    end

    if photons[state] then draw_photon(y,state) end
  end

  for object in all(objects) do
    if not object.hidden then
      local y=lane_y(object.lane)
      if object.kind=="energy" then
        draw_energy(object.fade_x or object.x,y,object.fade)
      else
        draw_blocker(object.x,y)
      end
    end
  end

  line(13,response.y,13,127,5)
  clip()
end

function draw_complete()
  cls(1)
  print_centered("photon runner",42,11)
  print_centered("uplink restored",58,7)
  print_centered("score "..score,67,10)
  print_centered("🅾️ replay",88,10)
end

function draw_game_over()
  cls(1)
  print_centered("signal lost",42,8)
  print_centered("score "..score,58,7)
  print_centered("o retry",88,10)
end

function draw_key_hint()
  local key_map=layout.key_map

  local key_x=key_map.x
  local key_y=key_map.y

  for item in all(key_map.items) do
    print(
      item.text,
      key_x+item.x,
      key_y+item.y,
      5
    )
  end
end

function _draw()
  if game_complete then
    draw_complete()
    return
  end

  if game_over then
    draw_game_over()
    return
  end

  cls(0)
  draw_key_hint()

  local op_feedback=layout.operation_feedback
  local op_feedback_x=op_feedback.x
  local op_feedback_y=op_feedback.y

  if btn(5) and cx_control>=0 then
    local pending_text="x q"..visual_q(cx_control).." on release"
    local pending_color=13

    if cx_moved and cx_target==cx_control then
      pending_text="cx cancel on release"
      pending_color=8
    elseif cx_moved then
      local pending_gate="c"..cx_target
      local pending_d=find_gate_depth(
        grid,cx_control,pending_gate
      )

      if pending_d>0 then
        pending_text=
          "cx q"..visual_q(cx_control)..
          ">q"..visual_q(cx_target)..
          " d"..pending_d.." on release"
      else
        pending_text="cx path blocked"
        pending_color=8
      end
    end

    print_centered_in_region(
      pending_text,
      op_feedback_x,
      op_feedback_y,
      op_feedback.w,
      pending_color
    )
  elseif btn(4) and h_q>=0 then
    print_centered_in_region(
      "h q"..visual_q(h_q).." on release",
      op_feedback_x,
      op_feedback_y,
      op_feedback.w,
      13
    )
  elseif blocked_timer>0 then
    print_centered_in_region(blocked_text,op_feedback_x,op_feedback_y,op_feedback.w,8)
  elseif fresh_timer>0 then
    local target=cx_target_of(fresh_gate)

    if target>=0 then
      print_centered_in_region(
        "cx q"..visual_q(fresh_q)..
        ">q"..visual_q(target)..
        " d"..fresh_d,
        op_feedback_x,
        op_feedback_y,
        op_feedback.w,
        13
      )
    else
      print_centered_in_region(
        gate_label(fresh_gate)..
        " > q"..visual_q(fresh_q)..
        " d"..fresh_d,
        op_feedback_x,
        op_feedback_y,
        op_feedback.w,
        13
      )
    end
  elseif signal_timer>0 then
    print_centered_in_region(
      signal_text,
      op_feedback_x,
      op_feedback_y,
      op_feedback.w,
      signal_color
    )
  end

  draw_circuit()
  draw_status()
  draw_waveguides()
end
