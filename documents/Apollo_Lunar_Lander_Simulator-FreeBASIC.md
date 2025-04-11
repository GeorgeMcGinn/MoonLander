# Apollo Lunar Lander Simulator - FreeBASIC Installation

This is the FreeBASIC version of the Apollo Lunar Lander Simulator (version 1.0.0), created by George McGinn on 04/02/2025. Below are the steps to install FreeBASIC to compile and run the program.

## Instructions for Installing FreeBASIC

### Installing FreeBASIC
To compile and run the `moonLander.bas` program, you need the FreeBASIC compiler (`fbc`). Follow the instructions for your operating system.

1. **Windows**

   - **Download FreeBASIC**:
     - Visit [https://sourceforge.net/projects/fbc/](https://sourceforge.net/projects/fbc/) and download the latest `FreeBASIC-x.xx.x-win64.zip` (e.g., `FreeBASIC-1.10.1-win64.zip`) for 64-bit systems or `FreeBASIC-x.xx.x-win32.zip` for 32-bit systems.

   - **Extract the Archive**:
     - Unzip the downloaded file to a directory (e.g., `C:\FreeBASIC`) using a tool like 7-Zip or Windows File Explorer.
     - No further installation is required; the compiler (`fbc.exe`) is ready to use.

   - **Add FreeBASIC to PATH** (optional, for convenience):
     - Add the FreeBASIC `bin` directory (e.g., `C:\FreeBASIC\bin`) to your system’s PATH:
       ```text
       Right-click "This PC" > "Properties" > "Advanced system settings" > "Environment Variables."
       Under "System variables," find "Path," click "Edit," and add the bin directory path.
       ```

   - **Verify the Installation**:
     - Open a Command Prompt and type:
       ```bash
       fbc --version
       ```
     - You should see the FreeBASIC version (e.g., `FreeBASIC-1.10.1`).

2. **macOS**

   - **Note on macOS Support**:
     - FreeBASIC does not officially provide pre-built binaries for macOS. You can compile it from source or use a virtual machine running Windows/Linux. Below are steps to attempt a source build, but success may vary depending on your macOS version.

   - **Install Dependencies**:
     - Install Xcode Command Line Tools for `gcc`:
       ```bash
       xcode-select --install
       ```
     - Install Homebrew (optional, for additional libraries):
       ```bash
       /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
       ```
     - Install required libraries:
       ```bash
       brew install libffi ncurses
       ```

   - **Download and Build FreeBASIC**:
     - Download the source from [https://sourceforge.net/projects/fbc/](https://sourceforge.net/projects/fbc/) (e.g., `FreeBASIC-1.10.1-source.tar.gz`).
     - Extract the archive:
       ```bash
       tar xzf FreeBASIC-1.10.1-source.tar.gz
       cd FreeBASIC-1.10.1-source
       ```
     - Build with macOS-specific flags (may require adjustments):
       ```bash
       make FBFLAGS="-asm att" ENABLE_XQUARTZ=1
       sudo make install
       ```
     - Note: You may encounter errors (e.g., missing `ffi.h` or linker issues). Check forums like [freebasic.net](https://freebasic.net) for community solutions.

   - **Verify the Installation** (if successful):
     - In the Terminal, type:
       ```bash
       fbc --version
       ```
     - You should see the FreeBASIC version information.

   - **Alternative**:
     - Run FreeBASIC in a Linux virtual machine using VirtualBox or Docker, following the Linux instructions below.

3. **Linux (Ubuntu/Debian)**

   - **Install Dependencies**:
     - Open a terminal and update the package list:
       ```bash
       sudo apt update
       ```
     - Install required libraries:
       ```bash
       sudo apt install -y gcc g++ libncurses5-dev libffi-dev libgl1-mesa-dev libx11-dev libxext-dev libxrender-dev libxrandr-dev libxpm-dev libtinfo5
       ```
     - For 32-bit FreeBASIC on a 64-bit system, add:
       ```bash
       sudo apt install -y gcc-multilib g++-multilib lib32ncurses5-dev libx11-dev:i386 libxext-dev:i386 libxrender-dev:i386 libxrandr-dev:i386 libxpm-dev:i386
       ```

   - **Download FreeBASIC**:
     - Visit [https://sourceforge.net/projects/fbc/](https://sourceforge.net/projects/fbc/) and download the latest `FreeBASIC-x.xx.x-linux-x86_64.tar.gz` (e.g., `FreeBASIC-1.10.1-linux-x86_64.tar.gz`) for 64-bit or `FreeBASIC-x.xx.x-linux-x86.tar.gz` for 32-bit.

   - **Extract and Install**:
     - Extract the archive:
       ```bash
       tar xzf FreeBASIC-1.10.1-linux-x86_64.tar.gz
       cd FreeBASIC-1.10.1-linux-x86_64
       ```
     - Run the install script:
       ```bash
       sudo ./install.sh -i
       ```

   - **Verify the Installation**:
     - In the terminal, type:
       ```bash
       fbc --version
       ```
     - You should see the FreeBASIC version information.

### Compiling and Running moonLander.bas
Once FreeBASIC is installed, follow these steps to compile and run `moonLander.bas`.

- **Save the Source Code**:
  - Copy the FreeBASIC code into a file named `moonLander.bas`.
  - Save it in a directory (e.g., `C:\Users\YourName\LunarLander` on Windows or `~/LunarLander` on macOS/Linux).

- **Open a Terminal or Command Prompt**:
  - Windows: Use Command Prompt or PowerShell.
  - macOS/Linux: Open the Terminal.

- **Navigate to the Directory**:
  - Use the `cd` command:
    ```bash
    cd C:\Users\YourName\LunarLander  # Windows
    cd ~/LunarLander                  # macOS/Linux
    ```

- **Compile the Program**:
  - Run:
    ```bash
    fbc moonLander.bas
    ```
  - This creates an executable named `moonLander` (or `moonLander.exe` on Windows).

- **Run the Program**:
  - On Windows:
    ```bash
    moonLander.exe
    ```
  - On macOS/Linux:
    ```bash
    ./moonLander
    ```

The game will start, and you can begin piloting the lunar lander!

### Troubleshooting

- **"fbc: command not found"**:
  - Ensure FreeBASIC is installed and in your PATH.
  - On Windows, add `C:\FreeBASIC\bin` to PATH if not already done.
  - On Linux, verify the install script ran successfully.
  - On macOS, confirm the source build completed or consider using a virtual machine.

- **Missing Library Errors**:
  - On Linux, install missing dependencies (e.g., `sudo apt install libncurses5-dev`).
  - On macOS, check for missing `libffi` or other libraries and install via Homebrew.

- **Permission Issues (macOS/Linux)**:
  - Make the executable runnable:
    ```bash
    chmod +x moonLander
    ```

- **macOS Compilation Issues**:
  - If source compilation fails, consult [freebasic.net forums](https://freebasic.net) for specific error fixes or use a Linux/Windows environment.

## Final Notes
These instructions ensure you can set up a FreeBASIC environment to compile and play `moonLander.bas`. The game is written in FreeBASIC, and the compiler produces standalone executables.

Note that macOS support is unofficial and may require extra effort. For a smoother experience, consider running FreeBASIC on Windows or Linux, possibly in a virtual machine on macOS.

Enjoy your lunar landing adventure!