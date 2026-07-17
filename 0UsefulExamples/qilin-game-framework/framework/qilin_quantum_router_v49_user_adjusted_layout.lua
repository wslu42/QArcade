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
states={"000","001","010","011","100","101","110","111"}

-- centralized layout contract
--
-- coordinate rule:
-- top-level block.x/y + local element offset
layout={
  controller={
    x=14-8,
    y=11-4,
    w=40,
    h=59,

    grid={
      x=0,
      y=2,
      cell_w=8,
      cell_h=8,
      col_pitch=11,
      row_pitch=11
    },

    depth_index={
      x=32,
      y=2,
      text_dy=2
    },

    depth_flow={
      x=34,
      y=2,
      gap_dy=-2
    },

    qubit_index={
      x=0+1,
      y=47
    },

    qubit_selector={
      x=2+1,
      y=53
    }
  },

  key_map={
    x=62-4,
    y=11-4,
    w=66,
    h=22,

    items={
      {text="🅾️⬆️ x",x=0,y=0},
      {text="🅾️⬇️ h",x=33,y=0},
      {text="🅾️⬅️/🅾️➡️ cnot",x=0,y=8},
      {text="⬇️ clr",x=8,y=16},
      {text="❎ run",x=41,y=16}
    }
  },

  operation_feedback={
    x=62-4,
    y=30,
    w=66,
    h=6
  },

  mission={
    x=46,
    y=36,
    w=82,
    h=30,

    title={
      x=0,
      y=0,
      w=82,
      h=6
    },

    instruction={
      x=0,
      y=10,
      w=82,
      h=6
    },

    feedback={
      x=0,
      y=19,
      w=82,
      h=6
    }
  },

  -- full rectangular quantum response area.
  -- screen bounds: x=0..127, y=66..127.
  -- includes:
  --   reserved top band:    y=66..85
  --   response content:     y=86..122
  --   bottom padding:       y=123..127
  response={
    x=0,
    y=66,
    w=128,
    h=62,

    legend={
      x=0,
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
      x=2,
      y=30,
      w=126,
      h=17,

      base_y=16,
      first_state_x=0,
      state_pitch=16
    },

    state_index={
      x=1,
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
    if (
      sub(gate,1,1)=="c" and
      tonum(sub(gate,2,2))==q
    ) then
      return true
    end
  end

  return false
end

-- 𝘧ind the first legal time slice from 𝘥1 to 𝘥3.
-- 𝘹/𝘩 occupy one qubit. 𝘤𝘹 occupies both control and target.
-- 𝘳eturn 0 when no legal depth exists; never shift old gates.
function append_gate(grid,q,gate)
  local target=-1

  if sub(gate,1,1)=="c" then
    target=tonum(sub(gate,2,2))
  end

  for d=1,circuit_depth do
    local free=not qubit_busy(grid,q,d)

    if target>=0 then
      free=free and not qubit_busy(grid,target,d)
    end

    if free then
      grid[q+1][d]=gate
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
    target={ ["001"]=16 },
    pass=16,
    hint="x on q3",
    lesson="x flips one bit"
  },
  {
    name="2 split",
    target={ ["000"]=8,["001"]=8 },
    pass=11,
    hint="h on q3",
    lesson="h gives two outcomes"
  },
  {
    name="3 linked pair",
    target={ ["000"]=8,["011"]=8 },
    pass=11,
    hint="h q2, cx 2>3",
    lesson="cx links bits"
  },
  {
    name="4 three-link",
    target={ ["000"]=8,["111"]=8 },
    pass=11,
    hint="h q1, cx 1>2,1>3",
    lesson="one bit links all"
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
    return 2
  end
  return q-1
end

function cx_target_left(q)
  if q==2 then
    return 0
  end
  return q+1
end

function visual_q(q)
  return num_qubits-q
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
  circfill(x+4,y+4,1,color)
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
    if btnp(5) then
      advance_level()
    elseif btnp(4) then
      edit_circuit()
    end
    return
  end

  local changed=false

  -- 𝘰riginal 𝘲ilin controls:
  -- hold z/o and press a direction to append a gate.
  if btn(4) then
    if btnp(2) then
      changed=try_add_gate(cursor_q,"x")
    end

    if btnp(3) then
      changed=try_add_gate(cursor_q,"h")
    end

    if btnp(1) then
      local gate="c"..cx_target_right(cursor_q)
      changed=try_add_gate(cursor_q,gate)
    end

    if btnp(0) then
      local gate="c"..cx_target_left(cursor_q)
      changed=try_add_gate(cursor_q,gate)
    end
  else
    -- 𝘸ithout z/o, left and right select the qubit column.
    if btnp(0) then
      cursor_q=mid(0,cursor_q+1,num_qubits-1)
    end

    if btnp(1) then
      cursor_q=mid(0,cursor_q-1,num_qubits-1)
    end

    -- 𝘰riginal 𝘲ilin clears the selected qubit queue with down.
    if btnp(3) then
      clear_qubit_gates(grid,cursor_q)
      fresh_timer=0
      blocked_timer=0
      changed=true
    end
  end

  if changed then
    edit_circuit()
  end

  -- 𝘱𝘪𝘤𝘰-8 x button runs the circuit and measures 16 shots.
  if btnp(5) then
    measure_circuit()
  end
end

-- 𝘳otated composer:
-- qubits are columns; d1 begins at the bottom and depth grows upward.
-- 𝘵he selected qubit column is highlighted because depth now fills
-- automatically, matching the original 𝘲ilin gate queue.
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
    local label="q"..(visual_col+1)
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

  -- qubit wires are derived from controller grid geometry.
  -- they therefore move and resize with the grid automatically.
  local wire_local_x=flr(grid_layout.cell_w/2)
  local wire_top_y=grid_y-2
  local wire_bottom_y=
    grid_y+
    (circuit_depth-1)*grid_layout.row_pitch+
    grid_layout.cell_h+
    2

  for visual_col=0,num_qubits-1 do
    local x=
      grid_x+
      visual_col*grid_layout.col_pitch+
      wire_local_x

    line(x,wire_top_y,x,wire_bottom_y,5)
    line(x-2,grid_y,x,wire_top_y,5)
    line(x+2,grid_y,x,wire_top_y,5)
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
      "d"..d,
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

      local symbol_color=7
      local border_color=5

      if is_fresh_pair or is_fresh_single then
        symbol_color=13
        border_color=13
      end

      rectfill(
        x,
        y,
        x+grid_layout.cell_w,
        y+grid_layout.cell_h,
        1
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

      if is_fresh_single and fresh_timer>21 then
        rect(
          x-1,
          y-1,
          x+grid_layout.cell_w+1,
          y+grid_layout.cell_h+1,
          13
        )
      end
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
  local title=mission.title
  local instruction=mission.instruction

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
  local feedback=mission.feedback

  local feedback_x=mission.x+feedback.x
  local feedback_y=mission.y+feedback.y

  if result_ready and passed then
    draw_prompt_line(level.lesson,11)

    print_centered_in_region(
      "score "..score.."/16 next",
      feedback_x,
      feedback_y,
      feedback.w,
      11
    )
  elseif result_ready then
    draw_prompt_line(level.hint,6)

    print_centered_in_region(
      "score "..score.."/16 retry",
      feedback_x,
      feedback_y,
      feedback.w,
      8
    )
  else
    draw_prompt_line(level.hint,6)
  end
end

function draw_histogram()
  local response=layout.response
  local legend=response.legend
  local canvas=response.canvas
  local state_index=response.state_index

  local legend_x=response.x+legend.x
  local legend_y=response.y+legend.y
  local canvas_x=response.x+canvas.x
  local canvas_y=response.y+canvas.y
  local state_x=response.x+state_index.x
  local state_y=response.y+state_index.y

  local base_y=canvas_y+canvas.base_y
  local unit_h=1

  rect(
    legend_x+legend.target.box_x,
    legend_y,
    legend_x+legend.target.box_x+4,
    legend_y+4,
    8
  )

  print(
    "target",
    legend_x+legend.target.text_x,
    legend_y,
    6
  )

  rectfill(
    legend_x+legend.measured.box_x,
    legend_y,
    legend_x+legend.measured.box_x+4,
    legend_y+4,
    11
  )

  print(
    "measured",
    legend_x+legend.measured.text_x,
    legend_y,
    6
  )

  for i=1,#states do
    local state=states[i]

    local x=
      canvas_x+
      canvas.first_state_x+
      (i-1)*canvas.state_pitch

    local target_h=(level.target[state] or 0)*unit_h
    local count_h=(counts[state] or 0)*unit_h

    line(x+4,base_y-16,x+4,base_y,1)

    if target_h>0 then
      rect(x,base_y-target_h,x+8,base_y,8)
    end

    if count_h>0 then
      rectfill(
        x+2,
        base_y-count_h+1,
        x+6,
        base_y-1,
        11
      )
    end

    print(
      state,
      state_x+
        (i-1)*state_index.state_pitch-1,
      state_y,
      6
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
      5
    )
  end
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

  if blocked_timer>0 then
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
  draw_status()
  draw_histogram()
end
