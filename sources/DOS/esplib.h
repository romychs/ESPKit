/*
================================================
 Header file for Sprinter-WiFi ISA Card Library
 Author: Roman A. Boykov
 License: BSD 3-Clause
================================================
 */

#include "espdef.h"

#ifndef __ESPLIB_H
#define __ESPLIB_H


#define DEBUG

/* Size of buffer for last response line */
#define LSTR_SIZE 20
#define LF 0x0A
#define CR 0x0D

enum CMD_RESULT { RESULT_OK, RESULT_ERROR, RESULT_FAIL, RESULT_TX_TIMEOUT, RESULT_RS_TIMEOUT, RESULT_CONNECTED, RESULT_NOT_CONNECTED, RESULT_ENABLED, RESULT_DISABLED };



 /*
  Small delay
    delay - number of ms, if delay=0, then 20ms
 */
void util_delay(unsigned delay_ms);

/*
   Init ISA card
   Result:
      0 - Not Found
      1 - Sprinter WiFi Found and initialized
*/
char isa_init(void);

/*
 Reset ISA device
*/
void isa_reset(void);

/*
  Open access to ISA ports as memory
*/
void isa_open(void);

/*
  Close access to ISA ports
*/
void isa_close(void);


char isa_get_slot(void);

/*
  Find UART device TL16C550
    return 0 - Not found
*/
char find_wifi(void);

/*
  Init UART device TL16C550
    Input:
       slot - ISA Slot number
*/
void uart_init(void);

/*
  Read TL16C550 register
    Input:
       reg - Port number
    Output:
       value from register
*/
char uart_read(unsigned reg);

/*
  Write TL16C550 register
    Input:
       reg - Port number
       value - value to write toregister
*/
void uart_write(unsigned reg, char value);

/*
  Wait for transmitter ready
     Output:
      0 - tr not ready, !=0 - tr ready
*/
char uart_wait_tr(void);

/*
  Empty receiver FIFO buffer
*/
void uart_empty_rs(void);

/*
  Wait byte in receiver fifo
	  Input:
		  wait_ms milliseconds to wait response
	  Output:
		  0 - fifo still empty, !=0 - receiver fifo is not empty
*/
char uart_wait_rs(int wait_ms);


/*
  Transmitt one byte
     Input:
        byte to transmit
	  Output:
		  0 - failure, transmitter not ready, !=0 - success
*/
char uart_tx_byte(char byte);

/*
  Transmitt bytes
     Input:
        tbuff - pointer to buffer
        size  - number of bytes to transmitt from buffer
     Output:
        RESULT_OK if ok and RESULT_TX_TIMEOUT otherwise
*/
char uart_tx_buffer(char* tbuff, int size);

/*
  Transmitt AT-command to ESP and wait response
     Input:
        tx_buff - command, zero ended string
        rs_buff - buffer to place response from ESP
        size - size of response buffer
        wait_ms - time to wait AT-command response from ESP
*/
char uart_tx_cmd(char* tx_buff, char* rs_buff, int size, int wait_ms);


// MODULE esp

/*
  Reset ESP device
*/
void esp_reset(char full);


#endif