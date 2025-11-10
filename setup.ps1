cd $PSScriptRoot

# Install deno
winget install denoland.deno
deno compile -A -o ./bin/helloworld.exe ./src/helloworld.mts
deno compile -A -o ./bin/xcopy.exe ./src/xcopy.mts
deno compile -A -o ./bin/bash.exe ./src/bash.mts

# Install busybox, another shell we will use to demonstrate the typical
# executable resolution behavior of shells
winget install frippery.busybox-w32