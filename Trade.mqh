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
    int             ticket;           // ����� ������ ��� ����������� ������
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
    color               GetColor(const ENUM_ORDER_TYPE order_type);
    void                ClearStructures(void);
    
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
    if(IsStopped())
        return(false);
    ClearStructures();
    if(order_type!=ORDER_TYPE_BUY && order_type!=ORDER_TYPE_SELL)
    {
        m_result.code = ERR_INVALID_TRADE_PARAMETERS;
        m_result.comment = ErrorDescription(m_result.code);
        return(false);
    }
    m_request.symbol = symbol;
    m_request.magic = m_magic;
    m_request.volume = volume;
    m_request.type = order_type;
    m_request.price = price;
    m_request.sl = sl;
    m_request.tp = tp;
    m_request.deviation = m_deviation;
    m_request.comment = comment;
    
    m_result.ticket = OrderSend(m_request.symbol, m_request.type, m_request.volume, m_request.price, m_request.deviation, m_request.sl, m_request.tp, m_request.comment, m_request.magic, 0, GetColor(m_request.type));

    if (m_result.ticket < 0) {
        m_result.code = GetLastError();
        m_result.comment = ErrorDescription(m_result.code);
        return (false);
    }

    return (true);
}
//+------------------------------------------------------------------+
//| Clear structures m_request,m_result and m_check_result           |
//+------------------------------------------------------------------+
void CTrade::ClearStructures(void)
{
   ZeroMemory(m_request);
   ZeroMemory(m_result);
}
//+------------------------------------------------------------------+
//| Order color                                                      |
//+------------------------------------------------------------------+
color CTrade::GetColor(const ENUM_ORDER_TYPE order_type)
{
    switch(order_type)
    {
        case OP_BUY:
        case OP_BUYLIMIT:
        case OP_BUYSTOP:
            return Blue;
        case OP_SELL:
        case OP_SELLLIMIT:
        case OP_SELLSTOP:
            return Red;
    }
    return Gray;
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
    return(PositionOpen(sym.Name(),ORDER_TYPE_BUY,volume,price,price-sl,price+tp,comment));
}
//+------------------------------------------------------------------+
//| Sell operation                                                    |
//+------------------------------------------------------------------+
bool CTrade::Sell(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
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
    return(PositionOpen(sym.Name(),ORDER_TYPE_SELL,volume,price,price+sl,price-tp,comment));
}

