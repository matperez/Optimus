//+------------------------------------------------------------------+
//|                                         ClusterIndicatorTest.mq4 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                                              http://www.mql4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, MetaQuotes Software Corp."
#property link      "http://www.mql4.com"
#property version   "1.00"
#property strict

#include "SymbolInfo.mqh"
#include "ClusterIndicator.mqh";

//--- input parameters
input int      gPricePeriod = 1000;
input int      gTimePeriod = 600;
input int      gClusterCount = 100;
input int      gTimer = 60;

CClusterIndicator *pClusterIndicator;
CSymbolInfo *pSymbol;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    int clusters[];
    Print("OnInit");
    EventSetTimer(gTimer);
    pSymbol = new CSymbolInfo();
    pSymbol.Name(_Symbol); 
    pClusterIndicator = new CClusterIndicator(pSymbol, gTimePeriod, gPricePeriod, gClusterCount);
    ArrayResize(clusters, gClusterCount*2);
    pClusterIndicator.GetClusters(clusters);
    for(int i=0; i < gClusterCount*2; i++) {
        Print(i, ": ", clusters[i], ", ");
    }
    return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//    EventKillTimer();
    delete pSymbol;
    delete pClusterIndicator;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
   
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
//---
    Print("OnTimer");
    int clusters[];
    ArrayResize(clusters, gClusterCount*2);
    pClusterIndicator.GetClusters(clusters);
//    for(int i=0; i < gClusterCount*2; i++) {
//        Print(i, ": ", clusters[i], ", ");
//    }
   
}
//+------------------------------------------------------------------+
