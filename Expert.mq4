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
#include <Arrays\List.mqh>

input   int     TakeProfit = 50;
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
    MqlTradeResult result;
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol);

    pTrade = new CTrade();
    pTrade.SetLogLevel(LOG_LEVEL_ALL);
    pTrade.SetDeviation(Deviation);
    
    Print("��������� ������: ", pSymbol.Name(), " ����������� ���: ", pSymbol.LotsMin(), " �����: ", pSymbol.Point());
    
    COrderInfo order;
    int total = OrdersTotal();
    
    if (total == 0) {
        Print("��� �������");
        
    } else {
        Print("�������� �������: ", total);
        for (int pos = 0; pos < total; pos++) {
            if (order.SelectByIndex(pos)) {
                Print("��� ������: ", order.OrderType());
            }
        }
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
        if (!pTrade.SellStop(Lot, Bid-TakeProfit*Point, NULL, Bid+TakeProfit*Point, Bid-StopLoss*Point)) {
            // ��������� ������
        }
        if (!pTrade.BuyStop(Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point,Ask+StopLoss*Point)) {
            // ��������� ������
        }
     }   
  }
//+------------------------------------------------------------------+
