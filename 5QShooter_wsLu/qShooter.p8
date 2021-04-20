pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
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
-- func_useful
-------------------------------
function wait(t) 
 for i = 1,t do flip() end end
-------------------------------
function fltn(tb,rank)
-- return flattened table from
--rank 2 to rank 4
 local tb_fl = {}

 if rank==2 then
  for i,v in pairs(tb) do
   for j,u in pairs(v) do
    add(tb_fl,u) end end    

 elseif rank==3 then
  for i,v in pairs(tb) do
   for j,u in pairs(v) do
    for k,t in pairs(u) do
    add(tb_fl,t) end end end    
 
 elseif rank==4 then
  for i,v in pairs(tb) do
   for j,u in pairs(v) do
    for k,t in pairs(u) do
     for k,s in pairs(t) do
     add(tb_fl,s) end end end end    

 end
 return(tb_fl)
end
-------------------------------
function tb2str (src, s2t)
-- convert tb_of_str to str
-- reverse action by s2t="s2t"
 local tar = -1
 if s2t=="s2t" then
  tar = {}
  for i = 1,#src do
   tar[i] = sub(src,i,i) end

 else
  tar = ""
  for i,v in pairs(src) do
   tar = tar..v end

 end
 return tar
end
-------------------------------
function as_bits (num,bits,idn)
-- convert decimal to bintable
-- set idn="s" to binstring
 local bitstring = {}
 for index = bits, 1, -1 do
     b = num - flr(num/2)*2
     num = flr((num - b) / 2)
     bitstring[index] = b
 end

 if idn=="s" then
  bitstring = tb2str(bitstring)
 end
 return bitstring
end
-------------------------------
function bin2dec(src)
-- convert bin table or binstr
--to a decimal number
 local n,str = 0, ""

 if type(src)=="table" then
  str = tb2str(src)
 else str = src end

 for i = 1,#str do 
  n +=tonum(sub(str,i,i))*2^(#str-i)
 end 

 return(n)
end
-------------------------------
function bint2dect(b,sort)
 local d = {}

 for i,v in pairs(b) do
  local n = {}
  for j,u in pairs(v) do
   n[j] = bin2dec(u)
  end

  if #n==1 then
   d[i] = tostr(n[1])
  elseif #n==2 and sort then
   d[i] = min(n[1],n[2])..max(n[1],n[2])
  elseif #n==0 then
  else
   d[i] = n[1]..n[2]
  end
 
 end
 return(d)
end
-------------------------------
function dect2bint(d)
 local b = {}
 for i,v in pairs(d) do
  local a1 = {}
  for j=1,#v do
   a0 = as_bits(sub(v,j,j),3,"_")
   a1[j] = a0
  end
  b[i] = a1
 end
 return b
end
-------------------------------
function prtct(m)
-- handle string from qc.meas
--translate to {state,counts}
//n = prtct(m)
//for i=1,#n[1] do
// print(n[1][i]) print(n[2][i]) end
 st={} ct={} j = 1
 for i,v in pairs(m) do
  st[j]=i ct[j]=v
  j=j+1   end
 return {st,ct}
end
-- cut only significant state
--with counts > llm
function qcmeas(qc,llm)
 for i = 0,2,1 do
  qc.measure(i,i) end
 local n = prtct(simulate(qc,"counts",16))
 local nst,nct = n[1],n[2]
 local possiblestt = {}
 for i,v in pairs(nct) do
  if tonum(v)>llm then
   possiblestt[i]=nst[i] end
 end
 return(possiblestt)
end
-------------------------------
-->8
---- func_cust ----
function prinb(tb)
-- tb is table_l2 {{}}
 for i,v in pairs(tb) do
  for j,u in pairs(v) do
   print(i..":"..j..":"..u,
         i*24+0,
         j*8+16)
  end end end
-------------------------------
function _bint2dect(b,sort)
 local d = {}

  local n = {}
  for j,u in pairs(v) do
   n[j] = bin2dec(u)
  end

  if #n==1 then
   d[i] = tostr(n[1])
  elseif #n==2 and sort then
   d[i] = min(n[1],n[2])..max(n[1],n[2])
  elseif #n==0 then
  else
   d[i] = n[1]..n[2]
 
 end
 return(d)
end
-------------------------------
function collide_map(obj,flag)
 -- obj = table needs xy
// local x,x1,x2 = obj.x,0,0
// x1=x+1 x1/=8 x2=x+8-1 x2/=8

 local y,y1,y2 = obj.y,0,0
 y1=y-1 y1/=8 y2=y     y2/=8
 
 if fget(mget(x1,y1),flag) 
 or fget(mget(x1,y2),flag) 
 or fget(mget(x2,y1),flag)
 or fget(mget(x2,y2),flag) then 
   return true
 else
   return false
 end
end
-------------------------------
function b2num(boo)
 if boo then
  return 1
 else
  return 0
 end
end
-------------------------------
--  if bug then
--   print("bugd",80,16+i*8,2)
--   wait(1)
--   for a,v in pairs(blls) do
--    for b,u in pairs(v) do
--     print((u),10*8,b*8+32) end 
--    print("_",80,80) end 
--  end

-->8
---- func_init ----
function _init()

   // dialogue selection

      tutlines = {
      "welcome me hero.\ni'm sorry that\nwe have no time\nto greet you, bu\nt let's celebrat\n",
      "together after\ndefending earth\nseccessfully.\n", 
      "welcome my hero", 
      "welcomme my hero", 
      "what say ya?"}
      
      tutbuttn = {
      "press d to conti", }
      
      tutrespo = {
      "i know what to do", 
      "   show me how",
      "tutorial mode"}
      
      linn = 1
      tuto = true
      main = false
      dsel=true
   
   // main 
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
      
      gtlsrst = false
      gtls = {{},{},{}}
      qc = quantumcircuit()
      qc.set_registers(3,3)
      pss = {}
      
   --  circuit composer / user control
      cmps = {s=6, x=13*8, y=14*8}
      
      enls = {}  egen = true
      enmy = {nm=2, s={1,5,3,2}, x={1*8,5*8}, y= 2*8, dy=2.5 }
         
      blls = {}

end
-->8
---- func__update ----
function _update()

    if tuto then
        if linn < #tutlines and btnp(3,1) then
            cls()
            linn+=1
        elseif linn == #tutlines then
            if btnp(⬅️) or btnp(➡️) then
                dsel = not dsel
			elseif btnp(3,1) then
                if not dsel then
                    tuto = false
                    main = true
                    cls()
                else
                    cls()
                    //butn = 1
                end
            end
        end
    end

	
	if main then
		-- btn: composer and gates
	    if btnp(⬅️) then
	        cmps.x = mid(11*8,cmps.x-1*8,13*8) end

        if btnp(➡️) then
	        cmps.x = mid(11*8,cmps.x+1*8,13*8) end 

        local qps = 13-cmps.x/8
        if btnp(3,1) then //d
	        gtls[qps+1]={} end

        if btnp(5,0) then //x
	        add(gtls[qps+1],"x") 
            if #gtls[qps+1] > 3 then
                del(gtls[qps+1],gtls[qps+1][1])
            end
        end

        if btnp(4,0) then //h
            add(gtls[qps+1],"h") 
            if #gtls[qps+1] > 3 then
                del(gtls[qps+1],gtls[qps+1][1])
            end
        end

								if btn(⬆️) then
        	if btnp(0,1) then //s
            if qps == 0 then tgqb = 2
            else tgqb = qps-1
            end

            add(gtls[qps+1],"v"..qps..tgqb) 
            if #gtls[qps+1] > 3 then
                del(gtls[qps+1],gtls[qps+1][1])
            end
         end
        end
		 
        if btnp(5,1) then //a
            if qps == 2 then tgqb = 0
            else tgqb = qps+1
            end

            add(gtls[qps+1],"c"..qps..tgqb)
            if #gtls[qps+1] > 3 then
                del(gtls[qps+1],gtls[qps+1][1])
            end
        end  
		
		--- enemy generation
		--- provide pse, build enls
		--- clear pse
        if egen then
            pse = {}
            bt = as_bits(flr(rnd(8)),3,"s")
            add(pse,bt)
            bt2= as_bits(flr(rnd(8)),3,"s")
            if bt2 != bt then
                add(pse,bt2) end     

            enle = {s=2,dy=endy,px=pse, y=1*8}
            add(enls,enle)
            egen = false
        end
		 
		-- btn: fire
		--- provide pss, build blls
		--- clear pss(or later?)
        if btnp(1,1) then //f
            for i,v in pairs(gtls) do
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

            pss = qcmeas(qc,3)

            fire = true
            qc = quantumcircuit()
            qc.set_registers(3,3) 
            gtls = {{},{},{}}
        end
		
		
		--- if enls[i].px == pss,
		---del enls[i]
		--- if enls[i].y  >  120,
		---del enls[i]
		--- if blls[i].y  <    8,
		---del blls[i]
		
        if fire then
            blle = {s=  7,dy=bldy,px=pss, y=16*8}
            blls = {blle}
            fire = false
            hit = true
        end 
		
        pss = {}
        for i,v in pairs(blls) do
            pss = v.px//bint2dect({v.px},true)
            if v.y > -8 then
                v.y += v.dy 
            else del(blls,v)
            end
        end
		
        pse = {}
        for i,v in pairs(enls) do
            pse = v.px//bint2dect({v.px},true)
            if v.y != nil then
                if v.y < 128-16 then
                    v.y += v.dy
                else
                    del(enls,v)
                    next_y=0 // update laser y
                end
            end
            if pse == pss then
                bug = true
                hit = true
                del(enls,v)
                next_y=0 // update laser y
            end
        end

		
		
		-- collision handling
		//  for i,v in pairs(enls) do
		//   local pses = v.px
		//   local em = bint2dect(pses,sort)
		//   local lm = bint2dect({pss},sort)
		//   local removed,a = {},0
		//   for i,v in pairs(lm) do
		//    a = (del(em,v))
		//    add(removed, a)
		//   end
		//   pses = dect2bint(em)
		// colmap = false
		//  col = collide_map(v,0)
		//  colmap = colmap or col
	
	end

end
-->8
---- func_draw ----
function _draw()
   cls()
   map(0,0)

   print("qc cmp",11*8,10*8,6)
   spr(cmps.s,cmps.x,cmps.y)

-- handle dialogue lines
   if tuto then
      for x = 0,64,8 do
         for y = 0,40,8 do
            spr(21,4+x,44+y)
         end
      end
      spr(38,4,44)
      spr(39,4,84)
      spr(40,68,84)
      spr(41,68,44)

      print(tutlines[linn],8,48,7) 
      if linn == #tutlines then
         print(tutrespo[b2num(dsel)+1],6,78,9) 
      end
      print(tutbuttn[1],8,84,6)
   end

-- draw gate w/ gtls
   for i,v in pairs(gtls) do
      for j,u in pairs(v) do
         local ch=sub(u,1,1)
         local gt_s
         if ch=="x" then gt_s = 16
         elseif ch=="h" then gt_s = 17
         elseif ch=="v" then gt_s = 18
         elseif ch=="c" then gt_s = 19
         end
         local gt_x = (14-i)*8
         local gt_y = (14-j)*8
         spr(gt_s,gt_x,gt_y)
      end
   end

-- draw enemy w/ enls
   local vx,vy = {},{}
   for i,v in pairs(enls) do
      for i = 1,8 do
         spr(3,(i*8+0),v.y)
         next_y = max(next_y,v.y) end

      local sp
      if not hit then
         if fmct%4 < 4\2 then sp=20
         else  sp=4 end
         for i = 1,8 do
            animisct += 1
            spr(sp,(i*8+0),next_y)
         end
      end

      if animisct >0 then
         miss = false
         animisct = -300
      end

      for j,u in pairs(v.px) do
         v_x = (8-bin2dec(u))*8
         spr(v.s,v_x,v.y)
         add(vx,v_x)
      end
   end

--   local vx1 = max(vx[1],vx[2])
--   local vx2 = min(vx[1],vx[2])
--   dis = (vx1-vx2)/8-1
--   for i = 1,dis do
--    spr(3,(i*8+vx2),y) end

-- draw bullets w/ blls
---currently use laser
   bm_x = {}
   for i,v in pairs(blls) do
      for j,u in pairs(v.px) do
         local v_x = (8-bin2dec(u))*8
--           spr(v.s,v_x,v.y)
         add(bm_x,v_x)
      end
   end

   local sp
   if fmct%4 < 4\2 
      then sp=24
   else  sp=25 
   end
   local d = next_y+6
   for i,v in pairs(bm_x) do
      sspr((sp%16)*8,(sp\16)*8,8,8,v,d,8,120-d)
   end


-- set enemy gen at given frame
   fmct += 1
   if fmct==fmk then 
      fmct=0
      egen=true
   end  

-- firework animation
//  fire_ani
   for i = 1,18,3 do
      if fmct%18==i+1 or fmct%18==i+2 or fmct%18==i+3 or fmct%18==i+4 then
         if hit then
            anihitct += 1
            spr(8+flr(i/3),vx[1],d-5)
            spr(8+flr(i/3),vx[2],d-5)
         end
         if anihitct >0 then
            hit = false
            anihitct = -30
         end
      end
   end


end

-->8
--todo

----note: data structure
-- gtls: {{x,h},{c02,v12},{}}
-- /bt: "111"
-- pse/pss: {"111","010"}
-- enle/blle: {s=  7,dy=bldy,
--            px=pss, y=16*8}
-- enls/blls: {enle,enle,enle}

---- use gtls to practice oop

---- make laser version
-----in _update verify shot loc
-----in every frame. basically
-----#blls[1][1] is always 1,
-----which means blle={} every
-----frame at the end. 

---- sprite list remake
-----we need complete lists of
-----enls and blls
-----contains {{{'000','111},
-----           {'100','101} }}

---- collision check
-----1st chk enls vs wall (f1)
-----use or betw flags
-----2nd chk blls vs wall (f1)
-----use or betw flags
-----3rd chk enls vs blls (f2)
-----use and betw flags

---- make tutorial

---- make front page

---- make storyline box

---- make sound
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000033330000333300000000000000000000333300000000000000000000000000000000000a09a0900909a0a00909a0a00900a0a00000000000000000
00000000033bb333033bb3300000000000000000333bb33000000000000770000019190000919100009a7900009a790000911900001111000000000000000000
0000000033bbbbbb33bbbb3333333333bbbbbbbbbbbbbb330076760000676700009a71000017a90009a7a7a009a7a7a0091111a0001111a00000000000000000
000000003bbb9bbb3bba9bb333333333bbbbbbbbbbb9bbb307676670007676000017a900009a71000a7a7a900a7a7a900a1111900a1111000000000000000000
000000005bb9abbb5bb9abb555555555a9a9a9a9bbba9bb5066007600006600000919100001919000097a9000097a90000911900001111000000000000000000
0000000055ba9b5555ba9b55000000000000000055b9ab5500000000000000000000000000000000090a90a00a0a90900a0a90900a0a00900000000000000000
0000000005b00b5005b00b50000000000000000005b00b5000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666666666666666000000005555555500000000000000000089a800008a9800000000000000000000000000000000000000000000000000
6000000660000006600000066000000600000000555555550000000000077000008a98000089a800000000000000000000000000000000000000000000000000
6080080660c0000660bb80866808bb06000000005555555500000000007776000089a800008a9800000000000000000000000000000000000000000000000000
6000800660ccc0066bb0080660800bb6bbbbbbbb555555550000000006676760008a98000089a800000000000000000000000000000000000000000000000000
6008000660c00c066bb0080660800bb6bbbbbbbb5555555500000000067676600089a800008a9800000000000000000000000000000000000000000000000000
6080080660c00c0660bb80866808bb069a9a9a9a555555550000000000666700008a98000089a800000000000000000000000000000000000000000000000000
60000006600000066000000660000006000000005555555500000000000660000089a800008a9800000000000000000000000000000000000000000000000000
6666666666666666666666666666666600000000555555550000000000000000008a98000089a800000000000000000000000000000000000000000000000000
70000000000000000000000777777777700000077777777777777777700000000000000777777777000000000000000000000007700000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000000000000000000700000000700000070000000070000000700000000000000700000007000000000000000000000000000000000000000000000000
70000000777777770000000700000000700000077777777770000000777777777777777700000007700000000000000700000000000000000000000000000000
77000000000000000000007777777777770000777777777777777777770000000000007777777777000000000000000000000000770000000000000000000000
77000000000000000000007777777777770000777777777777777777770000000000007777777777000000000000000000000000770000000000000000000000
77000000000000000000007700000000770000770000000077000000770000000000007700000077000000000000000000000000000000000000000000000000
77000000000000000000007700000000770000770000000077000000770000000000007700000077000000000000000000000000000000000000000000000000
77000000000000000000007700000000770000770000000077000000770000000000007700000077000000000000000000000000000000000000000000000000
77000000000000000000007700000000770000770000000077000000770000000000007700000077000000000000000000000000000000000000000000000000
77000000777777770000007700000000770000777777777777000000777777777777777700000077770000000000007700000077000000000000000000000000
77000000777777770000007700000000770000777777777777000000777777777777777700000077770000000000007700000077000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020200020200000200020002000000000202000002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
02020200020200000200020002000000000202000002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
02020200020205000205020002050500050202000502050005050200050505000000000000000000000000000000000000000000000000000000000000000000
02020200020205000205020002050500050202000502050005050200050505000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02020200020200000200020002000000000202000002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
02020200020200000200020002000000000202000002000000000200000000000000000000000000000000000000000000000000000000000000000000000000
02020200020205000205020002050500050202000502050005050200050505000000000000000000000000000000000000000000000000000000000000000000
02020200020205000205020002050500050202000502050005050200050505000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e000e0e00000e000e000e000000000e0e00000e000000000e00000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e000e0e00000e000e000e000000000e0e00000e000000000e00000000000000000000000000000000000000000000000000000000000000000000000000
0e0e0e000e0e07000e070e000e070700070e0e00070e070007070e00070707000000000000000000000000000000000000000000000000000000000000000000
0e0e0e000e0e07000e070e000e070700070e0e00070e070007070e00070707000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
77777777777777777777777777777777777777777777777777777777777777770000000000000000000000000000000000000000000000000000000000000000
__gff__
0002020101020002000000000000000000000000010000020000000000000000010101010101010101010101010100000101010101010101010101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
3633333333333333333933333333390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000003200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000003200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000003200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000003200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573200000000320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300000000000000000322b212121320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573222242424320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3000000000000000003222242424320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3050515253545556573222242424320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
300000000000000000322c232323320000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3760616263646566673831676767380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
011000000f3201632014320123200f3201632014320123200f3201632014320123200f3201632014320123200f3201632014320123200f3201632014320123200f3201632014320123200f320163201432012320
01100000144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410144100f410124100f4101441012410144100f410
000400002d7201f7301875015750117500e7400b720097200771005710047100271000710007100470001700007000b7000970007700067000570005700057000470004700037000370002700017000070000700
000400002d6201f6301865015650116500e6400b620096200761005610046100261000610006100460001600006000b6000960007600066000560005600056000460004600036000360002600016000060000600
001400000c13011150171501c1101f12021130261302a1402c1402e1503015033160351703517034170321602e15029150211401b1401715014130111500f1500f1500f150101401314015140181401b1401f140
__music__
01 00004344

