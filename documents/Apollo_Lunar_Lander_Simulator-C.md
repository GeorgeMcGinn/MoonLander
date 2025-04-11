# Apollo Lunar Lander Simulator - C/C++ Installation

This is the C version of the Apollo Lunar Lander Simulator (version 1.0.0), created by George McGinn on 04/02/2025. Below are the steps to install C or C++ to compile and run the program.

## Instructions for Installing a C Compiler


### Installing a C Compiler
To compile and run the moonLander.c program, you need a C compiler. Follow the instructions for your operating system.

1. **Windows**
- Install MinGW (Minimalist GNU for Windows):
- Download the MinGW installer from https://sourceforge.net/projects/mingw/.

### Run the installer and select the mingw32-base package for the C compiler.

- Complete the installation and add the MinGW bin directory (e.g., C:\MinGW\bin) to your system’s PATH:
```text 
Right-click "This PC" > "Properties" > "Advanced system settings" > "Environment Variables." 
```

- Under "System variables," find "Path," click "Edit," and add the MinGW bin path.

- Verify the installation by opening a Command Prompt and typing:
```bash

gcc --version
```

You should see the GCC version information.

2. **macOS**
- Install Xcode Command Line Tools:
- Open the Terminal and run:
```bash
xcode-select --install
```

- Follow the prompts to install the tools, which include the Clang compiler.

- Verify the installation by typing:
```bash

gcc --version
```
- You should see the Clang version information (aliased as gcc).

3. Linux (Ubuntu/Debian)
- Install GCC: Open a terminal and run:
```bash
sudo apt update
sudo apt install build-essential
```
- This installs GCC and essential tools.

- Verify the installation by typing:
```bash
gcc --version
```

### Compiling and Running moonLander.c
Once the C compiler is installed, follow these steps to compile and run moonLander.c.

- Save the Source Code:
- Copy the C code into a file named moonLander.c.
- Save it in a directory (e.g., C:\Users\YourName\LunarLander on Windows or ~/LunarLander on macOS/Linux).
- Open a Terminal or Command Prompt (Windows: Use Command Prompt, macOS/Linux: Open the Terminal.)
- Navigate to the Directory (Use the cd command):
```bash
cd C:\Users\YourName\LunarLander  # Windows
cd ~/LunarLander                  # macOS/Linux
```
- Compile the Program:
```bash
gcc -o moonLander moonLander.c -lm
```
-o moonLander: Sets the output executable name.
-lm: Links the math library (required for some functions).

- Run the Program:
On Windows:
```bash
moonLander.exe
```
On macOS/Linux:
```bash
./moonLander
```

The game will start, and you can begin playing!

### Troubleshooting
"gcc: command not found": Ensure the compiler is installed and in your PATH.

Math Library Errors: Include -lm in the compile command.

Permission Issues (macOS/Linux): Run chmod +x moonLander if needed.


## Instructions for Installing a C++ Compiler
This section provides steps to install a C++ compiler on Windows, macOS, and Linux. Note: A C++ compiler can also compile C code, but these instructions focus on C++ setup.

### Installing a C++ Compiler
1. Windows
- Install MinGW:
Follow the MinGW installation steps from the C section above, ensuring you also select the mingw32-gcc-g++ package for C++.

Verify with:
```bash
g++ --version
```

- Alternative: Visual Studio Community Edition:
Download from https://visualstudio.microsoft.com/vs/community/.

- During installation, select "Desktop development with C++" to include the C++ compiler.

- Verify by opening the Developer Command Prompt and typing:
```bash
cl
```

2. macOS
- Install Xcode Command Line Tools:
- Follow the same steps as in the C section (they include Clang++, the C++ compiler).
- Verify with:
```bash
clang++ --version
```

3. Linux (Ubuntu/Debian)
- Install G++:
The build-essential package from the C section includes g++.
- Verify with:
```bash
g++ --version
```

### Using a C++ Compiler for moonLander.c (Optional)
If you prefer to use a C++ compiler for moonLander.c, replace the gcc command with:
```bash
g++ -o moonLander moonLander.c -lm
```
Then run it as described in the C section.

## Final Notes
These instructions ensure you can set up a C or C++ environment and play moonLander.c.

The game is written in C, so a C compiler is sufficient, but a C++ compiler works too.

Enjoy your lunar landing adventure!

