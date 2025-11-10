set shell := ["bash", "-c"]
default:
    cat error_message.txt
    @if wslinfo --version >/dev/null ; then echo "WSL version: $(wslinfo --version) (this proves we're inside WSL, which we should not be)" ; fi

shebang:
    #!bash -c
    cat error_message.txt
    if wslinfo --version >/dev/null ; then echo "WSL version: $(wslinfo --version) (this proves we're inside WSL, which we should not be)" ; fi