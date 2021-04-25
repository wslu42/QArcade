pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function _init()
 x0,y0=68,68
 x,y = x0,y0
 sp=1

-------------------------------
 pb = {}
 pb.x ,pb.y = 40,40
 pb.sp      = 18

 p={}
 for i=1,8,1 do
  c={}       c.sp = i+17
  c.dx,c.dy= 8*i-8,0
  c.show   = true
  p[i]=c
 end

-------------------------------

end
-->8
function _update()
 
 local dx,dy = 0,0
 if not (btn(5,0) or btn(4,0)) then
	 if (btn(⬅️)) dx-=1 
	 if (btn(➡️)) dx+=1
	 if (btn(⬆️)) dy-=1 
	 if (btn(⬇️)) dy+=1
 end

 pb.x += dx
 pb.y += dy

 for i,v in pairs(p) do
  v.x=pb.x
  v.y=pb.y end

 if (btnp(❎)) then
  r = rnd({1,2,3,4,5,6,7,8})
  for i,v in pairs(p) do
   if (i==r) v.show=false
  end
 end

 if (btnp(🅾️)) then
  for i,v in pairs(p) do
   v.show=true
  end
 end
 
--  qn = 3
--	 counts = 2*2^qn
	 
--	 qc = quantumcircuit()
--	 qc.set_registers(qn,qn)
--	 qc.x(0)
--	 for i = 0,1,1 do qc.h(i) end
	
--	 for i = 0,qn-1,1 do
--	  qc.measure(i,i) end
--	 res = simulate(qc,"counts",counts)
--	
--	 st,ct = stct(res,3)
-- 

     
end
-->8
function _draw()

 cls()

 for i,v in pairs(p) do
  if v.show then
   spr(v.sp,v.x+v.dx,
            v.y+v.dy) end
 end

end
-->8
--------- microqiskit ---------

---- math.p8 ----
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
---- microqiskit.lua ----
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
-->8
function stct(qcsim,llm)
	-- take: results from qc simulate.
	-- return: states [table] and counts [table].
	 local st,ct,l={},{},1
	 if (llm == nil) llm=0
	 for i,v in pairs(qcsim) do
	  if v>llm then
 	  st[l],ct[l] = i,v
	   l+=1
	  end
	 end
	 return st,ct
	end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800070770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00800800070770700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000020040000000000008009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900900000000000fddddf0008eee0007666670002888000fb0000000e00b7007b00e0000000bf0000000000000000000000000000000000000000000000000
090990900000000003bbbbb000eeeee00baaaaa0008888804dbff8200eed7a6886a7dee0028ffbd4000000000000000000000000000000000000000000000000
009009000000000000ffff00007d7d000077770000f1f1000dbf18800ee77a6006a77ee00881fbd0000000000000000000000000000000000000000000000000
0090090000000000001f1f000077770000d7d70000ffff000dbff8800eed7a6006a7dee0088ffbd0000000000000000000000000000000000000000000000000
0909909000000000088888000aaaaab00eeeee000bbbbb302dbf188008e77a6996a77e800881fbd2000000000000000000000000000000000000000000000000
0090090000000000008882000766667000eee8000fddddf00f30080000000a7007a00000008003f0000000000000000000000000000000000000000000000000
00000000000000000000000000900800000000000040020000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a00a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0aa00a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a00aa0a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00a00a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0bb0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b0bb0b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000b0700c0700f0701107013070160701b0701f0702207027070297702e77034770377703a7703c7703e7703e7503d7403d7303b7303a730397303673033720307202b730287402575023760217701e770
000100000004038740317402d7402b7402a7402774025740237401f7401d7401a7401674014740117400f7400d7400c7400a74009740097400874007740077400774006740067400574004740047400374002730
000100001575018750237502b7502e75028750237501f75019750137500d7500575002750077502d750277501e75017750137500a7502375025750217501875010750337502a75025750217501b7501875016750
000100001715000000000000000000000000000000000000000000000033150000000000000000000000000000000000001e15000000000000000000000000000000000000000003515000000000000000000000
000100000000000000000000000016250000000000000000000000000022250000000000000000000000000008250000002c250000000000003250000002a2500000000000000000000000000000000000000000
