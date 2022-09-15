# Fix for Opera's FFMPEG in Linux
The script was fixed to correctly link the latest version of the library.
One of the exit codes was changed from 1 to 0 so that it does not interfere
with apt post-invoke actions if configured.

The 99-opera-fix file can be put directly into /etc/apt/apt.conf.d after
changing it to reflect the correct path where the script is available.


