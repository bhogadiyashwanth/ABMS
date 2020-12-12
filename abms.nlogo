breed [gates gate]
breed [chargers charger]
breed [agvs agv]

agvs-own [ carrying-pallets free destination current-location charge capacity ] ;;" gate-1 ", " sorting area "
gates-own [ number pallets pallets-present ]
chargers-own [ number empty ]

globals
[
  test-variable
  route-list
  pallets-at-sorting-zone
]

to draw-buffer-zone
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      set pcolor yellow
    ]
  ]
end

to draw-gate-x         ;; get value of gate from chooserand then store as global variable
  if mouse-down?
  [
     create-gates 1 [
       setxy mouse-xcor mouse-ycor
       set shape "square"
       set size 1.5
       set number currently-drawing-gate
       set color pink
       set pallets true
      set pallets-present 0
      ]

    stop
  ]
end


to create-route-from-to
  let current-route (list from-route (list) to-route) ;; [["buffer-zone",[],"gate-1"],["buffer-zone",[],"gate-1"],["buffer-zone",[],"gate-1"]] -> route-list
  set route-list lput current-route route-list
end



to draw-route-from-to

  if mouse-down? [
    let current-list (list)
    let current-position -1
    let changed False
    ;; my-route = ["gate-1" [] "gate-2"]
    ;; current-list
    foreach route-list
    [
      [my-route] ->
      if first my-route = from-route and last my-route = to-route
      [
        set current-list item 1 my-route
        set current-position position my-route route-list
        ifelse not empty? current-list
        [
          if last current-list != (patch mouse-xcor mouse-ycor)
          [
            set current-list lput (patch mouse-xcor mouse-ycor) current-list
            set my-route replace-item 1 my-route current-list
            set current-list my-route
            set changed True
            ask patch mouse-xcor mouse-ycor
            [
              set pcolor black
            ]
          ]
        ]
        [
          set current-list lput (patch mouse-xcor mouse-ycor) current-list
          set my-route replace-item 1 my-route current-list
          set current-list my-route
          set changed True
          ask patch mouse-xcor mouse-ycor
          [
            set pcolor black
          ]
        ]
      ]
      print(route-list)
    ]
    if current-position != -1 and changed
    [
      set route-list replace-item current-position route-list current-list
    ]
  ]

end






to patch-eraser
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      if pcolor = black
      [
        loop-through-route (patch mouse-xcor mouse-ycor)
      ]
      set pcolor grey - random-float 0.5
    ]
  ]
end

to loop-through-route [ current-patch ]
  let index 0
  loop [
    if index = length route-list [ stop ]
    let path item 1 (item index route-list)
    set path remove current-patch path
    let current-route replace-item 1 (item index route-list) path
    set route-list replace-item index route-list current-route
    print route-list
    set index index + 1
  ]
end

to turtle-eraser
  if mouse-down?
  [
    ask turtles-on (patch-set patch mouse-xcor mouse-ycor)
    [
      die
    ]
  ]
end


to setup
  clear-all
  reset-ticks
  ask patches [
    set pcolor grey - random-float 0.5
  ]
  set pallets-at-sorting-zone 0
  set route-list (list)
end


to setup-agv
  reset-ticks
  set-default-shape agvs "truck"
  ask agvs [ die ]
  set pallets-at-sorting-zone 0
  if count agvs != num_agv[
    ask n-of num_agv (patches with [pcolor = yellow]) [sprout-agvs 1 [
      set charge 120
      set current-location "buffer-zone"
      set size 2
      let dum random 100
      set color white - dum

      set free true
      set destination ""
      set capacity 30
    ]
   ]
  ]
  ask gates [
    set pallets-present 100
  ]

end

to main-logic
  let gates_with_pallets gates with [ pallets-present > 0 ]
  ask gates_with_pallets
  [
    let dummy number

    let current-agv one-of agvs with [ free = true and current-location = "buffer-zone" and charge > calc-distance-agv dummy ]
    ask agvs with [ charge < calc-distance-agv dummy and free = true ]
    [
      charge-agvs-main
    ]
    if current-agv != nobody[
    let pallets-picked 0
    let dummy-pallets pallets-present



    ask current-agv [
        if dummy-pallets > capacity [
          set dummy-pallets capacity
        ]
        set pallets-picked dummy-pallets
        set carrying-pallets dummy-pallets
        set destination dummy
        set free false
      ]
     set pallets-present pallets-present - pallets-picked
    ]
  ]
  ask agvs [ move-agv current-location destination]
end

to go
  goto-charge-agvs
  charge-agvs
  main-logic
  gate-to-sorting
  sorting-to-buffer

  if ticks < SPAWN-TILL [
    pallets-spawing-at-gates
  ]
  let dum1 0
  ask gates [
    set dum1 dum1 + pallets-present
  ]
  ifelse dum1 = 0 and ticks > SPAWN-TILL [
    let agvs-dum agvs with [ current-location = "buffer-zone" and destination = "" ]
    if count agvs-dum = num_agv [ stop ]
  ][
    set dum1 0
  ]
  tick
end

to charge-agvs-main
  let empty-charger one-of chargers with [ empty = true ]
  let charge-location ""
  if empty-charger != nobody
  [
    ask empty-charger [
      set empty false
      set charge-location number
      ask myself [
        set free false
        set destination charge-location
      ]
    ]

    ;      move-agv current-location charge-location
  ]
end


to goto-charge-agvs
  ask agvs with [ charge < charge-threshold / 100 * full-charge and destination = "" and current-location = "buffer-zone" ] [

    charge-agvs-main
;      move-agv current-location charge-location

  ]
end

to charge-agvs
  ask chargers with [ empty = false] [
    ask agvs with [ current-location = [number] of myself ] [
      ifelse charge >= full-charge [
;        move-agv current-location "buffer-zone"
        set destination "buffer-zone"
        set free true
        ask myself [ set empty true ]
      ]
      [
        set charge charge + 1
      ]
    ]
     if not any? agvs with [current-location = [number] of myself or destination = [number] of myself]
    [
      set empty true
      print "HI"
    ]
  ]
end
to sorting-to-buffer
  ask agvs [ print(current-location) ]
  ask agvs with [ current-location = "sorting-zone" ] [
    set destination "buffer-zone"
  ]
end

to gate-to-sorting
  ask agvs with [ current-location = "gate-1" or current-location = "gate-2" or current-location = "gate-3" or current-location = "gate-4" or current-location = "gate-5" ] [
    set destination "sorting-zone"
  ]
end


to pallets-spawing-at-gates
  if remainder ticks 150 = 0 [
    ask gates [
      set pallets-present pallets-present + pallets-spawn-rate
    ]
  ]
end


to move-agv [ from-location to-location ]
  if to-location != "" [
  foreach route-list
  [
    [route] ->
    if first route = from-location and last route = to-location[
      let flag 0
      foreach reverse item 1 route [
        [path] ->
          let temp 0
          if path = patch-here [
            set temp position path reverse item 1 route
            set temp temp - 1
            if temp = -1  [
             move-inside self to-location
             stop
           ]
            move-to item temp reverse item 1 route
            set charge charge - 1
            set flag 1
            stop
          ]
      ]
        if flag = 0 [
          move-to first item 1 route
        ]
    ]
      if last route = from-location and first route = to-location [
        let flag 0
        foreach item 1 route [
        [path] ->
          let temp 0
          if path = patch-here [
            set temp position path item 1 route
            set temp temp - 1
            if temp = -1  [
             move-inside self to-location
             stop
           ]
            move-to item temp item 1 route
            set charge charge - 1
            set flag 1
            stop
          ]
      ]
        if flag = 0 [
          move-to last item 1 route
        ]
      ]
  ]
  ]
end

to move-inside [ my-agv to-location ]
  ask my-agv [
        set current-location to-location
        (ifelse
          current-location = "sorting-zone"
          [
            set pallets-at-sorting-zone pallets-at-sorting-zone + carrying-pallets
            set carrying-pallets 0
            move-to one-of patches with [ pcolor = cyan ]
          ]
          current-location = "buffer-zone"
          [
            set free true
            move-to one-of patches with [ pcolor = yellow ]
          ]
          []
        )
         set destination ""

  ]

;  ask chargers with [ number = to-location ] [
;   set empty false
;  ]
end


to draw-sorting-area
  if mouse-down?
  [
    ask patch mouse-xcor mouse-ycor
    [
      set pcolor cyan
    ]
  ]
end

to draw-charger-x         ;; get value of gate from chooserand then store as global variable
  if mouse-down?
  [
     create-chargers 1 [
      setxy mouse-xcor mouse-ycor
      set shape "square"
      set size 1.5
      set number currently-drawing-charger
      set color blue
      set empty true
    ]

    stop
  ]
end

to-report calc-distance-agv [to-gate]
  let total-length charge-threshold
  foreach route-list
  [
    [route] ->
   if first route = "buffer-zone" and last route = to-gate [
     set total-length total-length + (length item 1 route)
    ]
   if last route = "buffer-zone" and first route = to-gate [
     set total-length total-length + (length item 1 route)
    ]
    if last route = "sorting-zone" and first route = to-gate [
     set total-length total-length + (length item 1 route)
    ]
    if first route = "sorting-zone" and last route = to-gate [
     set total-length total-length + (length item 1 route)
    ]
    if first route = "sorting-zone" and last route = "buffer-zone" [
     set total-length total-length + (length item 1 route)
    ]
    if last route = "sorting-zone" and first route = "buffer-zone" [
     set total-length total-length + (length item 1 route)
    ]
  ]
  report total-length
end
@#$#@#$#@
GRAPHICS-WINDOW
395
19
1099
405
-1
-1
11.42424242424243
1
10
1
1
1
0
1
1
1
-30
30
-16
16
0
0
1
ticks
30.0

BUTTON
44
111
186
148
NIL
draw-buffer-zone
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
46
65
191
98
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
201
254
342
287
NIL
patch-eraser
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
46
340
187
385
from-route
from-route
"gate-1" "gate-2" "gate-3" "gate-4" "gate-5" "gate-6" "gate-7" "gate-8" "gate-9" "gate-10" "buffer-zone" "sorting-zone" "charger-1" "charger-2" "charger-3" "charger-4" "charger-5" "charger-6" "charger-7" "charger-8" "charger-9" "charger-10"
0

CHOOSER
202
340
343
385
to-route
to-route
"gate-1" "gate-2" "gate-3" "gate-4" "gate-5" "gate-6" "gate-7" "gate-8" "gate-9" "gate-10" "buffer-zone" "sorting-zone" "charger-1" "charger-2" "charger-3" "charger-4" "charger-5" "charger-6" "charger-7" "charger-8" "charger-9" "charger-10"
11

BUTTON
43
156
186
194
NIL
draw-gate-x
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
45
200
188
245
currently-drawing-gate
currently-drawing-gate
"gate-1" "gate-2" "gate-3" "gate-4" "gate-5" "gate-6" "gate-7" "gate-8" "gate-9" "gate-10"
2

BUTTON
201
110
343
148
NIL
draw-sorting-area
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
201
156
344
196
NIL
draw-charger-x
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
199
200
345
245
currently-drawing-charger
currently-drawing-charger
"charger-1" "charger-2" "charger-3" "charger-4" "charger-5" "charger-6" "charger-7" "charger-8" "charger-9" "charger-10"
4

BUTTON
45
253
187
286
NIL
turtle-eraser
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
202
297
343
330
NIL
draw-route-from-to
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
45
296
187
329
NIL
create-route-from-to
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
202
65
283
98
setup-agv
setup-agv
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
290
32
356
98
num_agv
40.0
1
0
Number

BUTTON
47
28
110
61
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
50
402
187
440
export-world-1
export-world \"world1.csv\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
202
402
344
441
import-world-1
carefully [\n     import-world \"world1.csv\"\n ][\n  print \"file does not exist\"\n ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
398
467
570
500
pallets-spawn-rate
pallets-spawn-rate
0
100
52.0
1
1
NIL
HORIZONTAL

MONITOR
775
412
913
457
Pallets At Sorting Area
pallets-at-sorting-zone
17
1
11

MONITOR
670
528
767
573
Pallets at Gate-1
[pallets-present] of gates with [ number = \"gate-1\" ]
17
1
11

MONITOR
798
530
895
575
Pallets at Gate-2
[pallets-present] of gates with [ number = \"gate-2\" ]
17
1
11

MONITOR
930
531
1027
576
Pallets at Gate-3
[pallets-present] of gates with [ number = \"gate-3\" ]
17
1
11

TEXTBOX
745
503
928
531
Pallets Spawn at Every 250 Ticks
11
0.0
1

SLIDER
399
421
571
454
full-charge
full-charge
0
400
200.0
1
1
NIL
HORIZONTAL

SLIDER
578
422
750
455
charge-threshold
charge-threshold
0
100
22.0
1
1
NIL
HORIZONTAL

BUTTON
205
459
343
499
import-world-2
carefully [\n     import-world \"world2.csv\"\n ][\n  print \"file does not exist\"\n ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
51
460
188
500
export-world-2
export-world \"world2.csv\"
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1124
17
1324
167
Pallet-Count
ticks
Pallets
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot pallets-at-sorting-zone"

PLOT
1201
233
1401
383
Throughput
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"thourghhgput" 1.0 0 -16777216 true "" "plot pallets-at-sorting-zone / (ticks + 1)"

INPUTBOX
401
511
556
571
SPAWN-TILL
500.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

This model works as a tool that helps the user to build various layouts of warehouses. This can help him study the performances of warehouse under different setups and understand the factors that effect the warehouse. Hence, the model helps the user in cutting the cost it would take to experiment with all the entities involved in warehouse in real-time.

## HOW IT WORKS

Our warehouse model involves the following entities -
1. AGVs (Automated Guided Vehicles): These vehicles carry the pallets spawned at the unloading gates to the sorting area in a user-specified path. The AGVs are powered by electricity. The AGVs have a certain capacity of pallets that they can pick up at a time.

2. Gates: These gates represent the unloading gates in an actual warehouse where trucks arrive and drop off pallets containing goods.

3. Buffering Zone: When the AGVs are "free" i.e when they don't have any pallets to pick they wait in the buffering zone.

4. Charging bays:  When the AGV's charge levels drop below a certain user-specified value they go to a charging bay that is empty and recharge their batteries there.

The user has the ability to import a pre-existing model of a warehouse (could be their own warehouses) from a csv file. After changing a few parameters and deciding upon the setup they can export this layout to a csv file.

The user has to initialize the values of certain variables and draw the paths from the buffering zone to charging bays, from the buffering zone to the sorting zone, the sorting zone to the unloading gates. The pallets are spawned at the gates at a certain rate and any AGV which is free (in the buffering zone or the ones which are not carrying any pallets at the moment) is assigned to a certain gate to pick up the pallets according to the capacity.

The pallets are dropped off at the sorting zone for further processing (dispatch, transportation, etc)

The AGVs calculate the charge required to carry pallets from the gate to the sorting zone and getting back to the buffer zone. The AGVs only move if they have the appropriate amount of charging left to make the round trip. Otherwise, they go to a charging bay which is free to recharge their batteries.

## HOW TO USE IT

1. Setup the area.
2. Draw Buffer-Zone and Sorting-Zone using the drawing tool.
3. Draw Gates and Charging Stations using the drawing tool.
4. Draw routes from source(buffer-zone/sorting-zone/charging-station/gate) the 
   destination(buffer-zone/sorting-zone/charging-station/gate).
5. Input the number of AGVs required(num_agv).
6. Adjust the slider parameters(full-charge, charge-threshold, pallets-spawn-rate).
7. Look at the monitors to see palletes spawning at gates present.
8. Look at the monitors to see count of unloaded pallets at the Sorting Zone.


Parameter:
num_agv: Number of AGVs for processing the pallets.
full-charge : The maximum amount of charge that an AGV can attain.
charge-threshold : The threshold at which the AGV goes to charging station for charging itself
pallets-spawn-rate : The Rate at which the pallets spawn at the gates.
SPAWN-TILL : Number of ticks till the spawing is active.

Notes:
- One unit of charge is deducted for every move an AGV does.
- One unit of charge is increased upto "full-charge" when the AGV is at charging station.

There are four monitors to show the count of unloaded pallets at soring zone, count of pallets present at gate-1, gate-2 and gate-3.


## THINGS TO NOTICE

* Even when the path from one location to another is in a circle the AGVs choose the shortest path.
* As the number of AGVs is increased in the warehouse we can observe that for some number of AGVs the throughput is maximized for any particular layout.

Below is the plot for experiments that has benn conducted for 'world-2' layout in the model for different Number of AGVs (i.e., 3,5,9,20,35,40)
 ![Example](file:abms.png)
From the plot, we can observe that at num_agv = 20 the number of ticks taken to process all the AGVs (i.e., pickup & drop pallets, go to charging stations, etc) is 832 which is the optimal one among the conducted experiments.


## THINGS TO TRY

Try adjusting the parameters under various settings. How different factors are affecting the warehouse setup.

Try running the experiments on the specific warehouse by setting different number of AGVs("num_agv"). This may tell us the optimal number of AGVs required for the created setup.

Try adding more complexiety or factors for charging stations that would decrease the charging time of AGV.

## EXTENDING THE MODEL

There are number of ways to add many features to the model. One of them could be independent spawing rate for each gate. 
What happens when there are junctions for the routes?
What happens when we add two way route from a single route?


## NETLOGO FEATURES
Note the use of breeds to model three different kinds of turtles (Gates, Charging Stations, AGVs). 
Note the use of "mouse-down" that enables to draw the buffer-zone, sorting zone and other turtles.
Note the use of "one-of" agentset reporter to select random AGV to pickup and drop the pallets.

## RELATED MODELS

Look at the Agent-based simulation study for improving logistic warehouse performance work which has been done for three specific layouts whereas our tool enables user to customize and build the warehouse layout of his own.

## CREDITS AND REFERENCES

P. Ribino, M. Cossentino, C. Lodato, S. Lopes
Agent-based simulation study for improving logistic warehouse performance
J Simul, 12 (1) (2018), pp. 23-41, 10.1057/s41273-017-0055-z

Ito, T., & Mousavi Jahan Abadi, S. M. (2002). Agent-based material handling and inventory planning in warehouse. Journal of Intelligent Manufacturing, 13(3), 201–210. https://doi.org/10.1023/A:1015786822825

Maka, A., Cupek, R., & Wierzchanowski, M. (2011). Agent-based modeling for warehouse logistics systems. Proceedings - 2011 UKSim 13th International Conference on Modelling and Simulation, UKSim 2011, 151–155. https://doi.org/10.1109/UKSIM.2011.37

Taylor, P., Datta, P. P., Christopher, M., & Allen, P. (2007). A Leading Journal of Supply Chain Management Agent-based modelling of complex production / distribution systems to improve resilience. International Journal of Logistics Research: And Applications, 10(3), 187–203.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

guided
true
0
Rectangle -6459832 true false 75 75 120 210
Rectangle -7500403 true true 120 150 195 210
Line -16777216 false 120 120 195 120

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup
import-world "world2.csv"
setup-agv</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="to-route">
      <value value="&quot;sorting-zone&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="charge-threshold">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num_agv">
      <value value="3"/>
      <value value="5"/>
      <value value="9"/>
      <value value="15"/>
      <value value="25"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="currently-drawing-gate">
      <value value="&quot;gate-3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pallets-spawn-rate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="currently-drawing-charger">
      <value value="&quot;charger-5&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="full-charge">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SPAWN-TILL">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="from-route">
      <value value="&quot;gate-1&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
