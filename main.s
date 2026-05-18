/*********************************************************************************************
*	main.s
*	Organización y arquitectura de computadoras - UCC
*   2025
**********************************************************************************************/
.text
.org 0x0000

.equ PERIPHERAL_BASE, 0x3F000000 // Peripheral Base Address
.equ GPIO_BASE, 0x200000 	// GPIO Base Address
.equ GPIO_GPFSEL1, 0x4 		// GPIO Function Select 1
.equ GPIO_GPSET0, 0x1C 		// GPIO Pin Output Set 0
.equ GPIO_GPCLR0, 0x28 		// GPIO Pin Output Clear 0


	// Set Cores 1..3 To Infinite Loop (no modificar)
	mrs X0, MPIDR_EL1 	// X0 = Multiprocessor Affinity Register (MPIDR)
	ands X0,X0,3 		// X0 = CPU ID (Bits 0..1)
	b.ne CoreLoop 		// IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

	// Load in W0 the GPIO base address
	ldr W0,=(PERIPHERAL_BASE + GPIO_BASE)

	// Config GPIO18 as output (usar GPIO_GPFSEL1)
	ldr W1, [X0, GPIO_GPFSEL1] 
	and W1, W1, ~(0x7 << 24) // Limpia los 3 bits de GPIO18 (26:24)
	orr W1, W1, (0x1 << 24) // Pone 001
	str W1, [X0, GPIO_GPFSEL1]

	// Mascara de GPIO18
	mov W5, (1 << 18)

	//------------------ CODE HERE ------------------------------------------------------
	// Ciclos de CPU disponibles por semiperíodo = 1_200_000_000 / (2 * F)
	// Cada iteración del loop de delay consume 2 ciclos (SUBS + B.NE)
	// => iteraciones_delay = 600_000_000 / F
	//
	// Repeticiones por nota (3 segundos) = 3 * F * 2   (dos semiperíodos por período)
	// => reps = 6 * F  (redondeado al entero más cercano)
	//
	// Nota   F[Hz]    delay_iters   reps_3s
	// DO     261.63   2295000       1570
	// RE     293.66   2045000       1762
	// MI     329.63   1821000       1978
	// FA     349.23   1719000       2096
	// SOL    392.00   1530600       2352
	// LA     440.00   1363600       2640
	// SI     493.88   1215000       2964

infloop:
	// DO 261.63 Hz
	ldr W2, =2295000
	ldr W3, =1570
	bl play_note

	// RE  293.66 Hz
	ldr W2, =2045000
	ldr W3, =1762
	bl play_note
	
	// MI  329.63 Hz
	ldr W2, =1821000
	ldr W3, =1978
	bl play_note
	
	// FA  349.23 Hz
	ldr W2, =1719000
	ldr W3, =2096
	bl play_note
	
	// SOL 392.00 Hz
	ldr W2, =1530600
	ldr W3, =2352
	bl play_note
	
	// LA  440.00 Hz
	ldr W2, =1363600
	ldr W3, =2640
	bl play_note
	
	// SI  493.88 Hz
	ldr W2, =1215000
	ldr W3, =2964
	bl play_note

  b infloop

play_note:
	// GPIO_GPSET0, GPIO_GPCLR0

note_period:
	// semiperiodo alto GPIO18 = 1
	str W5, [X0, GPIO_GPSET0] // GPIO18 = 1
	
	mov W4, W2
delay_high:
	subs W4, W4, 1
	b.ne delay_high

	// semiperiodo bajo GPIO18 = 0
	str W5, [X0, GPIO_GPCLR0] // GPIO18 = 0

	mov W4, W2
delay_low:
	subs W4, W4, 1
	b.ne delay_low

	// restar un periodo y repetir
	subs W3, W3, 1
	b.ne note_period

	ret // vuelve al origen de la llamada

	//----------------------------------------------------------------------------------

CoreLoop:       // Infinite Loop For Core 1..3
  b CoreLoop

