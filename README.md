# angryIPsym

The Test-NetworkRange function must be loaded into your PowerShell session. This typically happens if the script containing the function was not executed or loaded correctly. Here's how you can resolve it:

Save your script as a .ps1 file, for example, NetworkScanner.ps1.
Verify the file contains the Test-NetworkRange function.
Navigate to the Script's Directory:

In PowerShell, use the cd command to navigate to the directory where your script is saved:
powershell:

Copy code
cd "C:\Path\To\Your\Script"
Dot-Source the Script: To load the script into the current session, use dot-sourcing:

powershell
Copy code
. .\NetworkScanner.ps1
(Note the space between the two dots at the start.)

This step ensures that the Test-NetworkRange function is available in the current PowerShell session.

Run the Function: Now, call the Test-NetworkRange function:

powershell
Copy code
Test-NetworkRange -StartIP "192.168.0.1" -EndIP "192.168.0.254"
