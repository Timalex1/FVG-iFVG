#pragma once

#include "Common.mqh"

class CDashboard
  {
private:
   string            m_prefix;
   int               m_active_tab;

   string            TabName(int tab) const
     {
      if(tab==0) return "STATUS";
      if(tab==1) return "SETTINGS";
      return "STATS";
     }

   string            ObjName(const string &suffix) const
     {
      return m_prefix+suffix;
     }

   void              CreateButton(const string &name,int x,int y,const string &text,bool active)
     {
      if(!ObjectFind(0,name))
         ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,80);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
      ObjectSetInteger(0,name,OBJPROP_COLOR,active ? clrWhite : clrSilver);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,active ? clrDodgerBlue : clrGray);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
     }

   void              CreateLabel(const string &name,int x,int y,const string &text)
     {
      if(!ObjectFind(0,name))
         ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
     }

public:
                     CDashboard(void) : m_prefix("FVG_Dash_"), m_active_tab(0) {}

   void              Init(const string &prefix)
     {
      m_prefix=prefix;
     }

   void              Draw(void)
     {
      CreateButton(ObjName("TabStatus"),10,10,TabName(0),m_active_tab==0);
      CreateButton(ObjName("TabSettings"),95,10,TabName(1),m_active_tab==1);
      CreateButton(ObjName("TabStats"),180,10,TabName(2),m_active_tab==2);

      if(m_active_tab==0)
         CreateLabel(ObjName("Content"),10,40,"Active Zones / Last Action");
      else if(m_active_tab==1)
         CreateLabel(ObjName("Content"),10,40,"Key Parameters");
      else
         CreateLabel(ObjName("Content"),10,40,"P/L Summary");
     }

   void              OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
     {
      if(id!=CHARTEVENT_OBJECT_CLICK)
         return;
      if(sparam==ObjName("TabStatus"))
         m_active_tab=0;
      else if(sparam==ObjName("TabSettings"))
         m_active_tab=1;
      else if(sparam==ObjName("TabStats"))
         m_active_tab=2;
      Draw();
     }
  };
