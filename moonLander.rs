// /*
// * moonLander    Version 1.0  04/10/2025
// ***************************************************************************************
// *       PROGRAM: moonLander
// *        AUTHOR: George McGinn
// *                <gjmcginn@icloud.com>
// *  DATE WRITTEN: 04/10/2025
// *       VERSION: 1.0
// *       PROJECT: Apollo Moon Lander Simulator
// *
// *   DESCRIPTION: Interactive game where you pilot the Lunar Module (LEM) after an 
// *                Apollo Guidance Computer (AGC) failure at 7,500 ft. Emergency 
// *                burn errors leave random initial speeds (vDown: 200–700 ft/s, 
// *                horizSpeed: 50–200 ft/s). Manually adjust vBurn and hBurn to land 
// *                safely or abort with ascent fuel. There is also a time delay in
// *                displaying the correction to the user. The time delay is 6.6 seconds
// *                (signlal delay of 2.6 seconds and 4 seconds for Ground Control to
// *                process the correction) and is added to the time when the correction
// *                is evaluated. The correction is displayed at the time of the 
// *                evaluation plus 6.6 seconds.
// *
// * Written by George McGinn
// * 
// * Copyright (C)2025 George McGinn - All Rights Reserved
// * Creative Commons Attribution-NonCommercial-ShareAlike 4.0 (CC BY-NC-SA 4.0)   
// * https://creativecommons.org/licenses/by-nc-sa/4.0/
// * You are allowed to copy, distribute, remix, adapt, and build upon your work, 
// * but only for non-commercial purposes, and must credit me and share your 
// * adaptations under the same license. 
// *
// * Version 1.0 - Created 04/10/2025
// *
// * CHANGE LOG
// ***************************************************************************************
// * 04/10/2025 GJM - New Program. Version 1.0
// ***************************************************************************************
// * Copyright (C)2025 by George McGinn.  All Rights Reserved
// *
// * This program is free software: you can redistribute it and/or modify
// * it under the terms of the GNU General Public License as published by
// * the Free Software Foundation.   
// ***************************************************************************************
// */

use std::io::{self, Write};
use std::thread::sleep;
use std::time::{Duration, SystemTime};

// Simple pseudo-random number generator to replace rand crate
struct SimpleRng {
    seed: u64,
}

impl SimpleRng {
    fn new() -> SimpleRng {
        let seed = SystemTime::now()
            .duration_since(SystemTime::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        SimpleRng { seed }
    }

    // Linear Congruential Generator (LCG) for pseudo-random numbers
    fn next(&mut self) -> u32 {
        self.seed = self.seed.wrapping_mul(6364136223846793005).wrapping_add(1);
        (self.seed >> 33) as u32
    }

    fn gen_range(&mut self, range: std::ops::RangeInclusive<i32>) -> i32 {
        let min = *range.start();
        let max = *range.end();
        min + (self.next() % (max - min + 1) as u32) as i32
    }
}

// RK4 helper functions 
fn compute_vertical_derivatives(state: [f64; 2], net_acc: f64) -> [f64; 2] {
    let mut derivatives = [0.0; 2];
    derivatives[0] = -state[1];  // d(altitude)/dt = -vDown
    derivatives[1] = net_acc;    // d(vDown)/dt = netAcc
    derivatives
}

fn compute_horizontal_derivatives(state: [f64; 2], horiz_acc: f64) -> [f64; 2] {
    let mut derivatives = [0.0; 2];
    derivatives[0] = state[1];   // d(horizPos)/dt = horizSpeed
    derivatives[1] = horiz_acc;  // d(horizSpeed)/dt = horizAcc
    derivatives
}

fn rk4_vertical(altitude: &mut f64, v_down: &mut f64, dt: f64, net_acc: f64) {
    let state = [*altitude, *v_down];
    let k1 = compute_vertical_derivatives(state, net_acc);
    let temp_state = [state[0] + 0.5 * dt * k1[0], state[1] + 0.5 * dt * k1[1]];
    let k2 = compute_vertical_derivatives(temp_state, net_acc);
    let temp_state = [state[0] + 0.5 * dt * k2[0], state[1] + 0.5 * dt * k2[1]];
    let k3 = compute_vertical_derivatives(temp_state, net_acc);
    let temp_state = [state[0] + dt * k3[0], state[1] + dt * k3[1]];
    let k4 = compute_vertical_derivatives(temp_state, net_acc);

    *altitude += (k1[0] + 2.0 * k2[0] + 2.0 * k3[0] + k4[0]) * dt / 6.0;
    *v_down += (k1[1] + 2.0 * k2[1] + 2.0 * k3[1] + k4[1]) * dt / 6.0;
}

fn rk4_horizontal(horiz_pos: &mut f64, horiz_speed: &mut f64, dt: f64, horiz_acc: f64) {
    let state = [*horiz_pos, *horiz_speed];
    let k1 = compute_horizontal_derivatives(state, horiz_acc);
    let temp_state = [state[0] + 0.5 * dt * k1[0], state[1] + 0.5 * dt * k1[1]];
    let k2 = compute_horizontal_derivatives(temp_state, horiz_acc);
    let temp_state = [state[0] + 0.5 * dt * k2[0], state[1] + 0.5 * dt * k2[1]];
    let k3 = compute_horizontal_derivatives(temp_state, horiz_acc);
    let temp_state = [state[0] + dt * k3[0], state[1] + dt * k3[1]];
    let k4 = compute_horizontal_derivatives(temp_state, horiz_acc);

    *horiz_pos += (k1[0] + 2.0 * k2[0] + 2.0 * k3[0] + k4[0]) * dt / 6.0;
    *horiz_speed += (k1[1] + 2.0 * k2[1] + 2.0 * k3[1] + k4[1]) * dt / 6.0;
}

// Modified Correction struct with isConfirmation field
#[derive(Clone, Copy)]
struct Correction {
    eval_time:       f64,  // Time when state was evaluated (end of burn)
    display_time:    f64,  // Time to display correction (evalTime + 6.6)
    v_burn_diff:     f64,
    h_burn_diff:     f64,
    is_confirmation: i32,  // 0 for correction, 1 for confirmation
}

fn main() {
    let gravity = 5.33136483;       // ft/s^2 (lunar gravity)
    let standard_gravity = 32.174;  // ft/s^2 (standard gravity)
    let vex = 10000.0;              // ft/s (exhaust velocity)
    let max_vertical_burn = 250.0;  // lbs/s
    let max_horiz_burn = 10.0;      // lbs/s
    let time_limit = 600.0;         // seconds
    let small_dt = 0.1;

    // --- Initial Conditions (Descent Stage)
    let descent_dry_mass = 4700.0;  // lb (descent stage dry)
    let mut descent_fuel_mass = 1500.0; // lb (descent fuel)

    // --- Ascent Stage Parameters (for abort)
    let ascent_dry_mass = 4850.0;   // lb (ascent stage dry)
    let ascent_fuel_mass = 5187.0;  // lb (ascent fuel)
    let ascent_vex = 10000.0;       // ft/s
    let min_altitude_for_abort = 100.0; // ft (minimum altitude to safely abort)

    // Total mass includes both stages
    let mut mass = descent_dry_mass + descent_fuel_mass + ascent_dry_mass + ascent_fuel_mass; // 16,237 lbs
    let mut altitude = 7500.0;                  // feet
    let mass_slugs = mass / standard_gravity;   // Earth's Standard Gravity (32.174) in ft/s²

    let target_touchdown_speed = 5.0; // ft/s
    let mut rng = SimpleRng::new();
    let mut v_down = 200.0 + rng.gen_range(0..=500) as f64; // 200-700 ft/s
    let mut horiz_speed = 50.0 + rng.gen_range(0..=150) as f64; // 50-200 ft/s
    let mut horiz_pos = 0.0;
    let mut current_time = 0.0;

    // Tolerances for burn corrections (10% of max burns)
    let v_burn_tolerance = 0.1 * max_vertical_burn; // 25 lbs/s (corrected from 20)
    let h_burn_tolerance = 0.1 * max_horiz_burn;    // 1 lbs/s

    // Time Delay for feedback
    let transmission_delay = 2.6;   // Transmission time in seconds
    let processing_delay = 2.0;     // Processing time in seconds

    // Correction queue
    let mut pending_corrections: Vec<Correction> = Vec::with_capacity(100);

    // Game Introduction 
    println!("=========================================================");
    println!("          APOLLO LUNAR LANDER SIMULATOR");
    println!("=========================================================");
    println!();
    println!("Welcome to the Apollo Lunar Lander Simulator!");
    println!("Version 1.0.0 - Created by George McGinn - 04/10/2025");
    println!();
    println!("You are the pilot of the Lunar Module (LEM) when the AGC");
    println!("fails at 7500 ft due to prior burn errors. Initial speeds");
    println!("are random (vDown: 200-700 ft/s, horizSpeed: 50-200 ft/s).");
    println!();
    println!("Starting Conditions:");
    println!("  - Altitude: 7,500 ft");
    println!("  - Vertical Speed: {:.2} ft/s (downward)", v_down);
    println!("  - Horizontal Speed: {:.2} ft/s", horiz_speed);
    println!("  - Descent Fuel: {:.2} lbs", descent_fuel_mass);
    println!("  - Ascent Fuel (for abort): {:.0} lbs", ascent_fuel_mass);
    println!("  - Descent Dry Mass: {:.0} lbs", descent_dry_mass);
    println!("  - Ascent Dry Mass: {:.0} lbs", ascent_dry_mass);
    println!("  - Total Mass: {:.0} lbs", mass);
    println!("  - Total Mass Slugs: {:.3}", mass_slugs);
    println!();
    println!("Controls:");
    println!("  - Duration: Time (seconds) to apply burns (-1 to abort)");
    println!("  - vBurn: Vertical burn rate (0 to 250 lbs/s)");
    println!("  - hBurn: Horizontal burn rate (-10 to 10 lbs/s)");
    println!();
    println!("Objective:");
    println!("Land with vDown <= 5 ft/s and |horizSpeed| <= 5 ft/s for a");
    println!("perfect landing. Receive feedback after each burn to adjust");
    println!("your trajectory. Abort if needed, but ensure you can reach orbit!");
    println!();
    println!("Note: The game also enforces a time delay that the real astronauts.");
    println!("      experienced. The time delay is {:.1} seconds (signal delay of", transmission_delay + processing_delay);
    println!("      {:.1} seconds and {:.1} seconds for Ground Control to process the", transmission_delay, processing_delay);
    println!("      correction).");
    println!();
    println!("Ready to land on the Moon? Let's begin!");
    println!("=========================================================");
    println!();
    sleep(Duration::from_secs(5));

    println!("Lunar Lander: AGC failed. Altitude={:.0} ft, vDown={:.0} ft/s, hSpeed={:.0} ft/s", altitude, v_down, horiz_speed);
    println!("Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10), separated by spaces");

    while altitude > 0.0 {
    
        // Step 1: Display Current State
        if descent_fuel_mass == 0.0 {
            println!("\x1b[31m[WARNING] DESCENT FUEL HAS RUN OUT. CONSIDER ABORT PROCESS.\x1b[0m");
        }
        println!("t={:.2}s  Alt={:.3}  vDown={:.3}  hPos={:.3}  hSpeed={:.3}  Fuel={:.3}", 
            current_time, altitude, v_down, horiz_pos, horiz_speed, descent_fuel_mass);

        // Step 2: Prompt for User Input
        let (duration, v_burn, h_burn) = loop {
            print!(">> ");
            io::stdout().flush().unwrap();
            let mut input = String::new();
            io::stdin().read_line(&mut input).expect("Failed to read line");
            let parts: Vec<&str> = input.trim().split_whitespace().collect();
            if parts.len() != 3 {
                println!("Invalid input. Please enter three numbers separated by spaces.");
                continue;
            }
            match (parts[0].parse::<f64>(), parts[1].parse::<f64>(), parts[2].parse::<f64>()) {
                (Ok(d), Ok(v), Ok(h)) => break (d, v, h),
                _ => {
                    println!("Invalid input. Please enter valid numbers.");
                    continue;
                }
            }
        };

        // Step 3: Handle Abort Condition
        if duration < 0.0 {
            println!("Aborting landing...");
            if altitude < min_altitude_for_abort {
                println!("\x1b[31mToo low to abort safely! Crashing into the surface.\x1b[0m");
                altitude = 0.0;
                break;
            } else if ascent_fuel_mass <= 0.0 {
                println!("\x1b[31mNo ascent fuel left! Cannot reach orbit. Crashing.\x1b[0m");
                altitude = 0.0;
                break;
            } else {
//                let delta_v = ascent_vex * ((ascent_dry_mass + ascent_fuel_mass) / ascent_dry_mass).ln();
                let mass_ratio: f64 = (ascent_dry_mass + ascent_fuel_mass) / ascent_dry_mass;
                let delta_v: f64 = ascent_vex * mass_ratio.ln();
                let lunar_orbital_speed = 5512.0;  // ft/s (approximate speed for lunar orbit)
                if delta_v >= lunar_orbital_speed - horiz_speed.abs() {
                    println!("\x1b[32mAbort successful! Achieved lunar orbit with {:.2} ft/s delta-v.\x1b[0m", delta_v);
                    break;
                } else {
                    println!("\x1b[32mAbort failed! Insufficient delta-v ({:.2} ft/s) to reach orbit.\x1b[0m", delta_v);
                    println!("Continuing landing with remaining fuel.");
                }
            }
        }

        // Step 4: Validate User Inputs 
        if v_burn < 0.0 || v_burn > max_vertical_burn || h_burn < -max_horiz_burn || h_burn > max_horiz_burn {
            println!("Invalid burn rates.");
            continue;
        }

        // Step 5: Simulate the Burn Duration
        let steps = (duration / small_dt) as i32;
        for _ in 0..steps {
            if altitude <= 0.0 {
                break;
            }
            let fuel_used = (v_burn + h_burn.abs()) * small_dt;
            let fuel_used = if fuel_used > descent_fuel_mass { descent_fuel_mass } else { fuel_used };
            descent_fuel_mass -= fuel_used;
            mass = descent_dry_mass + descent_fuel_mass + ascent_dry_mass + ascent_fuel_mass;
            let mass_slugs = mass / standard_gravity;   // Earth's Standard Gravity (32.174) in ft/s²

            // Vertical thrust
            let mass_flow_rate_vertical = v_burn / standard_gravity;  // slugs/s
            let thrust_force_vertical = mass_flow_rate_vertical * vex;  // lbs
            let thrust_acc_vertical = thrust_force_vertical / mass_slugs;  // ft/s² upward
            let net_acc_vertical = gravity - thrust_acc_vertical;  // gravity downward

            // Horizontal thrust
            let mass_flow_rate_horizontal = h_burn.abs() / standard_gravity;  // slugs/s
            let thrust_force_horizontal = mass_flow_rate_horizontal * vex;  // lbs
            let thrust_acc_horizontal = (if h_burn >= 0.0 { 1.0 } else { -1.0 }) * thrust_force_horizontal / mass_slugs;  // ft/s²

            rk4_vertical(&mut altitude, &mut v_down, small_dt, net_acc_vertical);
            rk4_horizontal(&mut horiz_pos, &mut horiz_speed, small_dt, thrust_acc_horizontal);
            current_time += small_dt;

            // Provide Feedback after time delay
            let mut j = 0;
            while j < pending_corrections.len() {
                if current_time >= pending_corrections[j].display_time {
                    if pending_corrections[j].is_confirmation == 1 {
                        println!("\x1b[33m[Mission Control: on t={:.2}s (received on t={:.2}s)] Burn rates are nominal.\x1b[0m",
                            pending_corrections[j].eval_time, pending_corrections[j].display_time);
                    } else {
                        if pending_corrections[j].v_burn_diff > 0.0 {
                            println!("\x1b[33m[Mission Control: on t={:.2}s (received on t={:.2}s)] Increase vBurn by {:.2} lbs/s\x1b[0m",
                                pending_corrections[j].eval_time, pending_corrections[j].display_time, pending_corrections[j].v_burn_diff);
                        } else if pending_corrections[j].v_burn_diff < 0.0 {
                            println!("\x1b[33m[Mission Control: on t={:.2}s (received on t={:.2}s)] Decrease vBurn by {:.2} lbs/s\x1b[0m",
                                pending_corrections[j].eval_time, pending_corrections[j].display_time, -pending_corrections[j].v_burn_diff);
                        }
                        if pending_corrections[j].h_burn_diff > 0.0 {
                            println!("\x1b[33m[Mission Control: on t={:.2}s (received on t={:.2}s)] Increase hBurn by {:.2} lbs/s\x1b[0m",
                                pending_corrections[j].eval_time, pending_corrections[j].display_time, pending_corrections[j].h_burn_diff);
                        } else if pending_corrections[j].h_burn_diff < 0.0 {
                            println!("\x1b[33m[Mission Control: on t={:.2}s (received on t={:.2}s)] Decrease hBurn by {:.2} lbs/s\x1b[0m",
                                pending_corrections[j].eval_time, pending_corrections[j].display_time, -pending_corrections[j].h_burn_diff);
                        }
                    }
                    pending_corrections.remove(j);
                } else {
                    j += 1;
                }
            }
        }

        // Step 6: Queue New Correction or Confirmation
        if altitude > 0.0 {
            // Temporary variables for projection
            let mut projected_altitude = altitude;
            let mut projected_v_down = v_down;
            let mut projected_h_speed = horiz_speed;
            let mut temp_mass = mass;
            let mut temp_fuel = descent_fuel_mass;
            let mut temp_mass_slugs = temp_mass / standard_gravity;
            let projection_dt = 0.1;  // Small time step for projection
            let max_projection_steps = 10000;  // Limit iterations to prevent infinite loop
            let mut step_count = 0;

            // Simulate descent until landing or limit reached
            while projected_altitude > 0.0 && temp_fuel >= 0.0 && temp_mass > 0.0 && step_count < max_projection_steps {
                // Fuel consumption
                let fuel_used = (v_burn + h_burn.abs()) * projection_dt;
                let fuel_used = if fuel_used > temp_fuel { temp_fuel } else { fuel_used };
                temp_fuel -= fuel_used;
                temp_mass = descent_dry_mass + temp_fuel + ascent_dry_mass + ascent_fuel_mass;
                if temp_mass <= 0.0 {
                    break;  // Avoid division by zero
                }
                temp_mass_slugs = temp_mass / standard_gravity;

                // Vertical acceleration
                let mass_flow_rate_vertical = v_burn / standard_gravity;  // slugs/s
                let thrust_force_vertical = mass_flow_rate_vertical * vex;  // lbs
                let thrust_acc_vertical = thrust_force_vertical / temp_mass_slugs;  // ft/s²
                let net_acc_vertical = gravity - thrust_acc_vertical;

                // Horizontal acceleration
                let mass_flow_rate_horizontal = h_burn.abs() / standard_gravity;
                let thrust_force_horizontal = mass_flow_rate_horizontal * vex;
                let thrust_acc_horizontal = (if h_burn >= 0.0 { 1.0 } else { -1.0 }) * thrust_force_horizontal / temp_mass_slugs;

                // Update state using RK4
                rk4_vertical(&mut projected_altitude, &mut projected_v_down, projection_dt, net_acc_vertical);
                // Note: In C, horizPos is updated but not used in feedback; we update a dummy value
                let mut dummy_pos = 0.0;
                rk4_horizontal(&mut dummy_pos, &mut projected_h_speed, projection_dt, thrust_acc_horizontal);
                step_count += 1;
            }

            // Define safe landing targets
            let target_touchdown_speed = 5.0;  // ft/s
            let target_h_speed = 0.0;          // ft/s (ideal horizontal speed)
            let tolerance = 5.0;               // ft/s tolerance for safe landing

            // Calculate errors from safe landing targets
            let v_down_error = projected_v_down - target_touchdown_speed;  // Positive if too fast
            let h_speed_error = projected_h_speed - target_h_speed;        // Positive if right, negative if left

            // Suggest burn adjustments (tuned proportionality constants)
            let mut v_burn_adjustment = v_down_error * 0.1;    // lbs/s per ft/s error
            let mut h_burn_adjustment = h_speed_error * 0.05;  // Smaller factor for horizontal

            // Clamp adjustments to physical limits
            if v_burn + v_burn_adjustment > max_vertical_burn {
                v_burn_adjustment = max_vertical_burn - v_burn;
            }
            if v_burn + v_burn_adjustment < 0.0 {
                v_burn_adjustment = -v_burn;
            }
            if h_burn + h_burn_adjustment > max_horiz_burn {
                h_burn_adjustment = max_horiz_burn - h_burn;
            }
            // Fixed from C code: Original had 'hBurnAdjustment = -hBurn + maxHorizBurn', which was incorrect
            if h_burn + h_burn_adjustment < -max_horiz_burn {
                h_burn_adjustment = -max_horiz_burn - h_burn;
            }

            // Queue feedback
            if v_down_error.abs() <= tolerance && h_speed_error.abs() <= tolerance {
                if pending_corrections.len() < 100 {
                    pending_corrections.push(Correction {
                        eval_time: current_time,
                        display_time: current_time + transmission_delay + processing_delay,
                        v_burn_diff: 0.0,
                        h_burn_diff: 0.0,
                        is_confirmation: 1,
                    });
                }
            } else {
                if pending_corrections.len() < 100 {
                    pending_corrections.push(Correction {
                        eval_time: current_time,
                        display_time: current_time + transmission_delay + processing_delay,
                        v_burn_diff: v_burn_adjustment,
                        h_burn_diff: h_burn_adjustment,
                        is_confirmation: 0,
                    });
                }
            }
        }
    }

    // Evaluate Landing Outcome 
    if altitude <= 0.0 {
        if altitude < 0.0 {
            altitude = 0.0;
        }
        println!();
        println!("Touchdown at t = {:.1} s", current_time);
        println!("Final Downward Speed: {:.2} ft/s", v_down);
        println!("Final Horizontal Speed: {:.2} ft/s", horiz_speed);
        if v_down <= target_touchdown_speed && horiz_speed.abs() <= 5.0 {
            println!("\x1b[32mPerfect Landing! Impact speed is safe.\x1b[0m");
        } else if v_down <= 15.0 && horiz_speed.abs() <= 15.0 {
            println!("\x1b[32mGood Landing (minor impact).\x1b[0m");
        } else {
            println!("\x1b[31mCrash Landing! Impact speed is too high.\x1b[0m");
        }
    } else if current_time >= time_limit {
        println!("\nSimulation aborted after reaching the time limit.");
    }
}