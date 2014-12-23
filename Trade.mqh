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
   LOG_LEVEL_NO    =0,
   LOG_LEVEL_ERRORS=1,
   LOG_LEVEL_ALL   =2
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
    void    SetMagicNumber(const int magic) { m_magic=magic; }
    void    SetLogLevel(const ENUM_LOG_LEVELS log_level)   { m_log_level=log_level; }
    void    SetDeviation(const int deviation) { m_deviation = deviation; }
    bool    Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="");
};


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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade::CTrade() : m_magic(0),
    m_deviation(10),
    m_log_level(LOG_LEVEL_ERRORS)
{
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade::~CTrade()
{
}
//+------------------------------------------------------------------+
