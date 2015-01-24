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

input   int     TakeProfit = 350;
//input   int     StopLoss = 700;
input   double  Lot = 0.01;
input   int     Deviation = 10;
input   int     Spred = 0;
input   double  Delta = 1.05;


// Счетчик ордеров указанного типа в текущей итерации и в прошлом
int counters[3], countersOld[3];
int StopLoss;

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
    
    StopLoss = TakeProfit*2;
    
    ArrayInitialize(countersOld, 0);
    
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
    
    total = pOrderList.Total();

//    Print("Счетчики: c1 = ",counters[1], ", c2 = ", counters[2], ", c0 = ", counters[0] );

    if (ArrayCompare(counters, countersOld) != 0) {
        if ((counters[1] != 0  && counters[1] < countersOld[1]) 
        || (counters[2] != 0  && counters[2] < countersOld[2])) {
            Print("Счетчики изменились: c1 = ",counters[1], ", c2 = ", counters[2], ", c0 = ", counters[0] );
//            CloseOpenOrders();
        }
    }

    if (total == 0) {
        OpenOppositePositions();
    } else if(total == 1) {
        HandleSinglePosition(pOrderList.GetFirstNode());
    } else if (total == 2) {
        HandleOppositePosition(pOrderList.GetNodeAtIndex(0), pOrderList.GetNodeAtIndex(1));
    } else {
        COrderInfo* lastBuy, *lastSell, *current;
        int buy = 0, sell = 0;
        
        for(int i = 0; i < pOrderList.Total(); i++) {
            current = pOrderList.GetNodeAtIndex(i);
            if (current.IsBuy()) {
                buy++;
                lastBuy = current;
            } else if (current.IsSell()) {
                sell++;
                lastSell = current;
            }
        }
        
        if (buy+sell == total) {
            if (lastSell.GetOpenTime() > lastBuy.GetOpenTime()) {
                double volume = GetLotSize(Lot, Delta, buy+sell);
                pTrade.BuyStop(volume, lastBuy.GetOpenPrice(), NULL, lastSell.GetTakeProfit()+Spred*Point, lastSell.GetStopLoss()+Spred*Point, 0, NULL, lastBuy.GetMagic());
            } else {
                double volume = GetLotSize(Lot, Delta, buy+sell);
                pTrade.SellStop(volume, lastSell.GetOpenPrice(), NULL, lastBuy.GetTakeProfit()+Spred*Point, lastBuy.GetStopLoss()-Spred*Point, 0, NULL, lastSell.GetMagic());
            }
        }
        
        // Больше двух ордеров
        //Print("Больше двух ордеров");
        
    }
    
    ArrayCopy(countersOld, counters);
}

void CloseOpenOrders()
{
    COrderInfo* order;     
    for(int i = 0; i < pOrderList.Total(); i++) {
        order = pOrderList.GetNodeAtIndex(i);
        if (!order.IsPending()) {
            pTrade.Delete(order);
        }
    }
}

//+------------------------------------------------------------------+
//| Два ордера напротив друг друга                                  |
//+------------------------------------------------------------------+
void HandleOppositePosition(COrderInfo* order1, COrderInfo* order2)
{
    bool ordersIsBalanced = (order1.GetStopLoss() == order2.GetTakeProfit() || order2.GetStopLoss() == order1.GetTakeProfit());
    if (order1.IsPending() && order1.IsPending()) {
        // Два условных ордера, ни один не выполнился.
    } else if (!order1.IsPending() && order2.IsPending() && !ordersIsBalanced) {
        // Первый выполнился, второй передвигаем
        if (order1.IsBuy()) {
            if (pTrade.SellStop(GetLotSize(Lot, Delta, 1), order1.GetOpenPrice()-TakeProfit*Point, NULL, order1.GetTakeProfit()+Spred*Point, order1.GetStopLoss()-Spred*Point, 0, NULL, order1.GetMagic())) {
                pTrade.Delete(order2);
            }
        } else if (order1.IsSell()) {
            if (pTrade.BuyStop(GetLotSize(Lot, Delta, 1), order1.GetOpenPrice()+TakeProfit*Point, NULL, order1.GetTakeProfit()+Spred*Point, order1.GetStopLoss()+Spred*Point, 0, NULL, order1.GetMagic())) {
                pTrade.Delete(order2);
            }
        }
    } else if (order1.IsPending() && !ordersIsBalanced) {
        // Второй выполнился, первый передвигаем
        if (order2.IsBuy()) {
            if (pTrade.SellStop(GetLotSize(Lot, Delta, 1), order2.GetOpenPrice()-TakeProfit*Point, NULL, order2.GetTakeProfit()+Spred*Point, order2.GetStopLoss()-Spred*Point, 0, NULL, order2.GetMagic())) {
                pTrade.Delete(order1);
            }
        } else if (order2.IsSell()) {
            if (pTrade.BuyStop(GetLotSize(Lot, Delta, 1), order2.GetOpenPrice()+TakeProfit*Point, NULL, order2.GetTakeProfit()+Spred*Point, order2.GetStopLoss()+Spred*Point, 0, NULL, order2.GetMagic())) {
                pTrade.Delete(order1);
            }
        }
    } else if (!order1.IsPending() && !order2.IsPending()) {
        Print("Оба ордера выполнились");
        // Оба выполнились
        if (order1.IsBuy() && order2.IsSell()) {
            pTrade.BuyStop(GetLotSize(Lot, Delta, 2), order1.GetOpenPrice(), NULL, order1.GetStopLoss()+Spred*Point, order1.GetTakeProfit()+Spred*Point, 0, NULL, order1.GetMagic());
        } else if (order1.IsSell() && order2.IsBuy()) {
            pTrade.SellStop(GetLotSize(Lot, Delta, 2), order1.GetOpenPrice(), NULL, order1.GetStopLoss()+Spred*Point, order1.GetTakeProfit()-Spred*Point, 0, NULL, order1.GetMagic());
        } else {
            // Сюда мы не должны попадать
        }
    } else {
        // Ордера уже сбалансированы
    }
}
//+------------------------------------------------------------------+
//| Открывает трендовую позицию в направлении прошлого закрытия      |
//+------------------------------------------------------------------+
void HandleSinglePosition(COrderInfo* order)
{
    if (order.IsPending()) {
        if (order.GetType() == OP_BUYSTOP) {
            pTrade.Sell(Lot, Bid, NULL, Bid+(StopLoss+2*Spred)*Point, Bid-(TakeProfit+Spred)*Point, NULL, 2);   
            pTrade.BuyStop(GetLotSize(Lot, Delta, 1), Bid+(TakeProfit+Spred)*Point, NULL, Bid-(TakeProfit+Spred)*Point, Bid+(StopLoss+2*Spred)*Point, 0, NULL, 2);   
        } else if(order.GetType() == OP_SELLSTOP) {
            pTrade.Buy(Lot, Ask, NULL, Ask-(StopLoss+2*Spred)*Point, Ask+(TakeProfit+Spred)*Point, NULL, 1);
            pTrade.SellStop(GetLotSize(Lot, Delta, 1), Ask-(TakeProfit+Spred)*Point, NULL, Ask+(TakeProfit+Spred)*Point, Ask-(StopLoss+2*Spred)*Point, 0, NULL, 1);   
        }    
        pTrade.Delete(order);
    } else {
        if (order.GetType() == OP_BUY) {
            pTrade.SellStop(GetLotSize(Lot, Delta, 1), order.GetOpenPrice()-TakeProfit*Point, NULL, order.GetTakeProfit()+Spred*Point, order.GetStopLoss()-Spred*Point, 0, NULL, order.GetMagic());  
        } else { // OP_SELL
            pTrade.BuyStop(GetLotSize(Lot, Delta, 1), order.GetOpenPrice()+TakeProfit*Point, NULL, order.GetTakeProfit()+Spred*Point, order.GetStopLoss()+Spred*Point, 0, NULL, order.GetMagic());  
        }
    }
}

//+------------------------------------------------------------------+
//| Open opposite positions on expert initialization                 |
//+------------------------------------------------------------------+
void OpenOppositePositions()
{
    pTrade.BuyStop(Lot, Ask+100*Point, NULL, Ask-(StopLoss+100+2*Spred)*Point, Ask+(TakeProfit+100+Spred)*Point, 0, NULL, 1);
    pTrade.SellStop(Lot, Bid-100*Point, NULL, Bid+(StopLoss+100+2*Spred)*Point, Bid-(TakeProfit+100+Spred)*Point, 0, NULL, 2);
}

//+------------------------------------------------------------------+
//| List active orders                                               |
//+------------------------------------------------------------------+
void ListOrders() 
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
//+------------------------q------------------------------------------+
void UpdateList() 
{
    COrderInfo* order;
    int magic, total, pos;
    
    pOrderList.Clear();
    total = OrdersTotal();
    ArrayInitialize(counters, 0);
    for (pos = 0; pos < total; pos++) {
        order = new COrderInfo();
        if (order.SelectByIndex(pos)) {
            pOrderList.Add(order);
            if (!order.IsPending()) {
                magic = order.GetMagic();
                counters[magic] = counters[magic] + 1;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Возвращает размер лота для следующего трейда                     |
//+------------------------------------------------------------------+
double GetLotSize(double minLot, double delta, int i)
{
    double result;
    if (i == 0) {
        result = minLot;
    } else if (i == 1) {
        result = delta*2*minLot+minLot;
    } else if (i == 2) {
        result = delta*(1 + 2*delta)*minLot+minLot;
    } else {
        result = 2 * GetLotSize(minLot, delta, i - 1)  * MathPow(delta, i-1);
        Print(i+", "+result);
    }
    return NormalizeDouble(result, 2);
}
//+------------------------------------------------------------------+
