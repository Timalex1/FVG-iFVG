#pragma once

#include "Common.mqh"

class CFVGDetector
  {
private:
   ENUM_TIMEFRAMES   m_tf;
   int               m_max_back_bars;
   bool              m_skip_initial_scan;
   datetime          m_last_scanned_time;
   CIdGenerator     *m_id_gen;

   bool              IsBullishFVG(const MqlRates &c1,const MqlRates &c2,const MqlRates &c3) const
     {
      return (c1.high < c3.low && c2.close > c2.open);
     }

   bool              IsBearishFVG(const MqlRates &c1,const MqlRates &c2,const MqlRates &c3) const
     {
      return (c1.low > c3.high && c2.close < c2.open);
     }

public:
                     CFVGDetector(void)
                       : m_tf(PERIOD_H4),
                         m_max_back_bars(0),
                         m_skip_initial_scan(false),
                         m_last_scanned_time((datetime)-1),
                         m_id_gen(NULL)
                     {}

   void              Init(ENUM_TIMEFRAMES tf,int max_back_bars,CIdGenerator *id_gen)
     {
      m_tf=tf;
      m_max_back_bars=max_back_bars;
      m_id_gen=id_gen;
      m_skip_initial_scan=(max_back_bars==0);
      m_last_scanned_time=(datetime)-1;
     }

   bool              ScanForNewZones(FVGZone &out_zone)
     {
      int bars=iBars(_Symbol,m_tf);
      if(bars<4)
         return false;

      if(m_skip_initial_scan && m_last_scanned_time==(datetime)-1)
        {
         datetime latest_closed=iTime(_Symbol,m_tf,1);
         m_last_scanned_time=latest_closed;
         return false;
        }

      int start_shift=3;
      if(m_last_scanned_time!=(datetime)-1)
        {
         int shift=iBarShift(_Symbol,m_tf,m_last_scanned_time,true);
         if(shift>0)
            start_shift=shift+1;
        }

      int end_shift=3;
      if(m_max_back_bars>0)
         end_shift=MathMin(bars-3,m_max_back_bars+2);

      MqlRates rates[];
      int copied=CopyRates(_Symbol,m_tf,0,end_shift+3,rates);
      if(copied<end_shift+3)
         return false;

      for(int i=start_shift; i<=end_shift; i++)
        {
         MqlRates c1=rates[i+2];
         MqlRates c2=rates[i+1];
         MqlRates c3=rates[i];
         if(IsBullishFVG(c1,c2,c3))
           {
            out_zone.id=m_id_gen.Next();
            out_zone.type=ZONE_BULLISH;
            out_zone.state=ZONE_ACTIVE;
            out_zone.start_time=c3.time;
            out_zone.end_time=TimeCurrent();
            out_zone.high=c3.low;
            out_zone.low=c1.high;
            out_zone.is_ifvg=false;
            out_zone.stalking=false;
            out_zone.traded=false;
            m_last_scanned_time=c3.time;
            return true;
           }
         if(IsBearishFVG(c1,c2,c3))
           {
            out_zone.id=m_id_gen.Next();
            out_zone.type=ZONE_BEARISH;
            out_zone.state=ZONE_ACTIVE;
            out_zone.start_time=c3.time;
            out_zone.end_time=TimeCurrent();
            out_zone.high=c1.low;
            out_zone.low=c3.high;
            out_zone.is_ifvg=false;
            out_zone.stalking=false;
            out_zone.traded=false;
            m_last_scanned_time=c3.time;
            return true;
           }
         m_last_scanned_time=c3.time;
        }

      return false;
     }

   void              CheckFlip(FVGZone &zone,double close_price)
     {
      if(zone.state==ZONE_INVALIDATED)
         return;

      if(zone.type==ZONE_BULLISH && close_price<zone.low)
        {
         zone.type=ZONE_BEARISH;
         zone.is_ifvg=true;
         zone.state=ZONE_ACTIVE;
        }
      else if(zone.type==ZONE_BEARISH && close_price>zone.high)
        {
         zone.type=ZONE_BULLISH;
         zone.is_ifvg=true;
         zone.state=ZONE_ACTIVE;
        }
     }
  };
