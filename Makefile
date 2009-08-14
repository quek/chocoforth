chocoforth: chocoforth.o
	ld -o chocoforth chocoforth.o
	./chocoforth

.SUFFIXES: .asm

.asm.o:
	nasm -f elf64 $<

chocoforth.o: chocoforth.asm Makefile
