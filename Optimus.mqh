//+------------------------------------------------------------------+
//|                                                      Optimus.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict

#include <Object.mqh>
#include <stderror.mqh>
#include <stdlib.mqh>

#include "Trade.mqh"
#include "SymbolInfo.mqh"
#include "OrderInfo.mqh"
#include "OrderQueue.mqh"

// —писок состо€ний
enum states {
    STATE_INITIAL = 0, // только что включилс€ » ордеров нет »Ћ» оппозитные стопы еще не сработали 
    STATE_TARGETING = 1, // стади€ прицеливани€ после срабатывани€ одного из оппозитных ордеров. вычисление ширины канала.
    STATE_TRADE = 2, // торгова€ итераци€
    STATE_CLOSE = 3, // итераци€ закрыта по тейк профиту или стоп лоссу
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Optimus : public CObject
{
    private:
        int m_take_profit; // тейк профит
        int m_stop_loss; // стоп лосс (вычисл€етс€ автоматически)
        double m_multiplier; // отношение sl/tp
        double m_base_size; // базовый объем дл€ торговли
        int m_deviation; // допустимое отклонение при выполнении ордера
        int m_spread; // спред (используетс€ дл€ расчетов)
        double m_delta; // ???
        states m_state; // состо€ние
        CTrade* m_trade; // торгова€ сесси€
        CSymbolInfo* m_symbol; // данные валютной пары
        COrderQueue* m_order_queue; // очередь ордеров
        double m_price_difference; // максимальное рассто€ние между текущей ценой и ценой открыти€ позиции в состо€нии прицеливани€
        
        void ThrowError(string message);
        double GetRevertLotSize(int op, double sellSize, double buySize);
        void HandleInitialState();
        void HandleTargetingState();
        void HandleTradingState();
        void HandleCloseState();
        
    public:
         Optimus(int takeProfit, double multiplier, string symbol);
        ~Optimus();
        void SetState(states state);
        void OnTick();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::OnTick(void)
{
    m_order_queue.Update();
    switch(m_state) {
        case STATE_INITIAL:
            HandleInitialState();
            break;
        case STATE_TARGETING:
            HandleTargetingState();
            break;    
        case STATE_TRADE:
            HandleTradingState();
            break;  
        case STATE_CLOSE:
            HandleCloseState();
            break;  
        default:
            ThrowError("Ёто состо€ние еще не описано");
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleCloseState()
{
    SetState(STATE_INITIAL);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleTradingState()
{
    COrderInfo* lastSell;
    COrderInfo* lastBuy;
    int total;
    
    total = m_order_queue.GetList().Total();
    
    switch(total) {
        case 0:
            SetState(STATE_CLOSE);
            break;
        case 1:
            ThrowError("¬ состо€нии торговли не может быть менее двух ордеров в очереди");    
        default:
            lastSell = m_order_queue.GetLastSell();
            lastBuy = m_order_queue.GetLastBuy();
        
            if (lastSell && lastBuy && !m_order_queue.HasPendingOrders()) {
                if (lastSell.GetOpenTime() > lastBuy.GetOpenTime()) {
                    m_trade.BuyStop(GetRevertLotSize(OP_BUY, m_order_queue.GetSellSize(), m_order_queue.GetBuySize()), lastBuy.GetOpenPrice(), NULL, lastSell.GetTakeProfit(), lastSell.GetStopLoss(), 0, NULL, lastBuy.GetMagic());
                } else {
                    m_trade.SellStop(GetRevertLotSize(OP_SELL, m_order_queue.GetSellSize(), m_order_queue.GetBuySize()), lastSell.GetOpenPrice(), NULL, lastBuy.GetTakeProfit(), lastBuy.GetStopLoss(), 0, NULL, lastSell.GetMagic());
                }
            }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleTargetingState()
{
    CList* list = m_order_queue.GetList();
    COrderInfo* order;
    int total = list.Total();
    double difference; // разница между текущей ценой и ценой ордера
    double rollback = m_multiplier*m_take_profit*Point; // необходима€ величина отката
    bool hasReachedTheGoal, hasComeBack;
    double newStopLoss;
    string comment;
    switch(total) {
        case 0:
            SetState(STATE_CLOSE);
            break;
        case 1:
            order = list.GetFirstNode();
            if (order.IsPending()) {
                ThrowError("¬ состо€нии прицеливани€ не должно быть отложенных ордеров.");
                break;
            }
            difference = MathAbs(Ask - order.GetOpenPrice());
            if (difference > m_price_difference) {
                m_price_difference = difference;
            }
            hasReachedTheGoal = m_price_difference > (m_multiplier + 1) * m_take_profit * Point;
            hasComeBack = difference < m_price_difference - m_take_profit;
            if (hasReachedTheGoal && hasComeBack && difference >= m_multiplier*m_take_profit*Point) {
                m_price_difference = 0;
                comment = __FUNCTION__+": страхующий стоп завершающий прицеливание";
                if (order.GetType() == OP_BUY) {
                    m_trade.Sell(GetRevertLotSize(OP_SELL, m_order_queue.GetSellSize(), m_order_queue.GetBuySize()), Bid, NULL, order.GetTakeProfit(), Bid-m_take_profit*Point, comment, order.GetMagic());
                    newStopLoss = Bid-m_take_profit*Point;
                } else {
                    m_trade.Buy(GetRevertLotSize(OP_BUY, m_order_queue.GetSellSize(), m_order_queue.GetBuySize()), Ask, NULL, order.GetTakeProfit(), Ask+m_take_profit*Point, comment, order.GetMagic());
                    newStopLoss = Ask+m_take_profit*Point;
                }
                if (!order.SetStopLoss((float)newStopLoss)) {
                    ThrowError("ќшибка модификации уровн€ стоп-лосс");
                }
                SetState(STATE_TRADE);
            }
            break;
        default:
            ThrowError("¬ состо€нии прицеливани€ не может быть более одного ордера в очереди");    
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleInitialState()
{
    COrderInfo* first;
    COrderInfo* second;
    string comment;
    CList* list = m_order_queue.GetList();
    int total = list.Total();
    switch(total) {
        case 0:
            comment = __FUNCTION__+": open opposite position on initial state";
            m_trade.BuyStop(m_base_size, Ask+100*Point, NULL, 0, Ask+(m_take_profit+100)*Point, 0, comment, 1);
            m_trade.SellStop(m_base_size, Bid-100*Point, NULL, 0, Bid-(m_take_profit+100)*Point, 0, comment, 2);
            break;
        case 1:
            ThrowError("¬ состо€нии инициализации не может быть ровно одного ордера в очереди.");
            break;
        case 2:
            first = list.GetFirstNode();
            second = list.GetLastNode();
            if (first.IsPending() && second.IsPending()) {
                break;
            }
            if (!first.IsPending() && !second.IsPending()) {
                ThrowError("¬ состо€нии инициализации не может быть двух выполненных ордера.");
                break;
            }
            if (!first.IsPending()) {
                m_trade.Delete(second);
            }
            if (!second.IsPending()) {
                m_trade.Delete(first);
            }
            SetState(STATE_TARGETING);
            break;
        default:
            ThrowError("¬ состо€нии инициализации не может быть более двух ордеров в очереди.");
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Optimus::GetRevertLotSize(int op, double sellSize, double buySize)
{
    double size;
    if (sellSize > buySize) {
        size = (sellSize*(m_multiplier+1)*m_take_profit - buySize*m_take_profit + (buySize+sellSize)*m_spread)/(m_take_profit - m_spread);
    } else if (sellSize < buySize) {
        size = (buySize*(m_multiplier+1)*m_take_profit - sellSize*m_take_profit + (buySize+sellSize)*m_spread)/(m_take_profit - m_spread);
    } else {
        ThrowError("ќшибка: –авные объемы проданных и купленных ордеров при расчете размера реверсивной позиции: "+(string)buySize+", "+(string)sellSize);
    }
    size = NormalizeDouble(size, 2) + 0.01;
    return size;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::SetState(states state)
{
    m_state = state;
    switch(m_state) {
        case STATE_INITIAL:
            Print("ѕереход в состо€ние инициализации");
            break;
        case STATE_TARGETING:
            Print("ѕереход в состо€ние прицеливани€");
            break;
        case STATE_TRADE:
            Print("ѕереход в состо€ние торговли");
            break;
        case STATE_CLOSE:
            Print("ѕереход в состо€ние завершенной торговли");
            break;
        default:
            ThrowError("Ќеизвестное состо€ние");
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::ThrowError(string message)
{
    Print("Error: ", message);
    CSymbolInfo* pSI;
    pSI.Refresh();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Optimus::Optimus(int takeProfit, double multiplier, string symbol):
    m_delta(1.05),
    m_spread(0),
    m_deviation(10),
    m_base_size(0.01)
{
    m_take_profit = takeProfit;
    m_multiplier = multiplier;
    m_stop_loss = (int) m_multiplier * m_take_profit;
    
    m_symbol = new CSymbolInfo();
    m_symbol.Name(symbol);
    
    m_trade = new CTrade();
    m_trade.SetLogLevel(LOG_LEVEL_ERRORS);
    m_trade.SetDeviation(m_deviation);
    
    m_order_queue = new COrderQueue();

    SetState(STATE_INITIAL);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Optimus::~Optimus()
{
    delete m_order_queue;
    delete m_symbol;
    delete m_trade;
}
//+------------------------------------------------------------------+
