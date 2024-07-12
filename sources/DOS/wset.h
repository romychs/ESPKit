/*
====================================================
 Setup program for Sprinter-WiFi ISA Card
 Author: Roman A. Boykov
 License: BSD 3-Clause
====================================================
*/

#ifndef __WSET_H
#define __WSET_H

#define MSG_START "Setup for Sprinter WiFi Card (ESP8266)\nv1.0.0 by Romych (Boykov Roman)\n\n",0
#define MSG_NOT_FOUND "No Sprinter WiFi card found!\n"
#define MSG_FOUND "Sprinter WiFi card found at slot: %d\n"

#define RS_BUFF_SIZE 4098
#define AP_LIST_SIZE 20

struct ap_info {
   char ecn;
   char* ssid;
   int  rssi;
};

#endif
