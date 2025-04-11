# How to Play: Moon Lander Simulation Game

Welcome to the **Moon Lander Simulation**! In this game, you take on the role of an astronaut piloting the Lunar Excursion Module (LEM) as it descends to the Moon's surface. Starting at 7,500 feet above the lunar surface, the Apollo Guidance Computer (AGC) has failed, leaving you in manual control of the descent. Your task is to land the LEM safely using limited fuel, guided by feedback from Mission Control. Here’s everything you need to know to play.

---

## Starting Parameters
- **Altitude**: 7,500 ft  
- **Vertical Speed (vDown)**: 200-700 ft/s (downward) \* 
- **Horizontal Speed**: 50-200 ft/s  \*
- **Initial Mass**: 16,237 lbs
- **Descent Dry Mass**: 4,700 lbs
- **Descent Fuel**: 1,500 lb (used for landing)  
- **Ascent Dry Mass**: 4,850 lb
- **Ascent Fuel Mass**: 5,187 lb
- **Lunar Orbital Speed**: 5,512 ft/s
- **Lunar Gravity**: 5.33136483 ft/s² (approximately 1/6th of Earth’s gravity)  
- **Exhaust Velocity ($V_{ex}$)**: 10,000 ft/s (engine efficiency)  

\* NOTE: Vertical and horizontal speeds are randomized at the start of the game. 

---

## Objective
Land the LEM safely on the lunar surface with:

- **Vertical impact speed** ≤ 5 ft/s  
- **Horizontal speed** ≤ 5 ft/s  

Meeting both criteria results in a "perfect landing." You must manage your 1,500 lb of descent fuel carefully, as it’s insufficient to abort and return to orbit.

---

## Gameplay Controls
1. **Input Burn Duration and Rates**:  
   At each step, you’ll be prompted to enter three values:  
   - **Duration**: Time (in seconds) to apply the burn rates. Enter `-1` to abort the landing.  
   - **Vertical Burn Rate (vBurn)**: Fuel consumption rate for the descent engine (0 to 200 lb/s). Controls upward thrust to slow your descent.  
   - **Horizontal Burn Rate (hBurn)**: Fuel consumption rate for lateral thrusters (-10 to 10 lb/s). Adjusts horizontal speed.  
   - **Example**: Entering `5 100 2` (`5,100,2` for QB64) applies a 100 lb/s vertical burn and a 2 lb/s horizontal burn for 5 seconds, using 500 lbs of fuel (100 lbs a second for 5 seconds).

2. **Simulation Time Step**:  
   - The simulation updates in fixed 0.1-second increments using the Runge-Kutta 4th order (RK4) method for accurate motion calculations.  
   - Unlike some simulations, there’s no adaptive time step; control is entirely manual.

3. **Abort Option**:  
   - Enter a negative duration (e.g., `-1`) followed by two zeroes to attempt an abort and return to orbit using ascent fuel.  
   - **Conditions for Abort**:  
     - Altitude must be above 100 ft.  
     - Ascent fuel must remain.  
   - The game calculates if you have enough delta-v to reach orbit; if not, the abort fails.

---

## Game Features
1. **Text-Based Interface**:  
   - Displays the LEM’s current state after each input, including:  
     - Time elapsed  
     - Altitude  
     - Vertical speed (vDown)  
     - Horizontal position and speed  
     - Fuel remaining (descent and ascent)  
     - Total mass  
     - Current burn rates (vBurn and hBurn)  
   Sample game display:
         ```text
         Lunar Lander: AGC failed. Altitude=7500 ft, vDown=401 ft/s, hSpeed=108 ft/s
         Input duration (s, -1 to abort), vBurn (0-250), hBurn (-10 to 10)
         t=0.00s  Alt=7500.000  vDown=401.000  hPos=0.000  hSpeed=108.000  Fuel=1500.000
         >> 
         ```
2. **Mission Control Feedback**:  
   - After each input, Mission Control provides optimal burn rate suggestions:  
     - **Yellow**: Adjust vBurn or hBurn if outside tolerance.  
     - **Red**: Warnings for excessive descent or horizontal speed.  
     - **Yellow (altitude < 1,000 ft)**: Suggests shorter burn durations for precision.  
   - The game enforces a time delay as to when you receive feedback from Mission Control. Signal speed is 1.3 seconds each way, and it would take an additional 2 seconds for the team and the mainframe to process the corrections. This simulates Mission Control receiving your telemetry after a burn, the time to process it and calculate the correction if needed, and the time to transmit it back to you.
3. **Landing Outcome**:  
   - Evaluated based on final speeds:  
     - **Perfect Landing**: vDown ≤ 5 ft/s and |horizSpeed| ≤ 5 ft/s (green text).  
     - **Good Landing**: vDown ≤ 15 ft/s and |horizSpeed| ≤ 15 ft/s (green text, minor impact).  
     - **Crash Landing**: Speeds exceed thresholds (red text).  

---

## Tips for Success
- **Follow Feedback**: Use Mission Control’s optimal burn suggestions to refine your inputs. Keep in mind that this advice will come at least 4.6 seconds after the burn it references.  
- **Conserve Fuel**: Avoid excessive burns early on; 1,500 lbs of descent fuel depletes quickly at high rates.  
- **Fine-Tune Near Surface**: Below 1,000 ft, use shorter durations (e.g., 1-2 seconds or fractional like .1) for precision.  
- **Balance Speeds**: Adjust vBurn to slow descent and hBurn to minimize horizontal drift.  
- **Abort Strategically**: Only abort if you’re high enough; otherwise, commit to landing.

---

## Key Points on Astronaut Behavior
In this simulation, you manually control the LEM’s descent, mirroring how Apollo astronauts took over when automation failed. Mission Control’s real-time (time delayed) feedback simulates the guidance provided during missions like Apollo 11. Your success depends on interpreting this advice and making precise adjustments to land safely.

---

## Future Enhancements
Potential updates include:  
- Visual lunar surface with obstacles like craters and hills.  
- Mascons that present variable gravity.
- Enhanced telemetry or graphical displays.  
- Greater control over lateral movement and orientation (3D rather than the game's current 2D motion).  

---

**Note**: This is a text-based game with no visual elements. All interactions occur via console input and output.

---