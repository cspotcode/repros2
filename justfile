set unstable := true

default:
    cat error_message.txt
    @if wslinfo --version >/dev/null ; then echo "WSL version: $(wslinfo --version) (this proves we're inside WSL, which we should not be)" ; fi

which exe:
    #!powershell -noprofile
    echo '{{which(exe + '.exe')}}'