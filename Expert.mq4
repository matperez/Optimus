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
    COrderInfo* order1;
    COrderInfo* order2;     
    
    int total = pOrderList.Total();
    
    Print("����� ������� � �������: ", total);

    if (total == 0) {
        OpenOppositePosition();
    } else if (total == 2) {
        ListOrders(pOrderList);
        order1 = pOrderList.GetNodeAtIndex(0);
        order2 = pOrderList.GetNodeAtIndex(1);
        if (order1.IsPending() && order2.IsPending()) {
            Print("�� ���� ����� �� ����������");
        } else if (order1.IsPending()) {
            ModifyOpposite(order1);
        } else {
            ModifyOpposite(order2);
        }
    } else {
        
    }
}
//+------------------------------------------------------------------+
//| List active orders                                               |
//+------------------------------------------------------------------+
void ModifyOpposite(COrderInfo* order)
{
    if (order.GetType() == OP_BUYSTOP) {
        pTrade.BuyStop(Lot, Ask+TakeProfit*Point, NULL, Ask-StopLoss*Point, Ask+StopLoss*Point);   
    } else {
        pTrade.SellStop(Lot, Bid-TakeProfit*Point, NULL, Bid+StopLoss*Point, Bid-StopLoss*Point);   
    }
    OrderDelete(order.GetTicket(), Orange);
}
//+------------------------------------------------------------------+
//| List active orders                                               |
//+------------------------------------------------------------------+
void ListOrders(CList* pOrderList) 
{
    COrderInfo* order;     
    for(int i = 0; i < pOrderList.Total(); i++) {
        order = pOrderList.GetNodeAtIndex(i);
        Print("����� ����: ", order.GetType(), " ���� ��������: ", order.GetOpenPrice(), " ��������: ", order.IsPending()?"���":"��");
    }
}

//+------------------------------------------------------------------+
//| Open opposite positions on expert initialization                 |
//+------------------------------------------------------------------+
void OpenOppositePosition() 
{
        if (!pTrade.SellStop(Lot, Bid-TakeProfit*Point, NULL, Bid+TakeProfit*Point, Bid-StopLoss*Point)) {
            Print("������ ����������� ������: ", pTrade.GetMessage());
        }
        if (!pTrade.BuyStop(Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point,Ask+StopLoss*Point)) {
            Print("������ ����������� ������: ", pTrade.GetMessage());
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
