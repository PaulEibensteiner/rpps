globals
[eps step_size]

breed [bouncer-particles bouncer-particle]

; REVERSIBLE PRIMORDIAL PARTICLE SYSTEM DEFINITION BEGINNING

turtles-own
[N]

to color-all
  ask turtles [
    set N (count other turtles in-cone radius 360)
    (ifelse
      N = 7 [set color green]
      N = 3 [set color blue]
      N = 0 or N = 2 or N = 4 or N = 6 [set color red]
      [set color gray]
    )
  ]
end

to count-all
  ask turtles [
    set N (count other turtles in-cone radius 360)
  ]
end

to move-all
  ask turtles [
    let delta_phi (alpha + beta * N)
    set heading (heading + delta_phi)
    forward speed
  ]
end

; REVERSIBLE PRIMORDIAL PARTICLE SYSTEM DEFINITION END

; DEBUGGING

to show-radii
  ask turtles [
    ask patches in-cone radius 360 [ set pcolor turquoise ]
  ]
end

; SINGLE CELL CREATION

to create-signal [x y deg]
  repeat 2 [
    cro 4 [
      set heading (heading + 45)
      forward sqrt 0.5 ; Distance from each other is 1
      set heading deg
      set xcor (xcor + x)
      set ycor (ycor + y)
    ]
  ]
end

to create-bouncer [x y deg]
  repeat 4 [
    create-ordered-bouncer-particles 4 [
      forward 2.75
      set heading deg
      set xcor (xcor + x)
      set ycor (ycor + y)
    ]
  ]
end

; 1/8th rotation per num
to create-rotation [x y deg num]
  crt num [
    set heading deg
    set xcor x
    set ycor y
  ]
end

; MULTI CELL CREATION

; Create a cycle of rotation cells,
; each containing num particles
; thus rotating by num*45 at every step
to create-rotation-cycle [x y deg num]
  let x_cur x
  let y_cur y
  let deg_cur deg - num * beta

  loop [
    create-rotation x_cur y_cur deg_cur num
    set deg_cur deg_cur + num * beta
    set x_cur x_cur + (sin deg_cur) * speed
    set y_cur y_cur + (cos deg_cur) * speed
    if (abs (x_cur - x) < eps and abs (y_cur - y) < eps) [ stop ]
  ]
end

; CREATE BASIC CONFIGURATIONS

to create-interaction-1
  create-signal 0 0 0
  create-bouncer 10 10 90
end

to create-interaction-2
  create-signal 0 -10 0
  create-bouncer 0 0 135
  create-rotation (sqrt 50) (20 + sqrt 50) 135 1
  create-rotation 10 (2 * sqrt 50) -135 3
  create-rotation (sqrt 50) (sqrt 50)  0 2
end

; CREATE ONE OF THE FOUR SIDES OF A TILE

to create-rotation-transformed [x y deg num transform x_orig y_orig]
  (ifelse
    transform = "top-bottom" [ ; Identity transform
      create-rotation-cycle x + x_orig y + y_orig deg num
    ]
    transform = "bottom" [ ; move to new origin and mirror two times
      set x_orig x_orig - sqrt 50
      set y_orig y_orig + 10 - sqrt 50
      create-rotation-cycle x_orig - x y_orig - y deg + 180 num
    ]
    transform = "left-right" [ ; rotate -90 deg and mirror l/r
      create-rotation-cycle (x_orig - y) (y_orig - x) (270 - deg) 8 - num
    ]
    transform = "right" [ ; move to new origin, rotate 90 deg and mirror u/d
      set x_orig x_orig - 10 + sqrt 50
      set y_orig y_orig + sqrt 50
      create-rotation-cycle x_orig + y y_orig + x 90 - deg 8 - num
    ]
    [error (word "transform string '" transform "' not understood")]
  )
end

to create-top-side[x y d transform]
  create-rotation-transformed (2 * sqrt 50) (d + 20 - 2 * sqrt 50) 90 3 transform x y

  create-rotation-transformed 0 d + 20 310 5 transform x y
  create-rotation-transformed (- sqrt 50) (d + 20 - sqrt 50) 225 7 transform x y
  create-rotation-transformed (- 2 * sqrt 50) (d + 20) 160 1 transform x y
  create-rotation-transformed (- 2 * sqrt 50) (d + 30) 200 1 transform x y
  create-rotation-transformed (- sqrt 50) (d + 30 + sqrt 50) 0 2 transform x y
  create-rotation-transformed (sqrt 50) (d + 30 - sqrt 50) 90 5 transform x y
end

to create-bottom-side [x y d transform]
  set d d - 20
  create-rotation-transformed 0 (- d - 10) 20 1 transform x y
  create-rotation-transformed (sqrt 50) (- d - 10 - sqrt 50) 220 7 transform x y

  create-rotation-transformed (- sqrt 50) (- d - 10 - sqrt 50) 150 3 transform x y
  create-rotation-transformed (- 2 * sqrt 50) (- d - 10) 300 5 transform x y
  create-rotation-transformed (- 2 * sqrt 50) (- d - 40) 220 5 transform x y

  create-rotation-transformed (- sqrt 50) (sqrt 50 - d - 40) 80 2 transform x y
  create-rotation-transformed (2 * sqrt 50) (- d - 40 - 2 * sqrt 50) 360 1 transform x y
end

; CREATE ONE WHOLE TILE WITH IT'S CENTER AT POSITION x y WITH STATE state

to create-tile [x y state]
  ifelse state
  [
    create-bouncer x y 135
    create-bouncer (x - sqrt 50) y + sqrt 50 315
  ]
  [
    create-bouncer x y 315
    create-bouncer (x + sqrt 50) (y - sqrt 50) 135
  ]

  create-rotation-cycle x y 109.3 2

  let d 40
  create-top-side x y d "top-bottom"
  create-bottom-side x y d "top-bottom"

  create-top-side x y d "left-right"
  create-bottom-side x y d "left-right"

end

to-report check_multiple_of_k [val_x val_y margin k]
  let remainder_x abs (val_x mod k)
  let remainder_y abs (val_y mod k)
  report (remainder_x <= margin or remainder_x >= k - margin) and (remainder_y <= margin or remainder_y >= k - margin)
end

; COLOR ALL TILES CORRESPONDING TO THEIR STATE

to color-tiles
  ask bouncer-particles [
    let margin 3
    let k 200
    (ifelse
      check_multiple_of_k (xcor + sqrt 50) (ycor - sqrt 50) margin k [
      let r 100
      let center_x 200 * round (xcor / 200)
      let center_y 200 * round (ycor / 200)

      ask patches with [
        pxcor > center_x - r and pxcor <= center_x + r and pycor > center_y - r and pycor <= center_y + r
      ] [ set pcolor gray ]
    ]
      check_multiple_of_k (xcor - sqrt 50) (ycor + sqrt 50) margin k [
      let r 100
      let center_x 200 * round (xcor / 200)
      let center_y 200 * round (ycor / 200)

      ask patches with [
        pxcor > center_x - r and pxcor <= center_x + r and pycor > center_y - r and pycor <= center_y + r
      ] [ set pcolor white ]
    ]
      check_multiple_of_k xcor ycor margin k [ ; don't do shit
      ]
      [print (word "bouncer particle at weird position: (" xcor ", " ycor ")" " which becomes " ((abs xcor) mod 200) ", " ((abs ycor) mod 200))]
      )
  ]
end

; POSITIONING THE ANT EITHER BELOW OR RIGHT OF A GIVEN TILE CENTER

to create-input [x y pos]
  (ifelse
    pos = "below" [
      create-signal (x + sqrt 50) (y - 80 - sqrt 50) 0
      create-signal (x + sqrt 50) (y - 70 - sqrt 50) 0
    ]
    pos = "right" [
      create-signal (x + 80 + sqrt 50) (y - sqrt 50) 270
      create-signal (x + 70 + sqrt 50) (y - sqrt 50) 270
    ]
    [error (word "position string '" pos "' not understood")]
   )
end

; CREATE A FIELD OF 3 BY 3 TILES WITH THE ANT BELOW THE CENTER TILE

to create-3-by-3-setup
  foreach [-1 0 1] [
    i -> foreach [-1 0 1] [
      j -> create-tile (i * 200) (j * 200) false
    ]
  ]
  create-input 0 0 "below"
end

; GLOBAL SETUP FUNCTION

to setup
  clear-all
  set-default-shape turtles "default"
  set eps 0.001

  create-3-by-3-setup

  count-all
  color-all
  color-tiles
  reset-ticks
end

; GLOBAL STEP FUNCTION

to go
  move-all
  count-all
  color-all
  color-tiles
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
2220
2021
-1
-1
2.0
1
30
1
1
1
0
1
1
1
-500
500
-500
500
1
1
1
ticks
10.0

BUTTON
15
10
81
43
setup
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
93
10
156
43
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

INPUTBOX
15
150
178
213
alpha
45.0
1
0
Number

INPUTBOX
16
219
179
279
beta
45.0
1
0
Number

INPUTBOX
15
288
180
348
speed
10.0
1
0
Number

INPUTBOX
15
356
179
416
radius
2.5
1
0
Number

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
