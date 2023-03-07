/*
==========================================================
 Header file with Definitions for Sprinter-WiFi ISA Card
 Author: Roman A. Boykov
 License: BSD 3-Clause
==========================================================
*/

#ifndef __ESPDEF_H
#define __ESPDEF_H

//#define ESTEXT

#define PORT_ISA        0x9FBD
#define PORT_SYSTEM		0x1FFD
#define PORT_MMU3       0xE2

#ifdef ESTEX
#define PORT_UART		   0xC3E8                     // COM3 base port in memory
#else
#define PORT_UART		   0x03E8                     // COM3 base port
#endif

/* UART TC16C550 Registers */
#define REG_RBR 		   PORT_UART + 0
#define REG_THR 		   PORT_UART + 0
#define REG_IER 		   PORT_UART + 1
#define REG_IIR 		   PORT_UART + 2
#define REG_FCR         PORT_UART + 2
#define REG_LCR 		   PORT_UART + 3
#define REG_MCR 		   PORT_UART + 4
#define REG_LSR 		   PORT_UART + 5
#define REG_MSR 		   PORT_UART + 6
#define REG_SCR 		   PORT_UART + 7
#define REG_DLL 		   PORT_UART + 0
#define REG_DLM 		   PORT_UART + 1
#define REG_AFR 		   PORT_UART + 2

/* UART TC16C550 Register bits */
#define MCR_DTR         0x01
#define MCR_RTS         0x02
#define MCR_RST         0x04
#define MCR_PGM         0x08
#define MCR_LOOP        0x10
#define MCR_AFE         0x20

#define LCR_WL8         0x03                // 8 bits word len
#define LCR_SB2         0x04                // 1.5 or 2 stp bits
#define LCR_DLAB        0x80                // enable Divisor latch

#define FCR_FIFO        0x01                // Enable FIFO for rx and tx
#define FCR_RESET_RX    0x02                // Reset Rx FIFO
#define FCR_RESET_TX    0x04                // Reset Tx FIFO
#define FCR_DMA         0x08                // set -RXRDY, -TXRDY to "1"
#define FCR_TR1         0x00                // trigger on 1 byte in fifo
#define FCR_TR4         0x40                // trigger on 4 bytes in fifo
#define FCR_TR8         0x80                // trigger on 8 bytes in fifo
#define FCR_TR14        0xC0                // trigger on 14 bytes in fifo

#define LSR_DR          0x01                // Data Ready
#define LSR_OE          0x02                // Overrun Error
#define LSR_PE          0x04                // Parity Error
#define LSR_FE          0x08                // Framing Error
#define LSR_BI				0x10					  // Break Interrupt
#define LSR_THRE        0x20                // Transmitter Holding Register
#define LSR_TEMT        0x40                // Transmitter empty
#define LSR_RCVE        0x80                // Error in receiver FIFO



/* PORT_ISA bits */
#define ISA_A14         0x01
#define ISA_A15         0x02
#define ISA_A16         0x04
#define ISA_A17         0x08
#define ISA_A18         0x10
#define ISA_A19         0x20
#define ISA_AEN         0x40
#define ISA_RESET       0x80

/* Speed divider for UART */
#define BAUD_RATE       115200              // Connection speed with ESP8266
#define XIN_FREQ 	      14745600            // On board frequency generator for TL16C550
#define DIVISOR 		   8                   // XIN_FREQ / (BAUD_RATE * 16) Frequency divider for Transmitter/Receiver

#endif