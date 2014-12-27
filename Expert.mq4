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

double Sigma = TakeProfit + 5;

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
    int total;     
    
    UpdateList();
    
    // ListOrders(pOrderList);

    total = pOrderList.Total();

    if (total == 0) {
        OpenOppositePositions();
    } else if(total == 1) {
        OpenTrendPosition(pOrderList.GetFirstNode());
    } else if (total == 2) {
        ModifyOppositePosition(pOrderList.GetNodeAtIndex(0), pOrderList.GetNodeAtIndex(1));
    } else {
        // ������ ���� �������
    }
}
//+------------------------------------------------------------------+
//| ��� ������ �������� ���� �����                                  |
//+------------------------------------------------------------------+
void ModifyOppositePosition(COrderInfo* order1, COrderInfo* order2)
{
    Print(__FUNCTION__, ": ", order1.GetType(), ", ", order2.GetType(),", ", order1.GetOpenPrice(),", ", order1.GetOpenPrice(), ", ", MathAbs(order1.GetOpenPrice() - order2.GetOpenPrice()), ", ", Sigma*Point);
    if (order1.GetType() == OP_SELLSTOP && order2.GetType() == OP_BUY && MathAbs(order1.GetOpenPrice() - order2.GetOpenPrice()) > Sigma*Point) {
        pTrade.SellStop(2*Lot, Bid-TakeProfit*Point, NULL, Bid+StopLoss*Point, Bid-StopLoss*Point);
        OrderDelete(order1.GetTicket(), Orange);
    } else if (order1.GetType() == OP_BUYSTOP && order2.GetType() == OP_SELL && MathAbs(order1.GetOpenPrice() - order2.GetOpenPrice()) > Sigma*Point) {
        pTrade.BuyStop(2*Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point, Ask+StopLoss*Point);
        OrderDelete(order1.GetTicket(), Orange);
    } else if (order1.GetType() == OP_BUY && order2.GetType() == OP_SELL) {
        pTrade.BuyStop(3*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit());
    } else if (order1.GetType() == OP_SELL && order2.GetType() == OP_BUY) {
        pTrade.SellStop(3*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit());
    }       
}
//+------------------------------------------------------------------+
//| ��������� ��������� ������� � ����������� �������� ��������      |
//+------------------------------------------------------------------+
void OpenTrendPosition(COrderInfo* order)
{
    Print(__FUNCTION__, ": ", order.GetType(), ", ", order.GetOpenPrice(), ", ", order.GetTakeProfit(), ", ", order.GetStopLoss());
    if (order.IsPending()) {
        if (order.GetType() == OP_BUYSTOP) {
            pTrade.Sell(Lot, Bid, NULL, Bid+StopLoss*Point, Bid-TakeProfit*Point);   
            pTrade.BuyStop(2*Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point, Ask+StopLoss*Point);   
        } else if(order.GetType() == OP_SELLSTOP) {
            pTrade.Buy(Lot, Ask, NULL, Ask+TakeProfit*Point, Ask-StopLoss*Point);
            pTrade.SellStop(2*Lot, Bid-TakeProfit*Point, NULL, Bid+TakeProfit*Point, Bid-StopLoss*Point);   
        }    
        OrderDelete(order.GetTicket(), Orange);
    } else {
        if (order.GetType() == OP_BUY) { // OP_BUY}
            pTrade.SellStop(2*Lot, order.GetOpenPrice()-TakeProfit*Point, NULL, order.GetOpenPrice()+StopLoss*Point, order.GetOpenPrice()-StopLoss*Point);   
        } else { // OP_SELL
            pTrade.BuyStop(2*Lot, order.GetOpenPrice()+TakeProfit*Point, NULL, order.GetOpenPrice()-StopLoss*Point, order.GetOpenPrice()+StopLoss*Point);   
        }
    }
}
//+------------------------------------------------------------------+
//| List active orders                                               |
//+------------------------------------------------------------------+
void ListOrders(CList* pOrderList) 
{
    COrderInfo* order;     
    Print("����� ������� � �������: ", pOrderList.Total());
    for(int i = 0; i < pOrderList.Total(); i++) {
        order = pOrderList.GetNodeAtIndex(i);
        Print("����� ����: ", order.GetType(), " ���� ��������: ", order.GetOpenPrice(), " ��������: ", order.IsPending()?"���":"��");
    }
}

//+------------------------------------------------------------------+
//| Open opposite positions on expert initialization                 |
//+------------------------------------------------------------------+
void OpenOppositePositions() 
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
