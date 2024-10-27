.386
.model flat, stdcall
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;includem biblioteci, si declaram ce functii vrem sa importam
includelib msvcrt.lib
extern exit: proc
extern malloc: proc
extern memset: proc
extern rand: proc

includelib canvas.lib
extern BeginDrawing: proc
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;declaram simbolul start ca public - de acolo incepe executia
public start
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;sectiunile programului, date, respectiv cod
.data
;aici declaram date
window_title DB "Exemplu proiect desenare",0
area_width EQU 500
area_height EQU 500
area DD 0

counter DD 0 ; numara evenimentele de tip timer

arg1 EQU 8
arg2 EQU 12
arg3 EQU 16
arg4 EQU 20

matrix DD 0,0,0
	   DD 0,0,0
	   DD 0,0,0
	   
your_turn DB 0

click_x DD 0
click_y DD 0

random DD 4

position DD 0
position_final DD 0

hundred DD 100
three DD 3

symbol_width EQU 10
symbol_height EQU 20
include digits.inc
include letters.inc

.code
; procedura make_text afiseaza o litera sau o cifra la coordonatele date
; arg1 - simbolul de afisat (litera sau cifra)
; arg2 - pointer la vectorul de pixeli
; arg3 - pos_x
; arg4 - pos_y

horizontal_line macro x, y, len, color 
local line_loop
    mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
line_loop:
    mov dword ptr[eax], color 
	add eax, 4
	loop line_loop
endm

vertical_line macro x, y, len, color 
local line_loop
    mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
line_loop:
    mov dword ptr[eax], color 
	add eax, area_width * 4
	loop line_loop
endm

cross_right_line macro x, y, len, color 
local line_loop
    mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
line_loop:
    mov dword ptr[eax], color 
	add eax, area_width * 4 + 4
	loop line_loop
endm

cross_left_line macro x, y, len, color 
local line_loop
    mov eax, y
	mov ebx, area_width
	mul ebx
	add eax, x
	shl eax, 2
	add eax, area
	mov ecx, len
line_loop:
    mov dword ptr[eax], color 
	add eax, area_width * 4 - 4
	loop line_loop
endm

make_x macro x, y 
	mov esi,x
	mov edi,y
	cross_right_line esi, edi, 100, 0FF0000h
	add esi,100
	cross_left_line esi, edi, 100, 0FF0000h
endm

make_O macro x, y 
	
	mov esi, x
	add esi, 10
	mov edi, y
	add edi, 10
	horizontal_line esi, edi,80,0FFh
	
	mov esi, x
	add esi, 10
	mov edi, y
	add edi, 90
	horizontal_line esi, edi,80,0FFh
	
	mov esi, x
	add esi, 10
	mov edi, y
	add edi, 10
	vertical_line esi, edi,80,0FFh
	
	mov esi, x
	add esi, 90
	mov edi, y
	add edi, 10
	vertical_line esi, edi,80,0FFh
endm

make_text proc
	push ebp
	mov ebp, esp
	pusha
	
	mov eax, [ebp+arg1] ; citim simbolul de afisat
	cmp eax, 'A'
	jl make_digit
	cmp eax, 'Z'
	jg make_digit
	sub eax, 'A'
	lea esi, letters
	jmp draw_text
make_digit:
	cmp eax, '0'
	jl make_space
	cmp eax, '9'
	jg make_space
	sub eax, '0'
	lea esi, digits
	jmp draw_text
make_space:	
	mov eax, 26 ; de la 0 pana la 25 sunt litere, 26 e space
	lea esi, letters
	
draw_text:
	mov ebx, symbol_width
	mul ebx
	mov ebx, symbol_height
	mul ebx
	add esi, eax
	mov ecx, symbol_height
bucla_simbol_linii:
	mov edi, [ebp+arg2] ; pointer la matricea de pixeli
	mov eax, [ebp+arg4] ; pointer la coord y
	add eax, symbol_height
	sub eax, ecx
	mov ebx, area_width
	mul ebx
	add eax, [ebp+arg3] ; pointer la coord x
	shl eax, 2 ; inmultim cu 4, avem un DWORD per pixel
	add edi, eax
	push ecx
	mov ecx, symbol_width
bucla_simbol_coloane:
	cmp byte ptr [esi], 0
	je simbol_pixel_alb
	mov dword ptr [edi], 0FF0000H
	jmp simbol_pixel_next
simbol_pixel_alb:
	mov dword ptr [edi], 0
simbol_pixel_next:
	inc esi
	add edi, 4
	loop bucla_simbol_coloane
	pop ecx
	loop bucla_simbol_linii
	popa
	mov esp, ebp
	pop ebp
	ret
make_text endp

; un macro ca sa apelam mai usor desenarea simbolului
make_text_macro macro symbol, drawArea, x, y
	push y
	push x
	push drawArea
	push symbol
	call make_text
	add esp, 16
endm

; functia de desenare - se apeleaza la fiecare click
; sau la fiecare interval de 200ms in care nu s-a dat click
; arg1 - evt (0 - initializare, 1 - click, 2 - s-a scurs intervalul fara click)
; arg2 - x
; arg3 - y
draw proc
	push ebp
	mov ebp, esp
	pusha
	
	
	
	mov eax, [ebp+arg1]
	cmp eax, 1
	jz evt_click
	cmp eax, 2
	jz evt_timer ; nu s-a efectuat click pe nimic
	;mai jos e codul care intializeaza fereastra cu pixeli albi

	jmp afisare_litere
	
evt_click:

reset:
	mov eax,[ebp+arg2]
	cmp eax,440
	jl play_with_computer
	cmp eax,480
	jg play_with_computer
	mov eax,[ebp+arg3]
	cmp eax,465
	jl play_with_computer
	cmp eax,485
	jg play_with_computer
	
;aici practic redesenezi toata fereastra cu negru peste tot ce era
;dar cum desenul careului e jos in "main" apuca sa deseneze careul
;si da impresia ca le stergi pe toate 
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	push 0 ; black
	push area
	call memset
	add esp, 12
; iar aici reinitializezi matricea cu 0 pentru a juca din nou
;e din 4 in 4 pentru ca matricea e de tip DWORD
init_with_0:
	mov matrix[0],0
	mov matrix[4],0
	mov matrix[8],0
	mov matrix[12],0
	mov matrix[16],0
	mov matrix[20],0
	mov matrix[24],0
	mov matrix[28],0
	mov matrix[32],0
	
	
play_with_computer:
	mov eax,[ebp+arg2]
	cmp eax,10
	jl player
	cmp eax,160
	jg player
	mov eax,[ebp+arg3]
	cmp eax,465
	jl player
	cmp eax,485
	jg player

; aici apelezi un numar aleator cu functia random 
;si il imparti cu 9 pentru ca restul inmultirii cu 9 e in intervalul (0-8)
; dar pentru ca imparti numarul random(32bit in eax) cu 9(ebx) atunci
;restul impartirii o sa fie salvat in EDX
;si in functie de edx te duci la un patrat liber definit mai jos
; like daca edx=0 te duci la primul,daca e edx=3 te duci la patratul 4 etc
random_place:
	pusha
	call rand
	mov random, eax
	popa
	
	mov eax, random
	mov edx, 0
	mov ebx, 9
	div ebx
	mov eax, edx

	
	mov ebx, 4
	mul ebx
	
	mov random, eax
	
;patrate libere

	cmp matrix[eax],0
	jne random_place
p1:
	cmp eax,0
	jne p2
	mov click_x, 100
	mov click_y, 100
	jmp final
p2:
	cmp eax,4
	jne p3
	mov click_x, 200
	mov click_y, 100
	jmp final
p3:
	cmp eax,8
	jne p4
	mov click_x, 300
	mov click_y, 100
	jmp final
p4:
	cmp eax,12
	jne p5
	mov click_x, 100
	mov click_y, 200
	jmp final
p5:
	cmp eax,16
	jne p6
	mov click_x, 200
	mov click_y, 200
	jmp final
p6:
	cmp eax,20
	jne p7
	mov click_x, 300
	mov click_y, 200
	jmp final
p7:
	cmp eax,24
	jne p8
	mov click_x, 100
	mov click_y, 300
	jmp final
p8:
	cmp eax,28
	jne p9
	mov click_x, 200
	mov click_y, 300
	jmp final
p9:
	cmp eax,32
	jne player
	mov click_x, 300
	mov click_y, 300
	jmp final
	
final:
	;cand ajunge aici inseamna ca a gasit un patrat liber mai sus si pune un simbol in functie
	;de al cui rand este,daca este X sau O
	cmp your_turn,0
	je random_x
	push eax
	make_O click_x,click_y
	pop eax
	mov matrix[eax],2
	dec your_turn
	jmp verificareO
	random_x:
	push eax
	make_X click_x,click_y
	pop eax
	mov matrix[eax],1
	inc your_turn
	jmp verificareX
	
	; your_turn -> variabila initiata cu 0 si care tine cont de randul jucatorului
;daca e your_turn=0 atunci e randul lui X si cand se pune X-ul pe tabla atunci 
;incrementam si X iar daca ar fi fost 0 am fi decrementat your_turn


;cum desenam X si O?
;avem 2 macrouri ,unul pentru X si unul pentru O
player:
	
	
;aici vezi daca dai click in careul de joc 300 / 300
	mov eax,[ebp+arg2]
	cmp eax,100 ; ideea e ca si x-ul si y-ul incepe de la 100 deci de la 100,400
	jl evt_timer
	cmp eax,400
	jg evt_timer
	sub eax,100
	mov edx, 0
	div hundred ;;; aici nu pun comentarii ca nu stiu cat ai putea intelege pe foaie e cel mai bine
	mov position,eax
	mul hundred
	add eax,100
	mov click_x,eax
	
	mov eax,[ebp+arg3]
	cmp eax,100
	jl evt_timer
	cmp eax,400
	jg evt_timer
	sub eax,100
	mov edx, 0
	div hundred
	mov position_final, eax
	mul hundred
	add eax,100
	mov click_y,eax
	; position_final - linie   position - element linie
	
	lea esi, matrix
	mov eax, position_final
	mov ebx, 3
	mul ebx
	mov ebx, 4
	mul ebx
	
	add esi, eax
	
	mov eax, position
	mov ebx, 4
	mul ebx
	
	add esi, eax
	
	
	
	
	mov eax, 0
	cmp [esi],eax
	jne evt_timer
	
	cmp your_turn,0
	jne turn_o
	
	push esi
	make_x click_x,click_y
	pop esi
	mov eax, 1
	add [esi], eax
	jmp verificareX
	verX:
	inc your_turn
	jmp evt_timer
	turn_o:
	
	push esi
	make_O click_x,click_y
	pop esi
	
	mov eax, 2
	add [esi],eax
	jmp verificareO
	verO:
	dec your_turn
	jmp evt_timer
	
verificareX:
;iar aici verifici toate formatiile posile dupa ce pui un simbol
;prima linie,a doua linie , pana pe verticala
first_line:
		;first line
		cmp matrix[0],1 ; 0->nu este nimic,1->X,2->O
		jne second_line
		cmp matrix[4],1
		jne second_line
		cmp matrix[8],1
		jne second_line
		horizontal_line 50,150,400,0FF0000h
		jmp init
second_line:
		;second line 
		cmp matrix[12],1
		jne third_line
		cmp matrix[16],1
		jne third_line
		cmp matrix[20],1
		jne third_line
		horizontal_line 50,250,400,0FF0000h
		jmp init
third_line:	
		;third line 
		cmp matrix[24],1
		jne first_v
		cmp matrix[28],1
		jne first_v
		cmp matrix[32],1
		jne first_v
		horizontal_line 50,350,400,0FF0000h
		jmp init
first_v:
		;first column 
		cmp matrix[0],1
		jne second_v
		cmp matrix[12],1
		jne second_v
		cmp matrix[24],1
		jne second_v
		vertical_line 150,50,400,0FF0000h
		jmp init
second_v:
		;second column 
		cmp matrix[4],1
		jne third_v
		cmp matrix[16],1
		jne third_v
		cmp matrix[28],1
		jne third_v
		vertical_line 250,50,400,0FF0000h
		jmp init
third_v:
		;second column 
		cmp matrix[8],1
		jne first_c
		cmp matrix[20],1
		jne first_c
		cmp matrix[32],1
		jne first_c
		vertical_line 350,50,400,0FF0000h
		jmp init
first_c:
		;first cross 
		cmp matrix[0],1
		jne second_c
		cmp matrix[16],1
		jne second_c
		cmp matrix[32],1
		jne second_c
		cross_right_line 50,50,400,0FF0000h
		jmp init
second_c:
		;second cross 
		cmp matrix[8],1
		jne not_x
		cmp matrix[16],1
		jne not_x
		cmp matrix[24],1
		jne not_x
		cross_left_line 450,50,400,0FF0000h
		jmp init
not_x:
	jmp verX
init:
		mov matrix[0],10
		mov matrix[4],10
		mov matrix[8],10
		mov matrix[12],10
		mov matrix[16],10
		mov matrix[20],10
		mov matrix[24],10
		mov matrix[28],10
		mov matrix[32],10
		make_text_macro 'X',area,230,10
		make_text_macro 'W',area,250,10
		make_text_macro 'I',area,260,10
		make_text_macro 'N',area,270,10
	jmp verX
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

verificareO:

first_lineO:
		;first line
		cmp matrix[0],2
		jne second_lineO
		cmp matrix[4],2
		jne second_lineO
		cmp matrix[8],2
		jne second_lineO
		horizontal_line 50,150,400,0FFh
		jmp initO
second_lineO:
		;second line 
		cmp matrix[12],2
		jne third_lineO
		cmp matrix[16],2
		jne third_lineO
		cmp matrix[20],2
		jne third_lineO
		horizontal_line 50,250,400,0FFh
		jmp initO
third_lineO:	
		;third line 
		cmp matrix[24],2
		jne first_vO
		cmp matrix[28],2
		jne first_vO
		cmp matrix[32],2
		jne first_vO
		horizontal_line 50,350,400,0FFh
		jmp initO
first_vO:
		;first column 
		cmp matrix[0],2
		jne second_vO
		cmp matrix[12],2
		jne second_vO
		cmp matrix[24],2
		jne second_vO
		vertical_line 150,50,400,0FFh
		jmp initO
second_vO:
		;second column 
		cmp matrix[4],2
		jne third_vO
		cmp matrix[16],2
		jne third_vO
		cmp matrix[28],2
		jne third_vO
		vertical_line 250,50,400,0FFh
		jmp initO
third_vO:
		;second column 
		cmp matrix[8],2
		jne first_cO
		cmp matrix[20],2
		jne first_cO
		cmp matrix[32],2
		jne first_cO
		vertical_line 350,50,400,0FFh
		jmp initO
first_cO:
		;first cross 
		cmp matrix[0],2
		jne second_cO
		cmp matrix[16],2
		jne second_cO
		cmp matrix[32],2
		jne second_cO
		cross_right_line 50,50,400,0FFh
		jmp initO
second_cO:
		;second cross 
		cmp matrix[8],2
		jne not_O
		cmp matrix[16],2
		jne not_O
		cmp matrix[24],2
		jne not_O
		cross_left_line 450,50,400,0FFh
		jmp initO
not_O:
	jmp verO
initO:
		mov matrix[0],10
		mov matrix[4],10
		mov matrix[8],10
		mov matrix[12],10
		mov matrix[16],10
		mov matrix[20],10
		mov matrix[24],10
		mov matrix[28],10
		mov matrix[32],10
		make_text_macro 'O',area,230,10
		make_text_macro 'W',area,250,10
		make_text_macro 'I',area,260,10
		make_text_macro 'N',area,270,10
	jmp verO	


evt_timer:
	inc counter
	
afisare_litere:
	;afisam valoarea counter-ului curent (sute, zeci si unitati)
	mov ebx, 10
	mov eax, counter
	;cifra unitatilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 30, 10
	;cifra zecilor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 20, 10
	;cifra sutelor
	mov edx, 0
	div ebx
	add edx, '0'
	make_text_macro edx, area, 10, 10
	;make_x 100,100
	;make_O 200,200
	
	horizontal_line 100,100,300,0FFFFFFh
	horizontal_line 100,200,300,0FFFFFFh
	horizontal_line 100,300,300,0FFFFFFh
	horizontal_line 100,400,300,0FFFFFFh
	vertical_line 100,100,300,0FFFFFFh
	vertical_line 200,100,300,0FFFFFFh
	vertical_line 300,100,300,0FFFFFFh
	vertical_line 400,100,300,0FFFFFFh
	
	make_text_macro 'P',area, 10, 465
	make_text_macro 'L',area, 20, 465
	make_text_macro 'A',area, 30, 465
	make_text_macro 'Y',area, 40, 465
	                              
    make_text_macro 'V',area, 60, 465
	make_text_macro 'S',area, 70, 465
	
	make_text_macro 'C',area, 90, 465
	make_text_macro 'P',area, 100, 465
	make_text_macro 'P',area, 110, 465
	
	make_text_macro 'R',area, 440, 465
	make_text_macro 'E',area, 450, 465
	make_text_macro 'S',area, 460, 465
	make_text_macro 'E',area, 470, 465
	make_text_macro 'T',area, 480, 465
	
	
final_draw:
	popa
	mov esp, ebp
	pop ebp
	ret
draw endp

start:
	;alocam memorie pentru zona de desenat
	mov eax, area_width
	mov ebx, area_height
	mul ebx
	shl eax, 2
	push eax
	call malloc
	add esp, 4
	mov area, eax
	
	; mov eax, area_width
	; mov ebx, area_height
	; mul ebx
	; shl eax, 2
	; push eax
	; push 255
	; push area
	; call memset
	; add esp, 12
	
	;apelam functia de desenare a ferestrei
	; typedef void (*DrawFunc)(int evt, int x, int y);
	; void __cdecl BeginDrawing(const char *title, int width, int height, unsigned int *area, DrawFunc draw);
	push offset draw
	push area
	push area_height
	push area_width
	push offset window_title
	call BeginDrawing
	add esp, 20
	
	;terminarea programului
	push 0
	call exit
end start
