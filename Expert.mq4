//+------------------------------------------------------------------+
//|                                                      Optimus.mq4 |
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

input   int     TakeProfit = 10;
input   int     StopLoss = 100;
input   double  Lot = 0.01;
input   int     Deviation = 10;

CTrade *pTrade;
CSymbolInfo *pSymbol;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol);

    pTrade = new CTrade();
    pTrade.SetLogLevel(LOG_LEVEL_ALL);
    pTrade.SetDeviation(Deviation);

    Print("Выбранный символ: ", pSymbol.Name(), " Минимальный лот: ", pSymbol.LotsMin(), " Поинт: ", pSymbol.Point());
    
    COrderInfo order;
    int total = OrdersTotal();
    int lastPos;
    
    if (total == 0) {
        Print("Нет ордеров");
        
    } else {
        Print("Активных ордеров: ", total);
        for (int pos = 0; pos < total; pos++) {
            if (order.SelectByIndex(pos)) {
                lastPos = pos;
                Print("Тип ордера: ", order.OrderType());
            }
        }
        COrderInfo lastOrder;
        lastOrder.SelectByIndex(lastPos);
    }
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    delete pSymbol;
    delete pTrade;   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
     int total, ticket;
     
     total=OrdersTotal();
     if(total==0)
     {
        Alert("Минимальная дистанция установления стоп ордера", MarketInfo(Symbol(),MODE_STOPLEVEL));
        ticket=OrderSend(Symbol(),OP_SELLSTOP,Lot,Bid-TakeProfit*Point,Deviation,Bid+TakeProfit*Point, Bid-StopLoss*Point,"Optimus",141183,0,Green);
        ticket=OrderSend(Symbol(),OP_BUYSTOP,Lot,Ask+TakeProfit*Point,Deviation,Ask-TakeProfit*Point, Ask+StopLoss*Point,"Optimus",141183,0,Blue);
        
     }   
  }
//+------------------------------------------------------------------+
