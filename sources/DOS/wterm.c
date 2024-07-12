/*
=====================================================
 Simple terminal program for Sprinter-WiFi ISA Card
 Author: Roman A. Boykov
 License: BSD 3-Clause
=====================================================
*/


#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "esplib.h"
#include "wterm.h"

#define RS_BUFF_SIZE 2048

char* quit = "QUIT\r";
char* version = "AT+GMR\r\n\0";
char* set_speed = "AT+UART_CUR=115200,8,1,0,3\r\n\0";
char* echo_off = "ATE0\r\n\0";
char* station_mode = "AT+CWMODE=1\r\n\0";
char* no_sleep = "AT+SLEEP=0\r\n\0";
char* check_conn_ap_cmd = "AT+CWJAP?\r\n\0";
char  rs_buff[RS_BUFF_SIZE];

void init_console()
{
  clrscr();
}

char esp_check_conn_ap(char* ssid, int size)
{
   char *eol, *eos;
   char res;
   int len;

   res = uart_tx_cmd(check_conn_ap_cmd, rs_buff, RS_BUFF_SIZE, 2000);
   if (res == RESULT_OK) {
      eol = (char *) strchr(rs_buff, LF);
      if (eol) {
         len = eol - rs_buff;
         printf("<LF> found at: %d\n", len);
         if (len>8 && strncmp("+CWJAP:\"", rs_buff,8) == 0) {
            res = RESULT_CONNECTED;
            if (ssid != NULL) {
               eos = (char *) strchr(rs_buff+8, '"');
             	if (eos) {
               	printf("end bracket found at %d\n", eos-rs_buff);
                  len = eos-rs_buff-8;
                  if (len > (size-1)) {
                     len = size-1;
                  }
                  strncpy(ssid, rs_buff+8, len);
                  *(ssid+len) = 0;
               }
            }
         } else {
             if (strncmp("No AP",rs_buff,5) == 0) {
             	res = RESULT_NOT_CONNECTED;
             } else {
               printf("Unknown ESP response:\n%s\n", rs_buff);
               res = RESULT_ERROR;
             }
         }
      } else {
         printf("<LF> not found!\n");
         res = RESULT_NOT_CONNECTED;
      }
   }
   return res;
}

void init_esp(void) {
#ifdef DEBUG
   printf("Echo off");
#endif
	uart_tx_cmd(echo_off, NULL, 0, 100);
#ifdef DEBUG
   printf("Station mode");
#endif
	uart_tx_cmd(station_mode, NULL, 0, 100);
#ifdef DEBUG
   printf("No sleep");
#endif
   uart_tx_cmd(no_sleep, NULL, 0, 100);
#ifdef DEBUG
   printf("Setup uart");
#endif
	uart_tx_cmd(set_speed, NULL, 0, 500);
}


void main()
{
	char found, q, tx_data, rx_data;

	clrscr();

	printf(MSG_START);
	found = isa_init();
	if (!found) {
		printf(MSG_NOT_FOUND);
		exit(EXIT_FAILURE);
	}
	printf(MSG_FOUND, isa_get_slot());

	uart_init();
	esp_reset(1);
   init_esp();

   printf(MSG_HLP);
   uart_empty_rs();
	rx_data = 0;
	q = 0;

	do {
		if(kbhit()) {
			tx_data = getch();

			// check for QUIT
			if (q <= 4 && tx_data == quit[q]) {
				q++;
				if (q > 4) break;
			} else q = 0;

			if ((tx_data == CR) || (tx_data > 0x1f)) putchar(tx_data);
			uart_tx_byte(tx_data);
			if (tx_data == CR) {
				putchar(LF);
				uart_tx_byte(LF);
			}
			if (tx_data == LF) {
				uart_tx_byte(CR);
			}
		}

		while (1) {
			rx_data = uart_read(REG_LSR);
			if (rx_data & 0x80) {
				printf("Receiver error LSR: %2x\n", (unsigned char)rx_data);
				uart_empty_rs();
				break;
			} else {
			  if (rx_data & 0x01) {
				  rx_data = uart_read(REG_RBR);
				  if ((rx_data == CR)||(rx_data > 0x1f)) putchar(rx_data);
				  if (rx_data == CR) putchar(LF);
			  } else {
				  break;
			  }
			}
		}

	} while(q < 5);
	printf("\nBye!\n");

}
