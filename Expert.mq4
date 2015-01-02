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
input   int     StopLoss = 200;
input   double  Lot = 0.01;
input   int     Deviation = 10;

double Sigma;

CTrade *pTrade;
CSymbolInfo *pSymbol;
CList* pOrderList;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Список ордеров
    pOrderList = new CList();
    
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol);

    pTrade = new CTrade();
    pTrade.SetLogLevel(LOG_LEVEL_ERRORS);
    pTrade.SetDeviation(Deviation);
    
    Sigma = NormalizeDouble((TakeProfit + 5)*Point, Digits);
    
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
        HandleSinglePosition(pOrderList.GetFirstNode());
    } else if (total == 2) {
        HandleOppositePosition(pOrderList.GetNodeAtIndex(0), pOrderList.GetNodeAtIndex(1));
    } else {
        // Больше двух ордеров
    }
}
//+------------------------------------------------------------------+
//| Два ордера напротив друг друга                                  |
//+------------------------------------------------------------------+
void HandleOppositePosition(COrderInfo* order1, COrderInfo* order2)
{
    double sigma = NormalizeDouble(MathAbs(order1.GetOpenPrice() - order2.GetOpenPrice()), Digits);
    if (order1.GetType() == OP_SELLSTOP && order2.GetType() == OP_BUY &&  sigma >= Sigma) {
        if (pTrade.SellStop(2*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit())) {
            pTrade.Delete(order1.GetTicket());
        }
    } else if (order1.GetType() == OP_BUYSTOP && order2.GetType() == OP_SELL && sigma >= Sigma) {
        if (pTrade.BuyStop(2*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit())) {
            pTrade.Delete(order1.GetTicket());
        };
    } else if (order1.GetType() == OP_BUY && order2.GetType() == OP_SELL) {
        pTrade.BuyStop(3*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit());
    } else if (order1.GetType() == OP_SELL && order2.GetType() == OP_BUY) {
        pTrade.SellStop(3*Lot, order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit());
    }       
}
//+------------------------------------------------------------------+
//| Открывает трендовую позицию в направлении прошлого закрытия      |
//+------------------------------------------------------------------+
void HandleSinglePosition(COrderInfo* order)
{
    if (order.IsPending()) {
        if (order.GetType() == OP_BUYSTOP) {
            pTrade.Sell(Lot, Bid, NULL, Bid+StopLoss*Point, Bid-TakeProfit*Point);   
            pTrade.BuyStop(2*Lot, Ask+TakeProfit*Point, NULL, Ask-TakeProfit*Point, Ask+StopLoss*Point);   
        } else if(order.GetType() == OP_SELLSTOP) {
            pTrade.Buy(Lot, Ask, NULL, Ask+TakeProfit*Point, Ask-StopLoss*Point);
            pTrade.SellStop(2*Lot, Bid-TakeProfit*Point, NULL, Bid+TakeProfit*Point, Bid-StopLoss*Point);   
        }    
        pTrade.Delete(order.GetTicket());
    } else {
        if (order.GetType() == OP_BUY) { // OP_BUY}
            pTrade.SellStop(2*Lot, order.GetOpenPrice()-TakeProfit*Point, NULL, order.GetOpenPrice()+StopLoss*Point, order.GetOpenPrice()-StopLoss*Point);   
        } else { // OP_SELL
            pTrade.BuyStop(2*Lot, order.GetOpenPrice()+TakeProfit*Point, NULL, order.GetOpenPrice()-StopLoss*Point, order.GetOpenPrice()+StopLoss*Point);   
        }
    }
}

//+------------------------------------------------------------------+
//| Open opposite positions on expert initialization                 |
//+------------------------------------------------------------------+
void OpenOppositePositions()
{
    double price = (Ask+Bid)/2;
    pTrade.SellStop(Lot, price-TakeProfit*Point, NULL, price+TakeProfit*Point, price-StopLoss*Point);
    pTrade.BuyStop(Lot, price+TakeProfit*Point, NULL, price-TakeProfit*Point, price+StopLoss*Point);
}

//+------------------------------------------------------------------+
//| List active orders                                               |
//+------------------------------------------------------------------+
void ListOrders(CList* pOrderList) 
{
    COrderInfo* order;     
    Print("Число ордеров в очереди: ", pOrderList.Total());
    for(int i = 0; i < pOrderList.Total(); i++) {
        order = pOrderList.GetNodeAtIndex(i);
        Print("Заказ типа: ", order.GetType(), " Цена открытия: ", order.GetOpenPrice(), " Исполнен: ", order.IsPending()?"Нет":"Да");
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
