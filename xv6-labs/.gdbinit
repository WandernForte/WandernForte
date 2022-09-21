add-auto-load-safe-path ./.gdbinit
set confirm off
set architecture riscv:rv64
@REM target remote 127.0.0.1:26000
symbol-file kernel/kernel
set disassemble-next-line auto
