# Apollo Guidance Computer (AGC) Trajectory Calculation and Integration Methods

This document explores the trajectory calculation methods used by the Apollo Guidance Computer (AGC) during lunar landings, its integration techniques, precision, limitations, and how mission control detected and corrected potential errors. It also clarifies the process mission control used to update the AGC when deviations occurred, including whether updates were transmitted directly or relied on astronaut input.

## Key Points
- The AGC used a **second-order integration method**, likely **Heun's method**, for trajectory burns due to its limited processing power.
- The AGC's method had a step size of about **0.5 seconds**, providing sufficient accuracy for lunar landings but with errors of $O(h^2)$.
- Mission control likely used **Runge-Kutta 4 (RK4)** on IBM mainframes for more precise simulations, helping verify and correct AGC errors.
- Mission control compared AGC predictions with real-time telemetry, detecting discrepancies and advising astronauts via **voice communication** if corrections were needed, especially during manual control phases.
- Mission control did not transmit updates directly to the AGC but relied on astronauts to manually adjust controls or input corrections.

---

## AGC's Trajectory Calculation Methods

The Apollo Guidance Computer (AGC), developed by MIT's Instrumentation Laboratory and used in the Lunar Excursion Module (LEM) during the Apollo missions, was tasked with calculating trajectory burns for lunar landings. Operating with a 16-bit architecture, a clock speed of 0.043 MHz, and 2K words of RAM, it relied on a **second-order accurate, fixed-step size integration method**, likely **Heun's method**. This predictor-corrector approach balanced accuracy and efficiency, with a global truncation error of $O(h^2)$, where $h$ is the step size.

Heun's method involves:
- A predictor step using forward Euler:  
  $y_{n+1} = y_n + h \cdot f(t_n, y_n)$
- A corrector step averaging the initial and predicted slopes:  
  $y_{n+1} = y_n + \frac{h}{2} \cdot \left( f(t_n, y_n) + f(t_{n+1}, y_{n+1}) \right)$

With a step size of approximately **0.5 seconds**, as documented in NASA technical reports, the AGC provided real-time updates for the Lunar Landing Guidance (LLG) program. This method required only two function evaluations per step, fitting the AGC's limited computational resources. However, its fixed-step approach and second-order accuracy made it susceptible to cumulative errors over long durations and less adept at handling rapidly changing dynamics, such as thrust adjustments, without frequent recalculations.

### Precision and Limitations
Heun's method offered sufficient precision for lunar landings, with errors decreasing quadratically with step size ($O(h^2)$). Yet, compared to higher-order methods like RK4 (error $O(h^4)$), it was less accurate. The AGC's memory constraints (2K words) and slow clock speed (0.043 MHz) restricted algorithm complexity and recalculation frequency, potentially missing subtle trajectory deviations. Its pre-programmed algorithms further limited adaptability during dynamic maneuvers like lunar descent.

---

## Mission Control's Role in Error Correction

Mission control, equipped with powerful IBM mainframes like the 360 series, supported the AGC by running high-precision offline simulations, likely using **Runge-Kutta 4 (RK4)**. With an error of $O(h^4)$ and four function evaluations per step, RK4 enabled mission control to predict the LEM's trajectory with greater accuracy than the AGC. They continuously monitored real-time telemetry—position, velocity, descent rate—via the Deep Space Network, comparing these with AGC outputs to detect discrepancies caused by computational errors or environmental factors.

When errors were identified, mission control could not transmit real-time updates directly to the AGC due to:
- **Communication Delays**: A 2.6-second round-trip time between Earth and the Moon plus the time it took to verify the results made direct updates impractical during dynamic phases.
- **Bandwidth Constraints**: The era's communication systems lacked the capacity for frequent, detailed updates mid-flight.

Instead, mission control relied on **voice communication** to relay instructions to astronauts via radio. These instructions included:
- Adjusting the descent engine throttle (e.g., "Increase throttle by 15%").
- Changing spacecraft attitude (e.g., "Pitch forward 5 degrees").
- Inputting specific commands or values into the AGC's Display and Keyboard (DSKY).

Astronauts then acted on these directives by:
- Manually adjusting controls (e.g., throttle or hand controller).
- Entering corrections into the AGC as directed.

For example, during Apollo 11, mission control monitored Neil Armstrong’s manual control, advising on fuel levels and descent rates to ensure a safe landing. This process leveraged the AGC's autonomy while using human intervention—guided by mission control’s expertise—as a safety net.

---

### Astronaut Interaction and Manual Control

While the AGC autonomously calculated the descent trajectory using Heun’s method, the astronauts played a vital role in fine-tuning the landing through manual control. Using the throttle lever, they could adjust the engine’s output to correct for deviations such as lateral drift or uneven terrain. Astronauts monitored key parameters—altitude, velocity, and fuel status—via the LEM’s displays, enabling them to supplement the AGC’s guidance with human judgment. This semi-automatic process was especially critical in the final moments of descent, ensuring precise adjustments for a safe touchdown.

During the actual landing phase, the AGC and astronauts were the primary decision-makers, with Ground Control providing support but not directly managing the real-time trajectory. This autonomy was essential due to the 2.6-second communication delay between Earth and the Moon and the need for immediate responses to changing conditions. For instance, during Apollo 11, Neil Armstrong manually steered the Lunar Module to avoid hazards, guided by mission control’s voice updates but relying on the AGC and his own inputs for real-time control.

---

## Historical Examples

Historical records illustrate this correction process:
- **Apollo 11 Lunar Landing**: Mission control tracked telemetry and advised Neil Armstrong via radio on descent rates and fuel status. Armstrong manually steered the Lunar Module to avoid hazards, relying on voice guidance rather than direct AGC updates.
- NASA reports, such as the [Apollo 11 Mission Report](https://ntrs.nasa.gov/citations/19700018598), confirm that real-time guidance was provided through voice communication, not direct transmissions to the AGC.

---

## Comparison of AGC and Mission Control Methods

| Aspect                  | AGC (Heun's Method)                     | Mission Control (RK4)                    |
|-------------------------|-----------------------------------------|------------------------------------------|
| **Integration Order**   | Second-order ($O(h^2)$)                 | Fourth-order ($O(h^4)$)                  |
| **Step Size**           | ~0.5 seconds, fixed                     | Variable, typically smaller for precision|
| **Computational Cost**  | Low, two evaluations per step           | Higher, four evaluations per step        |
| **Hardware**            | 16-bit, 0.043 MHz, 2K RAM               | IBM 360 mainframes, high processing power|
| **Role**                | Real-time guidance, autonomous          | Offline simulation, verification         |
| **Error Correction**    | Limited by step size, no adaptive steps | High precision, used for advising pilots |

This comparison underscores the AGC's efficiency for real-time tasks and mission control's precision for verification and support.

---

## Conclusion

The AGC’s use of Heun’s method, with second-order accuracy ($O(h^2)$) and a 0.5-second step size, was a practical solution for its hardware limitations, delivering reliable guidance for lunar landings. Mission control complemented this with RK4 simulations ($O(h^4)$) on IBM mainframes, detecting errors through telemetry comparisons and advising astronauts via voice communication. The landing was a collaborative effort, blending the AGC’s automated precision with the astronauts’ manual control. Using the throttle lever and LEM displays, astronauts made real-time adjustments, exercising autonomy during critical phases like the Apollo 11 landing. This synergy of technology and human adaptability ensured mission success.

---

## Citations
- [Apollo Guidance, Navigation, and Control](https://ntrs.nasa.gov/citations/19730015184)
- [TN D-5188 Orbital Mechanics](https://ntrs.nasa.gov/citations/19690024558)
- [Apollo 11 Mission Report](https://ntrs.nasa.gov/citations/19700018598)