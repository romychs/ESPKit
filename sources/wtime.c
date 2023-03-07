/*
=====================================================
 NTP Time program for Sprinter-WiFi ISA Card
 Author: Roman A. Boykov
 License: BSD 3-Clause
=====================================================
*/

#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include "esplib.h"
#include "wtime.h"

char* set_speed = "AT+UART_CUR=115200,8,1,0,3\r\n\0";
char* echo_off = "ATE0\r\n\0";
char* get_sntp_cmd = "AT+CIPSNTPCFG?\r\n\0";
char* set_sntp_cmd = "AT+CIPSNTPCFG=1,%d\r\n\0";
char* get_sntp_time_cmd = "AT+CIPSNTPTIME?\r\n\0";

char* cmd_end = "\r\n\0";
char  rs_buff[RS_BUFF_SIZE];

char* m_name[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };

/*
  Get time shift from TZ environment variable
  Output:
     -11..13 - time shift from GMT
*/
char get_timezone(void)
{
   char *tze, *gmtp, ss, off;
   tze = getenv("TZ");
   if (tze == NULL) {
      tze = getenv("tz");
   }
   if (tze == NULL) {
      printf("TZ environment variable not found, default value GMT+3\n");
      return 3;
   } else {
      gmtp = (char *) strstr(tze, "GMT");
      if (gmtp == tze) {
         ss = *(tze+3); // sign symbol
         if (ss == '+' || ss == '-') {
            off = atoi(tze+4);
            if (off>-12 && off<14) {
               return off;
            }
         }
      }
      printf("TZ environment variable will have format GMT+nn or GMT-nn, nn=[-11..13]\nUsed default value, GMT+3\n");
      return 3;
   }

}



/*
  Get time via SNTP protocol
*/
char get_sntp_time(char *time_str)
{
   char *bol, *eol, res;

#ifdef DEBUG
   printf("Get SNTP time");
#endif
   uart_empty_rs();
   res = uart_tx_cmd(get_sntp_time_cmd, rs_buff, RS_BUFF_SIZE, 1000);
   if (res == RESULT_OK) {
      bol = (char *) strstr(rs_buff, "+CIPSNTPTIME:");
      if (bol) {
         bol += 13;
         eol = (char *) strchr(bol, LF);
         if (eol) {
           *eol = 0;
           //printf("Net time %s\n", bol);
           strcpy(time_str, bol);
         }
      } else {
         printf("No +CIPSNTPTIME!\n %s", rs_buff);
      }
   }
   return res;
}



/*
  Get SNTP configuration state
  Output:
     RESULT_ENABLED - if SNTP enabled and configured
     RESULT_DISABLED - SNTP is disabled
*/
char get_sntp_state(void)
{
   char *bol, *eol, *comma, res, en, offset;
   uart_empty_rs();
#ifdef DEBUG
   printf("Get SNTP info");
#endif
   res = uart_tx_cmd(get_sntp_cmd, rs_buff, RS_BUFF_SIZE, 1000);
   if (res == RESULT_OK) {
        bol = (char *) strstr(rs_buff, "+CIPSNTPCFG:");
        if (bol) {
           bol += 12;
           en = *bol;
           if (en == '0') {
              res = RESULT_DISABLED;
#ifdef DEBUG
              printf("SNTP Disabled\n");
#endif
           }
           if (en == '1') {
              res = RESULT_ENABLED;
#ifdef DEBUG
              printf("SNTP Enabled, TZ ");
              comma = (char *) strchr(bol, ',');
              if (comma) {
                 bol = comma+1;
                 eol = (char *) strchr(bol, ',');
                 if (eol) {
                    *eol = 0;
                    offset = atoi(bol);
                    if (offset > 0) {
                       printf("UTC+%d\n", offset);
                    } else {
                       printf("UTC%d\n", offset);
                    }
                 }
              }
#endif
           }
        } else {
           printf("No +CIPSNTPCFG!\n %s", rs_buff);
        }
   }
   return res;
}

char enable_sntp(void)
{
   char  *cmd_buff, res, time_shift;
   time_shift = 3;
   cmd_buff = malloc(256);
   if (cmd_buff == NULL) {
      printf("ES Out of memory!\n");
      exit(1);
   }

   time_shift = get_timezone();
   // turn SNTP On

   sprintf(cmd_buff, set_sntp_cmd, time_shift);
#ifdef DEBUG
   printf("Enable SNTP");
#endif
   uart_empty_rs();
   res = uart_tx_cmd(cmd_buff, NULL, 0, 100);
   free(cmd_buff);
   return res;
}

/*
  Init basic parameters of ESP
*/
void init_esp(void) {
   uart_empty_rs();
#ifdef DEBUG
   printf("Echo off");
#endif
	uart_tx_cmd(echo_off, NULL, 0, 100);
#ifdef DEBUG
   printf("Setup uart");
#endif
	uart_tx_cmd(set_speed, NULL, 0, 500);
}

/*
  Parse text string rsponse from ESP to structure
  Input:
     time_str - pointer to string like 'Mon Mar 06 10:11:12 2023'
     ti - pointer to result
  Output:
     ti - filled winh parsed values
     RESULT_OK - if no errors,
     RESULT_ERROR - can not parse, illegal format
*/
char parse_time(char *time_str, struct time_info *ti)
{
   char *p[4], cnt, *ptr, mon;
   ptr = time_str;
   cnt = 0;
   // Find all spaces
   while (*ptr != 0 && cnt<4) {
        if (*ptr == ' ') {
           p[cnt++] = ptr+1;
           *ptr = 0;
        }
        ptr++;
   }
   // will be 4 space separators
   if (cnt != 4) {
      printf("Illegal time format!\n");
      return 0;
   }
   // convert month name to number
   mon = 0;
   for (mon=0; mon<12; mon++) {
      if (strcmp(p[0],m_name[mon]) == 0) {
         break;
      }
   }
   if (mon == 12) {
      printf("Month not found: %s\n", p[0]);
      return RESULT_ERROR;
   }
   // erase ':' in time
   *(p[2]+2) = 0;
   *(p[2]+5) = 0;
   // fill result
   ti->mon = mon;
	ti->day = atoi(p[1]);
   ti->year = atoi(p[3]);
   ti->h = atoi(p[2]);
   ti->m = atoi(p[2]+3);
   ti->s = atoi(p[2]+6);
   return RESULT_OK;
}



/*
  --------------------------------------------------------------------------
*/
void main()
{
	char res, sntp_status, *time_str, delay;
   struct time_info ti;


	clrscr();

	printf(MSG_START);
	res = isa_init();
	if (!res) {
		printf(MSG_NOT_FOUND);
		exit(EXIT_FAILURE);
	}
	printf(MSG_FOUND, isa_get_slot());
	uart_init();
   esp_reset(0);
   init_esp();


   printf("Time shift: %d\n", get_timezone());



   sntp_status = get_sntp_state();

   if (sntp_status == RESULT_DISABLED) {
      res = enable_sntp();
      if (res != RESULT_OK) {
         printf("Failed to enabable SNTP protocol! Error: %d;\n", res);
         exit(1);
      }
      sntp_status = get_sntp_state();
      printf("Wait for apply changes");
      for (delay = 0; delay<10; delay++) {
         printf("."); util_delay(500);
      }
      printf("\n");
   }

   if (sntp_status == RESULT_ENABLED) {
      time_str = malloc(1024);
      if (time_str == NULL) {
         printf("TS Out of memory!\n");
         exit(2);
      }

      res = get_sntp_time(time_str);
      if (res == RESULT_OK) {
         printf("Net time %s\n", time_str);
		} else {
         printf("Failed to get time! Error: %d;\n", res);
      }

      if ( parse_time(time_str, &ti) == RESULT_OK ) {
         printf("Day: %d; Year: %d", ti.day, ti.year);
		   printf(" Time %d:%d:%d\n", ti.h, ti.m, ti.s);
      } else {
         printf("Error parsing date-time string: '%s'!\n", time_str);
      }
      free(time_str);
   }

}