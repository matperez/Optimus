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
#include "OrderQueue.mqh"
#include <Arrays\List.mqh>

input   int     TakeProfit = 350;
//input   int     StopLoss = 700;
input   double  M = 2; // отношение SL/TP
input   double  Lot = 0.01;
input   int     Deviation = 10;
input   int     Spred = 0;
input   double  Delta = 1.05;


double StopLoss;

CTrade *pTrade;

CSymbolInfo *pSymbol;

COrderQueue* pOrderQueue;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol);

    pTrade = new CTrade();
    pTrade.SetLogLevel(LOG_LEVEL_ERRORS);
    pTrade.SetDeviation(Deviation);

    pOrderQueue = new COrderQueue();
    
    
    StopLoss = TakeProfit*M;
    
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
    delete pOrderQueue;
    delete pSymbol;
    delete pTrade;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    CList* orderList;
    COrderInfo* lastSell;
    COrderInfo* lastBuy;

    pOrderQueue.Update();
    
    orderList = pOrderQueue.GetList();
    
    //if (pOrderQueue.IsSeriesEnded()) {
    //    Print("Серия закрылась");
    //}

    switch(orderList.Total()) {
        case 0:
            OpenOppositePositions();
            break;
        case 1:
            HandleSinglePosition(orderList.GetFirstNode());
            break;
        case 2:
            HandleOppositePosition(orderList.GetNodeAtIndex(0), orderList.GetNodeAtIndex(1));
            break;
        default:
            lastSell = pOrderQueue.GetLastSell();
            lastBuy = pOrderQueue.GetLastBuy();
        
            if (lastSell && lastBuy && !pOrderQueue.HasPendingOrders()) {
                if (lastSell.GetOpenTime() > lastBuy.GetOpenTime()) {
                    pTrade.BuyStop(GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), lastBuy.GetOpenPrice(), NULL, lastSell.GetTakeProfit(), lastSell.GetStopLoss(), 0, NULL, lastBuy.GetMagic());
                } else {
                    pTrade.SellStop(GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), lastSell.GetOpenPrice(), NULL, lastBuy.GetTakeProfit(), lastBuy.GetStopLoss(), 0, NULL, lastSell.GetMagic());
                }
            }
            break;
    }
}


void CloseOpenOrders()
{
    COrderInfo* order; 
        
    for(int i = 0; i < pOrderQueue.GetList().Total(); i++) {
        order = pOrderQueue.GetList().GetNodeAtIndex(i);
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
            if (pTrade.SellStop(GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice()-StopLoss*Point, NULL, order1.GetTakeProfit(), order1.GetStopLoss(), 0, NULL, order1.GetMagic())) {
                pTrade.Delete(order2);
            }
        } else if (order1.IsSell()) {
            if (pTrade.BuyStop(GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice()+StopLoss*Point, NULL, order1.GetTakeProfit(), order1.GetStopLoss(), 0, NULL, order1.GetMagic())) {
                pTrade.Delete(order2);
            }
        }
    } else if (order1.IsPending() && !ordersIsBalanced) {
        // Второй выполнился, первый передвигаем
        if (order2.IsBuy()) {
            if (pTrade.SellStop(GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice(), NULL, order2.GetTakeProfit(), order2.GetStopLoss(), 0, NULL, order2.GetMagic())) {
                pTrade.Delete(order1);
            }
        } else if (order2.IsSell()) {
            if (pTrade.BuyStop(GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice(), NULL, order2.GetTakeProfit(), order2.GetStopLoss(), 0, NULL, order2.GetMagic())) {
                pTrade.Delete(order1);
            }
        }
    } else if (!order1.IsPending() && !order2.IsPending()) {
        Print("Оба ордера выполнились");
        Print("Размеры: "+pOrderQueue.GetSellSize()+", "+pOrderQueue.GetBuySize());
        // Оба выполнились
        if (order1.IsBuy() && order2.IsSell()) {
            pTrade.BuyStop(GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit(), 0, NULL, order1.GetMagic());
        } else if (order1.IsSell() && order2.IsBuy()) {
            pTrade.SellStop(GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order1.GetOpenPrice(), NULL, order1.GetStopLoss(), order1.GetTakeProfit(), 0, NULL, order1.GetMagic());
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
            pTrade.Sell(Lot, Bid, NULL, Bid+(StopLoss+TakeProfit)*Point, Bid-TakeProfit*Point, NULL, 2);
        } else if(order.GetType() == OP_SELLSTOP) {
            pTrade.Buy(Lot, Ask, NULL, Ask-(StopLoss+TakeProfit)*Point, Ask+TakeProfit*Point, NULL, 1);
        }    
        pTrade.Delete(order);
    } else {
        if (order.GetType() == OP_BUY) {
            if(!pTrade.SellStop(GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order.GetOpenPrice()-StopLoss*Point, NULL, order.GetTakeProfit(), order.GetStopLoss(), 0, NULL, order.GetMagic())) {
                Print("Ошибка размещения отложенного ордера на продажу: "+pTrade.GetMessage());
                Print("Объем: "+GetRevertLotSize(OP_SELL, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()));
            }
        } else { // OP_SELL
            if(!pTrade.BuyStop(GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()), order.GetOpenPrice()+StopLoss*Point, NULL, order.GetTakeProfit(), order.GetStopLoss(), 0, NULL, order.GetMagic())) {
                Print("Ошибка размещения отложенного ордера на покупку: "+pTrade.GetMessage());
                Print("Объем: "+GetRevertLotSize(OP_BUY, pOrderQueue.GetSellSize(), pOrderQueue.GetBuySize()));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Open opposite positions on expert initialization                 |
//+------------------------------------------------------------------+
void OpenOppositePositions()
{
    pTrade.BuyStop(Lot, Ask+100*Point, NULL, 0, Ask+(TakeProfit+100)*Point, 0, NULL, 1);
    pTrade.SellStop(Lot, Bid-100*Point, NULL, 0, Bid-(TakeProfit+100)*Point, 0, NULL, 2);
}


//+------------------------------------------------------------------+
//| Возвращает размер следующей позиции при развороте                |
//+------------------------------------------------------------------+
double GetRevertLotSize(int op, double sellSize, double buySize)
{
    double size;
    if (sellSize > buySize) {
        size = (sellSize*(M+1)*TakeProfit - buySize*TakeProfit + (buySize+sellSize)*Spred)/(TakeProfit - Spred);
    } else if (sellSize < buySize) {
        size = (buySize*(M+1)*TakeProfit - sellSize*TakeProfit + (buySize+sellSize)*Spred)/(TakeProfit - Spred);
    } else {
        Print("Ошибка: Равные объемы проданных и купленных ордеров при расчете размера реверсивной позиции: "+buySize+", "+sellSize);
    }
    size = NormalizeDouble(size, 2);
//    if (size == 0.01) {
//        size += 0.01;
//    }
    size += 0.01;
    return size;
}

