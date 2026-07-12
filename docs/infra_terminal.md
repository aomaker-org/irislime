### Troubleshooting: Forcing a Terminal Profile Refresh

If Windows Terminal does not automatically display your newly provisioned distribution in its environment list, its internal configuration registry needs a hard reload. 

To clear it cleanly, copy the command below, tap your **Windows Key**, paste it straight into your taskbar **Search Bar (Magnifying Glass)**, and hit **Enter**:

```cmd
cmd.exe /k taskkill /f /im WindowsTerminal.exe
taskkill /f /im WindowsTerminal.exe: Forcefully terminates all active host and background windows of the terminal suite, saving your current states and forcing a fresh inventory scan on next launch.

cmd.exe /k: Launders the execution through a persistent shell that keeps the command window open. This leaves an active "DOS box" on your screen so you can verify the SUCCESS: The process... has been terminated confirmation log instead of watching a window flash and disappear.


---
The [Taskkill Command Guide](https://www.youtube.com/watch?v=B96XkwK4AKk) is highly relevant here because it provides a clear visual demonstration of using the command-line interface to forcefully stop processes in Windows environments.


http://googleusercontent.com/youtube_content/26
