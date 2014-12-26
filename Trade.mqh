//+------------------------------------------------------------------+
//|                                                        Trade.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Object.mqh>

//+------------------------------------------------------------------+
//| enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_LOG_LEVELS
{
    LOG_LEVEL_NO     = 0,
    LOG_LEVEL_ERRORS = 1,
    LOG_LEVEL_ALL    = 2
};

enum ENUM_SELECT_TYPES
{
    SELECT_TYPE_TICKET  = SELECT_BY_TICKET,
    SELECT_TYPE_POS     = SELECT_BY_POS
};

enum ENUM_SELECT_MODES
{
    SELECT_MODE_TRADES = MODE_TRADES,
    SELECT_MODE_HISTORY = MODE_HISTORY
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrade : public CObject
{
private:
    ENUM_LOG_LEVELS m_log_level;
    int           m_deviation;       // deviation default
    int           m_magic;
    
public:
            CTrade();
            ~CTrade();
    void    UpdateQueue(void);
    void    SetMagicNumber(const int magic) { m_magic=magic; }
    void    SetLogLevel(const ENUM_LOG_LEVELS log_level)   { m_log_level=log_level; }
    void    SetDeviation(const int deviation) { m_deviation = deviation; }
    bool    Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="");
    bool    Sell(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="");
    bool    PositionOpen(const string symbol,const ENUM_ORDER_TYPE order_type,const double volume,
                        const double price,const double sl,const double tp,const string comment="");
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade::CTrade() : m_magic(0),
    m_deviation(10),
    m_log_level(LOG_LEVEL_ERRORS)
{
    UpdateQueue();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade::~CTrade()
{
}
//+------------------------------------------------------------------+


// Обновляет очередь с сервера
void CTrade::UpdateQueue()
{
    int total = OrdersTotal();
    for (int pos = 0; pos < total; pos++)
    {
        if (OrderSelect(pos, SELECT_BY_POS, MODE_TRADES) == true)
        {
            Print(OrderTicket(),OrderOpenPrice(),OrderOpenTime(),OrderSymbol(),OrderLots());
        }
    }
}

bool CTrade::Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
{
    if (price == 0.0) {
        price = Ask;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("Новый запрос на покупку по рынку. Символ: ", symbol,",цена: ", price, ", стоп: ", price-sl*Point, ", профит: ", price+tp*Point);
    }
    int result = OrderSend(symbol, OP_BUY, volume, price, m_deviation, price-sl*Point, price+tp*Point, comment, m_magic, 0, Blue);
    if (result < 0) {
        if (m_log_level == LOG_LEVEL_ERRORS || m_log_level == LOG_LEVEL_ALL) {
            Print("Ошибка покупки по рынку. Код ошибки: ", GetLastError());
        }
        return false;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("Успешная покупка по рынку. Код ответа: ", result);
    }
    return true;
}

bool CTrade::Sell(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
{
    if (price == 0.0) {
        price = Bid;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("Новый запрос на продажу по рынку. Символ: ", symbol,",цена: ", price, ", стоп: ", price+sl*Point, ", профит: ", price-tp*Point);
    }
    int result = OrderSend(symbol, OP_SELL, volume, price, m_deviation, price+sl*Point, price-tp*Point, comment, m_magic, 0, Red);
    if (result < 0) {
        if (m_log_level == LOG_LEVEL_ERRORS || m_log_level == LOG_LEVEL_ALL) {
            Print("Ошибка продажи по рынку. Код ошибки: ", GetLastError());
        }
        return false;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("Успешная продажа по рынку. Код ответа: ", result);
    }
    return true;
}

