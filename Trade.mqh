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
#include <stderror.mqh>
#include <stdlib.mqh>
#include "SymbolInfo.mqh"

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
//| structs                                                     |
//+------------------------------------------------------------------+
struct MqlTradeRequest
{
    ulong                         magic;            // ����� �������� (������������� magic number)
    ulong                         order;            // ����� ������
    string                        symbol;           // ��� ��������� �����������
    double                        volume;           // ������������� ����� ������ � �����
    double                        price;            // ���� 
    double                        stoplimit;        // ������� StopLimit ������
    double                        sl;               // ������� Stop Loss ������
    double                        tp;               // ������� Take Profit ������
    ulong                         deviation;        // ����������� ���������� ���������� �� ������������� ����
    ENUM_ORDER_TYPE               type;             // ��� ������
    datetime                      expiration;       // ���� ��������� ������ (��� ������� ���� ORDER_TIME_SPECIFIED)
    string                        comment;          // ����������� � ������
};

struct MqlTradeResult
{
    uint            code;             // ��� ���������� ��������
    ulong           deal;             // ����� ������, ���� ��� ���������
    ulong           order;            // ����� ������, ���� �� ���������
    double          volume;           // ����� ������, ������������� ��������
    double          price;            // ���� � ������, ������������� ��������
    double          bid;              // ������� �������� ���� ����������� (���� �������)
    double          ask;              // ������� �������� ���� ������ (���� �������)
    string          comment;          // ����������� ������� � �������� (�� ��������� ����������� ������������)
    uint            request_id;       // ������������� �������, ��������������� ���������� ��� �������� 
};

struct MqlTradeCheckResult
{
    uint         retcode;             // ��� ������
    double       balance;             // ������ ����� ���������� ������
    double       equity;              // ������ ����� ���������� ������
    double       profit;              // ��������� �������
    double       margin;              // �������� ����������
    double       margin_free;         // ��������� �����
    double       margin_level;        // ������� �����
    string       comment;             // ����������� � ���� ������ (�������� ������)
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CTrade : public CObject
{
private:
    ENUM_LOG_LEVELS     m_log_level;
    int                 m_deviation;       // deviation default
    int                 m_magic;
    MqlTradeRequest     m_request;         // request data
    MqlTradeResult      m_result;          // result data
    MqlTradeCheckResult m_check_result;  // result check data
public:
            CTrade();
            ~CTrade();
    void    SetMagicNumber(const int magic) { m_magic=magic; }
    void    SetLogLevel(const ENUM_LOG_LEVELS log_level)   { m_log_level=log_level; }
    void    SetDeviation(const int deviation) { m_deviation = deviation; }
    bool    Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="");
    bool    Sell(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="");
    bool    PositionOpen(const string symbol,const ENUM_ORDER_TYPE order_type,const double volume,
                          const double price,const double sl,const double tp,const string comment);
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CTrade::CTrade() : m_magic(0),
    m_deviation(10),
    m_log_level(LOG_LEVEL_ERRORS)
{
}

//+------------------------------------------------------------------+
//| Destructor                                                                 |
//+------------------------------------------------------------------+
CTrade::~CTrade()
{
}

//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
bool CTrade::PositionOpen(const string symbol,const ENUM_ORDER_TYPE order_type,const double volume,
                          const double price,const double sl,const double tp,const string comment)
{
//--- check stopped
    if(IsStopped())
        return(false);
//--- clean
   //ClearStructures();
//--- check
    if(order_type!=ORDER_TYPE_BUY && order_type!=ORDER_TYPE_SELL)
    {
        m_result.code = ERR_INVALID_TRADE_PARAMETERS;
        m_result.comment = ErrorDescription(m_result.code);
        return(false);
    }
//--- setting request
   m_request.symbol      = symbol;
   m_request.magic       = m_magic;
   m_request.volume      = volume;
   m_request.type        = order_type;
   m_request.price       = price;
   m_request.sl          = sl;
   m_request.tp          = tp;
   m_request.deviation   = m_deviation;
//--- check order type
//   if(!OrderTypeCheck(symbol))
//     return(false);
//--- check filling
   m_request.comment=comment;
   
   int result = OrderSend(symbol, order_type, volume, price, m_deviation, sl, tp, comment, m_magic, 0, Blue);
   if (result < 0) {
       if (m_log_level == LOG_LEVEL_ERRORS || m_log_level == LOG_LEVEL_ALL) {
           Print("������ ������� �� �����. ��� ������: ", GetLastError());
       }
       return false;
   }
   return true;
}
//+------------------------------------------------------------------+
//| Buy operation                                                    |
//+------------------------------------------------------------------+
bool CTrade::Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
{
    CSymbolInfo sym;

    if (volume<=0.0) {
        m_result.code = ERR_INVALID_TRADE_VOLUME;
        m_result.comment = ErrorDescription(m_result.code);
        return(false);
    }
    
    sym.Name((symbol==NULL)?Symbol():symbol);
    
    if(price==0.0) {
        sym.RefreshRates();
        price=sym.Ask();
    }
    
    return(PositionOpen(sym.Name(),ORDER_TYPE_BUY,volume,price,sl,tp,comment));
    //if (m_log_level == LOG_LEVEL_ALL) {
    //    Print("����� ������ �� ������� �� �����. ������: ", symbol,",����: ", price, ", ����: ", price-sl*Point, ", ������: ", price+tp*Point);
    //}
    //int result = OrderSend(symbol, OP_BUY, volume, price, m_deviation, price-sl*Point, price+tp*Point, comment, m_magic, 0, Blue);
    //if (result < 0) {
    //    if (m_log_level == LOG_LEVEL_ERRORS || m_log_level == LOG_LEVEL_ALL) {
    //        Print("������ ������� �� �����. ��� ������: ", GetLastError());
    //    }
    //    return false;
    //}
    //if (m_log_level == LOG_LEVEL_ALL) {
    //    Print("�������� ������� �� �����. ��� ������: ", result);
    //}
    //return true;
}

bool CTrade::Sell(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
{
    if (price == 0.0) {
        price = Bid;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("����� ������ �� ������� �� �����. ������: ", symbol,",����: ", price, ", ����: ", price+sl*Point, ", ������: ", price-tp*Point);
    }
    int result = OrderSend(symbol, OP_SELL, volume, price, m_deviation, price+sl*Point, price-tp*Point, comment, m_magic, 0, Red);
    if (result < 0) {
        if (m_log_level == LOG_LEVEL_ERRORS || m_log_level == LOG_LEVEL_ALL) {
            Print("������ ������� �� �����. ��� ������: ", GetLastError());
        }
        return false;
    }
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("�������� ������� �� �����. ��� ������: ", result);
    }
    return true;
}

