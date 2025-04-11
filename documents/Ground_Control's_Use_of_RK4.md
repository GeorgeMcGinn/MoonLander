# Ground Control's Use of RK4

Let’s dive into how ground control would use the Runge-Kutta 4th order method (RK4) to manage the Lunar Excursion Module’s (LEM) trajectory during a manual landing, especially if the Apollo Guidance Computer fails. You’ve asked for a detailed explanation of how RK4 updates based on the LEM’s current trajectory, whether it corrects that trajectory to a desired one, and what happens if correction isn’t possible—plus how this could be coded. I’ll break it down step-by-step, focusing on clarity and actionable details for your coding project written in **C**, **Python**, and two dialects of **BASIC** (QB64 and FreeBASIC).

## What is RK4, and Why Use It Here?

RK4 is a numerical method for solving ordinary differential equations (ODEs), which are equations that describe how things change over time—like the LEM’s position and velocity as it descends to the Moon. In this scenario, the LEM’s motion is governed by physical laws (gravity, thrust, etc.), expressed as ODEs. RK4 approximates the solution to these equations by stepping forward in time, predicting where the LEM will be based on its current state and the forces acting on it.

For a manual landing, ground control relies on telemetry data about the LEM’s position, velocity, attitude (orientation), and fuel—sent from the spacecraft. This data arrives with a 1.3-second delay due to signal travel time, and the pilot receives ground control’s instructions after a total delay of 4.6 seconds (2.6 seconds for transmission round-trip and 2 seconds for processing). With the AGC down, they can’t compute onboard, so they use RK4 on Earth to:

- Predict the LEM’s future path based on its current state and pilot inputs.
- Guide the pilot by comparing that prediction to a desired landing trajectory.
- Adapt if needed by calculating a new trajectory when the original plan fails.

## How RK4 Updates Based on the LEM’s Current Trajectory

RK4 doesn’t “update” the LEM’s trajectory directly—it predicts it. The LEM’s current trajectory is its actual path, determined by its state (position, velocity, etc.) and the pilot’s inputs (throttle, attitude adjustments). Ground control uses RK4 to model this trajectory forward in time, step-by-step, based on the latest telemetry received. Here’s how it works:

Current State: At time ( t ), the LEM has a state vector representing its position and velocity. The simulation uses a 2D model, so this includes:
- Altitude (vertical position)
- Vertical speed
- Horizontal position
- Horizontal speed  
**NOTE:** Telemetry provides this data, typically updated every second in the simulation.

Equations of Motion: These are ODEs, like:
- $( \frac{d(\text{altitude})}{dt} = \text{vertical speed} )$
- $( \frac{d(\text{vertical speed})}{dt} = \text{acceleration} )$ (from gravity and thrust)
In general: $( \frac{d\mathbf{y}}{dt} = \mathbf{f}(t, \mathbf{y}, u) ),$ where $( u )$ is the pilot’s control input (e.g., thrust).

**RK4 Steps:** RK4 computes the next state $( \mathbf{y}(t + h) )$ over a small time step $( h )$ (e.g., 0.1 seconds) using four evaluations of $( \mathbf{f} )$:
- $( k_1 = \mathbf{f}(t, \mathbf{y}, u) )$
- $( k_2 = \mathbf{f}(t + h/2, \mathbf{y} + (h/2)k_1, u) )$
- $( k_3 = \mathbf{f}(t + h/2, \mathbf{y} + (h/2)k_2, u) )$
- $( k_4 = \mathbf{f}(t + h, \mathbf{y} + h k_3, u) )$  
Then:  
- $( \mathbf{y}(t + h) = \mathbf{y}(t) + \frac{h}{6}(k_1 + 2k_2 + 2k_3 + k_4) )$

Prediction: Repeat this process over multiple steps to forecast the trajectory (e.g., over the next 10 seconds), assuming the pilot holds the current inputs constant.

Updating: As new telemetry arrives, ground control gets an updated state. They restart RK4 from this new $( \mathbf{y}(t) )$, incorporating the pilot’s latest inputs, and recompute the predicted trajectory. This is a continuous, iterative process, not a one-time calculation.

## Correcting the LEM’s Trajectory to the Desired One

Ground control’s goal is to ensure the LEM lands safely at the target site with near-zero velocity by projecting the current burn forward with RK4. They use RK4 to check if the current trajectory aligns with this goal and, if not, issue corrections. Here’s the process:

**Define the Desired Trajectory:**
- In the simulation, the desired trajectory isn’t a fixed path but a target state at landing: vertical speed ≤ 5 ft/s and horizontal speed ≤ 5 ft/s at zero altitude.

**Predict with RK4:**
- Using the current state and inputs, RK4 generates $( \mathbf{y}_{\text{predicted}}(t + \Delta t) )$ until landing.

**Compare:**
- Compare the predicted state (e.g., final speeds) to the desired state at key times.

**Example differences:**
- Vertical speed too high (e.g., > 5 ft/s).
- Horizontal speed too large (e.g., > 5 ft/s).
- Off-target landing position.

**Calculate Adjustments:**
- If there’s a mismatch, compute changes to inputs:
  - **Throttle:** Increase to slow descent if too fast.
  - **Attitude:** Adjust to reduce horizontal drift.  
- Adjustments are proportional (e.g., throttle change = 0.1 × vertical speed error), clamped to limits (0–250 lbs/s vertical, -10 to 10 lbs/s horizontal).

**Communicate:**
- Send instructions like “Increase throttle by 30 lbs/s” or “Decrease horizontal burn by 2 lbs/s.” After a 4.6-second delay, the pilot applies these, new telemetry reflects the change, and RK4 re-predicts.

This predict-compare-correct loop repeats until the predicted trajectory matches the desired landing conditions.

## What If Correction Isn’t Possible?

If the LEM’s state (e.g., too fast, too little fuel, or too far off course) makes the desired trajectory unachievable, ground control uses RK4 to calculate a new, feasible trajectory. Here’s how:

- **Assess Constraints:**
  - Current position, velocity, fuel, and time to landing.
  - Example: At 500 m altitude, 100 m/s downward, with 20% fuel, the original site 2 km away might be unreachable.

- **Define a New Goal:**
  - Find a closer, safe landing spot (e.g., 500 m away) with a target of near-zero velocity at touchdown.

- **Compute New Trajectory:**
  - Plan a path minimizing fuel and ensuring a soft landing (< 2 m/s).
  - Use RK4 to simulate this path from the current state, testing feasibility with remaining resources.

- **Guide the Pilot:**
  - Issue updated commands (e.g., “Reduce throttle to 50%, shift left 20 degrees”) and resume the predict-compare-correct loop.  
  - Instructions are queued and displayed after the 4.6-second delay (2.6s transmission, 2s processing), adding realism.

RK4’s fixed-step, four-evaluation process was feasible for 1960s computers, balancing accuracy with speed, much like Apollo contingency strategies.

## Summary

- **Updating:** RK4 predicts the trajectory from the latest telemetry, refreshing iteratively.
- **Correcting:** It compares the prediction to the desired landing state, guiding the pilot to align them.
- **Re-planning:** If correction fails, RK4 simulates a new, safe trajectory.

This balances realism and playability across your **C**, **Python**, **QB64**, and **FreeBASIC** simulations. Start with basic dynamics and an RK4 integrator, then refine the target state and correction logic to enhance the challenge.