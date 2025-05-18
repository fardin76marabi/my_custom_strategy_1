//+------------------------------------------------------------------+
//|                                                inigma_sFinal.mq5 |
//|                                                    Fardin Marabi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Fardin Marabi"
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |

/*

Strategy: its like flag base 1 but we find a strong leg in higher tf and calculate the pullback in lower tf 
when a fractal is recognized AND Considering 0 ta 1000 ideas in it

*/

#include<Trade/Trade.mqh>
CTrade trade;

CTrade                  m_trade;      
CPositionInfo           m_position; 

//Global Variables
static input ENUM_TIMEFRAMES M1=PERIOD_M1;
static input ENUM_TIMEFRAMES M5=PERIOD_M5;

static input ENUM_TIMEFRAMES M15=PERIOD_M15;
static input ENUM_TIMEFRAMES H1=PERIOD_H1;
static input ENUM_TIMEFRAMES H4=PERIOD_H4;
static input ENUM_TIMEFRAMES D1=PERIOD_D1;
static input ENUM_TIMEFRAMES W1=PERIOD_W1;
static input ENUM_TIMEFRAMES MN1=PERIOD_MN1;


input group "ZIG ZAG SETTINGS"
//input int Depth=12;
input int Depth=3;
input int Deviation=5;
input int Backstep=3;


input group "ORDERS SETTINGS"
input double Volume=0.01;
input double Stop_Loss_Coeff=1;
input double Take_Profit_Coeff=0.5;
input int Hours_Expire=10;
input double riskPerTrade=1;
input double RR=3;


#resource "\\Indicators\\Examples\\ZigZag.ex5"
int zz_handle_higher_TF;
int zz_handle_lower_TF;


// zz higher time frame
int Collect_Values_higherTF=6;
double ZZ_Values_higherTF[];
datetime ZZ_Times_higherTF[];


// zz lower time frame
int Collect_Values_lowerTF=6;
double ZZ_Values_lowerTF[];
datetime ZZ_Times_lowerTF[];


// fractal settings
int fracDef;

double fracUpArray[];
double fracDownArray[];
double fracDownValue;

// ema 
double myEMA[];
int emaDef;


// for controlling the position number for each flag;

//signal_value=start_of_bar; end_value=start_of_pullback; signal_time=start_of_bar_time

double bar_leg;
double pullback_leg;

double start_of_bar=-1; // begin of the flag (for signal)
datetime start_of_bar_time;

double start_of_pullback=-1;
datetime start_of_pllback_time;

double end_of_pllback=-1;
datetime end_of_pllback_time;

double last_signal=-1;



int flag=0;

double stop_loss=0;



// optimization parameters
input group "OPTIMIZATION PARAMETERS"
input int optimization_retrace=0;
double min_retrace=0.1;
double max_retrace=0.55;//0.3 works

input int optimization_alpha_recover=7;
double alpha_good_recover=1.2; //1.4 works 

input int optimization_alpha_strong_bar=0;
double alpha_strong_bar=0.7; // 0.7 works

input int optimization_alpha_pullback_ratio=0;
double alpha_pullback_ratio=1.5; // bar_length/pullback_size


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   // fractal initialization
   //ArraySetAsSeries(fracUpArray,true);
   //ArraySetAsSeries(fracDownArray,true);
   
   //fracDef=iFractals(_Symbol,lowerTF);
   
   
   // Zig Zag initialization
   zz_handle_lower_TF=iCustom(_Symbol,M1,"::Indicators\\Examples\\ZigZag.ex5",Depth,Deviation,Backstep);
   zz_handle_higher_TF=iCustom(_Symbol,M15,"::Indicators\\Examples\\ZigZag.ex5",Depth,Deviation,Backstep);
   
   ArrayResize(ZZ_Values_lowerTF,Collect_Values_lowerTF,0);
   ArrayResize(ZZ_Times_lowerTF,Collect_Values_lowerTF,0);
   
   ArrayResize(ZZ_Values_higherTF,Collect_Values_higherTF,0);
   ArrayResize(ZZ_Times_higherTF,Collect_Values_higherTF,0);
   
   // ema setup
   emaDef=iMA(_Symbol,H4,50,0,MODE_EMA,PRICE_CLOSE); //period=20
   
   
   // optimizing retrace parameters
   //optimizing_retrace();
   //optimizing_good_recover();
   //optimizing_strong_bar();
   
//---
   return(INIT_SUCCEEDED);
  }
  
  
// optimization functions
void optimizing_strong_bar(){
   if (optimization_alpha_strong_bar==0){
      alpha_strong_bar=0.3;
   }
   else if (optimization_alpha_strong_bar==1){
      alpha_strong_bar=0.4;
   }
   else if (optimization_alpha_strong_bar==2){
      alpha_strong_bar=0.5;
   }
   else if (optimization_alpha_strong_bar==4){
      alpha_strong_bar=0.6;
   }
   else if (optimization_alpha_strong_bar==4){
      alpha_strong_bar=0.7;
   }
   else if (optimization_alpha_strong_bar==5){
      alpha_strong_bar=0.8;
   }
   else if (optimization_alpha_strong_bar==6){
      alpha_strong_bar=0.9;
   }
   else if (optimization_alpha_strong_bar==7){
      alpha_strong_bar=1;
   }
   
}

void optimizing_good_recover(){
   if (optimization_alpha_recover==0){
      alpha_good_recover=1.0;
   }
   else if (optimization_alpha_recover==1){
      alpha_good_recover=1.1;
   }
   else if (optimization_alpha_recover==2){
      alpha_good_recover=1.2;
   }
   else if (optimization_alpha_recover==3){
      alpha_good_recover=1.3;
   }
   else if (optimization_alpha_recover==4){
      alpha_good_recover=1.4;
   }
   else if (optimization_alpha_recover==5){
      alpha_good_recover=1.5;
   }
   else if (optimization_alpha_recover==6){
      alpha_good_recover=1.6;
   }
   else if (optimization_alpha_recover==7){
      alpha_good_recover=1.7;
   }
   else if (optimization_alpha_recover==8){
      alpha_good_recover=1.8;
   }
   else if (optimization_alpha_recover==9){
      alpha_good_recover=1.9;
   }
}
void optimizing_retrace(){
   // optimization part
   if (optimization_retrace==0){
      min_retrace=0.1;
      max_retrace=0.5;
   }
   else if (optimization_retrace==1){
      min_retrace=0.2;
      max_retrace=0.5;
   }
   else if (optimization_retrace==2){
      min_retrace=0.3;
      max_retrace=0.5;
   }
   else if (optimization_retrace==3){
      min_retrace=0.4;
      max_retrace=0.5;
   }
   
   else if (optimization_retrace==4){
      min_retrace=0.1;
      max_retrace=0.6;
   }
   else if (optimization_retrace==5){
      min_retrace=0.2;
      max_retrace=0.6;
   }
   else if (optimization_retrace==6){
      min_retrace=0.3;
      max_retrace=0.6;
   }
   else if (optimization_retrace==7){
      min_retrace=0.3;
      max_retrace=0.6;
   }
   else if (optimization_retrace==8){
      min_retrace=0.4;
      max_retrace=0.6;
   }
   else if (optimization_retrace==9){
      min_retrace=0.5;
      max_retrace=0.6;
   }
   
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
double Signal_Value;

void OnTick()
  {
//---
   static int last_bar_higherTF=0;//updating higher Time Frame zig zag values 
   int bars_higherTF=iBars(_Symbol,M15);
   
   if(last_bar_higherTF!=bars_higherTF){ //updating higher Time Frame zig zag values 
      Collecting_ZZ_Values(zz_handle_higher_TF,Collect_Values_higherTF,M15,ZZ_Values_higherTF,ZZ_Times_higherTF);
   }
   
   
   static int last_bar_lowerTF=0;//updating lower Time Frame zig zag values 
   int bars_lowerTF=iBars(_Symbol,M1);
   
   if(last_bar_lowerTF!=bars_lowerTF){ //updating lower time frame zig zag and checking signals
      Collecting_ZZ_Values(zz_handle_lower_TF,Collect_Values_lowerTF,M1,ZZ_Values_lowerTF,ZZ_Times_lowerTF);
      last_bar_lowerTF=bars_lowerTF;
      
      ArraySetAsSeries(myEMA,true);
      CopyBuffer(emaDef,0,0,3,myEMA); // last ema's for last 3 candel is in this array
      
      
      double PriceArray[];
   
   
      //Sorting data
      ArraySetAsSeries(PriceArray,true);
   
      //define ATR
      int ATRDef=iATR(NULL,M15,14);   
      
      //define data and store result
      CopyBuffer(ATRDef,0,0,3,PriceArray);
   
      //get value of current data
      double ATRValue=NormalizeDouble(PriceArray[0],_Digits);
      //check_for_exit(M15); // close signals based on ema divergence
      
      
      Spotting_Patterns();
      int signal=signal_checker(M15);
      
      //check_for_exit(M15,20);
      
      if((signal==1) && (start_of_bar!=last_signal)){  //Buying order // here is ?? because we check candels date so the second condition is extra
         
         last_signal=start_of_bar;
         
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
         
         //
         //double sl=start_of_bar-ATRValue;
         double sl=NormalizeDouble(start_of_pullback-(0.80*MathAbs(start_of_bar-start_of_pullback)),_Digits); //
         
         double distanceEntryFromSL=entry-sl;
         //double tp=NormalizeDouble(entry+(RR*distanceEntryFromSL),_Digits); // RR*sl distance
         double tp=NormalizeDouble(end_of_pllback+(0.70*MathAbs(start_of_bar-start_of_pullback)),_Digits);
         
         double stoplossPoint=distanceEntryFromSL*MathPow(10,_Digits); //?? is *mathpow correct?
         double lotSize=volume_calculator(stoplossPoint);
         
         //trade.Buy(lotSize,NULL,entry,sl,tp);
         
         //trade.Buy(lotSize,NULL,entry,stop_loss,tp); // better for buys
      }
      
      
      
      if((signal==2) && (start_of_bar!=last_signal)){  //Selling order && ZZ_Values_higherTF[0]!=Signal_Value
         
         last_signal=start_of_bar;
         
         double entry=SymbolInfoDouble(_Symbol,SYMBOL_BID);
         
         //
         //double sl=start_of_bar+ATRValue;
         //double sl=NormalizeDouble(stop_loss+MathAbs(ATRValue),_Digits);
         //double sl=NormalizeDouble(end_of_pllback+MathAbs(ATRValue),_Digits);
         //double sl=NormalizeDouble(entry+(2*MathAbs(ATRValue)),_Digits);
         
         double sl=NormalizeDouble(0.80*MathAbs(start_of_bar-start_of_pullback)+start_of_pullback,_Digits);
         //double sl=NormalizeDouble(end_of_pllback,_Digits);
         double distanceEntryFromSL=sl-entry;
         
         
         
         double tp=NormalizeDouble(entry-(RR*distanceEntryFromSL),_Digits); // RR*sl distance
         //double tp=NormalizeDouble(end_of_pllback-(0.70*MathAbs(start_of_bar-start_of_pullback)),_Digits);
         
         
         double distanceEntryFromTP=entry-tp;
         
         double stoplossPoint=distanceEntryFromSL*MathPow(10,_Digits); //?? is *mathpow correct?
         double lotSize=volume_calculator(stoplossPoint);
         
         Print("entry ",entry);
         Print("start_of_bar ",start_of_bar);
         printf("date of bar ",start_of_bar_time);
         Print("distanceEntryFromSL ",distanceEntryFromSL);
         
         trade.Sell(lotSize,NULL,entry,sl,tp);
         //trade.Sell(lotSize,NULL,entry,stop_loss,tp);
         /*if (distanceEntryFromTP>=distanceEntryFromSL){
            trade.Sell(lotSize,NULL,entry,sl,tp);
         }*/
      }
      
      
   }
   
  }
//+------------------------------------------------------------------+


int Spotting_Patterns(){
   //0 = No Signal
   //1 = Buy
   //2 = Sell
   
   // higher tf zz values
   double first_value_higherTF=ZZ_Values_higherTF[0];  //recent swing
   double second_value_higherTF=ZZ_Values_higherTF[1]; //one before recent swing
   double third_value_higherTF=ZZ_Values_higherTF[2]; //two before recent swing
   double forth_value_higherTF=ZZ_Values_higherTF[3];  //recent swing
   double fifth_value_higherTF=ZZ_Values_higherTF[4]; //one before recent swing
   
   
   datetime first_date_higherTF=ZZ_Times_higherTF[0]; // date of last swing low
   datetime second_date_higherTF=ZZ_Times_higherTF[1]; // date of last swing low
   datetime third_date_higherTF=ZZ_Times_higherTF[2]; // date of last swing low
   datetime forth_date_higherTF=ZZ_Times_higherTF[3]; // date of last swing low
   datetime fifth_date_higherTF=ZZ_Times_higherTF[4]; // date of last swing low
   
   
   double second_leg=MathAbs(first_value_higherTF-second_value_higherTF);
   double first_leg=MathAbs(second_value_higherTF-third_value_higherTF);
   
   
   bar_leg=first_leg;
   pullback_leg=second_leg;
    
   if(trend_finder(first_value_higherTF,second_value_higherTF,third_value_higherTF)==1){ //bullish trend in higher tf
      if(good_pullback(first_leg,second_leg)==1){ //  not a deep pullback lastNCandels(H4,3)==1
         if(true){ // slope and power of pullback is weak slope(first_date_higherTF,second_date_higherTF,second_leg,M15)<=slope(second_date_higherTF,third_date_higherTF,first_leg,M15)
            if(true){//two_candles_signal(M5)==1 near_prz(first_value_higherTF,second_value_higherTF,M1)==1
               if(true){//trend_ema(M5,20)==2 (lastThreeCandels(H4)==1) trend_ema(D1,20)==1
                  if (start_of_bar!=third_value_higherTF){ //trend_finder(third_value_lowerTF,forth_value_lowerTF,fifth_value_lowerTF)==1 
                     if (flag==1){
                        return 0;
                     }
                     
                      
                     start_of_bar=third_value_higherTF;
                     start_of_bar_time=third_date_higherTF;
                     
                     start_of_pullback=second_value_higherTF;
                     start_of_pllback_time=second_date_higherTF;
                     
                     end_of_pllback=first_value_higherTF;
                     end_of_pllback_time=first_date_higherTF;
                     
                     flag=1;
                     
                     stop_loss=start_of_bar;
                  }
                  
               }
            }
         }
      }
   }
   
   else if(trend_finder(first_value_higherTF,second_value_higherTF,third_value_higherTF)==2){ //bearish trend in higher tf
      if(true){ // not a deep pullback  good_pullback(first_leg,second_leg)==1
         if(true){//near_prz(second_value_higherTF,M15)==2 lastNCandels(H4,2)==1 
            if(true){//good_recover(first_date_higherTF,second_date_higherTF,M15)==2
               if(true){ //simple_pullback(first_date_higherTF,second_date_higherTF,third_date_higherTF,M15)
                  if (start_of_bar!=third_value_higherTF){ 
                    
                     if (flag==2){
                        return 0;
                     }
                     
                     start_of_bar=third_value_higherTF;
                     start_of_bar_time=third_date_higherTF;
                     
                     
                     start_of_pullback=second_value_higherTF;
                     start_of_pllback_time=second_date_higherTF;
                     
                     
                     end_of_pllback=first_value_higherTF;
                     end_of_pllback_time=first_date_higherTF;
                     
                     flag=2;
                     
                     stop_loss=start_of_bar;
                     
                     
                  }
                  
               }
            }
         }
      }
   }
   
   
   
   return 0;
}


void check_for_exit(ENUM_TIMEFRAMES tf,int signal_period){
   int ema_signal=trend_ema(tf,signal_period);
   close_reverse_trade(ema_signal);
}


int signal_checker(ENUM_TIMEFRAMES tf){ // check for signal with extra filters

   pattern_validate(tf); // check wheather price is not beyand of pole (in each directions)ss
   
   //shadow_checker(ENUM_TIMEFRAMES tf,int i){ //check shadow size of ith candel in desired tf and compare the size of body and upper shadow
   //takback_last_swing(ENUM_TIMEFRAMES tf){ // we check wheather a good candel is takeback last swing, in pullback phase
   //inside_candel_higherTF(ENUM_TIMEFRAMES tf,int index){//check the signal candel(index=0) is inside the prev candel in Higher TF
   //peneterationHigherTF(int firstCandelIndex, ENUM_TIMEFRAMES tf){ //% of peneteration of second higher tf candel into first one (must be less than special percent)
   
   
   
   if ((flag==1)){
      
      //46% -->(check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==2)   )
      //46% (check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1)
      //int signal=rejection(M15);
      int signal=good_recover(end_of_pllback_time,start_of_pllback_time,M1);
      //int signal=trend_ema(D1,9);
      //int signal=power_in_lowerTF();
      //strong_bar(start_of_pllback_time,start_of_bar_time,M15)==1)
      //int signal=two_candles_signal(M15)==1;
      //int signal=price_in_zone(start_of_pllback_time,start_of_bar_time,tf);
      //int signal=price_in_trend(50,20,1,D1);
      //simple_pullback(end_of_pllback_time,start_of_pllback_time,start_of_bar_time,M15)
      //weak_pullback(start_of_pllback_time,end_of_pllback_time,M1) 
      
      
      /*
      if( (check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==2)  ){ // 
         return signal;
      }*/
      //strong_trend(20,20,M15)==2 /it works
      //close_prz(60,H4)==1 //sell only at near top                   
      
      if((true)&&( true ) ){//  strong_trend(20,20,M15)==2
         if( (true) && (true) ){//simple_pullback(end_of_pllback_time,start_of_pllback_time,start_of_bar_time,M15)==1 
            //stop_loss=start_of_bar;
            flag=0;//reseting the flag engulfing_pattern(3,M1)==2
            //Print("10 Pip*_point is ", 10*_Point);
            return 1;//strong_trend(20,20,H4)==2
            //return signal;
         }
         
         //lastNCandels();
         //takeback_last_swing;
         //reverse_started();// two lower low and lower high
         //distance_from_ema();
      }
      
      
   }
   
   //good setings:
   //(check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==2)  + int signal=price_in_trend(50,20,3,M15) (50,20,1,M15) (50,20,1,H4) (50,20,3,H4) (20,20,1,H4) (20,20,3,H4) (50,20,3,D1)
   
   //(check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==2)
   
   // + good_recover(end_of_pllback_time,start_of_pllback_time,M1)
   
   if ((flag==2)){
   
      //int signal=rejection(M15);
      //int signal=good_recover(end_of_pllback_time,start_of_pllback_time,M1); / it works
      //int signal=trend_ema(D1,20);
      //int signal=power_in_lowerTF();
      //int signal=two_candles_signal(M15)==2;
      //slope(datetime first_date,datetime second_date,double leg_size,ENUM_TIMEFRAMES tf)
      // && (weak_pullback(end_of_pllback_time,start_of_pllback_time,M1)==1)
      //strong_move(start_of_bar_time,start_of_pllback_time,M15)==2 /it works
      //int signal=price_in_trend (20,20,1,H4); //(50,20,3,M15) (50,20,1,M15) (50,20,1,H4) (50,20,3,H4) (20,20,1,H4)
      //(check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==2) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==1)
      //consecutive_candels(2,M15)==2
      //engulfing_pattern(5,M1)==2
      //local_swing(start_of_pullback,6,H4)==2 /it works
      //check_power(2,M15,start_of_pllback_time,start_of_bar_time)==2
      //strong_trend(20,20,M15)==2 /it works
      //close_prz(60,H4)==1 //sell only at near top
      //rejection(M15,1)==2
      
      //strong_move(start_of_bar_time,start_of_pllback_time,M15)==2
      //Trend Strength: If the preceding trend is exhausted??? 
      //Support and Resistance Levels: Overlapping support or resistance levels might prevent the flag pattern from completing. Significant levels can overpower the expected movement from the flag breakout.
      //Moving average crossovers (e.g., the price crossing back above a short-term moving average)
      // check engulfing in start of pullback for detecting exaustion
      // at end of pullback it be below ema 20 and 50 (both !) 
      //a functiom that gets two date and measure wheather a shadow is below the last candels low (in ploe) , if not so it is a strong move
      //check last day candel if its red. check where is the current price if its not near open or low of yesterday candel then sell
      
      //breakout(end_of_pllback_time,start_of_pullback, M15,1)==2
      //pole_N_size(start_of_bar_time,start_of_pllback_time,M15)==2
         //(check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==1) && (check_place_of_leg(start_of_pllback_time,end_of_pllback_time,M15,5)==2)  + int signal=price_in_trend(50,20,3,M15) (50,20,1,M15) (50,20,1,H4) (50,20,3,H4) (20,20,1,H4) (20,20,3,H4) (50,20,3,D1)
      //trend_ema(H4,50)==2
      //breakout(end_of_pllback_time,start_of_pullback, M15,1)==2 &&  strong_move(start_of_bar_time,start_of_pllback_time,M15)==2  
      //range_analyzer(start_of_pllback_time,M15)==2
      
      
      if((true)&&(strong_move(start_of_bar_time,start_of_pllback_time,M15)==2) ){//strong_move(start_of_bar_time,start_of_pllback_time,M15)==2
         if( (check_place_of_leg(start_of_bar_time, start_of_pllback_time,M15,50)==2) && (true) ){//simple_pullback(end_of_pllback_time,start_of_pllback_time,start_of_bar_time,M15)==1
            //stop_loss=start_of_bar;
            flag=0;//reseting the flag engulfing_pattern(3,M1)==2
            //Print("10 Pip*_point is ", 10*_Point);
            return 2;//strong_trend(20,20,H4)==2
         }
         
         //lastNCandels();
         //takeback_last_swing;
         //reverse_started();// two lower low and lower high
         //distance_from_ema();
         
         //considiration lasts long (bad)
         
         // from start of pulback till now, measure upshadows and downshadows and compare (even their bodies or ATR)
         // check first half of pole and second half ---> wheather bodies of bearish gets stronger ?
         
      }
      
      
   }
   
   
   return 0;
}

int range_analyzer(datetime start_of_pull ,ENUM_TIMEFRAMES tf){ // compare bodies of candels in range (more bullish or more bearish)
   int end=-1;
   
   for (int i=0;i<=100;i++){
      
      if (iTime(NULL,tf,i) == start_of_pull){
         end=i;
      }
            
   }
   
   if (end==-1){
      return 0;
   }
   
   double open;
   double close;
   
   double bullsTotal=0;
   double bearsTotal=0;
   
   int numOfReds=0;
   int numOfGreens=0;
   
   for(int i=1;i<end;i++){
      open=iOpen(NULL,tf,i);
      close=iClose(NULL,tf,i);
      if (close>open){
         numOfGreens+=1;
         bullsTotal+=(close-open);
      }
      else{
         numOfReds+=1;
         bearsTotal+=(open-close);
      }
   }
   
   if ((numOfGreens==0) || (numOfReds==0) ){
      return 0;
   }
   double bullsAVG=bullsTotal/numOfGreens;
   double bearsAVG=bearsTotal/numOfReds;
   
   if(bullsAVG>bearsAVG){
      return 1;
   } 
   if (bearsAVG>bullsAVG){
      return 2;
   }
   
   return 0;
}

int pole_N_size(datetime start_of_b,datetime start_of_pull ,ENUM_TIMEFRAMES tf){ //compare first half of pole candels and second half ---> wheather bodies of  gets stronger in the second half
   
   double first_half=0;  // for saving the atr of candels from now to nth candel
   double second_half=0;
   
   int start=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == start_of_b){
         end=i;
      }
      if (iTime(NULL,tf,i) == start_of_pull){
         start=i;
      }
            
   }
   
   if (start==-1 || end==-1){
      return 0;
   }
   
   int n= (end-start)/2;
   if (n==0){
      return 0;
   }
   
   for (int i=start;i<=end;i++){
      if(i<=start+n){ // for first half 
         first_half+=(iOpen(NULL,tf,i)-iClose(NULL,tf,i)); // recent power
         continue;
      }
      second_half+=(iOpen(NULL,tf,i)-iClose(NULL,tf,i));
   }
   
   double recent_power=first_half/n;
   double old_power=second_half/(end-(n+start));
   
   if(old_power<recent_power){
      return 2;
   }
   return 0;
}



int breakout(datetime end_of_pull,double block, ENUM_TIMEFRAMES tf,int break_index){ // check wheather price break the range in the direction of the pole with a good candel
   double last_close=iClose(NULL,tf,break_index); // close of break candel
   double alpha_close=0.7;
   double alpha_atr=1.5;
   
   double low=iLow(NULL,tf,break_index);
   double high=iHigh(NULL,tf,break_index);
   double last_candel_atr=(high-low);
      
   double limit_bullish=low+(alpha_close*last_candel_atr);
   double limit_bearish=high-(alpha_close*last_candel_atr);
   
   //finding index of end of pullback
   int start=break_index;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == end_of_pull){
         end=i;
      }
            
   }
   
   if (start==-1 || end==-1){
      return 0;
   }
   
   //bearish scenario
   if (last_close<=block){// close below the bar(range)      
      if(last_close<=limit_bearish){ // close near low
         if(last_candel_atr>=alpha_atr*atr_calculater(start,end,tf)){ // good atr
            return 2;
         }
      }
   }
   return 0;
}

double atr_calculater(int begin,int end,ENUM_TIMEFRAMES tf){

   int total_candels=0;
   double total_atr=0;
   double open;
   double close;
   double low;
   double high;
   
   for (int i=begin;i<=end;i++){
      total_candels +=1;
      
      open=iOpen(NULL,tf,i);
      close=iClose(NULL,tf,i);
      low=iLow(NULL,tf,i);
      high=iHigh(NULL,tf,i);
      total_atr+=MathAbs(high-low);
   }
   
   return total_atr/total_candels;
}

int overlap_finder(datetime first_date,datetime second_date,ENUM_TIMEFRAMES tf){// find gap in a move
   
   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         end=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   double totalCandels=MathAbs(end-begin); 
   
   int bullish_overlap=0;
   int bearish_overlap=0;
   //
   
   for (int i=begin;i<=end;i++){
   
      double candelBody=(iClose(NULL,tf,i)-iOpen(NULL,tf,i));
      double open=iOpen(NULL,tf,i);
      double close=iClose(NULL,tf,i);
      double low=iLow(NULL,tf,i);
      double high=iHigh(NULL,tf,i);
      
      double candelBody2=(iClose(NULL,tf,i+1)-iOpen(NULL,tf,i+1));
      double close2=iClose(NULL,tf,i+1);
      double open2=iOpen(NULL,tf,i+1);
      double low2=iLow(NULL,tf,i+1);
      double high2=iHigh(NULL,tf,i+1);
      
      if (low<=low2){
         bearish_overlap+=1;
      }
      if (high>=high2){
         bullish_overlap+=1;
      }
      
      
   }
   
   
   /*if(bearish_overlap<=2){
      return 1;
   }*/
   
   if(bullish_overlap<=2){
      return 1;
   }
   
   
   return 0;
}

int gap_finder(datetime first_date,datetime second_date,ENUM_TIMEFRAMES tf){// find gap in a move
   
   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         end=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   double totalCandels=MathAbs(end-begin); 
   
   int bullish_gap=0;
   int bearish_gap=0;
   //
   
   for (int i=begin;i<=end;i++){
   
      double candelBody=(iClose(NULL,tf,i)-iOpen(NULL,tf,i));
      double open=iOpen(NULL,tf,i);
      double close=iClose(NULL,tf,i);
      //double low=iLow(NULL,tf,i);
      //double high=iHigh(NULL,tf,i);
      
      double candelBody2=(iClose(NULL,tf,i+1)-iOpen(NULL,tf,i+1));
      double close2=iClose(NULL,tf,i+1);
      double open2=iOpen(NULL,tf,i+1);
      //double low2=iLow(NULL,tf,i+1);
      //double high2=iHigh(NULL,tf,i+1);
      
      if ((candelBody>0)&&(candelBody2>0)){ //both candels are bullish
         if (open2>close){
            bullish_gap+=1;
         }
      }
      /*if ((candelBody<0)&&(candelBody2<0)){ //both candels are bullish
         if (open2<close){
            Print("Second phase ..");
            bearish_gap+=1;
         }
      }*/
      if (open2<close){
            Print("Second phase ..");
            bearish_gap+=1;
      }
   }
   
   Print("Bearish gap ",bearish_gap);
   
   if(bearish_gap>=2){
      return 2;
   }
   
   return 0;
}



int close_prz(int period,int n_recently,ENUM_TIMEFRAMES tf){ // check if the price expereince a sup/res recently in N last candels
   
   double limit_distance=1000*Point();//50 pip
   
   double current=iClose(NULL,M1,1);
   double max=current;
   double min=current;
   datetime low_time;
   
   double recent_high=current;
   double recent_low=current;
   
   for (int i=1;i<=n_recently;i++){
      if(iHigh(NULL,tf,i)>=recent_high){
         recent_high=iHigh(NULL,tf,i);
      }
      if(iLow(NULL,tf,i)<=recent_low){
         recent_low=iLow(NULL,tf,i);
      }
   }
   
   for (int i=n_recently;i<=period;i++){
   
      if (iHigh(NULL,tf,i)>=max){
         max=iHigh(NULL,tf,i);
      }
      if (iLow(NULL,tf,i)<=min){
         min=iLow(NULL,tf,i);
         low_time=iTime(NULL,tf,i);
      }
      
   }
   
   
   /*if ((MathAbs(max-current)>=limit_distance) && (MathAbs(min-current)>=limit_distance) ){
         return 1;
   }*/
   if ((MathAbs(max-recent_high))<=limit_distance){ // if we experienced a high in our recent candles
      Print("Lowest point is ",min);
      Print("Date of it is ", low_time);
      Print("Limit is ",limit_distance);
      Print("min-current is ",min-current);
      return 1;
   }
   
   
   return 0;

}


int strong_trend(int period,int candels,ENUM_TIMEFRAMES tf){ // check whather all are candels in desired tf are above(or below for bearsih) the ema
   
   double myEMA2[];
   int emaDef2;
   
   emaDef2=iMA(_Symbol,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,100,myEMA2); // last ema's for last 3 candel is in this array
   
   
   int bullishflag=1;
   int bearishfalg=1;
   
   for(int i=1;i<=candels;i++){
      if (iClose(NULL,tf,i)>myEMA2[i]){
         bearishfalg=0;
      }
      if (iClose(NULL,tf,i)<myEMA2[i]){
         bullishflag=0;
      }
   }
   
   if (bullishflag==1){
      return 1;
   }
   
   if (bearishfalg==1){
      return 2;
   }
   return 0;
}


int engulfing_pattern(int num,ENUM_TIMEFRAMES tf){//for buy: does the last close of candel is hagher than high of last n candels in desired tf
   double swing=iClose(NULL,tf,1);
   int bulishCount=0;
   int bearishCount=0;
   
   for(int i=1;i<=num;i++){
      if(swing>=iHigh(NULL,tf,i)){
         bulishCount+=1;
      }
      if(swing<=iLow(NULL,tf,i)){
         bearishCount+=1;
      }
      
   }
   
   if (bulishCount==num){
      return 1;
   }
   if (bearishCount==num){
      return 2;
   }
   return 0;
}

int consecutive_candels(int number,ENUM_TIMEFRAMES tf){ // checking last n candel in a row (if n last candel in a row are green return 1)

   double open;
   double close;
   
   int numOfGreens=0;
   int numOfReds=0;
   
   for (int i=1;i<=number;i++){
      open=iOpen(NULL,tf,i);
      close=iClose(NULL,tf,i);
      
      if(close>open){
         numOfGreens+=1;
      }
      if(close<open){
         numOfReds+=1;
      }
      
   }
   
   
   if (numOfGreens==number){// all candels in desired tf are green (for exmaple if numner=2; last two candels in a row in desired tf are green )
      return 1;
   }
   
   if (numOfReds==number){
      return 2;
   }
   
   return 0;
}

int local_swing(double value,int period, ENUM_TIMEFRAMES tf){ //check weather the end of flag is inside a box or it self is a local swing (highest/lowest among peroids candels)
   
   double max=iHigh(NULL,tf,1);
   double min=iLow(NULL,tf,1);
   
   for(int i=2;i<=period;i++){
      if(iHigh(NULL,tf,i)>=max){
         max=iHigh(NULL,tf,i);
      }
      if(iLow(NULL,tf,i)<=min){
         min=iLow(NULL,tf,i);
      }
   }
   if (value>max){
      return 1;
   }
   if (value<min){
      return 2;
   }
   return 0;
}

double simple_pullback(datetime first_date,datetime second_date,datetime third_date, ENUM_TIMEFRAMES tf){//number of candels in pullback be one-third of the flag-bar --> a simple pullback not complicated
   
   int first=0;
   int second=0;
   int third=0;
   
   //double alpha=alpha_pullback_ratio;
   double alpha=1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         first=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         second=i;
      }
      if (iTime(NULL,tf,i) == third_date){
         third=i;
      }          
   }
   
   int len_first_move=MathAbs(third-second)+1;
   int len_second_move=MathAbs(first-second)+1;
   
   if (len_first_move/len_second_move>=alpha_pullback_ratio){
      return 1;
   }
   
   return 0;
}


int strong_move(datetime first_date,datetime second_date,ENUM_TIMEFRAMES tf){/// move strongness-> for bullish flag the pole has close near high (no up-shadows)
   
   double alpha=alpha_strong_bar;
   
   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         end=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   double totalCandels=MathAbs(end-begin); 
   
   int strong_bullish_candels=0;
   int strong_bearish_candels=0;
   //
   
   for (int i=begin;i<=end;i++){
      double candelSize=(iHigh(NULL,tf,i)-iLow(NULL,tf,i));
      double close=iClose(NULL,tf,i);
      double low=iLow(NULL,tf,i);
      double high=iHigh(NULL,tf,i);
      
      double limit_bullish=low+(alpha*candelSize);
      double limit_bearish=high-(alpha*candelSize);
      
      
      if(close>=limit_bullish){
         strong_bullish_candels+=1;
      }
      if(close<=limit_bearish){
         strong_bearish_candels+=1;
      }
   }
   
   
   if ((strong_bullish_candels/totalCandels)>alpha){ // in bullish scenario
      return 1;
   }
   
   if ((strong_bearish_candels/totalCandels)>alpha){
      return 2;
   }
   
   
   return 0;   
}




int price_in_trend(int period,int numOfCandels,int crossesLimit,ENUM_TIMEFRAMES tf){ // check how many times two ema have cross: the more means market is in range not trend
   
   double myEMA2[];
   int emaDef2;
   
   emaDef2=iMA(_Symbol,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,100,myEMA2); // last ema's for last 3 candel is in this array
   
   int numOfCrosses=0;
   double currentEMA;
   double one_before_EMA;
   
   double current;
   double one_before;
   
   for (int i=2;i<=numOfCandels;i++){
      current=iClose(NULL,tf,i);
      one_before=iClose(NULL,tf,i-1);
      
      currentEMA=myEMA2[i];
      one_before_EMA=myEMA2[i-1];
      
      if( (one_before>=one_before_EMA) && (current<=currentEMA) ){
         numOfCrosses+=1;
      }
      if( (one_before<=one_before_EMA) && (current>=currentEMA) ){
         numOfCrosses+=1;
      }
   }
   
   if (numOfCrosses<=crossesLimit){
      return 1;
   }
   
   return 0;
}


int check_place_of_leg(datetime start_of_move, datetime end_of_move,ENUM_TIMEFRAMES tf,int period){ // check start of pole be under ema then by end of it it comes above (also check for pullback start_end in position with another ema)

   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == start_of_move){
         end=i;
      }
      if (iTime(NULL,tf,i) == end_of_move){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   double myEMA2[];
   int emaDef2;
   
   emaDef2=iMA(NULL,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,200,myEMA2); // last ema's for last 100 candel is in this array
   
   double start_point_EMA=myEMA2[end];
   double end_point_EMA=myEMA2[begin];
   
   
   double start_point=iClose(NULL,tf,end);
   double end_point=iClose(NULL,tf,begin);
   
   if ((start_point<=start_point_EMA) && (end_point>=end_point_EMA)){
      return 1;
   }
   
   if ((start_point>=start_point_EMA) && (end_point<=end_point_EMA)){
      return 2;
   }
   
   return 0;
   
}



int distance_from_ema(int period,double distance_limit,ENUM_TIMEFRAMES tf){// check the distance price from ema is more than the limit or not
   double myEMA2[];
   int emaDef2;
   
   
   emaDef2=iMA(NULL,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,100,myEMA2); // last ema's for last 100 candel is in this array
   
   double currentEMA=myEMA2[1];
   
   
   double currentPrice=iClose(NULL,tf,1);
   
   double distance=(currentPrice-currentEMA);
   
   
   if (distance<(distance_limit*10*_Point)){
    
      return 1;
   }
   return 0;
}




double compare_size_of_bodies(datetime start_time, datetime end_time,ENUM_TIMEFRAMES tf){// compare body size of a leg

   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == start_time){
         end=i;
      }
      if (iTime(NULL,tf,i) == end_time){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   double total=0;
   double body;
   int numOfcandels=0;
   
   //- to - :41
   //+ to + : 40
   //total to total :42
   
   for(int i=begin;i<=end;i++){
      body=iClose(NULL,tf,i)-iOpen(NULL,tf,i);
      /*if (body<0){
         total+=MathAbs(body);
         numOfcandels+=1;
      }*/
      total+=(body);
      numOfcandels+=1;
   }
   
   if(numOfcandels==0){return 0;}
   
   return MathAbs(total/numOfcandels);
}


int good_recover(datetime first_date,datetime second_date,ENUM_TIMEFRAMES tf){ // compare size of recover candel after pullback and also power of that candel
   
   
   // this func is same for buy\sell and must return 1;
   
   int signal_index=1;
   double alpha=alpha_good_recover;
   //double alpha=1.2;
   
   double body=iClose(NULL,tf,signal_index)-iOpen(NULL,tf,signal_index);
   
   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         end=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   double total=MathAbs(end-begin)+1; // number of candels in a leg
   double sumOfATR=0;
   
   for (int i=end;i<=begin;i++){
      sumOfATR+=(iHigh(NULL,tf,i)-iLow(NULL,tf,i));
      //sumOfATR+=MathAbs(iClose(NULL,tf,i)-iOpen(NULL,tf,i));
   }
   
   double avgATR=sumOfATR/total;
   
   
   
   //double recoverATR=MathAbs(iClose(NULL,tf,signal_index)-iOpen(NULL,tf,signal_index)); 
   double recoverATR=(iHigh(NULL,tf,signal_index)-iLow(NULL,tf,signal_index));
   
   double close_limit_bullish=iLow(NULL,tf,signal_index)+(0.7*recoverATR); //added recently to check close near the top
   double close_limit_bearish=iHigh(NULL,tf,signal_index)-(0.7*recoverATR); 
   
   if((recoverATR>alpha*avgATR)){  //size of recover candel be 1.1 times of avgATR.pullbabk phase
      //if (body>0){
      if ((iClose(NULL,tf,signal_index)>close_limit_bullish)){
 
         return 1;
      }
      
      if ((iClose(NULL,tf,signal_index)<close_limit_bearish)){
         return 2;
      }
      
   }
   
   return 0;
}



int rejection_count(int numOfCandels,ENUM_TIMEFRAMES tf,double min, double max){ //count num of rejection in the zone ( we must specify range that shadow happens)
   
   double alpha=2;// size of shadow compare to body
   double close;
   double open;
   double body;
   double high;
   double low;
   double uppershadow;
   double downshadow;
   int total_num_of_bullish_rejection=0;
   
   for (int i=0;i<numOfCandels;i++){
      close=iClose(NULL,tf,i);
      open=iOpen(NULL,tf,i);
      body=close-open;
      high=iHigh(NULL,tf,i);
      low=iLow(NULL,tf,i);
      uppershadow=0;
      downshadow=0;
   
      if (body<0){
         uppershadow=high-open;
         downshadow=close-low;
      }
      else{
         uppershadow=high-close;
         downshadow=open-low;
      }
   
      if (MathAbs(downshadow)>=alpha*MathAbs(body) ){
         if ((max==0)&&(min==0)){
            total_num_of_bullish_rejection+=1;
         }
         if((low>=min)&&(low<=max)){
            total_num_of_bullish_rejection+=1;
         }
         
      }
   
      if (MathAbs(uppershadow)>=alpha*MathAbs(body)){
         total_num_of_bullish_rejection+=0;
      }
   
   }
   
   return total_num_of_bullish_rejection;
}

int check_for_close(double close_thr,datetime start_time,ENUM_TIMEFRAMES tf){//check weather price close below the thr or not (from begenning of pullback till now)

   datetime now=iTime(NULL,tf,1);
   
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == start_time){
         end=i;
      }
      if (iTime(NULL,tf,i) == now){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   for (int i=end;i<=begin;i++){
      if(iClose(NULL,tf,i)<close_thr){
         return 1;
      }
   }
   
   
   return 0;
}


int power_in_lowerTF(){
   // lower tf zz values
   
   double first_value_lowerTF=ZZ_Values_lowerTF[0];  //recent swing
   double second_value_lowerTF=ZZ_Values_lowerTF[1]; //one before recent swing
   double third_value_lowerTF=ZZ_Values_lowerTF[2]; //one before recent swing
   double forth_value_lowerTF=ZZ_Values_lowerTF[3]; //one before recent swing
   double fifth_value_lowerTF=ZZ_Values_lowerTF[4]; //one before recent swing
   
   datetime first_date_lowerTF=ZZ_Times_lowerTF[0]; // date of second swing 
   datetime second_date_lowerTF=ZZ_Times_lowerTF[1]; // date of second swing 
   datetime third_date_lowerTF=ZZ_Times_lowerTF[2]; // date of last swing low
   
   int power1=trend_finder(first_value_lowerTF,second_value_lowerTF,third_value_lowerTF);
   int power2=trend_finder(third_value_lowerTF,forth_value_lowerTF,fifth_value_lowerTF);
   
   if ((power1==2) &&(power2==2) ){
      return 2;
   }
   
   if ((power1==1) &&(power2==1) ){
      return 1;
   }
   
   return 0;
}

int rejection(ENUM_TIMEFRAMES tf,int index){ // check size of shadow of a candel in camp with the body

   double alpha=2;
   
   double close=iClose(NULL,tf,index-1);
   double open=iOpen(NULL,tf,index-1);
   double body=close-open;
   double high=iHigh(NULL,tf,index-1);
   double low=iLow(NULL,tf,index-1);
   double uppershadow=0;
   double downshadow=0;
   
   double closeLast=iClose(NULL,tf,index);
   
   if (body<0){
      uppershadow=high-open;
      downshadow=close-low;
   }
   else{
      uppershadow=high-close;
      downshadow=open-low;
   }
   
   if ((MathAbs(downshadow)>=alpha*MathAbs(body)) && (closeLast>=high) ){
      return 1;
   }
   
   if ((MathAbs(uppershadow)>=alpha*MathAbs(body)) && (closeLast<=low) ){
      return 2;
   }
   
   return 0;
}





void pattern_validate(ENUM_TIMEFRAMES tf){ // check when detected flag has no value anymore (time and price)

   double now=iClose(NULL,tf,1);
   double validation_limit=0;
   double bar=MathAbs(start_of_bar-start_of_pullback);
   
   if (flag==1){
      validation_limit=NormalizeDouble(start_of_pullback-(max_retrace*bar),_Digits);
      if ((now<=validation_limit) ){// // checking price || (now>=start_of_pullback)
         flag=0;
      }
      
   }
   
   if (flag==2){
      validation_limit=NormalizeDouble(start_of_pullback+(max_retrace*bar),_Digits);
      if ((now>=validation_limit) ){// // checking price       || (now<=start_of_pullback)
         flag=0;
      }
      
   }
   
}


int price_in_zone(datetime pullback_start,datetime bar_start,ENUM_TIMEFRAMES tf){ // check wheather price is comeback to demand zone or not
   
   //thresholds
   double alpha_distance=0.3;
   
   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == bar_start){
         end=i;
      }
      if (iTime(NULL,tf,i) == pullback_start){
         begin=i;
      }          
   }
   
   if (begin==-1 || end==-1){
      return 0;
   }
   
   int total_distance=(end-begin)+1;
   double thr_distance=total_distance*alpha_distance;
   
   //double min=begin+(total_distance*0.3);
   //double max=begin+(total_distance*0.6);
   int zone_candel=-1;
   double price_now=iClose(NULL,tf,1);
   
   double min=0;
   double max=0;
   for (int i=begin;i<=end;i++){//from last candel of bar to first one
      double body=iClose(NULL,tf,i)-iOpen(NULL,tf,i);
      if(body<0){
         if ((i-begin)>=thr_distance){
            min=iLow(NULL,tf,i);
            max=iHigh(NULL,tf,i);
            if ((price_now>=min)&&(price_now<=max)){//price is in the demand zone
               //Print("Found a zone");
               if(check_for_close(min,start_of_pllback_time,tf)==0){//check after start of pullback in m15 we did not close below it
                  
                  zone_candel=i;
               }
            }
            
         }
      }
   }
   
   
   if (zone_candel==-1){// the demand is not found or valid
      return 0;
   }
   /// count num of rejecton in zone in m1
   int numOfRejection=rejection_count(5,M1,min,max);
   if(numOfRejection>=3){
      return 1;
   }
   return 0;
}

double peneterationHigherTF(int firstCandelIndex, ENUM_TIMEFRAMES tf){ //% of peneteration of second higher tf candel into first one (must be less than special percent)
   double alpha=0.6;
   
   double openFirst=iOpen(NULL,tf,firstCandelIndex);
   double closeFirst=iClose(NULL,tf,firstCandelIndex);
   double highFirst=iHigh(NULL,tf,firstCandelIndex);
   double lowFirst=iLow(NULL,tf,firstCandelIndex);
   double bodyFirst=closeFirst-openFirst;
   double fullbodyFirst=MathAbs(highFirst-lowFirst);
   
   double openSecond=iOpen(NULL,tf,firstCandelIndex-1);
   double closeSecond=iClose(NULL,tf,firstCandelIndex-1);
   double lowSecond=iLow(NULL,tf,firstCandelIndex-1);
   double highSecond=iHigh(NULL,tf,firstCandelIndex-1);
   
   if (closeFirst>openFirst){ // first candel is bullish
      //if (lowSecond>openFirst){
      //if (lowSecond>(openFirst+(0.5*bodyFirst))){
      //if (lowSecond>(openFirst+(0.6*fullbodyFirst))){ last change that sounds logical
      if (lowSecond>(lowFirst+(alpha*fullbodyFirst))){
         return 1;
      }
   }
   if (closeFirst<openFirst){ // first candel is bearish
      if (highSecond<(lowFirst+(alpha*fullbodyFirst))){
         return 2;
      }
   }
   
   return 0;
}


double reverse_started(ENUM_TIMEFRAMES tf){ // for short: find two candels with lower low and lower high in the same tf of the flag
   double highFirst=iHigh(NULL,tf,2);
   double lowFirst=iLow(NULL,tf,2);
   double openFirst=iOpen(NULL,tf,2);
   double closeFirst=iClose(NULL,tf,2);
   double bodyFirst=closeFirst-openFirst;
   
   double highSecond=iHigh(NULL,tf,1);
   double lowSecond=iLow(NULL,tf,1);
   double openSecond=iOpen(NULL,tf,1);
   double closeSecond=iClose(NULL,tf,1);
   double bodySecond=closeSecond-openSecond;
   
   if((bodyFirst>0) && (bodySecond>0)){
      if((highSecond>highFirst)&&(lowSecond>lowFirst)){
         return 1;
      }
   }
   
   if((bodyFirst<0) && (bodySecond<0)){
      if((highSecond<highFirst)&&(lowSecond<lowFirst)){
         return 2;
      }
   }
   
   return 0;
}






double inside_candel_higherTF(ENUM_TIMEFRAMES tf,int index){//check the signal candel(index=0) is inside the prev candel in Higher TF
   double highFirst=iHigh(NULL,tf,index+1);
   double lowFirst=iLow(NULL,tf,index+1);
   
   double highSecond=iHigh(NULL,tf,index);
   double lowSecond=iLow(NULL,tf,index);
   
   if ((highFirst>highSecond)&&(lowFirst<lowSecond)){
      return 1;
   }
   return 0;
}

/*
double near_prz(double zz1,ENUM_TIMEFRAMES tf){//entry must not be far away from pullback
   double high=iHigh(NULL,tf,1);
   double low=iLow(NULL,tf,1);
   
   if(low<zz1){
      return 1;
   }
   if(high>zz1){
      return 2;
   }
   
   return 0;
   
}*/



double takback_last_swing(ENUM_TIMEFRAMES tf){ // we check wheather a good candel is takeback last swing, in pullback phase
   double last_close=iClose(NULL,tf,1);
   
   double last_swing_high=iHigh(NULL,tf,2);
   double last_swing_low=iLow(NULL,tf,2);
   
   if (last_close>last_swing_high){
      return 1;
   }
   if (last_close<last_swing_low){
      return 2;
   }
   return 0;
   
}



double shadow_checker(ENUM_TIMEFRAMES tf,int i){ //check shadow size of ith candel in desired tf and compare the size of body and upper shadow
   double alpha=1.0;
   
   double body=iClose(NULL,tf,i)-iOpen(NULL,tf,i);
   double upper_shadow=MathAbs(iHigh(NULL,tf,i)-iClose(NULL,tf,i));
   double down_shadow=MathAbs(iHigh(NULL,tf,i)-iClose(NULL,tf,i));
   
   if (body>0){ // bullish candel
      double upper_shadow=MathAbs(iHigh(NULL,tf,i)-iClose(NULL,tf,i));
      if((body>alpha*upper_shadow) && ( true)){//(iClose(NULL,tf,i)>iOpen(NULL,tf,i))
         return 1;
      }
   }
   else{// bearish candel
      double down_shadow=MathAbs(iClose(NULL,tf,i)-iLow(NULL,tf,i));
      if(MathAbs(body)>alpha*down_shadow){
         return 2;
      }
   }
   
   return 0;
}



double slope(datetime first_date,datetime second_date,double leg_size,ENUM_TIMEFRAMES tf){ // calculate power of a leg

   //finding candles of start and finish of first leg
   int begin=-1;
   int end=-1;
   
   for (int i=0;i<=100;i++){
      if (iTime(NULL,tf,i) == first_date){
         end=i;
      }
      if (iTime(NULL,tf,i) == second_date){
         begin=i;
      }          
   }
   double total=MathAbs(end-begin)+1; // number of candels in a leg
   
   
   double slope=leg_size/total;
   
   return slope;
   
   //double numOfGreens=0;
   //double numOfReds=0;
   
   
   /*for (int i=end;i<=begin;i++){
      if((iOpen(NULL,higherTF,i)<=iClose(NULL,higherTF,i))){
         numOfGreens++;
      }
      else{
         numOfReds++;
      }
   }
   total=numOfGreens+numOfReds;*/
   
}



int good_pullback(double first_leg,double second_leg){ // calculate pullback leg then if it is not a deep return 1, else 0 deep_pullback=0.5
   
   double pullback=(second_leg/first_leg);
   if((pullback<max_retrace) && (pullback>=min_retrace)){
      return 1;
   }
   
   return 0;
}

int trend_finder(double first_value,double second_value,double third_value){ // find trend based on zz values 

   
   if ( (first_value>third_value) && (second_value>third_value) ){ // bullish
      
      return 1;
   }
   else if ( (first_value<third_value) && (second_value<third_value) ){ // bullish
      return 2;
   }
   
   
   return 0;
   
}



// making zig zag value
void Collecting_ZZ_Values(int zz_h,int collect_val,ENUM_TIMEFRAMES timeframe, double &ZZ_Values[],datetime &ZZ_Times[]){

   int collected_values=0;
   int Collect_Values=collect_val;
   int zz_handle=zz_h;
   
   int i=1;
   double ZZ_Array[];
   
   while(collected_values<Collect_Values){
      CopyBuffer(zz_handle,0,i,1,ZZ_Array);
      if (ZZ_Array[0]!=0.0){
         ZZ_Values[collected_values]=ZZ_Array[0];
         ZZ_Times[collected_values]=iTime(NULL,timeframe,i);
         collected_values++;
      }
      i++;
   }

}

double volume_calculator(double stoploss)
{
   if(stoploss==0){
     return(0);
   }
   
   double usd_risk = riskPerTrade*0.01 * AccountInfoDouble(ACCOUNT_BALANCE); 
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double profit=0; 
   bool check=OrderCalcProfit(ORDER_TYPE_BUY,_Symbol,1,ask,ask+100*_Point,profit); // ?? type buy
   double point_value = profit*0.01; //?? zero!
   double lotsize = usd_risk/(stoploss*point_value);
   int volume_digits=int(MathAbs(MathLog10(SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP))));    
   
   double final_lot=NormalizeDouble(lotsize,volume_digits);
   if (final_lot<=0.01){
      final_lot=0.01;
   }
   return final_lot;
  
}


void close_reverse_trade(int signal){ // closing positions in opposite side of recent signal
   
   
   int new_signal_type=POSITION_TYPE_BUY; // do not change during the if elses
   
   
   if (signal==1){
      new_signal_type=POSITION_TYPE_BUY;
   }
   else if(signal==2){
      new_signal_type=POSITION_TYPE_SELL;
   }
   else{
      return;
   }
   
   if ( PositionsTotal() > 0) {
      Print("PositionsTotal() ",PositionsTotal() );
      for (int i=0; i < PositionsTotal() ; i++) {
         if( m_position.SelectByIndex(i) ) {
            if (m_position.Symbol()==Symbol()) {
               Print("m_position.Symbol() ",m_position.Symbol() ); 
               if (m_position.PositionType() != new_signal_type ) { // bar asas addad type ra bar migradanad
                  Print("new_signal_type ",new_signal_type);
                  Print("m_position.PositionType() ",m_position.PositionType()); 
                  m_trade.PositionClose(m_position.Ticket());
               }
            }
         }
      } 
   }
   
}

int two_candles_signal(ENUM_TIMEFRAMES tf){ //(bullish case describe) M5[1]>=M5[2] (low and high) and also both are bullish --> bullish trend started in last two higher TF candels

   double secondOpen=iOpen(NULL,tf,2);//M5[2]
   double secondClose=iClose(NULL,tf,2);
   double secondLow=iLow(NULL,tf,2);
   double secondHigh=iHigh(NULL,tf,2);
   
   
   double firstClose=iClose(NULL,tf,1);//M5[1]
   double firstOpen=iOpen(NULL,tf,1);
   double firstHigh=iHigh(NULL,tf,1);
   double firstLow=iLow(NULL,tf,1);
   
   
   if ((firstClose>secondHigh) && (firstLow>secondLow) && (secondClose>secondOpen) && (firstClose>firstOpen)){ // bullish Senario
      return 1; 
   }
   if ((firstClose<secondLow) && (firstHigh<secondHigh) && (secondClose<secondOpen) && (firstClose<firstOpen)){ // bearish Senario
      return 2;
   }
   return 0;
}

int trend_ema(ENUM_TIMEFRAMES tf,int period){ // calculate ema in a tf and a period then check price is about that or below that
   
   // ema 
   double myEMA2[];
   int emaDef2;
   emaDef2=iMA(_Symbol,tf,period,0,MODE_EMA,PRICE_CLOSE); //period=20
   ArraySetAsSeries(myEMA2,true);
   CopyBuffer(emaDef2,0,0,3,myEMA2); // last ema's for last 3 candel is in this array
   
   double myCurrentEMA=myEMA2[1];
   double lastCandel=iClose(NULL,tf,1);
   
   if (lastCandel>=myCurrentEMA){ // bullish Senario
      // if close price of last candel is above ema20
      return 1; 
   }
   if (lastCandel<myCurrentEMA){ // bearish Senario
      return 2;
   }
   return 0;
}

int lastNCandels(ENUM_TIMEFRAMES tf,int period){ // calculate trend in n last candel base on total body of those candel
   double total=0;
   double body=0;
   
   for (int i=1;i<=period;i++){
      double body=iClose(_Symbol,tf,i)-iOpen(_Symbol,tf,i);
      total+=body;
   }
   
   if(total>0){ // bullish
      // if body color of those 3 candel are green
      return 1;
   }
   else if(total<0){
      return 2;
   }
   else{
      return 0;
   }
   
}