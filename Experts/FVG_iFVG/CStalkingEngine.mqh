#pragma once

#include "Common.mqh"

class CStalkingEngine
  {
private:
   ENUM_TIMEFRAMES   m_tf;
   int               m_swing_lookback;

   bool              IsSwingHigh(const MqlRates rates[],int index,int lookback) const
     {
      double high=rates[index].high;
      for(int i=1; i<=lookback; i++)
        {
         if(rates[index-i].high>=high || rates[index+i].high>=high)
            return false;
        }
      return true;
     }

   bool              IsSwingLow(const MqlRates rates[],int index,int lookback) const
     {
      double low=rates[index].low;
      for(int i=1; i<=lookback; i++)
        {
         if(rates[index-i].low<=low || rates[index+i].low<=low)
            return false;
        }
      return true;
     }

public:
                     CStalkingEngine(void) : m_tf(PERIOD_M15), m_swing_lookback(3) {}

   void              Init(ENUM_TIMEFRAMES tf,int swing_lookback)
     {
      m_tf=tf;
      m_swing_lookback=swing_lookback;
     }

   bool              UpdateStalking(FVGZone &zone,double bid,double ask)
     {
      if(zone.state==ZONE_INVALIDATED || zone.traded)
         return false;

      bool in_zone=(bid<=zone.high && bid>=zone.low) || (ask<=zone.high && ask>=zone.low);
      if(in_zone)
        {
         zone.state=ZONE_TESTED;
         zone.stalking=true;
         return true;
        }

      if(zone.stalking)
         return true;

      return false;
     }

   bool              CheckChoCh(const FVGZone &zone,ENUM_ENTRY_TYPE entry_type,double &trigger_price)
     {
      int bars=iBars(_Symbol,m_tf);
      if(bars<10)
         return false;

      int needed=m_swing_lookback*2+5;
      MqlRates rates[];
      int copied=CopyRates(_Symbol,m_tf,1,needed,rates);
      if(copied<needed)
         return false;

      double last_swing_high=0.0;
      double last_swing_low=0.0;
      for(int i=m_swing_lookback+1; i<copied-m_swing_lookback; i++)
        {
         if(IsSwingHigh(rates,i,m_swing_lookback))
            last_swing_high=rates[i].high;
         if(IsSwingLow(rates,i,m_swing_lookback))
            last_swing_low=rates[i].low;
        }

      double recent_close=rates[0].close;
      if(zone.type==ZONE_BULLISH && last_swing_high>0.0 && recent_close>last_swing_high)
        {
         trigger_price=entry_type==ENTRY_RETEST ? (last_swing_high+last_swing_low)/2.0 : recent_close;
         return true;
        }
      if(zone.type==ZONE_BEARISH && last_swing_low>0.0 && recent_close<last_swing_low)
        {
         trigger_price=entry_type==ENTRY_RETEST ? (last_swing_high+last_swing_low)/2.0 : recent_close;
         return true;
        }

      return false;
     }
  };
