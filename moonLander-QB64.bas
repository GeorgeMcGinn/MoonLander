$CONSOLE:ONLY
' * moonLander    Version 1.0  04/10/2025
' ***************************************************************************************
' *       PROGRAM: moonLander
' *        AUTHOR: George McGinn
' *                <gjmcginn@icloud.com>
' *  DATE WRITTEN: 04/10/2025
' *       VERSION: 1.0
' *       PROJECT: Apollo Moon Lander Simulator
' *
' *   DESCRIPTION: Interactive game where you pilot the Lunar Module (LEM) after an 
' *                Apollo Guidance Computer (AGC) failure at 7,500 ft. Emergency 
' *                burn errors leave random initial speeds (vDown: 200-700 ft/s, 
' *                horizSpeed: 50-200 ft/s). Manually adjust vBurn and hBurn to land 
' *                safely or abort with ascent fuel. There is also a time delay in
' *                displaying the correction to the user. The time delay is 6.6 seconds
' *                (signal delay of 2.6 seconds and 4 seconds for Ground Control to
' *                process the correction) and is added to the time when the correction
' *                is evaluated. The correction is displayed at the time of the 
' *                evaluation plus 6.6 seconds.
' *
' * Written by George McGinn
' * 
' * Copyright (C)2025 George McGinn - All Rights Reserved
' * Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)   
' * https://creativecommons.org/licenses/by-nc-sa/4.0/
' * You are allowed to copy, distribute, remix, adapt, and build upon your work, 
' * but only for non-commercial purposes, and must credit me and share your 
' * adaptations under the same license. 
' *
' * Version 1.0 - Created 04/10/2025
' *
' * CHANGE LOG
' ***************************************************************************************
' * 04/10/2025 GJM - New Program. Version 1.0
' ***************************************************************************************
' * Copyright (C)2025 by George McGinn.  All Rights Reserved
' *
' * This program is free software: you can redistribute it and/or modify
' * it under the terms of the GNU General Public License as published by
' * the Free Software Foundation.   
' ***************************************************************************************

' ### Define the Correction Class
' In Python, we replace the C struct with a class to hold correction data.
' In QB64, we use a TYPE definition to mimic the class structure.
TYPE Correction
    evalTime       AS DOUBLE      ' Time when state was evaluated (end of burn)
    displayTime    AS DOUBLE      ' Time to display correction (evalTime + 6.6)
    vBurnDiff      AS DOUBLE
    hBurnDiff      AS DOUBLE
    isConfirmation AS INTEGER     ' 0 for correction, 1 for confirmation
END TYPE

' ### RK4 Helper Functions (adapted to QB64 from C)
DECLARE SUB compute_vertical_derivatives (state() AS DOUBLE, derivatives() AS DOUBLE, netAcc AS DOUBLE)
DECLARE SUB compute_horizontal_derivatives (state() AS DOUBLE, derivatives() AS DOUBLE, horizAcc AS DOUBLE)
DECLARE SUB rk4_vertical (altitude AS DOUBLE, vDown AS DOUBLE, dt AS DOUBLE, netAcc AS DOUBLE)
DECLARE SUB rk4_horizontal (horizPos AS DOUBLE, horizSpeed AS DOUBLE, dt AS DOUBLE, horizAcc AS DOUBLE)

' ### Main Program Variables
DIM SHARED altitude        AS DOUBLE
DIM SHARED vDown           AS DOUBLE
DIM SHARED horizPos        AS DOUBLE
DIM SHARED horizSpeed      AS DOUBLE
DIM SHARED descentFuelMass AS DOUBLE
DIM SHARED mass            AS DOUBLE
DIM SHARED currentTime     AS DOUBLE

' Additional Variables
DIM duration          AS DOUBLE
DIM vBurn             AS DOUBLE
DIM hBurn             AS DOUBLE
DIM delta_v           AS DOUBLE
DIM lunarOrbitalSpeed AS DOUBLE
DIM steps             AS INTEGER
DIM fuelUsed          AS DOUBLE
DIM thrustAcc         AS DOUBLE
DIM netAcc            AS DOUBLE
DIM horizAcc          AS DOUBLE
DIM i, j, k           AS INTEGER
DIM transmissionDelay AS DOUBLE
DIM processingDelay   AS DOUBLE
DIM numPending        AS INTEGER
DIM pendingCorrections(0 TO 99) AS Correction  ' List replaces Correction pendingCorrections[100] with fixed-size array

' Constants
CONST gravity = 5.33136483       ' ft/s^2 (lunar gravity)
CONST standardGravity = 32.174   ' ft/s^2 (standard gravity)
CONST Vex = 10000                ' ft/s (exhaust velocity)
CONST maxVerticalBurn = 250      ' lbs/s
CONST maxHorizBurn = 10          ' lbs/s
CONST timeLimit = 600            ' seconds
CONST small_dt = 0.1             ' simulation time step

' --- Initial Conditions (Descent Stage)
CONST descentDryMass = 4700      ' lb (descent stage dry)
CONST descentFuelMassInit = 1500 ' lb (descent fuel)

' --- Ascent Stage Parameters (for abort)
CONST ascentDryMass = 4850       ' lb (ascent stage dry)
CONST ascentFuelMass = 5187      ' lb (ascent fuel)
CONST ascentVex = 10000          ' ft/s
CONST minAltitudeForAbort = 100  ' ft (minimum altitude to safely abort)

' Temporary variables for projection
DIM projectedAltitude  AS DOUBLE
DIM projectedVDOWN     AS DOUBLE
DIM projectedHSpeed    AS DOUBLE
DIM tempMass           AS DOUBLE
DIM tempFuel           AS DOUBLE
DIM projection_dt      AS DOUBLE
DIM maxProjectionSteps AS INTEGER 
DIM stepCount          AS INTEGER
projection_dt = 0.1              ' Small time step for projection
maxProjectionSteps = 10000       ' Limit iterations to prevent infinite loop
stepCount = 0


' Define safe landing targets
DIM targetTouchdownSpeed AS DOUBLE 
DIM targetHSpeed         AS DOUBLE 
DIM tolerance            AS DOUBLE 
DIM vDownError           AS DOUBLE
DIM hSpeedError          AS DOUBLE
DIM vBurnAdjustment      AS DOUBLE
DIM hBurnAdjustment      AS DOUBLE
targetTouchdownSpeed = 5.0  ' ft/s
targetHSpeed = 0.0  ' ft/s (ideal horizontal speed)
tolerance = 5.0  ' ft/s tolerance for safe landing

' Initialize Variables
descentFuelMass = descentFuelMassInit  ' lb (descent fuel)
mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass  ' Total mass includes both stages: 16,237 lbs
DIM tempMassSlugs        AS DOUBLE
tempMassSlugs = mass / standardGravity  ' slugs

altitude = 7500                  ' feet
RANDOMIZE TIMER                  ' Python equivalent of random.seed(time.time())
vDown = 200 + INT(RND * 501)     ' 200-700 ft/s (rand() % 501 gives 0-500)
horizSpeed = 50 + INT(RND * 151) ' 50-200 ft/s (rand() % 151 gives 0-150)
horizPos = 0
currentTime = 0.0
numPending = 0                   ' Tracks number of pending corrections

' Time Delay for feedback
transmissionDelay = 2.6          ' Transmission time in seconds
processingDelay = 4              ' Processing time in seconds (adjusted to match total delay of 6.6s)

' #### Game Introduction 
PRINT "========================================================="
PRINT "          APOLLO LUNAR LANDER SIMULATOR"
PRINT "========================================================="
PRINT
PRINT "Welcome to the Apollo Lunar Lander Simulator!"
PRINT "Version 1.0.0 - Created by George McGinn - 04/10/2025"
PRINT
PRINT "You are the pilot of the Lunar Module (LEM) when the AGC"
PRINT "fails at 7500 ft due to prior burn errors. Initial speeds"
PRINT "are random (vDown: 200-700 ft/s, horizSpeed: 50-200 ft/s)."
PRINT
PRINT "Starting Conditions:"
PRINT "  - Altitude: 7,500 ft"
PRINT USING "  - Vertical Speed: ###.## ft/s (downward)"; vDown
PRINT USING "  - Horizontal Speed: ###.## ft/s"; horizSpeed
PRINT USING "  - Descent Fuel: #### lbs"; descentFuelMass
PRINT USING "  - Ascent Fuel (for abort): #### lbs"; ascentFuelMass
PRINT USING "  - Descent Stage Dry Mass: #### lbs"; descentDryMass
PRINT USING "  - Ascent Stage Dry Mass: #### lbs"; ascentDryMass
PRINT USING "  - Mass Slugs: ###.### slugs"; tempMassSlugs
PRINT
PRINT "Controls:"
PRINT "  - Duration: Time (seconds) to apply burns (-1 to abort)"
PRINT "  - vBurn: Vertical burn rate (0 to 250 lbs/s)"
PRINT "  - hBurn: Horizontal burn rate (-10 to 10 lbs/s)"
PRINT
PRINT "Objective:"
PRINT "Land with vDown <= 5 ft/s and |horizSpeed| <= 5 ft/s for a"
PRINT "perfect landing. Receive feedback after each burn to adjust"
PRINT "your trajectory. Abort if needed, but ensure you can reach orbit!"
PRINT
PRINT "Note: The game also enforces a time delay that the real astronauts."
PRINT USING "      experienced. The time delay is #.# seconds (signal delay of"; transmissionDelay + processingDelay
PRINT USING "      #.# seconds and #.# seconds for Ground Control to process the"; transmissionDelay; processingDelay
PRINT "      correction)."
PRINT
PRINT "Ready to land on the Moon? Let's begin!"
PRINT "========================================================="
PRINT
SLEEP 5  ' Pause for 5 seconds before starting the simulation


PRINT USING "Lunar Lander: AGC failed. Altitude=#### ft, vDown=#### ft/s, hSpeed=#### ft/s"; altitude; vDown; horizSpeed
PRINT "Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10), separated by commas"

' #### Main Simulation Loop
DO WHILE altitude > 0
    ' Step 1: Display Current State
    PRINT USING "t=##.##s  Alt=#####.###  vDown=####.###  hPos=####.###  hSpeed=####.###  Fuel=####.###"; _
        currentTime; altitude; vDown; horizPos; horizSpeed; descentFuelMass

    ' Step 2: Prompt for User Input
    INPUT ">> ", duration, vBurn, hBurn               ' QB64 INPUT reads comma-separated values
    IF duration = 0 AND vBurn = 0 AND hBurn = 0 THEN  ' Check for invalid input
        PRINT "Invalid input. Please enter three numbers separated by commas."
        GOTO nextIteration
    END IF

    ' Step 3: Handle Abort Condition
    IF duration < 0 THEN
        PRINT "Aborting landing..."
        IF altitude < minAltitudeForAbort THEN
            PRINT "Too low to abort safely! Crashing into the surface."
            altitude = 0
            EXIT DO
        ELSEIF ascentFuelMass <= 0 THEN
            PRINT "No ascent fuel left! Cannot reach orbit. Crashing."
            altitude = 0
            EXIT DO
        ELSE
            delta_v = ascentVex * LOG((ascentDryMass + ascentFuelMass) / ascentDryMass)
            lunarOrbitalSpeed = 5512  ' ft/s (lunar orbital speed)
            IF delta_v >= lunarOrbitalSpeed - ABS(horizSpeed) THEN
                COLOR 10  ' Green text
                PRINT USING "Abort successful. Achieved lunar orbit with ####.## ft/s delta-v."; delta_v
                COLOR 15  ' Reset to white
                EXIT DO
            ELSE
                COLOR 12  ' Red text
                PRINT USING "Abort failed. Insufficient delta-v (####.## ft/s) to reach orbit."; delta_v
                PRINT "Continuing landing with remaining fuel."
                COLOR 15  ' Reset to white
            END IF
        END IF
    END IF

    ' Step 4: Validate User Inputs 
    IF vBurn < 0 OR vBurn > maxVerticalBurn OR hBurn < -maxHorizBurn OR hBurn > maxHorizBurn THEN
        PRINT "Invalid burn rates."
        GOTO nextIteration
    END IF

    ' Step 5: Simulate the Burn Duration
    steps = INT(duration / small_dt)
    FOR i = 1 TO steps
        IF altitude <= 0 THEN EXIT FOR
        fuelUsed = (vBurn + ABS(hBurn)) * small_dt
        IF fuelUsed > descentFuelMass THEN fuelUsed = descentFuelMass
        descentFuelMass = descentFuelMass - fuelUsed
        mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass
        mass_slugs = mass / standardGravity  ' Earth's Standard Gravity (32.174) in ft/s²

        ' Vertical thrust
        mass_flow_rate_vertical = vBurn / standardGravity         ' slugs/s
        thrustForce_vertical = mass_flow_rate_vertical * Vex      ' lbs
        thrustAcc_vertical = thrustForce_vertical / mass_slugs    ' ft/s² upward
        netAcc_vertical = gravity - thrustAcc_vertical            ' gravity downward

        ' Horizontal thrust
        mass_flow_rate_horizontal = ABS(hBurn) / standardGravity  ' slugs/s
        thrustForce_horizontal = mass_flow_rate_horizontal * Vex  ' lbs
        thrustAcc_horizontal = SGN(hBurn) * thrustForce_horizontal / mass_slugs  ' ft/s², using SGN for direction

        CALL rk4_vertical(altitude, vDown, small_dt, netAcc_vertical)
        CALL rk4_horizontal(horizPos, horizSpeed, small_dt, thrustAcc_horizontal)
        currentTime = currentTime + small_dt

        ' Provide Feedback after time delay
        j = 0
        WHILE j < numPending
            IF currentTime >= pendingCorrections(j).displayTime THEN
                IF pendingCorrections(j).isConfirmation = 1 THEN
                    COLOR 14  ' Yellow text for Mission Control feedback
                    PRINT USING "[Mission Control: on t=###.##s (received on t=###.##s)] Burn rates are nominal."; _
                        pendingCorrections(j).evalTime; pendingCorrections(j).displayTime
                    COLOR 15  ' Reset to white
                ELSE
                    IF pendingCorrections(j).vBurnDiff > 0 THEN
                        COLOR 14
                        PRINT USING "[Mission Control: on t=###.##s (received on t=###.##s)] Increase vBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; pendingCorrections(j).vBurnDiff
                        COLOR 15
                    ELSEIF pendingCorrections(j).vBurnDiff < 0 THEN
                        COLOR 14
                        PRINT USING "[Mission Control: on t=###.##s (received on t=###.##s)] Decrease vBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; -pendingCorrections(j).vBurnDiff
                        COLOR 15
                    END IF
                    IF pendingCorrections(j).hBurnDiff > 0 THEN
                        COLOR 14
                        PRINT USING "[Mission Control: on t=###.##s (received on t=###.##s)] Increase hBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; pendingCorrections(j).hBurnDiff
                        COLOR 15
                    ELSEIF pendingCorrections(j).hBurnDiff < 0 THEN
                        COLOR 14
                        PRINT USING "[Mission Control: on t=###.##s (received on t=###.##s)] Decrease hBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; -pendingCorrections(j).hBurnDiff
                        COLOR 15
                    END IF
                END IF
                ' Shift array to remove processed correction
                FOR k = j TO numPending - 2
                    pendingCorrections(k) = pendingCorrections(k + 1)
                NEXT k
                numPending = numPending - 1
            ELSE
                j = j + 1
            END IF
        WEND
    NEXT i

    ' Step 6: Queue New Correction or Confirmation
    IF altitude > 0 THEN
        ' Temporary variables for projection
        projectedAltitude = altitude
        projectedVDOWN = vDown
        projectedHSpeed = horizSpeed
        tempMass = mass
        tempFuel = descentFuelMass
        tempMassSlugs = tempMass / standardGravity
        stepCount = 0

        ' Simulate descent until landing or limit reached
        WHILE projectedAltitude > 0 AND tempFuel >= 0 AND tempMass > 0 AND stepCount < maxProjectionSteps
            ' Fuel consumption
            fuelUsed = (vBurn + ABS(hBurn)) * projection_dt
            IF fuelUsed > tempFuel THEN fuelUsed = tempFuel
            tempFuel = tempFuel - fuelUsed
            tempMass = descentDryMass + tempFuel + ascentDryMass + ascentFuelMass
            IF tempMass <= 0 THEN EXIT WHILE  ' Avoid division by zero
            tempMassSlugs = tempMass / standardGravity

            ' Vertical acceleration
            mass_flow_rate_vertical = vBurn / standardGravity  ' slugs/s
            thrustForce_vertical = mass_flow_rate_vertical * Vex  ' lbs
            thrustAcc_vertical = thrustForce_vertical / tempMassSlugs  ' ft/s²
            netAcc_vertical = gravity - thrustAcc_vertical

            ' Horizontal acceleration
            mass_flow_rate_horizontal = ABS(hBurn) / standardGravity
            thrustForce_horizontal = mass_flow_rate_horizontal * Vex
            thrustAcc_horizontal = SGN(hBurn) * thrustForce_horizontal / tempMassSlugs

            ' Update state using RK4
            CALL rk4_vertical(projectedAltitude, projectedVDOWN, projection_dt, netAcc_vertical)
            ' Note: In C, horizPos is passed but not used in feedback; we use a dummy 0 here
            CALL rk4_horizontal(0, projectedHSpeed, projection_dt, thrustAcc_horizontal)
            stepCount = stepCount + 1
        WEND

        ' Calculate errors from safe landing targets
        vDownError = projectedVDOWN - targetTouchdownSpeed  ' Positive if too fast
        hSpeedError = projectedHSpeed - targetHSpeed  ' Positive if right, negative if left

        ' Suggest burn adjustments (tuned proportionality constants)
        vBurnAdjustment = vDownError * 0.1  ' lbs/s per ft/s error
        hBurnAdjustment = hSpeedError * 0.05  ' Smaller factor for horizontal

        ' Clamp adjustments to physical limits
        IF vBurn + vBurnAdjustment > maxVerticalBurn THEN vBurnAdjustment = maxVerticalBurn - vBurn
        IF vBurn + vBurnAdjustment < 0 THEN vBurnAdjustment = -vBurn
        IF hBurn + hBurnAdjustment > maxHorizBurn THEN hBurnAdjustment = maxHorizBurn - hBurn
        IF hBurn + hBurnAdjustment < -maxHorizBurn THEN hBurnAdjustment = -hBurn - maxHorizBurn  ' Corrected from C's "-hBurn + maxHorizBurn"

        ' Queue feedback
        IF ABS(vDownError) <= tolerance AND ABS(hSpeedError) <= tolerance THEN
            IF numPending < 100 THEN
                pendingCorrections(numPending).evalTime = currentTime
                pendingCorrections(numPending).displayTime = currentTime + transmissionDelay + processingDelay
                pendingCorrections(numPending).vBurnDiff = 0
                pendingCorrections(numPending).hBurnDiff = 0
                pendingCorrections(numPending).isConfirmation = 1
                numPending = numPending + 1
            END IF
        ELSE
            IF numPending < 100 THEN
                pendingCorrections(numPending).evalTime = currentTime
                pendingCorrections(numPending).displayTime = currentTime + transmissionDelay + processingDelay
                pendingCorrections(numPending).vBurnDiff = vBurnAdjustment
                pendingCorrections(numPending).hBurnDiff = hBurnAdjustment
                pendingCorrections(numPending).isConfirmation = 0
                numPending = numPending + 1
            END IF
        END IF
    END IF

nextIteration:
LOOP

' #### Evaluate Landing Outcome
IF altitude <= 0 THEN
    IF altitude < 0 THEN altitude = 0
    PRINT
    PRINT USING "Touchdown at t = ###.# s"; currentTime
    PRINT USING "Final Downward Speed: ###.## ft/s"; vDown
    PRINT USING "Final Horizontal Speed: ###.## ft/s"; horizSpeed
    IF vDown <= 5 AND ABS(horizSpeed) <= 5 THEN  ' targetTouchdownSpeed is 5
        COLOR 10  ' Green text
        PRINT "Perfect Landing! Impact speed is safe."
        COLOR 15  ' Reset to white
    ELSEIF vDown <= 15 AND ABS(horizSpeed) <= 15 THEN
        COLOR 10
        PRINT "Good Landing (minor impact)."
        COLOR 15
    ELSE
        COLOR 12  ' Red text
        PRINT "Crash Landing! Impact speed is too high."
        COLOR 15
    END IF
ELSEIF currentTime >= timeLimit THEN
    PRINT
    PRINT "Simulation aborted after reaching the time limit."
END IF

END

' ### RK4 Helper Functions (adapted to QB64 from C)
SUB compute_vertical_derivatives (state() AS DOUBLE, derivatives() AS DOUBLE, netAcc AS DOUBLE)
    derivatives(0) = -state(1)  ' d(altitude)/dt = -vDown
    derivatives(1) = netAcc     ' d(vDown)/dt = netAcc
END SUB

SUB compute_horizontal_derivatives (state() AS DOUBLE, derivatives() AS DOUBLE, horizAcc AS DOUBLE)
    derivatives(0) = state(1)  ' d(horizPos)/dt = horizSpeed
    derivatives(1) = horizAcc  ' d(horizSpeed)/dt = horizAcc
END SUB

SUB rk4_vertical (altitude AS DOUBLE, vDown AS DOUBLE, dt AS DOUBLE, netAcc AS DOUBLE)
    DIM k1(0 TO 1)         AS DOUBLE
    DIM k2(0 TO 1)         AS DOUBLE
    DIM k3(0 TO 1)         AS DOUBLE
    DIM k4(0 TO 1)         AS DOUBLE
    DIM temp_state(0 TO 1) AS DOUBLE
    DIM state(0 TO 1)      AS DOUBLE
    state(0) = altitude
    state(1) = vDown

    CALL compute_vertical_derivatives(state(), k1(), netAcc)
    temp_state(0) = state(0) + 0.5 * dt * k1(0)
    temp_state(1) = state(1) + 0.5 * dt * k1(1)
    CALL compute_vertical_derivatives(temp_state(), k2(), netAcc)
    temp_state(0) = state(0) + 0.5 * dt * k2(0)
    temp_state(1) = state(1) + 0.5 * dt * k2(1)
    CALL compute_vertical_derivatives(temp_state(), k3(), netAcc)
    temp_state(0) = state(0) + dt * k3(0)
    temp_state(1) = state(1) + dt * k3(1)
    CALL compute_vertical_derivatives(temp_state(), k4(), netAcc)

    altitude = altitude + (k1(0) + 2 * k2(0) + 2 * k3(0) + k4(0)) * dt / 6.0
    vDown = vDown + (k1(1) + 2 * k2(1) + 2 * k3(1) + k4(1)) * dt / 6.0
END SUB

SUB rk4_horizontal (horizPos AS DOUBLE, horizSpeed AS DOUBLE, dt AS DOUBLE, horizAcc AS DOUBLE)
    DIM k1(0 TO 1)         AS DOUBLE
    DIM k2(0 TO 1)         AS DOUBLE
    DIM k3(0 TO 1)         AS DOUBLE
    DIM k4(0 TO 1)         AS DOUBLE
    DIM temp_state(0 TO 1) AS DOUBLE
    DIM state(0 TO 1)      AS DOUBLE
    state(0) = horizPos
    state(1) = horizSpeed

    CALL compute_horizontal_derivatives(state(), k1(), horizAcc)
    temp_state(0) = state(0) + 0.5 * dt * k1(0)
    temp_state(1) = state(1) + 0.5 * dt * k1(1)
    CALL compute_horizontal_derivatives(temp_state(), k2(), horizAcc)
    temp_state(0) = state(0) + 0.5 * dt * k2(0)
    temp_state(1) = state(1) + 0.5 * dt * k2(1)
    CALL compute_horizontal_derivatives(temp_state(), k3(), horizAcc)
    temp_state(0) = state(0) + dt * k3(0)
    temp_state(1) = state(1) + dt * k3(1)
    CALL compute_horizontal_derivatives(temp_state(), k4(), horizAcc)

    horizPos = horizPos + (k1(0) + 2 * k2(0) + 2 * k3(0) + k4(0)) * dt / 6.0
    horizSpeed = horizSpeed + (k1(1) + 2 * k2(1) + 2 * k3(1) + k4(1)) * dt / 6.0
END SUB