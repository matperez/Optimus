//+------------------------------------------------------------------+
//|                                                    OrderInfo.mqh |
//|                   Copyright 2009-2013, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#include <Object.mqh>
#include "SymbolInfo.mqh"
//+------------------------------------------------------------------+
//| Class COrderInfo.                                                |
//| Appointment: Class for access to order info.                     |
//|              Derives from class CObject.                         |
//+------------------------------------------------------------------+
class COrderInfo : public CObject
  {
protected:
   ulong            m_ticket;
   ENUM_ORDER_TYPE  m_type;
   datetime         m_expiration;
   double           m_volume_curr;
   double           m_stop_loss;
   double           m_take_profit;
   int              m_magic;
   double           m_open_price;
   datetime         m_open_time;
   string           m_symbol;
   double           m_profit;
   string           m_comment;

public:
                     COrderInfo(void);
                    ~COrderInfo(void);
   bool              IsPending(void) { return !(m_type == OP_BUY || m_type == OP_SELL); }
   double            GetVolume(void) { return m_volume_curr; }
   //--- methods of access to protected data
   ulong             Ticket(void) const { return(m_ticket); }
   //--- fast access methods to the integer order propertyes
   datetime          TimeSetup(void) const;
   ulong             TimeSetupMsc(void) const;
   datetime          TimeDone(void) const;
   ulong             TimeDoneMsc(void) const;
   ENUM_ORDER_TYPE   GetType(void) const { return (ENUM_ORDER_TYPE) m_type; }
   int               GetMagic(void) const { return m_magic; }
   double            GetOpenPrice(void) const { return m_open_price; }
   datetime          GetOpenTime(void) const { return m_open_time; }
   string            GetSymbol(void) const { return m_symbol; }
   double            GetProfit(void) const { return m_profit; }
   ulong             GetTicket(void) const { return m_ticket; }
   string            GetComment(void) const { return m_comment; }
   double            GetTakeProfit(void) const { return m_take_profit; }
   double            GetStopLoss(void) const { return m_stop_loss; }
   string            TypeDescription(void) const;
   string            StateDescription(void) const;
   datetime          TimeExpiration(void) const;
   string            TypeFillingDescription(void) const;
   string            TypeTimeDescription(void) const;
   long              Magic(void) const;
   long              PositionId(void) const;
   //--- fast access methods to the double order propertyes
   double            VolumeInitial(void) const;
   double            VolumeCurrent(void) const;
   double            PriceOpen(void) const;
   double            StopLoss(void) const;
   double            TakeProfit(void) const;
   double            PriceCurrent(void) const;
   double            PriceStopLimit(void) const;
   //--- fast access methods to the string order propertyes
   string            Symbol(void) const;
   string            Comment(void) const;
   //--- access methods to the API MQL5 functions
   bool              InfoInteger(const ENUM_ORDER_PROPERTY_INTEGER prop_id,long &var) const;
   bool              InfoDouble(const ENUM_ORDER_PROPERTY_DOUBLE prop_id,double &var) const;
   bool              InfoString(const ENUM_ORDER_PROPERTY_STRING prop_id,string &var) const;
   //--- info methods
   string            FormatType(string &str,const uint type) const;
   string            FormatStatus(string &str,const uint status) const;
   string            FormatTypeFilling(string &str,const uint type) const;
   string            FormatTypeTime(string &str,const uint type) const;
   string            FormatOrder(string &str) const;
   string            FormatPrice(string &str,const double price_order,const double price_trigger,const uint digits) const;
   //--- method for select order
   bool              Select(void);
   bool              Select(const ulong ticket);
   bool              SelectByIndex(const int index);
   //--- addition methods
   void              StoreState(void);
   bool              CheckState(void);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
COrderInfo::COrderInfo(void) : m_ticket(ULONG_MAX),
                               m_type(WRONG_VALUE),
                               m_expiration(0),
                               m_volume_curr(0.0),
                               m_stop_loss(0.0),
                               m_take_profit(0.0)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
COrderInfo::~COrderInfo(void)
  {
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TIME_SETUP"                        |
//+------------------------------------------------------------------+
datetime COrderInfo::TimeSetup(void) const
  {
   return((datetime)OrderGetInteger(ORDER_TIME_SETUP));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TIME_SETUP_MSC"                    |
//+------------------------------------------------------------------+
ulong COrderInfo::TimeSetupMsc(void) const
  {
   return(OrderGetInteger(ORDER_TIME_SETUP_MSC));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TIME_DONE"                         |
//+------------------------------------------------------------------+
datetime COrderInfo::TimeDone(void) const
  {
   return((datetime)OrderGetInteger(ORDER_TIME_DONE));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TIME_DONE_MSC"                     |
//+------------------------------------------------------------------+
ulong COrderInfo::TimeDoneMsc(void) const
  {
   return(OrderGetInteger(ORDER_TIME_DONE_MSC));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TYPE"                              |
//+------------------------------------------------------------------+
//ENUM_ORDER_TYPE COrderInfo::OrderType(void) const
//  {
//   return((ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE));
//  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TYPE" as string                    |
//+------------------------------------------------------------------+
string COrderInfo::TypeDescription(void) const
  {
   string str;
//---
   return(FormatType(str,OrderType()));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TIME_EXPIRATION"                   |
//+------------------------------------------------------------------+
datetime COrderInfo::TimeExpiration(void) const
  {
   return((datetime)OrderGetInteger(ORDER_TIME_EXPIRATION));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_MAGIC"                             |
//+------------------------------------------------------------------+
long COrderInfo::Magic(void) const
  {
   return(OrderGetInteger(ORDER_MAGIC));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_VOLUME_INITIAL"                    |
//+------------------------------------------------------------------+
double COrderInfo::VolumeInitial(void) const
  {
   return(OrderGetDouble(ORDER_VOLUME_INITIAL));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_VOLUME_CURRENT"                    |
//+------------------------------------------------------------------+
double COrderInfo::VolumeCurrent(void) const
  {
   return(OrderGetDouble(ORDER_VOLUME_CURRENT));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_PRICE_OPEN"                        |
//+------------------------------------------------------------------+
double COrderInfo::PriceOpen(void) const
  {
   return(OrderGetDouble(ORDER_PRICE_OPEN));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_SL"                                |
//+------------------------------------------------------------------+
double COrderInfo::StopLoss(void) const
  {
   return(OrderGetDouble(ORDER_SL));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_TP"                                |
//+------------------------------------------------------------------+
double COrderInfo::TakeProfit(void) const
  {
   return(OrderGetDouble(ORDER_TP));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_PRICE_CURRENT"                     |
//+------------------------------------------------------------------+
double COrderInfo::PriceCurrent(void) const
  {
   return(OrderGetDouble(ORDER_PRICE_CURRENT));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_PRICE_STOPLIMIT"                   |
//+------------------------------------------------------------------+
double COrderInfo::PriceStopLimit(void) const
  {
   return(OrderGetDouble(ORDER_PRICE_STOPLIMIT));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_SYMBOL"                            |
//+------------------------------------------------------------------+
string COrderInfo::Symbol(void) const
  {
   return(OrderGetString(ORDER_SYMBOL));
  }
//+------------------------------------------------------------------+
//| Get the property value "ORDER_COMMENT"                           |
//+------------------------------------------------------------------+
string COrderInfo::Comment(void) const
  {
   return(OrderGetString(ORDER_COMMENT));
  }
//+------------------------------------------------------------------+
//| Access functions OrderGetInteger(...)                            |
//+------------------------------------------------------------------+
bool COrderInfo::InfoInteger(const ENUM_ORDER_PROPERTY_INTEGER prop_id,long &var) const
  {
   return(OrderGetInteger(prop_id,var));
  }
//+------------------------------------------------------------------+
//| Access functions OrderGetDouble(...)                             |
//+------------------------------------------------------------------+
bool COrderInfo::InfoDouble(const ENUM_ORDER_PROPERTY_DOUBLE prop_id,double &var) const
  {
   return(OrderGetDouble(prop_id,var));
  }
//+------------------------------------------------------------------+
//| Access functions OrderGetString(...)                             |
//+------------------------------------------------------------------+
bool COrderInfo::InfoString(const ENUM_ORDER_PROPERTY_STRING prop_id,string &var) const
  {
   return(OrderGetString(prop_id,var));
  }
//+------------------------------------------------------------------+
//| Converts the order type to text                                  |
//+------------------------------------------------------------------+
string COrderInfo::FormatType(string &str,const uint type) const
  {
//--- clean
   str="";
//--- see the type
   switch(type)
     {
      case ORDER_TYPE_BUY            : str="buy";             break;
      case ORDER_TYPE_SELL           : str="sell";            break;
      case ORDER_TYPE_BUY_LIMIT      : str="buy limit";       break;
      case ORDER_TYPE_SELL_LIMIT     : str="sell limit";      break;
      case ORDER_TYPE_BUY_STOP       : str="buy stop";        break;
      case ORDER_TYPE_SELL_STOP      : str="sell stop";       break;

      default:
         str="unknown order type "+(string)type;
         break;
     }
//--- return the result
   return(str);
  }
//+------------------------------------------------------------------+
//| Converts the order status to text                                |
//+------------------------------------------------------------------+
string COrderInfo::FormatStatus(string &str,const uint status) const
  {
//--- clean
   str="";
//--- see the type
   switch(status)
     {
      //case ORDER_STATE_STARTED       : str="started";            break;
      //case ORDER_STATE_PLACED        : str="placed";             break;
      //case ORDER_STATE_CANCELED      : str="canceled";           break;
      //case ORDER_STATE_PARTIAL       : str="partial";            break;
      //case ORDER_STATE_FILLED        : str="filled";             break;
      //case ORDER_STATE_REJECTED      : str="rejected";           break;
      //case ORDER_STATE_EXPIRED       : str="expired";            break;
//      case ORDER_STATE_REQUEST_ADD   : str="request adding";     break;
//      case ORDER_STATE_REQUEST_MODIFY: str="request modifying";  break;
//      case ORDER_STATE_REQUEST_CANCEL: str="request cancelling"; break;

      default:
         str="unknown order status "+(string)status;
         break;
     }
//--- return the result
   return(str);
  }
//+------------------------------------------------------------------+
//| Converts the order parameters to text                            |
//+------------------------------------------------------------------+
string COrderInfo::FormatOrder(string &str) const
  {
   string      type,price;
   CSymbolInfo symbol;
//--- set up
   symbol.Name(Symbol());
   int digits=symbol.Digits();
//--- form the order description
   str=StringFormat("#%I64u %s %s %s",
                    Ticket(),
                    FormatType(type,OrderType()),
                    DoubleToString(VolumeInitial(),2),
                    Symbol());
//--- receive the price of the order
   FormatPrice(price,PriceOpen(),PriceStopLimit(),digits);
//--- if there is price, write it
   if(price!="")
     {
      str+=" at ";
      str+=price;
     }
//--- return the result
   return(str);
  }
//+------------------------------------------------------------------+
//| Converts the order prices to text                                |
//+------------------------------------------------------------------+
string COrderInfo::FormatPrice(string &str,const double price_order,const double price_trigger,const uint digits) const
  {
   string price,trigger;
//--- clean
   str="";
//--- Is there its trigger price?
   if(price_trigger)
     {
      price  =DoubleToString(price_order,digits);
      trigger=DoubleToString(price_trigger,digits);
      str    =StringFormat("%s (%s)",price,trigger);
     }
   else
      str=DoubleToString(price_order,digits);
//--- return the result
   return(str);
  }
//+------------------------------------------------------------------+
//| Selecting a order to access                                      |
//+------------------------------------------------------------------+
bool COrderInfo::Select(void)
  {
   return(OrderSelect(m_ticket, SELECT_BY_TICKET));
  }
//+------------------------------------------------------------------+
//| Selecting a order to access                                      |
//+------------------------------------------------------------------+
bool COrderInfo::Select(const ulong ticket)
  {
   if(OrderSelect(ticket, SELECT_BY_TICKET))
     {
      m_ticket=ticket;
      StoreState();
      return(true);
     }
   m_ticket=ULONG_MAX;
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Select an order on the index                                     |
//+------------------------------------------------------------------+
bool COrderInfo::SelectByIndex(const int index)
  {
    int ticket = 0;
    if (OrderSelect(index, SELECT_BY_POS)) 
    {
        ticket = OrderTicket();
    }
   if(ticket==0)
      return(false);
//---
   return(Select(ticket));
  }
//+------------------------------------------------------------------+
//| Stored order's current state                                     |
//+------------------------------------------------------------------+
void COrderInfo::StoreState(void)
{
/*
OrderClosePrice(), 
OrderCloseTime(), 
OrderComment(), 
OrderCommission(), 
OrderPrint(), 
OrderSwap(), 
*/
   m_type = (ENUM_ORDER_TYPE) OrderType();
   m_expiration = OrderExpiration();
   m_volume_curr = OrderLots();
   m_stop_loss  = OrderStopLoss();
   m_take_profit= OrderTakeProfit();
   m_magic = OrderMagicNumber();
   m_open_price = OrderOpenPrice();
   m_open_time = OrderOpenTime();
   m_symbol = OrderSymbol();
   m_profit = OrderProfit();
   m_ticket = OrderTicket();
   m_comment = OrderComment();
}
//+------------------------------------------------------------------+
//| Check order change                                               |
//+------------------------------------------------------------------+
bool COrderInfo::CheckState(void)
  {
   if(m_type==OrderType() && 
      m_expiration ==TimeExpiration() &&
      m_volume_curr==VolumeCurrent() &&
      m_stop_loss==StopLoss() && 
      m_take_profit==TakeProfit())
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
