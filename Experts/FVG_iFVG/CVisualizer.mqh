#pragma once

#include "Common.mqh"

class CVisualizer
  {
private:
   int               m_keep_zones;
   int               m_extend_seconds;

   string            ZoneName(const FVGZone &zone) const
     {
      return StringFormat("FVG_%d",zone.id);
     }

   color             ZoneColor(const FVGZone &zone) const
     {
      if(zone.type==ZONE_BULLISH)
         return zone.is_ifvg ? clrTomato : clrLimeGreen;
      return zone.is_ifvg ? clrDeepSkyBlue : clrRed;
     }

   ENUM_LINE_STYLE   ZoneStyle(const FVGZone &zone) const
     {
      return zone.is_ifvg ? STYLE_DASH : STYLE_SOLID;
     }

public:
                     CVisualizer(void) : m_keep_zones(8), m_extend_seconds(3600) {}

   void              Init(int keep_zones,int extend_seconds)
     {
      m_keep_zones=keep_zones;
      m_extend_seconds=extend_seconds;
     }

   void              DrawZone(const FVGZone &zone)
     {
      string name=ZoneName(zone);
      if(!ObjectFind(0,name))
        {
         ObjectCreate(0,name,OBJ_RECTANGLE,0,zone.start_time,zone.high,zone.end_time,zone.low);
        }
      ObjectSetInteger(0,name,OBJPROP_COLOR,ZoneColor(zone));
      ObjectSetInteger(0,name,OBJPROP_STYLE,ZoneStyle(zone));
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_FILL,true);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);

      datetime future=TimeCurrent()+m_extend_seconds;
      ObjectMove(0,name,0,zone.start_time,zone.high);
      ObjectMove(0,name,1,future,zone.low);
     }

   void              HideZone(const FVGZone &zone)
     {
      string name=ZoneName(zone);
      if(ObjectFind(0,name))
         ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }

   void              Sweep(const FVGZone &zones[],int total)
     {
      int total_objects=ObjectsTotal(0,-1,-1);
      for(int i=total_objects-1; i>=0; i--)
        {
         string name=ObjectName(0,i,-1,-1);
         if(StringFind(name,"FVG_")!=0)
            continue;
         bool found=false;
         for(int z=0; z<total; z++)
           {
            if(name==ZoneName(zones[z]))
              {
               found=true;
               break;
              }
           }
         if(!found)
            ObjectDelete(0,name);
        }
     }

   void              EnforceLimit(FVGZone &zones[],int &total)
     {
      if(total<=m_keep_zones)
         return;
      int remove_count=total-m_keep_zones;
      for(int i=0; i<remove_count; i++)
        {
         string name=ZoneName(zones[i]);
         ObjectDelete(0,name);
        }
      for(int j=remove_count; j<total; j++)
        zones[j-remove_count]=zones[j];
      total-=remove_count;
     }
  };
