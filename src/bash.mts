// This compiles to bash.exe
console.log('\x1b[32mGOOD: $Path was respected. ./bin/bash.exe stub received positional arguments:\x1b[0m');
console.dir(Deno.args);