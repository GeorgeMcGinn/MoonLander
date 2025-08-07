# Technical Details

## Physics Implementation

- **Integration Method**: Simplified Euler (optimized for C64 performance)
- **Time Steps**: 1-second intervals (historically accurate to AGC cycles)
- **Coordinate System**: Altitude (up), Horizontal position (right positive)
- **Units**: Imperial (feet, pounds, seconds) - consistent with Apollo documentation

## Spacecraft Parameters

```
Descent Stage:
- Dry Mass: 4,700 lbs
- Fuel Capacity: 1,500 lbs
- Max Thrust: 250 lbs/s vertical, ±10 lbs/s horizontal

Ascent Stage:
- Dry Mass: 4,850 lbs  
- Fuel Capacity: 5,187 lbs
- Exhaust Velocity: 10,000 ft/s

Lunar Environment:
- Surface Gravity: 5.33 ft/s²
- No Atmosphere: No drag effects
- Orbital Velocity: 5,512 ft/s
```

## Mission Control System

- **Signal Delay**: 2.6 seconds (Earth-Moon)
- **Processing Delay**: 4.0 seconds (Ground Control)
- **Total Delay**: 6.6 seconds
- **Queue Limit**: 10 pending messages maximum

## Performance Optimizations

- **Maximum Steps**: 20 per burn cycle (prevents long waits)
- **Simplified Constants**: Rounded for faster computation
- **Integer Math**: Where precision allows
- **Selective MC Calls**: Only after 10+ seconds flight time

## Landing Evaluation

- **Perfect Landing**: vDown ≤ 5 ft/s AND |hSpeed| ≤ 5 ft/s
- **Good Landing**: vDown ≤ 15 ft/s AND |hSpeed| ≤ 15 ft/s  
- **Crash Landing**: Impact speeds exceed safe limits

## Development History

This Commodore 64 version represents the culmination of a multi-platform development journey:

1. **Original C Implementation** - Full RK4 integration, high precision
2. **QB64 Port** - Maintained advanced numerical methods
3. **Python Version** - Leveraged mathematical libraries
4. **C64 Adaptation** - Optimized for 1980s hardware constraints

### Key Adaptations for C64

- **RK4 → Euler Integration**: 4× performance improvement
- **Variable Precision**: 3 decimal places for display
- **Memory Management**: Fixed arrays, compact variables
- **UI Redesign**: 40×25 screen optimization

### Color Coding

- **White**: Normal text and status information
- **Green**: Success messages (perfect/good landings, successful abort)
- **Red**: Error messages (crashes, abort failures, invalid inputs)
- **Yellow**: Mission Control communications

## Source Code Structure

**Text-Based Version:**

```
Lines 10-120:    Initialization, constants, and variables
Lines 130-500:   Introduction and instructions (two-screen display)
Lines 540-830:   Main game loop, status display, and input handling
Lines 1000:      Physics integration subroutine (Euler method)
Lines 2000:      Abort sequence handling
Lines 3000:      Mission Control message display subroutine
Lines 4000:      Trajectory analysis and feedback subroutine
Lines 5000:      Landing evaluation and results
Lines 5500:      Program termination
```

**Real-Time Version:**

```
Lines 10-120:    Initialization, constants, and variables
Lines 130-340:   Introduction and instructions  
Lines 360-570:   Real-time game loop with joystick input
Lines 1000:      Physics integration (Euler method)
Lines 2000:      Abort sequence handling
Lines 3000:      Mission Control message display
Lines 4000:      Trajectory analysis and feedback
Lines 5000:      Landing evaluation and results
Lines 6000:      Real-time display update system
```

---
