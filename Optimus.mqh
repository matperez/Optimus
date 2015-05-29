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

// Список состояний
enum states {
    STATE_INITIAL = 0, // только что включился И ордеров нет ИЛИ оппозитные стопы еще не сработали 
    STATE_TARGETING = 1, // стадия прицеливания после срабатывания одного из оппозитных ордеров. вычисление ширины канала.
    STATE_TRADE = 2, // торговая итерация
    STATE_CLOSE = 3, // итерация закрыта по тейк профиту или стоп лоссу
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Optimus : public CObject
{
    private:
        int m_take_profit; // тейк профит
        int m_stop_loss; // стоп лосс (вычисляется автоматически)
        double m_multiplier; // отношение sl/tp
        double m_base_size; // базовый объем для торговли
        int m_deviation; // допустимое отклонение при выполнении ордера
        int m_spread; // спред (используется для расчетов)
        int m_delta; // добавка в пунктах к величине отката при прицеливании
        states m_state; // состояние
        CTrade* m_trade; // торговая сессия
        CSymbolInfo* m_symbol; // данные валютной пары
        COrderQueue* m_order_queue; // очередь ордеров
        int m_last_open_type;
        double m_max_price_difference; // максимальное расстояние между текущей ценой и ценой открытия позиции в состоянии прицеливания
        
        void ThrowError(string message);
        double GetRevertLotSize(int op, double sellSize, double buySize, double channelWidth);
        void HandleInitialState();
        void HandleTargetingState();
        void HandleTradingState();
        void HandleCloseState();
        void CloseAll();
        
    public:
         Optimus(int takeProfit, double multiplier, string symbol);
        ~Optimus();
        void   SetState(states state);
        void   SetDelta(int delta) { m_delta = delta; };
        int GetDelta() { return m_delta; };
        void   OnTick();
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
            ThrowError("Это состояние еще не описано");
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::CloseAll()
{
    COrderInfo* order; 
    Print("Вызвана функция закрытия всех ордеров.");
    for(int i = 0; i < m_order_queue.GetList().Total(); i++) {
        order = m_order_queue.GetList().GetNodeAtIndex(i);
        if (!order.IsPending()) {
            m_trade.Delete(order);
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleCloseState()
{
    int total;
    string comment;
    COrderInfo* order;
    CList* list;
    list = m_order_queue.GetList();
    total = list.Total();
    switch(total) {
        case 0:
            if (m_last_open_type == OP_SELL || m_last_open_type == OP_BUY) {
                if (m_last_open_type == OP_BUY) {
                    m_trade.Buy(m_base_size, Ask, NULL, 0, Ask + m_take_profit*Point, comment, 1);
                } else {
                    m_trade.Sell(m_base_size, Bid, NULL, 0, Bid - m_take_profit*Point, comment, 2);
                }
                SetState(STATE_TARGETING);
            } else {
                SetState(STATE_INITIAL);
            }
            break;
        case 1:
            order = list.GetFirstNode();
            if (order == NULL) {
                SetState(STATE_INITIAL);
                break;
            }
            if (!order.IsPending()) {
                Print("В состоянии завершения в очереди не должно быть открытых ордеров, однако, один все-таки затесался.");
                SetState(STATE_TARGETING);
                break;
            }
            comment = __FUNCTION__+": новый ордер по рынку в направлении закрытой сделки";
            if (order.GetType() == OP_BUYSTOP) {
                m_trade.Sell(m_base_size, Bid, NULL, 0, Bid - m_take_profit*Point, comment, 2);
            } else {
                m_trade.Buy(m_base_size, Ask, NULL, 0, Ask + m_take_profit*Point, comment, 1);
            }
            m_trade.Delete(order);
            SetState(STATE_TARGETING);
            break;
        default: 
            ThrowError("В состоянии завершения в очереди должно оставаться не более одного ордера.");
    }
    m_last_open_type = NULL;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Optimus::HandleTradingState()
{
    COrderInfo* lastSell;
    COrderInfo* lastBuy;
    int total;
    double channelWidth;
    
    
    if (m_order_queue.GetLastOpen() != NULL) {
        m_last_open_type = m_order_queue.GetLastOpen().GetType();
    }

    total = m_order_queue.GetList().Total();
    
    if (total > 0 && m_order_queue.IsSeriesEnded()) {
        CloseAll();
        SetState(STATE_CLOSE);
        return;
    }
    
    switch(total) {
        case 0:
            Print("В состоянии торговли не осталось ордеров в очереди.");
            SetState(STATE_CLOSE);
            break;
        case 1:
            Print("В состоянии торговли остался один ордер в очереди.");
            SetState(STATE_CLOSE);
//            ThrowError("В состоянии торговли не может быть менее двух ордеров в очереди");
            break;    
        default:
            lastSell = m_order_queue.GetLastSell();
            lastBuy = m_order_queue.GetLastBuy();
        
            if (lastSell && lastBuy && !m_order_queue.HasPendingOrders()) {
                channelWidth = MathAbs(lastBuy.GetOpenPrice() - lastSell.GetOpenPrice());
                if (lastSell.GetOpenTime() > lastBuy.GetOpenTime()) {
                    m_trade.BuyStop(GetRevertLotSize(OP_BUY, m_order_queue.GetSellSize(), m_order_queue.GetBuySize(), channelWidth), lastBuy.GetOpenPrice(), NULL, lastSell.GetTakeProfit(), lastSell.GetStopLoss(), 0, NULL, lastBuy.GetMagic());
                } else {
                    m_trade.SellStop(GetRevertLotSize(OP_SELL, m_order_queue.GetSellSize(), m_order_queue.GetBuySize(), channelWidth), lastSell.GetOpenPrice(), NULL, lastBuy.GetTakeProfit(), lastBuy.GetStopLoss(), 0, NULL, lastSell.GetMagic());
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
    bool hasReachedTheGoal, hasComeBack;
    double newStopLoss, channelWidth, revertLotSize, maximumChannelWidth, multiplier, NthPersentOfMaxDailyMoving;
    string comment;
    
    if (m_order_queue.GetLastOpen() != NULL) {
        m_last_open_type = m_order_queue.GetLastOpen().GetType();
    }
    
    switch(total) {
        case 0:
            SetState(STATE_CLOSE);
            break;
        case 1:
            order = list.GetFirstNode();
            if (order.IsPending()) {
                ThrowError("В состоянии прицеливания не должно быть отложенных ордеров.");
                break;
            }
            difference = MathAbs(Ask - order.GetOpenPrice());
            if (difference > m_max_price_difference) {
                m_max_price_difference = difference;
            }
            NthPersentOfMaxDailyMoving = 0.2*(High[iHighest(NULL,0,MODE_HIGH,24,0)]-Low[iLowest(NULL,0,MODE_LOW,24,0)]);
            multiplier = (NthPersentOfMaxDailyMoving/Point - m_take_profit)/m_take_profit;
            if (multiplier < 1) {
                multiplier = 1;
            }
            maximumChannelWidth = (multiplier * m_take_profit + m_take_profit) * Point;
            hasReachedTheGoal = m_max_price_difference > maximumChannelWidth;
            hasComeBack = (difference < m_max_price_difference - (m_take_profit + m_delta) * Point) && (difference > multiplier*m_take_profit * Point);
            if (hasReachedTheGoal) { // && hasComeBack) {
                Print("30 процентов от дневного движения: ", NthPersentOfMaxDailyMoving);
                Print("Вычисленный множитель: ", multiplier);
                comment = __FUNCTION__+": страхующий стоп завершающий прицеливание";
                if (order.GetType() == OP_BUY) {
                    channelWidth = MathAbs(order.GetOpenPrice() - Bid);
                    revertLotSize = GetRevertLotSize(OP_SELL, m_order_queue.GetSellSize(), m_order_queue.GetBuySize(), channelWidth);
                    m_trade.Sell(revertLotSize, Bid, NULL, order.GetTakeProfit(), Bid-m_take_profit*Point, comment, order.GetMagic());
                    newStopLoss = Bid-m_take_profit*Point;
                } else {
                    channelWidth = MathAbs(order.GetOpenPrice() - Ask);
                    revertLotSize = GetRevertLotSize(OP_BUY, m_order_queue.GetSellSize(), m_order_queue.GetBuySize(), channelWidth);
                    m_trade.Buy(revertLotSize, Ask, NULL, order.GetTakeProfit(), Ask+m_take_profit*Point, comment, order.GetMagic());
                    newStopLoss = Ask+m_take_profit*Point;
                }
                if (!order.SetStopLoss((float)newStopLoss)) {
                    ThrowError("Ошибка модификации уровня стоп-лосс");
                }
                m_max_price_difference = 0;
                SetState(STATE_TRADE);
            }
            break;
        default:
            ThrowError("В состоянии прицеливания не может быть более одного ордера в очереди");    
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
            ThrowError("В состоянии инициализации не может быть ровно одного ордера в очереди.");
            break;
        case 2:
            first = list.GetFirstNode();
            second = list.GetLastNode();
            if (first.IsPending() && second.IsPending()) {
                break;
            }
            if (!first.IsPending() && !second.IsPending()) {
                ThrowError("В состоянии инициализации не может быть двух выполненных ордера.");
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
            ThrowError("В состоянии инициализации не может быть более двух ордеров в очереди.");
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Optimus::GetRevertLotSize(int op, double sellSize, double buySize, double channelWidth)
{
    double size;
    channelWidth = channelWidth/Point;
    if (sellSize > buySize) {
        size = (sellSize * (channelWidth + m_take_profit) - buySize*m_take_profit + (buySize+sellSize)*m_spread)/(m_take_profit - m_spread);
    } else if (sellSize < buySize) {
        size = (buySize * (channelWidth + m_take_profit) - sellSize*m_take_profit + (buySize+sellSize)*m_spread)/(m_take_profit - m_spread);
    } else {
        ThrowError("Ошибка: Равные объемы проданных и купленных ордеров при расчете размера реверсивной позиции: "+(string)buySize+", "+(string)sellSize);
    }
    Print("Величина канала: ", channelWidth, " ,продажи: ", sellSize, " ,покупки:", buySize, ", tp: ", m_take_profit);
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
            Print("Переход в состояние инициализации");
            break;
        case STATE_TARGETING:
            Print("Переход в состояние прицеливания");
            break;
        case STATE_TRADE:
            Print("Переход в состояние торговли");
            break;
        case STATE_CLOSE:
            Print("Переход в состояние завершенной торговли");
            break;
        default:
            ThrowError("Неизвестное состояние");
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
    m_delta(50),
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
