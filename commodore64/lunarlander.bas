10 rem *** moonlander for commodore 64 basic v2
20 rem *** version 1.5 08/11/2025
30 rem *** converted from c/qb64 by george mcginn
40 rem *** apollo moon lander simulator - real-time joystick
50 print chr$(147):poke53280,0:poke53281,0
60 gv=5:sg=32:vx=10000:mv=2500:mh=10:ds=0.1
70 dd=4700:df=1500:ad=4850:af=5187:av=10000:mi=100
80 dim et(9):dim dt(9):dim vf(9):dim hf(9):dim ic(9):np=0
90 t1=5:t2=0:td=2.6:pr=4
100 dm=df:tm=dd+dm+ad+af:al=7500:pa=7500:di=0
110 vd=200+int(rnd(1)*501):hs=50+int(rnd(1)*151):if rnd(1)>0.5 then hs=-hs:hp=0:ct=0:np=0
120 vb=0:hb=0:dc=0
125 gosub 7000
130 print chr$(147)
140 print "======================================="
150 print "     apollo lunar lander simulator"
160 print "======================================="
170 print
180 print "real-time joystick control (port 2):"
190 print "  down  = increase vertical thrust"
200 print "  up    = decrease vertical thrust" 
210 print "  left  = thrust left"
220 print "  right = thrust right"
230 print "  button = abort to orbit"
240 print
250 print "starting conditions:"
260 print "  - altitude: 7,500 ft"
270 print "  - vertical speed: "; vd; " ft/s"
280 print "  - horizontal speed: "; hs; " ft/s"
290 print "  - descent fuel: ";dm;" lbs"
300 print
310 print "objective: land with speeds <= 5 ft/s"
320 print
330 print "press any key to begin real-time flight..."
340 get k$:if k$="" then 340
346 print chr$(147)
347 print "======================================="
348 print "        current landing status"
349 print "======================================="
350 print
351 print "            time:"
352 print "        altitude:"
353 print "      difference:"
354 print "  vertical speed:"
355 print "horizontal speed:"
356 print "  fuel remaining:"
357 print
358 print "       vburn:      lbs/s"
359 print "       hburn:      lbs/s":print:print
360 if al<=0 then goto 5000
370 js=peek(56320)
400 if vb=0 then vi=100:goto 415
401 if vb<100 then vi=1:goto 415
402 vi=10:if vd>=400 then vi=100
415 if vb<=100 then vr=1:goto 425
416 if vb>=300 then vr=50:goto 425  
417 vr=10
425 if (js and 2)=0 then if vb<mv then vb=vb+vi
430 if (js and 1)=0 then if vb>0 then vb=vb-vr:if vb<0 then vb=0
435 if (js and 4)=0 then if hb>-mh then hb=hb-1
440 if (js and 8)=0 then if hb<mh then hb=hb+1
460 if (js and 16)=0 then goto 2000
480 if dm>0 then fu=(vb/10+abs(hb))*ds:if fu>dm then fu=dm
490 if dm>0 then dm=dm-fu:tm=dd+dm+ad+af:ms=tm/sg
500 gosub 1000:ct=ct+ds
510 gosub 6000
520 dc=dc+1:if dc>=1 then dc=0:gosub 3000
530 if vd>400 and ct>=1.3 and int(ct)>int(ct-ds) then gosub 4000
540 if al>0 and ct>=1.3 and int(ct/2)>int((ct-ds)/2) then gosub 4000
550 goto 360
1000 if dm<=0 then vb=0:hb=0
1010 ms=tm/sg:ta=(vb/10)*vx/(ms*sg):na=gv-ta
1020 al=al-vd*ds:vd=vd+na*ds
1030 ha=hb*vx/(ms*sg):hp=hp+hs*ds:hs=hs+ha*ds:return
2000 print chr$(147)
2010 print:print "aborting..."
2020 if al<mi then poke 646,2:print "too low to abort safely! crashing.":poke 646,1:al=0:goto 5000
2030 if af<=0 then poke 646,2:print "no ascent fuel left! crashing.":poke 646,1:al=0:goto 5000
2040 dv=av*log((ad+af)/ad):lo=5512
2050 if dv>=lo-abs(hs) then poke 646,5:print "abort successful with ";int(dv);"ft/s delta-v":poke 646,1:goto 5500
2060 poke 646,2:print "abort failed with ";int(dv);"ft/s delta-v":poke 646,1:goto 5500
3000 if np=0 then return
3020 j=0
3030 if j>=np then return
3040 if ct<dt(j) then return
3050 poke 211,0:poke 214,16:sys 58640
3051 print "                                       ";
3052 poke 211,0:poke 214,16:sys 58640:
3060 poke 646,7:print "[mc: t=";int(et(j)*10)/10;"] ";
3070 if ic(j)=1 then poke 646,5:print "all nominal":poke 646,1:goto 3110
3075 if vf(j)=-999 then poke 646,5:print "vburn nominal ";:poke 646,1
3080 if vf(j)<>0 and vf(j)<>-999 then poke 646,7:print "vburn ";int(vf(j)*10)/10;" ";
3085 if hf(j)=-999 then poke 646,5:print "hburn nominal ";:poke 646,1
3090 if hf(j)<>0 and hf(j)<>-999 then poke 646,7:print "hburn ";hf(j);" ";
3100 print "                                        ";
3110 poke 646,1
3130 for k=j to np-2:et(k)=et(k+1):dt(k)=dt(k+1):vf(k)=vf(k+1):hf(k)=hf(k+1):ic(k)=ic(k+1):next k
3140 np=np-1
3150 goto 3020
4000 if al<=0 or vd<=0 then return
4010 ad=(vd*vd-t1*t1)/(2*al):ta=gv+ad:vo=ta*ms*sg/vx
4020 va=int(vo):if va>mv then va=mv:if va<0 then va=0
4030 if abs(hs)<=t1 then ha=0:goto 4035
4031 hc=int(-hs*0.1):if abs(hc)<1 and abs(hs)>t1 then hc=-1:if hs<0 then hc=1
4032 ha=hc:if abs(hc)>mh and hc>0 then ha=mh
4033 if abs(hc)>mh and hc<0 then ha=-mh
4035 if abs(vo*10-vb)<=1 and abs(hs)<=t1 then ic=1:va=0:ha=0:goto 4060
4040 if abs(vo*10-vb)<=1 then va=-999:goto 4045
4041 if vo<10 then va=int(vo*10)/10:goto 4043
4042 va=int(vo)
4043 if va<0 then va=0
4045 if abs(hs)<=t1 then ha=-999:goto 4050
4050 ic=0
4060 et(np)=ct:dt(np)=ct+td+pr:vf(np)=va:hf(np)=ha:ic(np)=ic:np=np+1:return
5000 if al<0 then al=0
5010 poke 646,7
5020 print chr$(147)
5030 print "======================================="
5040 print "       final landing results"
5050 print "======================================="
5060 print
5070 print "        touchdown at t: ";int(ct*10)/10;"s"
5080 print "  final downward speed: ";int(vd*10)/10;"ft/s"
5090 print "final horizontal speed: ";int(hs*10)/10;"ft/s"
5100 print "        fuel remaining: ";int(dm);"lbs"
5110 print
5120 if vd<=5 and abs(hs)<=5 then poke 646,5:print "perfect landing! impact speed is safe.":poke 646,1:goto 5500
5130 if vd<=15 and abs(hs)<=15 then poke 646,5:print "good landing (minor impact).":poke 646,1:goto 5500
5140 poke 646,2:print "crash landing! impact speed is too high.":poke 646,1
5500 print:print "press any key to continue ..."
5520 get k$:if k$="" then 5520
5530 print chr$(147)
5540 poke53280,6:poke53281,6:print chr$(147)
5550 end
6000 di=al-pa:pa=al
6010 poke 646,7
6030 poke 211,18:poke 214,5:sys 58640:print "          ";
6040 poke 211,18:poke 214,5:sys 58640:print int(ct*10)/10
6060 poke 211,18:poke 214,6:sys 58640:print "          ";
6065 if al>7500 or al<=100 then poke 646,2
6066 if al>100 and al<=750 then poke 646,5
6070 poke 211,18:poke 214,6:sys 58640:print int(al*10)/10
6080 poke 646,7
6090 poke 211,18:poke 214,7:sys 58640:print "          ";
6095 if di>=0 then poke 646,2
6096 if di>=-1 and di<=-0.5 then poke 646,5
6100 poke 211,18:poke 214,7:sys 58640:print int(di*10)/10
6105 poke 646,7
6120 poke 211,18:poke 214,8:sys 58640:print "          ";
6125 if vd<0 then poke 646,2                 
6126 if vd>0 and vd<=15 then poke 646,5      
6127 if vd>200 then poke 646,2
6130 poke 211,18:poke 214,8:sys 58640:print int(vd*10)/10
6140 poke 646,7
6150 poke 211,18:poke 214,9:sys 58640:print "          ";
6155 if abs(hs)<=5 then poke 646,5
6156 if abs(hs)>50 then poke 646,2
6160 poke 211,18:poke 214,9:sys 58640:print int(hs*10)/10
6170 poke 646,7
6180 poke 211,18:poke 214,10:sys 58640:print "          ";
6185 if dm<=200 then poke 646,2
6190 poke 211,18:poke 214,10:sys 58640:print int(dm*10)/10
6200 poke 646,7
6210 poke 211,14:poke 214,12:sys 58640:print "     ";
6220 poke 211,14:poke 214,12:sys 58640:print vb/10
6240 poke 211,14:poke 214,13:sys 58640:print "    ";
6250 poke 211,14:poke 214,13:sys 58640:print hb
6255 poke 646,7
6260 return
7000 print chr$(147):poke53280,0:poke53281,0:poke 646,1
7010 print "   **                        *****"
7020 print "  *  *                       *   *"
7030 print " *    * ";
7040 poke 646,5
7050 print "apollo lunar lander";
7060 poke 646,1
7070 print " ** o **"
7080 print " ******   ";
7090 poke 646, 5:print "simulator v1.5    ";
7100 poke 646,1:print "**   **"
7110 print " *    *          by         *******"
7120 print " *    *    george mcginn    *     *"
7130 print " ******                    *       *"
7140 print "   **                     *         *"
7150 print
7160 print
7170 poke 646,7
7180 print tab(5);"a commodore-64 original game"
7190 print
7200 print tab(3);"take control of the lem after the"
7210 print tab(2);"guidance computer fails and safely"
7220 print tab(7);"land on the lunar surface"
7230 print
7240 print
7250 poke 646,5
7260 print tab(12);"launching in..."
7270 poke 646,1
7280 print
7290 for dc=10 to 0 step -1
7300 poke 211,19:poke 214,19:sys 58640
7310 print "   ";
7320 poke 211,19:poke 214,19:sys 58640
7330 poke 646,2
7340 print dc;
7350 poke 646,1
7360 for np=1 to 500:next np
7370 next dc
7380 print
7390 poke 646,5
7400 print:print tab(16);"liftoff!"
7410 poke 646,1
7420 for np=1 to 500:next np
7430 dc=0:np=0:return