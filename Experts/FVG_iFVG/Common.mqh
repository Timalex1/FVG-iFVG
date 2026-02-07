#pragma once

#include <Trade/Trade.mqh>

enum ENUM_ZONE_TYPE
  {
   ZONE_BULLISH = 0,
   ZONE_BEARISH = 1
  };

enum ENUM_ZONE_STATE
  {
   ZONE_ACTIVE = 0,
   ZONE_TESTED = 1,
   ZONE_TRADED = 2,
   ZONE_INVALIDATED = 3,
   ZONE_HIDDEN = 4
  };

enum ENUM_ENTRY_TYPE
  {
   ENTRY_IMMEDIATE = 0,
   ENTRY_RETEST = 1,
   ENTRY_SNIPER = 2
  };

typedef struct FVGZone
  {
   int               id;
   ENUM_ZONE_TYPE    type;
   ENUM_ZONE_STATE   state;
   datetime          start_time;
   datetime          end_time;
   double            high;
   double            low;
   bool              is_ifvg;
   bool              stalking;
   bool              traded;
  } FVGZone;

class CIdGenerator
  {
private:
   int m_next_id;

public:
                     CIdGenerator(void) : m_next_id(1) {}
   int               Next(void) { return m_next_id++; }
  };
