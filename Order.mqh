//+------------------------------------------------------------------+
//|                                                        Order.mqh |
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
enum ENUM_OP_TYPES
  {
   OP_TYPE_BUY      = OP_BUY,
   OP_TYPE_SELL     = OP_SELL,
   OP_TYPE_BUY_LIMIT = OP_BUYLIMIT,
   OP_TYPE_SELL_LIMIT = OP_SELLLIMIT,
   OP_TYPE_BUY_STOP = OP_BUYSTOP,
   OP_TYPE_SELL_STOP = OP_SELLSTOP,
  };


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class COrder : public CObject
  {
private:
    int             m_id;
    ENUM_OP_TYPES   m_type;
    
    bool            OrderSelect() { return OrderSelect(m_id, SELECT_BY_TICKET); }
public:
                    COrder(int id);
                    ~COrder();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrder::COrder(int id): m_id(id)
  {
        
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrder::~COrder()
  {
  }
//+------------------------------------------------------------------+
