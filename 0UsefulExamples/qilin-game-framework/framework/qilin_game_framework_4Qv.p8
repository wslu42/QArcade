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
num_qubits=4
circuit_depth=5
shots=16
states={
  "0000","0001","0010","0011",
  "0100","0101","0110","0111",
  "1000","1001","1010","1011",
  "1100","1101","1110","1111"
}

-- centralized layout contract
--
-- coordinate rule:
-- top-level block.x/y + local element offset
layout={

  -- full response canvas: x=0..127, y=0..77.
  response={
    x=0,
    y=0,
    w=128,
    h=78,

    rooms={
      x=3,
      y=3,
      cols=4,
      rows=4,
      w=29,
      h=16,
      col_pitch=31,
      row_pitch=18
    }
  },


  controller={
    anchor="bottom_right",
    x=91,
    y=78,
    w=37,
    h=50,

    grid={
      x=1,
      y=1,
      cell_w=6,
      cell_h=6,
      col_pitch=8,
      row_pitch=8
    },

    depth_index={
      x=33,
      y=2,
      text_dy=1
    },

    qubit_index={
      x=1,
      y=41
    },

    qubit_selector={
      x=3,
      y=47,
      w=3,
      h=2,
      style="pixel_caret"
    }
  },

  mission={
    x=0,
    y=78,
    w=91,
    h=26
  },
  operation_feedback={
    x=0,
    y=104,
    w=91,
    h=6
  },

  key_map={
    x=0,
    y=110,
    w=91,
    h=18,
    color=6,

    items={
      {text="❎",x=3,y=2},
      {text="🅾️",x=31,y=2},
      {text="⬆️",x=65,y=2},
      {text="❎⬅️/❎➡️",x=3,y=10},
      {text="⬇️",x=65,y=10}
    },

    control_examples={
      color=13,
      x={x=11,y=1},
      h={x=39,y=1},
      cx={control_x=40,target_x=48,y=9},
      run={text="run",x=75,y=2},
      clear={text="clr",x=75,y=10}
    }
  },



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

-- 𝘧ind the first legal time slice from 𝘥1 to the final depth.
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
levels={
  {
    name="1 address",
    target={ ["0001"]=16 },
    pass=16,
    hint="x on q0",
    lesson="x flips one bit"
  },
  {
    name="2 split",
    target={ ["0000"]=8,["0001"]=8 },
    pass=11,
    hint="h on q0",
    lesson="h gives two outcomes"
  },
  {
    name="3 linked pair",
    target={ ["0000"]=8,["0011"]=8 },
    pass=11,
    hint="h q1, cx q1>q0",
    lesson="cx links bits"
  },
  {
    name="4 three-link",
    target={ ["0000"]=8,["1111"]=8 },
    pass=11,
    hint="h q3, chain to q0",
    lesson="one bit links four"
  }
}
--------- quantum router game ---------
function load_level(index)
  level_index=index
  level=levels[level_index]
  grid=blank_grid()
  counts=blank_counts()
  cursor_q=2
  fresh_q=-1
  fresh_d=0
  fresh_gate=""
  fresh_timer=0
  blocked_q=-1
  blocked_target=-1
  blocked_text=""
  blocked_timer=0
  result_ready=false
  passed=false
  score=0
  attempts=0
  x_was_down=false
  z_was_down=false
  left_was_down=false
  right_was_down=false
  cx_control=-1
  cx_target=-1
  cx_moved=false
  h_q=-1
end

function append_gate(grid,q,gate)
  local d=find_gate_depth(grid,q,gate)
  if d>0 then grid[q+1][d]=gate end
  return d
end

function measure_circuit()
  counts=run_grid(grid)
  score=distribution_score(counts,level.target)
  attempts=attempts+1
  result_ready=true
  passed=score>=level.pass
end

function advance_level()
  if level_index<#levels then
    load_level(level_index+1)
  else
    game_complete=true
  end
end

function edit_circuit()
  result_ready=false
  passed=false
end

function cx_target_right(q)
  if q==0 then
    return num_qubits-1
  end
  return q-1
end

function cx_target_left(q)
  if q==num_qubits-1 then
    return 0
  end
  return q+1
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
  circfill(x+3,y+3,2,color)
end

function draw_target_plus(x,y,color)
  circ(x+3,y+3,2,color)
  line(x+1,y+3,x+5,y+3,color)
  line(x+3,y+1,x+3,y+5,color)
end

function draw_h_gate(x,y,color)
  line(x+2,y+2,x+2,y+4,color)
  line(x+4,y+2,x+4,y+4,color)
  line(x+2,y+3,x+4,y+3,color)
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

function _init()
  game_complete=false
  load_level(1)
end

function _update()
  if (fresh_timer>0) fresh_timer-=1
  if (blocked_timer>0) blocked_timer-=1

  if game_complete then
    if btnp(4) then
      game_complete=false
      load_level(1)
    end
    return
  end

  if result_ready and passed then
    if btnp(2) then
      advance_level()
    elseif btnp(4) then
      edit_circuit()
    end
    return
  end

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
  if z_pressed and not x_down then h_q=cursor_q end

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
    edit_circuit()
    cx_control=-1
    cx_target=-1
    cx_moved=false
  end

  if z_released then
    if h_q>=0 and not x_down then
      try_add_gate(h_q,"h")
      edit_circuit()
    end
    h_q=-1
  end

  if btnp(2) and not x_down then
    measure_circuit()
  elseif btnp(3) and not x_down then
    clear_qubit_gates(grid,cursor_q)
    fresh_timer=0
    blocked_timer=0
    edit_circuit()
  end

  x_was_down=x_down
  z_was_down=z_down
  left_was_down=left_down
  right_was_down=right_down
end

-- 𝘳otated composer:
-- qubits are columns; d1 begins at the bottom and depth grows upward.
-- 𝘵he selected qubit column is highlighted because depth now fills
-- automatically, matching the original 𝘲ilin gate queue.
function draw_circuit()
  local controller=layout.controller
  local grid_layout=controller.grid
  local depth_index=controller.depth_index
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
    local label_color=visual_col%2==0 and 13 or 6

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
      local selector_x=
        controller_x+qubit_selector.x+
        visual_col*grid_layout.col_pitch
      local selector_y=controller_y+qubit_selector.y
      pset(selector_x+1,selector_y,label_color)
      pset(selector_x,selector_y+1,label_color)
      pset(selector_x+2,selector_y+1,label_color)
    end
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

      local symbol_color=1
      local cell_color=visual_col%2==0 and 13 or 6

      rectfill(
        x,
        y,
        x+grid_layout.cell_w,
        y+grid_layout.cell_h,
        cell_color
      )

      if is_control then
        draw_control_dot(x,y,symbol_color)
      elseif is_target then
        draw_target_plus(x,y,symbol_color)
      else
        if gate=="x" then
          draw_target_plus(x,y,symbol_color)
        elseif gate=="h" then
          draw_h_gate(x,y,symbol_color)
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

        line(control_x+3,y+3,target_x+3,y+3,1)
        draw_control_dot(control_x,y,1)
        draw_target_plus(target_x,y,1)
      end
    end
  end

  -- preview the cnot that x release will commit.
  if btn(5) and cx_moved and cx_target!=cx_control then
    local gate="c"..cx_target
    local d=find_gate_depth(grid,cx_control,gate)
    if d>0 then
      local preview_color=7
      local visual_row=circuit_depth-d
      local y=grid_y+visual_row*grid_layout.row_pitch
      local control_x=grid_x+
        (num_qubits-1-cx_control)*grid_layout.col_pitch
      local target_x=grid_x+
        (num_qubits-1-cx_target)*grid_layout.col_pitch
      line(control_x+3,y+3,target_x+3,y+3,preview_color)
      draw_control_dot(control_x,y,preview_color)
      draw_target_plus(target_x,y,preview_color)
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

function mission_print_centered(text,y,color)
  local mission=layout.mission
  print_centered_in_region(
    text,
    mission.x,
    mission.y+y,
    mission.w,
    color
  )
end

-- developer-owned mission canvas. replace this function with dialogue,
-- progress, icons, or other game-specific mission content.
function draw_mission()
  local mission=layout.mission
  clip(mission.x,mission.y,mission.w,mission.h)
  mission_print_centered(level.name,0,10)

  if result_ready and passed then
    mission_print_centered(level.lesson,10,11)
    mission_print_centered("score "..score.."/16 up next",19,11)
  elseif result_ready then
    mission_print_centered(level.hint,10,6)
    mission_print_centered("score "..score.."/16 retry",19,8)
  else
    mission_print_centered(level.hint,10,6)
  end
  clip()
end

function draw_room(x,y,state,wanted,count,w,h)
  local edge=wanted and 8 or 5
  local fill=count>0 and 1 or 0

  rectfill(x,y,x+w-1,y+h-1,fill)
  rect(x,y,x+w-1,y+h-1,edge)
  print(state,x+flr((w-16)/2),y+2,6)

  if count>0 then
    circfill(x+5,y+h-5,2,11)
    print(count,x+10,y+h-7,11)
  else
    pset(x+5,y+h-5,5)
    print("-",x+10,y+h-7,5)
  end
end

function draw_rooms()
  local response=layout.response
  local rooms=response.rooms

  for i=1,#states do
    local state=states[i]
    local col=(i-1)%rooms.cols
    local row=flr((i-1)/rooms.cols)
    draw_room(
      response.x+rooms.x+col*rooms.col_pitch,
      response.y+rooms.y+row*rooms.row_pitch,
      state,
      (level.target[state] or 0)>0,
      counts[state] or 0,
      rooms.w,
      rooms.h
    )
  end
end

function draw_complete()
  cls(1)
  print_centered("router complete",42,11)
  print_centered("circuits change outcomes",58,7)
  print_centered("and correlations",67,7)
  print_centered("🅾️ replay",88,10)
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
      key_map.color
    )
  end

  local examples=key_map.control_examples
  local color=examples.color
  draw_target_plus(key_x+examples.x.x,key_y+examples.x.y,color)
  draw_h_gate(key_x+examples.h.x,key_y+examples.h.y,color)

  print(
    examples.run.text,
    key_x+examples.run.x,
    key_y+examples.run.y,
    color
  )
  print(
    examples.clear.text,
    key_x+examples.clear.x,
    key_y+examples.clear.y,
    color
  )

  local cx=examples.cx
  line(
    key_x+cx.control_x+3,key_y+cx.y+3,
    key_x+cx.target_x+3,key_y+cx.y+3,color
  )
  draw_control_dot(key_x+cx.control_x,key_y+cx.y,color)
  draw_target_plus(key_x+cx.target_x,key_y+cx.y,color)
end

function _draw()
  if game_complete then
    draw_complete()
    return
  end

  cls(0)
  draw_key_hint()

  local op_feedback=layout.operation_feedback
  local op_feedback_x=op_feedback.x
  local op_feedback_y=op_feedback.y

  if btn(5) and cx_control>=0 then
    local text="x q"..visual_q(cx_control).." on release"
    if cx_moved and cx_target==cx_control then
      text="cx cancel on release"
    elseif cx_moved then
      text="cx q"..visual_q(cx_control)..
        ">q"..visual_q(cx_target).." on release"
    end
    print_centered_in_region(text,op_feedback_x,op_feedback_y,op_feedback.w,13)
  elseif btn(4) and h_q>=0 then
    print_centered_in_region(
      "h q"..visual_q(h_q).." on release",
      op_feedback_x,op_feedback_y,op_feedback.w,13
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
  end

  draw_circuit()
  draw_mission()
  draw_rooms()
end
