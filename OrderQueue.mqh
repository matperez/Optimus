//+------------------------------------------------------------------+
//|                                                   CCOrderQueue.mqh |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <Object.mqh>
#include <Arrays\List.mqh>
#include "OrderInfo.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class COrderQueue : public CObject
{
private:

    // �������� ������� �������
    double m_sell_size;
    double m_buy_size;
    double m_sell_stop_size;
    double m_buy_stop_size;
    
    // �������� ���������� �������
    int m_total_sell;
    int m_total_buy;
    int m_total_sell_stop;
    int m_total_buy_stop;
    
    // �������� �������� �����
    int m_counters[3];
    int m_counters_old[3];
    
    COrderInfo* m_last_buy;
    COrderInfo* m_last_sell;
    
    CList* m_pOrderList;
    
    void ZeroCounters();

public:
    COrderQueue();
    ~COrderQueue();
    
    void Update();
    
    CList* GetList();
    
    double GetSellSize();
    double GetSellStopSize();
    double GetBuySize();
    double GetBuyStopSize();
    
    COrderInfo* GetLastBuy();
    COrderInfo* GetLastSell();
    
    int GetTotalSell();
    int GetTotalBuy();
    int GetTotalSellStop();
    int GetTotalBuyStop();
    
    bool IsSeriesEnded();
    bool HasPendingOrders();
};

//+------------------------------------------------------------------+
//| ������� ������� � ������� ���������� �������                     |
//+------------------------------------------------------------------+
bool COrderQueue::HasPendingOrders(void)
{
    return m_pOrderList.Total() > 0 && m_pOrderList.Total() != m_total_buy + m_total_sell;
}

//+------------------------------------------------------------------+
//| ������ �� ��������� �������� ����� �� �������                    |
//+------------------------------------------------------------------+
COrderInfo* COrderQueue::GetLastBuy()
{
    return m_last_buy;
}

//+------------------------------------------------------------------+
//| ������ �� ��������� �������� ����� �� �������                    |
//+------------------------------------------------------------------+
COrderInfo* COrderQueue::GetLastSell()
{
    return m_last_sell;
}

//+------------------------------------------------------------------+
//| ������� ����, ��� ����� ������ �����������                       |
//+------------------------------------------------------------------+
bool COrderQueue::IsSeriesEnded(void)
{
    if (ArrayCompare(m_counters, m_counters_old) != 0) {
        if ((m_counters[1] != 0  && m_counters[1] < m_counters_old[1]) 
        || (m_counters[2] != 0  && m_counters[2] < m_counters_old[2])) {
            return true;
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| ���������� ���������� ���� �������� ������� �� �������           |
//+------------------------------------------------------------------+
int COrderQueue::GetTotalBuy(void)
{
    return m_total_buy;
}

//+------------------------------------------------------------------+
//| ���������� ���������� ���� �������� ������� �� �������           |
//+------------------------------------------------------------------+
int COrderQueue::GetTotalSell(void)
{
    return m_total_sell;
}

//+------------------------------------------------------------------+
//| ���������� ���������� ���� ���������� ������� �� �������         |
//+------------------------------------------------------------------+
int COrderQueue::GetTotalSellStop(void)
{
    return m_total_sell_stop;
}

//+------------------------------------------------------------------+
//| ���������� ���������� ���� ���������� ������� �� �������         |
//+------------------------------------------------------------------+
int COrderQueue::GetTotalBuyStop(void)
{
    return m_total_buy_stop;
}

//+------------------------------------------------------------------+
//| ���������� ������ ���� �������� ������� �� �������               |
//+------------------------------------------------------------------+
double COrderQueue::GetBuySize(void)
{
    return m_buy_size;
}

//+------------------------------------------------------------------+
//| ���������� ������ ���� �������� ������� �� �������               |
//+------------------------------------------------------------------+
double COrderQueue::GetSellSize(void)
{
    return m_sell_size;
}

//+------------------------------------------------------------------+
//| ���������� ������ ���� ���������� ������� �� �������             |
//+------------------------------------------------------------------+
double COrderQueue::GetBuyStopSize(void)
{
    return m_buy_stop_size;
}

//+------------------------------------------------------------------+
//| ���������� ������ ���� ���������� ������� �� �������             |
//+------------------------------------------------------------------+
double COrderQueue::GetSellStopSize(void)
{
    return m_sell_stop_size;
}

//+------------------------------------------------------------------+
//| ��������� �������� �������                                       |
//+------------------------------------------------------------------+
void COrderQueue::Update()
{
    int total, pos, magic;
    COrderInfo* order;
    
    ZeroCounters();
    
    m_pOrderList.Clear();
    
    m_last_buy = NULL;
    m_last_sell = NULL;
    
    ArrayCopy(m_counters_old, m_counters);
    
    total = OrdersTotal();
    
    for (pos = 0; pos < total; pos++) {
        order = new COrderInfo();
        if (order.SelectByIndex(pos)) {
            m_pOrderList.Add(order);
            
            if (order.GetType() == OP_BUY) {
                m_total_buy += 1;
                m_buy_size += order.GetVolume();
                m_last_buy = order;
            } else if (order.GetType() == OP_SELL) {
                m_total_sell += 1;
                m_sell_size += order.GetVolume();
                m_last_sell = order;
            } else if (order.GetType() == OP_SELLSTOP) {
                m_total_sell_stop += 1;
                m_sell_stop_size += order.GetVolume();
            } else if (order.GetType() == OP_BUYSTOP) {
                m_total_buy_stop += 1;
                m_buy_stop_size += order.GetVolume();
            }

            if (!order.IsPending()) {
                magic = order.GetMagic();
                m_counters[magic] += 1;
            }
            
        }
    }
}
  
//+------------------------------------------------------------------+
//| ���������� ��������� �� ������ �������                           |
//+------------------------------------------------------------------+
CList* COrderQueue::GetList(void)
{
    return m_pOrderList;
}

//+------------------------------------------------------------------+
//| �������� �������� �������                                        |
//+------------------------------------------------------------------+
void COrderQueue::ZeroCounters(void)
{
    m_total_buy = 0;
    m_total_sell = 0;
    m_total_sell_stop = 0;
    m_total_buy_stop = 0;
    
    m_sell_size = 0;
    m_buy_size = 0;
    m_sell_stop_size = 0;
    m_buy_stop_size = 0;
    
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrderQueue::COrderQueue()
{
    m_pOrderList = new CList();
    ArrayInitialize(m_counters, 0);
    Update();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
COrderQueue::~COrderQueue()
{
    delete m_pOrderList;
}
//+------------------------------------------------------------------+
