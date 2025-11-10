# Hardcode path to git bash here, since we'll be shadowing it by ./bin/bash.exe on $PATH for the sake of our
# reproduction.
$gitbash = 'C:\Program Files\Git\bin\bash.exe'

# Prefix local `./bin` directory to $Path
$env:Path = "$(pwd)/bin;$($env:Path)"

function header($message) { write-host -foregroundcolor blue $message }
function red($message) { write-host -color red $message }
function blue($message) { write-host -color blue $message }

function TestHowShellsResolveAnExecutable($exe) {
    header "=== Spawn $exe via sh ==="
    sh -c "$exe -c 'BAD'"

    header "=== Spawn $exe via git bash ==="
    & $gitbash -c ('export "PATH=$(pwd)/bin:$PATH" ; ' + $exe + ' -c "BAD"')
    # Git bash prefixes its own additions to Path on startup, so we need to re-do ours

    header "=== Spawn $exe via powershell ==="
    powershell -noprofile -c "$exe -c ''"

    if(get-command pwsh) {
        header "=== Spawn $exe via pwsh ==="
        pwsh -noprofile -c "$exe -c ''"
    }
    
    if(get-command busybox) {
        header "=== Spawn $exe via busybox sh ==="
        busybox sh -c "$exe -c 'BAD'"
        header "=== Spawn $exe via busybox bash ==="
        busybox bash -c "$exe -c 'BAD'"
    }

    header "=== Spawn $exe via 'just --shell' ==="
    just --shell $exe

    header "=== Spawn $exe via 'just' with 'set shell :=' ==="
    just --justfile justfile.$exe

    header "=== Spawn $exe via 'just' with '#!' recipe ==="
    just --justfile justfile.$exe shebang
    
    header "=== Resolve $exe via 'just' which() function ==="
    just which $exe

    echo ''
    echo '------------------'
    echo ''
}

TestHowShellsResolveAnExecutable helloworld
TestHowShellsResolveAnExecutable xcopy
TestHowShellsResolveAnExecutable bash