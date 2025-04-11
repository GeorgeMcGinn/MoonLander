# Apollo Lunar Lander Simulator - QB64 (Phoenix Edition) Installation

This is the QB64/QB64pe version of the Apollo Lunar Lander Simulator (version 1.0.0), created by George McGinn on 04/02/2025. Below are the steps to install QB64 BASIC and run the program.



## QB64 Installation and Execution Steps


Download the appropriate package for your operating system over at <https://github.com/QB64-Phoenix-Edition/QB64pe/releases/latest>

1. **Windows**

Make sure to extract the package contents to a folder with full write permissions (failing to do so may result in IDE or compilation errors).

* It is advisable to whitelist the 'qb64pe' folder in your antivirus/antimalware software *

2. **macOS**

Before using QB64-PE make sure to install the Xcode command line tools with:

```bash
xcode-select --install
```

Run ```./setup_osx.command``` to compile QB64-PE for your OS version.

3. **Linux**

Compile QB64-PE with ```./setup_lnx.sh```.

Dependencies should be automatically installed. Required packages include OpenGL, ALSA and the GNU C++ Compiler.

## Usage

Run the ```qb64pe``` executable to launch the IDE, which you can use to edit your .BAS files. From there, hit F5 to compile and run your code.

To generate a binary without running it, hit F11.

Additionally, if you do not wish to use the integrated IDE and to only compile your program, you can use the following command-line calls:

```qb64pe -c yourfile.bas```

```qb64pe -c yourfile.bas -o outputname.exe```

Replacing `-c` with `-x` will compile without opening a separate compiler window.

## Additional Information

More about QB64-PE at our wiki: <https://qb64phoenix.com/qb64wiki>

We have a community forum at: <https://qb64phoenix.com/forum>

Find us on Discord: <https://discord.gg/D2M7hepTSx>

Join us on Reddit: <https://www.reddit.com/r/QB64pe/>