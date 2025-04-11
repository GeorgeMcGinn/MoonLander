# Sample Strategy for Moon Lander Simulation Game
 
This document outlines a general strategy for landing the Lunar Excursion Module (LEM) in the Moon Lander Simulation Game. The strategy uses specific burn rates and durations to manage limited fuel while reducing vertical and horizontal speeds for a safe touchdown. Due to the high initial downward speed and only 500 lb of fuel, a "perfect landing" (vertical speed ≤ 5 ft/s, horizontal speed ≤ 5 ft/s) is challenging, so the focus is on achieving a "good landing" (vertical speed ≤ 15 ft/s, horizontal speed ≤ 15 ft/s).

## Notes on the Real Apollo Guidance Computer (AGC)
The Apollo Guidance Computer (AGC), developed by MIT's Instrumentation Laboratory and used in the Lunar Excursion Module (LEM) during the Apollo missions, was tasked with calculating trajectory burns for lunar landings. Operating with a 16-bit architecture, a clock speed of 0.043 MHz, and 2K words of RAM, it relied on a **second-order accurate, fixed-step size integration method**, likely **Heun's method**. This predictor-corrector approach balanced accuracy and efficiency, with a global truncation error of $O(h^2)$, where $h$ is the step size.

Heun's method involves:
- A predictor step using forward Euler:  
  $y_{n+1} = y_n + h \cdot f(t_n, y_n)$
- A corrector step averaging the initial and predicted slopes:  
  $y_{n+1} = y_n + \frac{h}{2} \cdot \left( f(t_n, y_n) + f(t_{n+1}, y_{n+1}) \right)$

With a step size of approximately **0.5 seconds**, as documented in NASA technical reports, the AGC provided real-time updates for the Lunar Landing Guidance (LLG) program. This method required only two function evaluations per step, fitting the AGC's limited computational resources. However, its fixed-step approach and second-order accuracy made it susceptible to cumulative errors over long durations and less adept at handling rapidly changing dynamics, such as thrust adjustments, without frequent recalculations.

If the LEM uses the Runge-Kutta 4th order method (RK4) to land the LEM, it would complete a safe, perfect landing in about 25 seconds (See **[Ground Control's Use of RK4](Ground_Control's_Use_of_RK4.md)** for how NASA's IBM 360 Mainframe would have calculated the LEM's trajectory).

--- 

## Starting Conditions

- **Altitude**: 7,500 ft  
- **Vertical Speed (vDown)**: 200-700 ft/s (downward) \*  
- **Horizontal Speed**: 50-200 ft/s \* 
- **Descent Fuel**: 1,500 lbs  
- **Ascent Fuel**: 5,187 lbs (reserved for abort only)  
- **Lunar Gravity**: 5.33136483 ft/s²  
- **Exhaust Velocity ($V_{ex}$)**: 10,000 ft/s  

\* Vertical and Horizontal speeds are randomized for each game within the ranges specified above.

---

## Strategy Overview

The descent of the Lunar Excursion Module (LEM) in the Moon Lander Simulation Game is a delicate balance of fuel management and speed control, complicated by a time delay in Mission Control’s feedback. The strategy is divided into four phases, each with distinct goals for adjusting vertical and horizontal burn rates. Rather than relying on specific numbers, this overview provides a conceptual framework to help players develop their own approach to achieving a safe landing—ideally a "perfect landing" (vertical speed ≤ 5 ft/s, horizontal speed ≤ 5 ft/s) or at least a "good landing" (vertical speed ≤ 15 ft/s, horizontal speed ≤ 15 ft/s).

### Fuel Consumption Formula
- **Vertical Fuel**: $vBurn (lb/s) × duration (s)$  
- **Horizontal Fuel**: $|hBurn| (lb/s) × duration (s)$  
- **Total Fuel per Phase**: $(vBurn + |hBurn|) × duration$

When inputting duration and burn rates, the burn rate is for each second. For example, if you put duration=10, vBurn=10, hBurn=10, that will burn 10lbs (vDown) and 10lbs (hDown) every second for a total of 200 lbs of fuel used.

---


### Phase 1: Initial Descent

**Goal**: Begin slowing the descent with minimal fuel use.  
- **Duration**: Early in the descent.  
- **Vertical Burn Rate (vBurn)**: Low to conserve fuel.  
- **Horizontal Burn Rate (hBurn)**: Minimal to start correcting lateral drift.  

**Fuel Management**: Use small burns to stretch fuel reserves while initiating a reduction in vertical speed.

---

### Phase 2: Mid-Descent

**Goal**: Increase vertical burn to further reduce descent speed.  
- **Duration**: Middle of the descent.  
- **Vertical Burn Rate (vBurn)**: Moderate to slow descent more effectively.  
- **Horizontal Burn Rate (hBurn)**: Adjust to manage lateral drift.  

**Fuel Management**: Gradually increase burns as altitude decreases, balancing fuel use with speed reduction.

---

### Phase 3: Approach

**Goal**: Prepare for landing with stronger burns.  
- **Duration**: As the LEM nears the surface.  
- **Vertical Burn Rate (vBurn)**: High to significantly slow descent.  
- **Horizontal Burn Rate (hBurn)**: Fine-tune to minimize lateral speed.  

**Fuel Management**: Commit more fuel here to ensure a safe landing speed, prioritizing vertical control.

---

### Phase 4: Final Descent

**Goal**: Use remaining fuel for a controlled landing.  
- **Duration**: Last moments before touchdown.  
- **Vertical Burn Rate (vBurn)**: Maximum or as needed to meet landing criteria.  
- **Horizontal Burn Rate (hBurn)**: Minimal or zero to stabilize lateral movement.  

**Fuel Management**: Apply short, precise burns to adjust speed and position for touchdown.

---

## Summary of Approach

The strategy focuses on conserving fuel in the early phases by using low burn rates, then progressively increasing burns as the LEM descends to effectively reduce vertical speed. Horizontal adjustments are made gradually to manage lateral drift without excessive fuel consumption. Players must remain adaptable, responding to Mission Control’s feedback—which arrives after a time delay—simulating the real-world communication challenges faced during lunar landings. The key is to prioritize vertical speed reduction while keeping horizontal speed in check, all within the constraints of limited fuel.

---

## Progress Table

| **Phase**         | **Time** | **Altitude** | **vDown** | **Horiz Speed** | **Fuel** | **vBurn** | **hBurn** |
|-------------------|----------|--------------|-----------|-----------------|----------|-----------|-----------|
| Start             | Early    | High         | High      | Moderate        | Full     | -         | -         |
| End Phase 1       | -        | Moderate     | Reduced   | Slightly reduced| High     | Low       | Minimal   |
| End Phase 2       | -        | Lower        | Further reduced | Managed | Moderate | Moderate  | Adjusted  |
| End Phase 3       | -        | Low          | Low       | Minimized       | Low      | High      | Fine-tuned|
| Touchdown         | Final    | 0            | Very low  | Very low        | Minimal  | As needed | Stabilized|

*Note*: Adjust burns based on Mission Control feedback and real-time conditions. The table reflects conceptual milestones rather than exact values.

---

## Using Mission Control Feedback

- **Optimal Burns**: Increase vBurn if vDown remains too high; adjust hBurn for lateral drift.  
- **Warnings**: Red alerts signal urgent speed issues; yellow suggests minor tweaks.  
- **Fine Tuning**: Use 1-2 second bursts (even down to .1 seconds) below 1,000 ft for precision.  

---

## Tips for Players

- **Fuel Management**: Start with low burns to stretch the 1,500 lb limit.  
- **Prioritize vDown**: Vertical speed is the primary landing hazard.  
- **Engaging Challenge**: “With just 1,500 lb of fuel, every burn is a trade-off—can you master the balance for a lunar touchdown?”
