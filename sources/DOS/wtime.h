/*
====================================================
 NTP Time program for Sprinter-WiFi ISA Card
 Header file
 Author: Roman A. Boykov
 License: BSD 3-Clause
====================================================
*/

#ifndef __WTIME_H
#define __WTIME_H

#define MSG_START "NTP Time for Sprinter WiFi Card (ESP8266)\nv1.0.0 by Romych (Boykov Roman)\n\n",0
#define MSG_NOT_FOUND "No Sprinter WiFi card found!\n"
#define MSG_FOUND "Sprinter WiFi card found at slot: %d\n"

#define RS_BUFF_SIZE 1024

struct time_info {
   char mon;
   char day;
   char h;
   char m;
   char s;
   int  year;
};

#endif
