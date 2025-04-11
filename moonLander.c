/*
* moonLander    Version 1.0  04/10/2025
***************************************************************************************
*       PROGRAM: moonLander
*        AUTHOR: George McGinn
*                <gjmcginn@icloud.com>
*  DATE WRITTEN: 04/10/2025
*       VERSION: 1.0
*       PROJECT: Apollo Moon Lander Simulator
*
*   DESCRIPTION: Interactive game where you pilot the Lunar Module (LEM) after an 
*                Apollo Guidance Computer (AGC) failure at 7,500 ft. Emergency 
*                burn errors leave random initial speeds (vDown: 200–700 ft/s, 
*                horizSpeed: 50–200 ft/s). Manually adjust vBurn and hBurn to land 
*                safely or abort with ascent fuel. There is also a time delay in
*                displaying the correction to the user. The time delay is 6.6 seconds
*                (signlal delay of 2.6 seconds and 4 seconds for Ground Control to
*                process the correction) and is added to the time when the correction
*                is evaluated. The correction is displayed at the time of the 
*                evaluation plus 6.6 seconds.
*
* Written by George McGinn
* 
* Copyright (C)2025 George McGinn - All Rights Reserved
* Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)   
* https://creativecommons.org/licenses/by-nc-sa/4.0/
* You are allowed to copy, distribute, remix, adapt, and build upon your work, 
* but only for non-commercial purposes, and must credit me and share your 
* adaptations under the same license. 
*
* Version 1.0 - Created 04/10/2025
*
* CHANGE LOG
***************************************************************************************
* 04/10/2025 GJM - New Program. Version 1.0
***************************************************************************************
* Copyright (C)2025 by George McGinn.  All Rights Reserved
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation.   
***************************************************************************************
*/

 #include <stdio.h>
 #include <stdlib.h>
 #include <math.h>
 #include <unistd.h>  // For sleep()
 #include <time.h>    // For srand/time
 
// RK4 helper functions
void compute_vertical_derivatives(double state[], double derivatives[], double netAcc) {
    derivatives[0] = -state[1];  // d(altitude)/dt = -vDown
    derivatives[1] = netAcc;     // d(vDown)/dt = netAcc
}

void compute_horizontal_derivatives(double state[], double derivatives[], double horizAcc) {
    derivatives[0] = state[1];  // d(horizPos)/dt = horizSpeed
    derivatives[1] = horizAcc;  // d(horizSpeed)/dt = horizAcc
}

void rk4_vertical(double *altitude, double *vDown, double dt, double netAcc) {
    double k1[2], k2[2], k3[2], k4[2];
    double temp_state[2];
    double state[2] = {*altitude, *vDown};

    compute_vertical_derivatives(state, k1, netAcc);
    temp_state[0] = state[0] + 0.5 * dt * k1[0];
    temp_state[1] = state[1] + 0.5 * dt * k1[1];
    compute_vertical_derivatives(temp_state, k2, netAcc);
    temp_state[0] = state[0] + 0.5 * dt * k2[0];
    temp_state[1] = state[1] + 0.5 * dt * k2[1];
    compute_vertical_derivatives(temp_state, k3, netAcc);
    temp_state[0] = state[0] + dt * k3[0];
    temp_state[1] = state[1] + dt * k3[1];
    compute_vertical_derivatives(temp_state, k4, netAcc);

    *altitude += (k1[0] + 2*k2[0] + 2*k3[0] + k4[0]) * dt / 6.0;
    *vDown += (k1[1] + 2*k2[1] + 2*k3[1] + k4[1]) * dt / 6.0;
}

void rk4_horizontal(double *horizPos, double *horizSpeed, double dt, double horizAcc) {
    double k1[2], k2[2], k3[2], k4[2];
    double temp_state[2];
    double state[2] = {*horizPos, *horizSpeed};

    compute_horizontal_derivatives(state, k1, horizAcc);
    temp_state[0] = state[0] + 0.5 * dt * k1[0];
    temp_state[1] = state[1] + 0.5 * dt * k1[1];
    compute_horizontal_derivatives(temp_state, k2, horizAcc);
    temp_state[0] = state[0] + 0.5 * dt * k2[0];
    temp_state[1] = state[1] + 0.5 * dt * k2[1];
    compute_horizontal_derivatives(temp_state, k3, horizAcc);
    temp_state[0] = state[0] + dt * k3[0];
    temp_state[1] = state[1] + dt * k3[1];
    compute_horizontal_derivatives(temp_state, k4, horizAcc);

    *horizPos += (k1[0] + 2*k2[0] + 2*k3[0] + k4[0]) * dt / 6.0;
    *horizSpeed += (k1[1] + 2*k2[1] + 2*k3[1] + k4[1]) * dt / 6.0;
}

// Modified Correction struct with isConfirmation field
typedef struct {
    double evalTime;      // Time when state was evaluated (end of burn)
    double displayTime;   // Time to display correction (evalTime + 6.6)
    double vBurnDiff;
    double hBurnDiff;
    int isConfirmation;   // 0 for correction, 1 for confirmation
} Correction;

int main() {
    double gravity = 5.33136483;       // ft/s^2 (lunar gravity)
    double standardGravity = 32.174;   // ft/s^2 (standard gravity)
    double Vex = 10000;                // ft/s (exhaust velocity)
    double maxVerticalBurn = 250;      // lbs/s
    double maxHorizBurn = 10;          // lbs/s
    double timeLimit = 600;            // seconds
    double small_dt = 0.1;

    // --- Initial Conditions (Descent Stage)
    double descentDryMass = 4700;      // lb (descent stage dry)
    double descentFuelMass = 1500;     // lb (descent fuel)

    // --- Ascent Stage Parameters (for abort)
    double ascentDryMass = 4850;       // lb (ascent stage dry)
    double ascentFuelMass = 5187;      // lb (ascent fuel)
    double ascentVex = 10000;          // ft/s
    double minAltitudeForAbort = 100;  // ft (minimum altitude to safely abort)

    // Total mass includes both stages
    double mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass;  // 16,237 lbs
    double altitude = 7500;            // feet

    // Convert mass to slugs for calculations
    // Slugs = lbs / g (where g = 32.174 ft/s²)
    double mass_slugs = mass / standardGravity;                     // Earth's Standard Gravity (32.174) in ft/s²

    double targetTouchdownSpeed = 5;   // ft/s
    srand(time(NULL));
    double vDown = 200 + (rand() % 501), horizSpeed = 50 + (rand() % 151), horizPos = 0;
    double currentTime = 0.0;

    // Time Delay for feedback
    double transmissionDelay = 2.6;                 // Transmission time in seconds
    double processingDelay = 2;                     // Processing time in seconds

    // Correction queue
    Correction pendingCorrections[100];
    int numPending = 0;

    // Game Introduction
    printf("=========================================================\n");
    printf("          APOLLO LUNAR LANDER SIMULATOR\n");
    printf("=========================================================\n");
    printf("\n");
    printf("Welcome to the Apollo Lunar Lander Simulator!\n");
    printf("Version 1.0.0 - Created by George McGinn - 04/10/2025\n");
    printf("\n");
    printf("You are the pilot of the Lunar Module (LEM) when the AGC\n");
    printf("fails at 7500 ft due to prior burn errors. Initial speeds\n");
    printf("are random (vDown: 200-700 ft/s, horizSpeed: 50-200 ft/s).\n");
    printf("\n");
    printf("Starting Conditions:\n");
    printf("  - Altitude: 7,500 ft\n");
    printf("  - Vertical Speed: %.2f ft/s (downward)\n", vDown);
    printf("  - Horizontal Speed: %.2f ft/s\n", horizSpeed);
    printf("  - Descent Fuel: %.0f lbs\n", descentFuelMass);
    printf("  - Ascent Fuel (for abort): %.0f lbs\n", ascentFuelMass);
    printf("  - Descent Stage Dry Mass: %.0f lbs\n", descentDryMass);
    printf("  - Ascent Stage Dry Mass: %.0f lbs\n", ascentDryMass);
    printf("  - Total Mass Slugs: %.3f lbs\n", mass_slugs);
    printf("\n");
    printf("Controls:\n");
    printf("  - Duration: Time (seconds) to apply burns (-1 to abort)\n");
    printf("  - vBurn: Vertical burn rate (0 to 250 lbs/s)\n");
    printf("  - hBurn: Horizontal burn rate (-10 to 10 lbs/s)\n");
    printf("\n");
    printf("Objective:\n");
    printf("Land with vDown <= 5 ft/s and |horizSpeed| <= 5 ft/s for a\n");
    printf("perfect landing. Receive feedback after each burn to adjust\n");
    printf("your trajectory. Abort if needed, but ensure you can reach orbit!\n");
    printf("\n");
    printf("Note: The game also enforces a time delay that the real astronauts.\n");
    printf("      experienced. The time delay is %.1f seconds (signal delay of\n", transmissionDelay + processingDelay);
    printf("      %.1f seconds and %.1f seconds for Ground Control to process the\n", transmissionDelay, processingDelay);
    printf("      correction).\n");    
    printf("\n");
    printf("Ready to land on the Moon? Let's begin!\n");
    printf("=========================================================\n");
    printf("\n");
    sleep(5);

    printf("Lunar Lander: AGC failed. Altitude=%.0f ft, vDown=%.0f ft/s, hSpeed=%.0f ft/s\n",
        altitude, vDown, horizSpeed);
    printf("Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10), separated by spaces\n");

    while (altitude > 0) {
     
        // Step 1: Display Current State
        if (descentFuelMass == 0) {
            printf("\033[31m[WARNING] DESCENT FUEL HAS RUN OUT. CONSIDER ABORT PROCESS.\033[0m\n");
        }
        printf("t=%.2fs  Alt=%.3f  vDown=%.3f  hPos=%.3f  hSpeed=%.3f  Fuel=%.3f\n",
            currentTime, altitude, vDown, horizPos, horizSpeed, descentFuelMass);

        // Step 2: Prompt for User Input
        double duration, vBurn, hBurn;
        printf(">> ");
        scanf("%lf %lf %lf", &duration, &vBurn, &hBurn);

        // Step 3: Handle Abort 
        if (duration < 0) {
            printf("Aborting landing...\n");
            if (altitude < minAltitudeForAbort) {
                printf("\033[31mToo low to abort safely! Crashing into the surface.\033[0m\n");
                altitude = 0;
                break;
            } else if (ascentFuelMass <= 0) {
                printf("\033[31mNo ascent fuel left! Cannot reach orbit. Crashing.\033[0m\n");
                altitude = 0;
                break;
            } else {
                double delta_v = ascentVex * log((ascentDryMass + ascentFuelMass) / ascentDryMass);
                double lunarOrbitalSpeed = 5512;  // ft/s (approximate speed for lunar orbit)
                if (delta_v >= lunarOrbitalSpeed - fabs(horizSpeed)) {
                    printf("\033[32mAbort successful! Achieved lunar orbit with %.2f ft/s delta-v.\033[0m\n", delta_v);
                    break;
                } else {
                    printf("\033[31mAbort failed! Insufficient delta-v (%.2f ft/s) to reach orbit.\033[0m\n", delta_v);
                    printf("Continuing landing with remaining fuel.\n");
                }
            }
        }

        // Step 4: Validate User Inputs 
        if (vBurn < 0 || vBurn > maxVerticalBurn || hBurn < -maxHorizBurn || hBurn > maxHorizBurn) {
            printf("Invalid burn rates.\n");
            continue;
        }

        // Step 5: Simulate the Burn Duration
        int steps = (int)(duration / small_dt);
        for (int i = 0; i < steps && altitude > 0; i++) {
            double fuelUsed = (vBurn + fabs(hBurn)) * small_dt;
            if (fuelUsed > descentFuelMass) fuelUsed = descentFuelMass;
            descentFuelMass -= fuelUsed;
            mass = descentDryMass + descentFuelMass + ascentDryMass + ascentFuelMass;
            mass_slugs = mass / standardGravity;                            // Earth's Standard Gravity (32.174) in ft/s²

            // Vertical thrust
            double mass_flow_rate_vertical = vBurn / standardGravity;       // slugs/s
            double thrustForce_vertical = mass_flow_rate_vertical * Vex;    // lbs
            double thrustAcc_vertical = thrustForce_vertical / mass_slugs;  // ft/s² upward
            double netAcc_vertical = gravity - thrustAcc_vertical;          // gravity downward

            // Horizontal thrust
            double mass_flow_rate_horizontal = fabs(hBurn) / standardGravity;                           // slugs/s
            double thrustForce_horizontal = mass_flow_rate_horizontal * Vex;                            // lbs
            double thrustAcc_horizontal = (hBurn >= 0 ? 1 : -1) * thrustForce_horizontal / mass_slugs;  // ft/s²

            rk4_vertical(&altitude, &vDown, small_dt, netAcc_vertical);
            rk4_horizontal(&horizPos, &horizSpeed, small_dt, thrustAcc_horizontal);
            currentTime += small_dt;

            // Provide Feedback after time delay
            for (int j = 0; j < numPending; j++) {
                if (currentTime >= pendingCorrections[j].displayTime) {
                    if (pendingCorrections[j].isConfirmation == 1) {
                        printf("\033[33m[Mission Control: on t=%.2fs (received on t=%.2fs)] Burn rates are nominal.\033[0m\n",
                            pendingCorrections[j].evalTime,
                            pendingCorrections[j].displayTime);
                    } else {
                        if (pendingCorrections[j].vBurnDiff > 0) {
                            printf("\033[33m[Mission Control: on t=%.2fs (received on t=%.2fs)] Increase vBurn by %.2f lbs/s\033[0m\n",
                                pendingCorrections[j].evalTime,
                                pendingCorrections[j].displayTime,
                                pendingCorrections[j].vBurnDiff);
                        } else if (pendingCorrections[j].vBurnDiff < 0) {
                            printf("\033[33m[Mission Control: on t=%.2fs (received on t=%.2fs)] Decrease vBurn by %.2f lbs/s\033[0m\n",
                                pendingCorrections[j].evalTime,
                                pendingCorrections[j].displayTime,
                                -pendingCorrections[j].vBurnDiff);
                        }
                        if (pendingCorrections[j].hBurnDiff > 0) {
                            printf("\033[33m[Mission Control: on t=%.2fs (received on t=%.2fs)] Increase hBurn by %.2f lbs/s\033[0m\n",
                                pendingCorrections[j].evalTime,
                                pendingCorrections[j].displayTime,
                                pendingCorrections[j].hBurnDiff);
                        } else if (pendingCorrections[j].hBurnDiff < 0) {
                            printf("\033[33m[Mission Control: on t=%.2fs (received on t=%.2fs)] Decrease hBurn by %.2f lbs/s\033[0m\n",
                                pendingCorrections[j].evalTime,
                                pendingCorrections[j].displayTime,
                                -pendingCorrections[j].hBurnDiff);
                        }
                    }
                    // Remove the entry from the queue
                    for (int k = j; k < numPending - 1; k++) {
                        pendingCorrections[k] = pendingCorrections[k + 1];
                    }
                    numPending--;
                    j--;
                }
            }
        }

        // Step 6: Queue New Correction or Confirmation
        if (altitude > 0) {
            // Temporary variables for projection
            double projectedAltitude = altitude;
            double projectedVDOWN = vDown;
            double projectedHSpeed = horizSpeed;
            double tempMass = mass;
            double tempFuel = descentFuelMass;
            double tempMassSlugs = tempMass / standardGravity;
            double projection_dt = 0.1;      // Small time step for projection
            int maxProjectionSteps = 10000;  // Limit iterations to prevent infinite loop
            int stepCount = 0;

            // Simulate descent until landing or limit reached
            while (projectedAltitude > 0 && tempFuel >= 0 && tempMass > 0 && stepCount < maxProjectionSteps) {
                // Fuel consumption
                double fuelUsed = (vBurn + fabs(hBurn)) * projection_dt;
                if (fuelUsed > tempFuel) fuelUsed = tempFuel;
                tempFuel -= fuelUsed;
                tempMass = descentDryMass + tempFuel + ascentDryMass + ascentFuelMass;
                if (tempMass <= 0) break;  // Avoid division by zero
                tempMassSlugs = tempMass / standardGravity;

                // Vertical acceleration
                double mass_flow_rate_vertical = vBurn / standardGravity;  // slugs/s
                double thrustForce_vertical = mass_flow_rate_vertical * Vex;  // lbs
                double thrustAcc_vertical = thrustForce_vertical / tempMassSlugs;  // ft/s²
                double netAcc_vertical = gravity - thrustAcc_vertical;

                // Horizontal acceleration
                double mass_flow_rate_horizontal = fabs(hBurn) / standardGravity;
                double thrustForce_horizontal = mass_flow_rate_horizontal * Vex;
                double thrustAcc_horizontal = (hBurn >= 0 ? 1 : -1) * thrustForce_horizontal / tempMassSlugs;

                // Update state using RK4
                rk4_vertical(&projectedAltitude, &projectedVDOWN, projection_dt, netAcc_vertical);
                rk4_horizontal(&horizPos, &projectedHSpeed, projection_dt, thrustAcc_horizontal);
                stepCount++;
            }

            // Define safe landing targets
            double targetTouchdownSpeed = 5.0;  // ft/s
            double targetHSpeed = 0.0;          // ft/s (ideal horizontal speed)
            double tolerance = 5.0;             // ft/s tolerance for safe landing

            // Calculate errors from safe landing targets
            double vDownError = projectedVDOWN - targetTouchdownSpeed;  // Positive if too fast
            double hSpeedError = projectedHSpeed - targetHSpeed;        // Positive if right, negative if left

            // Suggest burn adjustments (tuned proportionality constants)
            double vBurnAdjustment = vDownError * 0.1;    // lbs/s per ft/s error
            double hBurnAdjustment = hSpeedError * 0.05;  // Smaller factor for horizontal

            // Clamp adjustments to physical limits
            if (vBurn + vBurnAdjustment > maxVerticalBurn) vBurnAdjustment = maxVerticalBurn - vBurn;
            if (vBurn + vBurnAdjustment < 0) vBurnAdjustment = -vBurn;
            if (hBurn + hBurnAdjustment > maxHorizBurn) hBurnAdjustment = maxHorizBurn - hBurn;
            if (hBurn + hBurnAdjustment < -maxHorizBurn) hBurnAdjustment = -hBurn + maxHorizBurn;

            // Queue feedback
            if (fabs(vDownError) <= tolerance && fabs(hSpeedError) <= tolerance) {
                if (numPending < 100) {
                    pendingCorrections[numPending].evalTime = currentTime;
                    pendingCorrections[numPending].displayTime = currentTime + transmissionDelay + processingDelay;
                    pendingCorrections[numPending].vBurnDiff = 0;
                    pendingCorrections[numPending].hBurnDiff = 0;
                    pendingCorrections[numPending].isConfirmation = 1;
                    numPending++;
                }
            } else {
                if (numPending < 100) {
                    pendingCorrections[numPending].evalTime = currentTime;
                    pendingCorrections[numPending].displayTime = currentTime + transmissionDelay + processingDelay;
                    pendingCorrections[numPending].vBurnDiff = vBurnAdjustment;
                    pendingCorrections[numPending].hBurnDiff = hBurnAdjustment;
                    pendingCorrections[numPending].isConfirmation = 0;
                    numPending++;
                }
            }
        }
    }

    // Evaluate Landing Outcome
    if (altitude <= 0) {
        if (altitude < 0) altitude = 0;
        printf("\n");
        printf("Touchdown at t = %.1f s\n", currentTime);
        printf("Final Downward Speed: %.2f ft/s\n", vDown);
        printf("Final Horizontal Speed: %.2f ft/s\n", horizSpeed);
        if ((vDown <= targetTouchdownSpeed) && (fabs(horizSpeed) <= 5)) {
            printf("\033[32mPerfect Landing! Impact speed is safe.\033[0m\n");
        } else if ((vDown <= 15) && (fabs(horizSpeed) <= 15)) {
            printf("\033[32mGood Landing (minor impact).\033[0m\n");
        } else {
            printf("\033[31mCrash Landing! Impact speed is too high.\033[0m\n");
        }
    } else if (currentTime >= timeLimit) {
        printf("\nSimulation aborted after reaching the time limit.\n");
    }

    return 0;
}