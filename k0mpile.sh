set -x
fasm speedupavx2.asm
ld -shared speedupavx2.o -o libspeedupavx2.so -lc
g++ -Wall -O -pthread main.cpp -L. -lspeedupavx2 -o bench
fasm list_sort.asm
