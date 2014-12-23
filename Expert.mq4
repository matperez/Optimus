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

input   int     TakeProfit = 50;
input   double  Lot = 0.01;
input   int     Deviation = 10;

CTrade *pTrade;

/*
OnInit:
    double CurrentPrice = GetCurrentPrice()
    BuyMarket(TP: TakeProfit, SL: CurrentPrice-TakeProfit*2);
    SellStop(PRICE: CurrentPrice - TakeProfit, TP: CurrentPrice - TakeProfit*2)
    
    

OnTick:
    1. 


*/


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    pTrade = new CTrade();
    pTrade.SetLogLevel(LOG_LEVEL_ALL);
    pTrade.SetDeviation(Deviation);
    
    pTrade.Buy(Lot, _Symbol, 0.0, 2*TakeProfit, TakeProfit);
    pTrade.Sell(Lot, _Symbol, 0.0, TakeProfit*2, TakeProfit);
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
