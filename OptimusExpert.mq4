//+------------------------------------------------------------------+
//|                                                      Optimus.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include "Optimus.mqh";

input   int     TakeProfit = 350;
//input   int     StopLoss = 700;
input   double  M = 2; // отношение SL/TP
input   double  Lot = 0.01;
input   int     Deviation = 10;
input   int     Spred = 0;
input   int     Delta = 50;

Optimus* pExpert;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    pExpert = new Optimus(TakeProfit, M, _Symbol);
    pExpert.SetDelta(Delta);
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
    delete pExpert;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    pExpert.OnTick();
}


