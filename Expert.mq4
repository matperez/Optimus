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
CList* pOrderList;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // ������ �������
    pOrderList = new CList();
    
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
                Print("��� ������: ", order.GetType());
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
    delete pOrderList;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    UpdateList();
    COrderInfo* order;     

    if (pOrderList.Total() == 0) {
        if (!pTrade.SellStop(Lot, Bid-TakeProfit*Point, NULL, Bid+TakeProfit*Point, Bid-StopLoss*Point)) {
            Print("������ ����������� ������: ", pTrade.GetMessage());
        }
        if (!pTrade.BuyStop(Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point,Ask+StopLoss*Point)) {
            Print("������ ����������� ������: ", pTrade.GetMessage());
        }
    } else {
        Print("����� ������� � �������: ", pOrderList.Total());
        
        for(int i = 0; i < pOrderList.Total(); i++) {
            order = pOrderList.GetNodeAtIndex(i);
            Print("����� ����: ", order.GetType(), " ���� ��������: ", order.GetOpenPrice(), " ��������: ", order.IsPending()?"���":"��");
        }
    }
}
  
//+------------------------------------------------------------------+
//| Update orders queue                                              |
//+------------------------------------------------------------------+
void UpdateList() 
{
    COrderInfo* order;
    pOrderList.Clear();
    int total = OrdersTotal();
    for (int pos = 0; pos < total; pos++) {
        order = new COrderInfo();
        if (order.SelectByIndex(pos)) {
            pOrderList.Add(order);
        }
    }
}
//+------------------------------------------------------------------+
