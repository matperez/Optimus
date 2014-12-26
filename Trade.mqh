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
#include "SymbolInfo.mqh"

//+------------------------------------------------------------------+
//| enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_ERR_CODES
{
    ERR_NO_ERROR = 0, // ��� ������
    ERR_NO_RESULT = 1, // ��� ������, �� ��������� ����������
    ERR_COMMON_ERROR = 2, // ����� ������
    ERR_INVALID_TRADE_PARAMETERS = 3, // ������������ ���������
    ERR_SERVER_BUSY = 4, // �������� ������ �����
    ERR_OLD_VERSION = 5, // ������ ������ ����������� ���������
    ERR_NO_CONNECTION = 6, // ��� ����� � �������� ��������
    ERR_NOT_ENOUGH_RIGHTS = 7, // ������������ ����
    ERR_TOO_FREQUENT_REQUESTS = 8, // ������� ������ �������
    ERR_MALFUNCTIONAL_TRADE = 9, // ������������ ��������, ���������� ���������������� �������
    ERR_ACCOUNT_DISABLED = 64, // ���� ������������
    ERR_INVALID_ACCOUNT = 65, // ������������ ����� �����
    ERR_TRADE_TIMEOUT = 128, // ����� ���� �������� ���������� ������
    ERR_INVALID_PRICE = 129, // ������������ ����
    ERR_INVALID_STOPS = 130, // ������������ �����
    ERR_INVALID_TRADE_VOLUME = 131, // ������������ �����
    ERR_MARKET_CLOSED = 132, // ����� ������
    ERR_TRADE_DISABLED = 133, // �������� ���������
    ERR_NOT_ENOUGH_MONEY = 134, // ������������ ����� ��� ���������� ��������
    ERR_PRICE_CHANGED = 135, // ���� ����������
    ERR_OFF_QUOTES = 136, // ��� ���
    ERR_BROKER_BUSY = 137, // ������ �����
    ERR_REQUOTE = 138, // ����� ����
    ERR_ORDER_LOCKED = 139, // ����� ������������ � ��� ��������������
    ERR_LONG_POSITIONS_ONLY_ALLOWED = 140, // ��������� ������ �������
    ERR_TOO_MANY_REQUESTS = 141, // ������� ����� ��������
    ERR_TRADE_MODIFY_DENIED = 145, // ����������� ���������, ��� ��� ����� ������� ������ � �����
    ERR_TRADE_CONTEXT_BUSY = 146, // ���������� �������� ������
    ERR_TRADE_EXPIRATION_DENIED = 147, // ������������� ���� ��������� ������ ��������� ��������
    ERR_TRADE_TOO_MANY_ORDERS = 148, // ���������� �������� � ���������� ������� �������� �������, �������������� ��������
    ERR_TRADE_HEDGE_PROHIBITED = 149, // ������� ������� ��������������� ����� � ������, ���� ������������ ���������
    ERR_TRADE_PROHIBITED_BY_FIFO = 150, // ������� ������� ������� �� ����������� � ������������ � �������� FIFO
}

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
    ENUM_ERR_CODES  retcode;          // ��� ���������� ��������
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
                        const double price,const double sl,const double tp,const string comment="");
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
//| Buy operation                                                    |
//+------------------------------------------------------------------+
bool CTrade::Buy(const double volume,const string symbol=NULL,double price=0.0,const double sl=0.0,const double tp=0.0,const string comment="")
{
    CSymbolInfo sym;

    if(volume<=0.0) {
        m_result.retcode = ERR_INVALID_TRADE_VOLUME;
        return(false);
    }
    
    sym.Name((symbol==NULL)?Symbol():symbol);
    
    if(price==0.0) {
        sym.RefreshRates();
        price=sym.Ask();
    }
    
    //return(PositionOpen(sym.Name(),ORDER_TYPE_BUY,volume,price,sl,tp,comment));
    if (m_log_level == LOG_LEVEL_ALL) {
        Print("����� ������ �� ������� �� �����. ������: ", symbol,",����: ", price, ", ����: ", price-sl*Point, ", ������: ", price+tp*Point);
    }
    int result = OrderSend(symbol, OP_BUY, volume, price, m_deviation, price-sl*Point, price+tp*Point, comment, m_magic, 0, Blue);
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

