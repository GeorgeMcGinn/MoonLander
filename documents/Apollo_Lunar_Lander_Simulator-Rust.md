# Apollo Lunar Lander Simulator - Rust Installation

This is the Rust version of the Apollo Lunar Lander Simulator (version 1.0.0), created by George McGinn on 04/02/2025. Below are the steps to install Rust to compile and run the program.

## Instructions for Installing Rust

### Installing Rust
To compile and run the `moonLander.rs` program, you need the Rust compiler (`rustc`). Follow the instructions for your operating system.

1. **Windows**

   - **Install Rust via rustup**:
     - Download and run the `rustup` installer from [https://www.rust-lang.org/tools/install](https://www.rust-lang.org/tools/install).
     - Open a web browser, navigate to the Rust website, and click "Get Started" to download `rustup-init.exe`.
     - Run `rustup-init.exe` and follow the prompts. Choose the default installation (stable toolchain) by pressing Enter.

   - **Add Rust to PATH** (optional, usually automatic):
     - The installer typically adds Rust to your system PATH. If not, manually add `C:\Users\YourName\.cargo\bin` to PATH:
       ```text
       Right-click "This PC" > "Properties" > "Advanced system settings" > "Environment Variables."
       Under "User variables," find "Path," click "Edit," and add the path above.
       ```

   - **Verify the installation**:
     - Open a Command Prompt and type:
       ```bash
       rustc --version
       ```
     - You should see the Rust compiler version (e.g., `rustc 1.81.0`).

2. **macOS**

   - **Install Rust via rustup**:
     - Open the Terminal and run:
       ```bash
       curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
       ```
     - Follow the prompts. Choose the default installation by pressing `1` and Enter.
     - After installation, restart your Terminal or run:
       ```bash
       source $HOME/.cargo/env
       ```

   - **Verify the installation**:
     - In the Terminal, type:
       ```bash
       rustc --version
       ```
     - You should see the Rust compiler version information.

3. **Linux (Ubuntu/Debian)**

   - **Install Rust via rustup**:
     - Open a terminal and run:
       ```bash
       curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
       ```
     - Follow the prompts. Choose the default installation by pressing `1` and Enter.
     - After installation, restart your terminal or run:
       ```bash
       source $HOME/.cargo/env
       ```

   - **Verify the installation**:
     - In the terminal, type:
       ```bash
       rustc --version
       ```
     - You should see the Rust compiler version information.

### Compiling and Running `moonLander.rs`
Once Rust is installed, follow these steps to compile and run `moonLander.rs`.

- **Save the Source Code**:
  - Copy the Rust code into a file named `moonLander.rs`.
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
    rustc moonLander.rs
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

- **"rustc: command not found"**:
  - Ensure Rust is installed correctly and added to your PATH.
  - On Windows, verify that `C:\Users\YourName\.cargo\bin` is in PATH.
  - On macOS/Linux, run `source $HOME/.cargo/env` or restart your terminal.

- **Compilation Errors**:
  - Check that `moonLander.rs` is error-free. Syntax issues or missing dependencies may cause failures.
  - If errors persist, run `rustc --explain <error_code>` (e.g., `rustc --explain E0689`) for details.

- **Permission Issues (macOS/Linux)**:
  - If you get a permission denied error, make the executable runnable:
    ```bash
    chmod +x moonLander
    ```

## Final Notes
These instructions ensure you can set up a Rust environment to compile and play `moonLander.rs`. The game is written in Rust and compiled with `rustc` for a standalone executable, avoiding dependencies like Cargo for simplicity.

Enjoy your lunar landing adventure!