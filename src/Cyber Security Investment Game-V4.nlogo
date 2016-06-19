;; Adversarial Investment Game  
;;     (C) Russell C. Thomas, 2016 is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
;;
;;  AS IS, NO WARRANTYS, NO GUARANTEES
;;   - based on replication of Galla & Farmer (2012)
;;   - with extensions and modifications

extensions [
  array  
  table
  matrix
]

globals [ 
  completed-reset? 
  
  focal-agent-A
  focal-agent-B
  focal-game
  
  focal-agent-A-avg-payoff
  focal-agent-B-avg-payoff
  
  focal-agent-A-sd-payoff
  focal-agent-B-sd-payoff
  
  payoff-highlight
  pointer-row
  pointer-col
  
  green-num-moves-list
  red-num-moves-list
  
  max-moves  ;; the largest number of possible moves = size of each dimension in full payff matrix
  
  agent-list
  
  num-payoff-matricies
  ;num-red-agents
  ;num-green-agents
  max-agents
  
  num-games     ; = # green-v-green games + # green-v-red games = C(g,2) + r * g
  
  ;num-green-v-red
  ;num-green-v-green
  
  avg-green-blind-spots
  avg-red-blind-spots
    
  payoff-display-margin ;; used for offsetting the payoff matrix in the grid, to make space for the investment grid for each focal agent
  right-display-margin  ;; used for displaying move probabilities for each agent
  pr-x-display-width    ;; the number of cells devoted to each agent for displaying pr-x-list
  border                ;; # cells (space) between payoff matrix and pr-x-display
  
  request-redraw-payoff-display?
  
  initial-pr-x
  
  current-display-mode
  currently-displayed-game
  
  focal-payoff-index    ;; integer >= 0
  focal-payoff-A-matrix
  focal-payoff-B-matrix
  focal-payoff-colors  ;; 0 = "green v red" or 1 = "green v green"
  
  mean-payoff-A
  mean-payoff-B
  pct-positive-payoff-A
  pct-positive-payoff-B
  
  move-IDs-A-list        ;; list of move numbers (x) to plot in time series
  move-IDs-B-list 
  
  payoff-row-matrix-list     ;; list of payoff matricies for agent A (row Player)
  payoff-col-matrix-list     ;; list of payoff matricies for agent B (column Player)
  
  ;; these are only used for "optimized" attraction algorithm -- WHICH IS NOT CURRENTLY USED
  payoff-row-matrix-avg-list     ;; list of lists of average of row payoffs matricies for agent A (row Player)
  payoff-col-matrix-avg-list     ;; list of lists of average of row payoffs matricies for agent A (row Player)
  
  green-v-green-index-list
  green-v-red-index-list
  
  
  W-array ; array of weights used to accumulate contributions from each game an agent plays; reused for each agent since each value 
  
  pr-x-matrix ; one row for each player, one column for each possible move.  Setup as global for speed
  
  
  green-best-practice-array   ;; this is the average pr-x-list for all of the best-performing-agents
  red-best-practice-array     ;; this is the average pr-x-list for all of the best-performing-agents
  
  green-best-practices?  ;; true if there exists, currently, a set of best practices (x) for green agents
  red-best-practices?  ;; true if there exists, currently, a set of best practices (x) for red agents  
            
  pr-x-threshold     ; above this threshold, a pr-x is considerd "top"
  
]


breed [red-agents red-agent]
breed [green-agents green-agent]
breed [infrastructure-investments infrastructure-investment]
breed [capability-investments capability-investment]
breed [green-Xs green-X]   ; an "X" is a bundle of practices
breed [red-Xs red-X] 

;; these agent's are purely for display and user interface
breed [highlights highlight]
breed [pointers pointer]


breed [games game]

patches-own [
  payoff-list ;; just a pair of values, for the two focal agents
  my-color
  
  display-pr-x?  ;; true if this patch is part of a pr-x display for an agent
  display-investment-x? ;; true of this patch is part to display for one or more investment's possible-x
  agent-pr-x     ;; the agent for whom to display their pr-x
  agent-pr-x-id  ;; agent id, for whom to display their pr-x 
  investment-list   ;; investment associated with this patch, to display possible-x
  x-value        ;; index value of x
  
]


links-own [
  normal-color
  highlight-color
]

highlights-own [
  previous-x
  previous-y
  current-x
  current-y
]

games-own [
  row-agent
  col-agent
  payoff-matrix-index  ;; an index into the payoff matricies list
  
  current-row-move     ;; updated each round the game is played
  current-col-move
  
  id
  
]

green-Xs-own[
  practice-code-number ; an integer that encodes practice-vector by treating it as binary number
  practice-vector      ; 9 element binary vector 
  
]

red-Xs-own[
  practice-code-number ; a integer that encodes practice-vector by treating it as binary number
  practice-vector      ; 9 element binary vector 
]

infrastructure-investments-own [
  possible-x-list ;; list of index numbers of possible moves for this investment.  Each index number is between 0 and 399
  num-possible-x
  
  defense?       ;; true if this investment facilitates defense
  attack?        ;; true if this investment facilitates attack
  
  id

]

capability-investments-own [
  possible-x-list ;; list of index numbers of possible moves for this investment.  Each index number is between 0 and 399
  num-possible-x
  
  defense?       ;; true if this investment facilitates defense
  attack?        ;; true if this investment facilitates attack
  
  id

]



red-agents-own [
  my-beta   ;; private learning parameters
  my-alpha
  
  current-x ;; player's chosen move in the current round
  history-x-list  ;; list of moves selected by this agent, with one list element added every tick and therefore in chronological order
  unique-history-x-list  ;; list of unique moves selected by this agent (no duplicates)
  
  trigger-novelty?   ;; set to true if the current-x is new to the unique-history-x-list  (but only after ticks > start-novety-at)

  ;; NOW STORED IN GLOBAL MATRIX FOR SPEED  
  ;    pr-x-list ;; list of player's probabilities for each of N possible move ("x")
  Q-array    ;; array of a player's "attraction" to each of N possible moves.  These are updated through learning
  
  possible-x-list ;; list of index numbers of possible moves for each player.  Each index number is between 0 and 399
  num-possible-x
  investment-enabled-x-list ;; list of index numbers that are enabled by BOTH infrastructure and capability investments
  
  
  blind-spots-array ;; array of GREEN OPPONENT'S x where this agent is "blind" -- i.e. does not include in attractiveness calculation. "1" = sighted, "0" blind
  num-blind-spots   ;; = number of of zeros in blind-spots-array
  visibility-list   ;; to collect visibility metric for all games against GREEN;  visibility = proportion of opponent's moves that are visible (i.e. not blind)
                    ;; cleared and updated each tick
  opponent-move-list ;; list of GREEN OPPONENT's moves THIS TICK. Cleared each tick. Used to modify (reduce) the blind-spot-list.
   
  infrastructure-investments-list  
  capability-investments-list
  
  current-payoff
  cum-payoff
  
  current-period-payoff  ; for graphing
  last-period-payoff
  payoff-history
  avg-payoff
  sd-payoff
  
  id ;;  pointer in the agent-list and payoff-list
  feasable-x-list ;; list of agent's feasable moves.  1 = feasable
  
  games-opponents-list
  games-matrix-index-list
  games-position-list
  
  normal-agent-color
  highlight-agent-color
  
  best-performing-agent?   ;; used for identifying best practices
  
  game-list         ; the games this agent is playing in
  game-weight-list  ; one weight value for each game 
  
  ;; DEPRECIATED
  top-x-list  ; list of x indicies that point to pr-x values above pr-x-threshold
  
  
]

green-agents-own [
  my-beta   ;; private learning parameters
  my-alpha
  
  current-x ;; player's chosen move in the current round
  history-x-list  ;; list of moves selected by this agent, with one list element added every tick and therefore in chronological order
  unique-history-x-list  ;; list of unique moves selected by this agent (no duplicates)
  
  trigger-novelty?   ;; set to true if the current-x is new to the unique-history-x-list  (but only after ticks > start-novety-at)

  ;; NOW STORED IN GLOBAL MATRIX FOR SPEED  
  ;    pr-x-list ;; list of player's probabilities for each of N possible move ("x")
  Q-array    ;; array of a player's "attraction" to each of N possible moves.  These are updated through learning
  
  possible-x-list ;; list of index numbers of possible moves for each player.  Each index number is between 0 and 399
  num-possible-x
  investment-enabled-x-list ;; list of index numbers that are enabled by BOTH infrastructure and capability investments
  
  blind-spots-array ;; array of RED OPPONENT'S x where this agent is "blind" -- i.e. does not include in attractiveness calculation.  "1" = sighted, "0" blind
  num-blind-spots   ;; = number of of zeros in blind-spots-array
  visibility-list   ;; to collect visibility metric for all games against GREEN;  visibility = proportion of opponent's moves that are visible (i.e. not blind)
                    ;; cleared and updated each tick
  opponent-move-list ;; list of GREEN OPPONENT's moves THIS TICK. Cleared each tick. Used to modify (reduce) the blind-spot-list.
  
  infrastructure-investments-list  
  capability-investments-list
  
  current-payoff
  cum-payoff
  
  current-period-payoff  ; for graphing
  last-period-payoff
  payoff-history
  avg-payoff
  sd-payoff
  
  id ;;  pointer in the agent-list and payoff-list
  feasable-x-list ;; list of agent's feasable moves.  1 = feasable
  
  games-opponents-list
  games-matrix-index-list
  games-position-list
  
  normal-agent-color
  highlight-agent-color
  
  best-performing-agent?   ;; used for identifying best practices
  
  game-list ; the games this agent is playing in
  game-weight-list  ; one weight value for each game 
  
  ;; DEPRECIATED
  top-x-list  ; list of x indicies that point to pr-x values above pr-x-threshold
  
  
]


;;#######################################################################################################
;;#######################################################################################################
;;                                                  RESET
;;#######################################################################################################
;;#######################################################################################################



to reset 
  clear-all
  set max-moves 400                         ;; 400 + 177 + 50 = 627,  626 = max-pxcor
  set num-possible-moves 100
  set max-agents 28
  set payoff-display-margin 50 ;; cells
  set border 9 ;; cells
  set pr-x-display-width 6 ; round((right-display-margin - border) / num-agents)
  set right-display-margin border + max-agents * pr-x-display-width ;; cells   = 9 + 28 * 6 = 177   (vs 82 before, or 42 more)
  set Gamma 0
  
  set alpha 0.01
  set beta 0.07
  
  set period 300
  set display-mode "2-agent payoff matrix"
  set learning-model "experience weighted"
  set lock-seed false
  set focal-agent-A 0
  set focal-agent-B 1
  set sim-seed 0
  set setup-seed -2147483648 ;; max negative integer.  Will be incremented sequentially each setup click
  set focal-payoff-A-matrix 0
  set focal-payoff-B-matrix 0
  set focal-payoff-colors 0
  
  
  let N num-possible-moves
  set move-IDs-A (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
  set move-IDs-B (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
  set move-IDs-A-list read-from-string (word "[" (replace-newlines move-IDs-A " ") "]")
  set move-IDs-B-list read-from-string (word "[" (replace-newlines move-IDs-B " ") "]")
  
  ;; Thomas 2016 extensions
  set num-agents 2
  set num-payoff-matricies 1
  set num-green-agents 1
  set num-red-agents 1
  ;set payoff-matricies 50
  ;set pct-red-agents 50
  ;set pct-green-v-red 100
  set game-num 0
  
  set top-pr-x-pct 120
  set completed-reset? true
  
end

;;#######################################################################################################
;;#######################################################################################################
;;                                                  SETUP
;;#######################################################################################################
;;#######################################################################################################



to setup
  if completed-reset? = 0 or not completed-reset? [reset]
  let GREEN-V-GREEN 1 ; constants
  let GREEN-V-RED 0   ; constants
  set focal-payoff-colors GREEN-V-RED
  
  clear-all-plots
  clear-turtles
  clear-patches
  clear-drawing
  clear-links
  
  RESET-TICKS
  if (not lock) [set sim-seed sim-seed + 1]
  
  random-seed sim-seed
  with-local-randomness [
    if not lock-seed [set setup-seed setup-seed + 1]
    random-seed setup-seed
    
    set green-best-practice-array array:from-list n-values 400 [0]
    set red-best-practice-array array:from-list n-values 400 [0]
        
    if num-green-agents = 1 and num-red-agents = 0 [
      set num-red-agents 1                           ; there must be at least two agents, either green >= 2 or (green = 1 and red >=1)
    ]
    
    set green-num-moves-list [ ]
    set red-num-moves-list [ ]
    ask patches [
      set  display-pr-x? false  ; default to false
      set display-investment-x? false ; same
      set investment-list [ ] ; initially empty
    ]
    
    let x-list but-first n-values 512 [?]
    set x-list shuffle x-list
    create-green-Xs 400 [
      hide-turtle
      set practice-code-number first x-list
      set x-list but-first x-list
      set practice-vector integer-to-binary-list practice-code-number 9
    ]
    
    set x-list but-first n-values 512 [?]
    set x-list shuffle x-list
    create-red-Xs 400 [
      hide-turtle
      set practice-code-number first x-list
      set x-list but-first x-list
      set practice-vector integer-to-binary-list practice-code-number 9
    ]
    
    set  payoff-row-matrix-avg-list [ ]
    set  payoff-col-matrix-avg-list [ ]
    
    set pr-x-threshold (1 / num-possible-moves ) * top-pr-x-pct / 100
    
     set W-array array:from-list n-values max-moves [0]  ;; SPEED IDEA -- create W-array ONCE as global 
     ifelse model = "Galla & Farmer 2012" [
       set pr-x-matrix matrix:make-constant num-agents max-moves 0
     ]
     [
       set pr-x-matrix matrix:make-constant (num-red-agents + num-green-agents) max-moves 0
     ]

    
    
    let N num-possible-moves
    set move-IDs-A (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
    set move-IDs-B (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
    
    set-current-plot "Move Probabilities - Focal Agent A"
    set-plot-x-range 0 max-moves
    set-current-plot "Move Probabilities - Focal Agent B"
    set-plot-x-range 0 max-moves
    
    if model = "Galla & Farmer 2012" 
    [
      set num-agents 2 ;; force this to 2
      ;set pct-red-agents 50
      ;set payoff-matricies 100
      ;set pct-green-v-red 100
    ] 
    
    set current-display-mode "2-agent payoff matrix"
    ask patches with [pxcor < payoff-display-margin and pycor < payoff-display-margin] 
    [
      set pcolor 2
      set my-color pcolor
    ]
    ask patches with [pxcor > payoff-display-margin and pycor < payoff-display-margin] 
    [
      set pcolor 11
      set my-color pcolor
    ]
    ask patches with [pxcor < payoff-display-margin and pycor > payoff-display-margin] 
    [
      set pcolor 51
      set my-color pcolor
    ]

    let two-factorial  2
    let num-green-v-green-games 0
    ifelse num-green-agents > 2 [
      set num-green-v-green-games ((factorial num-green-agents)  / (two-factorial * ( factorial  (num-green-agents - 2) )) )
    ] 
    [
      if num-green-agents = 2 [
        set num-green-v-green-games 1
      ]
    ]
    set num-games  num-green-v-green-games  + (num-green-agents * num-red-agents)   ; = # green-v-green games + # green-v-red games = C(g,2) + r * g
    
    
    set move-IDs-A-list  read-from-string (word "[" (replace-newlines move-IDs-A " ") "]")
    set move-IDs-B-list  read-from-string (word "[" (replace-newlines move-IDs-B " ") "]")
    
    
    ; initialize investments
    
    if investments? [
      let j 0
      let used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
      let unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned
      let possibility-pool  n-values max-moves [?] 
      create-infrastructure-investments num-green-infrastructure [
        set defense? true
        set attack? false
        let result random-draw-x-list possibility-pool unused-possible-moves-pool used-possible-moves-pool green-infrastr-diversity green-infrastr-span
        set possible-x-list item 0 result
        ;show possibility-pool
        ;show possible-x-list
        set unused-possible-moves-pool item 1 result
        set used-possible-moves-pool item 2 result
        set num-possible-x green-infrastr-span
        hide-turtle
        set id j
        set j j + 1
      ]
      

      set used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
      set unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned
   
     create-infrastructure-investments num-red-infrastructure [
       set defense? false
       set attack? true
        let result random-draw-x-list possibility-pool unused-possible-moves-pool used-possible-moves-pool red-infrastr-diversity red-infrastr-span
        set possible-x-list item 0 result
        ;show possibility-pool
        ;show possible-x-list
        set unused-possible-moves-pool item 1 result
        set used-possible-moves-pool item 2 result
       set num-possible-x red-infrastr-span
       hide-turtle
        set id j
        set j j + 1
     ]
     
     set j 0
      set used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
      set unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned

     create-capability-investments num-green-capabilities [
       set defense? true
       set attack? false
        let result random-draw-x-list possibility-pool unused-possible-moves-pool used-possible-moves-pool green-cap-diversity green-capability-span
        set possible-x-list item 0 result
        ;show (sentence possibility-pool "\n" possible-x-list)
        set unused-possible-moves-pool item 1 result
        set used-possible-moves-pool item 2 result
       set num-possible-x green-capability-span
       hide-turtle
       set id j
        set j j + 1
     ]
     

      set used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
      set unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned

     create-capability-investments num-red-capabilities [
       set defense? false
       set attack? true
        let result random-draw-x-list possibility-pool unused-possible-moves-pool used-possible-moves-pool red-cap-diversity red-capability-span
        set possible-x-list item 0 result
       ; show possibility-pool
       ; show possible-x-list
        set unused-possible-moves-pool item 1 result
        set used-possible-moves-pool item 2 result
       set num-possible-x red-capability-span
       hide-turtle
       set id j
        set j j + 1
     ]
      
      ;user-message "continue?"
    ]
    
    set agent-list [ ]
    let i 0
    
    set green-v-red-index-list [ ]
    set green-v-green-index-list [ ]
    
    ;; create payoff matricies for (A, B) payoff values
    set payoff-row-matrix-list [ ] ; initialize empty list
    set payoff-col-matrix-list [ ] ; initialize empty list
    
    let payoff-matrix-list-index 0 ;; index to all matricies, regardless of colors
    
    let this-payoff-A-matrix (matrix:make-constant  max-moves max-moves 0)
    let this-payoff-B-matrix (matrix:make-constant  max-moves max-moves 0)
    
    let this-gamma Gamma-green-v-green
    if model = "Galla & Farmer 2012" [
      set this-gamma Gamma
    ]
    
    repeat num-green-v-green [       
      let this-col 0
      repeat max-moves [
        let this-row 0
        repeat max-moves [
          let this-payoff-pair random-normal-correlated this-gamma
          matrix:set this-payoff-A-matrix this-row this-col item 0 this-payoff-pair
          matrix:set this-payoff-B-matrix this-row this-col item 1 this-payoff-pair
          set this-row this-row + 1
        ]
        set this-col this-col + 1
      ]
      set payoff-row-matrix-list lput this-payoff-A-matrix  payoff-row-matrix-list
      set payoff-col-matrix-list lput this-payoff-B-matrix  payoff-col-matrix-list
      
      
      calc-avg-row-and-col-avg this-payoff-A-matrix this-payoff-B-matrix
      
      
      set green-v-green-index-list lput payoff-matrix-list-index green-v-green-index-list
      ; increment index
      set payoff-matrix-list-index payoff-matrix-list-index + 1
      
    ]
    
    set this-payoff-A-matrix (matrix:make-constant  max-moves max-moves 0)
    set this-payoff-B-matrix (matrix:make-constant  max-moves max-moves 0)
    
    set this-gamma Gamma-green-v-red
    if model = "Galla & Farmer 2012" [
      set this-gamma Gamma
    ]
    
    repeat num-green-v-red [
      let this-col 0
      repeat max-moves [
        let this-row 0
        repeat max-moves [
          let this-payoff-pair  random-normal-correlated this-gamma
          if asymmetric
          [ 
            set this-payoff-pair transform-log-normal this-payoff-pair
            
          ]
          ;set this-payoff-pair (list ((item 0 this-payoff-pair) + green-red-offset)  ((item 1 this-payoff-pair - green-red-offset) ) )
          if debug [print (sentence this-payoff-pair)]
          matrix:set this-payoff-A-matrix this-row this-col item 0 this-payoff-pair
          matrix:set this-payoff-B-matrix this-row this-col item 1 this-payoff-pair
          set this-row this-row + 1
        ]
        set this-col this-col + 1
      ]
      set payoff-row-matrix-list lput this-payoff-A-matrix  payoff-row-matrix-list
      set payoff-col-matrix-list lput this-payoff-B-matrix  payoff-col-matrix-list
      
      
;; THIS IS ONLY USED IN "OPTIMIZED" ATTRACTION ALGORITHM - WHICH IS DEPRECIATED
     ; calc-avg-row-and-col-avg this-payoff-A-matrix this-payoff-B-matrix
      
      set green-v-red-index-list lput payoff-matrix-list-index green-v-red-index-list
      ; increment index
      set payoff-matrix-list-index payoff-matrix-list-index + 1
    ] 
    
    ; create agents,first red then green
    let agent-index 0
    set i 0
    
    let agent-circle-delta round(360 / (num-green-agents + num-red-agents))
    let agent-circle-angle 0 
    let agent-circle-radius round( (max-pycor  - min-pycor) * 0.4)  ; for agent interaction display
    let center-x  round( (max-pxcor - min-pxcor) / 2)
    let center-y  round( (max-pycor - min-pycor) / 2)
    if num-red-agents > 0 
      [
        let used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
        
        let unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned
        let possibility-pool unused-possible-moves-pool
          create-red-agents num-red-agents [
            hide-turtle
            set id i
            set label id
            set top-x-list [ ]
            ifelse model = "Galla & Farmer 2012" [
              set my-alpha alpha
              set my-beta beta
            ] 
            [ ; else
              if model = "Thomas 2016" [
                set my-alpha alpha-red ;+ ( 0.001 * random-float 1.0 )
                set my-beta beta-red ;+ (0.05 * random-float 1.0)
              ]
            ]
            
            if investments? [
              set infrastructure-investments-list [ ] 
              let available-infrastructure-list [ ]
              ask  infrastructure-investments with [attack?] [
                set available-infrastructure-list lput self available-infrastructure-list
              ]
              set available-infrastructure-list shuffle available-infrastructure-list
              let infrastructure-enabled-x [ ]
              let done? false
              while [not done? and length available-infrastructure-list > 0] [
                ; pick an infrastructure investment at random
                let candidate first available-infrastructure-list
                set available-infrastructure-list but-first available-infrastructure-list
                set infrastructure-investments-list lput candidate infrastructure-investments-list
                set infrastructure-enabled-x remove-duplicates (sentence infrastructure-enabled-x ([possible-x-list] of candidate))
                ; if adding the infrastructure investment supports the required number of moves, then done
                if length infrastructure-enabled-x >= 3 * num-red-moves [set done? true ] 
                ; if not, add another infrastructure investment at random, unless there are no more available
              ]
              
              
              
              
              ;            let num-infrastructure-investments random (count infrastructure-investments with [attack?]) + 1
              ;            set infrastructure-investments-list [ ] 
              ;            ;set infrastructure-investments-list lput (one-of infrastructure-investments with [attack?]) infrastructure-investments-list
              ;            repeat num-infrastructure-investments [
              ;              let candidate (one-of infrastructure-investments with [attack?])
              ;              let safety 10
              ;              while [member? candidate infrastructure-investments and safety > 0] [
              ;                set candidate (one-of infrastructure-investments with [attack?])
              ;                set safety safety - 1
              ;              ]
              ;              if candidate !=  0 and (length infrastructure-investments-list = 0 or not member? candidate infrastructure-investments-list) [
              ;                set infrastructure-investments-list lput candidate infrastructure-investments-list
              ;              ]
              ;            ]
              
              ;            let num-capability-investments random (count capability-investments with [attack?]) + 1
              ;            set capability-investments-list [ ]
              ;            repeat num-capability-investments [
              ;              let candidate (one-of capability-investments with [attack?])
              ;              let safety 10
              ;              while [member? candidate capability-investments-list and safety > 0] [
              ;                set candidate (one-of capability-investments with [attack?])
              ;                set safety safety - 1
              ;              ]
              ;              if candidate !=  0 and (length capability-investments-list = 0 or not member? candidate capability-investments-list) [
              ;                set capability-investments-list lput candidate capability-investments-list
              ;              ]
              ;            ]
              
              set capability-investments-list [ ]
              let available-capability-list [ ]
              ask capability-investments with [attack?] [
                set available-capability-list lput self available-capability-list
              ]
              set available-capability-list shuffle available-capability-list
              let capability-enabled-x [ ]
              set done? false
              while [not done? and length available-capability-list > 0] [
                ; pick an infrastructure investment at random
                let candidate first available-capability-list
                set available-capability-list but-first available-capability-list
                set capability-investments-list lput candidate capability-investments-list
                ;set capability-enabled-x remove-duplicates (sentence capability-investments-list ([possible-x-list] of candidate))
                ; if adding the infrastructure investment supports the required number of moves, then done
                set investment-enabled-x-list get-enabled-x infrastructure-investments-list capability-investments-list
                if length investment-enabled-x-list >= 1.2 * num-red-moves [set done? true ] 
                ;if length capability-enabled-x >= 2 * num-red-moves [set done? true ] 
                ; if not, add another infrastructure investment at random, unless there are no more available
              ]
              
              set investment-enabled-x-list get-enabled-x infrastructure-investments-list capability-investments-list
              ;show investment-enabled-x-list
              ;user-message (sentence self "investment-enabled-x-list len = " length investment-enabled-x-list)
              set possibility-pool investment-enabled-x-list
            ]
            
            set payoff-history [ ]
            set avg-payoff 0
            set sd-payoff 0
            
            set best-performing-agent? false 
            
            set history-x-list [ ]
            set unique-history-x-list [ ]
            set opponent-move-list [ ]
               
            let j 0
            set visibility-list [ ]   
            set num-blind-spots 0
            set blind-spots-array 0
            if uncertainty? [
              set blind-spots-array array:from-list n-values 400 [1]
              let potential-blind-spots shuffle n-values 400 [?]
              repeat round (( red-blind-spots / 100 ) * 400) [
                array:set blind-spots-array (item j potential-blind-spots) 0
                set j j + 1
              ]
              set num-blind-spots round (( red-blind-spots / 100 ) * 400)
            ]
            
            
            set normal-agent-color red - 3
            set highlight-agent-color red
            set color normal-agent-color
            set size 30
            set shape "face neutral"
            let this-x 0
            let this-y 0
            
            ask patch center-x center-y [
              ask patch-at-heading-and-distance agent-circle-angle agent-circle-radius 
              [ 
                set this-x pxcor 
                set this-y pycor
              ]
            ]
            set xcor this-x
            set ycor this-y
            set agent-circle-angle  agent-circle-angle + agent-circle-delta
            set N num-possible-moves
            set num-possible-x num-possible-moves
            if model = "Thomas 2016" [
              set num-possible-x num-red-moves
              set N num-red-moves
            ] 
            
            ;set initial-pr-x 1 / num-possible-x
            ;show possibility-pool
            ;user-message (sentence self "possibility-pool len = " length possibility-pool)
            let this-unused-pool remove -1 map [ifelse-value (member? ? possibility-pool) [?] [-1] ] unused-possible-moves-pool
            let this-used-pool remove -1 map [ifelse-value (member? ? possibility-pool) [?] [-1] ] used-possible-moves-pool
            ;show this-unused-pool
            ;user-message (sentence self "Unused pool len = " length this-unused-pool "\nUsed pool len = " length this-used-pool)
            
            let result random-draw-x-list possibility-pool this-unused-pool this-used-pool red-diversity num-red-moves
            
            set possible-x-list item 0 result
            set unused-possible-moves-pool (sentence unused-possible-moves-pool item 1 result)
            set unused-possible-moves-pool remove-duplicates unused-possible-moves-pool
            
            set used-possible-moves-pool (sentence item 2 result used-possible-moves-pool)
            set used-possible-moves-pool remove-duplicates used-possible-moves-pool
            set red-num-moves-list lput (length possible-x-list) red-num-moves-list
            set initial-pr-x 1 / (length possible-x-list)
            
            ;; DEPRECIATED -replaced by function: "random-draw-x-list"
            
            ;          set possible-x-list  [ ];; list of index numbers of possible moves for each player.  Ranges between 0 and 399
            ;          let j 0
            ;          let num-draw-previously-used round((1 - red-diversity) * N )
            ;          
            ;          ifelse length used-possible-moves-pool > 0 [
            ;            let my-used-pool shuffle used-possible-moves-pool ;; copy this so it can be mutated in the following repeat loop
            ;            repeat N [
            ;
            ;              let this-move -1
            ;              ifelse num-draw-previously-used > 0 and length my-used-pool > 0 [ ;; draw from previously used possibilities
            ;                  set this-move first my-used-pool
            ;                  set my-used-pool but-first my-used-pool
            ;                  set num-draw-previously-used num-draw-previously-used - 1
            ;              ] ; end if
            ;              [ ; else select from unused possibilities
            ;                set this-move first unused-possible-moves-pool
            ;                set used-possible-moves-pool lput this-move used-possible-moves-pool
            ;                set unused-possible-moves-pool but-first unused-possible-moves-pool
            ;                if length unused-possible-moves-pool = 0 [
            ;                  set unused-possible-moves-pool shuffle( n-values max-moves [?] )
            ;                ]
            ;              ]
            ;              set possible-x-list lput this-move possible-x-list
            ;              ; matrix:set pr-x-matrix id this-move initial-pr-x ; now done in foreach
            ;              set j j + 1
            ;            ]  ; end repeat
            ;          ] ; end if
            ;          [ ; else : length used-possible-moves-pool <= 0
            ;            ;         select from unused-possible-moves-pool to initialize the list of used-possible-moves-pool
            ;            set j 0
            ;            let this-move -1
            ;            repeat N [ 
            ;              set this-move first unused-possible-moves-pool
            ;              set used-possible-moves-pool lput this-move used-possible-moves-pool
            ;              set unused-possible-moves-pool but-first unused-possible-moves-pool
            ;              if length unused-possible-moves-pool = 0 [
            ;                set unused-possible-moves-pool shuffle( n-values max-moves [?] )
            ;              ]
            ;              
            ;              set possible-x-list lput this-move possible-x-list
            ;              ; matrix:set pr-x-matrix id this-move initial-pr-x ; now done in foreach
            ;              set j j + 1
            ;            ]
            ;            
            ;            
            ;          ] ; end else
            ; end DEPRECIATED
            
            let total 0
            foreach possible-x-list [
              let this-value initial-pr-x
              if random-initial-pr-x? [
                with-local-randomness [
                  ;random-seed sim-seed
                  set this-value max (list 0.0001 (random-normal initial-pr-x (initial-pr-x )) )
                ]
                set total total + this-value
              ]
              matrix:set pr-x-matrix id ? this-value
            ]
            if random-initial-pr-x? [
              let adjustment 1 / total
              foreach possible-x-list [
                matrix:set pr-x-matrix id ? (matrix:get pr-x-matrix id ?) * adjustment
              ]
            ]
            set possible-x-list sort possible-x-list
            set current-x choose-x
            set Q-array array:from-list n-values max-moves [0]
            
            let initial-Q 0
            if random-initial-pr-x? [
              set initial-Q max (list 0 (random-normal 20 16))
              set j 0
              repeat max-moves [
                array:set Q-array j initial-Q
                set j j + 1
              ]
            ]  
            
            set game-list [ ] 
            set game-weight-list [ ]
            set agent-list lput  self agent-list
            
            set i i + 1
          ]

      ]
    if num-green-agents > 0 
      [
        let used-possible-moves-pool [ ]                                ;; this will hold the moves that are already assigned as possible-x to some agents of same color
        let unused-possible-moves-pool shuffle( n-values max-moves [?] ) ;; this will hold possible moves that are not already assigned
        let possibility-pool unused-possible-moves-pool
          create-green-agents num-green-agents 
          [
            hide-turtle
            set id i
            set label id
            set top-x-list [ ]
            ifelse model = "Galla & Farmer 2012" [
              set my-alpha alpha
              set my-beta beta
            ] 
            [ ; else
              if model = "Thomas 2016" [
                set my-alpha alpha-green
                set my-beta beta-green
              ]
            ]
            set payoff-history [ ]
            set avg-payoff 0
            set sd-payoff 0
            
            set best-performing-agent? false 
            
            set history-x-list [ ]
            set unique-history-x-list [ ]
            set opponent-move-list [ ]
             
            set visibility-list [ ]  
            let j 0
            set num-blind-spots 0
            set blind-spots-array 0
            if  uncertainty? [
              set blind-spots-array array:from-list n-values 400 [1]
              let potential-blind-spots shuffle n-values 400 [?]
              repeat round (( green-blind-spots / 100 ) * 400) [
                array:set blind-spots-array (item j potential-blind-spots) 0
                set j j + 1
              ]
              set num-blind-spots round (( green-blind-spots / 100 ) * 400)
            ]
            
            set normal-agent-color green - 3
            set highlight-agent-color green
            set color normal-agent-color
            
            set size 30
            set shape "face neutral"
            
            set N num-possible-moves
            set num-possible-x num-possible-moves
            if model = "Thomas 2016" [
              set num-possible-x num-green-moves
              set N num-green-moves
            ] 
            ;set initial-pr-x 1 / num-possible-x
            let this-x 0
            let this-y 0
            
            
            ask patch center-x center-y [
              ask patch-at-heading-and-distance agent-circle-angle agent-circle-radius 
              [ 
                set this-x pxcor 
                set this-y pycor
              ]
            ]
            set xcor this-x
            set ycor this-y
            
            set agent-circle-angle  agent-circle-angle + agent-circle-delta
            ; OLD set pr-x-list [ ]
            
            if investments? [
              set infrastructure-investments-list [ ] 
              let available-infrastructure-list [ ]
              ask  infrastructure-investments with [defense?] [
                set available-infrastructure-list lput self available-infrastructure-list
              ]
              set available-infrastructure-list shuffle available-infrastructure-list
              let infrastructure-enabled-x [ ]
              let done? false
              while [not done? and length available-infrastructure-list > 0] [
                ; pick an infrastructure investment at random
                let candidate first available-infrastructure-list
                set available-infrastructure-list but-first available-infrastructure-list
                set infrastructure-investments-list lput candidate infrastructure-investments-list
                set infrastructure-enabled-x remove-duplicates (sentence infrastructure-enabled-x ([possible-x-list] of candidate))
                ; if adding the infrastructure investment supports the required number of moves, then done
                if length infrastructure-enabled-x >= 2 * num-green-moves [set done? true ] 
                ; if not, add another infrastructure investment at random, unless there are no more available
              ]
              set capability-investments-list [ ]
              let available-capability-list [ ]
              ask capability-investments with [defense?] [
                set available-capability-list lput self available-capability-list
              ]
              set available-capability-list shuffle available-capability-list
              let capability-enabled-x [ ]
              set done? false
              while [not done? and length available-capability-list > 0] [
                ; pick an infrastructure investment at random
                let candidate first available-capability-list
                set available-capability-list but-first available-capability-list
                set capability-investments-list lput candidate capability-investments-list
                ; set capability-enabled-x remove-duplicates (sentence capability-enabled-x ([possible-x-list] of candidate))
                ; if adding the infrastructure investment supports the required number of moves, then done
                set investment-enabled-x-list get-enabled-x infrastructure-investments-list capability-investments-list
                ;show length investment-enabled-x-list
                if length investment-enabled-x-list >= 1.2 * num-green-moves [set done? true ] 
                ; if length capability-enabled-x >= 2 * num-green-moves [set done? true ] 
                ; if not, add another infrastructure investment at random, unless there are no more available
              ]
              set investment-enabled-x-list get-enabled-x infrastructure-investments-list capability-investments-list
              set possibility-pool investment-enabled-x-list
            ] ; end  if investments?
            
            set possible-x-list [ ] ;; list of index numbers of possible moves for each player.  Ranges between 0 and 399
            let possible-moves shuffle( n-values max-moves [?] )
            
            let this-unused-pool remove -1 map [ifelse-value (member? ? possibility-pool) [?] [-1] ] unused-possible-moves-pool
            let this-used-pool remove -1 map [ifelse-value (member? ? possibility-pool) [?] [-1] ] used-possible-moves-pool
            ;user-message (sentence self "Unused pool len = " length this-unused-pool "Used pool len = " length this-used-pool)
            let result random-draw-x-list possibility-pool this-unused-pool this-used-pool green-diversity num-green-moves
            
            set possible-x-list item 0 result
            ;show possible-x-list
            ;user-message (sentence "possible-x-list length = " (length possible-x-list) "\ncontinue?")
            set unused-possible-moves-pool (sentence unused-possible-moves-pool item 1 result)
            set unused-possible-moves-pool remove-duplicates unused-possible-moves-pool
            
            set used-possible-moves-pool (sentence item 2 result used-possible-moves-pool)
            set used-possible-moves-pool remove-duplicates used-possible-moves-pool
            set green-num-moves-list lput (length possible-x-list) green-num-moves-list
            
            
            set initial-pr-x 1 / (length possible-x-list)
            
            ;; DEPRECIATED -- replaced by a function: "random-draw-x-list"
            ;          let j 0
            ;          let num-draw-previously-used round((1 - green-diversity) * N )
            
            ;          ifelse length used-possible-moves-pool > 0 [
            ;            let my-used-pool shuffle used-possible-moves-pool ;; copy this so it can be mutated in the following repeat loop
            ;            repeat N [
            ;              ; set pr-x-list lput initial-pr-x pr-x-list
            ;              ;let this-move item j possible-moves
            ;              let this-move -1
            ;              ifelse num-draw-previously-used > 0 and length my-used-pool > 0 [ ;; draw from previously used possibilities
            ;                  set this-move first my-used-pool
            ;                  set my-used-pool but-first my-used-pool
            ;                  set num-draw-previously-used num-draw-previously-used - 1
            ;              ] ; end if
            ;              [ ; else select from unused possibilities
            ;                set this-move first unused-possible-moves-pool
            ;                set used-possible-moves-pool lput this-move used-possible-moves-pool
            ;                set unused-possible-moves-pool but-first unused-possible-moves-pool
            ;                if length unused-possible-moves-pool = 0 [
            ;                  set unused-possible-moves-pool shuffle( n-values max-moves [?] )
            ;                ]
            ;              ]
            ;              set possible-x-list lput this-move possible-x-list
            ;              matrix:set pr-x-matrix id this-move initial-pr-x
            ;              set j j + 1
            ;            ]  ; end repeat
            ;          ] ; end if
            ;          [ ; else : length used-possible-moves-pool <= 0
            ;            ;         select from unused-possible-moves-pool to initialize the list of used-possible-moves-pool
            ;            set j 0
            ;            ;let original-unused-possible-moves-pool unused-possible-moves-pool ;; to restore each iteration
            ;            let this-move -1
            ;            repeat N [ 
            ;              set this-move first unused-possible-moves-pool
            ;              set used-possible-moves-pool lput this-move used-possible-moves-pool
            ;              set unused-possible-moves-pool but-first unused-possible-moves-pool
            ;              if length unused-possible-moves-pool = 0 [
            ;                set unused-possible-moves-pool shuffle( n-values max-moves [?] )
            ;              ]            
            ;              set possible-x-list lput this-move possible-x-list
            ;              matrix:set pr-x-matrix id this-move initial-pr-x
            ;              set j j + 1
            ;            ]           
            ;          ] ; end else
            ;;  end DEPRECIATED
            
            let total 0
            foreach possible-x-list [
              let this-value initial-pr-x
              if random-initial-pr-x? [
                set this-value max (list 0.0001 (random-normal initial-pr-x (initial-pr-x)))
                set total total + this-value
              ]
              ;user-message (sentence "this-value = " this-value)
              matrix:set pr-x-matrix id ? this-value
            ]
            if random-initial-pr-x? [
              let adjustment 1 / total
              ;user-message (sentence "Adjustment = " adjustment)
              
              foreach possible-x-list [
                matrix:set pr-x-matrix id ? (matrix:get pr-x-matrix id ?) * adjustment
              ]
            ]
            set possible-x-list sort possible-x-list
            set current-x choose-x
            set Q-array array:from-list n-values max-moves [0]
            let initial-Q 0
            if random-initial-pr-x? [
              with-local-randomness [
                set initial-Q max (list 0 (random-normal 20 16))
              ]
              set j 0
              repeat max-moves [
                array:set Q-array j initial-Q
                set j j + 1
              ]
            ]
            
            set agent-list lput  self agent-list
            
            set game-list [ ]
            set game-weight-list [ ]
            
            set i i + 1
            
          ] ; end else  
      ] ; end if num-green-agents > 0
    
    ;; setup the games by assigning agents and matrix indices to each game
    let row-agent-index 0
    let col-agent-index 0
    let green-v-green-index random length green-v-green-index-list  ;0
    let green-v-red-index random length green-v-red-index-list   ;0
    
    let green-agent-list [ ]
    ask green-agents [
      set green-agent-list lput self green-agent-list
    ]
    
    let done false 
    let game-index 0
    create-games num-games [
      hide-turtle
      let row-safety-count num-green-agents
      let done-with-row-agent false
      while [not done-with-row-agent and row-safety-count > 0] [
        ;; assign a row-agent, which is always green
        set row-agent item row-agent-index green-agent-list
        set col-agent item col-agent-index agent-list
        ;print (sentence "Proposed:" row-agent-index row-agent col-agent-index col-agent)
        let safety-count length agent-list
        let already-connected false
        let alter col-agent
        ask row-agent [
          set already-connected link-neighbor? alter
        ]
        while [ (already-connected  or row-agent = col-agent) and safety-count > 0] [
          ifelse already-connected [
            ;print (sentence "already connected... finding another agent")
          ] [
          ;print (sentence "Self-game... finding another agent")
          ]
          ;; increment the indices, and reset if necessary
          set col-agent-index col-agent-index + 1
          if col-agent-index >= length agent-list [
            set col-agent-index 0
          ]
          set col-agent item col-agent-index agent-list
          ;print (sentence "New:" col-agent-index col-agent)
          
          set alter col-agent
          ask row-agent [
            set already-connected link-neighbor? alter
          ]
          set safety-count safety-count - 1
        ] ; end while  (already-connected  or row-agent = col-agent)
        
        ifelse safety-count = 0   ;; the alternatives were exhausted (i.e. already connected)
          [
            set col-agent-index 0
            set row-agent-index row-agent-index + 1
            if row-agent-index >= num-green-agents [
              print (sentence "ERROR in assigning agents to games. Ran out of green-agents.")
              set row-agent-index 0 ;; this shouldn't happen.  Should finish instead
            ]
          ] 
          [
            set done-with-row-agent true
          ]
        set row-safety-count row-safety-count - 1
      ] ; end while not done-with-row-agent
      
      set current-row-move [current-x] of row-agent
      set current-col-move [current-x] of col-agent
      
      ask row-agent [
        set game-list lput myself game-list
      ]
      
      ask col-agent [
        set game-list lput myself game-list
      ]
      
      
      ;; assign the appropriate payoff-matrix, either green-v-green or green-v-red, using round-robin
      let g-v-g? false
      
      ifelse is-green-agent? row-agent and is-green-agent? col-agent [
        set payoff-matrix-index item green-v-green-index green-v-green-index-list
        set green-v-green-index random length green-v-green-index-list
        
        ;set green-v-green-index green-v-green-index + 1
        ;if green-v-green-index >= length green-v-green-index-list [
        ;  set green-v-green-index 0
        ;]
        
        set g-v-g? true
      ]
      [  ;; else, assign a green v red matrix, and increment the index
        set payoff-matrix-index item green-v-red-index green-v-red-index-list
        set green-v-red-index random length green-v-red-index-list
        
        ;set green-v-red-index green-v-red-index + 1
        ;if green-v-red-index >= length green-v-red-index-list [
        ;  set green-v-red-index 0
        ;]
        
      ]
      
      let alter-agent col-agent
      ask row-agent [
        if self != alter-agent [
          create-link-with alter-agent [
            hide-link
            ifelse g-v-g? [
              set normal-color 2
              set highlight-color green
              set color normal-color
            ] 
            [
              set normal-color red - 3
              set highlight-color red
              set color normal-color
            ]
          ]
        ]
      ]
      
      ;; increment the agent indices, and reset if necessary
      set col-agent-index col-agent-index + 1
      if col-agent-index >= length agent-list [
        set col-agent-index 0
        set row-agent-index row-agent-index + 1
        if row-agent-index >= num-green-agents [
          print (sentence "ERROR in assigning agents to games. Ran out of green-agents. (#2)")
          set row-agent-index 0 ;; this shouldn't happen.  Should finish instead
        ]
      ]
      ;print (sentence "game # " game-index "Selected:" row-agent col-agent)
      ;print (sentence "new row = " row-agent-index "; new col = " col-agent-index )
      
      set id game-index
      set game-index game-index + 1
      
    ] ;; end create-games
    
    foreach agent-list [
      ask ? [
        let num-my-games length game-list
        let this-weight 1 / num-my-games
        let weight-sum 0
        repeat num-my-games [
          if random-initial-game-weights 
          [
            set this-weight random-float 1.0
          ]
          set game-weight-list lput this-weight  game-weight-list
          set weight-sum weight-sum + this-weight     
        ]
        if random-initial-game-weights 
        [
          let new-game-weight-list [ ]
          foreach game-weight-list [
            set new-game-weight-list lput (? / weight-sum) new-game-weight-list
          ]
        ]
      ]
    ]
    
    
    
    ;set focal-agent-A item 0 agent-list
    ;set focal-agent-B item 1 agent-list
    
    
    set focal-game  one-of games with [id = 0]
    set currently-displayed-game [id] of focal-game
    set game-num [id] of focal-game
    set focal-agent-A [row-agent] of focal-game
    set focal-agent-B [col-agent] of focal-game
    
    let type-A "green"
    let type-B "green"
    
    if is-red-agent? focal-agent-A [
      set type-A "red"
      
    
    ]
    if is-red-agent? focal-agent-B [
      set type-B "red"
    ]


    if model = "Thomas 2016" [
      set N length [possible-x-list] of focal-agent-A
      set move-IDs-A (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
      set N length [possible-x-list] of focal-agent-B
      set move-IDs-B (word (word round(N / 10)) "\n" (word round(N / 5)) "\n"  (word round(N / 4)) "\n" (word round(N / 2)) )
    ]

    set move-IDs-A-list  read-from-string (word "[" (replace-newlines move-IDs-A " ") "]")
    set move-IDs-B-list  read-from-string (word "[" (replace-newlines move-IDs-B " ") "]")
    

    let this-x convert-pxcor [current-x] of focal-agent-A
    let this-y convert-pycor [current-x] of focal-agent-B
    ask patch this-x this-y [
      sprout-highlights 1 [
        set size 18
        set color [pcolor] of patch-here
        set shape "square 3"
        set previous-x  this-x 
        set previous-y this-y
        set current-x  this-x 
        set current-y this-y
        set payoff-highlight self
      ]
    ]
    let pointer-x (payoff-display-margin - 8 - border)
    let pointer-y this-y
    ask patch pointer-x pointer-y [
      sprout-pointers 1 [
        set size 15
        set color 55
        set pointer-row self
        facexy (pointer-x + 1) pointer-y 
        
      ]
    ]
    set pointer-x this-x
    set pointer-y (payoff-display-margin - 8 - border)
    ask patch pointer-x pointer-y [
      sprout-pointers 1 [
        set size 15
        set color 15
        set pointer-col self
        facexy pointer-x (pointer-y + 1)
        
      ]
    ]
    set-current-plot "Moving Average Mean Payoffs"
    ask red-agents [
      create-temporary-plot-pen (word "red" id)
      set-current-plot-pen (word "red" id)
      set-plot-pen-color 12 + (id mod 6)
    ]
     ask green-agents [
      create-temporary-plot-pen (word "green" id)
      set-current-plot-pen (word "green" id)
      set-plot-pen-color 52 + (id mod 6)
    ]
     
    set-current-plot "Moving Average SD Payoffs"
    ask red-agents [
      create-temporary-plot-pen (word "red" id)
      set-current-plot-pen (word "red" id)
      set-plot-pen-color 12 + (id mod 6)
    ]
     ask green-agents [
      create-temporary-plot-pen (word "green" id)
      set-current-plot-pen (word "green" id)
      set-plot-pen-color 52 + (id mod 6)
    ]
    

    set currently-displayed-game -1
    update-game-display
    
    if display-mode = "2-agent payoff matrix" [
      draw-payoff-display
    ]

    ;; setup the display of agent move probabilities (pr-x-list)
    foreach agent-list [
      let this-agent ?
      let start-x max-pxcor - right-display-margin + border + (([id] of this-agent) * pr-x-display-width)
      let end-x start-x + pr-x-display-width
      let y payoff-display-margin 
      ;show  highlight-agent-color
      ;let color-offset (id mod 2) * 10
      set i 0 ; iterates through rows
      repeat max-moves [
        ;let pr (matrix:get pr-x-matrix id i)
        ;let h-color highlight-agent-color
        let j 0 ; iterates through columns
        repeat pr-x-display-width - 2 [
          if (start-x + j) > max-pxcor [
            show (sentence [id] of this-agent start-x j)
            user-message "error"
          ]
          ask patch (start-x + j) y [
            let is-possible? false
            ask this-agent[
              if member? i possible-x-list [
                set is-possible? true
              ]
            ]
            set display-pr-x? is-possible?
            set agent-pr-x this-agent
            set agent-pr-x-id [id] of this-agent
            set x-value i
            ;set pcolor  (pr  * 8.9) + (h-color + color-offset - 4)
          ]
          set j j + 1
        ]
        set i i + 1
        set y y + 1
      ]
      
    ]

    ;focal-agent-A
    let this-agent focal-agent-A
    let start-x payoff-display-margin - border
    let end-x payoff-display-margin - 1
    let y payoff-display-margin 
    ;show  highlight-agent-color
    ;let color-offset (id mod 2) * 10
    set i 0 ; iterates through rows
    repeat max-moves [
      let is-possible? false
      ask this-agent[
        if member? i possible-x-list [
          set is-possible? true
        ]
      ]
      let j 0 ; iterates through columns
      repeat pr-x-display-width  [
        ask patch (start-x + j) y [
          
          set display-pr-x? is-possible?
          set agent-pr-x this-agent
          set agent-pr-x-id [id] of this-agent
          set x-value i
          ;set pcolor  (pr  * 8.9) + (h-color + color-offset - 4)
        ]
        set j j + 1
      ]
      set i i + 1
      set y y + 1
    ]
    

    
    ;focal-agent-B
    set this-agent focal-agent-B
    let start-y payoff-display-margin - border
    let end-y payoff-display-margin - 1
    let x payoff-display-margin 
    ;show  highlight-agent-color
    ;let color-offset (id mod 2) * 10
    set i 0 ; iterates through rows
    repeat max-moves [
      let is-possible? false
      ask this-agent[
        if member? i possible-x-list [
          set is-possible? true
        ]
      ]
      let j 0 ; iterates through rows
      repeat pr-x-display-width  [
        ask patch x (start-y + j)  [
          set display-pr-x? is-possible?
          set agent-pr-x this-agent
          set agent-pr-x-id [id] of this-agent
          set x-value i
        ]
        set j j + 1
      ]
      set i i + 1
      set x x + 1
    ]

    if investments? [
      ask focal-agent-A [
        if length infrastructure-investments-list > 0 [
          set start-x 0
          foreach infrastructure-investments-list [
            let this-investment ?
            
            set end-x start-x + pr-x-display-width
            set y payoff-display-margin 
            
            set i 0 ; iterates through rows
            repeat max-moves [
              let is-possible? member? i [possible-x-list] of this-investment
              let j 0 ; iterates through columns
              repeat pr-x-display-width  [
                ask patch (start-x + j) y [                 
                  set display-investment-x? true; is-possible?
                  set agent-pr-x myself
                  set agent-pr-x-id [id] of myself
                  if is-possible? [set investment-list lput this-investment investment-list]
                  set x-value i
                  
                ]
                set j j + 1
              ] ;end repeat pr-x-display-width
              set i i + 1
              set y y + 1
            ] ; end repeat
            set start-x start-x ;+ 2
          ] ;end foreach infrastructure-investments-list
          
        ] ; end if length infrastructure-investments-list > 0
        
        if length capability-investments-list > 0 [
         set start-x pr-x-display-width + border
          foreach capability-investments-list [
            let this-investment ?
            
            set end-x start-x + pr-x-display-width
            set y payoff-display-margin
            
            set i 0 ; iterates through rows
            repeat max-moves [
              let is-possible? member? i [possible-x-list] of this-investment
              let j 0 ; iterates through columns
              repeat pr-x-display-width  [
                ask patch (start-x + j) y [                 
                  set display-investment-x? true; is-possible?
                  set agent-pr-x myself
                  set agent-pr-x-id [id] of myself
                  if is-possible? [set investment-list lput this-investment investment-list]
                  set x-value i
                  
                ]
                set j j + 1
              ] ;end repeat pr-x-display-width
              set i i + 1
              set y y + 1
            ] ; end repeat
            set start-x start-x ;+ 2
          ] ;end foreach capability-investments-list
          
        ] ; end if length capability-investments-list > 0

      ] ; end ask focal-agent-A
      
      
      ask focal-agent-B [
        if length infrastructure-investments-list > 0 [
          set start-y  0
          foreach infrastructure-investments-list [
            let this-investment ?
            
            set end-y start-y + pr-x-display-width
            set x payoff-display-margin 
            
            set i 0 ; iterates through rows
            repeat max-moves [
              let is-possible? member? i [possible-x-list] of this-investment
              let j 0 ; iterates through columns
              repeat pr-x-display-width  [
                ask patch  x (start-y + j) [                 
                  set display-investment-x? true ; is-possible?
                  set agent-pr-x myself
                  set agent-pr-x-id [id] of myself
                  if is-possible? [set investment-list lput this-investment investment-list]
                  set x-value i
                  
                ]
                set j j + 1
              ] ;end repeat pr-x-display-width
              set i i + 1
              set x x + 1
            ] ; end repeat
            set start-y start-y ;+ 2
          ] ;end foreach infrastructure-investments-list
          
        ] ; end if length infrastructure-investments-list > 0
        
        if length capability-investments-list > 0 [
          set start-y pr-x-display-width + border
          foreach capability-investments-list [
            let this-investment ?
            
            set end-y start-y + pr-x-display-width
            set x payoff-display-margin 
            
            set i 0 ; iterates through rows
            repeat max-moves [
              let is-possible? member? i [possible-x-list] of this-investment
              let j 0 ; iterates through columns
              repeat pr-x-display-width  [
                ask patch x (start-y + j) [                 
                  set display-investment-x? true; is-possible?
                  set agent-pr-x myself
                  set agent-pr-x-id [id] of myself
                  if is-possible? [set investment-list lput this-investment investment-list]
                  set x-value i
                  
                ]
                set j j + 1
              ] ;end repeat pr-x-display-width
              set i i + 1
              set x x + 1
            ] ; end repeat
            set start-x start-x ;+ 2
          ] ;end foreach capability-investments-list
          
        ] ; end if length capability-investments-list > 0
      ] ; end ask focal-agent-A
    ] ; end if investments?
    
     ask patches [
       ifelse display-pr-x? [
         display-pr-x-values
       ]
       [
         if display-investment-x? [
           display-investment-x-values
         ]
       ]
     ]
     
;     ask patches with [pxcor >  (max-pxcor - right-display-margin + border) and pycor >= payoff-display-margin ]
;    [
;       display-pr-x-values
;     ]
;    
;     ; focal-agent-A
;     ask patches with [pxcor >  payoff-display-margin - border and pxcor <  payoff-display-margin - 1 and pycor >= payoff-display-margin] 
;     [ 
;       display-pr-x-values
;     ]
;     
;     ; focal-agent-A investments
;     ask patches with [pxcor >=  0 and pxcor <  (payoff-display-margin - 8 - border) and pycor >= payoff-display-margin ] 
;     [ 
;       display-investment-x-values
;     ]
;     
;     ; focal-agent-B
;     ask patches with [pycor >  payoff-display-margin - border and pycor <  payoff-display-margin - 1 and pxcor >= payoff-display-margin and pxcor < payoff-display-margin + max-moves] 
;     [ 
;       display-pr-x-values
;     ]
;     
;     ; focal-agent-B investments
;     ask patches with [pxcor >= payoff-display-margin and pxcor < payoff-display-margin + max-moves and pycor >=  0 and pycor <  payoff-display-margin - border ] 
;     [ 
;       display-investment-x-values
;     ]
    ask highlights [
      set color pcolor
    ]
    clear-output
    ifelse investments? [
      ask green-agents [
        let i-ids [ ]
        foreach infrastructure-investments-list [
          ask ? [
            set i-ids lput id i-ids
          ]
        ]
        
        let c-ids [ ]
        foreach capability-investments-list [
          ask ? [
            set c-ids lput id c-ids
          ]
        ]
        output-print (sentence (word "G" id ":") i-ids ";" c-ids)
      ]
      output-print ""
      ask red-agents [
        let i-ids [ ]
        foreach infrastructure-investments-list [
          ask ? [
            set i-ids lput id i-ids
          ]
        ]
        
        let c-ids [ ]
        foreach capability-investments-list [
          ask ? [
            set c-ids lput id c-ids
          ]
        ]
        output-print (sentence (word "R" id ":") i-ids ";" c-ids)
      ]
    ]  ; if investments?
    [
      foreach agent-list [
        ask ? [
          set investment-enabled-x-list n-values 400 [?]
        ]
        
      ]
    ]
    set green-num-moves-list [ ]
    set avg-green-blind-spots 0
    ask green-agents[
      if uncertainty? [update-blind-spots]
      set green-num-moves-list lput (length possible-x-list) green-num-moves-list
      set avg-green-blind-spots avg-green-blind-spots + num-blind-spots
      set opponent-move-list [ ]
    ]
    set avg-green-blind-spots  avg-green-blind-spots / num-green-agents
    set red-num-moves-list [ ]
    set avg-red-blind-spots 0
    ask red-agents[
      if uncertainty? [update-blind-spots]
      set red-num-moves-list lput (length possible-x-list) red-num-moves-list
      set avg-red-blind-spots avg-red-blind-spots +  num-blind-spots
      set opponent-move-list [ ]
    ]
    if num-red-agents > 0 [
      set avg-red-blind-spots avg-red-blind-spots / num-red-agents
    ]
    set green-best-practices? false
    set red-best-practices? false
    
    ;update ;; switch to other display if that option is set
    plot-payoff-distributions
    set request-redraw-payoff-display? false
  ] ;; end with-local-randomness
  
end

;;#######################################################################################################
;;#######################################################################################################
;;                                  GO
;;#######################################################################################################
;;#######################################################################################################



to go
  set move-IDs-A-list  read-from-string (word "[" (replace-newlines move-IDs-A " ") "]")
  set move-IDs-B-list  read-from-string (word "[" (replace-newlines move-IDs-B " ") "]")
  
  
  ;; first, all agents choose their move (aka "x")
  foreach agent-list[
    ask ? [
      set trigger-novelty? false
      set current-payoff 0
      set current-x choose-x
      set history-x-list lput current-x history-x-list
      if not member? current-x unique-history-x-list [
        set unique-history-x-list lput current-x unique-history-x-list
        set trigger-novelty? true
      ]
    ]
  ]  
  
  ;; next, play all the games and update all agent's payoffs
  ask games [
    play-game  ;; the game object polls it's agents for moves, then updates them the agents with their respective payoffs, and informs each agent of the opponent's move in case of g-v-r
    
  ]
  
  let reset-period-payoff false
  if (ticks - 1) mod period = 0 and ticks > 0 [
    set reset-period-payoff true
  ]
  foreach agent-list[
    ask ? [
      
      if length payoff-history >= period [
        set payoff-history but-first payoff-history  ;; remove the first (oldest) payoff from the list
      ]
      set payoff-history lput current-payoff payoff-history  ;; add current payoff to the end of the list
      set avg-payoff mean payoff-history
      if length payoff-history > 1 [set sd-payoff standard-deviation payoff-history]
      
      ;let pr-x-alters [ ]
      let opponents [ ]
      foreach game-list [  ;; SPEED IDEA -- use global M X N array for pr-X instead of lists in each agent.  Would eliminate all this list copying!!
        ask ? [
          ;set pr-x-alters lput (get-opponent-pr-x-list myself)   pr-x-alters
          set opponents lput get-opponent myself opponents ;; returns id of opponent, for indexing into the pr-x-matrix
        ]
      ]
      
      ;; add new possible-x if trigger-novelty? = true and ticks >= start-novelty-at
      if novelty? and trigger-novelty? and ticks >= start-novelty-at and length possible-x-list < 400 [
        if random-float 1.0 <= pr-novelty [
          let candidate-x-list remove false map [ifelse-value (not member? ? possible-x-list) [?] [false] ]  investment-enabled-x-list  ;; return only those enabled x values that are not already in use as possibilities
          if length candidate-x-list > 0 [
            let novel-count 0
            ifelse is-green-agent? ? [
              set novel-count min (list green-novel-possibilities (length candidate-x-list))
            ]
            [
              set novel-count min (list red-novel-possibilities (length candidate-x-list))
            ]
            let novel-x-list n-of novel-count candidate-x-list
            add-new-possible-x novel-x-list
          ]
        ]
        set trigger-novelty? false
      ]
      
      ; update-attractions pr-x-alters  ;; SPEED IDEA -- THIS IS THE SLOWEST PROCEDURE, BY FAR!!!!  O(N * (N - 1) * M * M)
      ifelse is-green-agent? ? [
        if ticks mod gr-learning-cycle = 0 [
          update-attractions2 opponents 
        ]
      ] 
      [  ;; for red-agents update every cycle
         update-attractions2 opponents
      ]
    ]
  ]
  foreach agent-list[
    ask ? [   
      update-choice-probabilities     ;; SPEED IDEA -- NOT TOO SLOW:  O(N *  M)
      if reset-period-payoff [
        ; show "resetting period payoffs"
        set last-period-payoff (current-period-payoff / period)
        set current-period-payoff 0
      ]
      
      ;if ticks mod round(period / 5) = 0 [
      ;  display-pr-x-list
      ;]
    ] ; end ask agent
    
  ] ; end foreach agent-list
  
  let new-x convert-pxcor [current-x] of focal-agent-B
  let new-y convert-pycor [current-x] of focal-agent-A
  if display-mode = "2-agent payoff matrix" [
    clear-drawing ;; erase turtle previous lines
  ]
  ask pointer-row [
    setxy pxcor new-y
  ]
  ask pointer-col [
    setxy new-x pycor
  ]
  ask payoff-highlight [
    set previous-x pxcor 
    set previous-y pycor
    if display-mode = "2-agent payoff matrix" [
      hide-turtle
      set color white
      pen-down
    ]
    setxy new-x new-y
    set current-x new-x 
    set current-y new-y
    pen-up
    set color [pcolor] of patch-here
    show-turtle
  ]
  
  ask focal-agent-B [
    set focal-agent-B-avg-payoff avg-payoff
    set focal-agent-B-sd-payoff sd-payoff
  ]
  ask focal-agent-A [
    set focal-agent-A-avg-payoff avg-payoff
    set focal-agent-A-sd-payoff sd-payoff
  ]
  
  ask patches [
    ifelse display-pr-x? [
      display-pr-x-values
    ]
    [
      if display-investment-x? [
        display-investment-x-values
      ]
    ]
  ]
  if  request-redraw-payoff-display? [
    draw-payoff-display
  ]
  set green-num-moves-list [ ]
  set avg-green-blind-spots 0
  let avg-green-cum-payoff 0
  ask green-agents[
    set avg-green-cum-payoff avg-green-cum-payoff + cum-payoff
    update-blind-spots
    set green-num-moves-list lput (length possible-x-list) green-num-moves-list
    set avg-green-blind-spots avg-green-blind-spots + num-blind-spots
    set opponent-move-list [ ]
    set best-performing-agent? false ;; restore this
  ]
  set avg-green-cum-payoff avg-green-cum-payoff / num-green-agents
  set avg-green-blind-spots  avg-green-blind-spots / num-green-agents
  
  set green-best-practices? false
  if green-imitate-bp > 0 and num-green-agents > 1 [
    ask green-agents with [cum-payoff >= avg-green-cum-payoff * (1 + (leader-threshold-bp / 100))] [
      set green-best-practices? true
      set best-performing-agent? true
    ]
  ]
  
  set red-num-moves-list [ ]
  set avg-red-blind-spots 0
  let avg-red-cum-payoff 0
  ask red-agents[
    set avg-red-cum-payoff avg-red-cum-payoff + cum-payoff
    update-blind-spots
    set red-num-moves-list lput (length possible-x-list) red-num-moves-list
    set avg-red-blind-spots avg-red-blind-spots + num-blind-spots
    set opponent-move-list [ ]
    set best-performing-agent? false ;; restore this
  ]
  set red-best-practices? false
  if num-red-agents > 0 [
    set avg-red-cum-payoff avg-red-cum-payoff / num-red-agents
    set avg-red-blind-spots  avg-red-blind-spots / num-red-agents
    
    if red-imitate-bp > 0 and num-red-agents > 1 [
      ask red-agents with [cum-payoff >= avg-red-cum-payoff * (1 + (leader-threshold-bp / 100))] [
        set red-best-practices? true
        set best-performing-agent? true
      ]
    ]
  ]
  
  if green-best-practices? [
    let initial-value 0
    if bp-mode = "min all" [
      set initial-value 1
    ]
    let i 0
    repeat 400 [
      array:set green-best-practice-array i initial-value
      set i i + 1
    ]
    ask green-agents with [best-performing-agent? = true ] [
      set i 0
      repeat 400 [
        ifelse bp-mode = "avg all" [
          array:set green-best-practice-array i (array:item green-best-practice-array i) + (matrix:get pr-x-matrix ID i)
        ] 
        [
          ifelse bp-mode = "min all" [
            array:set green-best-practice-array i min (list (array:item green-best-practice-array i)  (matrix:get pr-x-matrix ID i) )
          ][
          if bp-mode = "max any" [
            array:set green-best-practice-array i max (list (array:item green-best-practice-array i)  (matrix:get pr-x-matrix ID i) )
          ]
          ]
        ]
        set i i + 1
      ]
    ]

    if bp-mode = "avg all" [
      ; normalize
      set i 0
      repeat 400 [
        array:set green-best-practice-array i (array:item green-best-practice-array i) / (count green-agents with [best-performing-agent? = true ])
        set i i + 1
      ]
    ]
  ]
  
  if red-best-practices? [
    
    let initial-value 0
    if bp-mode = "min all" [
      set initial-value 1
    ]
    let i 0
    repeat 400 [
      array:set red-best-practice-array i initial-value
      set i i + 1
    ]
    ask red-agents with [best-performing-agent? = true ] [
      set i 0
      repeat 400 [
        ifelse bp-mode = "avg all" [
          array:set red-best-practice-array i (array:item red-best-practice-array i) + (matrix:get pr-x-matrix ID i)
        ] 
        [
          ifelse bp-mode = "min all" [
            array:set red-best-practice-array i min (list (array:item red-best-practice-array i)  (matrix:get pr-x-matrix ID i) )
          ][
          if bp-mode = "max any" [
            array:set red-best-practice-array i max (list (array:item red-best-practice-array i)  (matrix:get pr-x-matrix ID i) )
          ]
          ]
        ]
        set i i + 1
      ]
    ]

    if bp-mode = "avg all" [
      ; normalize
      set i 0
      repeat 400 [
        array:set red-best-practice-array i (array:item red-best-practice-array i) / (count red-agents with [best-performing-agent? = true ])
        set i i + 1
      ]
    ]
  ]
  
  set request-redraw-payoff-display? false
  do-plots
  if ticks >= max-ticks [stop]
  tick
end

;; #####################################  END GO ################################################
;; ##############################################################################################

to-report random-draw-x-list [new-pool available-pool used-pool diversity N]
  ; new-pool is the pristine list of possible-x.  Either it's the full sequence of integers up to 399, or it's drawn from infrastructure + capability investments
  ; available-pool is updated each time, removing the x values that are used. This is ALREADY filtered to match new-pool, so I don't have to test membership
  ; used-pool is updated each time, adding new x values when they are used. This is ALREADY filtered to match new-pool, so I don't have to test membership
  
  let x-list  [ ];; list of index numbers of possible moves.  Ranges between 0 and 399
  let j 0
  let num-draw-previously-used round((1 - diversity) * N )
  set available-pool shuffle available-pool
  
  ifelse length used-pool > 0 [
    let my-used-pool shuffle used-pool ;; copy this so it can be mutated in the following repeat loop
    repeat N [
      let this-move -1
      ifelse num-draw-previously-used > 0 and length my-used-pool > 0 [ ;; draw from previously used possibilities   
        set this-move first my-used-pool
        set my-used-pool but-first my-used-pool
        set num-draw-previously-used num-draw-previously-used - 1
        
      ] ; end if
      [ ; else select from unused possibilities 
        set this-move first available-pool  
        set used-pool lput this-move used-pool
        set available-pool but-first available-pool
      ] ; end else
      if length available-pool = 0 [
        set available-pool shuffle( new-pool )
      ]
      set x-list lput this-move x-list
      set j j + 1
    ]  ; end repeat
  ] ; end if
  [ ; else : length used-possible-moves-pool <= 0
    ;         select from available-pool to initialize the list of used-possible-moves-pool
    ;set j 0
    let this-move -1
    repeat N [
      
        set this-move first available-pool
        
        set used-pool lput this-move used-pool
        set available-pool but-first available-pool
      
      if length available-pool = 0 [
        set available-pool shuffle( new-pool )
      ]
      
      set x-list lput this-move x-list
      ;set j j + 1
    ]
  ] ; end else
  set x-list remove-duplicates (sort x-list)
  report (list x-list available-pool used-pool)
end

to-report old-random-draw-x-list [new-pool available-pool used-pool diversity N]
  ; new-pool is the pristine list of possible-x.  Either it's the full sequence of integers up to 399, or it's drawn from infrastructure + capability investments
  ; available-pool is updated each time, removing the x values that are used
  ; used-pool is updated each time, adding new x values when they are used
  
  let x-list  [ ];; list of index numbers of possible moves.  Ranges between 0 and 399
  let j 0
  let num-draw-previously-used round((1 - diversity) * N )
  
  ifelse length used-pool > 0 [
    let my-used-pool shuffle used-pool ;; copy this so it can be mutated in the following repeat loop
    repeat N [
      
      let this-move -1
      ifelse num-draw-previously-used > 0 and length my-used-pool > 0 [ ;; draw from previously used possibilities
        let match? false
        let i -1
        while [not match? and i < (length my-used-pool - 1)] [
          set i i + 1
          set this-move item i my-used-pool
          if member? this-move new-pool [ 
            set match? true
            
            ]
        ]
        ifelse match? [
          set my-used-pool remove-item i my-used-pool
          set num-draw-previously-used num-draw-previously-used - 1
        ] [
           set num-draw-previously-used 0 ;; no match? means draw all from the available-pool
        ]
      ] ; end if
      [ ; else select from unused possibilities
        let match? false
        let i -1
        while [not match? and i < (length available-pool - 1)] [
          set i i + 1
          set this-move item i available-pool
          if member? this-move new-pool [ 
            set match? true
            
            ]
        ]
        if match? [
          set used-pool lput this-move used-pool
          set available-pool remove-item i available-pool
        ]
        if length available-pool = 0 [
          set available-pool shuffle( new-pool )
        ]
      ]
      set x-list lput this-move x-list
      set j j + 1
    ]  ; end repeat
  ] ; end if
  [ ; else : length used-possible-moves-pool <= 0
    ;         select from available-pool to initialize the list of used-possible-moves-pool
    set j 0
    let this-move -1
    repeat N [
      let match? false
      let i -1
      while [not match? and i < (length available-pool - 1)] [
        set i i + 1
        set this-move item i available-pool
        if member? this-move new-pool [ 
          set match? true
          
        ]
      ]
      if match? [
        set used-pool lput this-move used-pool
        set available-pool remove-item i available-pool
      ]
      if length available-pool = 0 [
        set available-pool shuffle( new-pool )
      ]
      
      set x-list lput this-move x-list
      set j j + 1
    ]
    
    
  ] ; end else
  set x-list sort x-list
  report (list x-list available-pool used-pool)
end

to-report get-enabled-x [i-list c-list]  ; reports a list of index numbers that are "enabled", i.e. common to both the infrastructure investments and capability investments
  let result [ ]
  ; combine the possible-x-lists from all infrastructure investments
  let possible-x-infrastructure [ ]
  foreach i-list [ 
    set possible-x-infrastructure (sentence possible-x-infrastructure [possible-x-list] of ?)
  ]
  
   set possible-x-infrastructure remove-duplicates possible-x-infrastructure
  
  ; combine the possible-x-lists from all capability investments
  let possible-x-capabilities [ ]
  foreach c-list [ 
    set possible-x-capabilities (sentence possible-x-capabilities [possible-x-list] of ?)
  ]
  
   set possible-x-capabilities remove-duplicates possible-x-capabilities
  
  ; report a list will all the index numbers that are in both
  foreach possible-x-capabilities[
    if member? ? possible-x-infrastructure [
      set result lput ? result
    ]
    
  ]
  
  set result sort result
  
  report result
  
end


;; DEPRECIATED!!!!
;; THIS IS ONLY USED IN "OPTIMIZED" ATTRACTION ALGORITHM
to calc-avg-row-and-col-avg [ row-payoff-matrix col-payoff-matrix]
      let this-row-avg array:from-list n-values num-possible-moves [0]
      let row-index 0
      repeat num-possible-moves[
        let this-avg 0
        let this-sum 0
        let col-index 0 
        repeat num-possible-moves [
          set this-sum this-sum + (matrix:get row-payoff-matrix row-index col-index  )     ; was  row-index  col-index, but that was reversed from 
          set col-index col-index + 1
        ]       
        array:set this-row-avg row-index (this-sum / num-possible-moves) 
        set row-index row-index + 1
      ]
      set payoff-row-matrix-avg-list lput this-row-avg payoff-row-matrix-avg-list
      
      let this-col-avg array:from-list n-values num-possible-moves [0]
      let col-index 0 
      repeat num-possible-moves[
        let this-avg 0
        let this-sum 0
        set row-index 0
        repeat num-possible-moves [
          set this-sum this-sum + (matrix:get col-payoff-matrix row-index col-index)                
          set row-index row-index + 1
        ]       
        array:set this-col-avg col-index  (this-sum / num-possible-moves) 
        set col-index col-index + 1
      ]
      set payoff-col-matrix-avg-list lput this-col-avg payoff-col-matrix-avg-list
  end



;; ##################################################################################

to-report calc-avg-row [r-num] ; diagnostic only
  let result 0
  ask patches with [pxcor >= payoff-display-margin and pxcor < (payoff-display-margin + max-moves) and pycor = (r-num + payoff-display-margin)]
  [
    set result result + item 1 payoff-list
  ]
  
  report result / num-possible-moves
  
end

to-report calc-avg-col [c-num] ; diagnostic only
  let result 0
  ask patches with [pycor >= payoff-display-margin and pycor < (payoff-display-margin + max-moves) and pxcor = (c-num + payoff-display-margin)]
  [
    set result result + item 0 payoff-list
  ]
  
  report result / num-possible-moves
  
end


;; ##################################################################################

to update-game-display
  
  ask links [
    set color normal-color
  ]
  
  ask green-agents [
    set color normal-agent-color
  ]
  
  ask red-agents [
    set color normal-agent-color
  ]
  
  ask focal-agent-A [
    set color highlight-agent-color
    ask my-links with [other-end = focal-agent-B] [
      set color highlight-color
    ]
  ]
  
  ask focal-agent-B [
    set color  highlight-agent-color
  ]
  
  
  ask patch 30 8 [
    set plabel [id] of focal-game
  ]
  
  if display-mode = "2-agent payoff matrix" [
    
    ask patch 20 40 [
      set plabel [id] of focal-agent-A
      ifelse is-green-agent? focal-agent-A [ 
        set plabel-color green
        ask pointer-row [
          set color green
        ]
        set-row-control-patches 51
      ] 
      [
        set plabel-color red
        ask pointer-row [
          set color red
        ]
        set-row-control-patches 11
      ]
    ]
    
    ask patch 47 25 [
      set plabel [id] of focal-agent-B
      ifelse is-green-agent? focal-agent-B [ 
        set plabel-color green
        ask pointer-col [
          set color green
        ]
        set-col-control-patches 51
      ] 
      [
        set plabel-color red
        ask pointer-col [
          set color red
        ]
        set-col-control-patches 11
      ]
    ]
    let new-x convert-pxcor [current-x] of focal-agent-B
    let new-y convert-pycor [current-x] of focal-agent-A
    
    ask pointer-row [
      setxy pxcor new-y
    ]
    ask pointer-col [
      setxy new-x pycor
    ]
    ask payoff-highlight [
      setxy new-x new-y
      set current-x new-x 
      set current-y new-y
      set color [pcolor] of patch-here
    ]
  ]
  
end
;; ##################################################################################

to set-row-control-patches [control-color]

  ask patches with [pxcor < payoff-display-margin and pycor > payoff-display-margin] 
    [
      if not (display-pr-x? or not display-investment-x?)  [
        set pcolor control-color
        set my-color pcolor
      ]
    ]
 ask patches with [pxcor = payoff-display-margin - 1 and pycor >= payoff-display-margin] 
    [
      set pcolor grey
      set my-color pcolor
    ]
end
;; ##################################################################################

to set-col-control-patches [control-color]

  ask patches with [pxcor > payoff-display-margin and pycor < payoff-display-margin and pxcor < (max-pxcor - right-display-margin)] 
    [
      if not (display-pr-x? or not display-investment-x?) [
        set pcolor control-color
        set my-color pcolor
      ]
    ]
  ask patches with [pycor < payoff-display-margin and pxcor >= (max-pxcor - right-display-margin)] 
    [
      set pcolor grey ;- 3
      set my-color pcolor
    ]
   ask patches with [pycor >= payoff-display-margin and pxcor > (max-pxcor - right-display-margin) and pxcor < (max-pxcor - right-display-margin + border - 1)] 
    [
      set pcolor grey ;- 3
      set my-color pcolor
    ]
   ask patches with [pxcor >= payoff-display-margin and pycor = payoff-display-margin - 1] 
    [
      set pcolor grey
      set my-color pcolor
    ]
end
;; ##################################################################################

to new-sim-random-seed
  set sim-seed sim-seed + 1
end
;; ##################################################################################

to update 
  ;; change display modes if it has changed
  if  current-display-mode != display-mode or currently-displayed-game != game-num [
    clear-drawing
    ask patches [
      change-display-mode
    ]
    ask payoff-highlight [
      change-display-mode-highlight
    ]
    ask pointers [
      change-display-mode-pointers
    ]
    foreach agent-list [
      ask ? [
        change-display-mode-agents
      ]
    ]
    ask links [
      change-display-mode-links
    ]
    
    if display-mode = "2-agent payoff matrix" [
      update-game-display
    ]
    
  ]
  set current-display-mode display-mode
  
  if game-num < num-games and game-num != [id] of focal-game [
    set focal-game one-of games with [id = game-num]
    set focal-agent-A [row-agent] of focal-game
    set focal-agent-B [col-agent] of focal-game
    update-game-display
    if display-mode = "2-agent payoff matrix" [
      draw-payoff-display
    ]
    plot-payoff-distributions
    
  ]
end
;; ##################################################################################

to draw-payoff-display
  clear-drawing
  let i [payoff-matrix-index] of focal-game 
  set focal-payoff-A-matrix item i payoff-row-matrix-list
  set focal-payoff-B-matrix item i payoff-col-matrix-list
  let possible-x-list-A [ ]
  let possible-x-list-B [ ]
  ask focal-agent-A [
    set possible-x-list-A possible-x-list
  ]
  ask focal-agent-B [
    set possible-x-list-B possible-x-list
  ]
  ask patches with [pxcor < (convert-pxcor max-moves) 
    and pxcor >= (convert-pxcor 0) 
    and pycor < (convert-pycor max-moves)
    and pycor >= (convert-pycor 0) ]  
  [
    let this-row inverse-pycor pycor
    let this-col inverse-pxcor pxcor
    
    ifelse (member? this-row possible-x-list-A) and (member? this-col possible-x-list-B) [
    let payoff-A matrix:get focal-payoff-A-matrix this-row this-col
    let payoff-B matrix:get focal-payoff-B-matrix this-row this-col
    set payoff-list (list payoff-A payoff-B)
    
    set pcolor scale-two-color-two-param item 0 payoff-list  item 1 payoff-list  3.0 -3.0  ;; color limits are 3 * sigma = 99.7%
                                                                                           ;; for focal-agent-A, set cell in payoff-matrix
    ]
    [
      set pcolor black
    ]
    set my-color pcolor ;; for use when changing display-mode
    
  ]  ;; end ask patches in payoff matrix area
  
  
end

;; ##############################################################################################

to-report transform-log-normal [payoff-pair] ;1.651453
  let row-payoff item 0 payoff-pair
  set row-payoff  (-(exp (- row-payoff * red-payoff-sigma)) + 1.651453 + green-red-offset) * (payoff-intensity) + (1 - payoff-intensity) * row-payoff  ;; defender
  let col-payoff item 1 payoff-pair
  set col-payoff  ( (exp ( col-payoff * red-payoff-sigma)) - 1.651453 - green-red-offset) * (payoff-intensity) + (1 - payoff-intensity) * col-payoff  ;; attacker
  report (list row-payoff col-payoff)
end

to-report distort [this-payoff] 
  ; see inverse.transform.logNormal.R for relevant code
  let result 0 
  ifelse this-payoff = 0 [
    set result 0
  ] 
  [
    ifelse this-payoff > 3 [
      set result ln (this-payoff) * (red-payoff-sigma + green-red-offset)
    ]
    [ 
      ifelse this-payoff < -3 [
        set result (- (ln (- this-payoff) * (red-payoff-sigma + green-red-offset)))
      ]
      [
        set result  this-payoff * 3 
      ]
    ]
  ]
  set result result * (payoff-intensity) + (1 - payoff-intensity) * this-payoff
  report result
end

to-report random-normal-correlated [gamma-x ]
  let mean-x 0          ;; mean = 0     ; from Galla & Farmer p 2
  let variance-x 1 ;; variance = 1 ; from Galla & Farmer p 2
                   ;; draw M random normal numbers, x and y
                   ;;  x has given mean and variance
                   ;;  y has variance scaled by gamma
                   ;;  then rotate the pair by 45 degrees, centered on {0.0,0.0}  https://en.wikipedia.org/wiki/Rotation_matrix#In_two_dimensions
                   ;;   45 degrees = 0.78539816339 radians = pi / 4
  
  let x random-normal 0 1.0
  ;set x min (list 3.0 max (list -3.0 x))
  let y random-normal mean-x (variance-x - abs( gamma-x ) )
  ;set y min (list 3.0 max (list -3.0 y))
  ;;show (word x ", " y)
  
  let theta 45
  ifelse gamma-x > 0 [
    set theta  45
  ]
  [
    set theta  -45
  ]
  let x-prime (x * cos(theta)) - (y * sin(theta))
  let y-prime (x * sin(theta)) + (y * cos(theta))
  ;set x-prime min (list 3.0 max (list -3.0 x-prime))
  ;set y-prime min (list 3.0 max (list -3.0 y-prime))
  report (list x-prime y-prime)
  
end


to-report scale-two-color-two-param [param1 param2 upper-limit lower-limit]
  let x-color [0 255 0 ]
  let y-color [255 0 0]
  let neutral-color [0 0 127]
  
  set param1 max (list lower-limit min (list param1 upper-limit))  ;; limit the parameters to the range between the limits
  set param2 max (list lower-limit min (list param2 upper-limit))
  
  let range upper-limit - lower-limit
  
  let x-weight  max(list 0 ((param1 - lower-limit  ) / range) )
  let y-weight  max(list 0 ((param2 - lower-limit ) / range) )
  ;let neutral-weight (1 - (abs(param1) + abs(param2) )  / range ) 
  
  let neutral-weight (1 - (sqrt ((x-weight - 0.5) ^ 2 + (y-weight - 0.5) ^ 2) / .707 ) )  ;; neutral weight = 0..1   ; close to 1.0 when x-weight = y-weight = 0.5
  set neutral-weight neutral-weight * neutral-weight * neutral-weight * neutral-weight  ;;  neutral-weight ^ 4  => fast decreasing when not near 1.0
  
                                                                                        ;print (sentence "param1 = " param1 "; param2 = " param2 "; x-weight = " x-weight "; y-weight = " y-weight "; neutral-weight = " neutral-weight)
  
  let i 0
  let scaled-color [ ]
  repeat 3 [
    let new-color (x-weight * item i x-color + y-weight * item i y-color  + neutral-weight * item i neutral-color)
    set scaled-color lput  new-color scaled-color
    set i i + 1
  ]
  report scaled-color
  
end

;; ##############################################################################################
;; #####################################  UTILITIES #############################################

to-report integer-to-binary-list [num bits]
  let result [ ]
  while [num > 0][
    set result fput (num mod 2) result
    set num int (num / 2)
  ]
  ; Java version
  ; int binary[] = new int[40];
  ;   int index = 0;
  ;   while(num > 0){
  ;     binary[index++] = num%2;
  ;     num = num/2;
  ;   }
  
  while [length result < bits] [
    set result fput 0 result
  ]
  
  report result
  
end

to-report factorial [num]
  let result num
  while [num > 1] [
    set num num - 1
    set result result * num
  ]
  report result
end 

to-report replace-newlines [str replace-str] 
  let new-string str
  let newline-pos position "\n" new-string
  while [newline-pos != false] [
    set new-string replace-item newline-pos new-string replace-str
    set newline-pos position "\n" new-string
  ]
  report new-string
end

to-report roulette [probabilities-list ]
  ;; create a roulette wheel using the probabilities-list, then return a random draw from that list according to probabilities
  let num-buckets length probabilities-list
  let buckets array:from-list n-values num-buckets [0]
  let total 0
  let i 0
  foreach probabilities-list [
    set total total + ?
    array:set buckets i total
    set i i + 1
  ]
  let result -1
  let draw random-float 1
  let done false
  set i 0
  
  if total <= 0 [
    show buckets
    user-message "Error in roulette: all probability buckets are empty"
  ]
  while [not done] [
    if array:item buckets i >= draw [
      set result  i
      set done  true
    ]
    set i i + 1
    if i >= num-buckets [
      set done  true
      set result i - 1
      ;show (sentence "Draw = " draw "Buckets = " buckets)
     ; user-message "Error in roulette: Ran out of buckets"  ;; not an error!!
    ]
  ]
  
  report result
end

to-report generate-key-list [n-dim  max-N]
  ;; return a list of lists, with the full cross product of values for each dimension
  
  ;; first, generate a list sequence from 0 to max-N
  let result n-values max-N [ (list ?) ]
  if n-dim > 1 [
    set result add-sub-list result 1 n-dim max-N
  ]
  report result
end

to-report add-sub-list [main-list dim limit-dim max-N]
  ;; recursively add sub-lists to the main-list, one sub-list for each additional dimension
  let result [ ]
  foreach main-list [
    let i 0
    repeat max-N [
      set result lput ( lput  i ?) result
      set i i + 1
    ]
  ]
  if dim < limit-dim - 1 [
    let nextdim dim + 1
    set result add-sub-list result nextdim limit-dim max-N
  ]
  report result
end

to-report convert-pxcor [x]

  report min(list (max-pxcor - right-display-margin) (x + payoff-display-margin))
end

to-report convert-pycor [y]
  report min(list max-pycor (y + payoff-display-margin))
end

to-report inverse-pxcor [x]
  report max(list 0 (x - payoff-display-margin))
end

to-report inverse-pycor [y]
  report max(list 0 (y - payoff-display-margin))
end

;; ############################## END UTILITIES #################################################




;; ##############################################################################################
;; #####################################  PATCH PROCEDURES ######################################

to change-display-mode
  ifelse display-mode = "2-agent payoff matrix" [
    set pcolor my-color
  ] 
  [
    if display-mode = "Agent interactions" [
      set pcolor black
      set plabel ""
    ]
  ]
end

; patch procedure
to display-pr-x-values
  let color-offset (agent-pr-x-id  mod 2) * 10  ;  color-offset is either 0 (for even IDs) or 10 (for odd IDs).  This changes hue for every other ocolumn
  let pr (matrix:get pr-x-matrix agent-pr-x-id x-value)
  
  let h-color [highlight-agent-color] of agent-pr-x
  
  let x-color [ ]
  
  set pr (log (pr ^ 0.3  + 1)  10)/ 0.6931472 ; which is log(2)
  
  let color-delta pr * 64
  ; if color-delta > 20 [
  ;   show (sentence x-value pr color-delta)
  ; ]
  ifelse h-color  = 55 [
    set x-color (list (32 - color-delta ) (min (list 255 (32 + color-delta * 8))) (32 + color-delta) )
    ;set x-color (list (255 - color-delta * 4) 255 (255 - color-delta * 4) )
  ]
  [
    set x-color (list (min (list 255 (32 + color-delta * 8))) (32 + color-delta ) (32 + color-delta) )
    ;set x-color (list 255 (255 - color-delta * 4) (255 - color-delta * 4) )
  ]
  
  ;
  set pcolor  x-color ;(h-color + color-offset - 3) + (pr * 8.9)
  set my-color pcolor
  
end

; patch procedure
to display-investment-x-values
  let h-color black
  let pr 0 
  
  ask agent-pr-x [
    set h-color highlight-agent-color
  ]
   set pr pr + length investment-list
   
   let attack 0
   let defense 0
   let color-offset 0
   let defense-only? false
   let attack-only? false
   let both-attack-and-defense? false
   foreach investment-list [
     set color-offset color-offset + ([id] of ?) mod 4
     if [attack?] of ? [
       set attack-only? true
     ]
     if [defense?] of ? [
       set defense-only? true
     ]
   ]
   if attack-only? and defense-only? [
     set defense-only? false
     set attack-only? false
     set both-attack-and-defense? true
   ]
   
   ifelse attack-only? [
     set h-color 15
   ] 
   [
     ifelse defense-only? [
       set h-color 55
     ]
     [
       if both-attack-and-defense? [set h-color 105]  ; for both-attack-and-defense?
     ]
   ]

  ifelse pr > 0 [ 
    ;(list min (list 255 (32 + attack)) min (list 255 (32 + attack / 2 + defense / 2)) min (list 255 (32 + defense))) ;
    set pcolor   (h-color - 4) + min (list 8 (pr * 4)) + 10 * color-offset
    set my-color pcolor
  ] 
  [ 
    ;(list 32 32 32) 
    set pcolor (h-color - 4)
    set my-color pcolor
  ]  
end


;; ##############################################################################################
;; #####################################  LINK PROCEDURES ######################################

to change-display-mode-links
  ifelse display-mode = "2-agent payoff matrix" [
    hide-link
  ] 
  [
    show-link
  ]
end
;; ##############################################################################################
;; #####################################  AGENT PROCEDURES ######################################

;; agent procedure
to add-new-possible-x [new-x-list]
  let added-x-list [ ]
  ; append the possible-x-list with the elements of new-x-list, avoiding duplicates
  foreach new-x-list [
    if not member? ? possible-x-list [
      set added-x-list lput ? added-x-list
      
    ]
  ]
  
  let new-added-count length added-x-list
  
  if new-added-count > 0 [
    let old-num-possible-x num-possible-x
    set num-possible-x num-possible-x + length added-x-list
    ; update the pr-x-matrix.  For new pr-x values, initialize them at a default value.
    
    let new-default-pr-x (1 / num-possible-x)
    let new-total-pr-x new-default-pr-x * length added-x-list  ;  this is the total probabilty to take away from existing values
    let old-possible-x-list possible-x-list
    foreach added-x-list[
      matrix:set pr-x-matrix id ? new-default-pr-x
      set possible-x-list lput ? possible-x-list
    ]
    
     ;  For all existing pr-x values, reduce them by a pro-rated amount of the reallocated probability.
     let reduction-pr-x new-total-pr-x / old-num-possible-x
     let max-pr-x 0
     let max-pr-x-index -1
     let reduction-count 0
    foreach old-possible-x-list [
      if (matrix:get pr-x-matrix id ?) > reduction-pr-x [
        if (matrix:get pr-x-matrix id ?) > max-pr-x [
          set max-pr-x (matrix:get pr-x-matrix id ?)
          set max-pr-x-index ?
          set reduction-count reduction-count + 1
        ]
        matrix:set pr-x-matrix id ? (matrix:get pr-x-matrix id ?) - reduction-pr-x
      ]
    ]
    
    if reduction-count < new-added-count [
      ; remove the remaining probability from the x with the highest probability
      repeat new-added-count - reduction-count [
        matrix:set pr-x-matrix id max-pr-x-index (matrix:get pr-x-matrix id max-pr-x-index) - reduction-pr-x
      ]
      
    ]
    
    if focal-agent-A = self or focal-agent-B = self[
      ;; turn on the new rows or columns
      set request-redraw-payoff-display? true
    ]
    
    set num-possible-x num-possible-x + new-added-count
  ]
  
end

to drop-possible-x [request-drop-x-list]
    let drop-x-list [ ]
  ; append the possible-x-list with the elements of new-x-list, avoiding duplicates
  foreach request-drop-x-list [
    if  member? ? possible-x-list [
      set drop-x-list lput ? drop-x-list
      
    ]
  ]
  
  let drop-count length drop-x-list
  if drop-count > 0 [
    
    let old-num-possible-x num-possible-x
    set num-possible-x num-possible-x - drop-count
    ; update the pr-x-matrix.  For new pr-x values, initialize them at a default value.
    
    let dropped-total-pr-x 0  ;  this is the total probabilty to add to existing pr-x values
    let old-possible-x-list possible-x-list
    foreach drop-x-list[
      set dropped-total-pr-x dropped-total-pr-x + matrix:get pr-x-matrix id ? 
      matrix:set pr-x-matrix id ? 0                 ; reset it to zero
      set possible-x-list remove ? possible-x-list  ; remove it from possible-x-list
    ]
    
     ;  For all existing pr-x values, increase them by a pro-rated amount of the reallocated probability.
     let increase-pr-x dropped-total-pr-x / num-possible-x
     
    foreach possible-x-list [
        matrix:set pr-x-matrix id ? min (list 1 ((matrix:get pr-x-matrix id ?) + increase-pr-x) )
      
    ]
    
    
    if focal-agent-A = self or focal-agent-B = self[
      ;; turn on the new rows or columns
      set request-redraw-payoff-display? true
    ]
  ]
  
end

;; agent procedure
;  OBSOLETE
;to display-pr-x-list
;  let start-x max-pxcor - right-display-margin + border + (id * pr-x-display-width)
;  let end-x start-x + pr-x-display-width
;  let i 0
;  let y payoff-display-margin 
  ;show  highlight-agent-color
;  let color-offset (id mod 2) * 10
;  repeat num-possible-moves [
;    let pr (matrix:get pr-x-matrix id i)
;    let h-color highlight-agent-color
;    let j 0
;    repeat pr-x-display-width [
;      ask patch (start-x + j) y [
;        set pcolor  (pr  * 8.9) + (h-color + color-offset - 4)
;      ]
;      set j j + 1
;    ]
;    set i i + 1
;    set y y + 1
;  ] 
;end

;; agent procedure
to change-display-mode-agents
  ifelse display-mode = "2-agent payoff matrix" [
    hide-turtle
  ]
  [
    show-turtle
  ]
end

;; agent procedure
to change-display-mode-highlight
  ifelse display-mode = "2-agent payoff matrix" [
    pen-up
    setxy previous-x previous-y
    show-turtle
    pen-down
    setxy current-x current-y
    pen-up
    
  ] 
  [
    if display-mode = "Agent interactions" [
      hide-turtle
    ]
  ]
end

;; agent procedure
to change-display-mode-pointers
  ifelse display-mode = "2-agent payoff matrix" [
    show-turtle
  ] 
  [
    if display-mode = "Agent interactions" [
      hide-turtle
    ]
  ]
end

;; agent procedure
to-report choose-x 
  report roulette matrix:get-row pr-x-matrix id
end

;; agent procedure
to update-attractions2 [opponents-list] ;; ;; SPEED PROBLEM -- called N times, once for each agent,  N - 1 (opponents), and M * M in the inner loop!!!!  O( (N ^ 2 ) * (M ^ 2) )
  
  ;; use pr-x-list of the alter agents
  let green-self? false
  if is-green-agent? self [
    set green-self? true
  ]
  
  let game-index 0
  foreach opponents-list [    ;; SPEED PROBLEM -- *** OUTER LOOP ****--  This loop is N - 1, worst case
    let i 0
    let this-opponent-index ?
    let this-opponent item this-opponent-index agent-list
    let get-row true
    
    let this-payoff-matrix 0
    
    let this-payoff-matrix-index 0
    ask (item game-index game-list) [
      set this-payoff-matrix-index payoff-matrix-index
      ifelse row-agent = myself [
        
        set this-payoff-matrix item payoff-matrix-index payoff-row-matrix-list  
        set get-row true
      ]
      [
        set this-payoff-matrix item payoff-matrix-index payoff-col-matrix-list
        set get-row false
      ]
    ]
    
    let skip-inner-loop false
    
    if not skip-inner-loop [  ;; SPEED TEST -- disables updating weights
      
      let this-game-weight item game-index game-weight-list
      if this-game-weight > 0.01 [ ;; SPEED IDEA -- only execute the inner loop if the weight of the game > MIN-GAME-WEIGHT ; i.e. ignore games with negligable weight
        ifelse get-row [  
          ; OLD repeat num-possible-moves [  ;; SPEED PROBLEM --  *** INNER LOOP ****  M^2  
          foreach possible-x-list [  ;; SPEED PROBLEM --  *** INNER LOOP ****  M^2 
            set i ?   
            ifelse old-weighted-payoff-methods [                                      
              array:set W-array i array:item W-array i + weighted-payoff-row2  this-payoff-matrix i this-opponent this-opponent-index this-game-weight green-self? 
              if debug [
                let new-weighted-payoff weighted-payoff-row-NEW  this-payoff-matrix this-payoff-matrix-index i  this-opponent-index this-game-weight
                print (sentence i "Old row = " array:item W-array i "vs new = "  new-weighted-payoff )   
                print ""
              ]
            ]
            [
              array:set W-array i array:item W-array i + weighted-payoff-row-NEW  this-payoff-matrix i this-opponent this-opponent-index this-game-weight 
              if debug [
                let old-weighted-payoff  weighted-payoff-row2  this-payoff-matrix this-payoff-matrix-index i this-opponent-index this-game-weight green-self?
                print (sentence i "Old row = " old-weighted-payoff  "vs new = "  array:item W-array i )   
                print ""
              ]
            ]

            ; OLD set i i + 1      
          ] ;;  END INNER LOOP 
        ]
        [ ;else 
          ;repeat num-possible-moves [ ;; SPEED PROBLEM --  *** INNER LOOP **** called M times, once for each possible move
          foreach possible-x-list [  ;; SPEED PROBLEM --  *** INNER LOOP ****  M^2 
            set i ?
            ifelse old-weighted-payoff-methods [
              array:set W-array i array:item W-array i + weighted-payoff-col2 this-payoff-matrix i this-opponent this-opponent-index this-game-weight green-self?; (item game-index game-weight-list)
              if debug [
                let new-weighted-payoff weighted-payoff-col-NEW this-payoff-matrix this-payoff-matrix-index i this-opponent-index this-game-weight
                print (sentence i "Old col = " array:item W-array i "vs new = " new-weighted-payoff)
                print ""
              ]
            ]
            [
              array:set W-array i array:item W-array i + weighted-payoff-col-NEW   this-payoff-matrix this-payoff-matrix-index i this-opponent-index this-game-weight
              if debug [
                let old-weighted-payoff array:item W-array i + weighted-payoff-col2 this-payoff-matrix i this-opponent this-opponent-index this-game-weight green-self?
                print (sentence i "Old row = " old-weighted-payoff  "vs new = "  array:item W-array i )   
                print ""
              ]
            ]

            ; set i i + 1
          ] ;;  END INNER LOOP
          
        ] ;end ifelse get-row
      ] ; end if this-game-weight > min
      
    ] ; end if not skip-inner-loop  ;; SPEED TEST
    
    set game-index game-index + 1
  ] ;; end foreach pr-x-alters-list   ;;  END OUTER LOOP
  
  let i 0
  ;repeat num-possible-moves [  ;; SPEED PROBLEM -- *** SECOND LOOP **** called M times, once for each possible move
  foreach possible-x-list [
    set i ?
    array:set Q-array i ((1 - my-alpha) * array:item Q-array i) + array:item W-array i
    array:set W-array i 0 ; reset this for the use by the next agent
    ;set i i + 1
  ]
  ;print ""
end

;; agent procedure
to-report weighted-payoff-row2 [p-matrix p-row-index opponent opponent-index a-weight green-self?]
  let total 0
  let i 0
  let probabilistic-risk-assessment? green-rule = "probabilistic risk assessment"
  let H-M-L-risk-assessment? green-rule = "H-M-L risk assessment"
  let binary-assessment? green-rule = "binary assessment"
  let payoff-threshold green-rating-threshold
  let opponent-uncertainty green-oppon-uncertainty
  if is-red-agent? self [
    set opponent-uncertainty red-oppon-uncertainty
    set probabilistic-risk-assessment? red-rule = "probabilistic risk assessment"
    set H-M-L-risk-assessment? red-rule = "H-M-L risk assessment"
    set binary-assessment? red-rule = "binary assessment"
    set payoff-threshold red-rating-threshold
  ]

   let distortion 0
   let noise 0
   let this-game-uncertainty? false
   if uncertainty? [
     ifelse green-self? and is-red-agent? opponent [
       set distortion green-distortion
       set noise green-noise
       set this-game-uncertainty? true
     ] 
     [
       if not green-self? and is-green-agent? opponent[
         set distortion red-distortion
         set noise red-noise
         
         set this-game-uncertainty? true
       ]     
     ]
   ]
  ask opponent [
    let default-probability (1 / num-possible-x)
    let pr-threshold payoff-threshold * default-probability
    foreach possible-x-list [
  
      set i ?
      ;set total total + ((matrix:get p-matrix p-row-index i) * (1 - noise) + (noise * random-payoff ) ) * matrix:get pr-x-matrix opponent-index i 
      
      ifelse not this-game-uncertainty? [
        set total total + (matrix:get p-matrix p-row-index i)  * matrix:get pr-x-matrix opponent-index i
      ]
      [ 
        if  [array:item blind-spots-array i] of myself = 1 [
          let random-payoff random-normal 0 1.0
          let this-row-payoff matrix:get p-matrix p-row-index i
          let this-row-pr matrix:get pr-x-matrix opponent-index i
          ifelse binary-assessment? [
            ; set this-row-payoff to payoff-threshold if >=, otherwise set to zero
            ifelse abs this-row-payoff >= payoff-threshold [
              let sign ifelse-value (this-row-payoff >= 0) [1] [-1]
              set this-row-payoff (payoff-threshold * sign)
            ]
            [
              set this-row-payoff 0
            ]
            
           ; set this-row-pr to pr-threshold if >=, otherwise set to zero
           ifelse this-row-pr >= pr-threshold [
              set this-row-pr pr-threshold 
            ]
            [
              set this-row-pr 0
            ]
            
          ] [
          if  H-M-L-risk-assessment? [
             ; set this-row-payoff to one of three threshold values, or to zero
            let sign ifelse-value (this-row-payoff >= 0) [1] [-1]
            ifelse abs this-row-payoff > payoff-threshold * 2 [
              set this-row-payoff (payoff-threshold * sign * 2)
            ]
            [
              ifelse abs this-row-payoff > payoff-threshold  [
                set this-row-payoff (payoff-threshold * sign )
              ]
              [
                ifelse abs this-row-payoff > payoff-threshold / 2  [
                  set this-row-payoff (sign * payoff-threshold / 2  )
                ]
                [
                  set this-row-payoff 0
                ]               
              ]
            ]
              ; set this-row-pr to one of three threshold values, or to zero
              
            ifelse abs this-row-pr >= pr-threshold * 2 [
              set this-row-pr (pr-threshold * 2)
            ]
            [
              ifelse abs this-row-pr >= pr-threshold  [
                set this-row-pr pr-threshold  
              ]
              [
                ifelse abs this-row-pr >= pr-threshold / 2  [
                  set this-row-pr (pr-threshold / 2  )
                ]
                [
                  set this-row-pr 0
                ]               
              ]
            ]
            ]
          ]
          
          let this-expected-payoff 
            (
              (
                this-row-payoff * (1 - distortion)                      ;; undistorted payoff
              + (distortion * distort (this-row-payoff))                ;; distorted payoff
              ) * 
              (
                this-row-pr * (1 - opponent-uncertainty)     ;; certain opponent probability
              + (opponent-uncertainty * default-probability)                                  ;; uncertain opponent probability
              )
            ) * (1 - noise) + (noise * random-payoff )                                      ;; mixture of clean and noisy payoff       
          
          
          ;show (sentence i this-expected-payoff)
          set total total + this-expected-payoff
        ]
        ;ask myself [show (sentence (matrix:get p-matrix p-row-index i) distort (matrix:get p-matrix p-row-index i))]
      ]
    ]
  ]
  report total * a-weight
end

;; agent procedure
to-report weighted-payoff-col2 [p-matrix p-col-index opponent opponent-index a-weight green-self?]
  let total 0
  let i 0
  let probabilistic-risk-assessment? green-rule = "probabilistic risk assessment"
  let H-M-L-risk-assessment? green-rule = "H-M-L risk assessment"
  let binary-assessment? green-rule = "binary assessment"
  let expected-payoff-threshold green-rating-threshold
  let opponent-uncertainty green-oppon-uncertainty
  if is-red-agent? self [
    set opponent-uncertainty red-oppon-uncertainty
    set probabilistic-risk-assessment? red-rule = "probabilistic risk assessment"
    set H-M-L-risk-assessment? red-rule = "H-M-L risk assessment"
    set binary-assessment? red-rule = "binary assessment"
    set expected-payoff-threshold red-rating-threshold
  ]

  let distortion 0
  let noise 0
  let this-game-uncertainty? false
   if uncertainty? [
     ifelse green-self? and is-red-agent? opponent [
       set distortion green-distortion
       set noise green-noise
       set this-game-uncertainty? true
     ] 
     [
       if not green-self? and is-green-agent? opponent[
         set distortion red-distortion
         set noise red-noise
         set this-game-uncertainty? true
       ]     
     ]
   ]
  ask opponent [
    let default-probability (1 / num-possible-x)
    foreach possible-x-list [
      ;let random-payoff random-normal 0 1.0
      set i ?
      ;set total total + ((matrix:get p-matrix i p-col-index) * (1 - noise) + (noise * random-payoff ) ) * matrix:get pr-x-matrix opponent-index i 
      
      ifelse not this-game-uncertainty? [
        set total total + (matrix:get p-matrix i p-col-index)  * matrix:get pr-x-matrix opponent-index i 
      ] 
      [ 
        if  [array:item  blind-spots-array i] of myself = 1 [
          let random-payoff random-normal 0 1.0
          let this-expected-payoff ((((matrix:get p-matrix i p-col-index) * (1 - distortion) 
            + (distortion * distort (matrix:get p-matrix i p-col-index)) ) * matrix:get pr-x-matrix opponent-index i ) * (1 - opponent-uncertainty)
            + (opponent-uncertainty * default-probability) ) * (1 - noise) + (noise * random-payoff )
          ifelse binary-assessment? [
            ifelse abs this-expected-payoff > expected-payoff-threshold [
              let sign ifelse-value (this-expected-payoff >= 0) [1] [-1]
              set this-expected-payoff (expected-payoff-threshold * sign)
            ]
            [
              set this-expected-payoff 0
            ]
          ]
          [
            if H-M-L-risk-assessment? [
              let sign ifelse-value (this-expected-payoff >= 0) [1] [-1]
              ifelse abs this-expected-payoff > expected-payoff-threshold * 2 [
                set this-expected-payoff (expected-payoff-threshold * sign * 2)
              ]
              [
                ifelse abs this-expected-payoff > expected-payoff-threshold  [
                  set this-expected-payoff (expected-payoff-threshold * sign )
                ]
                [
                  ifelse abs this-expected-payoff > expected-payoff-threshold / 2  [
                    set this-expected-payoff (sign * expected-payoff-threshold / 2  )
                  ]
                  [
                    set this-expected-payoff 0
                  ]
                  
                  
                ]
              ]
            ]
          ]
          set total total + this-expected-payoff
        ]
        ;ask myself [show (sentence (matrix:get p-matrix i p-col-index) distort (matrix:get p-matrix i p-col-index))]
      ]
      ;set i i + 1
    ]
  ]
  report total * a-weight 
end

;; agent procedure
; NEW NEW NEW for speed improvement
to-report weighted-payoff-row-NEW [p-matrix  p-matrix-index p-row-index opponent  a-weight]  ;top-x-list is agent variable
  ;; use top-x-list to index the pr-x-matrix
  
  
  ; top-x-list holds the list of the top pr(x) indices (x values), used as keys to top-pr-x-table
  ; remainder-probability = 1 - sum(top-pr-x)
  ; Remainder weight = (average-payoff - top-pr-x-payoffs) * remainder-probability
  
  ; iterate through the top-pr-x-list ; probably less than 10, and maybe less than 4.  Gets faster when fewer significant pr(x)
  
  ;  foreach, get the corresponding top-pr-x from the top-pr-x-table
  let sum-top-pr-x-weight 0
  let sum-pr-x 0
  foreach top-x-list [
    ;  set this-weighted-payoff multiply top-pr-x * this-payoff (the corresponding payoff from my payoff matrix)
    let this-weighted-payoff (matrix:get p-matrix p-row-index ?) * matrix:get pr-x-matrix opponent ?
    ;  add this-weighted-payoff to the total-top-pr-x-weight
    set sum-top-pr-x-weight sum-top-pr-x-weight + this-weighted-payoff
    ;  add this-payoff to total-top-payoffs
    set sum-pr-x sum-pr-x + matrix:get pr-x-matrix opponent ? 
    if debug [
      print (sentence "Row #" p-row-index "; col # " ?  " weight=" matrix:get pr-x-matrix opponent ? "; payoff=" this-weighted-payoff "; # top-x =" length top-x-list)  
    ] 
  ]
  
  ; remainder-probability = 1 - sum-pr-x
  let remainder-probability  1 - sum-pr-x
  if debug [
    print (sentence p-row-index "row top-x-payoff sum=" sum-top-pr-x-weight "; top-x sum =" sum-pr-x )
  ]
  let remainder-weight 0
 ; let debug-output 0
  ifelse length top-x-list > 0 [                                                                                                               ;;  payoff-row-matrix-avg-list
    ;set remainder-weight  ((initial-pr-x - (sum-top-pr-x-weight / length top-x-list)) * remainder-probability ) * array:item (item p-matrix-index payoff-row-matrix-avg-list) p-row-index
    set remainder-weight  ((array:item (item p-matrix-index payoff-row-matrix-avg-list) p-row-index - (sum-top-pr-x-weight * (length top-x-list / num-possible-moves))) * remainder-probability ) 
    if debug [
      print (sentence "remainder-weight= " remainder-weight  "; normalized sum-top-pr-x-weight=" (sum-top-pr-x-weight * (length top-x-list / num-possible-moves))  "; remainder-probability=" remainder-probability) 
    ]
 ;;   set debug-output (sentence "Row = " p-row-index "; weighted payoff = " remainder-weight)
  ]
  [                                                   ;; payoff-row-matrix-avg-list
    set remainder-weight array:item (item p-matrix-index payoff-row-matrix-avg-list) p-row-index
 ;   set debug-output (sentence "Row = " p-row-index "; weighted payoff = " remainder-weight "(nothing in top list)")
  ]
  let new-weight  sum-top-pr-x-weight + remainder-weight
;  set debug-output (sentence debug-output "; returning: " (new-weight * a-weight))
;  print debug-output
  report new-weight * a-weight
end

; NEW NEW NEW for speed improvement
to-report weighted-payoff-col-NEW  [p-matrix p-matrix-index p-col-index opponent a-weight]
    ;; use top-x-list to index the pr-x-matrix
  
  
  ; top-x-list holds the list of the top pr(x) indices (x values), used as keys to top-pr-x-table
  ; remainder-probability = 1 - sum(top-pr-x)
  ; Remainder weight = (average-payoff - top-pr-x-payoffs) * remainder-probability
  
  ; iterate through the top-pr-x-list ; probably less than 10, and maybe less than 4.  Gets faster when fewer significant pr(x)
  
  ;  foreach, get the corresponding top-pr-x from the top-pr-x-table
  let sum-top-pr-x-weight 0
  let sum-pr-x 0
  foreach top-x-list [
    ;  set this-weighted-payoff multiply top-pr-x * this-payoff (the corresponding payoff from my payoff matrix)
    let this-weighted-payoff (matrix:get p-matrix ? p-col-index) * matrix:get pr-x-matrix opponent ?
    ;  add this-weighted-payoff to the total-top-pr-x-weight
    set sum-top-pr-x-weight sum-top-pr-x-weight + this-weighted-payoff
    ;  add this-payoff to total-top-payoff
    if debug [
      print (sentence "Col #" p-col-index "; row # " ?  " weight=" matrix:get pr-x-matrix opponent ? "; payoff=" this-weighted-payoff  "; # top-x =" length top-x-list)
    ]  
    set sum-pr-x sum-pr-x + matrix:get pr-x-matrix opponent ?    
  ]

  ; remainder-probability = 1 - sum-pr-x
  let remainder-probability  1 - sum-pr-x
  let remainder-weight 0
  if debug [
    print (sentence p-col-index "row top-x-payoff sum=" sum-top-pr-x-weight "; top-x sum =" sum-pr-x )
  ]
 ; let debug-output 0
  ifelse length top-x-list > 0 [
    set remainder-weight  ((array:item (item p-matrix-index payoff-col-matrix-avg-list) p-col-index - (sum-top-pr-x-weight * (length top-x-list / num-possible-moves)))  * remainder-probability ) 
    if debug [
      print (sentence "remainder-weight= " remainder-weight  "; normalized sum-top-pr-x-weight=" (sum-top-pr-x-weight * (length top-x-list / num-possible-moves))  "; remainder-probability=" remainder-probability) 
    ]
 ;   set debug-output (sentence "Col = " p-col-index "; weighted payoff = " remainder-weight)
  ]
  [
    set remainder-weight array:item (item p-matrix-index payoff-col-matrix-avg-list) p-col-index                   ;; RUSS!!! THIS DOESN'T WORK ... STAYS STUCK AT INITIAL-PR-X
 ;    set debug-output (sentence "Col = " p-col-index "; weighted payoff = " remainder-weight "(nothing in top list)")
  ]
  
  let new-weight  sum-top-pr-x-weight + remainder-weight
;  set debug-output (sentence debug-output "; returning: " (new-weight * a-weight))
;  print debug-output
  report new-weight * a-weight
  
end

;; agent procedure
to update-blind-spots
  let pr-discovery 1
  ifelse is-red-agent? self [
    set pr-discovery red-pr-discovery
  ] [
    set pr-discovery green-pr-discovery
  ]
  if num-blind-spots > 0 [
    foreach opponent-move-list [
      if array:item blind-spots-array ? = 0 and random-float 1 <= pr-discovery  [ 
        array:set blind-spots-array ? 1 
        set num-blind-spots num-blind-spots - 1
      ]
    ]
  ]
end


;; agent procedure
to update-choice-probabilities
  
  ifelse learning-model = "none" [
    ;; no update
  ] 
  [
    let best-practice-proportion 0
    let best-practices-available?  false
    let bp-array 0 
    if bp-mode != "none" and not best-performing-agent? [
      ifelse is-red-agent? self [
        set best-practice-proportion red-imitate-bp
        set best-practices-available? red-best-practices?
        set bp-array red-best-practice-array
      ] 
      [
        set best-practice-proportion green-imitate-bp
        set best-practices-available?  green-best-practices?
        set bp-array green-best-practice-array
      ]
    ]
    set top-x-list [ ]
    ;; calculate the numerators, storing them in a list, and accumulate the sum for use in the denomenator
    let total 0
    let numerators [ ]
    let this-numerator 0
    let i 0
    foreach possible-x-list [
    ;repeat num-possible-moves [
      set i ?
      set this-numerator exp (my-beta * array:item Q-array i) 
      set numerators lput this-numerator numerators
      set total total + this-numerator
      ;set i i + 1
    ]
    
    let j 0
    let revised-total 0
    foreach possible-x-list [
      set i ?
      let new-pr-x ((item j numerators) / total )
      let imitate? true  ;  
      if aspire? and best-practices-available? and not best-performing-agent? [
        set imitate? (array:item bp-array i) > (item j numerators) / total  ;; if aspire? = true, then only include best practice of pr-best-practice is greater than pr-x
      ]
      if bp-mode != "none" and ticks >= start-bp and not best-performing-agent? and best-practices-available? and best-practice-proportion > 0 and imitate?  [
        set new-pr-x ((item j numerators) / total ) * (1 - best-practice-proportion) + (best-practice-proportion) * (array:item bp-array i)
      ]
      set revised-total revised-total + new-pr-x
      matrix:set pr-x-matrix id i new-pr-x
      set j j + 1
    ]
    if revised-total != 1 and revised-total > 0 [ ;; then normalize
      let multiplier 1 / revised-total
      foreach possible-x-list [
        set i ?
        matrix:set pr-x-matrix id i ((matrix:get pr-x-matrix id i) * multiplier)
      ]
      
    ]
    
  ]

end

to update-payoff [this-payoff this-game]
  let game-index position this-game game-list
  let this-weight item game-index game-weight-list
  set current-payoff current-payoff + this-payoff * this-weight
  set cum-payoff cum-payoff + this-payoff * this-weight
  
  set current-period-payoff current-period-payoff + this-payoff * this-weight

  
end

;;###############################################################################################
;; #####################################  GAME (agent) PROCEDURES ###############################
;; ##############################################################################################

to play-game
  ;; poll the two agents for their moves
  
  set current-row-move [current-x] of row-agent
  
  set current-col-move [current-x] of col-agent
  
  if (is-green-agent? row-agent and is-red-agent? col-agent) or (is-green-agent? col-agent  and is-red-agent? row-agent) [
    ask row-agent[
      if not member? [current-col-move] of myself opponent-move-list [
        set opponent-move-list lput [current-col-move] of myself opponent-move-list
      ]
    ]
    ask col-agent[
      if not member? [current-row-move] of myself opponent-move-list [
        set opponent-move-list lput [current-row-move] of myself opponent-move-list
      ]
    ]
    
  ]
  
  ;; retrieve the payoffs
  let row-payoff matrix:get (item payoff-matrix-index payoff-row-matrix-list) current-row-move current-col-move
  
  let col-payoff matrix:get (item payoff-matrix-index payoff-col-matrix-list) current-row-move current-col-move
  
  ;show (sentence row-agent " gets " row-payoff "; " col-agent " gets " col-payoff "; from matrix #" payoff-matrix-index)
    
    
  ;; inform the agents about the new the payoffs
  ask row-agent [
    update-payoff row-payoff myself
  ]
  
  ask col-agent [
    update-payoff col-payoff myself
  ]
  
end

to-report get-opponent [an-agent]
  let result -1
  ifelse an-agent = row-agent [
    set result [id] of col-agent 
  ] 
  [ ; else
    if an-agent = col-agent [
    set result [id] of row-agent 
    ]
  ]
  report result
  
end

;to-report get-opponent-pr-x-list [an-agent]  ;; OBSOLETE!!!!
;  let result [ ]
;  ifelse an-agent = row-agent [
;    ask col-agent [
;      set result pr-x-list
;    ]
;  ] 
;  [ ; else
;    if an-agent = col-agent [
;      ask row-agent [
;        set result pr-x-list
;      ]
;    ]
;  ] 
;  report result
;end




;;#######################################################################################################
;;#######################################################################################################
;;                                  PLOTTING
;;#######################################################################################################
;;#######################################################################################################

to plot-payoff-distributions
  set-current-plot "Possible Payoffs - A"
  let payoffs  matrix:to-row-list focal-payoff-A-matrix
  set payoffs reduce sentence payoffs
  set mean-payoff-A mean payoffs
  set pct-positive-payoff-A length (filter [? > 0] payoffs) / length (payoffs)
  ;print length (filter [? > 0] payoffs)
  ;let max-payoffs-A max payoffs
  ;let min-payoffs-A min payoffs

  ; convert to log values
  ;set payoffs map [log (? - min-payoffs-A + 1) 10] payoffs
  
  set-plot-x-range ((round (min payoffs)) - 2) ((round (max payoffs)) + 2)
  set-histogram-num-bars 21
  histogram payoffs
  
  set-current-plot "Possible Payoffs - B"
  set payoffs  matrix:to-row-list focal-payoff-B-matrix
  set payoffs reduce sentence payoffs
  set mean-payoff-B mean payoffs
  set pct-positive-payoff-B length (filter [? > 0] payoffs) / length (payoffs)
  ;print length (filter [? > 0] payoffs)
  set-plot-x-range ((round (min payoffs))  - 2) ((round (max payoffs)) + 2)
  set-histogram-num-bars 21
  histogram payoffs
end

to do-plots
  let focal-id-A [id] of focal-agent-A
  let focal-id-B [id] of focal-agent-B
  
  set-current-plot "Focal Agents' Cumulative Payoffs"
  ;; only plot the two focal agents
  set-current-plot-pen "A"
  set-plot-pen-color ([normal-agent-color] of focal-agent-A)
  plot [cum-payoff] of focal-agent-A
  set-current-plot-pen "B"
  set-plot-pen-color ([highlight-agent-color] of focal-agent-B)
  plot [cum-payoff] of  focal-agent-B
  
  set-current-plot "Move Probabilities - Focal Agent A"
  clear-plot
  set-plot-pen-color ([normal-agent-color] of focal-agent-A)
  set-plot-x-range 0 max-moves
  foreach matrix:get-row pr-x-matrix focal-id-A [
    plot ?
  ]
 ; ask focal-agent-A [
 ;   foreach pr-x-list [
 ;     plot ?
 ;   ]
 ; ]
  set-current-plot "Move Probabilities - Focal Agent B"
  clear-plot
  set-plot-pen-color ([highlight-agent-color] of focal-agent-B)
  set-plot-x-range 0 max-moves
  foreach matrix:get-row pr-x-matrix focal-id-B [
    plot ?
  ]
  ;ask focal-agent-B [
  ;  foreach pr-x-list [
  ;    plot ?
  ;  ]
  ;]
  let x1 item (item 0 move-IDs-A-list) [possible-x-list] of focal-agent-A
  let x2 item (item 1 move-IDs-A-list) [possible-x-list] of focal-agent-A
  let x3 item (item 2 move-IDs-A-list) [possible-x-list] of focal-agent-A
  let x4 item (item 3 move-IDs-A-list) [possible-x-list] of focal-agent-A
  set-current-plot "Pr(move) Time Series - Focal Agent A"
 
  set-current-plot-pen "1"
  if (matrix:get pr-x-matrix focal-id-A x1 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-A x1 ) 10
   ] 
  set-current-plot-pen "2"
  if (matrix:get pr-x-matrix focal-id-A x2 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-A x2  ) 10
   ] 
  set-current-plot-pen "3"
  if (matrix:get pr-x-matrix focal-id-A x3 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-A x3 ) 10
   ] 
  set-current-plot-pen "4"
  if (matrix:get pr-x-matrix focal-id-A x4  > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-A x4  ) 10
   ] 
  ;set-plot-y-range -10 1
  
  set x1 item (item 0 move-IDs-B-list) [possible-x-list] of focal-agent-B
  set x2 item (item 1 move-IDs-B-list) [possible-x-list] of focal-agent-B
  set x3 item (item 2 move-IDs-B-list) [possible-x-list] of focal-agent-B
  set x4 item (item 3 move-IDs-B-list) [possible-x-list] of focal-agent-B
  
  set-current-plot "Pr(move) Time Series - Focal Agent B"
  set-current-plot-pen "1"
  if (matrix:get pr-x-matrix focal-id-B x1 > 0)  [
   plot log ( matrix:get pr-x-matrix focal-id-B x1 ) 10
  ] 
  set-current-plot-pen "2"
  if (matrix:get pr-x-matrix focal-id-B x2 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-B x2 ) 10
  ] 
  set-current-plot-pen "3"
  if (matrix:get pr-x-matrix focal-id-B x3 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-B x3 ) 10
  ] 
  set-current-plot-pen "4"
  if (matrix:get pr-x-matrix focal-id-B x4 > 0)  [
  plot log ( matrix:get pr-x-matrix focal-id-B x4 ) 10
  ] 
  ;set-plot-y-range -50 1
  
  ;if ticks mod period = 0 and ticks > 0 [
  set-current-plot "Mean Payoffs"
  clear-plot
  set-plot-pen-color black
  ifelse model = "Galla & Farmer 2012" [
    set-plot-x-range 0 num-agents 
    repeat num-agents[
      plot 0 ;; for baseline
    ]
  ] 
  [
    set-plot-x-range 0 (num-red-agents + num-green-agents )
    repeat num-red-agents + num-green-agents[
      plot 0 ;; for baseline
    ]
  ]
  

  plot-pen-up
  plotxy -1 0
  
  plot-pen-down
  let min-y 0
  let max-y 0
  if num-green-agents > 0 [
    set-plot-pen-color green
    let i 0
    let min-id (min [ID] of green-agents)
    repeat num-green-agents [
      ask one-of green-agents with [ID = i + min-id ][
        ifelse avg-payoff > max-y [
          set max-y (ceiling(avg-payoff * 10) / 10 ) 
        ] 
        [
          if avg-payoff < min-y [
            set min-y (floor(avg-payoff * 10) / 10) 
          ]
        ]
        plot avg-payoff ; last-period-payoff 
                        ;show (sentence last-period-payoff current-period-payoff)
      ]
      set i i + 1
    ]
    
  ]   
  if num-red-agents > 0 [
    set-plot-pen-color red
    let i 0
    let min-id (min [ID] of red-agents)
    repeat num-red-agents [
      ask one-of red-agents with [ID = i + min-id] [
        ifelse avg-payoff > max-y [
          set max-y (ceiling(avg-payoff * 10) / 10) 
        ] 
        [
          if avg-payoff < min-y [
            set min-y (floor(avg-payoff * 10) / 10) 
          ]
        ]
        plot avg-payoff ; last-period-payoff
                        ;show (sentence last-period-payoff current-period-payoff)
      ]
      set i i + 1
    ]
  ]
  set max-y (round(max-y * 100) / 100) + 0.05
  set min-y (round(min-y * 100) / 100 ) - 0.05

  set-current-plot "Actual Payoffs-A"
  ask focal-agent-A [
    set-histogram-num-bars 21
    set-plot-x-range ((round (min payoff-history))  - 2) ((round (max payoff-history)) + 2)
    histogram payoff-history
    set focal-agent-A-avg-payoff avg-payoff
    set focal-agent-A-sd-payoff sd-payoff
  ]
  
  set-current-plot "Actual Payoffs-B"
  ask focal-agent-B [
    set-histogram-num-bars 21
    set-plot-x-range ((round (min payoff-history))  - 2) ((round (max payoff-history)) + 2)
    histogram payoff-history

  ]
  
  
  set-current-plot "Moving Average Mean Payoffs"
  set-current-plot-pen "default"
  plot 0
  ask red-agents [
    set-current-plot-pen (word "red" id)
    ifelse ticks < period / 3 [
      plot-pen-up
    ]
    [
      plot-pen-down
    ]
    plot avg-payoff
  ]
  ask green-agents [
    set-current-plot-pen (word "green" id)
    ifelse ticks < period / 3 [
      plot-pen-up
    ]
    [
      plot-pen-down
    ]
    plot avg-payoff
  ]
  
  set-current-plot "Moving Average SD Payoffs"
  set-current-plot-pen "default"
  plot 0
  ask red-agents [
    set-current-plot-pen (word "red" id)
    ifelse ticks < period / 3 [
      plot-pen-up
    ]
    [
      plot-pen-down
    ]
    plot sd-payoff
  ]
  ask green-agents [
    set-current-plot-pen (word "green" id)
    ifelse ticks < period / 3 [
      plot-pen-up
    ]
    [
      plot-pen-down
    ]
    plot sd-payoff
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
1077
429
1714
910
-1
-1
1.0
1
15
1
1
1
0
0
0
1
0
626
0
449
0
0
1
ticks
30.0

BUTTON
10
54
65
87
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
70
54
125
88
NIL
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

SLIDER
1337
943
1497
976
num-possible-moves
num-possible-moves
10
400
100
5
1
NIL
HORIZONTAL

SLIDER
1337
982
1496
1015
Gamma
Gamma
-1
1
0
.1
1
NIL
HORIZONTAL

CHOOSER
1177
934
1327
979
display-mode
display-mode
"2-agent payoff matrix" "Agent interactions"
0

SLIDER
1502
944
1652
977
num-agents
num-agents
2
20
2
1
1
NIL
HORIZONTAL

BUTTON
975
934
1030
967
NIL
reset
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
409
708
1072
908
Focal Agents' Cumulative Payoffs
ticks
NIL
0.0
10.0
-1.0
1.0
true
true
"" ""
PENS
"A" 1.0 0 -7500403 true "" ""
"B" 1.0 0 -2674135 true "" ""

TEXTBOX
8
13
198
55
Cyber Security \nInvestment Game
15
0.0
1

SLIDER
1500
983
1650
1016
alpha
alpha
0
.02
0.01
.0001
1
NIL
HORIZONTAL

CHOOSER
1343
1023
1492
1068
learning-model
learning-model
"experience weighted" "none"
0

SLIDER
1503
1023
1651
1056
beta
beta
0
.15
0.07
.01
1
NIL
HORIZONTAL

BUTTON
134
54
189
88
step
go
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
1067
13
1549
160
Move Probabilities - Focal Agent A
move #
Pr.
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1067
159
1549
306
Move Probabilities - Focal Agent B
move #
Pr.
0.0
10.0
0.0
0.1
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
411
10
1063
180
Pr(move) Time Series - Focal Agent A
NIL
log Pr.
0.0
10.0
-3.0
0.0
true
true
"" ""
PENS
"1" 1.0 0 -16777216 true "" ""
"2" 1.0 0 -7500403 true "" ""
"3" 1.0 0 -955883 true "" ""
"4" 1.0 0 -8630108 true "" ""

PLOT
409
181
1062
351
Pr(move) Time Series - Focal Agent B
NIL
log Pr
0.0
10.0
-3.0
0.0
true
true
"" ""
PENS
"1" 1.0 0 -16777216 true "" ""
"2" 1.0 0 -7500403 true "" ""
"3" 1.0 0 -955883 true "" ""
"4" 1.0 0 -8630108 true "" ""

INPUTBOX
277
79
407
139
sim-seed
0
1
0
Number

SWITCH
317
73
407
106
lock
lock
0
1
-1000

INPUTBOX
277
140
409
204
setup-seed
-2147483645
1
0
Number

INPUTBOX
1820
359
1880
502
move-IDs-A
1\n2\n3\n5
1
1
String

INPUTBOX
1820
504
1883
621
move-IDs-B
1\n2\n3\n5
1
1
String

CHOOSER
977
1015
1167
1060
model
model
"Galla & Farmer 2012" "Thomas 2016"
1

TEXTBOX
1345
925
1652
944
-- Galla & Farmer 2012 -------------------------
11
0.0
1

SLIDER
1554
95
1587
277
Gamma-green-v-green
Gamma-green-v-green
-1
1
0.4
.1
1
NIL
VERTICAL

SLIDER
1595
95
1628
277
Gamma-green-v-red
Gamma-green-v-red
-1
1
-0.9
.1
1
NIL
VERTICAL

SLIDER
43
189
76
357
alpha-red
alpha-red
0
.05
0.0040
.0001
1
NIL
VERTICAL

SLIDER
7
189
40
357
alpha-green
alpha-green
0
0.05
0.0040
.0001
1
NIL
VERTICAL

SLIDER
95
189
128
357
beta-green
beta-green
0
.8
0.1
.01
1
NIL
VERTICAL

SLIDER
135
189
168
357
beta-red
beta-red
0
.8
0.1
0.01
1
NIL
VERTICAL

BUTTON
1264
985
1319
1018
NIL
update
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1178
1045
1252
1090
NIL
num-games
0
1
11

INPUTBOX
1177
982
1254
1042
game-num
0
1
0
Number

INPUTBOX
253
13
318
76
period
300
1
0
Number

SWITCH
1634
94
1750
127
asymmetric
asymmetric
1
1
-1000

SLIDER
1638
129
1671
277
red-payoff-sigma
red-payoff-sigma
1
5
1.5
.1
1
NIL
VERTICAL

SWITCH
1812
759
2037
792
random-initial-game-weights
random-initial-game-weights
1
1
-1000

SLIDER
1812
719
1984
752
top-pr-x-pct
top-pr-x-pct
0
200
120
1
1
%
HORIZONTAL

SWITCH
1812
679
2026
712
old-weighted-payoff-methods
old-weighted-payoff-methods
0
1
-1000

SLIDER
194
13
227
202
max-ticks
max-ticks
50
10000
1000
50
1
NIL
VERTICAL

SWITCH
1814
633
1904
666
debug
debug
1
1
-1000

SLIDER
1672
129
1705
278
payoff-intensity
payoff-intensity
0
1
1
.1
1
NIL
VERTICAL

SLIDER
1707
129
1740
279
green-red-offset
green-red-offset
-3
3
0.1
.01
1
NIL
VERTICAL

PLOT
422
939
686
1081
Possible Payoffs - A
NIL
NIL
-3.0
3.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 false "" ""

PLOT
695
937
959
1079
Possible Payoffs - B
NIL
NIL
-3.0
3.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 false "" ""

MONITOR
507
1084
570
1129
mean
mean-payoff-A
3
1
11

MONITOR
779
1079
847
1124
mean
mean-payoff-B
3
1
11

MONITOR
422
1084
497
1129
% positive
pct-positive-payoff-A * 100
1
1
11

MONITOR
695
1080
767
1125
% positive
pct-positive-payoff-B * 100
2
1
11

PLOT
1107
305
1299
428
Actual Payoffs-A
NIL
NIL
-10.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

PLOT
1363
304
1555
428
Actual Payoffs-B
NIL
NIL
-10.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

MONITOR
1045
339
1109
384
mean
focal-agent-A-avg-payoff
3
1
11

MONITOR
1300
342
1364
387
mean
focal-agent-B-avg-payoff
3
1
11

SLIDER
199
424
351
457
num-red-moves
num-red-moves
10
400
10
1
1
NIL
HORIZONTAL

SLIDER
202
379
355
412
num-green-moves
num-green-moves
10
400
10
1
1
NIL
HORIZONTAL

SLIDER
199
499
398
532
red-diversity
red-diversity
0
1
0.4
.1
1
NIL
HORIZONTAL

SLIDER
199
464
398
497
green-diversity
green-diversity
0
1
0.4
.1
1
NIL
HORIZONTAL

SLIDER
5
94
172
127
num-green-agents
num-green-agents
1
20
1
1
1
NIL
HORIZONTAL

SLIDER
5
133
170
166
num-red-agents
num-red-agents
0
8
1
1
1
NIL
HORIZONTAL

SLIDER
1553
28
1726
61
num-green-v-red
num-green-v-red
1
20
1
1
1
NIL
HORIZONTAL

SLIDER
1554
60
1727
93
num-green-v-green
num-green-v-green
1
20
1
1
1
NIL
HORIZONTAL

TEXTBOX
1562
13
1671
33
Payoff Matricies
11
0.0
1

TEXTBOX
1539
860
1668
890
Move Probabilities\n(all agents)
11
0.0
1

MONITOR
1300
385
1364
430
sd
focal-agent-B-sd-payoff
3
1
11

MONITOR
1045
384
1109
429
sd
focal-agent-A-sd-payoff
3
1
11

PLOT
409
353
1041
532
Moving Average Mean Payoffs
NIL
NIL
0.0
10.0
-0.3
0.3
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

PLOT
409
530
1041
703
Moving Average SD Payoffs
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

BUTTON
1040
933
1095
967
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
1042
974
1097
1008
NIL
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

MONITOR
317
13
404
58
NIL
ticks
0
1
11

SWITCH
317
138
407
171
lock-seed
lock-seed
1
1
-1000

MONITOR
1014
115
1064
160
A
[id] of focal-agent-A
0
1
11

MONITOR
1013
288
1063
333
B
[id] of focal-agent-B
0
1
11

TEXTBOX
18
968
178
991
Infrastructure Investments
11
0.0
1

SLIDER
54
993
87
1175
green-infrastr-span
green-infrastr-span
10
400
100
1
1
NIL
VERTICAL

SLIDER
90
993
123
1175
green-infrastr-diversity
green-infrastr-diversity
0
1
0.7
.1
1
NIL
VERTICAL

SLIDER
15
993
48
1174
num-green-infrastructure
num-green-infrastructure
1
10
5
1
1
NIL
VERTICAL

SLIDER
220
992
253
1175
num-red-infrastructure
num-red-infrastructure
1
10
5
1
1
NIL
VERTICAL

SLIDER
259
992
292
1175
red-infrastr-span
red-infrastr-span
10
400
100
1
1
NIL
VERTICAL

SLIDER
295
992
328
1175
red-infrastr-diversity
red-infrastr-diversity
0
1
0.7
.1
1
NIL
VERTICAL

TEXTBOX
15
1178
155
1201
Capability Investments
11
0.0
1

SLIDER
15
1194
48
1369
num-green-capabilities
num-green-capabilities
1
20
10
1
1
NIL
VERTICAL

SLIDER
223
1194
256
1368
num-red-capabilities
num-red-capabilities
1
20
10
1
1
NIL
VERTICAL

SLIDER
54
1194
87
1369
green-capability-span
green-capability-span
10
400
50
1
1
NIL
VERTICAL

SLIDER
260
1194
293
1368
red-capability-span
red-capability-span
10
400
50
1
1
NIL
VERTICAL

SLIDER
94
1194
127
1369
green-cap-diversity
green-cap-diversity
0
1
1
.1
1
NIL
VERTICAL

SLIDER
295
1194
328
1368
red-cap-diversity
red-cap-diversity
0
1
1
.1
1
NIL
VERTICAL

SLIDER
128
993
161
1175
gr-infr-innovation-rate
gr-infr-innovation-rate
0
100
1
1
1
NIL
VERTICAL

SLIDER
330
992
363
1175
red-infr-innovation-rate
red-infr-innovation-rate
0
100
1
1
1
NIL
VERTICAL

SLIDER
375
992
408
1369
red-appropriation-pr
red-appropriation-pr
0
.3
0
0.005
1
NIL
VERTICAL

SLIDER
132
1194
165
1369
gr-cap-innovation-rate
gr-cap-innovation-rate
0
100
1
1
1
NIL
VERTICAL

SLIDER
333
1194
366
1368
red-cap-innovation-rate
red-cap-innovation-rate
0
100
1
1
1
NIL
VERTICAL

TEXTBOX
12
172
139
191
Agent Learning
11
0.0
1

TEXTBOX
204
362
299
381
Possible Moves
11
0.0
1

SLIDER
170
992
203
1370
green-disarm-pr
green-disarm-pr
0
.3
0
0.005
1
NIL
VERTICAL

SWITCH
242
942
372
975
investments?
investments?
1
1
-1000

BUTTON
1105
974
1160
1007
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

OUTPUT
958
1203
1211
1468
4

MONITOR
352
369
410
414
#
mean green-num-moves-list
1
1
11

MONITOR
352
414
410
459
#
mean red-num-moves-list
1
1
11

SLIDER
980
1117
1163
1150
gr-learning-cycle
gr-learning-cycle
1
100
1
1
1
ticks
HORIZONTAL

SLIDER
4
685
194
718
green-distortion
green-distortion
0
1
0
0.1
1
NIL
HORIZONTAL

SLIDER
4
763
194
796
green-noise
green-noise
0
1
0
.01
1
NIL
HORIZONTAL

SWITCH
1347
1087
1522
1120
random-initial-pr-x?
random-initial-pr-x?
1
1
-1000

SLIDER
4
437
188
470
start-novelty-at
start-novelty-at
0
1000
10
10
1
ticks
HORIZONTAL

SLIDER
4
482
187
515
green-novel-possibilities
green-novel-possibilities
0
10
1
1
1
NIL
HORIZONTAL

SLIDER
5
520
188
553
red-novel-possibilities
red-novel-possibilities
0
10
1
1
1
NIL
HORIZONTAL

SWITCH
87
364
185
397
novelty?
novelty?
1
1
-1000

SLIDER
4
398
189
431
pr-novelty
pr-novelty
0
1
0.5
.1
1
NIL
HORIZONTAL

TEXTBOX
12
379
65
402
Novelty
11
0.0
1

TEXTBOX
9
560
168
588
Risk Assessment,\nIgnorance, and Uncertainty
11
0.0
1

CHOOSER
3
628
198
673
green-rule
green-rule
"probabilistic risk assessment" "H-M-L risk assessment" "binary assessment"
1

CHOOSER
205
629
403
674
red-rule
red-rule
"probabilistic risk assessment" "H-M-L risk assessment" "binary assessment"
0

SLIDER
8
807
195
840
green-blind-spots
green-blind-spots
0
100
50
5
1
%
HORIZONTAL

SLIDER
0
725
194
758
green-oppon-uncertainty
green-oppon-uncertainty
0
1
0.2
.1
1
NIL
HORIZONTAL

SLIDER
207
687
400
720
red-distortion
red-distortion
0
1
0
.1
1
NIL
HORIZONTAL

SLIDER
208
764
400
797
red-noise
red-noise
0
1
0
.01
1
NIL
HORIZONTAL

SLIDER
208
807
400
840
red-blind-spots
red-blind-spots
0
100
0
5
1
%
HORIZONTAL

SLIDER
205
724
400
757
red-oppon-uncertainty
red-oppon-uncertainty
0
1
0
.1
1
NIL
HORIZONTAL

MONITOR
50
839
118
884
avg #
avg-green-blind-spots
3
1
11

MONITOR
269
839
339
884
avg #
avg-red-blind-spots
3
1
11

SWITCH
212
549
342
582
uncertainty?
uncertainty?
0
1
-1000

TEXTBOX
124
858
163
881
of 400
11
0.0
1

TEXTBOX
348
859
392
882
of 400
11
0.0
1

SLIDER
9
883
199
916
green-pr-discovery
green-pr-discovery
0
1
0.05
.005
1
NIL
HORIZONTAL

SLIDER
209
883
403
916
red-pr-discovery
red-pr-discovery
0
1
0
.05
1
NIL
HORIZONTAL

SLIDER
3
590
207
623
green-rating-threshold
green-rating-threshold
0
3
1
.01
1
NIL
HORIZONTAL

SLIDER
210
589
400
622
red-rating-threshold
red-rating-threshold
0
3
0.1
.01
1
NIL
HORIZONTAL

SLIDER
188
258
403
291
green-imitate-bp
green-imitate-bp
0
1
0.5
.05
1
NIL
HORIZONTAL

PLOT
1553
279
1745
429
Mean Payoffs
agent #
NIL
0.0
2.0
-0.1
0.1
true
false
"" ""
PENS
"default" 1.0 1 -10899396 true "" ""

SLIDER
189
289
403
322
red-imitate-bp
red-imitate-bp
0
1
0
.05
1
NIL
HORIZONTAL

TEXTBOX
189
207
293
226
Best Practices
11
0.0
1

SLIDER
189
323
404
356
leader-threshold-bp
leader-threshold-bp
0
100
20
1
1
%
HORIZONTAL

CHOOSER
312
213
405
258
bp-mode
bp-mode
"none" "avg all" "min all" "max any"
2

SLIDER
235
78
268
203
start-bp
start-bp
0
2000
100
50
1
NIL
VERTICAL

SWITCH
189
223
293
256
aspire?
aspire?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

Replicates the model in "Complex dynamics in learning complicated games" by Galla and Farmer (2012). (http://www.pnas.org/cgi/doi/10.1073/pnas.1109672110)

This model shows the dynamics of strategies when two or more agents try to play complicated games (large number of possible moves, bounded rationality about long-term payoffs, etc.).  The payoff matrices of the games are generated randomly, based on parameters described below.  This allows experiments over a large number of games with similar qualities, without making assumptions about the detailed structure of the game (as is typical in analytic Game Theory).

The purpose of the model is to explore the conditions that fit traditional Game Theory analysis (e.g. unique equilibrium) and those that do not (multiple equilibria, chaotic dynamics).  And given the complexity of the game, the model allows us to explore how well this learning model works to enable players to evolve cooperative solutions, even when the payoff matrix might be unappealing.

## HOW IT WORKS
Every tick, each agent choses a single "move" (indexed by x = 1..N) by drawing at random according to their current probabilities ("Pr(move)" or "x" in notation by Galla & Farmer). As in all Game Theory settings, their payoff depends both on their own choice of moves and that of other agents. Their payoff is added to their cumulative total for charting purposes. Finally, each agent updates their probabilities using "experience weighted learning", as described in Galla & Farmer (2012) 

The grid shows the payoff matrix for the two focal agents, "A" and "B", with each cell in the matrix color coded according to the pair of payoffs.  Payoffs can range from -3.0 to +3.0.  The color code is:

* Red = positive for A, negative for B
* Green = positive for B, negative for A
* Yellow = positive for both A and B
* Dark Brown = negative for both A and B

When Gamma is set to -1.0 (perfect negative correlation), you will only see shades of red or green.  When Gamma is set to 1.0 (perfect positive correlation) you will only see shades of yellow (to olive and dark brown).  When Gamma is set to zero, you will see the full range of colors.

The black square on the grid highlights the current payoff, given the move choices of agents A and B.  The line drawn links the current payoff to the payoff in the previous tick.

## HOW TO USE IT

Click "Reset" to initialize the parameters in their default settings.

Click "Setup" to load the parameters and to initialize the payoff matrices.

Click "Go" to run the model continuously.  Unclick to stop the model

Click "Step" to single step the model.

Set "num-agents" (currently fixed at 2, but will be expanded to 100 in later versions.)

Set "num-possible-moves" (N), which is the number of possible moves for each agent, ranging from 10 to 100.  (Galla & Farmer 2012 use 50)

"Gamma" is the parameter that controls the correlation between agent payoffs.  -1.0 is perfect negative correlation (i.e. zero sum game).  +1.0 is perfect positive correlation (i.e. positive sum game). 0.0 is uncorrelated.

"alpha" is the parameter that controls agent memory (i.e. influence of past probabilities) when updating their preference probabilities.  0 is unlimited memory (no decay in the influence of past probabilities), while 1.0 is no memory (100% decay, meaning no influence of past probabilities).

"beta" is the parameter that controls randomness associated with the move choice decision.  0 is fully random with equal probability for each move.  Infinity (i.e. large positive number) is a deterministic choice for the move with the highest "attractiveness".  Galla & Farmer 2012 fix this at 0.07.

"learning-mode" is either "experience weighted", which is the Galla & Farmer model, or "none", which is no updating.

## THINGS TO NOTICE

The primary results to notice are the bar graphs for "Pr(move)" for the two focal agents, A and B. Do they settle into a stable pattern? (which would indicate an equilibrium)  Or do they oscillate regularly? (which would incidate limit cycles)  Or are the oscillations chaotic? (seemingly random)

It is interesting to compare the effectiveness of learning on cumulative payoffs, compared to no learning.  Can the agents, in effect, cooperate to make the most of the payoff options available?  With shorter memories (i.e. higher values of alpha), agents can reach an equilibrium in probabilities where they prefer a broad range of moves, but fail to home in on the few (or one) move that might yield the best payoff for all agents (i.e. a bright yellow cell in the payoff matrix).

## THINGS TO TRY

Try varying Gamma and alpha to see whether the probabilities Pr(move) demonstrate equilibria, limit cycles, or chaos. (Galla & Farmer 2012, p 2 and 3 show various parameter settings for Gamma and alpha that yeild interesting results)

Try varying "num-possible-moves" (N) to see if the complexity of the game has any effect.


## EXTENDING THE MODEL

**Detect equilibrium, and then stop.**  Currently the model runs forever (i.e. until it is stopped manually).  It would be useful to monitor changes in each players move probabilities and then stop the simulation when those probabilities stopped changing.

**Auto-detect "interesting" Pr(move) indices for plotting.**  Currently, the experimentor manually sets the index values for plotting Pr(move) in the time series.  Ideally, you'd like them to be "interesting" (i.e. large value and/or varying significantly with time). It would be good to detect this automatically after some number of ticks (~1,000).

**Support more than two agents.**  Galla & Farmer (2012) include multiple players in their setup, but then reduce to only two players in their model and results.  They don't describe how to implement multiple players, especially in light of the Gamma parameter which is the correlation in payoffs between any two players.  With three or more players, it is not possible to have all the pair-wise correlations to be negative. One approach would be to have C(M,2) 2-player games, where C(M,2) is the number combinations of 2-player games with M players.  (The formula for combinations is C(n,r) = n! / ( r! (n - r)! ), where n is the number of entities and r is the number in the subset.)  For various numbers of players: 

* C(2,2) = 1
* C(4,2) = 6
* C(10,2) = 45
* C(20,2) = 190
* C(100,2) = 4950

As you can see, the number of combinations grows rapidly with the total number of players. Since each payoff matrix is N X N, having a large number of players becomes infeasable on ordinary personal computers due to memory limitations.  One viable way of simplifying would be to not have different payoff matrices for each and every pair-wise game.  You could even have just two -- one for a positively correlated game and one for the complementary negatively correlated game.  Then each player plays both sides of each game, depending on the particular opponent.

**Probabilistic payoffs.** In some settings (e.g. cyber security) the payoff from moves is not deterministic, and instead is probabilistic.  This could be modeled by using a random draw from a given probability distribution.  It would be interesting to see how this would change the results if payoff distributions had long tails (i.e. enabling extreme payoffs on rare occasions).

**Uncertainty and/or imperfect knowledge regarding payoffs.** Along the same lines, it would be interesting to see if results would change if players had imperfect knowledge of their payoffs for a given move, or if their was uncertainty involved.  It might be possible to incorporate this into the "experience weighted learning" model.

**Sequential and/or combinatorial game.** The current design is a one-shot iterative game.  Many settings (e.g. investment sequencing) require sequential and/or combinatorial game structure.

## NETLOGO FEATURES

Uses Array and Matrix extensions.

## RELATED MODELS

The Galla & Farmer (2012) model is aligned with Evolutionary Game Theory. There are a number of NetLogo models that implement some version of Evolutionary Game Theory.  Examples include:

* GameTheory, by Rick O'Gorman (Submitted: 07/22/2014)
  http://ccl.northwestern.edu/netlogo/models/community/GameTheory
* Prisoner Dilemma N-Person with Strategies, by Tan Yongzhi (Submitted: 11/14/2012)
  http://ccl.northwestern.edu/netlogo/models/community/PD%20N-Person%20with%20Strategies
* FriendshipGameRev_1_0_25, by David S. Dixon (Submitted: 10/15/2011)
  http://ccl.northwestern.edu/netlogo/models/community/FriendshipGameRev_1_0_25
* Evolutionary_Game_Theory_Big_Bird_Replicator_Dynamic, by Jeff Russell (Submitted: 09/06/2007)
  http://ccl.northwestern.edu/netlogo/models/community/Evolutionary_Game_Theory_Big_Bird_Replicator_Dynamic

However, none of these models is focused on complex games (i.e. large strategy space) and associatied learning mechanisms.  The closest are probably those involving replicator dynamics (e.g. Russell 2007).

## CREDITS AND REFERENCES

Written by Russell C. Thomas (2016), based on paper and supplementary material:

Galla, T., & Farmer, J. D. (2013). Complex dynamics in learning complicated games. Proceedings of the National Academy of Sciences, 110(4), 1232–1236. http://doi.org/10.1073/pnas.1109672110

Cyber Security Game by Russell C. Thomas is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.


For discussion and analysis of this model, see this blog post:

* http://exploringpossibilityspace.blogspot.com/2016/01/complex-dynamics-in-learning.html
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

circle 3
false
0
Circle -7500403 false true 0 0 300
Circle -7500403 false true 2 2 297
Circle -7500403 false true 12 12 277
Circle -7500403 false true 23 23 255
Circle -7500403 false true 33 33 234
Circle -7500403 false true 44 44 212
Circle -7500403 false true 54 54 192
Circle -7500403 false true 65 65 170
Rectangle -7500403 false true 90 90 210 210
Rectangle -7500403 false true 75 75 225 225
Rectangle -7500403 false true 105 105 195 195
Circle -7500403 false true 86 86 127

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

square 3
false
0
Rectangle -1 true false 30 30 270 75
Rectangle -1 true false 30 225 270 270
Rectangle -1 true false 30 30 75 270
Rectangle -1 true false 225 30 270 270
Rectangle -7500403 true true 75 75 225 225

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
NetLogo 5.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[cum-payoff] of focal-agent-A</metric>
    <metric>[cum-payoff] of focal-agent-B</metric>
    <enumeratedValueSet variable="max-ticks">
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="sim-seed" first="1" step="1" last="25"/>
    <enumeratedValueSet variable="setup-seed">
      <value value="0"/>
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-agents">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-agents">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-moves">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-green">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-red">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="investments?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="period">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymmetric">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-appropriation-pr">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-B">
      <value value="&quot;9\n18\n23\n45&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-red-offset">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-red">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model">
      <value value="&quot;Thomas 2016&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-possible-moves">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="game-num">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-disarm-pr">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-payoff-sigma">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff-intensity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-weighted-payoff-methods">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-diversity">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-est-noise">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-red">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-green">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-underestimate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;2-agent payoff matrix&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-green">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-red">
      <value value="-0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-moves">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-learning-cycle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-green">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-model">
      <value value="&quot;experience weighted&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-pr-x-pct">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-initial-game-weights">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-A">
      <value value="&quot;6\n12\n15\n30&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="payoff-time-series" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[current-payoff] of item 0 agent-list</metric>
    <metric>[current-payoff] of item 1 agent-list</metric>
    <enumeratedValueSet variable="green-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-initial-pr-x?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="investments?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-payoff-sigma">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-red">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-est-noise">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-disarm-pr">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-model">
      <value value="&quot;experience weighted&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-initial-game-weights">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-underestimate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-moves">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-possible-moves">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-learning-cycle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-green">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-green">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-red-offset">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-agents">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-pr-x-pct">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff-intensity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="game-num">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-red">
      <value value="-0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-green">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-green">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-diversity">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-moves">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-red">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sim-seed">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-agents">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-A">
      <value value="&quot;6\n12\n15\n30&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-red">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-B">
      <value value="&quot;6\n12\n15\n30&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;2-agent payoff matrix&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-weighted-payoff-methods">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="period">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-seed">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymmetric">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-appropriation-pr">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model">
      <value value="&quot;Thomas 2016&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="payoff-time-series2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[current-payoff] of item 0 agent-list</metric>
    <metric>[current-payoff] of item 1 agent-list</metric>
    <metric>[current-payoff] of item 2 agent-list</metric>
    <metric>[current-payoff] of item 3 agent-list</metric>
    <metric>[current-payoff] of item 4 agent-list</metric>
    <enumeratedValueSet variable="green-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-initial-pr-x?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="investments?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-capability-span">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-payoff-sigma">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-red">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-est-noise">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-infrastructure">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-disarm-pr">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-model">
      <value value="&quot;experience weighted&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-initial-game-weights">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-underestimate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-moves">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-possible-moves">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-learning-cycle">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-green">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-span">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-green">
      <value value="0.0010"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-red-offset">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-red-agents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-pr-x-pct">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff-intensity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-infrastr-diversity">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="game-num">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-capabilities">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-cap-diversity">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-red">
      <value value="-0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-v-green">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gamma-green-v-green">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-diversity">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-moves">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta-red">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sim-seed">
      <value value="23"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-green-agents">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-A">
      <value value="&quot;6\n12\n15\n30&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-agents">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha-red">
      <value value="9.0E-4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-IDs-B">
      <value value="&quot;6\n12\n15\n30&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="display-mode">
      <value value="&quot;2-agent payoff matrix&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="old-weighted-payoff-methods">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta">
      <value value="0.07"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-infr-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="period">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gr-cap-innovation-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setup-seed">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="asymmetric">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-appropriation-pr">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="model">
      <value value="&quot;Thomas 2016&quot;"/>
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
