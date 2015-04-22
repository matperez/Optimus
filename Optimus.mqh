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
        
        void ThrowError(string message);
        void HandleInitialState();
        
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
        default:
            ThrowError("Ёто поведение еще не описано");
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
                m_trade.Delete(second);
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
void Optimus::SetState(states state)
{
    m_state = state;
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
    m_base_size(0.01),
    m_state(STATE_INITIAL)
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
