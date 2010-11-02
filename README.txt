VLCSync will synchronize multiple instances of VLC using their Remote Control interfaces. This is useful for synchronizing a video viewing with a remote partner.

if one of the synchronized, connected instances pauses or plays, VLCSync will attempt to make sure all connected instances are in the same state.
Additionally, VLCSync will try to make sure all connected instances are at the same timestamp in their file.


Usage:
to start up VLC with a remote control interface, use the command:
(unix-style)
vlc <file> --extraintf rc --rc-host <external-ip>:<port to bind to>

to run VLCSync, use the command:
ruby VLCSync.rb [host:port [host:port]...] 

if you specify no host:port pairs on the command line, you will be prompted for them.

VLCSync accepts a '-v' or '--verbose' option, to print debug information to the command prompt.
