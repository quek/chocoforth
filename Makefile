.SUFFIXES: .asm

.PHONY:	chocoforth

all: chocoforth
	./$< < chocoforth.fs

chocoforth: chocoforth.o
	ld -o $@ $<

.asm.o:
	nasm -g -f elf64 -l $*.lst -o $*.o $<

clean:
	rm -f *~ *.o *.lst chocoforth

chocoforth.o: chocoforth.asm Makefile
