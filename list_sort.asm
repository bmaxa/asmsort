format elf64 executable 3 at 0x100000000
struc Node {
	.next dq ?
	.data dd ?
	.size = $-.next
}
virtual at 0
	n Node
end virtual
include 'import64.inc'
interpreter '/lib64/ld-linux-x86-64.so.2'
needed 'libc.so.6','./libspeedupavx2.so'

import atoi,printf,puts,exit,rand_r,time,malloc, \
       radix_sort_avx2

segment executable
entry $
	mov [N],4096*4096
	cmp [rsp],dword 1
	je .skip
	mov rdi,[rsp+16]
	call [atoi]
	cmp eax,1
	jl .exit
	mov [N],eax

.skip:
	xor edi,edi
	call [time]
	mov [seed],eax ; seed on time
	mov rdi,fmt1
	mov esi,[seed]
	xor eax,eax
	call [printf] ; print seed

	mov rdi,fmt4
	mov esi,[N]
	xor eax,eax
	call [printf]
	mov rbx,list1
	push rbx
	call init_list
	mov rbx,list2
	push rbx
	call init_list
	add rsp,16

	mov edi,[N]
	imul rdi,4
	call [malloc]
	mov [array],rax

	mov rdi,[list2]
	mov rsi,[list1]
	call assign_list

	mov rdi,[array]
	mov rsi,[list1]
	call assign_array

	mov rdi,fmtu
	mov rbx,list1
	push rbx
	call print_list
	add rsp,8
radix_avx2 equ 1
if defined radix_avx2
	call init_time
	mov rdi,[array]
	mov esi,[N]
	call [radix_sort_avx2]
	mov rdi,fmtar
	call time_me
end if

if 1
	call init_time
	mov rbx,[list1]
	push rbx
	call radix_sort
	pop rbx
	mov [list1],rbx
	mov rdi,fmtr
	call time_me
end if

if 1
	call init_time
	mov rbx,[list2]
	push rbx
	call sort
	pop rbx
	mov [list2],rbx
	mov rdi,fmtm
	call time_me
end if
	mov rdi,[list1]
	mov rsi,[list2]
	call equal_list
	mov rdi,fmte
	test eax,eax
	mov rbx,fmtne
	cmovz rdi,rbx
	call [puts]

	mov rdi,[array]
	mov rsi,[list2]
	call equal_array
	mov rdi,fmte
	test eax,eax
	mov rbx,fmtne
	cmovz rdi,rbx
	call [puts]

	mov rdi,fmts
	mov rbx,list1
	push rbx
	call print_list
	add rsp,8
	mov rdi,[list1]
	call length
	mov rdx,rcx
	mov rdi,fmt3
	mov rsi,n.size
	xor eax,eax
	call [printf]
	xor edi,edi
.exit:
	call [exit]
init_list:
	mov ebx,[N]
	mov r12,[rsp+8]
.L0:
	mov edi,n.size
	call [malloc]
	mov rcx,[r12]
	mov [rax+n.next],rcx
	mov [r12],rax
	mov rdi,seed
if 1
	call [rand_r]
else
	rdrand eax
end if
	xor edx,edx
	mov ecx,[N]
	div ecx
	mov rcx,[r12]
	mov [rcx+n.data],edx
	dec ebx
	jnz .L0
	ret
print_list:
	call [puts]
	mov rbx,[rsp+8]
	mov rbx,[rbx]
	mov r12,16
.L0:
	test rbx,rbx
	jz .exit
	mov rdi,fmt2
	mov rsi,[rbx+n.next]
	mov edx,[rbx+n.data]
	xor eax,eax
	call [printf]
	mov rbx,[rbx+n.next]
	dec r12
	jz .exit
	jmp .L0
.exit:
	ret
; rsi source, rdi dest
assign_list:
.L0:
	test rsi,rsi
	jz .exit
	test rdi,rdi
	jz .exit
	mov eax,[rsi+n.data]
	mov [rdi+n.data],eax
	mov rsi,[rsi+n.next]
	mov rdi,[rdi+n.next]
	jmp .L0
.exit:
	ret
assign_array:
.L0:
	test rsi,rsi
	jz .exit
	mov eax,[rsi+n.data]
	mov [rdi],eax
	mov rsi,[rsi+n.next]
	add rdi,4
	jmp .L0
.exit:
	ret
equal_list:
	mov eax,1
.L0:
	test rsi,rsi
	jz .exit
	test rdi,rdi
	jz .exit
	mov eax,[rsi+n.data]
	cmp [rdi+n.data],eax
	jnz .false
	mov rsi,[rsi+n.next]
	mov rdi,[rdi+n.next]
	jmp .L0
.exit:
	ret
.false:
	xor eax,eax
	ret
equal_array:
	mov eax,1
.L0:
	test rsi,rsi
	jz .exit
	mov eax,[rsi+n.data]
	cmp [rdi],eax
	jnz .false
	mov rsi,[rsi+n.next]
	add rdi,4
	jmp .L0
.exit:
	ret
.false:
	xor eax,eax
	ret
; [rsp+8] list to sort
sort:
	mov rdi,[rsp+8]
	call length
	cmp rcx,1
	jle .exit
	shr rcx,1 ; middle
	sub rsp,16 ; left,right
	mov qword[rsp],0
	mov qword[rsp+8],0
	mov rbx,[rsp+8+16]
.L0: ; append to left
	mov rax,[rsp]
	mov rdx,[rbx+n.next]
	mov [rbx+n.next],rax
	mov [rsp],rbx
	mov rbx,rdx
	dec rcx
	jnz .L0
.L1: ; append to right
	mov rax,[rsp+8]
	mov rdx,[rbx+n.next]
	mov [rbx+n.next],rax
	mov [rsp+8],rbx
	mov rbx,[rbx+n.next]
	mov rbx,rdx
	test rbx,rbx
	jnz .L1
	sub rsp,8 ; result
	mov rbx,[rsp+8]
	mov [rsp],rbx
	call sort
	mov rbx,[rsp]
	mov [rsp+8],rbx

	mov rbx,[rsp+16]
	mov [rsp],rbx
	call sort
	mov rbx,[rsp]
	mov [rsp+16],rbx
	call merge
	mov rbx,[rsp]
	add rsp,24
	mov [rsp+8],rbx
.exit:
	ret
; [rsp+8] output , [rsp+16] left, [rsp+24] right
merge:
	sub rsp,8 ; append position
	mov qword[rsp+16],0
	mov qword[rsp],0
.L0:
	cmp qword[rsp+24],0
	jz .right
	cmp qword[rsp+32],0
	jz .left
	mov rax,[rsp+24]
	mov ebx,[rax+n.data]
	mov rcx,[rsp+32]
	cmp ebx,[rcx+n.data]
	jl .add_left
.add_right:
	cmp qword[rsp],0
	je .just_set_right
	mov rdx,[rsp]
	mov [rdx+n.next],rcx
	mov rdx,[rcx+n.next]
	mov [rsp+32],rdx
	mov qword[rcx+n.next],0
	mov [rsp],rcx
	jmp .L0
.add_left:
	cmp qword[rsp],0
	je .just_set_left
	mov rdx,[rsp]
	mov [rdx+n.next],rax
	mov rdx,[rax+n.next]
	mov [rsp+24],rdx
	mov qword[rax+n.next],0
	mov [rsp],rax
	jmp .L0
.just_set_left:
	mov rdx,[rax+n.next]
	mov qword[rax+n.next],0
	mov [rsp],rax
	mov [rsp+16],rax
	mov [rsp+24],rdx
	jmp .L0
.just_set_right:
	mov rdx,[rcx+n.next]
	mov qword[rcx+n.next],0
	mov [rsp],rcx
	mov [rsp+16],rcx
	mov [rsp+32],rdx
	jmp .L0
.right:
	cmp qword[rsp+32],0
	jz .exit
	mov rcx,[rsp+32]
	cmp qword[rsp],0
	je .just_set_right_only
	mov rdx,[rsp]
	mov [rdx+n.next],rcx
	mov [rsp],rcx
	mov rdx,[rcx+n.next]
	mov qword[rcx+n.next],0
	mov [rsp+32],rdx
	jmp .right
.just_set_right_only:
	mov rdx,[rcx+n.next]
	mov qword[rcx+n.next],0
	mov [rsp],rcx
	mov [rsp+16],rcx
	mov [rsp+32],rdx
	jmp .right
.left:
	cmp qword[rsp+24],0
	jz .exit
	mov rax,[rsp+24]
	cmp qword[rsp],0
	je .just_set_left_only
	mov rdx,[rsp]
	mov [rdx+n.next],rax
	mov [rsp],rax
	mov rdx,[rax+n.next]
	mov qword[rax+n.next],0
	mov [rsp+24],rdx
	jmp .left
.just_set_left_only:
	mov rdx,[rax+n.next]
	mov qword[rax+n.next],0
	mov [rsp],rax
	mov [rsp+24],rax
	mov [rsp+32],rdx
	jmp .left
.exit:
	add rsp,8
	ret
; rdi input list, rcx count
length:
	mov rcx,0
.L0:
	test rdi,rdi
	jz .exit
	mov rdi,[rdi+n.next]
	inc rcx
	jmp .L0
.exit:
	ret
; [rsp+8] list to sort
radix_sort:
	sub rsp,32*8
	xor ebx,ebx
.L0:
	mov rdi,rsp
	mov rcx,32
	xor eax,eax
	rep stosq
	mov rdi,[rsp +32*8+8]
.L1:
	test rdi,rdi
	jz .next
	mov ecx,ebx
	shl ecx,2
	mov esi,[rdi+n.data]
	shr esi,cl
	and esi,0fh
	cmp qword[rsp+rsi*8],0
	je .just_set
	mov rdx,[rdi+n.next]
	mov rax,[rsp+rsi*8+16*8]
	mov [rax+n.next],rdi
	mov [rsp+rsi*8+16*8],rdi
	mov qword[rdi+n.next],0
	mov rdi,rdx
	jmp .L1
.just_set:
	mov rdx,[rdi+n.next]
	mov [rsp+rsi*8],rdi
	mov [rsp+rsi*8+16*8],rdi
	mov qword[rdi+n.next],0
	mov rdi,rdx
	jmp .L1
.next:
	mov qword[rsp+32*8+8],0
	xor edi,edi
	xor ecx,ecx
.L2:
	mov rsi,[rsp+rcx*8]
.L3:
	test rsi,rsi
	jz .next1
	test rdi,rdi
	jz .just_set1
	mov [rdi+n.next],rsi
	mov rdi,rsi
	mov rdx,[rsi+n.next]
	mov qword[rsi+n.next],0
	mov rsi,rdx
	jmp .L3
.just_set1:
	mov rdi,rsi
	mov [rsp+32*8+8],rsi
	mov rdx,[rsi+n.next]
	mov qword[rsi+n.next],0
	mov rsi,rdx
	jmp .L3
.next1:
	inc ecx
	cmp ecx,16
	jl .L2
	inc rbx
	cmp rbx,8
	jl .L0
.exit:
	add rsp,32*8
	ret
init_time:
	rdtscp
	shl rdx,32
	or rax,rdx
	mov [elapsed],rax
	ret
time_me:
	rdtscp
	shl rdx,32
	or rax,rdx
	sub rax,[elapsed]
	cvtsi2sd xmm0,rax
	divsd xmm0,[clock]
	mov rax,1
	jmp [printf]

segment readable
clock dq 3.8e9
fmtu db 'unsorted',0ah,0
fmts db 'sorted' ,0ah,0
fmte db 'equal',0ah,0
fmtne db 'not equal',0ah,0
fmtm db 'list merge elapsed %f seconds',0ah,0
fmtr db 'list radix elapsed %f seconds',0ah,0
fmtar db 'array radix elapsed %f seconds',0ah,0
fmt1 db 'seed: %d',0ah,0
fmt2 db '%16p %d',0ah,0
fmt3 db 'size of node %d, length %d',0ah,0
fmt4 db "N: %d",0xa,0
segment writeable
list1 dq 0
list2 dq 0
array rq 1
elapsed rq 1
N rd 1; number of nodes
seed rd 1

;seed rd 1
