10 rem *** moonlander for commodore 64 basic v2
20 rem *** version 1.0 04/10/2025
30 rem *** converted from c/qb64 by george mcginn
40 rem *** apollo moon lander simulator
50 print chr$(147):poke53280,0:poke53281,0
60 gv=5:sg=32:vx=10000:mv=250:mh=10:ds=1
70 dd=4700:df=1500:ad=4850:af=5187:av=10000:mi=100
80 dim et(9):dim dt(9):dim vf(9):dim hf(9):dim ic(9):np=0
90 t1=5:t2=0:td=2.6:pr=4
100 dm=df:tm=dd+dm+ad+af:al=7500:pa=7500:di=0
110 vd=200+int(rnd(1)*501):hs=50+int(rnd(1)*151):hp=0:ct=0:np=0
120 print chr$(147)
130 print "======================================="
140 print "     apollo lunar lander simulator"
150 print "======================================="
160 print
170 print "input: duration,vburn,hburn"
180 print
190 print "starting conditions:"
200 print "  - altitude: 7,500 ft"
210 print "  - vertical speed: "; vd; " ft/s"
220 print "  - horizontal speed: "; hs; " ft/s"
230 print "  - descent fuel: ";dm;" lbs"
240 print
250 print "controls:"
260 print "  - duration: time(secs)"
270 print "  - vburn: 0 to 250 lbs/s"
280 print "  - hburn: -10 to 10 lbs/s"
290 print
300 print "objective:"
310 print "  land with vdown <= 5 ft/s"
320 print "            hspeed <= 5 ft/s"
330 print:print "press any key to continue..."
340 get k$:if k$="" then 340
350 print chr$(147)
360 print "======================================="
370 print "     apollo lunar lander simulator"
380 print "======================================="
390 print
400 print "note: 
410 print "the game also enforces a time delay"
420 print "that the real astronauts experienced."
430 print "the time delay is 6.6 seconds."
440 print "for ground control to process the"
450 print "correction."
460 print
470 print "ready to land on the moon? let's begin!"
480 print "======================================="
490 print:print "press any key to play..."
500 get k$:if k$="" then 500
510 print chr$(147)
520 print "lunar lander agc has failed. land manually"
530 print
540 if al<=0 then goto 5000
550 print chr$(147):poke 646,1
560 print "======================================="
570 print "        current landing status"
580 print "======================================="
590 print
600 print "            time: ";int(ct*1000)/1000
610 print "        altitude: ";int(al*1000)/1000
620 print "      differemce: ";int(di*1000)/1000
630 print "  verticle speed: ";int(vd*1000)/1000
640 print "horizontal speed: ";int(hs*1000)/1000
650 print "  fuel remaining: ";int(dm*1000)/1000
660 print 
670 gosub 3000
680 print:print "dur, vburn, hburn >> ";
690 input du,vb,hb
700 if du=0 and vb=0 and hb=0 then 680
710 if du<0 then goto 2000
720 if vb<0 or vb>mv or hb<-mh or hb>mh then print "invalid":goto 680
730 pa=al
740 sp=int(du/ds):if sp>20 then sp=20
750 for i=1 to sp
760 if al<=0 then 790
770 fu=(vb+abs(hb))*ds:if fu>dm then fu=dm
780 dm=dm-fu:tm=dd+dm+ad+af:ms=tm/sg
790 gosub 1000:ct=ct+ds
800 next i
810 di=al-pa
820 if al>0 and ct>10 then gosub 4000
830 goto 540
1000 rem *** physics integration subroutine
1010 ms=tm/sg:ta=vb*vx/(ms*sg):na=gv-ta
1020 al=al-vd*ds:vd=vd+na*ds
1030 ha=hb*vx/(ms*sg):hp=hp+hs*ds:hs=hs+ha*ds:return
2000 rem *** abort condition handler
2010 print:print "aborting..."
2020 if al<mi then poke 646,2:print "too low to abort safely! crashing.":poke 646,1:al=0:goto 5000
2030 if af<=0 then poke 646,2:print "no ascent fuel left! crashing.":poke 646,1:al=0:goto 5000
2040 dv=av*log((ad+af)/ad):lo=5512
2050 if dv>=lo-abs(hs) then poke 646,5:print "abort successful with ";int(dv);"ft/s delta-v":poke 646,1:goto 5500
2060 poke 646,2:print "abort failed with ";int(dv);"ft/s delta-v":poke 646,1:goto 680
3000 rem *** mission control display subroutine
3010 j=0
3020 if j>=np then return
3030 if ct>=dt(j) then 3050
3040 j=j+1:goto 3020
3050 if ic(j)=1 then poke 646,7:print "[mission control: t=";et(j);"] nominal":poke 646,1:goto 3080
3060 if vf(j)<>0 then poke 646,7:print "[mission control: t=";et(j);"] vburn";vf(j):poke 646,1
3070 if hf(j)<>0 then poke 646,7:print "[mission control: t=";et(j);"] hburn";hf(j):poke 646,1
3080 for k=j to np-2:et(k)=et(k+1):dt(k)=dt(k+1):vf(k)=vf(k+1):hf(k)=hf(k+1):ic(k)=ic(k+1):next k
3090 np=np-1:goto 3020
4000 rem *** trajectory analysis subroutine
4010 te=al/vd:if te<0 then return
4020 pv=vd+gv*te:ps=hs
4030 ve=pv-t1:he=ps-t2:va=int(ve*0.1):ha=int(he*0.05)
4040 if abs(ve)<=t1 and abs(he)<=t1 then ic=1:va=0:ha=0 else ic=0
4050 if np>=10 then return
4060 et(np)=ct:dt(np)=ct+td+pr:vf(np)=va:hf(np)=ha:ic(np)=ic:np=np+1:return
5000 rem *** landing evaluation subroutine
5010 if al<0 then al=0
5020 print:print "on the moon-press any key for results..."
5030 get k$:if k$="" then 5030
5040 print chr$(147)
5050 print "======================================="
5060 print "       current landing results"
5070 print "======================================="
5080 print
5090 print "touchdown at t="; ct
5100 print "  final downward speed: ";int(vd);"ft/s"
5110 print "final horizontal speed: ";int(hs);"ft/s"
5120 print "        fuel remaining: ";int(dm);"lbs"
5130 print
5140 if vd<=5 and abs(hs)<=5 then poke 646,5:print "perfect landing! impact speed is safe.":poke 646,1:goto 5500
5150 if vd<=15 and abs(hs)<=15 then poke 646,5:print "good landing (minor impact).":poke 646,1:goto 5500
5160 poke 646,2:print "crash landing! impact speed is too high.":poke 646,1
5500 rem *** program termination
5510 print:print "press any key to continue ..."
5520 get k$:if k$="" then 5520
5530 print chr$(147)
5540 poke53280,6:poke53281,6:print chr$(147)
5550 end
