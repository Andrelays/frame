.model tiny
.286
.code
org 100h
locals @@
;-------------------------------------------------------------------
;Args: 1 - length 			(decimal number)
;	   2 - width  		 	(decimal number)
;	   3 - frame color		(hex number)
;	   4 - border color		(hex number)
;	   5 - number of style 	(is digit (0 or 1)
;Example: frame.com 20 8 1A 32 1
;--------------------------------------------------------------------
PTR_CMD    		equ 0080h  ; ptr of cmd line
PTR_VIDMEM    	equ 0b800h ; ptr of video memory

x_coord_average equ 40
y_coord_average equ 12
;--------------------------------------------------------------------
Start: 				jmp main
;------------------------------MAIN----------------------------------
;[bp-2]  - length
;[bp-4]  - width
;[bp-6]  - frame_color
;[bp-8]  - border_color
;[bp-10] - style of frame
;--------------------------------------------------------------------
main				proc
					push bp								;save bp
					mov  bp, sp
					sub  sp, 10   						;5 local vars in stack

					mov si, PTR_CMD         			;si - ptr of cmd line
					inc si

					call skip_spaces					;data input
					call strtoi
					mov [bp-2], ax						;input length

					call skip_spaces
					call strtoi
					mov [bp-4], ax						;input width

					call skip_spaces
					call strtoh
					mov [bp-6], ax						;input frame_color

					call skip_spaces
					call strtoh
					mov [bp-8], ax						;input border_color

					call skip_spaces
					call strtoi
					imul ax, 9
					add ax, offset control_str_array
					mov [bp-10], ax						;input style of frame

					mov bx, PTR_VIDMEM
	    			mov es, bx							;es - ptr of video memory

					push [bp-4]
					push [bp-6]
					push [bp-8]
					push [bp-10]
					push [bp-2]

        			call draw_frame

	    			mov ax, 4c00h
	    			int 21h

					mov sp,bp
        			pop bp
        			ret
main 				endp
;-----------------------FUNCTIONS-------------------------------

;------------------------STRTOI---------------------------------
;Converts a string to a number and returns it in the AX register
;Return:  AX - number
;Assumes: SI is ptr of the beginning of the line
;Destr: AX, SI
;---------------------------------------------------------------
strtoi				proc
					push cx						;save registers
					push bx

					mov bx, 10
					mov ax, 0
					mov al, [si]
					cmp al, '0'
					jb @@end_while_cycle
					cmp al, '9'
					ja @@end_while_cycle
					sub al, '0'
					inc si
@@while_cycle:
					mov cl, [si]
					cmp cl, '0'
					jb @@end_while_cycle
					cmp cl, '9'
					ja @@end_while_cycle
					sub cl, '0'
					mul bx
					add ax, cx
					inc si
					jmp @@while_cycle
@@end_while_cycle:
					pop bx
					pop cx

					ret
strtoi				endp

;------------------------STRTOH---------------------------------
;Converts a string to a hex number and returns it in the AX register
;Return:  AX - hex number
;Assumes: SI is ptr of the beginning of the line
;Destr: AX, SI
;---------------------------------------------------------------
strtoh				proc
					push cx						;save registers
					push bx

					mov bx, 16
					mov ax, 0
					mov al, [si]
					cmp al, '0'
					jb @@end_while_cycle
					cmp al, '9'
					ja @@end_while_cycle
					sub al, '0'
					inc si
@@while_cycle:
					mov cl, [si]
					cmp cl, '0'
					jb @@let
					cmp cl, '9'
					ja @@let
					sub cl, '0'
					jmp @@writing_number

@@let:				cmp cl, 'A'
					jb @@end_while_cycle
					cmp cl, 'F'
					ja @@end_while_cycle
					add cl, -'A' + 10

@@writing_number:
					mul bx
					add ax, cx
					inc si
					jmp @@while_cycle
@@end_while_cycle:
					pop bx
					pop cx

					ret
strtoh				endp
;------------------------SKIP_SPACES----------------------------
;Skip spaces in string
;Assumes: SI is ptr of the beginning of the line
;Destr: SI
;---------------------------------------------------------------
skip_spaces			proc
@@while_cycle:
					cmp byte ptr [si], ' '
					jne  @@end_while_cycle
					inc si
					jmp @@while_cycle
@@end_while_cycle:
					ret
skip_spaces			endp
;------------------------------DRAW_FRAME----------------------------
;Draw a frame to video memory
;Entry: [bp+4]  - length
;		[bp+6]  - style of frame
;		[bp+8]  - border_color
;		[bp+10] - frame_color
;		[bp+12] - width
;Assumes: es = 0b800h
;--------------------------------------------------------------------
draw_frame			proc
					push bp
					mov  bp, sp

					push bx							;save registers
					push cx
					push ax
					push dx
					push di

					mov cx, [bp+4]					;length
					mov bx, [bp+12]   				;width
					shr bx, 1						;width  / 2
					shr cx, 1						;length / 2
					mov ax, x_coord_average
					mov dx, y_coord_average
					sub ax, cx						;y_coord_average - frame_width  / 2
					sub dx, bx						;x_coord_average - frame_length / 2
					imul dx, 80						;(y_coord_average - frame_width / 2) * 80
					mov di, ax
					add di, dx
					shl di, 1						;mov di, ((y_coord_average - frame_width / 2) * 80 + (x_coord_average - frame_length / 2)) * 2

					mov  bx, [bp + 6]

					push [bp + 10]
					push [bp + 8]
					push  bx
					push [bp + 4]

					call draw_line					;draw the first line of the frame

					add bx, 3						;bx is next line of array

					;(80 - frame_length - 2) * 2
					mov cx, [bp+12]
					sub cx, 2						;cx is frame_width - 2

@@draw_inside_frame:
					mov ax, 80
					sub ax, [bp+4]
					shl ax, 1
					add di, ax						;di += (80 - frame_length) * 2

					push [bp + 10]
					push [bp + 8]
					push  bx
					push [bp + 4]

					call draw_line
					loop @@draw_inside_frame

					mov ax, 80
					sub ax, [bp+4]
					shl ax, 1
					add di, ax						;di += (80 - 2 - frame_length) * 2

					add bx, 3						;bx is next line of array

					push [bp + 10]
					push [bp + 8]
					push  bx
					push [bp + 4]

					call draw_line					;draw the last line of the frame

					pop di
					pop dx
					pop ax
					pop cx							;ret regs
					pop bx
					pop bp

					ret 10
draw_frame  		endp
;------------------------------DRAW_LINE-----------------------------
;Draw a line to video memory
;Entry: [bp+4]  - length
;		[bp+6]  - style of frame
;		[bp+8]  - border_color
;		[bp+10] - frame_color
;Assumes: es = 0b800h
;		  di is ptr of the beginning of the line
;--------------------------------------------------------------------
draw_line   		proc
					push bp
					mov  bp, sp

					push ax
					push bx							;save registers
					push cx

	    			mov  bx, [bp + 6]				;bx - style of frame

	    			mov  ah, [bp + 8]
					add  ah, [bp + 10]				;draw - first character
					mov  al, [bx]
        			stosw

					mov  ah, [bp + 8]
					add  ah, [bp + 10]
	    			mov  al, [bx] + 1				;draw - second character * (length - 2)
	    			mov  cx, [bp + 4]
					sub  cx,  2
        			rep  stosw

					mov  ah, [bp + 8]
					add  ah, [bp + 10]				;draw - third character
					mov  al, [bx] + 2
					stosw

					pop cx
					pop bx							;ret regs
					pop ax
					pop bp

        			ret 8
draw_line   		endp

control_str_array 			db 0c9h, 0cdh, 0bbh
				  			db 0bah, 020h, 0bah
				  			db 0c8h, 0cdh, 0bch
							db 0dah, 0c4h, 0bfh
				  			db 0b3h, 020h, 0b3h
				  			db 0c0h, 0c4h, 0d9h
end Start

