; ---------------------------------------------------------------------------
; Allowing inbound TCP connections to the device is done by setting a
; the UART_MCR register to a value of $08. If you wish to drop the current connection
; and block future connections, write a value of $00 to UART_MCR. 

Allow_Connections:
	move.b	#$08,(UART_MCR)		; Allow inbound connections on port 5364.
	rts

Deny_Connections:
	move.b	#$00,(UART_MCR)		; Drop/Deny connections inbound
	rts
; ---------------------------------------------------------------------------
; To make a connection to another device via TCP you will need to send a connection
; command through the UART to the XPICO by writing an IP address and port "C70.13.153.10:5364\n".
; You can also use DNS in place of the IP address as well "Cwebsite.com:80\n". All Retro.link 
; cartidges use the port 5364 for incoming connections. 

Connect:
	lea	IP_ADDRESS(pc),A0	; Our string to send
	moveq	#22-1,D1		; Number of bytes to send
.loop
	move.b	(a0)+,d0		; Move byte from string to d0
	bsr.s	Send_Byte		; Send byte in d0
	dbf	d1,.loop		; Decrement and branch until done
	rts				; return

IP_ADDRESS:	 dc.b 'C000.000.000.000:5364\n',0

; This will either return a single 'C' character if a connection was successfully made or an 'N'
; character which means it could not connect to the supplied address. Once connected you can read
; or write serial data to the other device immediately. 

; When receiving an inbound connection, you will receive a string of text. This string contains 'CI'
; and then the IP address of the remote device connecting. 'CI192.168.1.150'. 

; When the device disconnects or is disconnected it will return a 'D' character.
; ---------------------------------------------------------------------------
; Sending or receving data is done a byte at a time querying the UART status register
Send_Byte:
-	btst	#5,UART_LSR		; Ok to send?
	beq.s	-			; Wait until ok
	move.b	d0,UART_THR		; Send a byte
	rts				; Return

Receive_Byte:
-	btst	#0,UART_LSR		; Data available?
	beq.s	-			; No. So wait and check until data arrives
	move.b	UART_RHR,d0		; Read in byte from receive buffer to d0
	rts				; Return

Flush_Fifos:
	move.b	#$07,UART_FCR		; Flush send/receive fifos
	rts				; Return
; ---------------------------------------------------------------------------
; example
;SendCompPlayerInput:
;	movea.w	(playerinputaddr).w,a1
;	moveq	#4-1,d1
;-	move.b	(a1)+,d0
;	bsr.s	Send_Byte
;	dbf	d1,-
;	rts

;GetCompPlayerInput:
;	movea.w	(playerinputaddr).w,a1
;	moveq	#4-1,d1
;-	bsr.s	Receive_Byte
;	move.b	d0,(a1)+
;	dbf	d1,-
;	rts