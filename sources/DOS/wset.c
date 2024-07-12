/*
=====================================================
 ESP Setup program for Sprinter-WiFi ISA Card
 Author: Roman A. Boykov
 License: BSD 3-Clause
=====================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "esplib.h"
#include "wset.h"

char* set_speed = "AT+UART_CUR=115200,8,1,0,3\r\n\0";
char* echo_off = "ATE0\r\n\0";
char* station_mode = "AT+CWMODE=1\r\n\0";
char* no_sleep = "AT+SLEEP=0\r\n\0";
char* check_conn_ap_cmd = "AT+CWJAP?\r\n\0";
char* cwlap_opt = "AT+CWLAPOPT=1,23\r\n\0";
char* get_ap_list_cmd = "AT+CWLAP\r\n\0";
char* get_dhcp_cmd = "AT+CWDHCP?\r\n\0";
char* set_dhcp_cmd = "AT+CWDHCP=1,1\r\n\0";
char* get_ip_cmd = "AT+CIPSTA?\r\n\0";

char* cmd_end = "\r\n\0";

char  rs_buff[RS_BUFF_SIZE];

/*
  Encription mode names
*/
char* ecn[] = {"Open", "WEP", "WPA_PSK", "WPA2_PSK", "WPA_WPA2_PSK",
               "WPA2_ENTERPRISE", "WPA3_PSK", "WPA2_WPA3_PSK"};

/*
  Cause of connection errors
*/
char* conn_fault[] = {"None", "Connection timeout", "Wrong password",
               "Can not find network", "Connection failed"};

void init_console()
{
  clrscr();
}

/*
  Init basic parameters of ESP
*/
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
#ifdef DEBUG
   printf("Setup options");
#endif
	uart_tx_cmd(cwlap_opt, NULL, 0, 100);

}


/*
  Check connection to AP
  Input:
     ssid - pointer to buffer for Network ID
     size - size of ssid buffer
  Output:
     RESULT_CONNECTED - if Ok
     ssid - ID of network with which connection established
     RESULT_NOT_CONNECTED - if no connections
*/
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
         if (len>8 && strncmp("+CWJAP:\"", rs_buff,8) == 0) {
            res = RESULT_CONNECTED;
            if (ssid != NULL) {
               eos = (char *) strchr(rs_buff+8, '"');
             	if (eos) {
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
         res = RESULT_NOT_CONNECTED;
      }
   }
   return res;
}

/*
  Parse info about Access Point
  Input:
     buff - pointer to line in response with info about AP
     item - pointer to structure with info about AP
  Output:
     RESULT_OK - if parsing complete without errors
     item - pointer with filled info about AP
*/
char parse_ap_info(char *buff, struct ap_info *item)
{
	int res;
   char *bol, *eol;  // pointers to begin and end of line fragment
   bol = buff;
   eol = (char *) strchr(bol, ',');
   if (eol != NULL) {
      *eol = 0;
      item->ecn = atoi(bol);
      bol = eol+2;
      eol = (char *) strchr(bol, '"');
      if (eol != NULL) {
          *eol = 0;
          item->ssid = bol;
          bol = eol+2;
          eol = (char *) strchr(bol, ',');
          if (eol) {
             *eol = 0;
             item->rssi = atoi(bol);
             res = RESULT_OK;
          } else {
           	 res = RESULT_ERROR;
          }
      } else {
          res = RESULT_ERROR;
      }
   } else {
      res = RESULT_ERROR;
   }
   return res;
}

/*
   Get list of Access Points (Wireless networks)
	Input:
     ap_list - array to put info about AP
     size - size of array ap_list
   Output:
     ap_list - array with AP
     result_size - number of found AP in ap_list
 */
char esp_get_ap_list(struct ap_info ap_list[], int size, int *result_size)
{
   char *bol, *eol, *buff;
   char res;
   int ctr;
   ctr = 0;

   res = uart_tx_cmd(get_ap_list_cmd, rs_buff, RS_BUFF_SIZE, 5000);
   if (res == RESULT_OK) {
      buff = rs_buff;
      while (buff < rs_buff + RS_BUFF_SIZE && ctr < size) {
         // search begin of response line
         bol = (char *) strstr(buff, "+CWLAP:(");
         if (bol) {
            // search end of response line
            eol = (char *) strchr(buff, LF);
            if (eol) {
               *eol = 0; // mark end of line
               buff = eol+1;
		         if ( parse_ap_info(bol+8, &ap_list[ctr]) != RESULT_OK ) {
            		printf("Can not parse AP Item!\n%s\n", bol+8);
            		break;
         		} else {
                  ctr++;
               }
            } else {
               buff += 8;
            }
         } else {
            break;
         }
      }
      *result_size = ctr;

   }

   return res;
}


/*
  Try to connect to specified Wireles network
  Input:
     ssid - Network identifier
     passwd - password to use
  Output:
     RESULT_OK - if all Ok
     RESULT_FAIL - if error and message with details displayed
*/
char connect_network(char *ssid, char *passwd) {
   char *resp, *cmd, *bol, *eol;
   char res, code;

   resp = (char *)malloc(512);
   cmd = (char *)malloc(512);
   if (resp == NULL || cmd == NULL) {
      printf("CN Out of memory!\n");
      exit(1);
   }

   strset(cmd, 0);
   sprintf(cmd, "AT+CWJAP=\"%s\",\"%s\"", ssid, passwd);
   cmd = strcat(cmd, cmd_end);
   res = uart_tx_cmd(cmd, resp, 512, 1000);
   if (res != RESULT_OK) {
      if (res == RESULT_FAIL) {
        bol = (char *) strstr(resp, "+CWJAP:");
        if (bol) {
           bol += 7;
           eol = (char *) strchr(bol, LF);
           if (eol) {
              *eol = 0;
              code = atoi(bol);
              if (code>0 && code<5) {
                 printf("%s", conn_fault[code]);
              } else {
                 printf("Unknown error code: %d; '%s'", code, bol);
              }
           } else {
              printf("no EOL\n");
           }
        } else {
          printf("no +cwjap\n %s", resp);
        }
      }
   }

   free(resp);
   free(cmd);

   return res;
}

/*
  Output main menu to select user action
*/
char select_main_menu(void)
{
   char select;
   printf("\n1 - Select WiFi Network\n");
   printf("2 - Configure IP parameters\n");
   printf("3 - Display info\n0 - Exit\n");
	while (1) {
      printf("\nEnter number 0..3: ");
      scanf("%1d", &select);
      fflush(stdin);
      if (select >= 0 && select < 4) {
         break;
      }
   }
   return select;
}

/*
  Output list of available Wireles networks.
  Try to connect to network if required by user.
*/
void select_network(void)
{
   char *passwd, yn, res;
   int ap_list_size, ctr, select;
   struct ap_info ap_list[AP_LIST_SIZE];

   passwd = (char *)malloc(21);
   if (passwd == NULL) {
      printf("SN Out of memory!");
      exit(1);
   }

   while (1) {
#ifdef DEBUG
		printf("Get Network List");
#endif
      esp_get_ap_list(ap_list, AP_LIST_SIZE, &ap_list_size);

      printf("Select Wireless network to connect: \n\n");
      for (ctr = 0; ctr< ap_list_size; ctr++) {
         printf("%d - %s, %ddBm, %s\n",ctr+1, ap_list[ctr].ssid,
                ap_list[ctr].rssi, ecn[ap_list[ctr].ecn]);
      }

      while (1) {
         printf("\nEnter number 1..%d or 0 to exit: ", ap_list_size);
         scanf("%2d", &select);
         fflush(stdin);
         if (select >= 0 && select <= ap_list_size) {
            break;
         }
      }
      if (select == 0) {
        break;
      }
      select--;

      printf("Enter password for %s: ", ap_list[select].ssid);
      scanf("%20s", passwd);
      fflush(stdin);

      printf("Connecting to Network %s: ", ap_list[select].ssid);
      res = connect_network(ap_list[select].ssid, passwd);
      if (res != RESULT_OK) {
         printf("\nTry again Y|n?", ap_list[select].ssid);
         scanf("%c",&yn);
         fflush(stdin);
         if (yn == 'N' || yn == 'n') {
            break;
         }
      } else {
         break;
      }
   }

   free(passwd);
}

/*
  Get info about AP with which communication is established
*/
void get_current_ap(void)
{
   char found, *ssid;
   ssid = (char *)malloc(128);
   if (ssid != NULL) {
#ifdef DEBUG
      printf("Get WiFi Network");
#endif
	   found = esp_check_conn_ap(ssid, 128);
      if (found == RESULT_CONNECTED) {
         printf("Connected to Wireles net: %s\n", ssid);
      } else if (found == RESULT_NOT_CONNECTED) {
         printf("Not connected to Wireles net!\n");
      } else {
         printf("CAP Unexpected error: %d\n", found);
         exit(1);
      }
      free(ssid);
   } else {
      printf("CAP Out of memory!");
      exit(1);
   }
}

char set_dhcp_mode(void)
{
#ifdef DEBUG
   printf("Set DHCP mode");
#endif
   return uart_tx_cmd(set_dhcp_cmd, rs_buff, RS_BUFF_SIZE, 1000);
}

char is_byte(char *byte)
{
   int i;
   i = atoi(byte);
   return (i >= 0 && i <= 255);
}

#define ADDR_LENGTH  16

/*
 Check string to looks like IP address
 Input:
    ip_str - pointer to string with IP
 Output:
    1 - look like IP
    0 - not
*/
char is_ip_addr(char *ip_str)
{
   char *p1, *p2, *p3, *ip;
   char res;
   res = 0;
   if (strlen(ip_str) < ADDR_LENGTH) {
      ip = malloc(ADDR_LENGTH);
      if (ip == NULL) {
         printf("IIP Out of memory!\n");
         exit(1);
      }
      strcpy(ip, ip_str);
      p1 = (char *) strchr(ip, '.');
      if (p1) {
         p2 = (char *) strchr(p1+1, '.');
         if (p2) {
            p3 = (char *) strchr(p2+1, '.');
            if (p3) {
               *p1 = 0;
               *p2 = 0;
               *p3 = 0;
               res = (is_byte(ip) && is_byte(p1+1) &&
                      is_byte(p2+1) && is_byte(p3+1));
            }
         }
      }
      free(ip);
   }
   return res;
}


void enter_ip(char *message, char *ip)
{
   char is_ip;
   do {
      printf("Enter %s: ", message);
      scanf("%15s", ip);
      fflush(stdin);
      is_ip = is_ip_addr(ip);
      if (!is_ip) {
         printf("Invalid address, not in nnn.nnn.nnn.nnn format! Where nnn=0..255\n");
      }
   } while (!is_ip);
}

char set_ip_config(char *ip, char *gateway, char *netmask)
{
   char res, *resp, *cmd;
   resp = (char *)malloc(512);
   cmd = (char *)malloc(256);
   if (resp == NULL || cmd == NULL) {
      printf("SIP Out of memory!\n");
      exit(1);
   }

   strset(cmd, 0);
   sprintf(cmd, "AT+CIPSTA=\"%s\",\"%s\",\"%s\"", ip, gateway, netmask);
   cmd = strcat(cmd, cmd_end);
#ifdef DEBUG
   printf("Set ip config");
#endif
   res = uart_tx_cmd(cmd, resp, 512, 2000);
   if (res != RESULT_OK) {

/*
      if (res == RESULT_FAIL) {
        bol = (char *) strstr(resp, "+CWJAP:");
        if (bol) {
        }
      }
*/
   }
   free(cmd);
   free(resp);
   return res;
}

/*
  Allow the user to select DHCP or manual IP-configuration
*/
void config_ip(void)
{
	char select, *ip, *netmask, *gateway;
   ip = malloc(ADDR_LENGTH);
   netmask = malloc(ADDR_LENGTH);
   gateway = malloc(ADDR_LENGTH);
   if (ip == NULL || netmask == NULL || gateway == NULL) {
      printf("CIP Out of memory!\n");
      exit(1);
   }
   strnset(ip,0,ADDR_LENGTH);
   strnset(netmask,0,ADDR_LENGTH);
   strnset(gateway,0,ADDR_LENGTH);

   printf("Select mode:\n1 - Automatic via DHCP\n");
   printf("2 - Specify IP-address, netmask and gateway\n0 - Exit.\n");

	while (1) {
      printf("\nEnter number 0..2: ");
      scanf("%1d", &select);
      fflush(stdin);
      if (select >= 0 && select < 3) {
         break;
      }
   }

   switch (select) {
      case 1 : {
            set_dhcp_mode();
            break;
         }
      case 2 : {
            enter_ip("IP-address", ip);
            enter_ip("Gateway", gateway);
            enter_ip("Net mask", netmask);
            set_ip_config(ip, gateway, netmask);
            break;
         }
   }
   free(ip);
   free(gateway);
   free(netmask);
}

/*
  Get state of DHCP
  Output:
     RESULT_ENABLED - if DHCP enabled
     RESULT_DISABLED - DHCP is disabled
*/
char get_dhcp_state(void) {
   char *bol, *eol, res;

#ifdef DEBUG
   printf("Get DHCP info");
#endif
   res = uart_tx_cmd(get_dhcp_cmd, rs_buff, RS_BUFF_SIZE, 1000);
   if (res == RESULT_OK) {
        bol = (char *) strstr(rs_buff, "+CWDHCP:");
        if (bol) {
           bol += 8;
           eol = (char *) strchr(bol, LF);
           if (eol) {
              *eol = 0;
              if (atoi(bol) & 0x02) {		// for new AT versions, it is changed to 0x01
                 printf("DHCP enabled\n");
                 res = RESULT_ENABLED;
              } else {
                 printf("DHCP disabled\n");
                 res = RESULT_DISABLED;
              }
           }
        } else {
           printf("No +CWDHCP!\n %s", rs_buff);
        }
   }
   return res;
}

/*
  Display configurtion of IP adresses
*/
void get_ip_config(void)
{
   char *bol, *eol, *name, res, ctr;

#ifdef DEBUG
   printf("Get IP config");
#endif
   res = uart_tx_cmd(get_ip_cmd, rs_buff, RS_BUFF_SIZE, 1000);
   bol = rs_buff;
   if (res == RESULT_OK) {
      ctr = 0;
      while (ctr++ < 4) {
         bol = (char *) strstr(bol, "+CIPSTA:");
         if (bol) {
            bol += 8;
            eol = (char *) strchr(bol, ':');
            if (eol) {
               *eol = 0;
               name = bol;
               bol = eol+1;
               eol = (char *) strchr(bol, LF);
               if (eol) {
                  *eol = 0;
                  printf("%s: %s\n", name, bol);
               }
               bol = eol+1;
            }
         } else {
           break;
         }
      }
   }
}

/*
  Display currenf Info, configured in ESP
*/
void display_info(void)
{
   printf("\n--- Current info ---\n");
   get_current_ap();
   get_dhcp_state();
   get_ip_config();
   printf("\n--------------------\n");
}

/*
  --------------------------------------------------------------------------
*/
void main()
{
	char found;

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

   while (1) {
      switch(select_main_menu()) {
         case 1: {
            select_network();
            break;
         }
         case 2: {
            config_ip();
            break;
         }
         case 3: {
            display_info();
            break;
         }
         default: {
            printf("Bye!\n");
            exit(0);
         }
    	}
   }

}