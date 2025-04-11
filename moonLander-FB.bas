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
Type Correction
    evalTime       As Double         ' Time when state was evaluated (end of burn)
    displayTime    As Double      ' Time to display correction (evalTime + 6.6)
    vBurnDiff      As Double
    hBurnDiff      As Double
    isConfirmation As Integer  ' 0 for correction, 1 for confirmation
End Type

' ### RK4 Helper Functions
Declare Sub compute_vertical_derivatives(state() As Double, derivatives() As Double, netAcc As Double)
Declare Sub compute_horizontal_derivatives(state() As Double, derivatives() As Double, horizAcc As Double)
Declare Sub rk4_vertical(ByRef altitude As Double, ByRef vDown As Double, dt As Double, netAcc As Double)
Declare Sub rk4_horizontal(ByRef horizPos As Double, ByRef horizSpeed As Double, dt As Double, horizAcc As Double)

' ### Main Program Variables
Dim Shared altitude        As Double
Dim Shared vDown           As Double
Dim Shared horizPos        As Double
Dim Shared horizSpeed      As Double
Dim Shared descentFuelMass As DoubleDim vBurnTolerance    As Double
Dim hBurnTolerance    As Double
Dim fuelUsed          As Double
Dim i                 As Integer
Dim j                 As Integer
Dim k                 As Integer
Dim transmissionDelay As Double
Dim processingDelay   As Double
Dim numPending        As Integer
Dim pendingCorrections(0 To 99) As Correction

' Constants
Const gravity = 5.33136483       ' ft/s^2 (lunar gravity)
Const standardGravity = 32.174   ' ft/s^2 (standard gravity)
Const Vex = 10000                ' ft/s (exhaust velocity)
Const maxVerticalBurn = 250      ' lbs/s
Const maxHorizBurn = 10          ' lbs/s
Const timeLimit = 600            ' seconds
Const small_dt = 0.1             ' simulation time step

' --- Initial Conditions (Descent Stage)
Const descentDryMass = 4700      ' lb (descent stage dry)
Const descentFuelMassInit = 1500 ' lb (descent fuel)

' --- Ascent Stage Parameters (for abort)
Const ascentDryMass = 4850       ' lb (ascent stage dry)
Const ascentFuelMass = 5187      ' lb (ascent fuel)
Const ascentVex = 10000          ' ft/s
Const minAltitudeForAbort = 100  ' ft (minimum altitude to safely abort)

' Declare variables for main simulation calculations
Dim mass_slugs                As Double
Dim mass_flow_rate_vertical   As Double
Dim thrustForce_vertical      As Double
Dim thrustAcc_vertical        As Double
Dim netAcc_vertical           As Double
Dim mass_flow_rate_horizontal As Double
Dim thrustForce_horizontal    As Double
Dim thrustAcc_horizontal      As Double
mass_slugs = mass / standardGravity  ' Earth's Standard Gravity (32.174) in ft/s²

' Declare variables for projection calculations
Dim projectedAltitude         As Double
Dim projectedVDOWN            As Double
Dim projectedHSpeed           As Double
Dim tempMass                  As Double
Dim tempFuel                  As Double
Dim tempMassSlugs             As Double
Dim projection_dt             As Double
Dim maxProjectionSteps        As Integer
Dim stepCount                 As Integer
projection_dt = 0.1
maxProjectionSteps = 10000
stepCount = 0

Dim targetTouchdownSpeed      As Double 
Dim targetHSpeed              As Double 
Dim tolerance                 As Double 
targetTouchdownSpeed = 5.0
targetHSpeed = 0.0
tolerance = 5.0

Dim vDownError                As Double
Dim hSpeedError               As Double
Dim vBurnAdjustment           As Double
Dim hBurnAdjustment           As Double

' Initialize Variables
descentFuelMass = descentFuelMassInit
mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass

altitude = 7500
Randomize Timer
vDown = 200 + Int(Rnd * 501)
horizSpeed = 50 + Int(Rnd * 151)
horizPos = 0
currentTime = 0.0
numPending = 0

' Time Delay for feedback
transmissionDelay = 2.6
processingDelay = 4

' #### Game Introduction
Print "========================================================="
Print "          APOLLO LUNAR LANDER SIMULATOR"
Print "========================================================="
Print
Print "Welcome to the Apollo Lunar Lander Simulator!"
Print "Version 1.0.0 - Created by George McGinn - 04/10/2025"
Print
Print "You are the pilot of the Lunar Module (LEM) when the AGC"
Print "fails at 7500 ft due to prior burn errors. Initial speeds"
Print "are random (vDown: 200-700 ft/s, horizSpeed: 50-200 ft/s)."
Print
Print "Starting Conditions:"
Print "  - Altitude: 7,500 ft"
Print Using "  - Vertical Speed: ###.## ft/s (downward)"; vDown
Print Using "  - Horizontal Speed: ###.## ft/s"; horizSpeed
Print Using "  - Descent Fuel: #### lbs"; descentFuelMass
Print Using "  - Ascent Fuel (for abort): #### lbs"; ascentFuelMass
Print Using "  - Descent Stage Dry Mass: #### lbs"; descentDryMass
Print Using "  - Ascent Stage Dry Mass: #### lbs"; ascentDryMass
Print Using "  - Mass Slugs: ###.### slugs"; mass_slugs
Print
Print "Controls:"
Print "  - Duration: Time (seconds) to apply burns (-1 to abort)"
Print "  - vBurn: Vertical burn rate (0 to 250 lbs/s)"
Print "  - hBurn: Horizontal burn rate (-10 to 10 lbs/s)"
Print
Print "Objective:"
Print "Land with vDown <= 5 ft/s and |horizSpeed| <= 5 ft/s for a"
Print "perfect landing. Receive feedback after each burn to adjust"
Print "your trajectory. Abort if needed, but ensure you can reach orbit!"
Print
Print "Note: The game also enforces a time delay that the real astronauts."
Print Using "      experienced. The time delay is #.# seconds (signal delay of"; transmissionDelay + processingDelay
Print Using "      #.# seconds and #.# seconds for Ground Control to process the"; transmissionDelay; processingDelay
Print "      correction)."
Print
Print "Ready to land on the Moon? Let's begin!"
Print "========================================================="
Print
Sleep 5000, 1

Print Using "Lunar Lander: AGC failed. Altitude=#### ft, vDown=#### ft/s, hSpeed=#### ft/s"; altitude; vDown; horizSpeed
Print "Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10), separated by commas"

' #### Main Simulation Loop
Do While altitude > 0
    Print Using "t=##.##s  Alt=#####.###  vDown=####.###  hPos=####.###  hSpeed=####.###  Fuel=####.###"; _
        currentTime; altitude; vDown; horizPos; horizSpeed; descentFuelMass

    Input ">> ", duration, vBurn, hBurn
    If duration = 0 And vBurn = 0 And hBurn = 0 Then
        Print "Invalid input. Please enter three numbers separated by commas."
        GoTo nextIteration
    End If

    If duration < 0 Then
        Print "Aborting landing..."
        If altitude < minAltitudeForAbort Then
            Print "Too low to abort safely! Crashing into the surface."
            altitude = 0
            Exit Do
        ElseIf ascentFuelMass <= 0 Then
            Print "No ascent fuel left! Cannot reach orbit. Crashing."
            altitude = 0
            Exit Do
        Else
            delta_v = ascentVex * Log((ascentDryMass + ascentFuelMass) / ascentDryMass)
            lunarOrbitalSpeed = 5512 ' ft/s (approximate speed for lunar orbit)
            If delta_v >= lunarOrbitalSpeed - Abs(horizSpeed) Then
                Color 10 ' Green for success
                Print Using "Abort successful. Achieved lunar orbit with ####.## ft/s delta-v."; delta_v
                Color 7  ' Reset to default
                Exit Do
            Else
                Color 12 ' Red for failure
                Print Using "Abort failed. Insufficient delta-v (####.## ft/s) to reach orbit."; delta_v
                Color 7  ' Reset to default
                Print "Continuing landing with remaining fuel."
            End If
        End If
    End If

    If vBurn < 0 Or vBurn > maxVerticalBurn Or hBurn < -maxHorizBurn Or hBurn > maxHorizBurn Then
        Print "Invalid burn rates."
        GoTo nextIteration
    End If

    ' Step 5: Simulate the Burn Duration
    steps = Int(duration / small_dt)
    For i = 1 To steps
        If altitude <= 0 Then Exit For
        fuelUsed = (vBurn + Abs(hBurn)) * small_dt
        If fuelUsed > descentFuelMass Then fuelUsed = descentFuelMass
        descentFuelMass = descentFuelMass - fuelUsed
        mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass
        mass_slugs = mass / standardGravity  ' Earth's Standard Gravity (32.174) in ft/s²

        ' Vertical thrust
        mass_flow_rate_vertical = vBurn / standardGravity         ' slugs/s
        thrustForce_vertical = mass_flow_rate_vertical * Vex      ' lbs
        thrustAcc_vertical = thrustForce_vertical / mass_slugs    ' ft/s² upward
        netAcc_vertical = gravity - thrustAcc_vertical            ' gravity downward

        ' Horizontal thrust
        mass_flow_rate_horizontal = Abs(hBurn) / standardGravity  ' slugs/s
        thrustForce_horizontal = mass_flow_rate_horizontal * Vex  ' lbs
        thrustAcc_horizontal = Sgn(hBurn) * thrustForce_horizontal / mass_slugs  ' ft/s², using SGN for direction

        rk4_vertical (altitude, vDown, small_dt, netAcc_vertical)
        rk4_horizontal (horizPos, horizSpeed, small_dt, thrustAcc_horizontal)
        currentTime = currentTime + small_dt

        j = 0
        While j < numPending
            If currentTime >= pendingCorrections(j).displayTime Then
                If pendingCorrections(j).isConfirmation = 1 Then
                    Color 14 ' Yellow for Mission Control
                    Print Using "[Mission Control: on t=###.##s (received on t=###.##s)] Burn rates are nominal."; _
                        pendingCorrections(j).evalTime; pendingCorrections(j).displayTime
                    Color 7  ' Reset to default
                Else
                    If pendingCorrections(j).vBurnDiff > 0 Then
                        Color 14 ' Yellow for Mission Control
                        Print Using "[Mission Control: on t=###.##s (received on t=###.##s)] Increase vBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; pendingCorrections(j).vBurnDiff
                        Color 7  ' Reset to default
                    ElseIf pendingCorrections(j).vBurnDiff < 0 Then
                        Color 14 ' Yellow for Mission Control
                        Print Using "[Mission Control: on t=###.##s (received on t=###.##s)] Decrease vBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; -pendingCorrections(j).vBurnDiff
                        Color 7  ' Reset to default
                    End If
                    If pendingCorrections(j).hBurnDiff > 0 Then
                        Color 14 ' Yellow for Mission Control
                        Print Using "[Mission Control: on t=###.##s (received on t=###.##s)] Increase hBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; pendingCorrections(j).hBurnDiff
                        Color 7  ' Reset to default
                    ElseIf pendingCorrections(j).hBurnDiff < 0 Then
                        Color 14 ' Yellow for Mission Control
                        Print Using "[Mission Control: on t=###.##s (received on t=###.##s)] Decrease hBurn by ##.## lbs/s"; _
                            pendingCorrections(j).evalTime; pendingCorrections(j).displayTime; -pendingCorrections(j).hBurnDiff
                        Color 7  ' Reset to default
                    End If
                End If
                For k = j To numPending - 2
                    pendingCorrections(k) = pendingCorrections(k + 1)
                Next k
                numPending = numPending - 1
            Else
                j = j + 1
            End If
        Wend
    Next i

    ' Step 6: Queue New Correction or Confirmation
    If altitude > 0 Then
        projectedAltitude = altitude
        projectedVDOWN = vDown
        projectedHSpeed = horizSpeed
        tempMass = mass
        tempFuel = descentFuelMass
        tempMassSlugs = tempMass / standardGravity
        stepCount = 0

        While projectedAltitude > 0 And tempFuel >= 0 And tempMass > 0 And stepCount < maxProjectionSteps
            fuelUsed = (vBurn + Abs(hBurn)) * projection_dt
            If fuelUsed > tempFuel Then fuelUsed = tempFuel
            tempFuel = tempFuel - fuelUsed
            tempMass = descentDryMass + tempFuel + ascentDryMass + ascentFuelMass
            If tempMass <= 0 Then Exit While
            tempMassSlugs = tempMass / standardGravity

            mass_flow_rate_vertical = vBurn / standardGravity
            thrustForce_vertical = mass_flow_rate_vertical * Vex
            thrustAcc_vertical = thrustForce_vertical / tempMassSlugs
            netAcc_vertical = gravity - thrustAcc_vertical

            mass_flow_rate_horizontal = Abs(hBurn) / standardGravity
            thrustForce_horizontal = mass_flow_rate_horizontal * Vex
            thrustAcc_horizontal = Sgn(hBurn) * thrustForce_horizontal / tempMassSlugs

            rk4_vertical (projectedAltitude, projectedVDOWN, projection_dt, netAcc_vertical)
            rk4_horizontal (0, projectedHSpeed, projection_dt, thrustAcc_horizontal)
            stepCount = stepCount + 1
        Wend

        vDownError = projectedVDOWN - targetTouchdownSpeed
        hSpeedError = projectedHSpeed - targetHSpeed
        vBurnAdjustment = vDownError * 0.1
        hBurnAdjustment = hSpeedError * 0.05

        If vBurn + vBurnAdjustment > maxVerticalBurn Then vBurnAdjustment = maxVerticalBurn - vBurn
        If vBurn + vBurnAdjustment < 0 Then vBurnAdjustment = -vBurn
        If hBurn + hBurnAdjustment > maxHorizBurn Then hBurnAdjustment = maxHorizBurn - hBurn
        If hBurn + hBurnAdjustment < -maxHorizBurn Then hBurnAdjustment = -hBurn - maxHorizBurn

        If Abs(vDownError) <= tolerance And Abs(hSpeedError) <= tolerance Then
            If numPending < 100 Then
                pendingCorrections(numPending).evalTime = currentTime
                pendingCorrections(numPending).displayTime = currentTime + transmissionDelay + processingDelay
                pendingCorrections(numPending).vBurnDiff = 0
                pendingCorrections(numPending).hBurnDiff = 0
                pendingCorrections(numPending).isConfirmation = 1
                numPending = numPending + 1
            End If
        Else
            If numPending < 100 Then
                pendingCorrections(numPending).evalTime = currentTime
                pendingCorrections(numPending).displayTime = currentTime + transmissionDelay + processingDelay
                pendingCorrections(numPending).vBurnDiff = vBurnAdjustment
                pendingCorrections(numPending).hBurnDiff = hBurnAdjustment
                pendingCorrections(numPending).isConfirmation = 0
                numPending = numPending + 1
            End If
        End If
    End If

nextIteration:
Loop

If altitude <= 0 Then
    If altitude < 0 Then altitude = 0
    Print
    Print Using "Touchdown at t = ###.# s"; currentTime
    Print Using "Final Downward Speed: ###.## ft/s"; vDown
    Print Using "Final Horizontal Speed: ###.## ft/s"; horizSpeed
    If vDown <= 5 And Abs(horizSpeed) <= 5 Then
        Color 10 ' Green for success
        Print "Perfect Landing! Impact speed is safe."
        Color 7  ' Reset to default
    ElseIf vDown <= 15 And Abs(horizSpeed) <= 15 Then
        Color 10 ' Green for success
        Print "Good Landing (minor impact)."
        Color 7  ' Reset to default
    Else
        Color 12 ' Red for failure
        Print "Crash Landing! Impact speed is too high."
        Color 7  ' Reset to default
    End If
ElseIf currentTime >= timeLimit Then
    Print
    Print "Simulation aborted after reaching the time limit."
End If

End

' ### RK4 Helper Functions
Sub compute_vertical_derivatives(state() As Double, derivatives() As Double, netAcc As Double)
    derivatives(0) = -state(1)
    derivatives(1) = netAcc
End Sub

Sub compute_horizontal_derivatives(state() As Double, derivatives() As Double, horizAcc As Double)
    derivatives(0) = state(1)
    derivatives(1) = horizAcc
End Sub

Sub rk4_vertical(ByRef altitude As Double, ByRef vDown As Double, dt As Double, netAcc As Double)
    Dim k1(0 To 1)         As Double
    Dim k2(0 To 1)         As Double
    Dim k3(0 To 1)         As Double
    Dim k4(0 To 1)         As Double
    Dim temp_state(0 To 1) As Double
    Dim state(0 To 1)      As Double
    state(0) = altitude
    state(1) = vDown

    compute_vertical_derivatives state(), k1(), netAcc
    temp_state(0) = state(0) + 0.5 * dt * k1(0)
    temp_state(1) = state(1) + 0.5 * dt * k1(1)
    compute_vertical_derivatives temp_state(), k2(), netAcc
    temp_state(0) = state(0) + 0.5 * dt * k2(0)
    temp_state(1) = state(1) + 0.5 * dt * k2(1)
    compute_vertical_derivatives temp_state(), k3(), netAcc
    temp_state(0) = state(0) + dt * k3(0)
    temp_state(1) = state(1) + dt * k3(1)
    compute_vertical_derivatives temp_state(), k4(), netAcc

    altitude = altitude + (k1(0) + 2 * k2(0) + 2 * k3(0) + k4(0)) * dt / 6.0
    vDown = vDown + (k1(1) + 2 * k2(1) + 2 * k3(1) + k4(1)) * dt / 6.0
End Sub

Sub rk4_horizontal(ByRef horizPos As Double, ByRef horizSpeed As Double, dt As Double, horizAcc As Double)
    Dim k1(0 To 1)         As Double
    Dim k2(0 To 1)         As Double
    Dim k3(0 To 1)         As Double
    Dim k4(0 To 1)         As Double
    Dim temp_state(0 To 1) As Double
    Dim state(0 To 1)      As Double
    state(0) = horizPos
    state(1) = horizSpeed

    compute_horizontal_derivatives state(), k1(), horizAcc
    temp_state(0) = state(0) + 0.5 * dt * k1(0)
    temp_state(1) = state(1) + 0.5 * dt * k1(1)
    compute_horizontal_derivatives temp_state(), k2(), horizAcc
    temp_state(0) = state(0) + 0.5 * dt * k2(0)
    temp_state(1) = state(1) + 0.5 * dt * k2(1)
    compute_horizontal_derivatives temp_state(), k3(), horizAcc
    temp_state(0) = state(0) + dt * k3(0)
    temp_state(1) = state(1) + dt * k3(1)
    compute_horizontal_derivatives temp_state(), k4(), horizAcc

    horizPos = horizPos + (k1(0) + 2 * k2(0) + 2 * k3(0) + k4(0)) * dt / 6.0
    horizSpeed = horizSpeed + (k1(1) + 2 * k2(1) + 2 * k3(1) + k4(1)) * dt / 6.0
End Sub