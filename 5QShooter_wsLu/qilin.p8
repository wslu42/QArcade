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

-->8
---------- func_cust ----------
function wait(t) 
  for i = 1,t*33 do flip() end
end

-------------------------------
function qcmeas(qc,llm)
  for i = 0,2,1 do
    qc.measure(i,i) end
  -- handle string {'state':counts} from qc.meas
  local m = simulate(qc,"counts",16)
  -- translate to (state,counts)
  local st,ct,j = {},{},1
  for i,v in pairs(m) do
    st[j]=i   ct[j]=v   j=j+1
  end
  -- cut only significant state w/ counts > llm
  local st_sig = {}
  for i,v in pairs(ct) do
    if tonum(v)>llm then
      st_sig[i]=st[i] end
  end

  return st_sig
end

--------------------------------
function tb2str (src, s2t)
 -- convert tb_of_str to str
 -- reverse action by s2t="s2t"
  local tar = -1
  if s2t=="s2t" then
    tar = {}
    for i = 1,#src do
      tar[i] = sub(src,i,i)
    end
  else
    tar = ""
    for i,v in pairs(src) do
      tar = tar..v
    end
  end
  return tar
end
--------------------------------
function bstrtb2dtb(bstrtb)
  valtb = {}
  for i,v in pairs(bstrtb) do
    local n=0
    for j = 1,#v do 
      n+=tonum(sub(v,j,j))*2^(#v-j)
    end 
    add(valtb,(7-n)*8+48)
  end
  return valtb
end
--------------------------------
function rintx(n,o,s)
 if (n==nil) n=8
 if (o==nil) o=6
 if (s==nil) s=8
 -- return a pure integer
 return (flr(rnd(n))+o)*s
end
--------------------------------
function tbsort(tb)
  for i=1,#tb do
    local j = i
    while j>1 and tb[j-1]>tb[j] do
      tb[j],tb[j-1] = tb[j-1],tb[j]
      j = j - 1
    end
  end
end
--------------------------------
function tbcmpr(a,b)
  tbsort(a)
  tbsort(b)
  if (#a!=#b) return false
	for i=1,#a do
		if (a[i]!=b[i]) return false
	end
	return true
end

--------------------------------
function elgen(eltype, tbas)
  local el={}
  if eltype=='2enemy' then
    local x1 = rintx()
    local x2 = rintx()
    while x2==x1 do	
      x2 = rintx()
    end
    el.x = {x1,x2}
    tbsort(el.x)
    el.y,el.dy = 0,endrop
    el.s = {1,5}
  elseif eltype=='1enemy' then
    local x1 = rintx()
    el.x = {x1}
    el.y,el.dy = 0,endrop
    el.s = {2}
  elseif eltype=='bullet' then
    if tbas==nil then
      local x1 = rintx()
      local x2 = rintx()
      while x2==x1 do	
        x2 = rintx()
      end
    tbas = {x1,x2}
    end
    el.x = tbas
    tbsort(el.x)
    el.y,el.dy = 115,lsrspd
    el.s = 24
  end
 -- el = {el.x,el.y,el.dy,el.s}
 -- ex: { {64,72},127, 0, 24 }
  return el
end

-------------------------------
function ani_init(anitb,
  anisec,
  fmdark)
  fmct=0
  ani_ini = false
  fps = 0.03
  anifm = anisec\fps

  fmtb = {}
  for i=1,#anitb do
    for j=1,anifm\#anitb do
    add(fmtb,anitb[i]) end
  end
  for i=1,anifm%#anitb do
  add(fmtb,fmdark) end
end
--------------------------------
function ani_draw(ani_act,x,y)
  if ani_ini then fmct+=1
  else fmct=0 end

  if (ani_act and fmct==0) then
  ani_ini=true
  end

  if (ani_ini==true and fmct<anifm) then
  spr(fmtb[fmct],x,y)
  elseif fmct==anifm then
    ani_ini=false
  end
end


-->8
------------ menu_ ------------
function menu_init()
  menu={x=16, y=32, w=96,
        h=60, m=8 , offset=0,
        sel_sp = 22, fmlast = 0}
  menu.s=menu.m+2
  menu.sel_x = menu.x+menu.m
  menu.sel_y = menu.y+menu.s
  
  anitb = {} -- sprites that constitutes the animation
  for i=8,13 do add(anitb,i) end
  ani_init(anitb, 1, 21)

		stars={}
 	for i=1,16 do
	 	add(stars,{x=rnd(128),
		 											y=rnd(128),
			 										d=rnd(2)+1,
			 										c=rnd(2)+5})
	 end

end
-------------------------------
function menu_update()
  dy = 0
  if (btnp(⬇️)) dy += menu.s sfx(13)
  if (btnp(⬆️)) dy -= menu.s sfx(13)
  menu.sel_y += dy
  if (menu.sel_y == menu.y) menu.sel_y=menu.y+menu.s*3
  if (menu.sel_y == menu.y+menu.s*4) menu.sel_y=menu.y+menu.s

	 for st in all(stars) do
	 	st.y+=st.d
	 	if (st.y>128) st.y=0 st.x=rnd(128)
	 end

end
-------------------------------
function menu_draw()
  cls()
  for st in all(stars) do
		 pset(st.x,st.y,st.c)
		end
  
  pal(3,5)  pal(5,1)  pal(6,1) 
  pal(7,13) pal(8,2)  pal(9,2)
  pal(10,4) pal(11,3) pal(12,3)
  spr(1,6*8,1*8)
  for i=7,9 do spr(4,i*8,1*8) end
  spr(5,10*8,1*8)
  spr(2,13*8,1.8*8)
  spr(1,9*8,12*8)
  for i=10,11 do spr(4,i*8,12*8) end
  spr(5,12*8,12*8)
  for i=1,2 do spr(10,64+i*8,13*8) end
  for i=1,8 do spr(79+i,40+i*8,14*8) end
  spr(19,32,12*8) 
  spr(16,16,13*8)
  spr(19,24,13*8)
  spr(17,32,13*8)
  spr(6,32,14*8)
  
  rectfill(menu.x, menu.y, 
           menu.x+menu.w-1,
           menu.y+menu.h, 4)
  for i=112,116 do spr(i,36+8*(i-111),3*8) end
  for i=2,4 do spr(26,i*8,3.2*8) end
  for i=11,13 do spr(26,i*8,3.2*8) end
  for i=1,15 do pal(i,i) end

  menu_sel_color = 2
  menu_sel_color2= 15 --rmv: after color decided
  menu.offset, menu.sel_color = 0, menu_sel_color
  if (menu.sel_y == menu.y+menu.s*1) menu.offset = 4 menu.sel_color = menu_sel_color2
  print('story',     menu.x+menu.m*2+menu.offset, menu.y+menu.s*1, menu.sel_color)
  menu.offset, menu.sel_color = 0, menu_sel_color
  if (menu.sel_y == menu.y+menu.s*2) menu.offset = 4 menu.sel_color = menu_sel_color2
  print('sandbox',   menu.x+menu.m*2+menu.offset, menu.y+menu.s*2, menu.sel_color)
  menu.offset, menu.sel_color = 0, menu_sel_color
  if (menu.sel_y == menu.y+menu.s*3) menu.offset = 4 menu.sel_color = menu_sel_color2
  print('survivial', menu.x+menu.m*2+menu.offset, menu.y+menu.s*3, menu.sel_color)
  print(' hold z or 🅾️ to begin', menu.x, menu.y+menu.h-menu.m, menu_sel_color)

  spr(menu.sel_sp, menu.sel_x, menu.sel_y)

  if btn(🅾️) then
    sfx(2)
    local ssp=88
    if (framecouts%4 < 2) ssp=80
    sspr(ssp,8,8,8,menu.x+menu.m*2-2, menu.sel_y,48,8)
    ani_draw(true,menu.x+menu.m*2-2+48,menu.sel_y-1)

    -- animation lasts for 30 frames for key-holding effects
    if menu.fmlast <30 then 
      menu.fmlast+=1
    else 
      music(-1,1000)
      wait(2)
      mode.menu = false
      if (menu.sel_y==menu.y+menu.s*1) mode.stor = true
      if (menu.sel_y==menu.y+menu.s*2) mode.sand = true
      if (menu.sel_y==menu.y+menu.s*3) mode.surv = true
    end
  end
end

-->8
------------ stor_ ------------
function stor_init()

  dtb_init() -- numlines=3
  stor={}
  stor.op = {
  "welcome to the quantum da vinci program, _qdav_ for short. this is daedalus and i am your guide today.",
  "today we are going to test our newly developed quantum interference lasing neutralizer, or _qilin_ for short.",
  "it is a defense system prototype comes with two parts, (1) a dialing interface and (2) a coherent high power laser actuator.",
  "the dialing interface marked as _qc cmp_ in front of you used the ancient circuit composer technique, which accepts quantum gates as operations on a 3-qubit system, marked as qubit-2-1-0 from left to right.",
  "for available quantum operations such as not, hadamard, and cnot gates please check the four key combo listed up front.",
  "the cnot operation was defined as following: the qubit where cnot icon locates is the _control_ qubit, while the _target_ qubit is the one next to it.",
  "for example if you press 🅾️+➡️ on the left most qubit (2), you apply a cnot operation with control qubit 2 and target qubit 1.",
  "accordingly, if qubit 2 has been prepared in superposition state (by applying hadamard with 🅾️+⬇️) before the cnot operation, this will give you a _bell state_ entangling qubit 2 and qubit 1.",
  "which means after pressing ❎, you will very likely see _two_ laser beams shooting out from qilin at location marked as 110 _and_ 000, which has been shown here.",
  "by he way, if you press 🅾️+➡️ on the right most qubit (0), however, you end up applying a cnot operation with control qubit 0 and target qubit 2 (it's cyclic in both directions).",
  "ok, so what ❎ does is it initiates 16 shots quantum measurement for current commands in the queue of our dialing interface. however not all possible states from the measurement outcome are counted.",
  "we, unfortunately, have technical limits on the high power laser actuator and can _only_ send 2-3 beam at a time at most.",
  "as a result, among all possible outcomes we select those state with counts greater or equal to 4 and fire the corresponding coherent laser beams from positions marked with those red and white bars in the right panel",
  "red bars represent the certain qubit is in excited state (1) while white ones means ground state (0), for example the left most column in the right panel is 111 while the right most is 000.",
  "there will be enemy dropping from above, and your mission today is to eliminate the enemy at once with these coherent laser beams.",
  "a fair warning, this is a quantum machine which means it is possible that your quantum measurement did _not_ return all possible states you are expecting.",
  "next time you may skip this tutorial by choosing the _survival_ mode at the opening menu.",
  "please go ahead and try it out.",
  "happy shooting."}
  -- stor.op = { "the quantum interference lasing neutralizer, or qilin for short, is a defense system which was discovered near taiwan island on the seabed of philippine sea in 2142. this ancient device comes with two parts, a dialing interface and a laser actuator.",
  --             "an weaponized ancient laser came with two parts?",
  --             "yes. unlike contemporary solid state lasers, the civilization lived on the taiwan island several thousands years ago seems to be able to harvest extra energies from radioactive ions and weaponized it. my team has managed to recover the laser actuator by replacing the ion core with strontium-90 which was a direct biproduct from our nuclear fission plants. the dialing pad, however, requires sophisticated quantum operations which was similar to the old gate-based logic when quantum computation was firstly developed during the nisq-era more than a hundred years ago.",
  --             "great, an ancient defense system with a vintage control interface…",
  --             "i wish we have better options. i have only heard of this technology when I was writing a review article as a graduate student, but I will try my best to show you some working principles. and unfortunately you will have to improvise during the battle. are you up for a quick tutorial now?",
  --             "i think i still remember how to program a nisq quantum computer so let us get started",
  --             "any instruction will be helpful.",
  --             "ok so here is the dialing panel, or the quantum composer as how the ancients are calling it. now suppose we would like to initiate a laser at the left most position marked as three pink bars, we will need to input x gates on all qubit terminals by pressing z+up arrow key in front of each qubits. Try it out yourselves.",
  --           }
  
  stor.linn = 1
  stor.sp = {72,75}
  stor.spx = {1,95}
  stor.color = {6,15}
  stor_sp = stor.sp[2]
  stor_color = stor.color[1]
  stor_spx = stor.spx[2]
  stor.ask = "what say ya?"
  stor.btn = "press z to conti"
  stor.resp = {"yes", "no"}
  stor.sel = true
end

--------------------------------
function brint(text,x,y,c)
  for dx = -1,1 do
   for dy = -1,1 do
    print(text,x+dx,y+dy,0) 
   end
  end
  print(text,x,y,c) 
end

--------------------------------
-- dialogue text box library by oli414.
function dtb_init(n) 
  dtb_q={}
  dtb_f={}
  dtb_n=3 
  
  if n then 
   dtb_n=n 
  end
  
  _dtb_c()
end
--------------------------------
function dtb_update()
  if #dtb_q>0 then 
      if dtb_c==0 then 
          dtb_c=1 
      end 
      local z,x,q,c 
      z=#dtb_d 
      x=dtb_q[1]
      q=#dtb_d[z]
      c=q>=#x[dtb_c]
      
      if c and dtb_c>=#x then
          if btnp(🅾️) then 
              if dtb_f[1]~=0 then 
                  dtb_f[1]()
              end 
              del(dtb_f,dtb_f[1])
              del(dtb_q,dtb_q[1])_dtb_c()
              sfx(12)
              return 
          end 
      elseif dtb_c>0 then 
          dtb_l-=1 
          if not c then 
              if dtb_l<=0 then 
                  local v,h 
                  v=q+1 
                  h=sub(x[dtb_c],v,v)
                  dtb_l=1 
                  if h~=" " then 
                      sfx(11)
                  end 
                  if h=="." then 
                      dtb_l=6 
                  end 
                  dtb_d[z]=dtb_d[z]..h 
              end 
              if btnp(🅾️) then 
                  dtb_d[z]=x[dtb_c]
              end 
          else 
              if btnp(🅾️) then 
                  _dtb_l()
              end 
          end 
      end 
  end 
end
--------------------------------
function dtb_draw(color,sp,x)
  if #dtb_q>0 then 
    local z,o 
    z=#dtb_d 
    o=0 
    if dtb_c<z then 
        o=z-dtb_c 
    end 
    if (color==nil) color = 5
    rectfill(2-1,125-z*8,125-7,125,color)
    spr(sp,x,77,3,3)
      
    if dtb_c>0 and #dtb_d[#dtb_d]==#dtb_q[1][dtb_c] then 
        brint("\x8e",118-7,120-0,7)
    end 
    
    for i=1,z do 
        brint(dtb_d[i],4,i*8+119-(z+o)*8,7)
    end 
  end 
end
--------------------------------
function dtb_disp(t,c)
  local s,l,w,h,u
  s={}
  l=""
  w=""
  h=""
  u=function()	
      if #w+#l>29 then 
        add(s,l) l="" 
      end 
      l=l..w
      w=""
    end 

  for i=1,#t do
    h=sub(t,i,i)
    w=w..h
    if h==" " then 
      u()
    elseif #w>28 then
      w=w.."-"
      u()
    end
  end

  u()

  if l~="" then
    add(s,l)
  end

  add(dtb_q,s)

  if c==nil then 
    c=0 
  end 

  add(dtb_f,c)
end
--------------------------------
function _dtb_c()
  dtb_d={}
  for i=1,dtb_n do
      add(dtb_d,"")
  end
  dtb_c=0
  dtb_l=0
end
--------------------------------
function _dtb_l()
  dtb_c+=1
  for i=1,#dtb_d-1 do
      dtb_d[i]=dtb_d[i+1]
  end
  
  dtb_d[#dtb_d]=""
  sfx(12)
end
-->8
------------ sand_ ------------
function sand_init()

  cls()
  
  bltb = {}
  blrng = -128
  lsrspd= -18
  
  fmct=0
  kill=false
  --fps=30

  gttbrst = false
  gttb = {{},{},{}}
  qc = quantumcircuit()
  qc.set_registers(3,3)
  pss = {}

--  entb = {}  egen = true
--  enmy = {nm=2, s={1,5,3,2}, x={1*8,5*8}, y= 2*8, dy=2.5 }

  cmps = {s=6, x=3*8, y=14*8}

--  flying stars
  stars = {}
 	for i=1,16 do
	 	add(stars,{x=rnd(72)+44,
		 											y=rnd(128),
			 										d=rnd(2)+1,
			 										c=rnd(2)+5})
	 end

--animation test
-- anitb = {} -- sprites that constitutes the animation
-- for i=8,13 do add(anitb,i) end
-- ani_init(anitb, 1, 21)



end
-------------------------------
function sand_update()

  local qps = 3-cmps.x/8
  if btn(🅾️) then
    if btnp(⬆️) then -- press 🅾️+⬆️ append one x gate
      add(gttb[qps+1],"x") 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(⬇️) then -- press 🅾️+⬇️ append one h gate
      add(gttb[qps+1],"h") 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(➡️) then -- press 🅾️+➡️ append cx (control: current position; target: the qubit to its right)
      if qps == 0 then tgqb = 2
      else tgqb = qps-1
      end
      add(gttb[qps+1],"v"..qps..tgqb) 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(⬅️) then -- press 🅾️+⬅️ append cx (control: current position; target: the qubit to its left)
      if qps == 2 then tgqb = 0
      else tgqb = qps+1
      end
      add(gttb[qps+1],"c"..qps..tgqb)
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
  end
  if not btn(🅾️) then
    if (btnp(⬅️)) cmps.x = mid(1*8,cmps.x-1*8,3*8) sfx(13)
    if (btnp(➡️)) cmps.x = mid(1*8,cmps.x+1*8,3*8) sfx(13)    -- press ⬅️➡️ move player
    if (btnp(⬇️)) gttb[qps+1]={} sfx(14) -- press ⬅️➡️ clear gates on the current qubit
  end
  if (btnp(❎)) then -- press ❎ then fire/perform qcmeas
    for i,v in pairs(gttb) do
      for j,u in pairs(v) do
        local ch=sub(u,1,1)
        if ch=="x" then
          qc.x(i-1) 
        elseif ch=="h" then 
          qc.h(i-1)
        elseif ch=="v" then
          local ct = tonum(sub(u,3)) 
          qc.cx(i-1,ct) 
        elseif ch=="c" then 
          local ct = tonum(sub(u,3)) 
          qc.cx(i-1,ct)
        end
      end
    end

    pss = qcmeas(qc,3) -- store meas results
    -- handle laser
    pss_dec = bstrtb2dtb(pss)
    add(bltb,elgen('bullet',pss_dec))
    sfx(2)
    fire = true -- turn on fire flag

    qc = quantumcircuit() -- reset qc and gttb
    qc.set_registers(3,3) 
    gttb = {{},{},{}}
  end


		fmct+=1
  -- end
     -- laser limited by first enemy
  for el in all(bltb) do
    if el.y!=nil then
    if (el.y> blrng) el.y+=el.dy
    if (el.y<=blrng) del(bltb,el)
    end
  end

	 for st in all(stars) do
	 	st.y+=st.d
	 	if (st.y>125) st.y=3 st.x=rnd(72)+44
	 end

end
-------------------------------
function sand_draw()
      
	 for st in all(stars) do
		 pset(st.x,st.y,st.c)
		end

  map(0,0)
  pal(0,1)
  brint("qc cmp",8,4*8+17,6)
  spr(16,3+7,8-5+1)
  brint("🅾️⬆️",12+7,8-5+2+1,6)
  spr(17,3+7,16-5+1)
  brint("🅾️⬇️",12+7,16-5+2+1,6)
  spr(18,3+7,24-5+1)
  brint("🅾️➡️",12+7,24-5+2+1,6)
  spr(19,3+7,32-5+1)
  brint("🅾️⬅️",12+7,32-5+2+1,6)
  spr(24,3,40-5+1)
  brint("❎",11,40-5+2+1,6)
  spr(12,3+16+4,40-5+1)
  brint("⬇️",11+16+4,40-5+2+1,6)

  pal(0,0)
  spr(cmps.s,cmps.x,cmps.y-6*8+16)

  for i,v in pairs(gttb) do
    for j,u in pairs(v) do
       local ch=sub(u,1,1)
       local gt_s
       local gt_x = (4-i)*8
       local gt_y = (14-j-6)*8+16

       if ch=="x" then 
       	gt_s = 16
								spr(gt_s,gt_x,gt_y)
       elseif ch=="h" then 
       	gt_s = 17
								spr(gt_s,gt_x,gt_y)
       elseif ch=="v" then 
       	gt_s = 18
								spr(gt_s,gt_x,gt_y)
       elseif ch=="c" then 
       	gt_s = 19
								spr(gt_s,gt_x,gt_y)
       end

    end
   end

  for i,v in pairs(pss_dec) do print((7-(v-48)/8),8,8*i+80) end  
  
  
  for el in all(bltb) do
   for x in all(el.x) do
    sspr(el.s%16*8,el.s\16*8,8,8,
          x, el.y, 8, 115)
   end
  end
  
--animation test
--    local ssp=88
--    if (framecouts%4 < 2) ssp=80
--    sspr(ssp,8,8,8,64, 64,48,8)
		-- if	btn(❎) then
		--  ani_draw(true,64,64)
--   end
-- animation lasts for 30 frames for key-holding effects
--    if menu.fmlast <30 then 
    --  menu.fmlast+=1
			-- end

end
-->8
------------ surv_ ------------
function surv_init()
  surv={}
  surv.music = true
  cl = true
  dia = nil
  s = nil

  endy =  5.2-5
  bldy = -5.8-15
  fire_ani = 0
  next_y = 0
  hit = false

  fmk  = 280/10*30
  anihitct = -30
  animisct = -300

  cls()
  pps = 0
  ppp = 0
  pses = {}
  bles = {}

  bug = false
  bm_x = {}
  fmct = 0
  
  cmps = {s=6, x=3*8, y=14*8}
  gttbrst = false
  gttb = {{},{},{}}
  qc = quantumcircuit()
  qc.set_registers(3,3)
  pss = {}
--**********************--
  -- entb = {}  egen = true
  -- enmy = {nm=2, s={1,5,3,2}, x={1*8,5*8}, y= 2*8, dy=2.5 }

  -- bltb = {}
--**********************--
--**********************--
    blrng = -128

    endrop= 0.2 -- 0.4 pixel-pf
    enspcn= 30  -- 30 pixel betw enemy, min 15
    lsrspd= -36
    --fps=30
  
    entb,bltb = {},{}
    
  //  fire=false
  //  miss=false
    kill=false
    
    killcount = 0
    misscount = 0
--**********************--

  -- anitb = {} -- sprites that constitutes the animation
  -- for i=8,13 do add(anitb,i) end
  -- ani_init(anitb, 1, 21)

  stars = {}
 	for i=1,16 do
	 	add(stars,{x=rnd(72)+44,
		 											y=rnd(128),
			 										d=rnd(2)+1,
			 										c=rnd(2)+5})
	 end

end
-------------------------------
function surv_update()

  -- btn: composer and gates
  local qps = 3-cmps.x/8
  if btn(🅾️) then
    if btnp(⬆️) then -- press x append one x gate
      add(gttb[qps+1],"x") 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(⬇️) then -- press z append one h gate
      add(gttb[qps+1],"h") 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(➡️) then //s
      if qps == 0 then tgqb = 2
      else tgqb = qps-1
      end
      add(gttb[qps+1],"v"..qps..tgqb) 
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
    if btnp(⬅️) then //a
      if qps == 2 then tgqb = 0
      else tgqb = qps+1
      end
      add(gttb[qps+1],"c"..qps..tgqb)
      if (#gttb[qps+1] > 3) del(gttb[qps+1],gttb[qps+1][1])
    end
  end

    -- btn: fire
    --- provide pss, build bltb
    --- clear pss(or later?)

  if not btn(🅾️) then
    if (btnp(⬅️)) cmps.x = mid(1*8,cmps.x-1*8,3*8) sfx(13)
    if (btnp(➡️)) cmps.x = mid(1*8,cmps.x+1*8,3*8) sfx(13)    -- press ⬅️➡️ move player
    if (btnp(⬇️)) gttb[qps+1]={} sfx(14) -- press ⬅️➡️ clear gates on the current qubit
  end


  if (btnp(❎)) then -- press ❎ then fire/perform qcmeas
    for i,v in pairs(gttb) do
      for j,u in pairs(v) do
        local ch=sub(u,1,1)
        if ch=="x" then
          qc.x(i-1) 
        elseif ch=="h" then 
          qc.h(i-1)
        elseif ch=="v" then
          local ct = tonum(sub(u,3)) 
          qc.cx(i-1,ct) 
        elseif ch=="c" then 
          local ct = tonum(sub(u,3)) 
          qc.cx(i-1,ct)
        end
      end
    end

    -- initiate user attack
    pss = qcmeas(qc,3) -- store meas results
    -- handle laser
    pss_dec = bstrtb2dtb(pss)
    add(bltb,elgen('bullet',pss_dec))
    sfx(2)
    fire = true -- turn on fire flag

    qc = quantumcircuit() -- reset qc and gttb
    qc.set_registers(3,3) 
    gttb = {{},{},{}}
  end

  fmct+=1
    -- end
    -- laser limited by first enemy

    -- generate enemy
  if killcount>512 then
    endrop=0.7
  elseif killcount>256 then
    endrop=0.6
  elseif killcount>128 then
    endrop=0.5
  elseif killcount>64 then
    endrop=0.4
  elseif killcount>32 then
    endrop=0.3
  elseif killcount>16 then
    endrop=0.25
  else
    endrop=0.2
  end

  if fmct%flr(enspcn/endrop)==0 then
    n = rintx(2,1,1)
    add(entb,elgen(n..'enemy')) 
  end

  for el in all(entb) do
   if el.y!=nil then
    if (el.y< 107) el.y+=el.dy
    if (el.y>=107) then
      del(entb,el)
      sfx(14)
      misscount+=1
    end
   end
  end

  -- kill detection
  local ent2={}
  for i=1,#entb do ent2[i]=entb[i] end

  for b in all(bltb) do
    for i,v in pairs(entb) do
    if tbcmpr(v.x,b.x) then
      del(ent2,entb[i])
      sfx(3)
      killcount+=1
    end
    end
  end

  entb={}
  for i=1,#ent2 do entb[i]=ent2[i] end

    -- laser limited by first enemy
    -- if (#entb!=0) blrng=entb[1].y
  for el in all(bltb) do
    if el.y!=nil then
      if (el.y> blrng) el.y+=el.dy
      if (el.y<=blrng) del(bltb,el)
    end
  end
--**********************--

	 for st in all(stars) do
	 	st.y+=st.d
	 	if (st.y>125) st.y=3 st.x=rnd(72)+44
	 end
	 
end
-------------------------------
function surv_draw()

	 for st in all(stars) do
		 pset(st.x,st.y,st.c)
		end
      
  map(0,0)
  brint("qc cmp",8,4*8+17,6)
  spr(16,3+7,8-5+1)
  brint("🅾️⬆️",12+7,8-5+2+1,6)
  spr(17,3+7,16-5+1)
  brint("🅾️⬇️",12+7,16-5+2+1,6)
  spr(18,3+7,24-5+1)
  brint("🅾️➡️",12+7,24-5+2+1,6)
  spr(19,3+7,32-5+1)
  brint("🅾️⬅️",12+7,32-5+2+1,6)
  spr(24,3,40-5+1)
  brint("❎",11,40-5+2+1,6)
  spr(12,3+16+4,40-5+1)
  brint("⬇️",11+16+4,40-5+2+1,6)
  
  spr(cmps.s,cmps.x,cmps.y-6*8+16)
  brint("killed:",6,88+4,6)
  brint(" "..killcount,6,96+4,7)
  brint("missed:",6,104+4,6)
  brint(" "..misscount,6,112+4,7)


  for i,v in pairs(gttb) do
    for j,u in pairs(v) do
       local ch=sub(u,1,1)
       local gt_s
       if ch=="x" then gt_s = 16
       elseif ch=="h" then gt_s = 17
       elseif ch=="v" then gt_s = 18
       elseif ch=="c" then gt_s = 19
       end
       local gt_x = (4-i)*8
       local gt_y = (14-j-6)*8+16
       spr(gt_s,gt_x,gt_y)
    end
   end
  

  local excite,exctfl = 0,true
  -- -- local exctct =0
  -- -- if fire
  -- if not kill then
    excite = 8
    if (fmct%4<2) exctfl=not exctfl
  -- end
    for el in all(entb) do
  --	 for i,x in pairs(el.x) do
  -- 	 spr(el.s[i],x,el.y)
  -- 	end
      if #el.x==2 then
        spr(1,el.x[1],el.y)
        spr(1,el.x[2],el.y,1,1,true)
        sspr(24+excite,0,8,8,
            el.x[1]+8,el.y,
            el.x[2]-el.x[1]-8,8,
            exctfl)
      else
        spr(2,el.x[1],el.y)
      end

    end

    for el in all(bltb) do
    for x in all(el.x) do
    sspr(el.s%16*8,el.s\16*8,8,8,
          x, el.y, 8, 127)
    end
    end


end
-->8
------------ _init ------------
function _init()

  music(0,10000)

  framecouts = 0
  mode={}
 
  mode.menu=true
  mode.stor=false
  mode.sand=false
  mode.surv=false
  
  menu_init() 
  stor_init()

  for i =1,#stor.op do 
    dtb_disp(stor.op[i], 
      function() 
        -- stor_color = stor.color[i%2+1]
        -- stor_sp = stor.sp[i%2+1]
        -- stor_spx = stor.spx[i%2+1]
        stor_color = stor.color[1]
        stor_sp = stor.sp[2]
        stor_spx = stor.spx[2]

        if (i==#stor.op) mode.stor = false mode.surv = true
      end) 
  end

  sand_init()
  surv_init()

--poke(0x5f2d,1) 
end

--------------------------------
function _update()

  framecouts += 1
  
  if mode.menu then
    menu_update()
  elseif mode.stor then
    dtb_update()
  elseif mode.sand then
    sand_update()
  elseif mode.surv then
    if (surv.music) music(2,20000) surv.music=false
    surv_update()
  end

end

--------------------------------
function _draw()

  cls()

  if mode.menu then
    menu_draw()
  elseif mode.stor then      
    map(0,0)

    sspr(24%16*8,24\16*8,8,8,
    (7-0)*8+48, 64, 8, 40)
    sspr(24%16*8,24\16*8,8,8,
    (7-6)*8+48, 64, 8, 40)

    brint("qc cmp",8,4*8+17,6)
    spr(16,3+7,8-5+1)
    brint("🅾️⬆️",12+7,8-5+2+1,6)
    spr(17,3+7,16-5+1)
    brint("🅾️⬇️",12+7,16-5+2+1,6)
    spr(18,3+7,24-5+1)
    brint("🅾️➡️",12+7,24-5+2+1,6)
    spr(19,3+7,32-5+1)
    brint("🅾️⬅️",12+7,32-5+2+1,6)
    spr(24,3,40-5+1)
    brint("❎",11,40-5+2+1,6)
    spr(12,3+16+4,40-5+1)
    brint("⬇️",11+16+4,40-5+2+1,6)
    spr(18,8,64)
    spr(17,8,72)
    spr(cmps.s,cmps.x,cmps.y-6*8+16)  

    dtb_draw(stor_color,stor_sp,stor_spx)

  elseif mode.sand then
    sand_draw()
  elseif mode.surv then
    surv_draw()
  end
-- handle dialogue lines 
-- brint(tutbuttn[1],48,84,7)
-- draw gate w/ gttb

--spr(0,stat(32)-1,stat(33)-1)
end

--------------------------------

--todo

----note: data structure
-- gttb: {{x,h},{c02,v12},{}}
-- /bt: "111"
-- pse/pss: {"111","010"}
-- enle/blle: {s=  7,dy=bldy,
--            px=pss, y=16*8}
-- entb/bltb: {enle,enle,enle}

---- use gttb to practice oop

-----in _update verify shot loc
-----in every frame. basically
-----#bltb[1][1] is always 1,
-----which means blle={} every
-----frame at the end. 

---- make tutorial

---- make storyline box


------------------------------- 🅾️❎⬇️⬆️⬅️➡️


------------------------------- 🅾️❎⬇️⬆️⬅️➡️

__gfx__
1111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a980000000000
1f7100000033330000333300000000000000000000333300008882000000000000000000000000000a09a090090a90a00909a0a00900a0a00089a80000000000
17111000033bb333033bb3300000000000000000333bb33000888800000770000009090000909000009a79000097a9000090090000000000008a980000000000
1117100033bbbbbb33bbbb3333333333bbbbbbbbbbbbbb330011110000676700009a70000007a90009a7a7a00a7a7a90090000a0000000a00089a80000000000
001110003bbb9bbb3bba9bb333333333bbbbbbbbbbb9bbb300f11f00007676000007a900009a70000a7a7a9009a7a7a00a0000900a000000008a980000000000
000000005bb9abbb5bb9abb555555555a9a9a9a9bbba9bb50b311bb00006600000909000000909000097a900009a790000900900000000000089a80000000000
0000000055ba9b5555ba9b55000000000000000055b9ab550fddddf0000000000000000000000000090a90a00a09a0900a0a90900a0a0090008a980000000000
0000000005b00b5005b00b50000000000000000005b00b5000200400000000000000000000000000000000000000000000000000000000000089a80000000000
666666666666666666666666666666660000000000000000f0000000000000000028820000288200888888888888888866660066066666006006666666600666
600000066000000660000006600000060000000000000000f7f0000000077000028a98200289a8209a9a9a9aa9a9a9a960000006000000066000000060000006
6080080660c0000660bb80866808bb0600000000000000000f7f700000777600028fa820028af820a9a9a9a99a9a9a9a00000006600000066000000060000006
6000800660ccc0066bb0080660800bb6bbbbbbbb0000000077f00000066767600289f820028f98209a9a9a9aa9a9a9a900000006600000066000000600000000
6008000660c00c066bb0080660800bb6bbbbbbbb00000000f000000006767660028fa820028af820a9a9a9a99a9a9a9a60000000600000066000000600000000
6080080660c00c0660bb80866808bb069a9a9a9a000000000000000000666700028af820028fa820888888888888888860000000600000060000000660000006
6000000660000006600000066000000600000000000000000000000000066000028f98200289f820000000000000000060000006600000000000000660000006
66666666666666666666666666666666000000000000000000000000000000000289f820028f9820000000000000000066006666006666606666600666600666
60000000000000000000000666666666600000066666666666666666600000000000000666666666000000000000000000000006600000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000000000000000000600000000600000060000000060000000600000000000000600000006000000000000000000000000000000000000000000000000
60000000666666660000000600000000600000066666666660000000666666666666666600000006600000000000000600000000000000000000000000000000
66000000000000000000006666666666660000666666666666666666660000000000006666666666000000000000000000000000660000000000000000000000
66000000000000000000006666666666660000666666666666666666660000000000006666666666000000000000000000000000660000000000000000000000
66000000000000000000006600000000660000660000000066000000660000000000006600000066000000000000000000000000000000000000000000000000
66000000000000000000006600000000660000660000000066000000660000000000006600000066000000000000000000000000000000000000000000000000
66000000000000000000006600000000660000660000000066000000660000000000006600000066000000000000000000000000000000000000000000000000
66000000000000000000006600000000660000660000000066000000660000000000006600000066000000000000000000000000000000000000000000000000
66000000666666660000006600000000660000666666666666000000666666666666666600000066660000000000006600000066000000000000000000000000
66000000666666660000006600000000660000666666666666000000666666666666666600000066660000000000006600000066000000000000000000000000
6666666666666666666666666666666666666666666666666666666666666666999999999999999999999999dddddddddddddddddddddddd0000000000000000
66666666666666666666666666666666666666666666666666666666666666669ffffffffffffffffffffff9d6666666666666666666666d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffffffffffffffffffffff9d6666666666666666666666d0000000000000000
02020200020200000200020002000000000202000002000000000200000000009ffffffffffffffffffffff9d6666666664444446666666d0000000000000000
02020200020200000200020002000000000202000002000000000200000000009ffffffffaaaaaaffffffff9dee666644444eeee4446666d0000000000000000
02020200020205000205020002050500050202000502050005050200050505009ffffffaaaaaaaaa9ffffff9d8eee6444eeeeeeeeee4666d0000000000000000
02020200020205000205020002050500050202000502050005050200050505009fffffaa9999999999fffff9d688e44eeeeeeeeeeeeee66d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffffaa999999999999ffff9d682eeeeeeee44444444446d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffffa999a999999999ffff9d882eeee4444f44f4444446d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009fff9999a99999999992fff9d226444444ffff4ffff4446d0000000000000000
02020200020200000200020002000000000202000002000000000200000000009fff999a999999999942fff9d66644444fffffffffff446d0000000000000000
02020200020200000200020002000000000202000002000000000200000000009fff9999999999999942fff9d664444ffff17ff17fff446d0000000000000000
02020200020205000205020002050500050202000502050005050200050505009fff9999999999999942fff9d66444fffff11ff11fff446d0000000000000000
02020200020205000205020002050500050202000502050005050200050505009fff9999999999999942fff9d6644fffffffffffffff466d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009fff9999999999999942fff9d6644ffffeffffffffef566d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffff99999999999942ffff9d66444fffffff88ffff5666d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffff99999999999442ffff9d66444fffffffffffff5666d0000000000000000
0e0e0e000e0e00000e000e000e000000000e0e00000e000000000e00000000009fffff999999944442fffff9d66446622ffffffff226666d0000000000000000
0e0e0e000e0e00000e000e000e000000000e0e00000e000000000e00000000009ffffff9444444222ffffff9d6664665922ffff22266666d0000000000000000
0e0e0e000e0e07000e070e000e070700070e0e00070e070007070e00070707009ffffffff222222ffffffff9d6664665992222229956666d0000000000000000
0e0e0e000e0e07000e070e000e070700070e0e00070e070007070e00070707009ffffffffffffffffffffff9d6666659999992999995666d0000000000000000
00000000000000000000000000000000000000000000000000000000000000009ffffffffffffffffffffff9d6666659999992999995666d0000000000000000
66666666666666666666666666666666666666666666666666666666666666669ffffffffffffffffffffff9d6666659999992999995666d0000000000000000
6666666666666666666666666666666666666666666666666666666666666666999999999999999999999999dddddddddddddddddddddddd0000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888400088884008840000008888400888008840000000000000000000000000028880000000000000000000044440000000000000000000000000000000000
88408840008840008840000000884000888808840000000000000000000000000088888000000000000000000eeeee0000000000000000000000000000000000
884088400088400088400000008840008888888400000000000000000000000000f1f1000000000000000000d0f5f50000000000000000000000000000000000
884888400088400088400000008840008848888400000000000000000000000000ffff00000000000000000000ffff0000000000000000000000000000000000
88888400008840008840000000884000884088840000000000000000000000000bbbbb3000000000000000000299292000000000000000000000000000000000
08848840088884008888884008888400884008840000000000000000000000000fddddf000000000000000000f9999f000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000040020000000000000000000020040000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000555500000000000000000000000000005555000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000005533555000000000000000000000000555335500000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000055333333333333333333333333333333333333550000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000053332333333333333333333333333333333233350000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000013324333424242424242424242424242333423310000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011342311000000000000000000000000113243110000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000001300310000000000000000000000000013003100000000000000000005555000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055335500000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000553333550000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000533423350000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133243310000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000113423110000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013003100000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000002222222222222222222222220000022224000222240022400000022224002220022400002222222222222222222222220000000000000000
00000000000000002424242424242424242424240000224022400022400022400000002240002222022400002424242424242424242424240000000000000000
00000000000000004242424242424242424242420000224022400022400022400000002240002222222400004242424242424242424242420000000000000000
00000000000000002424242424242424242424240000224222400022400022400000002240002242222400002424242424242424242424240000000000000000
00000000000000004242424242424242424242420000222224000022400022400000002240002240222400004242424242424242424242420000000000000000
00000000000000002222222222222222222222220000022422400222240022222240022224002240022400002222222222222222222222220000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444422422244224222424244444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444244442442424242424244444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444222442442424224422244444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444442442442424242444244444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444224442442244242422244444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
000000000000000044444444f444444444444ff4fff4ff44ff44fff44ff4f4f44444444444444444444444444444444444444444444444440000000000000000
000000000000000044444444f7f444444444f444f4f4f4f4f4f4f4f4f4f4f4f44444444444444444444444444444444444444444444444440000000000000000
0000000000000000444444444f7f74444444fff4fff4f4f4f4f4ff44f4f44f444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444477f44444444444f4f4f4f4f4f4f4f4f4f4f4f4f44444444444444444444444444444444444444444444444440000000000000000
000000000000000044444444f44444444444ff44f4f4f4f4fff4fff4ff44f4f44444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444422424242224242422242424222422242444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444244424242424242442442424424424242444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444222424242244242442442424424422242444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444442424242424222442442224424424242444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444224442242424424422244244222424242224444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444111144444444444444444440000000000000000
000000000000000044444444444444444444444444444444444444444444444444444444444444444444444441f7144444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444171114444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444111714444444444444444440000000000000000
00000000000000004444242442242444224444442224444442242224444442222244444422244224444422242221112422242244444444440000000000000000
00000000000000004444242424242444242444444424444424242424444422444224444442442424444424242444244442442424444444440000000000000000
00000000000000004444222424242444242444444244444424242244444422424224444442442424444422442244244442442424444444440000000000000000
00000000000000004444242424242444242444442444444424242424444422444224444442442424444424242444242442442424444444440000000000000000
00000000000000004444242422442224222444442224444422442424444442222244444442442244444422242224222422242424444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000004444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444440000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000100000010000000000000000000000000000000000555500000000000000000000555500000000000000000000000000
00000000000000000000000000000000120233010000000000000000000000000000000005533555000000000000000055533550000000000000000000000000
00000000000000000000000000000000102003310000000000000000000000000000000055333333333333333333333333333355000000000000000000000000
00000000000000000000000000000000102003310000000000000000000000000000000053332333333333333333333333323335000000000000000000000000
00000000000000000000000000000000120233010000000000000000000000000000000013324333424242424242424233342331000000000000000000000000
00000000000000000000000000000000100000010000000000000000000000000000000011342311000000000000000011324311000000000000000000000000
00000000000000000000000000000000111111110000000000000000000000000000000001300310000000000000000001300310000000000000000000000000
00000000000000001111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001000000110000001100000010000000000000000000000000000000004024020040240200000000000000000000000000000000000000000
0000000000000000102002011202330110300001000000000000000000000000000000000024d2000024d2000000000000000000000000000000000000000000
000000000000000010002001102003311033300100000000000000000000000000000000024d4d40024d4d400000000000000000000000000000000000000000
00000000000000001002000110200331103003010000000000000000000000000000000004d4d42004d4d4200000000000000000000000000000000000000000
000000000000000010200201120233011030030100000000000000000000000000000000002d4200002d42000000000000000000000000000000000000000000
00000000000000001000000110000001100000010000000000000000000000000000000002042040020420400000000000000000000000000000000000000000
00000000000000001111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000002222000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000002222000000000002020200020200000200020002000000000202000002000000000200000000000000000000000000
00000000000000000000000000000000001111000000000002020200020200000200020002000000000202000002000000000200000000000000000000000000
0000000000000000000000000000000000f11f000000000002020200020201000201020002010100010202000102010001010200010101000000000000000000
00000000000000000000000000000000035113300000000002020200020201000201020002010100010202000102010001010200010101000000000000000000
000000000000000000000000000000000fddddf00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000002004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__gff__
0002020101020002000000000000000000000000010000020000000000000000010101010101010101010101010100000101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3633333333363333333333333333390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300f000000305051525354555657320000000000000000000000151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300f000000300000000000000000320000000000000000001500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300f000000305051525354555657320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300f000000300000000000000000320000001c000000000000000000151c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000305051525354555657320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3021212100300000000000000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3024002400305051525354555657320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3024002400300000000000000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3024002400305051525354555657320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3023232300300000000000000000320000001500000000000000000015150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000305051525354555657320000001c000000000000000000001c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000300000000000000000320000000000150000151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000305051525354555657320000151515150000001515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000300000000000000000320000000015151515151515151515150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3731313131376061626364656667380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010c00201872018720180201802018520185201802018020185201852018520185201802018020180201802018720187201802018020185201852018020180201872018720185201852018020180201872018720
00180000144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410
000400001826018250184401843018220184100470004700037000370002700017000070000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400002d6201f6301865015650116500e6400b620096200761005610046100261000610006100460001600006000b6000960007600066000560005600056000460004600036000360002600016000060000600
000c00200f1100f1100f1100f1100f1100f1100f1100f1100c1100c1100c1100c1100c1100c1100c1100c11013110131101311013110131101311013110131101111011110111101111011110111101111011110
010c00200c7200c7200c7200c72013720137201372013720117201172011720117200c7200c7200c7200c7200c7200c7200c7200c72013720137201372013720117201172011720117200c7200c7200c7200c720
010c0000160101601016010160101601016010160101601011010110101101011010110101101011010110100c0100c0100c0100c0100c0100c0100c0100c0101301013010130101301013010130101301013010
011000202d7201502021720150202d720150202172015020247200c720180200c020247200c720180200c020287201c0201072028020287201c720107201c7202d0201502021020150202d720157202172015720
011000001702017020170201702017020170201702017020100201002010020100201002010020100201002012020120201202012020120201202012020120201702017020170201702017020170201702017020
011000001c7401c7401c0401c7401c7401c0401c7401c740130401374013740130401374013740130401374017740177401704017740177401704017740177401c7401c0401c7401c7401c7401c0401c7401c740
01100000150201c7301a5401c010157201c5301a0401c710155201c5301a0401c510150201c7301a5401c010157201c5301a0401c720155101c7301a5401c020150101c5301a0401c720155101c0301a7401c520
011000000f25400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000006000060000600006002c00027000220001f0001c00018000160001400012000100000f0000d0000c000090000800000600006000060000600006000060000600006000060000000000000000000000
010c00002b7342e000290000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01020000000000000000000122501425017250192501c2501f25021250212501e2501825013250372000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000003160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
03 00040541
03 41404446
03 0708490a

