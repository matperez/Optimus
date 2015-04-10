//+------------------------------------------------------------------+
//|                                             ClusterIndicator.mqh |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict

#include <Object.mqh>
#include "SymbolInfo.mqh"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CClusterIndicator : public CObject
{

private:
    int m_time_period;
    int m_price_period;
    int m_cluster_count;
    int m_clusters[];
    
    ENUM_TIMEFRAMES m_time_frame;
    
    CSymbolInfo *m_symbol;
    
    int GetBarCount();
    
public:
     CClusterIndicator(CSymbolInfo *symbol, int timePeriod, int pricePeriod, int clusterCount);
    ~CClusterIndicator();
    void Update();
    void SetTimeframe(ENUM_TIMEFRAMES timeframe);
    void GetClusters(int &clusters[]);
    double GetUpperLevel(double price);
    double GetLowerLevel(double price);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CClusterIndicator::GetUpperLevel(double price)
{
    Update();
    return 1.0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CClusterIndicator::GetLowerLevel(double price)
{
    Update();
    return 1.0;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CClusterIndicator::GetClusters(int &clusters[])
{
    Update();
    ArrayCopy(clusters, m_clusters, 0, 0, WHOLE_ARRAY);
}
//+------------------------------------------------------------------+
//| ¬озвращает количество баров в серии на заданном таймфрейме       |
//+------------------------------------------------------------------+
int CClusterIndicator::GetBarCount(void)
{
    switch(m_time_frame) 
    {
        case PERIOD_M1:
            return round(m_time_period/60);
        case PERIOD_M5:
            return round(m_time_frame/60/5);    
        case PERIOD_M15:
            return round(m_time_frame/60/15);    
        case PERIOD_M30:
            return round(m_time_frame/60/30);    
        case PERIOD_H1:
            return round(m_time_frame/3600);
        default:
            return 0;    
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CClusterIndicator::SetTimeframe(ENUM_TIMEFRAMES timeframe) { m_time_frame = timeframe; }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CClusterIndicator::Update()
{
    int barCount, i, j, jMin, jMax;
    double high, low, max, min, current, clusterSize;
    ArrayFill(m_clusters, 0, m_cluster_count*2, 0);
    barCount = GetBarCount();
    Print("bar count: ", barCount);
    // текуща€ цена
    current = Ask;
    Print("current: ", current, ", price period: ", m_price_period);
    // верхн€€ и нижн€€ границы диапазона рассчета
    max = current + m_price_period * Point;
    min = current - m_price_period * Point;
    Print("min: ", min, ", max: ", max);
    // размер кластера
    clusterSize = (max - min)/(2*m_cluster_count);
    Print("cluster size: ", clusterSize);
    for(i = 0; i < barCount; i++) {
        // верхн€€ и нижн€€ границы текущего бара
        high = iHigh(m_symbol.Name(), m_time_frame, i);
        low = iLow(m_symbol.Name(), m_time_frame, i);
        // если бар находитс€ за границей нашего диапазона
        if (low <= max && high >= min ) {
            jMax = MathRound((high - min)/clusterSize);
            jMin = MathRound((low - min)/clusterSize);
//            Print("j-min: ", jMin, ", j-max: ", jMax);
            for (j = jMin; j < jMax; j++) {
                m_clusters[j]++;
            }
        }
    }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CClusterIndicator::CClusterIndicator(CSymbolInfo *symbol, int timePeriod, int pricePeriod, int clusterCount): 
    m_time_frame(PERIOD_M1)
{
    m_symbol = symbol;
    m_time_period = timePeriod;
    m_price_period = pricePeriod;
    m_cluster_count = clusterCount;
    ArrayResize(m_clusters, m_cluster_count * 2);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CClusterIndicator::~CClusterIndicator()
{
}
//+------------------------------------------------------------------+
