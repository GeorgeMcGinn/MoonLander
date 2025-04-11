# Apollo Lunar Lander Simulator - Python Installation

This is the Python version of the Apollo Lunar Lander Simulator (version 1.0.0), created by George McGinn on 04/02/2025. Below are the steps to install Python and run the program.



## Python Installation and Execution Steps

### Prerequisites

- A computer with a terminal or command-line interface (Windows, macOS, or Linux).
- Python 3.x installed (the program does not require additional libraries beyond the standard library).

### Directions

1. **Install Python**  
   If Python is not already installed on your system, download and install it from the official Python website:  
   [https://www.python.org/downloads/](https://www.python.org/downloads/)  
   - Choose the latest Python 3.x version (e.g., Python 3.11 or higher).  
   - During installation, ensure you check the option to add Python to your system PATH (especially on Windows).

2. **Save the Script**  
   - Copy the Python code provided above into a file named `moonLander.py`.  
   - Save it in a directory of your choice (e.g., `C:\Users\YourName\LunarLander` on Windows or `~/LunarLander` on macOS/Linux).

3. **Open a Terminal or Command Prompt**  
   - **Windows**: Press `Win + R`, type `cmd` or `powershell`, and press Enter.  
   - **macOS**: Open the "Terminal" application (found in Applications > Utilities).  
   - **Linux**: Open your preferred terminal emulator (e.g., GNOME Terminal, Konsole).

4. **Navigate to the Script Directory**  
   Use the `cd` command to change to the directory where `moonLander.py` is saved. For example:  
   ```bash
   cd C:\Users\YourName\LunarLander  # Windows
   cd ~/LunarLander                  # macOS/Linux
   ```
5. Run the Program
Execute the script by typing one of the following commands:  
```bash
python moonLander.py
```

If python doesn’t work (common on some systems with multiple Python versions), try:  
```bash
python3 moonLander.py
```
The game will start, displaying the introduction and prompting you for input.

## Notes
Input Format: The game expects three numbers separated by spaces (e.g., 5 100 5 for duration, vBurn, and hBurn).  

Colored Output: The program uses ANSI escape codes for colored text (e.g., Mission Control messages in yellow). Most modern terminals (e.g., Windows Terminal, macOS Terminal, Linux terminals) support this, but if colors don’t display correctly, the game will still function normally.  

Gameplay: Follow the on-screen instructions to control the Lunar Module. Enter -1 as the duration to attempt an abort.

## Troubleshooting
If you get a "command not found" error, ensure Python is installed and added to your PATH. You can verify this by running:
```bash
 python --version or python3 --version.  
```
If the script fails to run, check that moonLander.py is saved correctly and that you’re in the right directory.

Enjoy landing on the Moon!


---