as list_sort.gas -o list_sort.o                                                                   
ld -o list_sort list_sort.o -lSystem -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
nasm -f macho64 list_sort.nasm
ld -o list_sortx86 list_sort.o -lSystem -L/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib
