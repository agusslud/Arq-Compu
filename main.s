/*********************************************************************************************
*	Materia: Organizacion y Arquitectura de Computadoras - UCC
*	Alumnos: Garelli Valentin -Ludueña Agustin
* Carrera: Ingenieria Electrónica
**********************************************************************************************/
.text
.org 0x0000

.equ PERIPHERAL_BASE, 0x3F000000 // Peripheral Base Address
.equ GPIO_BASE, 0x200000 	// GPIO Base Address
.equ GPIO_GPFSEL1, 0x4 		// GPIO Function Select 1
.equ GPIO_GPSET0, 0x1C 		// GPIO Pin Output Set 0
.equ GPIO_GPCLR0, 0x28 		// GPIO Pin Output Clear 0
.equ GPIO_PREN0, 0x4C 		// DIRECCION HABILITAR DETECCION FLANCO SUBIDA
.equ GPDES0, 0x40			//DIRECCION QUE GUARDA LA DETECCION DEL FLANCO

	// Set Cores 1..3 To Infinite Loop (no modificar)
	mrs X0, MPIDR_EL1 	// X0 = Multiprocessor Affinity Register (MPIDR)
	ands X0,X0,3 		// X0 = CPU ID (Bits 0..1)
	b.ne CoreLoop 		// IF (CPU ID != 0) Branch To Infinite Loop (Core ID 1..3)

	// Load in W0 the GPIO base address
	ldr W0,=(PERIPHERAL_BASE + GPIO_BASE)

	// GPIO18 = SALIDA (audio 1-bit), GPIO15 = ENTRADA (boton)
	// Se accede al registro GPFSEL1 (0x3F200004): cada 3 bits controlan un GPIO
	// GPIO15 -> bits [17:15], GPIO18 -> bits [26:24]. Valor 001 = salida, 000 = entrada
	mov X9,GPIO_BASE
	movz X10,#0x3F00,lsl #16
	mov X11,GPIO_GPFSEL1
	add X9,X9,X10               // X9 = 0x3F200000 (base GPIO)
	add X10,X9,X11              // X10 = 0x3F200004 (dir. GPFSEL1)
	ldr W11,[X10,#0]            // W11 = valor actual de GPFSEL1
	movz W9, #0xF8FC,LSL #16   // mascara alta: limpia bits [26:24] (GPIO18)
	movk W9, #0x7FFF,LSL #0    // mascara baja: limpia bits [17:15] (GPIO15)
	and W11,W11,W9              // aplica mascara: ambos pines quedan en modo entrada (000)
	movz W9,#0x0100,LSL #16    // W9 = bit 24 en 1 -> GPIO18 = 001 = SALIDA
	orr W11,W11,W9             // combina: GPIO18=SALIDA, GPIO15=ENTRADA (sin cambiar)
	str W11,[X10,#0]           // escribe configuracion en GPFSEL1

	// Habilitar deteccion de flanco de subida en GPIO15 via GPREN0 (0x3F20004C)
	// Cuando GPIO15 pasa de LOW a HIGH, el hardware setea el bit 15 en GPEDS0
	mov X9,GPIO_BASE
	movz X10,#0x3F00,lsl #16
	mov X11,GPIO_PREN0
	add X9,X9,X10               // X9 = 0x3F200000 (base GPIO)
	add X10,X9,X11              // X10 = 0x3F20004C (dir. GPREN0)
	ldr W11,[X10,#0]            // W11 = valor actual de GPREN0
	movz W9, #0x8000,LSL #0    // W9 = 0x8000 -> bit 15 corresponde a GPIO15
	orr W11,W11,W9             // habilita deteccion de flanco de subida en GPIO15
	str W11,[X10,#0]           // escribe configuracion en GPREN0

/*=============================================================================================
*	INICIALIZACION DE REGISTROS GLOBALES
*   Registros fijos durante toda la ejecucion. Se usan en PlayNote, PlayNote2 y PlaySilence.
================================================================================================*/
	mov X11,GPIO_BASE           // X11 = 0x200000  (offset base GPIO)
	movz X12,#0x3F00,lsl #16   // X12 = 0x3F000000 (base perifericos)
	mov X13,GPIO_GPSET0         // X13 = 0x1C (offset GPSET0: pone pin en ALTO)
	mov X14,GPIO_GPCLR0         // X14 = 0x28 (offset GPCLR0: pone pin en BAJO)
	movz X16, #0x0004,LSL #16  // X16 = 0x00040000 (mascara bit 18 = GPIO18)
	mov X17,GPDES0              // X17 = 0x40 (offset GPEDS0: registro de eventos)
	add X18,X11,X12             // X18 = 0x3F200000 (direccion absoluta base GPIO)
	add X17,X18,X17             // X17 = 0x3F200040 (direccion absoluta GPEDS0)

	// Espera de estabilizacion al encender: da tiempo a GPIO15 para asentarse
	// sin esto, transitorios de alimentacion pueden generar flancos falsos en GPEDS0
	movz W9, #0x8000, LSL #0       // W9 = mascara bit 15 (GPIO15)
	str W9, [X17, #0]              // limpiar GPEDS0 (descartar eventos del arranque)
	movz X10, #0x0200, LSL #16    // ~56ms de espera (33M iteraciones a 1.2GHz)
StartupDelay:
	subs X10, X10, #1
	b.ne StartupDelay
	str W9, [X17, #0]              // limpiar GPEDS0 nuevamente (descartar rebotes del delay)


infloop:

reproducir_notas:
 // Reproduccion de DO-RE-MI-FA-SOL-LA-SI-DO (C4-D4-E4-F4-G4-A4-B4-C5)

 	movz W9, #32768,LSL #0
	str W9, [X17, #0] // Limpiar detección de flanco (escribir 1 para limpiar)

	//PRIMER COMPAS


	// 82. MI4 (D4)
	movz X0, #7286
	mov X1, #450
	bl PlayNote2


	// 79. FA4 (E4)
	movz X0, #6513
	mov X1, #300
	bl PlayNote2


	// 66. SOL4 (F4)
	movz X0, #6085
	mov X1, #400
	bl PlayNote2



	// 77. LA4 (G4)
	movz X0, #5423
	mov X1, #500
	bl PlayNote2



	// 73. SI4 (A4) - Nota larga
	movz X0, #4773
	mov X1, #600
	bl PlayNote2


	// 75. DO4 (B4)
	movz X0, #9118
	mov X1, #400
	bl PlayNote2


	// 70. RE 4
	movz X0, #8192
	mov X1, #250
	bl PlayNote2
	
	
	b reproducir_notas
 // FIN DE REPRODUCCION NOTAS


	// Pausa de silencio antes de volver a empezar el bucle
	movz X10, #21, LSL #16
reproducir_elisa:
	// LUDWIG VAN BEETHOVEN: "Para Elisa" (Für Elise) - Versión Completa del Tema Principal

	movz W9, #32768,LSL #0
	str W9, [X17, #0] // Limpiar detección de flanco (escribir 1 para limpiar)
	
	// ============================================================================================
	// --- FRAGMENTO 1 ---
	// ============================================================================================
	
	// 1. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote
	
	// 2. RE#5 (D#5)
	movz X0, #3702
	mov X1, #279
	bl PlayNote
	
	// 3. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 4. RE#5 (D#5)
	movz X0, #3702
	mov X1, #279
	bl PlayNote

	// 5. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 6. SI4 (B4)
	movz X0, #4665
	mov X1, #222
	bl PlayNote

	// 7. RE5 (D5)
	movz X0, #3922
	mov X1, #264
	bl PlayNote

	// 8. DO5 (C5)
	movz X0, #4403
	mov X1, #234
	bl PlayNote

	// 9. LA4 (A4) - Nota larga
	movz X0, #5236
	mov X1, #300
	bl PlayNote

	// 10. Silencio breve
	movz X0, #5236
	mov X1, #150
	bl PlaySilence

	// 11. DO4 (C4)
	movz X0, #8806
	mov X1, #120
	bl PlayNote

	// 12. MI4 (E4)
	movz X0, #6989
	mov X1, #150
	bl PlayNote

	// 13. LA4 (A4)
	movz X0, #5236
	mov X1, #198
	bl PlayNote

	// 14. SI4 (B4) - Nota larga
	movz X0, #4665
	mov X1, #666
	bl PlayNote

	// 15. Silencio breve
	movz X0, #4665
	mov X1, #150
	bl PlaySilence

	// 16. MI4 (E4)
	movz X0, #6989
	mov X1, #150
	bl PlayNote

	// 17. SOL#4 (G#4)
	movz X0, #5547
	mov X1, #186
	bl PlayNote

	// 18. SI4 (B4)
	movz X0, #4665
	mov X1, #222
	bl PlayNote

	// 19. DO5 (C5) - Nota larga
	movz X0, #4403
	mov X1, #708
	bl PlayNote


	// ============================================================================================
	// --- FRAGMENTO 2 ---
	// ============================================================================================

	// 20. Silencio breve
	movz X0, #4403
	mov X1, #150
	bl PlaySilence

	// 21. MI4 (E4)
	movz X0, #6989
	mov X1, #149
	bl PlayNote

	// 22. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 23. RE#5 (D#5)
	movz X0, #3702
	mov X1, #276
	bl PlayNote

	// 24. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 25. RE#5 (D#5)
	movz X0, #3702
	mov X1, #279
	bl PlayNote

	// 26. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 27. SI4 (B4)
	movz X0, #4665
	mov X1, #222
	bl PlayNote

	// 28. RE5 (D5)
	movz X0, #3922
	mov X1, #264
	bl PlayNote

	// 29. DO5 (C5)
	movz X0, #4403
	mov X1, #234
	bl PlayNote

	// 30. LA4 (A4) - Nota larga
	movz X0, #5236
	mov X1, #600
	bl PlayNote

	// 31. Silencio breve
	movz X0, #5236
	mov X1, #150
	bl PlaySilence

	// 32. DO4 (C4)
	movz X0, #8806
	mov X1, #120
	bl PlayNote

	// 33. MI4 (E4)
	movz X0, #6989
	mov X1, #150
	bl PlayNote

	// 34. LA4 (A4)
	movz X0, #5236
	mov X1, #198
	bl PlayNote

	// 35. SI4 (B4) - Nota larga
	movz X0, #4665
	mov X1, #666
	bl PlayNote


	// ============================================================================================
	// --- FRAGMENTO 3 ---
	// ============================================================================================

	// 36. SI4 (B4) - Nota inicial de la transición
	movz X0, #4665
	mov X1, #228
	bl PlayNote

	// 37. DO5 (C5)
	movz X0, #4403
	mov X1, #234
	bl PlayNote

	// 38. RE5 (D5)
	movz X0, #3922
	mov X1, #264
	bl PlayNote

	// 39. MI5 (E5) - Nota sostenida
	movz X0, #3495
	mov X1, #600
	bl PlayNote

	// 40. SOL4 (G4)
	movz X0, #5877
	mov X1, #300
	bl PlayNote

	// 41. FA5 (F5)
	movz X0, #3298
	mov X1, #300
	bl PlayNote

	// 42. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 43. RE5 (D5) - Nota sostenida
	movz X0, #3922
	mov X1, #600
	bl PlayNote

	// 44. FA4 (F4)
	movz X0, #6597
	mov X1, #300
	bl PlayNote

	// 45. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 46. RE5 (D5)
	movz X0, #3922
	mov X1, #300
	bl PlayNote

	// 47. DO5 (C5) - Nota sostenida
	movz X0, #4403
	mov X1, #600
	bl PlayNote

	// 48. MI4 (E4)
	movz X0, #6989
	mov X1, #300
	bl PlayNote

	// 49. RE5 (D5)
	movz X0, #3922
	mov X1, #300
	bl PlayNote

	// 50. DO5 (C5)
	movz X0, #4403
	mov X1, #300
	bl PlayNote

	// 51. SI4 (B4) - Nota sostenida
	movz X0, #4665
	mov X1, #600
	bl PlayNote


	// ============================================================================================
	// --- FRAGMENTO 4 ---
	// ============================================================================================

	// 52. MI4 (E4)
	movz X0, #6989
	mov X1, #300
	bl PlayNote

	// 53. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 54. MI4 (E4)
	movz X0, #6989
	mov X1, #300
	bl PlayNote

	// 55. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 56. MI6 (E6) - Nota extra aguda
	movz X0, #1747
	mov X1, #450
	bl PlayNote

	// 57. RE#5 (D#5)
	movz X0, #3702
	mov X1, #300
	bl PlayNote

	// 58. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 59. RE#5 (D#5)
	movz X0, #3702
	mov X1, #300
	bl PlayNote

	// 60. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 61. RE#5 (D#5)
	movz X0, #3702
	mov X1, #300
	bl PlayNote

	// 62. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 63. RE#5 (D#5)
	movz X0, #3702
	mov X1, #300
	bl PlayNote

	// 64. MI5 (E5)
	movz X0, #3495
	mov X1, #300
	bl PlayNote

	// 65. SI4 (B4)
	movz X0, #4665
	mov X1, #300
	bl PlayNote

	// 66. RE5 (D5)
	movz X0, #3922
	mov X1, #300
	bl PlayNote

	// 67. DO5 (C5)
	movz X0, #4403
	mov X1, #300
	bl PlayNote

	// 68. LA4 (A4) - Resolución final
	movz X0, #5236
	mov X1, #900
	bl PlayNote

	// 69. Silencio prolongado de fin de ciclo antes de repetir
	movz X0, #5236
	mov X1, #659
	bl PlaySilence

	b reproducir_elisa


PauseMelody:
	subs X10, X10, #1
	b.ne PauseMelody

	b infloop // Reinicia la canción





/*=============================================================================================
*	SUBRUTINA: PlayNote Utilizada para la canción principal
================================================================================================*/
PlayNote:
	cbz X1, PlayNoteEnd   // Si por algún motivo los ciclos son 0, salimos

NoteLoop:
	// --- ESTADO ALTO (Pin en 1) ---
	add X9, X11, X12      // Direccion base GPIO
	add X9, X9, X13       // Dirección GPSET0
	str W16, [X9, #0]     // Mandar 1 lógico

	mov X10, X0           // Cargar retardo
DelayHigh:
	subs X10, X10, #1
	b.ne DelayHigh
	
	
	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToNotas   // Si se detecta un flanco, debounce y saltar a Notas

	// --- ESTADO BAJO (Pin en 0) ---
	add X9, X11, X12      // Direccion base GPIO
	add X9, X9, X14       // Dirección GPCLR0
	str W16, [X9, #0]     // Mandar 0 lógico

	mov X10, X0           // Cargar retardo
DelayLow:
	subs X10, X10, #1
	b.ne DelayLow

	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToNotas   // Si se detecta un flanco, debounce y saltar a Notas


	// Decrementar ciclos restantes y continuar si no llegamos a 0
	subs X1, X1, #1
	b.ne NoteLoop

PlayNoteEnd:
	// Breve silencio (gap) entre notas consecutivas para evitar que suenen pegadas
	movz X10, #24576
SilenceDelay:
	subs X10, X10, #1
	b.ne SilenceDelay
	br X30

//-------------------------------------------------------------------------------------


/*=============================================================================================
*	SUBRUTINA: PlayNote2 - Utilizada para reproducir Do-Re-Mi-Fa-Sol-LA-SI-DO (C4-D4-E4-F4-G4-A4-B4-C5)
================================================================================================*/



PlayNote2:
	cbz X1, PlayNoteEnd2   // Si por algún motivo los ciclos son 0, salimos

NoteLoop2:
	// --- ESTADO ALTO (Pin en 1) ---
	add X9, X11, X12      // Direccion base GPIO
	add X9, X9, X13       // Dirección GPSET0
	str W16, [X9, #0]     // Mandar 1 lógico

	mov X10, X0           // Cargar retardo
DelayHigh2:
	subs X10, X10, #1
	b.ne DelayHigh2

	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToCancion   // Si se detecta un flanco, debounce y saltar a cancion


	// --- ESTADO BAJO (Pin en 0) ---
	add X9, X11, X12      // Direccion base GPIO
	add X9, X9, X14       // Dirección GPCLR0
	str W16, [X9, #0]     // Mandar 0 lógico

	mov X10, X0           // Cargar retardo
DelayLow2:
	subs X10, X10, #1
	b.ne DelayLow2

	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToCancion   // Si se detecta un flanco, debounce y saltar a cancion

	// Decrementar ciclos restantes y continuar si no llegamos a 0
	subs X1, X1, #1
	b.ne NoteLoop2

PlayNoteEnd2:
	// Silencio entre notas (3x el de PlayNote para mayor separacion entre notas de la escala)
	movz X10, #1, LSL #16
	movk X10, #8192            // X10 = 73728 ciclos
SilenceDelay2:
	subs X10, X10, #1
	b.ne SilenceDelay2
	br X30

//-------------------------------------------------------------------------------------





/*=============================================================================================
*	SUBRUTINA: PlaySilence
================================================================================================*/
PlaySilence:
	cbz X1, PlaySilenceEnd   // Si los ciclos son 0, salimos inmediatamente

SilenceLoop:
	// --- MANTENER EN BAJO (Pin en 0) ---
	add X9, X11, X12      // Dirección del GPIO base
	add X9, X9, X14       // Dirección GPCLR0
	str W16, [X9, #0]     // Mandamos un 0 lógico al pin 18

	// Primer retraso de semiperiodo
	mov X10, X0           
DelaySilence1:
	subs X10, X10, #1
	b.ne DelaySilence1

	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToNotas   // Si se detecta un flanco, debounce y saltar a Notas


	// Segundo retraso de semiperiodo
	mov X10, X0           
DelaySilence2:
	subs X10, X10, #1
	b.ne DelaySilence2

	//Realiza el chequeo de GPIO15
	ldr W9, [X17, #0]     // Leer detección de flanco
	and W9, W9, #0x8000 // Aislar bit de GPIO15
	cbnz W9, DebounceToNotas   // Si se detecta un flanco, debounce y saltar a Notas


	// Decrementar los ciclos restantes
	subs X1, X1, #1
	b.ne SilenceLoop

PlaySilenceEnd:
	br X30


/*=============================================================================================
*	SUBRUTINAS DE DEBOUNCE
===================================================*/
DebounceToNotas:
	str W9, [X17, #0]               // Limpiar GPEDS0 
	movz X10, #128, LSL #16      // 8388608 iteraciones ≈ 14ms a 1.2GHz
DebounceToNotasLoop:
	subs X10, X10, #1
	b.ne DebounceToNotasLoop
	str W9, [X17, #0]               // Limpiar GPEDS0 otra vez (descartar rebotes del delay)
	b reproducir_notas

DebounceToCancion:
	str W9, [X17, #0]               // Limpiar GPEDS0
	movz X10, #128, LSL #16      
DebounceToCancionLoop:
	subs X10, X10, #1
	b.ne DebounceToCancionLoop
	str W9, [X17, #0]               // Limpiar GPEDS0 otra vez
	b reproducir_elisa

CoreLoop:       // Infinite Loop For Core 1..3
  b CoreLoop




