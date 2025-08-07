10 rem *** moonlander for commodore 64 basic v2
20 rem *** version 1.0 08/06/2025
30 rem *** converted from c/qb64 by george mcginn
40 rem *** apollo moon lander simulator - real-time joystick
50 print chr$(147):poke53280,0:poke53281,0
60 gv=5:sg=32:vx=10000:mv=250:mh=10:ds=0.1
70 dd=4700:df=1500:ad=4850:af=5187:av=10000:mi=100
80 dim et(9):dim dt(9):dim vf(9):dim hf(9):dim ic(9):np=0
90 t1=5:t2=0:td=2.6:pr=4
100 dm=df:tm=dd+dm+ad+af:al=7500:pa=7500:di=0
110 vd=200+int(rnd(1)*501):hs=50+int(rnd(1)*151):hp=0:ct=0:np=0
120 vb=0:hb=0:dc=0:rem current burn rates, display counter
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
345 rem *** set up static display
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
360 rem *** main real-time game loop
370 if al<=0 then goto 5000
380 rem *** read joystick port 2
390 js=peek(56320)
400 rem *** update burn rates - emergency response for excessive speeds
405 vi=1:if vd>=400 then vi=10:rem set vburn increment rate
410 if (js and 2)=0 then if vb<mv then vb=vb+vi:rem down pressed
415 vr=1:if vb>=30 then vr=5:rem set vburn decrement rate
420 if (js and 1)=0 then if vb>0 then vb=vb-vr:rem up pressed
430 if (js and 4)=0 then if hb>-mh then hb=hb-1:rem left pressed
440 if (js and 8)=0 then if hb<mh then hb=hb+1:rem right pressed
460 if (js and 16)=0 then goto 2000:rem button pressed (abort)
470 rem *** simulate physics for 0.1 seconds
480 if dm>0 then fu=(vb+abs(hb))*ds:if fu>dm then fu=dm
490 if dm>0 then dm=dm-fu:tm=dd+dm+ad+af:ms=tm/sg
500 gosub 1000:ct=ct+ds
510 rem *** update display every frame (0.1 second intervals)
520 gosub 6000
530 rem *** check mission control every 1 frame (0.1 seconds) for responsiveness
540 dc=dc+1:if dc>=1 then dc=0:gosub 3000
550 rem *** trajectory analysis - physics correct timing (every 2 seconds)
555 rem *** emergency guidance for dangerous speeds (every 1 second)  
556 if vd>400 and ct>=1.3 and int(ct)>int(ct-ds) then gosub 4000
560 if al>0 and ct>=1.3 and int(ct/2)>int((ct-ds)/2) then gosub 4000
570 goto 370
1000 rem *** physics integration subroutine
1010 if dm<=0 then vb=0:hb=0:rem no fuel, no thrust
1020 ms=tm/sg:ta=vb*vx/(ms*sg):na=gv-ta
1030 al=al-vd*ds:vd=vd+na*ds
1040 ha=hb*vx/(ms*sg):hp=hp+hs*ds:hs=hs+ha*ds:return
2000 rem *** abort condition handler
2010 print chr$(147)
2020 print:print "aborting..."
2030 if al<mi then poke 646,2:print "too low to abort safely! crashing.":poke 646,1:al=0:goto 5000
2040 if af<=0 then poke 646,2:print "no ascent fuel left! crashing.":poke 646,1:al=0:goto 5000
2050 dv=av*log((ad+af)/ad):lo=5512
2060 if dv>=lo-abs(hs) then poke 646,5:print "abort successful with ";int(dv);"ft/s delta-v":poke 646,1:goto 5500
2070 poke 646,2:print "abort failed with ";int(dv);"ft/s delta-v":poke 646,1:goto 5500
3000 rem *** mission control display subroutine
3010 if np=0 then return:rem no messages queued
3020 j=0
3030 if j>=np then return:rem no more messages
3040 if ct<dt(j) then return:rem message not ready yet
3050 rem *** position cursor and display the message
3055 poke 211,0:poke 214,16:sys 58640
3056 print "                                    ";
3057 poke 211,0:poke 214,16:sys 58640:
3060 poke 646,7:print "[mc: t=";int(et(j)*10)/10;"] ";
3070 if ic(j)=1 then print "nominal":goto 3110
3080 if vf(j)<>0 then print "vburn ";vf(j);" ";
3090 if hf(j)<>0 then print "hburn ";hf(j)
3110 poke 646,1
3120 rem *** remove displayed message from queue
3130 for k=j to np-2:et(k)=et(k+1):dt(k)=dt(k+1):vf(k)=vf(k+1):hf(k)=hf(k+1):ic(k)=ic(k+1):next k
3140 np=np-1
3150 goto 3020:rem check for more messages ready to display
4000 rem *** trajectory analysis subroutine
4010 te=al/vd:if te<0 then return
4020 pv=vd+gv*te:ps=hs
4030 ve=pv-t1:he=ps-t2:va=0:ha=0
4035 rem *** calculate corrections independently
4040 if abs(ve)>t1 then va=int(ve*0.1)
4045 if abs(he)>t1 then ha=int(-he*0.05)
4050 if va=0 and ha=0 then ic=1 else ic=0
4055 if np>=10 then return
4060 et(np)=ct:dt(np)=ct+td+pr:vf(np)=va:hf(np)=ha:ic(np)=ic:np=np+1:return
5000 rem *** landing evaluation subroutine
5010 if al<0 then al=0
5020 print chr$(147)
5030 print "======================================="
5040 print "       final landing results"
5050 print "======================================="
5060 print
5070 print "touchdown at t="; int(ct*10)/10;"s"
5080 print "  final downward speed: ";int(vd);"ft/s"
5090 print "final horizontal speed: ";int(hs);"ft/s"
5100 print "        fuel remaining: ";int(dm);"lbs"
5110 print
5120 if vd<=5 and abs(hs)<=5 then poke 646,5:print "perfect landing! impact speed is safe.":poke 646,1:goto 5500
5130 if vd<=15 and abs(hs)<=15 then poke 646,5:print "good landing (minor impact).":poke 646,1:goto 5500
5140 poke 646,2:print "crash landing! impact speed is too high.":poke 646,1
5500 rem *** program termination
5510 print:print "press any key to continue ..."
5520 get k$:if k$="" then 5520
5530 print chr$(147)
5540 poke53280,6:poke53281,6:print chr$(147)
5550 end
6000 rem *** real-time display update subroutine
6010 di=al-pa:pa=al:rem calculate altitude difference
6020 rem *** update time value
6030 poke 211,18:poke 214,5:sys 58640:print "          ";
6040 poke 211,18:poke 214,5:sys 58640:print int(ct*10)/10
6050 rem *** update altitude value
6060 poke 211,18:poke 214,6:sys 58640:print "          ";
6070 poke 211,18:poke 214,6:sys 58640:print int(al*10)/10
6080 rem *** update difference value
6090 poke 211,18:poke 214,7:sys 58640:print "          ";
6100 poke 211,18:poke 214,7:sys 58640:print int(di*10)/10
6110 rem *** update vertical speed value
6120 poke 211,18:poke 214,8:sys 58640:print "          ";
6130 poke 211,18:poke 214,8:sys 58640:print int(vd*10)/10
6140 rem *** update horizontal speed value
6150 poke 211,18:poke 214,9:sys 58640:print "          ";
6160 poke 211,18:poke 214,9:sys 58640:print int(hs*10)/10
6170 rem *** update fuel remaining value
6180 poke 211,18:poke 214,10:sys 58640:print "          ";
6190 poke 211,18:poke 214,10:sys 58640:print int(dm*10)/10
6200 rem *** update vburn value
6210 poke 211,14:poke 214,12:sys 58640:print "    ";
6220 poke 211,14:poke 214,12:sys 58640:print vb
6230 rem *** update hburn value
6240 poke 211,14:poke 214,13:sys 58640:print "    ";
6250 poke 211,14:poke 214,13:sys 58640:print hb
6260 return