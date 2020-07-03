	.text;				@ Store in ROM
;@============================================================================
;@============================================================================
Reset_Handler:
	.global Reset_Handler;	@ The entry point on reset
	; @ The main program
main:
	ldr sp, =#0x40004000; @ Initialize SP just past the end of RAM
	mov r4, #3;
	
	mov r7, #TestCount; ;@mov r0, #7; @ Load value of N into first argument
	ldr r8, =test_n;
outermost_loop_testing:
	ldr r0, [r8], #4;
	bl sub_fib; @ Find Nth value of the Fibonacci sequence
	subs r7, r7,#1;
	bne outermost_loop_testing;
	
	 ;@ at this point, r4 is be 3
stop:
	b stop; 
sub_fib:
	push { r0, r4, r7, r8, lr}
	mov r7, #0;
	mov r8, #0;
	;	@ Select which term we are calculating
	mov r4, r0;
	mov r0, #0;
;	@ Pointers to the variables
	ldr r2, =var_a;
	ldr r3, =var_b;
	
	mov r12, #1;	@ Constant used for initializing LSW of variables
	str r12, [r2, #0];
	str r12, [r3, #0];
	
	mov r9, #12;@ counter for initializing loop 
	mov r8, #4;
my_initializing_loop:
	mov r12, #0;	@ Constant used for initializing the variables
	str r12, [r2, r8];	@ Set the value of var_a
	str r12, [r3, r8];	@ Set the value of var_b
	add r8, r8,#4;
	subs r9, r9,#4;
	bne my_initializing_loop;

loop:
	bl add_128;			@ Perform a 128-bit add
	BCS overflow;		@ //////////////////////Detect if our variable overflowed by looking
;						@ at the carry flag after the top word add
;						@ If so, branch to "overflow"
	subs r4, #1;		@ //////////////////////Decrement the loop counter
	bne loop;		@ Have we reached the desired term yet?
	pop { r0, r4, r7, r8, lr}
	mov pc, lr;
done:
	b done;				@ Program done! Loop forever.
	
overflow:
	b overflow;			@ Oops, the add overflowed the variable!

; @ Subroutine to load two words from the variables into memory
add_128:	
	mov r5, lr;
;	@ Start with the least significant word (word 0)
;	@ We add the two words without carry for the LSW.
;	@ We add all other words using a carry.
;	@ We set the status register for subsequent operations
	mov r1, #0;
	bl load_var;
;	@ 32-bit add
	adds r0, r0, r1;	@ Add word 2 with carry, set status register
	mov r1, #0;
	bl store_var;
	
	mov r1, #4;
	bl load_var;
;	@ 32-bit add
	adcs r0, r0, r1;	@ Add word 2 with carry, set status register
	mov r1, #4;
	bl store_var;
	
	mov r1, #8;
	bl load_var;	
;	@ 32-bit add
	adcs r0, r0, r1;	@ Add word 2 with carry, set status register
	mov r1, #8;
	bl store_var;
	
	mov r1, #12;
	bl load_var;
;	@ 32-bit add
	adcs r0, r0, r1;	@ Add word 0, set status register
	mov r1, #12;	
	bl store_var;
;@@@@/////
; @ What issue do we have returning from the subroutine? How can we fix it?
	mov pc, r5;		@ ////////////////////Return from subroutine

; @ Subroutine to load two words from the variables into memory
load_var:
; @ Update this subroutine to take an argument so it can
; @ be reused for loading all four words
	ldr r0, [r2, r1];	@ Load the value of var_a
	ldr r1, [r3, r1];	@ Load the value of var_b
	mov pc, lr;			@ /////Return from subroutine

; @ Subroutine to shift move var_b into var_a and store
; @ the result of the add.
store_var:
; @ Update this subroutine to take an argument so it can
; @ be reused for storing all four words
	ldr	r12,[r3, r1];   @ Move var_b ...
	str	r12,[r2, r1];	@    ... into var_a
	str r0, [r3, r1];	@ Store the result into var_b
	mov pc, lr;			@ ///////////////Return from subroutine

;@ Test parameters format 2
    .equ    TestCount,    1
;@    test number            1            2            3          4          5       6            7 
test_n:   .word             5,          1,         90,          2,        175,        184,        185;    @ input n
ans_n:    .word             7,          3,         92,          4,        177,        186,        187;    @ output n
ans_of:   .word             0,          0,          0,          0,          0,          0,          1;    @ overflow
ans_msw:  .word    0x00000000, 0x00000000, 0x00000000, 0x00000000, 0x034B45B2, 0xFA63C8D9, 0x9523A14F;    @ fib msw
ans_lsw:  .word    0x0000000D, 0x00000002, 0x61ECCFBD, 0x00000003, 0x8AE80862, 0x333270F8, 0x1AAB3E85;    @ fib lsw

.data;					@ Store in RAM	
var_n:  .space 4;@ 1 word/32 bits – what Fib number ended up in var_b
var_a:	.space 16;		@ ///////////////////Variable A (128-bit)
var_b:	.space 16;		@ /////////////////Variable B (128-bit)

	.end;				@ End of program
	
