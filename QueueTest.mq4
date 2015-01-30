//+------------------------------------------------------------------+
//|                                                    QueueTest.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Trade.mqh"
#include "SymbolInfo.mqh"
#include "OrderInfo.mqh"
#include "OrderQueue.mqh"
#include <Arrays\List.mqh>

COrderQueue* queue;
CTrade* trade;

int ticks = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    queue = new COrderQueue();

    trade = new CTrade();
    trade.SetLogLevel(LOG_LEVEL_ERRORS);    

    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    queue.Update();
    ticks++;
    Print("Новый тик: "+ticks);
    Print("Количество ордеров: "+queue.GetList().Total());
    if (ticks % 3 == 0) {
        trade.Buy(0.01, Ask, NULL, 0.0, 0.0);
    }
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   delete queue;
   delete trade;
}
//+------------------------------------------------------------------+
