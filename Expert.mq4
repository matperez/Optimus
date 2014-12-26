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

input   int     TakeProfit = 50;
input   double  Lot = 0.01;
input   int     Deviation = 10;

CTrade *pTrade;
CSymbolInfo *pSymbol;

/*
TODO:
    1. ����� ��� �������� ������ �� �������
    2. �������� �������� � ��� ������ �������� �������
    3. ����� ��� ������������� ������ �������� ������� �� ����� �� ������ ������
    


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
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol);
    Print("��������� ������: ", pSymbol.Name(), " ����������� ���: ", pSymbol.LotsMin(), " �����: ", pSymbol.Point());
    
    COrderInfo order;
    int total = OrdersTotal();
    
    if (total == 0) {
        Print("��� �������");
        
    } else {
        Print("�������� �������: ", total);
        int lastPos;
        for (int pos = 0; pos < total; pos++) {
            if (order.SelectByIndex(pos)) {
                lastPos = pos;
                Print("��� ������: ", order.OrderType());
            }
        }
        COrderInfo lastOrder;
        lastOrder.SelectByIndex(lastPos);
    }

//    pTrade = new CTrade();
//    pTrade.SetLogLevel(LOG_LEVEL_ALL);
//    pTrade.SetDeviation(Deviation);
    
//    pTrade.Buy(Lot, _Symbol, 0.0, 2*TakeProfit, TakeProfit);
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
    delete pSymbol;
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
