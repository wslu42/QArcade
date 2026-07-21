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
circuit_depth=3
shots=16
valid_threshold=5
states={"000","001","010","011","100","101","110","111"}
lane_mode="binary"
lane_orders={
  binary={
    "000","001","010","011",
    "100","101","110","111"
  },
  gray={
    "000","001","011","010",
    "110","111","101","100"
  }
}

function active_lane_order()
  return lane_orders[lane_mode] or lane_orders.binary
end

-- centralized layout contract
--
-- coordinate rule:
-- top-level block.x/y + local element offset
layout={
  controller_left={
    anchor="bottom_left",
    player="p1",
    x=0,
    y=94,
    w=29,
    h=34,

    grid={
      x=5,
      y=1,
      cell_w=6,
      cell_h=6,
      col_pitch=8,
      row_pitch=8
    },

    -- mirror the depth-label side only; retain qubit order.
    depth_index={
      x=1,
      y=2,
      text_dy=0
    },

    qubit_index={
      x=5,
      y=25
    },

    qubit_selector={
      x=7,
      y=31,
      w=3,
      h=2,
      style="pixel_caret"
    }
  },

  -- player-two controller remains anchored to the bottom right.
  controller={
    anchor="bottom_right",
    player="p2",
    x=99,
    y=94,
    w=29,
    h=34,

    grid={
      x=1,
      y=1,
      cell_w=6,
      cell_h=6,
      col_pitch=8,
      row_pitch=8
    },

    depth_index={
      x=25,
      y=2,
      text_dy=0
    },

    qubit_index={
      x=1,
      y=25
    },

    qubit_selector={
      x=3,
      y=31,
      w=3,
      h=2,
      style="pixel_caret"
    }
  },

  key_map={
    x=29,
    y=94,
    w=70,
    h=34,
    color=6,
    action_color=13,

    items={
      {
        text="⬆️/e",action="run",
        x=2,y=2,label_x=19
      },
      {
        text="⬇️/d",action="clr",
        x=39,y=2,label_x=56
      },
      {
        text="❎/a",action="x",
        x=2,y=13,symbol_x=19,symbol_y=12
      },
      {
        text="🅾️/sf",action="h",
        x=39,y=13,symbol_x=56,symbol_y=12
      },
      {
        text="❎⬅️/❎➡️",action="cx",
        x=2,y=26,control_x=46,target_x=54,symbol_y=25
      }
    }
  },

  operation_feedback={
    x=0,
    y=104,
    w=86,
    h=6
  },

  mission={
    x=0,
    y=78,
    w=86,
    h=26
  },

  -- full response canvas: x=0..127, y=0..93.
  response={
    x=0,
    y=0,
    w=128,
    h=94,

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


-- ? qubit is busy at a depth if it has its own gate or is
-- the target of a ?? stored in another qubit's cell.
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

-- ?ind the first legal time slice from ?1 to the final depth.
-- ?/? occupy one qubit. ?? occupies both control and target.
-- ?eturn 0 when no legal depth exists; never shift old gates.
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

-- ?lear every operation involving the selected qubit, whether it is
-- a single-qubit gate, ?? control, or ?? target.
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

  -- ?ompile by circuit depth, not by qubit row.
  -- ?his preserves the left-to-right circuit order shown to students.
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

function run_grid_expected(grid)
  local measured=simulate(
    compile_grid(grid),"expected_counts",shots
  )
  local expected=blank_counts()
  for state,count in pairs(measured) do
    if expected[state]~=nil then
      expected[state]=count
    end
  end
  return expected
end

function default_valid_paddles()
  return { ["000"]=true }
end

--------- pvp controller state ---------
function reset_quantum_players()
  grid=blank_grid()
  counts=blank_counts()
  counts["000"]=shots
  valid_paddles=default_valid_paddles()
  cursor_q=0
  fresh_q=-1
  fresh_d=0
  fresh_gate=""
  fresh_timer=0
  blocked_q=-1
  blocked_target=-1
  blocked_text=""
  blocked_timer=0
  attempts=0
  x_was_down=false
  z_was_down=false
  left_was_down=false
  right_was_down=false
  cx_control=-1
  cx_target=-1
  cx_moved=false
  h_q=-1
  input_handoff=false
  mode_chord=false
  reset_player_states()
end

function capture_player_state()
  return {
    grid=grid,
    counts=counts,
    valid_paddles=valid_paddles,
    cursor_q=cursor_q,
    fresh_q=fresh_q,
    fresh_d=fresh_d,
    fresh_gate=fresh_gate,
    fresh_timer=fresh_timer,
    blocked_q=blocked_q,
    blocked_target=blocked_target,
    blocked_text=blocked_text,
    blocked_timer=blocked_timer,
    x_was_down=x_was_down,
    z_was_down=z_was_down,
    left_was_down=left_was_down,
    right_was_down=right_was_down,
    cx_control=cx_control,
    cx_target=cx_target,
    cx_moved=cx_moved,
    h_q=h_q
  }
end

function activate_player_state(index)
  local state=player_states[index]
  grid=state.grid
  counts=state.counts
  valid_paddles=state.valid_paddles
  cursor_q=state.cursor_q
  fresh_q=state.fresh_q
  fresh_d=state.fresh_d
  fresh_gate=state.fresh_gate
  fresh_timer=state.fresh_timer
  blocked_q=state.blocked_q
  blocked_target=state.blocked_target
  blocked_text=state.blocked_text
  blocked_timer=state.blocked_timer
  x_was_down=state.x_was_down
  z_was_down=state.z_was_down
  left_was_down=state.left_was_down
  right_was_down=state.right_was_down
  cx_control=state.cx_control
  cx_target=state.cx_target
  cx_moved=state.cx_moved
  h_q=state.h_q
end

function save_player_state(index)
  player_states[index]=capture_player_state()
end

function reset_player_ui()
  grid=blank_grid()
  counts=blank_counts()
  counts["000"]=shots
  valid_paddles=default_valid_paddles()
  cursor_q=0
  fresh_q=-1
  fresh_d=0
  fresh_gate=""
  fresh_timer=0
  blocked_q=-1
  blocked_target=-1
  blocked_text=""
  blocked_timer=0
  x_was_down=false
  z_was_down=false
  left_was_down=false
  right_was_down=false
  cx_control=-1
  cx_target=-1
  cx_moved=false
  h_q=-1
end

function reset_player_states()
  player_states={}
  player_states[1]=capture_player_state()
  reset_player_ui()
  player_states[2]=capture_player_state()
  activate_player_state(1)
end

function append_gate(grid,q,gate)
  local d=find_gate_depth(grid,q,gate)
  if d>0 then grid[q+1][d]=gate end
  return d
end

function measure_circuit()
  local candidate=run_grid_expected(grid)
  local next_valid={}
  local valid_count=0
  for state in all(states) do
    local valid=(candidate[state] or 0)>=valid_threshold
    next_valid[state]=valid
    if valid then valid_count+=1 end
  end
  attempts=attempts+1
  if valid_count>0 then
    counts=candidate
    valid_paddles=next_valid
    fresh_timer=30
    blocked_timer=0
    blocked_text=""
  else
    blocked_text="run invalid"
    blocked_timer=60
    fresh_timer=0
  end
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

function cancel_controller_input()
  cx_control=-1
  cx_target=-1
  cx_moved=false
  h_q=-1
end

function standard_buttons_up()
  for player_id=0,1 do
    for b=0,5 do
      if btn(b,player_id) then return false end
    end
  end
  return true
end

function begin_input_handoff()
  for index=1,2 do
    activate_player_state(index)
    cancel_controller_input()
    save_player_state(index)
  end
  activate_player_state(1)
  input_handoff=true
end

function update_input_handoff()
  for index=1,2 do
    activate_player_state(index)
    cancel_controller_input()
    save_player_state(index)
  end
  activate_player_state(1)
  if standard_buttons_up() then
    input_handoff=false
    for index=1,2 do
      activate_player_state(index)
      x_was_down=false
      z_was_down=false
      left_was_down=false
      right_was_down=false
      save_player_state(index)
    end
    activate_player_state(1)
  end
end

-- game-owned modal hook. extend this with dialogue or overlays.
function modal_confirm_pressed()
  return btnp(4,0) or btnp(4,1)
end

function modal_input_active()
  return menu_active
end

function update_modal_input()
  if not menu_input_ready then
    if standard_buttons_up() then menu_input_ready=true end
    return
  end

  if btnp(2,0) or btnp(2,1) then
    menu_selection-=1
    if menu_selection<1 then menu_selection=#lane_mode_options end
  elseif btnp(3,0) or btnp(3,1) then
    menu_selection+=1
    if menu_selection>#lane_mode_options then menu_selection=1 end
  elseif modal_confirm_pressed() then
    lane_mode=lane_mode_options[menu_selection]
    menu_active=false
    game_complete=false
    reset_quantum_players()
    init_pong()
    begin_input_handoff()
  end
end

function open_mode_menu(ready)
  lane_mode_options={"binary","gray"}
  menu_selection=lane_mode=="gray" and 2 or 1
  menu_active=true
  menu_input_ready=ready
end

-- game-owned hook for a future traditional/quantum mode switch.
function request_control_mode_switch()
end

function any_mode_chord_down()
  for player_id=0,1 do
    if btn(4,player_id) and btn(5,player_id) then
      return true
    end
  end
  return false
end

function update_mode_chord()
  if any_mode_chord_down() then
    mode_chord=true
    begin_input_handoff()
    input_handoff=false
  end

  if mode_chord then
    if standard_buttons_up() then
      mode_chord=false
      request_control_mode_switch()
      begin_input_handoff()
    end
  end
end

function active_input_owner()
  if game_complete then return "completion" end
  if modal_input_active() then return "modal" end
  if input_handoff then return "handoff" end
  if mode_chord or any_mode_chord_down() then
    return "mode_chord"
  end
  return "controller"
end

function _init()
  game_complete=false
  open_mode_menu(true)
end

function _update()
  local owner=active_input_owner()

  if owner=="completion" then
    if modal_confirm_pressed() then
      game_complete=false
      open_mode_menu(false)
    end
    return
  elseif owner=="modal" then
    update_modal_input()
    return
  elseif owner=="handoff" then
    update_input_handoff()
    return
  elseif owner=="mode_chord" then
    update_mode_chord()
    return
  end

  activate_player_state(1)
  for player_id=0,1 do
  if player_id==0 or not p2_is_npc then
  local state_index=player_id+1
  activate_player_state(state_index)
  if (fresh_timer>0) fresh_timer-=1
  if (blocked_timer>0) blocked_timer-=1

  local x_down=btn(5,player_id)
  local z_down=btn(4,player_id)
  local left_down=btn(0,player_id)
  local right_down=btn(1,player_id)
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

  if btnp(2,player_id) and not x_down then
    measure_circuit()
  elseif btnp(3,player_id) and not x_down then
    clear_qubit_gates(grid,cursor_q)
    fresh_timer=0
    blocked_timer=0
  end

  x_was_down=x_down
  z_was_down=z_down
  left_was_down=left_down
  right_was_down=right_down
  save_player_state(state_index)
  end
  end
  activate_player_state(1)
  update_pong()
end

-- ?otated composer:
-- qubits are columns; d1 begins at the bottom and depth grows upward.
-- ?he selected qubit column is highlighted because depth now fills
-- automatically, matching the original ?ilin gate queue.
function draw_controller(controller,player_id)
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
      local selector_x=controller_x+qubit_selector.x+
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

  if btn(5,player_id) and cx_moved and cx_target!=cx_control then
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

function draw_circuits()
  activate_player_state(1)
  draw_controller(layout.controller_left,0)
  if p2_is_npc then
    rectfill(99,94,127,127,0)
    rect(99,94,127,127,5)
    print("npc",107,101,8)
    print("classic",101,111,6)
    print("auto y",102,120,6)
  else
    activate_player_state(2)
    draw_controller(layout.controller,1)
  end
  activate_player_state(1)
end

function print_centered_in_region(text,x,y,w,color)
  local text_x=x+flr((w-#text*4)/2)
  if text_x<x then text_x=x end
  print(text,text_x,y,color)
end

function print_centered(text,y,color)
  print_centered_in_region(text,0,y,128,color)
end

--------- quantum pong ---------
p2_is_npc=true
win_score=5
court_top=7
court_bottom=93
paddle_h=9
paddle_x={5,120}
npc_speed=0.72

function lane_y(lane)
  return 13+lane*10
end

function init_pong()
  p1_score=0
  p2_score=0
  winner=0
  npc_y=48-flr(paddle_h/2)
  new_round(rnd(1)<0.5 and 1 or 2)
end

function new_round(toward_player)
  ball={
    x=63,y=48,
    dx=toward_player==1 and -0.65 or 0.65,
    dy=rnd(0.8)-0.4,
    size=2
  }
  serve_timer=45
end

function paddle_overlap(index)
  activate_player_state(index)
  local order=active_lane_order()
  for i=1,#order do
    local state=order[i]
    if valid_paddles[state] then
      local lane=i-1
      local py=lane_y(lane)-flr(paddle_h/2)
      local overlaps=
        ball.y+ball.size>=py and ball.y<=py+paddle_h
      if overlaps then
        activate_player_state(1)
        return true,lane
      end
    end
  end
  activate_player_state(1)
  return false,-1
end

function bounce_from_paddle(index,lane)
  local center=lane_y(lane)
  local ball_center=ball.y+ball.size/2
  ball.dy=mid(-1.25,ball.dy+(ball_center-center)*0.07,1.25)
  local speed=min(1.55,abs(ball.dx)+0.055)
  ball.dx=index==1 and speed or -speed
  ball.x=index==1 and paddle_x[1]+3 or paddle_x[2]-3
end

function player_run_status(index)
  activate_player_state(index)
  local invalid=blocked_timer>0 and blocked_text=="run invalid"
  activate_player_state(1)
  return invalid
end

function draw_valid_paddles(index)
  activate_player_state(index)
  local x=paddle_x[index]
  local color=index==1 and 12 or 8
  local order=active_lane_order()
  for i=1,#order do
    local state=order[i]
    if valid_paddles[state] then
      local y=lane_y(i-1)-flr(paddle_h/2)
      rectfill(x-1,y,x+3,y+paddle_h,color)
    end
  end
  activate_player_state(1)
end

function try_paddle_bounce(index)
  local hit,lane=paddle_overlap(index)
  if hit then
    bounce_from_paddle(index,lane)
    return true
  end
  return false
end

function update_npc()
  if not p2_is_npc then return end
  local target=48-flr(paddle_h/2)
  if ball.dx>0 then
    target=ball.y+ball.size/2-paddle_h/2
  end
  if npc_y<target then
    npc_y=min(npc_y+npc_speed,target)
  elseif npc_y>target then
    npc_y=max(npc_y-npc_speed,target)
  end
  npc_y=mid(court_top,npc_y,court_bottom-paddle_h)
end

function npc_paddle_overlap()
  return ball.y+ball.size>=npc_y and
    ball.y<=npc_y+paddle_h
end

function bounce_from_npc()
  local center=npc_y+paddle_h/2
  local ball_center=ball.y+ball.size/2
  ball.dy=mid(-1.25,ball.dy+(ball_center-center)*0.07,1.25)
  local speed=min(1.55,abs(ball.dx)+0.055)
  ball.dx=-speed
  ball.x=paddle_x[2]-3
end

function score_point(index)
  if index==1 then
    p1_score+=1
    if p1_score>=win_score then winner=1 end
    new_round(2)
  else
    p2_score+=1
    if p2_score>=win_score then winner=2 end
    new_round(1)
  end
  if winner>0 then game_complete=true end
end

function update_pong()
  update_npc()
  if serve_timer>0 then
    serve_timer-=1
    return
  end

  local old_x=ball.x
  ball.x+=ball.dx
  ball.y+=ball.dy

  if ball.y<=court_top then
    ball.y=court_top
    ball.dy=abs(ball.dy)
  elseif ball.y+ball.size>=court_bottom then
    ball.y=court_bottom-ball.size
    ball.dy=-abs(ball.dy)
  end

  if ball.dx<0 and old_x>paddle_x[1] and
    ball.x<=paddle_x[1]+2 then
    try_paddle_bounce(1)
  elseif ball.dx>0 and old_x<paddle_x[2] and
    ball.x+ball.size>=paddle_x[2] then
    if p2_is_npc then
      if npc_paddle_overlap() then bounce_from_npc() end
    else
      try_paddle_bounce(2)
    end
  end

  if ball.x+ball.size<0 then
    score_point(2)
  elseif ball.x>127 then
    score_point(1)
  end
end

function draw_pong()
  clip(0,0,128,94)
  cls(0)
  rect(0,court_top,127,court_bottom,5)

  local order=active_lane_order()
  for lane=0,7 do
    local y=lane_y(lane)
    if lane<7 then line(11,y+5,116,y+5,1) end
    print(order[lane+1],58,y-2,5)
  end

  for y=court_top+2,court_bottom-2,6 do
    pset(63,y,6)
  end

  draw_valid_paddles(1)
  if p2_is_npc then
    rectfill(
      paddle_x[2]-1,npc_y,
      paddle_x[2]+3,npc_y+paddle_h,8
    )
  else
    draw_valid_paddles(2)
  end
  rectfill(ball.x,ball.y,ball.x+ball.size,ball.y+ball.size,7)
  print("p1 "..p1_score,13,1,12)
  print(p2_score..(p2_is_npc and " npc" or " p2"),91,1,8)
  local mode_label=lane_mode=="gray" and "gry" or "bin"
  print(mode_label..">="..valid_threshold,51,1,6)
  if player_run_status(1) then print("invalid",29,1,8) end
  if not p2_is_npc and player_run_status(2) then
    print("invalid",73,1,8)
  end
  if serve_timer>0 then print_centered("ready",44,10) end
  clip()
end

function draw_mode_menu()
  cls(0)
  print_centered("quantum pong",10,10)
  print_centered("choose lane order",24,6)

  for i=1,#lane_mode_options do
    local y=38+(i-1)*20
    local selected=i==menu_selection
    if selected then rectfill(22,y-3,105,y+10,5) end
    local color=selected and 7 or 6
    local label=i==1 and "binary / x-friendly" or
      "gray / h-friendly"
    print_centered(label,y,color)
    if i==1 then
      print_centered("000 001 010 011 ...",y+7,13)
    else
      print_centered("000 001 011 010 ...",y+7,13)
    end
  end

  print_centered("p1 quantum vs npc classic",81,12)
  print_centered("up/down select",99,6)
  print_centered("o start",111,10)
end

function draw_complete()
  cls(1)
  print_centered("player "..winner.." wins",42,11)
  print_centered("quantum paddle champion",58,7)
  print_centered(p1_score.." - "..p2_score,68,10)
  print_centered("o mode menu",88,10)
end

function draw_key_hint()
  local key_map=layout.key_map
  local key_x=key_map.x
  local key_y=key_map.y
  local action_color=key_map.action_color

  for item in all(key_map.items) do
    print(item.text,key_x+item.x,key_y+item.y,key_map.color)

    if item.action=="x" then
      draw_target_plus(
        key_x+item.symbol_x,
        key_y+item.symbol_y,
        action_color
      )
    elseif item.action=="h" then
      draw_h_gate(
        key_x+item.symbol_x,
        key_y+item.symbol_y,
        action_color
      )
    elseif item.action=="cx" then
      local control_x=key_x+item.control_x
      local target_x=key_x+item.target_x
      local symbol_y=key_y+item.symbol_y
      line(
        control_x+3,symbol_y+3,
        target_x+3,symbol_y+3,
        action_color
      )
      draw_control_dot(control_x,symbol_y,action_color)
      draw_target_plus(target_x,symbol_y,action_color)
    else
      print(
        item.action,
        key_x+item.label_x,
        key_y+item.y,
        action_color
      )
    end
  end
end

function _draw()
  if game_complete then
    draw_complete()
    return
  end

  if menu_active then
    draw_mode_menu()
    return
  end

  cls(0)

  -- reserve the lower band for two controllers and the stacked key map.
  draw_pong()
  draw_circuits()
  draw_key_hint()
end
