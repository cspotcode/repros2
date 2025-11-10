# `just` `$Path` behavior on Windows

`just` does not resolve shell or interpreter executables like you might expect on Windows,
meaning that it's impossible to use a `bash.exe` from your `$Path` if you have WSL2 installed.
`C:\Windows\System32\bash.exe` always takes precedence. This calls into WSL2, a guest virtual machine. It is not a local bash shell.

This resolution behavior is *not* how other shells behave on Windows, not pwsh nor git bash. Shells respect `$Path`.
If you type `$ foo<enter>` in powershell, git bash, or any other shell, you expect it to find the `foo`
executable by searching `$Path` and `$PATHEXT`. `just` deviates from this expectation, which is why I think `just`'s behavior is a bug.

`just`, by way of `std::process::Command`, skips resolving the executable at all, which means it delegates to `CreateProcessA`. `CreateProcessA` implements [this behavior](https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa?redirectedfrom=MSDN) which gives `System32` priority over everything else.

**But isn't `CreateProcessA`'s resolution the correct (albeit strange) behavior, since it's built-in to Windows?**

I argue: no, not at all. The proof is that *other shells intentionally don't behave this way!* They resolve the target executable according to `$Path`, which matches user expectations.
They don't give `C:\Windows\System32` special treatment.

## How this reproduction works

We place 3 stub executables at the top of our `$Path`, then use various shells and `just` to call those executables by name. If a shell or `just` fails to respect the `$Path`, and if there's a System32 executable by the same name, it may incorrectly call the System32 exe. This is usually not a problem, except that *WSL2 places a bash.exe in System32 and it is not a local bash shell!*

The stubs:
- `helloworld` will be called correctly in all cases, because there are no other `helloworld` executables anywhere on the `$Path`. (at least, not on my machine)  
- `xcopy`: when `just` resolves incorrectly, it will call `C:\Windows\System32\xcopy.exe`  
- `bash`: when `just` resolves incorrectly, it will call `C:\Windows\System32\bash.exe`, which *launches a shell inside the WSL2 virtual machine.*  

This last example, `bash`, is our focus. Not only does it do the wrong thing, it is *very confusing*, potentially *masks the underlying issue* by running an actual shell that's in the wrong environment, and we are *unable to use a Windows bash via $Path for our justfiles* despite being able to do so in other scripting environments.

## Steps to reproduce

On a Windows machine, open a shell. These scripts are written for Powershell, so we'll use that. `powershell` or `pwsh` is fine. *This would work in any shell; feel free to type the commands manually into Git bash if you want.*

Install `deno` dependency and create a few executables in `./bin` which log simple messages. We will use their output
to demonstrate how executables are resolved on `$Path`.

*`deno` is the easiest way I know to create simple `.exe`s from a shell script, but you can use rust, compile C code, or whatever.*

```bash
# In powershell
. ./setup.ps1
```

Now run the test:

```bash
. ./test.ps1
```

### Interpreting the output

Our `helloworld` stub is, as expected, called by all shells including `just`, because there are not conflicting EXEs on `$Path`.

Our `xcopy` stub is called correctly by everything except `just`, demonstrating the bug, although in a contrived way. (C:\windows\System32\xcopy.exe is a bulk file copy utility)

Things get interesting with `bash`.
- `just` incorrectly calls `System32/bash.exe` which executes inside the WSL2 guest VM. We prove this by calling `wslinfo` which is only available inside the guest.
- `pwsh` and `powershell` correctly call the stub because they respect `$Path`.
- `sh` may or may not call the stub. I'm using `busybox` which implements `sh` and `bash` as built-ins, so its behavior is not representative.
- Git bash calls the stub so long as we are careful to set our desired `$PATH`.

Interesting to note that `just`'s own `which()` function resolves to `./bin`, meaning `{{which('bash.exe')}}` shows you a *different* executable than what is spawned by `just --shell bash`.

## References

https://github.com/rust-lang/rust/issues/37519

https://github.com/rust-lang/rust/blob/ac968c466451cb9aafd9e8598ddb396ed0e6fe31/src/libstd/sys/windows/process.rs#L133-L148

Note that the code checks for an explicitly specified `PATH` env var, but it's named `Path` on Windows, and `self.env` will be empty if you haven't customized the environment.

https://learn.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-createprocessa?redirectedfrom=MSDN

Read from "If lpApplicationName is NULL," and note that System32 takes priority *over* the Path env var.