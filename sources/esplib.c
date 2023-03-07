/*
==================================================
 Implementation of Sprinter-WiFi ISA Card Library
 Author: Roman A. Boykov
 License: BSD 3-Clause
==================================================
*/

#include <stdio.h>
#include <conio.h>
#include <time.h>
#include <string.h>
#include "esplib.h"

#ifdef ESTEX
#pragma nonrec
#define outb(port, b) mset(port, b);
#define inb(port) mget(port);
#else
#define outb(port, b) outp(port, b);
#define inb(port) inp(port);
#endif


void util_delay(unsigned delay_ms)
{
#ifdef ESTEX
   if (delay_ms==0) {
      delay_ms = 20;
   }
	unsigned ctr;
	for (ctr = 0; ctr < delay_ms*1000; ctr++)
	{
   }
#else
   clock_t t;
   t = clock() + delay_ms;
   while (clock() < t) {
   }

	//delay(delay_ms);
#endif
}

char save_mmu3 = 0;       // Variable to save Sprinter memory mapping
char isa_slot = -1;       // Variable to storeISA slot number where WiFi card found

char isa_init()
{
    char wifi_found;
    wifi_found = find_wifi();
    if (wifi_found) {
       isa_reset();
       return 1;
    } else {
       return 0;
    }
}


void isa_reset()
{
#ifdef ESTEX
   outp(port_isa, ISA_RESET | ISA_AEN); // RESET=1 AEN=1
   delay(20);
   outp(port_isa, 0);    // RESET=0 AEN=0
   delay(40);
#endif
}


void isa_open()
{
#ifdef ESTEX
   save_mmu3 = inp(PORT_MMU3);
	outp(PORT_SYSTEM, 0x11);
	outp(PORT_MMU3, ((isa_slot & 0x01) << 1) | 0xd4);
#endif
}

void isa_close()
{
#ifdef ESTEX
   outp(PORT_SYSTEM, 0x01);
   // restore mmu3 (Close ISA ports memory mapping)
   outp(PORT_MMU3, save_mmu3);
#endif
}

char isa_get_slot()
{
    return isa_slot;
}

char check_slot(char slot)
{
    char irr;
    isa_slot = slot;
	 isa_open();
	 irr = inb(REG_IIR);
    isa_close();
    return irr & 0x3F;
}


char find_wifi()
{
    // check isa slot 0
	 char exists;
    exists = check_slot(0);
    if (exists) {
	return 1;
    } else {
#ifdef ESTEX
	return check_slot(1);
#else
	return 0;
#endif
    }
}


// MODULE uart

void uart_init()
{
	 isa_open();
	 // enable FIFO buffer, trigger to 14 byte
	 outb(REG_FCR, FCR_TR14 | FCR_FIFO);
	 // Disable interrupts
	 outb(REG_IER, 0x00);
	 // Set 8bit word and Divisor for speed
	 outb(REG_LCR, LCR_DLAB | LCR_WL8);  // enable Baud rate latch
	 outb(REG_DLL, DIVISOR);
	 outb(REG_DLM, 0x00);
	 outb(REG_LCR, LCR_WL8);             // 8bit word
	 isa_close();
}

char uart_read(reg)
unsigned reg;
{
	 char res;
	 isa_open();
	 res = inb(reg);
	 isa_close();
	 return res;
}

void uart_write(reg, value)
unsigned reg;
char value;
{
	 isa_open();
	 outb(reg, value);
	 isa_close();
}

char uart_wait_tr()
{
	 char res;
	 char loops = 100;
	 while (loops>0)
	 {
		  res = uart_read(REG_LSR);

		  if (res & LSR_THRE) {
			 break;
		  }

		  loops--;
		  util_delay(1);
	 }
	 return loops;
}

char uart_tx_byte(byte)
char byte;
{
	char ready = uart_wait_tr();
	if (ready){
		uart_write(REG_THR, byte);
	}
	return ready;
}

char uart_tx_buffer(char* tbuff, int size)
{
	int ctr = size;
	while (ctr--) {
		if (uart_wait_tr()) {
		  uart_write(REG_THR, *tbuff++);
		} else {
		  return RESULT_TX_TIMEOUT;
		}
	}
	return RESULT_OK;
}

char uart_tx_cmd(char* tx_buff, char* rs_buff, int size, int wait_ms)
{
	char resp = RESULT_OK;
	char rcv, *buff;
	char lstr[LSTR_SIZE];
	int  lstrp = 0;
   buff = rs_buff;
   buff[size-1] = 0; // mark last byte of buffer as end of string
   size--;
	uart_empty_rs();

	if (uart_tx_buffer(tx_buff, strlen(tx_buff)) == RESULT_OK) {
		while (1) {
		  if (uart_wait_rs(wait_ms)) {
			 rcv = uart_read(REG_RBR);
          if (size > 0 && rcv != CR) { // ignore CR
             *buff++ = rcv;
             size--;
          }
			 if (rcv == CR || rcv == LF) {

				 lstr[lstrp] = 0;

				 if (strcmp(lstr, "OK")==0) {
					break;
				 }

				 if (strcmp(lstr, "ERROR")==0) {
					resp = RESULT_ERROR;
					break;
				 }

             if (strcmp(lstr, "FAIL")==0) {
               resp = RESULT_FAIL;
               break;
             }

				 lstrp = 0;
			 }

			 if (lstrp<LSTR_SIZE && rcv != CR && rcv != LF) {
				 lstr[lstrp++] = rcv;
			 }

		  } else {
#ifdef DEBUG
			 printf("No ansver to CMD, RCVR empty! %s\n", lstr);
#endif
			 return RESULT_RS_TIMEOUT;
		  }
		}
	   if (uart_wait_rs(1)) {
			 rcv = uart_read(REG_RBR); // read last LF
      }
      if (size > 0) {
         *buff = 0; // mark end of string
      }
#ifdef DEBUG
		printf(": '%s'\n", lstr);
#endif
	} else {
#ifdef DEBUG
	  printf("Cmd transmit error, TR not ready!\n");
#endif
	  return RESULT_TX_TIMEOUT;
	}
	return resp;
}


void uart_empty_rs()
{
	uart_write(REG_FCR, FCR_TR14 | FCR_RESET_RX | FCR_FIFO);
}

char uart_wait_rs(wait_ms)
int wait_ms;
{
	char res;
	unsigned loops;

	if (wait_ms<0) {
	  loops = 1;
	} else {
	  loops = wait_ms;
	}

	while (loops>0) {
		res = uart_read(REG_LSR) & LSR_DR;
		if (res){
			break;
		}
		loops--;
		util_delay(1);
	}

	return loops>0;
}



void esp_reset(char full)
{
	isa_open();
   if (full) {
	   outb(REG_MCR, MCR_RST | MCR_RTS)    // 0110b ESP  -PGM=1, -RST=0, -RTS=0
	   util_delay(20);
   }
	outb(REG_MCR, MCR_AFE | MCR_RTS)    // 0x0202 -RST = 1 -RTS=0 AutoFlow enabled
	isa_close();
   if (full) {
	   util_delay(1000);
   }
}

