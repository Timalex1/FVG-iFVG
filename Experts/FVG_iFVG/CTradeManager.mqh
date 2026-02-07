#pragma once

#include "Common.mqh"

class CTradeManager
  {
private:
   CTrade            m_trade;
   double            m_risk_percent;
   double            m_tp_levels[5];
   double            m_partial_close_percent;

   double            CalculateLot(double stop_distance_points)
     {
      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amount=balance*(m_risk_percent/100.0);
      double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      if(tick_value<=0.0 || tick_size<=0.0 || stop_distance_points<=0.0)
         return 0.01;
      double value_per_point=tick_value/tick_size;
      double lots=risk_amount/(stop_distance_points*value_per_point);
      double min_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
      double max_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
      double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
      lots=MathMax(min_lot,MathMin(max_lot,MathFloor(lots/step)*step));
      return lots;
     }

public:
                     CTradeManager(void)
                       : m_risk_percent(1.0),
                         m_partial_close_percent(20.0)
                     {
                      ArrayInitialize(m_tp_levels,0.0);
                     }

   void              Init(double risk_percent,double tp1,double tp2,double tp3,double tp4,double tp5,double partial_close_percent)
     {
      m_risk_percent=risk_percent;
      m_tp_levels[0]=tp1;
      m_tp_levels[1]=tp2;
      m_tp_levels[2]=tp3;
      m_tp_levels[3]=tp4;
      m_tp_levels[4]=tp5;
      m_partial_close_percent=partial_close_percent;
     }

   bool              PlaceTrade(const FVGZone &zone,ENUM_ENTRY_TYPE entry_type,double trigger_price)
     {
      double stop_loss=zone.type==ZONE_BULLISH ? zone.low : zone.high;
      double stop_distance=MathAbs(trigger_price-stop_loss);
      double lots=CalculateLot(stop_distance/_Point);
      if(lots<=0.0)
         return false;

      if(zone.type==ZONE_BULLISH)
         return m_trade.Buy(lots,_Symbol,trigger_price,stop_loss,0.0,"FVG Entry");
      return m_trade.Sell(lots,_Symbol,trigger_price,stop_loss,0.0,"FVG Entry");
     }

   void              ManagePositions(void)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {
         ulong ticket=PositionGetTicket(i);
         if(!PositionSelectByTicket(ticket))
            continue;
         double entry=PositionGetDouble(POSITION_PRICE_OPEN);
         double current=PositionGetDouble(POSITION_PRICE_CURRENT);
         long type=PositionGetInteger(POSITION_TYPE);

         double tp1=m_tp_levels[0];
         if(tp1>0.0)
           {
            double target=type==POSITION_TYPE_BUY ? entry+tp1*_Point : entry-tp1*_Point;
            if((type==POSITION_TYPE_BUY && current>=target) || (type==POSITION_TYPE_SELL && current<=target))
              {
               double stop=entry;
               m_trade.PositionModify(ticket,stop,0.0);
              }
           }
        }
     }
  };
