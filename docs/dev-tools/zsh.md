To set up **Zsh** as your default shell in **Visual Studio Code (VS Code)**, follow these steps:

### 1. Install Zsh
If you haven’t already, install Zsh:
- On macOS: `brew install zsh`
- On Ubuntu: `sudo apt install zsh`
- On Fedora: `sudo dnf install zsh`

### 2. Set Zsh as the Default Shell in VS Code
1. **Open VS Code** and go to **Settings**:
   - From the menu, choose `File` > `Preferences` > `Settings`, or use the shortcut `Ctrl + ,`.

2. In the **Settings** search bar, type **Integrated Terminal Shell**.

3. Locate the setting based on your platform (e.g., `Terminal > Integrated > Shell: Linux` or `Terminal > Integrated > Shell: Mac`) and enter the path to Zsh:
   - macOS: `/bin/zsh`
   - Linux: `/usr/bin/zsh`
   - Windows (via WSL): `wsl.exe -d Ubuntu -e zsh` (for Ubuntu WSL) or adapt for your Linux distribution.

4. Alternatively, you can set it directly via **Settings JSON**:
   - Open the Command Palette (`Ctrl + Shift + P` or `Cmd + Shift + P` on macOS) and search for **Preferences: Open Settings (JSON)**.
   - Add the following line to specify Zsh as the default terminal shell:
     ```json
     "terminal.integrated.defaultProfile.<platform>": "zsh"
     ```
   - Replace `<platform>` with `linux`, `macos`, or `windows` depending on your OS.

### 3. Open a New Terminal
After setting it up, open a new terminal in VS Code (`Ctrl + `` or `Cmd + `` on macOS) to start using Zsh as your default shell.

### Optional: Install Oh My Zsh for Enhanced Features
To add plugins and themes, install **Oh My Zsh** by running the following command in the terminal:
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

This setup will give you a Zsh shell in VS Code with all the enhanced autocompletion and customization options.