# /*
# * moonLander    Version 1.0  04/10/2025
# ***************************************************************************************
# *       PROGRAM: moonLander
# *        AUTHOR: George McGinn
# *                <gjmcginn@icloud.com>
# *  DATE WRITTEN: 04/10/2025
# *       VERSION: 1.0
# *       PROJECT: Apollo Moon Lander Simulator
# *
# *   DESCRIPTION: Interactive game where you pilot the Lunar Module (LEM) after an 
# *                Apollo Guidance Computer (AGC) failure at 7,500 ft. Emergency 
# *                burn errors leave random initial speeds (vDown: 200–700 ft/s, 
# *                horizSpeed: 50–200 ft/s). Manually adjust vBurn and hBurn to land 
# *                safely or abort with ascent fuel. There is also a time delay in
# *                displaying the correction to the user. The time delay is 6.6 seconds
# *                (signlal delay of 2.6 seconds and 4 seconds for Ground Control to
# *                process the correction) and is added to the time when the correction
# *                is evaluated. The correction is displayed at the time of the 
# *                evaluation plus 6.6 seconds.
# *
# * Written by George McGinn
# * Copyright (C)2025 George McGinn - All Rights Reserved
# * Version 1.0 - Created 04/10/2025
# *
# * CHANGE LOG
# ***************************************************************************************
# * 04/10/2025 GJM - New Program. Version 1.0
# ***************************************************************************************
# * Copyright (C)2025 by George McGinn.  All Rights Reserved
# *
# * Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)   
# * https://creativecommons.org/licenses/by-nc-sa/4.0/
# * You are allowed to copy, distribute, remix, adapt, and build upon your work, 
# * but only for non-commercial purposes, and must credit me and share your 
# * adaptations under the same license. 
# * 
# ***************************************************************************************
# */

import math
import time
import random

# Define the Correction class (equivalent to C struct)
class Correction:
    def __init__(self, evalTime, displayTime, vBurnDiff, hBurnDiff, isConfirmation):
        self.evalTime = evalTime
        self.displayTime = displayTime
        self.vBurnDiff = vBurnDiff
        self.hBurnDiff = hBurnDiff
        self.isConfirmation = isConfirmation

# RK4 helper functions
def compute_vertical_derivatives(state, netAcc):
    derivatives = [0, 0]
    derivatives[0] = -state[1]  # d(altitude)/dt = -vDown
    derivatives[1] = netAcc     # d(vDown)/dt = netAcc
    return derivatives

def compute_horizontal_derivatives(state, horizAcc):
    derivatives = [0, 0]
    derivatives[0] = state[1]   # d(horizPos)/dt = horizSpeed
    derivatives[1] = horizAcc   # d(horizSpeed)/dt = horizAcc
    return derivatives

def rk4_vertical(altitude, vDown, dt, netAcc):
    state = [altitude, vDown]
    k1 = compute_vertical_derivatives(state, netAcc)
    temp_state = [state[0] + 0.5 * dt * k1[0], state[1] + 0.5 * dt * k1[1]]
    k2 = compute_vertical_derivatives(temp_state, netAcc)
    temp_state = [state[0] + 0.5 * dt * k2[0], state[1] + 0.5 * dt * k2[1]]
    k3 = compute_vertical_derivatives(temp_state, netAcc)
    temp_state = [state[0] + dt * k3[0], state[1] + dt * k3[1]]
    k4 = compute_vertical_derivatives(temp_state, netAcc)
    new_altitude = altitude + (k1[0] + 2*k2[0] + 2*k3[0] + k4[0]) * dt / 6.0
    new_vDown = vDown + (k1[1] + 2*k2[1] + 2*k3[1] + k4[1]) * dt / 6.0
    return new_altitude, new_vDown

def rk4_horizontal(horizPos, horizSpeed, dt, horizAcc):
    state = [horizPos, horizSpeed]
    k1 = compute_horizontal_derivatives(state, horizAcc)
    temp_state = [state[0] + 0.5 * dt * k1[0], state[1] + 0.5 * dt * k1[1]]
    k2 = compute_horizontal_derivatives(temp_state, horizAcc)
    temp_state = [state[0] + 0.5 * dt * k2[0], state[1] + 0.5 * dt * k2[1]]
    k3 = compute_horizontal_derivatives(temp_state, horizAcc)
    temp_state = [state[0] + dt * k3[0], state[1] + dt * k3[1]]
    k4 = compute_horizontal_derivatives(temp_state, horizAcc)
    new_horizPos = horizPos + (k1[0] + 2*k2[0] + 2*k3[0] + k4[0]) * dt / 6.0
    new_horizSpeed = horizSpeed + (k1[1] + 2*k2[1] + 2*k3[1] + k4[1]) * dt / 6.0
    return new_horizPos, new_horizSpeed

def main():
    # Constants and initial conditions
    gravity = 5.33136483       # ft/s^2 (lunar gravity)
    standardGravity = 32.174   # ft/s^2 (standard gravity)
    Vex = 10000                # ft/s (exhaust velocity)
    maxVerticalBurn = 250      # lbs/s
    maxHorizBurn = 10          # lbs/s
    timeLimit = 600            # seconds
    small_dt = 0.1

    # --- Initial Conditions (Descent Stage)
    descentDryMass = 4700      # lb (descent stage dry)
    descentFuelMass = 1500     # lb (descent fuel)

    # --- Ascent Stage Parameters (for abort)
    ascentDryMass = 4850       # lbfd (ascent stage dry)
    ascentFuelMass = 5187      # lb (ascent fuel)
    ascentVex = 10000          # ft/s
    minAltitudeForAbort = 100  # ft (minimum altitude to safely abort)

    # Total mass includes both stages
    mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass  # 16,237 lbs
    altitude = 7500                      # feet
    mass_slugs = mass / standardGravity  # Earth's Standard Gravity (32.174) in ft/s²

    targetTouchdownSpeed = 5   # ft/s
    random.seed(int(time.time()))
    vDown = 200 + (random.randint(0, 500))  # rand() % 501 gives 0-500, so 200-700 ft/s
    horizSpeed = 50 + (random.randint(0, 150))  # 50-200 ft/s
    horizPos = 0
    currentTime = 0.0

    # Time Delay for feedback
    transmissionDelay = 2.6    # Transmission time in seconds
    processingDelay = 2        # Processing time in seconds

    # Correction queue (using a list instead of fixed array)
    pendingCorrections = []

    # Game Introduction 
    print("=========================================================")
    print("          APOLLO LUNAR LANDER SIMULATOR")
    print("=========================================================")
    print()
    print("Welcome to the Apollo Lunar Lander Simulator!")
    print("Version 1.0.0 - Created by George McGinn - 04/10/2025")
    print()
    print("You are the pilot of the Lunar Module (LEM) when the AGC")
    print("fails at 7500 ft due to prior burn errors. Initial speeds")
    print("are random (vDown: 200-700 ft/s, horizSpeed: 50-200 ft/s).")
    print()
    print("Starting Conditions:")
    print("  - Altitude: 7,500 ft")
    print(f"  - Vertical Speed: {vDown:.2f} ft/s (downward)")
    print(f"  - Horizontal Speed: {horizSpeed:.2f} ft/s")
    print(f"  - Descent Fuel: {descentFuelMass:.0f} lbs")
    print(f"  - Ascent Fuel (for abort): {ascentFuelMass:.0f} lbs")
    print(f"  - Descent Stage Dry Mass: {descentDryMass:.0f} lbs")
    print(f"  - Ascent Stage Dry Mass: {ascentDryMass:.0f} lbs")
    print(f"  - Total Mass Slugs:  {mass_slugs:.2f} slugs")
    print()
    print("Controls:")
    print("  - Duration: Time (seconds) to apply burns (-1 to abort)")
    print("  - vBurn: Vertical burn rate (0 to 250 lbs/s)")
    print("  - hBurn: Horizontal burn rate (-10 to 10 lbs/s)")
    print()
    print("Objective:")
    print("Land with vDown <= 5 ft/s and |horizSpeed| <= 5 ft/s for a")
    print("perfect landing. Receive feedback after each burn to adjust")
    print("your trajectory. Abort if needed, but ensure you can reach orbit!")
    print()
    print("Note: The game also enforces a time delay that the real astronauts.")
    print(f"      experienced. The time delay is {transmissionDelay + processingDelay:.1f} seconds (signal delay of")
    print(f"      {transmissionDelay:.1f} seconds and {processingDelay:.1f} seconds for Ground Control to process the")
    print("      correction).")
    print()
    print("Ready to land on the Moon? Let's begin!")
    print("=========================================================")
    print()
    time.sleep(5)

    print(f"Lunar Lander: AGC failed. Altitude={altitude:.0f} ft, vDown={vDown:.0f} ft/s, hSpeed={horizSpeed:.0f} ft/s")
    print("Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10), separated by spaces")

    while altitude > 0:
        # Step 1: Display Current State
        print(f"t={currentTime:.2f}s  Alt={altitude:.3f}  vDown={vDown:.3f}  hPos={horizPos:.3f}  hSpeed={horizSpeed:.3f}  Fuel={descentFuelMass:.3f}")

        # Step 2: Prompt for User Input
        while True:
            try:
                print(">> ", end="")
                user_input = input().strip()
                if not user_input:
                    print("Input cannot be empty. Please try again.")
                    continue
                duration, vBurn, hBurn = map(float, user_input.split())
                break
            except ValueError:
                print("Invalid input. Please enter three numbers separated by spaces.")

        # Step 3: Handle Abort Condition
        if duration < 0:
            print("Aborting landing...")
            if altitude < minAltitudeForAbort:
                print("\033[31mToo low to abort safely! Crashing into the surface.\033[0m")
                altitude = 0
                break
            elif ascentFuelMass <= 0:
                print("\033[31mNo ascent fuel left! Cannot reach orbit. Crashing.\033[0m")
                altitude = 0
                break
            else:
                delta_v = ascentVex * math.log((ascentDryMass + ascentFuelMass) / ascentDryMass)
                lunarOrbitalSpeed = 5512 # ft/s (approximate speed for lunar orbit)
                if delta_v >= lunarOrbitalSpeed - abs(horizSpeed):
                    print(f"\033[32mAbort successful! Achieved lunar orbit with {delta_v:.2f} ft/s delta-v.\033[0m")
                    break
                else:
                    print(f"\033[31mAbort failed! Insufficient delta-v ({delta_v:.2f} ft/s) to reach orbit.\033[0m")
                    print("Continuing landing with remaining fuel.")

        # Step 4: Validate User Inputs
        if vBurn < 0 or vBurn > maxVerticalBurn or hBurn < -maxHorizBurn or hBurn > maxHorizBurn:
            print("Invalid burn rates.")
            continue

        # Step 5: Simulate the Burn Duration
        steps = int(duration / small_dt)
        for i in range(steps):
            if altitude <= 0:
                break
            fuelUsed = (vBurn + abs(hBurn)) * small_dt
            if fuelUsed > descentFuelMass:
                fuelUsed = descentFuelMass
            descentFuelMass -= fuelUsed
            mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass
            mass_slugs = mass / standardGravity  # Earth's Standard Gravity (32.174) in ft/s²

            # Vertical thrust
            mass_flow_rate_vertical = vBurn / standardGravity  # slugs/s
            thrustForce_vertical = mass_flow_rate_vertical * Vex  # lbs
            thrustAcc_vertical = thrustForce_vertical / mass_slugs  # ft/s² upward
            netAcc_vertical = gravity - thrustAcc_vertical  # gravity downward

            # Horizontal thrust
            mass_flow_rate_horizontal = abs(hBurn) / standardGravity  # slugs/s
            thrustForce_horizontal = mass_flow_rate_horizontal * Vex  # lbs
            thrustAcc_horizontal = (1 if hBurn >= 0 else -1) * thrustForce_horizontal / mass_slugs  # ft/s²

            altitude, vDown = rk4_vertical(altitude, vDown, small_dt, netAcc_vertical)
            horizPos, horizSpeed = rk4_horizontal(horizPos, horizSpeed, small_dt, thrustAcc_horizontal)
            currentTime += small_dt

            # Provide Feedback after time delay
            j = 0
            while j < len(pendingCorrections):
                if currentTime >= pendingCorrections[j].displayTime:
                    if pendingCorrections[j].isConfirmation == 1:
                        print(f"\033[33m[Mission Control: on t={pendingCorrections[j].evalTime:.2f}s (received on t={pendingCorrections[j].displayTime:.2f}s)] Burn rates are nominal.\033[0m")
                    else:
                        if pendingCorrections[j].vBurnDiff > 0:
                            print(f"\033[33m[Mission Control: on t={pendingCorrections[j].evalTime:.2f}s (received on t={pendingCorrections[j].displayTime:.2f}s)] Increase vBurn by {pendingCorrections[j].vBurnDiff:.2f} lbs/s\033[0m")
                        elif pendingCorrections[j].vBurnDiff < 0:
                            print(f"\033[33m[Mission Control: on t={pendingCorrections[j].evalTime:.2f}s (received on t={pendingCorrections[j].displayTime:.2f}s)] Decrease vBurn by {-pendingCorrections[j].vBurnDiff:.2f} lbs/s\033[0m")
                        if pendingCorrections[j].hBurnDiff > 0:
                            print(f"\033[33m[Mission Control: on t={pendingCorrections[j].evalTime:.2f}s (received on t={pendingCorrections[j].displayTime:.2f}s)] Increase hBurn by {pendingCorrections[j].hBurnDiff:.2f} lbs/s\033[0m")
                        elif pendingCorrections[j].hBurnDiff < 0:
                            print(f"\033[33m[Mission Control: on t={pendingCorrections[j].evalTime:.2f}s (received on t={pendingCorrections[j].displayTime:.2f}s)] Decrease hBurn by {-pendingCorrections[j].hBurnDiff:.2f} lbs/s\033[0m")
                    del pendingCorrections[j]
                else:
                    j += 1

        # Step 6: Queue New Correction or Confirmation
        if altitude > 0:
            # Temporary variables for projection
            projectedAltitude = altitude
            projectedVDOWN = vDown
            projectedHSpeed = horizSpeed
            tempMass = mass
            tempFuel = descentFuelMass
            tempMassSlugs = tempMass / standardGravity
            projection_dt = 0.1  # Small time step for projection
            maxProjectionSteps = 10000  # Limit iterations to prevent infinite loop
            stepCount = 0

            # Simulate descent until landing or limit reached
            while projectedAltitude > 0 and tempFuel >= 0 and tempMass > 0 and stepCount < maxProjectionSteps:
                # Fuel consumption
                fuelUsed = (vBurn + abs(hBurn)) * projection_dt
                if fuelUsed > tempFuel:
                    fuelUsed = tempFuel
                tempFuel -= fuelUsed
                tempMass = descentDryMass + tempFuel + ascentDryMass + ascentFuelMass
                if tempMass <= 0:
                    break  # Avoid division by zero
                tempMassSlugs = tempMass / standardGravity

                # Vertical acceleration
                mass_flow_rate_vertical = vBurn / standardGravity  # slugs/s
                thrustForce_vertical = mass_flow_rate_vertical * Vex  # lbs
                thrustAcc_vertical = thrustForce_vertical / tempMassSlugs  # ft/s²
                netAcc_vertical = gravity - thrustAcc_vertical

                # Horizontal acceleration
                mass_flow_rate_horizontal = abs(hBurn) / standardGravity
                thrustForce_horizontal = mass_flow_rate_horizontal * Vex
                thrustAcc_horizontal = (1 if hBurn >= 0 else -1) * thrustForce_horizontal / tempMassSlugs

                # Update state using RK4
                projectedAltitude, projectedVDOWN = rk4_vertical(projectedAltitude, projectedVDOWN, projection_dt, netAcc_vertical)
                # Note: horizPos is updated in C but not used in feedback; we update a dummy value
                _, projectedHSpeed = rk4_horizontal(0, projectedHSpeed, projection_dt, thrustAcc_horizontal)
                stepCount += 1

            # Define safe landing targets
            targetTouchdownSpeed = 5.0  # ft/s
            targetHSpeed = 0.0         # ft/s (ideal horizontal speed)
            tolerance = 5.0            # ft/s tolerance for safe landing

            # Calculate errors from safe landing targets
            vDownError = projectedVDOWN - targetTouchdownSpeed  # Positive if too fast
            hSpeedError = projectedHSpeed - targetHSpeed        # Positive if right, negative if left

            # Suggest burn adjustments (tuned proportionality constants)
            vBurnAdjustment = vDownError * 0.1    # lbs/s per ft/s error
            hBurnAdjustment = hSpeedError * 0.05  # Smaller factor for horizontal

            # Clamp adjustments to physical limits
            if vBurn + vBurnAdjustment > maxVerticalBurn:
                vBurnAdjustment = maxVerticalBurn - vBurn
            if vBurn + vBurnAdjustment < 0:
                vBurnAdjustment = -vBurn
            if hBurn + hBurnAdjustment > maxHorizBurn:
                hBurnAdjustment = maxHorizBurn - hBurn
            # Corrected from C code: Original had 'hBurnAdjustment = -hBurn + maxHorizBurn',
            # which incorrectly clamps to maxHorizBurn instead of -maxHorizBurn
            if hBurn + hBurnAdjustment < -maxHorizBurn:
                hBurnAdjustment = -maxHorizBurn - hBurn

            # Queue feedback
            if abs(vDownError) <= tolerance and abs(hSpeedError) <= tolerance:
                if len(pendingCorrections) < 100:
                    pendingCorrections.append(Correction(
                        currentTime,
                        currentTime + transmissionDelay + processingDelay,
                        0,
                        0,
                        1
                    ))
            else:
                if len(pendingCorrections) < 100:
                    pendingCorrections.append(Correction(
                        currentTime,
                        currentTime + transmissionDelay + processingDelay,
                        vBurnAdjustment,
                        hBurnAdjustment,
                        0
                    ))

    # Evaluate Landing Outcome
    if altitude <= 0:
        if altitude < 0:
            altitude = 0
        print()
        print(f"Touchdown at t = {currentTime:.1f} s")
        print(f"Final Downward Speed: {vDown:.2f} ft/s")
        print(f"Final Horizontal Speed: {horizSpeed:.2f} ft/s")
        if (vDown <= targetTouchdownSpeed) and (abs(horizSpeed) <= 5):
            print("\033[32mPerfect Landing! Impact speed is safe.\033[0m")
        elif (vDown <= 15) and (abs(horizSpeed) <= 15):
            print("\033[32mGood Landing (minor impact).\033[0m")
        else:
            print("\033[31mCrash Landing! Impact speed is too high.\033[0m")
    elif currentTime >= timeLimit:
        print("\nSimulation aborted after reaching the time limit.")

if __name__ == "__main__":
    main()