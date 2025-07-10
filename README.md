Perl SSH Login GUI 🐫
Welcome to the Perl SSH Login GUI, a powerful and user-friendly tool crafted in the legendary Perl programming language! 🚀 With the spirit of the Perl camel guiding us, this script provides a graphical interface for SSH connections, command execution, and remote server management. Whether you're a sysadmin, developer, or ethical hacker, this tool harnesses Perl’s cryptic magic to make SSH tasks intuitive and efficient.
Built with Tk for a sleek GUI and Net::OpenSSH for robust SSH connectivity, this script is a modern tribute to Perl’s golden era of the 2000s, when the camel roamed freely across CGI scripts and system automation. 🐫
Features 🌟

Graphical Interface: A clean Tk-based GUI with input fields for host, username, port, identity file, and password.
Flexible Authentication: Supports both password and key-based SSH authentication, with a “Key-Only” option to disable passwords.
Command History: A ComboBox dropdown stores up to 20 recent commands (e.g., ls -la, whoami, pwd) for quick reuse.
Persistent Connections: Optional “Keep Connection Alive” mode to reuse SSH sessions for multiple commands.
Secure File Selection: Browse for SSH key files with a FileDialog for easy identity file selection.
Rich Output: Scrollable, read-only text area displays stdout, stderr (in red), and detailed logs with timestamps.
Robust Error Handling: Validates inputs, handles connection timeouts with Time::HiRes::alarm, and provides clear error messages.
Security Focus: Input sanitization, password masking, and attempts to zeroize passwords in memory (with a warning about Perl’s limitations).
Hacker-Friendly: Ideal for penetration testing, server automation, or exploring remote systems in a lab environment (use ethically!).

Screenshot 📸
 (Placeholder: Add a screenshot of the GUI in action!)
Installation 🛠️
Prerequisites

Perl: Version 5.10 or later (pre-installed on most Linux systems; use Strawberry Perl for Windows).
SSH Client: Required for Net::OpenSSH (e.g., OpenSSH’s ssh binary).
Perl Modules:
Net::OpenSSH
Tk
Tk::ROText
Tk::ComboBox
Tk::Checkbutton
Tk::FileDialog
Term::ReadKey
Time::HiRes
File::Basename



Steps

Install Perl and SSH:
Linux (e.g., Ubuntu/Kali): sudo apt-get install perl openssh-client
Windows: Install Strawberry Perl and OpenSSH.


Install Perl Modules:cpan Net::OpenSSH Tk Tk::ROText Tk::ComboBox Tk::Checkbutton Tk::FileDialog Term::ReadKey Time::HiRes File::Basename


On Linux, you may need perl-tk: sudo apt-get install perl-tk.


Download the Script:
Save the script as ssh_gui.pl from this repository.


Set Permissions (Linux):chmod +x ssh_gui.pl



Usage 🚀

Run the Script:./ssh_gui.pl


On Windows: perl ssh_gui.pl or double-click if Perl is associated with .pl files.


Configure SSH:
Host: Enter the target server (e.g., example.com or 192.168.1.100).
Username: Your SSH username (e.g., user).
Port: Default is 22; change if needed.
Identity File: Browse for your SSH key (e.g., ~/.ssh/id_rsa) or leave blank for password auth.
Password: Enter your password (masked with *); disable with “Key-Only Authentication.”
Command: Type a command (e.g., whoami) or select from the history dropdown.


Options:
Check “Key-Only Authentication” to force key-based login.
Check “Keep Connection Alive” to reuse the SSH session for multiple commands.


Execute:
Click “Connect & Execute” to connect and run the command.
View results in the output area (stdout, stderr, errors).
Use “Clear Output” to reset the log.


Exit:
Close the window to disconnect cleanly (if connected).



Example
To list files on a server:

Host: 192.168.1.100
Username: user
Port: 22
Identity File: ~/.ssh/id_rsa
Command: ls -la
Click “Connect & Execute” → Output shows directory listing.

Security Notes 🔒

Password Storage: Passwords entered in the GUI are stored in memory and not fully zeroized due to Perl’s memory management. Use key-based authentication for better security (enabled via “Key-Only” checkbox).
Host Key Checking: StrictHostKeyChecking is disabled in the code for testing (commented out). Enable it in production to prevent MITM attacks:master_opts => [-o => "StrictHostKeyChecking=yes"]


Input Sanitization: Host, username, and port are validated to prevent injection attacks, but always verify inputs in a production environment.
Ethical Use: Use this tool only on systems you own or have explicit permission to access. Unauthorized access is illegal.

For Hackers 🕵️‍♂️
This tool is a perfect fit for ethical hacking and penetration testing:

Pentest Labs: Use with Metasploitable 2 or TryHackMe to practice SSH-based attacks.
Automation: Script repetitive SSH tasks for recon or exploitation.
Extensibility: Add exploit modules (e.g., VSFTPD backdoor) or integrate with tools like Metasploit.
Perl Power: Leverage Perl’s regex and socket magic for custom hacking scripts.

“There’s more than one way to hack it!” – Perl’s motto, adapted for pentesters. 🐫
Troubleshooting 🛠️

Module Not Found: Ensure all CPAN modules are installed (cpan <module>).
SSH Connection Fails:
Verify ssh binary is installed (which ssh).
Check host, port, and credentials.
Enable StrictHostKeyChecking=no for testing (uncomment in code).


Tk Issues: Install perl-tk on Linux or ensure Strawberry Perl includes Tk on Windows.
Errors in Output: Check the GUI’s red stderr messages for clues.

Contributing 🤝
Contributions are welcome! Fork this repo, add features (e.g., exploit modules, logging), and submit a pull request. Let’s keep the Perl camel galloping! 🐫
Acknowledgments 🙏

Perl Community: For keeping the camel alive since 1987.
Net::OpenSSH & Tk Authors: For robust SSH and GUI libraries.
You: For choosing Perl as your hacking ally!

License 📜
This project is licensed under the MIT License. See LICENSE for details.

“The Perl Camel never forgets its roots, nor its power to trek through the toughest servers.”Happy hacking with Perl SSH Login GUI! 🐫
