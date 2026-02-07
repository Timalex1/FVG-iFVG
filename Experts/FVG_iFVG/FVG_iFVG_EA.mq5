#property strict
#property version   "1.00"
#property description "FVG/iFVG Strategy EA"

#include "Common.mqh"
#include "CFVGDetector.mqh"
#include "CVisualizer.mqh"
#include "CStalkingEngine.mqh"
#include "CTradeManager.mqh"
#include "CDashboard.mqh"

input ENUM_TIMEFRAMES InpHigherTimeframe = PERIOD_H4;
input int             InpMaxBackBars = 0;
input int             InpKeepZones = 8;
input bool            InpIgnoreMitigated = true;
input int             InpExtendSeconds = 3600;
input ENUM_TIMEFRAMES InpStalkingTimeframe = PERIOD_M15;
input ENUM_ENTRY_TYPE InpEntryType = ENTRY_IMMEDIATE;
input double          InpRiskPercent = 1.0;
input double          InpTP1 = 100.0;
input double          InpTP2 = 200.0;
input double          InpTP3 = 300.0;
input double          InpTP4 = 400.0;
input double          InpTP5 = 500.0;
input double          InpPartialClosePercent = 20.0;

CFVGDetector          g_detector;
CVisualizer           g_visualizer;
CStalkingEngine       g_stalking;
CTradeManager         g_trade_manager;
CDashboard            g_dashboard;
CIdGenerator          g_id_gen;

FVGZone               g_zones[64];
int                   g_zone_total=0;

int OnInit(void)
  {
   g_detector.Init(InpHigherTimeframe,InpMaxBackBars,&g_id_gen);
   g_visualizer.Init(InpKeepZones,InpExtendSeconds);
   g_stalking.Init(InpStalkingTimeframe,3);
   g_trade_manager.Init(InpRiskPercent,InpTP1,InpTP2,InpTP3,InpTP4,InpTP5,InpPartialClosePercent);
   g_dashboard.Init("FVG_Dash_");
   g_dashboard.Draw();
   return INIT_SUCCEEDED;
  }

void OnTick(void)
  {
   FVGZone new_zone;
   if(g_detector.ScanForNewZones(new_zone))
     {
      if(g_zone_total<64)
        g_zones[g_zone_total++]=new_zone;
     }

   double close_htf=iClose(_Symbol,InpHigherTimeframe,1);
   for(int i=0; i<g_zone_total; i++)
     {
      g_detector.CheckFlip(g_zones[i],close_htf);
      double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
      double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);

      bool stalking=g_stalking.UpdateStalking(g_zones[i],bid,ask);
      if(stalking && g_zones[i].state==ZONE_TESTED)
        {
         double trigger_price=0.0;
         if(g_stalking.CheckChoCh(g_zones[i],InpEntryType,trigger_price))
           {
            if(g_trade_manager.PlaceTrade(g_zones[i],InpEntryType,trigger_price))
              {
               g_zones[i].traded=true;
               g_zones[i].state=ZONE_TRADED;
              }
           }
        }

      if(InpIgnoreMitigated)
        {
         double mid=(g_zones[i].high+g_zones[i].low)/2.0;
         if((bid<=mid && bid>=g_zones[i].low) || (bid>=mid && bid<=g_zones[i].high))
           {
            g_zones[i].state=ZONE_HIDDEN;
            g_visualizer.HideZone(g_zones[i]);
           }
        }

      if(g_zones[i].state!=ZONE_HIDDEN)
         g_visualizer.DrawZone(g_zones[i]);
     }

   g_visualizer.EnforceLimit(g_zones,g_zone_total);
   g_visualizer.Sweep(g_zones,g_zone_total);
   g_trade_manager.ManagePositions();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   g_dashboard.OnChartEvent(id,lparam,dparam,sparam);
  }
