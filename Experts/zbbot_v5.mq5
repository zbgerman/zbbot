//+------------------------------------------------------------------+
//|                                                     zbbot_v1.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#import "shell32.dll"
   int ShellExecuteW(int hwnd, string lpOperation, string lpFile, string lpParameters, string lpDirectory, int nShowCmd);
#import



//+------------------------------------------------------------------+
//| Include Simple Order Panel                                                         |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Edit.mqh>
#include <Controls\Label.mqh>
#include <ChartObjects\ChartObjectsLines.mqh>




//+------------------------------------------------------------------+
//| Resources                                                        |
//+------------------------------------------------------------------+
#resource "\\Include\\Controls\\res\\RadioButtonOn.bmp"
#resource "\\Include\\Controls\\res\\RadioButtonOff.bmp"
#resource "\\Include\\Controls\\res\\CheckBoxOn.bmp"
#resource "\\Include\\Controls\\res\\CheckBoxOff.bmp"
#resource "\\Include\\Controls\\res\\SpinInc.bmp"
#resource "\\Include\\Controls\\res\\SpinDec.bmp"


//+------------------------------------------------------------------+
//| Definición de un inpumbral predeterminado para la fuerza de la mecha para usar con el recjection block 
//| La mecha debe ser al menos X veces más grande que el cuerpo (en valor absoluto)
//| Ajusta este valor según tu preferencia. Un valor entre 2 y 4 es común.

#define WICK_BODY_RATIO_THRESHOLD 1 


//Para poder usar ShellExecuteW
#define SW_HIDE 0


#define XRGB(r,g,b)    (0xFF000000|(uchar(r)<<16)|(uchar(g)<<8)|uchar(b))
#define GETRGB(clr)    ((clr)&0xFFFFFF)


#define PANEL_NAME "Order Panel"
#define PANEL_WIDTH 150
#define PANEL_HIEIGHT 350
#define PANEL_COLOR clrGray   // Definir el color del panel usando una constante predefinida
#define ROW_HEIGHT 15
#define COL_WIDTH 50
#define COL_SPACE 10
#define FONT_SIZE 8
#define BUY_BTN_NAME "Buy BTN"
#define SELL_BTN_NAME "Sell BTN"
#define BUY_LIMIT_BTN_NAME "Buy Limit BTN"
#define SELL_STOP_BTN_NAME "Sell Limit BTN"
#define BUY_STOP_BTN_NAME "Buy Stop BTN"
#define CLOSE_BTN_NAME "Close BTN"
#define SL_PF_BTN_NAME "Stop Loss Profit BTN"
#define SHOW_MACROS_KILLZOME_BTN_NAME "Show Macros y Killzone BTN"
#define BE_BTN_NAME "Break Even BTN"
#define SHOW_FVG_BTN_NAME "Show FVG"
#define SELL_LIMIT_BTN_NAME "Sell Stop BTN"
#define LABEL_NAMELOTESIZETEXT "Lot Size Text"
#define EDIT_NAMELOTESIZESELL "Lot Size Sell"
#define EDIT_NAMELOTESIZEBUY "Lot Size Buy"
#define LABEL_NAMEPORCENTAJERIESGOTEXT "Porcentaje Riesgo Text"
#define EDIT_NAMEPORCENTAJERIESGO "Porcentaje Riesgo"
#define LABEL_RIESGODINERO "Riesgo Dinero"
#define LABEL_PORCENTAJEUTILIDADTEXT "Porcentaje Utilidad Text"
#define EDIT_PORCENTAJEUTILIDAD "Porcentaje Utilidad"
#define LABEL_UTILIDADDINERO "Utilidad Dinero"

#define LABEL_PROFITTEXT "Porcentaje profit Text"
#define EDIT_PORCENTAJEPROFIT "Porcentaje Profit"
#define LABEL_PROFITDINERO "Profit Dinero"

#define LABEL_PUNTOSFVGTEXT "Puntos FVG Text"
#define EDIT_PUNTOSFVG "Pisp Stop Loss"
#define LABEL_RATIOTEXT "Ratio Text"
#define EDIT_RATIO "Ratio"

#define M1_BTN_NAME "Tendencia M1"
#define M3_BTN_NAME "Tendencia M3"
#define M15_BTN_NAME "Tendencia M15"
#define H1_BTN_NAME "Tendencia H1"
#define H4_BTN_NAME "Tendencia H4"
#define D1_BTN_NAME "Tendencia D1"



CAppDialog panel;
CButton buyBtn;
CButton sellBtn;
CButton buyLimitBtn;
CButton sellLimitBtn;
CButton buyStopBtn;
CButton sellStopBtn;
CLabel lotSizetext;
CEdit lotSizeSell;
CEdit lotSizeBuy;
CLabel porcentajeRiesgoText;
CEdit porcentajeRiesgo;
CLabel RiesgoDinero;
CLabel UtilidadText;
CEdit porcentajeUtilidad;
CLabel UtilidadDinero;
CLabel profitText;
CEdit porcentajeProfit;
CButton profitDineroBtn;
CLabel puntosFvgText;
CEdit puntosFvg;
CLabel ratioText;
CButton ratioBtn;
CButton sl_pf_Btn;
CButton closeBtn;
CButton beBtn;
CButton showMacrosKillzoneBtn;
CButton showFvgBtn;
CButton m1Btn;
CButton m3Btn;
CButton m15Btn;
CButton h1Btn;
CButton h4Btn;
CButton d1Btn;


//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
CTrade            MiTrade;                      // trading object
CSymbolInfo       MiSymbol;                     // symbol info object
CAccountInfo      MiAccount;                    // account info wrapper
CMoneyFixedRisk   MiMoney;

#define  Bid SymbolInfoDouble(_Symbol, SYMBOL_BID)
#define  Ask SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define  Puntos SymbolInfoDouble(_Symbol,SYMBOL_POINT)
#define MA_MAGIC 1234501


// Inputs para personalizar
string NombreLineaPromedio = "A_Linea_Promedio"; //Nombre Linea promedio


input ENUM_TIMEFRAMES Time_Frame_HTF = PERIOD_D1; //Select time frame for high time frame
input ENUM_TIMEFRAMES Time_Frame_M2022 = PERIOD_M3; //Select time frame for Model 2022
input int velas_verificar_fractal = 4; // Velas verificar fractal modelo 2022
input int  inpnumerofvg = 1; // Numero de FVG para las alarmas
input double inpumbral = 1; //inpumbral

input int inphorainicial = 7; //Hora inicial
input int inpminutoinicial = 30; //Minuto inial 
input int inphorafinal = 10; //Hora final
input int inpminutofinal = 00; //Minuto final

input double inpporcentajeGanancia = 1; //Porcentaje de utilidad
input double inpporcentajeRiesgo = 1; //Porcentaje de Riesgo
input double inpporcentajeRetroceso = 70; //Porcentaje retroceso para comprar o vender
input bool  inptendencia = true; // verdadero alcista falso bajista

input bool  lotaje_automatico = true;
input bool  inpcompra_automatica_M2022 = true;
input bool  mostrar_fvg = true; 
input bool  mostrar_fibo = true;  
input bool  mostrar_fractal = true;
input bool  mostrar_phpl = true;
input bool  mostrar_macros_killzone = false;

input double Pips_sl = 0; //Pips Stop Loss + Soporte o Resistencia
input bool showFVG = true; //Mostrar FVG?
input int velas_fractal = 200; // Velas Fractal

input color ColorLineaPromedio = clrWhite; //Average line color
input int GrosorLineaPromedio = 2; ////Average Line width

input int Velas_FVG_HTF = 10000; //Max bars back for calculate HTF
input int Velas_FVG_Current = 1000; //Max bars back for calculate current time frame
input ENUM_LINE_STYLE EstiloLineaPromedio = STYLE_SOLID;
input color Color_Bullish_HTF = C'45,45,45';  
input color Color_Bullish_HTF_CE = C'132,132,0';
input color Color_Bearist_HTF = C'45,45,45';
input color Color_Bearist_HTF_CE = clrRed;
input color Color_Bullish_Current = C'132,132,0';
input color Color_Bullish_Current_CE =clrWhite;
input color Color_Bearist_Current = C'255,113,137';
input color Color_Bearist_Current_CE = clrWhite;

input int VelasSoporteResistencia = 5; //Velas Soporte resistencia o cambio de estructura Minimo 10
input int VelasRecorrido = 100; //Velas recorrido en el for para buscar los mas altos y mas bajos - recomendable 200 para estructuras M15 - H1 para M1 puede ser 10 a 30


//+------------------------------------------------------------------+
//| Idicador tendencia horizontal donde no se debe operar            |
//+------------------------------------------------------------------+
input uchar    InputPeriod=5;    // Period, in mimutes
input double   VGporcentaje_venta_lote = 0.9; //Pocentaje venta de lote

MqlTick m_tick;

//Variables Globales
bool BoolGananciaUno = true;                    //Manjeo ganancia uno
bool BoolGananciaDos = true;

double VGMaximo1;
double VGMaximo2;

double VGMinimo1;
double VGMinimo2;

int VGCompra   = 0;
int VGVenta    = 0;


double VGSoporte;
double VGResistencia;
double VGMidPrice;
double VGMidPrice_M1;
double VGPorcentaje;
double VGPorcentaje_externa;
double VGPorcentaje_fibo;
double VGPorcentaje_fibo_M1;
double VGPorcentaje_fibo_M3;
double VGPorcentaje_fibo_M15;
double VGPorcentaje_fibo_H1;
double VGPorcentaje_fibo_H4;
double VGPorcentaje_fibo_D1;

int    VGContadorAlertasZona_M1;
int    VGContadorAlertasZona_M3;
int    VGContadorAlertasZona_M15;
int    VGContadorAlertasZona_H1;

int    VGContadorAlertasOte_M1;
int    VGContadorAlertasOte_M3;
int    VGContadorAlertasOte_M15;
int    VGContadorAlertasOte_H1;


datetime VGHoraInicio = TimeCurrent() - 10000;
datetime VGHoraFinal = TimeCurrent() + 10000;

string VGTendencia_interna;
string VGTendencia_interna_M1;
string VGTendencia_interna_M3;
string VGTendencia_interna_M15;
string VGTendencia_interna_H1;
string VGTendencia_interna_H4;
string VGTendencia_interna_D1;

int    VGcomodin = 1;


string VGTendencia_externa;
bool VGTipo_tendencia_interna = false;
bool VGTipo_tendencia_externa = false;

double VGsumaTotal      = 0.0;
double VGprecioPromedio = 0.0;

string VGnameFVG;


//Ganacia del simbolo actual
double TotalMiGanancia = 0;
double Ganancia = 0;

bool PosibleVenta;
bool PosibleCompra;

bool sl_pf_Btn1 = false;

bool VGShowMacrosKillzone = mostrar_macros_killzone;

bool VGShowFvg = mostrar_fvg;


MqlDateTime MiHoraInicio;

//Para crear los objetos
string NombreObjeto, obj_name;
long current_chart_id = ChartID();


//Para el dibujar trendline
datetime Tiempo1, Tiempo2;

double   VGLote = 0.05;
int      ObjectExiste = 0;
double   porcentajeRiesgo1    =  0.2;
double   porcentajeUtilidad1  =  5;
int      puntosFvg1 = 10000;
double   point;
int      ContadorRatio = 0;
double   ValorRatio = 2;
datetime TimePosition ; 
double   ValorMedia = 0;
int      CambioAlcista    = 0;
int      CambioBajista    = 0;
int      VGContadorAlertasOte    = 0;
int      VGContadorAlertasZona    = 0;
int      VGcontadorAlertasBajista   = 0;
int      VGcontadorAlertasAlcista   = 0;
int      VGcontadorFVG              = 0;
int      ContadorZonaDiscount     = 0;
int      ContadorZonaPremiunt     = 0;
int      ContadorModelo2022       = 0;
int      VGContadorPosible2022    = 0; 
int      ContadorSonido           = 0;
int      ContadorZB               = 0;
int      ContadorvelaZB           = 0;
double   MacroHigh                = 0;
double   MacroLow                 = 0;
double   VGloteCompra             = 0;
double   VGprecioCompra           = 0;
double   VGloteVenta              = 0;
double   VGprecioventa            = 0;
double   VGriesgoDinero           = 0;
int      VGtotalOrdenesAbiertas   = 0;   

double VGmicrolotes = 0;
double VGpuntos = 0;
int VGminutos_noticias = 0;
string VGprioridad_noticias = 0;
datetime VGfecha_noticia_anterior;
int VGprev_visible_bars = 0;

bool VGmodelo2022 = false;
bool VGmovetobreakeven = false;
bool VGAlarma_modelo2022 = false;
int  VGtradedia = 0;
bool VGcumplerregla = false ;
bool VGbag = false; //Breakway Gap
double VGhighestHigh;
double VGlowestLow;
double VGbias_W1;
double VGbias_D1;
double VGbias_H4;
color VGbias_W1_color;
color VGbias_D1_color;
color VGbias_H4_color;
int VGtecla = 0;

//variables para estrategia samurai
bool VGsamurai = false;
bool VGvelasamurai = false;
double VGumbral = inpumbral;

bool VGzona_venta = false;
bool VGzona_compra = false;

double VGfibo_nivel_value_interna;
double VGfibo_nivel_value_externa;

double VGvalor_fractal_alto;
double VGvalor_fractal_bajo;
double VGvalor_fractal_alto_5;
double VGvalor_fractal_bajo_5;

int VGscale = ChartGetInteger(0,CHART_SCALE,0);

//+------------------------------------------------------------------+
//| Variables globales para control de tiempo                        |
//+------------------------------------------------------------------+
datetime fibolastAction = 0;
datetime lastActionB = 0;
datetime lastActionC = 0;
datetime lastActionD = 0;

datetime lastActionNoticias = 0;

//Para que me este verificando el modelo 2022
datetime lastActionModelo2022 = 0;
int intervalModelo2022M5 = 1*60; //15 son los minutos o 900 segundos

//datetime lastActionFvgM3 = 0;
//int intervalFvgM3 = 3*60; //3 son los minutos 


datetime lastActionFvgM15 = 0;
int intervalFvgM15 = 15*60; //15 son los minutos


// Intervalos en segundos
int fiboInterval = 60; 
int intervalB = 60;//Macros
int intervalC = 15 * 60; // 5 son los minutos
int RejectionBlockInterval = 900; 
int NoticiasInterval = 600;


datetime previousCandleTimeM1 = 0;
datetime previousCandleTimeM15 = 0;
datetime futureTime = 0;
datetime futureTime_previus = 0;

//Hora NewYork
datetime VGnewYorkTime;
MqlDateTime VGHoraNewYork;



//--- Variables globales
string labelNameCandleTimer = "CandleTimerLabel";

ENUM_TIMEFRAMES VGTime_Frame_HT = Time_Frame_HTF;
ENUM_TIMEFRAMES VGTime_Frame_Current ; 
ENUM_TIMEFRAMES VGtime_Frame_Fractal ;




ENUM_SYMBOL_CALC_MODE calc_mode = (ENUM_SYMBOL_CALC_MODE) SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);
double tick_size   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
double tick_value  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);


//Para hacer backtesting
datetime m1 = iTime(Symbol(), PERIOD_M1, 0); // Inicio del día actual
datetime m5 = iTime(Symbol(), PERIOD_M5, 0); // Inicio del día actual
datetime m15 = iTime(Symbol(), PERIOD_M15, 0); // Inicio del día actual
datetime h1 = iTime(Symbol(), PERIOD_H1, 0); // Inicio del día actual
datetime h4 = iTime(Symbol(), PERIOD_H4, 0); // Inicio del día actual


string VGHTF_Name ;
string VGHTF_Name_Fractal;

color VGcolor_zona_compra_venta = C'30,30,0'; //34,34,0

datetime lastTime = 0; //Ejecucion en un minuto en ontick en vez de ontimer


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
  double lote_maximo_permitido = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
  double realLeverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
  Print( " lote_maximo_permitido : ",lote_maximo_permitido, " realLeverage :",realLeverage);
  
//--- Desactivar autoajuste y forzar margen
   ChartSetInteger(0, CHART_SHIFT, true);    
   ChartSetDouble(0, CHART_SHIFT_SIZE, 25);    // Desactiva Chart Shift temporalmente
   
   
   //DrawBarFractals(_Period, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   //VGResistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
   //VGSoporte      = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);

   VGResistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
   VGSoporte  = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
   VGMidPrice = VGResistencia + (VGSoporte - VGResistencia) / 2.0;
   ObjectSetDouble(0, "midPrice", OBJPROP_PRICE,0,VGMidPrice );
 
 
  // Posicionar 5 velas en el futuro desde la vela actual
    datetime futureTime = iTime(_Symbol, _Period, 0) + (5 * PeriodSeconds());  

   string name_object = "ZONA_VENTAS";
   ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
   ObjectSetInteger(0,name_object,OBJPROP_TIME,1,futureTime);
   ObjectSetInteger(0,name_object,OBJPROP_FILL,false);
   
   name_object = "ZONA_COMPRAS";
   ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
   ObjectSetInteger(0,name_object,OBJPROP_TIME,1,futureTime);
   ObjectSetInteger(0,name_object,OBJPROP_FILL,false);

   if(Bid > VGResistencia || Bid < VGSoporte )
   {
      //ObjectDelete(0,"Resistencia");   
      //ObjectDelete(0,"Soporte");   
      //Soporte_Resistencia(1);
   }   
   
   noticias();
   
   ReglasModelo2022();
   
   Bias(PERIOD_W1);
   Bias(PERIOD_D1);
   Bias(PERIOD_H4);
   Bias(PERIOD_H1);
   
   
   CalculateDailyLosses(); //Cacular las ganancias o perdidas diarias
   
   if ( MQLInfoInteger(MQL_TESTER))
      intervalC = 15 ;

   verificar_ordenes_Abiertas();
        
  Print("Inicio zbbot : ",_Symbol);
   //Print("_Period:",_Period);

   //VGTime_Frame_HT = Time_Frame_HTF;
   
   switch (_Period)
   {
      case 1:   VGTime_Frame_Current = PERIOD_M1; break;
      case 2:   VGTime_Frame_Current = PERIOD_M2; break;
      case 3:   VGTime_Frame_Current = PERIOD_M3; break;
      case 5:   VGTime_Frame_Current = PERIOD_M5; break;
      case 10:   VGTime_Frame_Current = PERIOD_M10; break;
      case 15:   VGTime_Frame_Current = PERIOD_M15; break;
      case 20:   VGTime_Frame_Current = PERIOD_M20; break;
      case 30:   VGTime_Frame_Current = PERIOD_M30; break;
      case 16385:   VGTime_Frame_Current = PERIOD_H1; break;
      case 16386:   VGTime_Frame_Current = PERIOD_H2; break;
      case 16388:   VGTime_Frame_Current = PERIOD_H4; break;
      case 16408:   VGTime_Frame_Current = PERIOD_D1; break;
      case 32769:   VGTime_Frame_Current = PERIOD_W1; break;
      default:  VGTime_Frame_Current = "Desconocido";
   }


   //HideObjectsByPrefix("ZB_"+ _Symbol + "_Macro"); 

   string name = "ZB_FIBO";
   ObjectsDeleteAll(0,name);
        
   int lvsoporte = ObjectFind(0,"Soporte");      
   int lvresistencia = ObjectFind(0,"Resistencia");  
   //Print("lvsoporte:",lvsoporte," lvresistencia : ",lvresistencia);    
   if (lvsoporte < 0 || lvresistencia < 0)
   {  
      //crea lineas de soporte y resistencia
      ObjectsDeleteAll(0,"Soporte");
      ObjectsDeleteAll(0,"Resistencia");
      Soporte_Resistencia(1);
   }
   else
   {
      //VGSoporte = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
      //VGResistencia = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE); 
      if (Bid > VGResistencia || Bid < VGSoporte)
      {
         //ObjectsDeleteAll(0,"Soporte");
         //ObjectsDeleteAll(0,"Resistencia");
         //Soporte_Resistencia(1);
      }
   }
   
   //fibo("1");
   //fibo("2");


   VGtime_Frame_Fractal = Time_Frame_HTF;

   if ( _Period < PERIOD_M3) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_M3; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }

   if ( _Period >= PERIOD_M3 & Period() < PERIOD_M15) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_M15; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }

   if ( Period() >= PERIOD_M15 && Period() < PERIOD_H1) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_H1; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }

   if ( _Period>= PERIOD_H1 && Period() < PERIOD_H4) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_H4; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }

   if ( _Period >= PERIOD_H4 && Period() < PERIOD_D1) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_D1; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   
   if ( _Period >= PERIOD_D1 && Period() < PERIOD_W1) //comparo si es PERIOD_W1 semanal
   {
     VGtime_Frame_Fractal = PERIOD_W1; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }


   ObjectsDeleteAll(0, "Fractal_");
   //VGtime_Frame_Fractal = Time_Frame_HTF;

   VGHTF_Name_Fractal = TimeframeToString(VGtime_Frame_Fractal);
   
   //Print( "VGHTF_Name_Fractal : ",VGHTF_Name_Fractal);
   
   Tendencia();
   
   //DrawBarFractals(PERIOD_M1, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   //DrawBarFractals(PERIOD_M3, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   DrawBarFractals(_Period, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 

   DrawBarFractals(VGtime_Frame_Fractal, 500, 30, "2");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo
   

   DrawBarFractals(VGtime_Frame_Fractal, 500, 30, "2");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo

   //Print(" VGtime_Frame_Fractal : ",VGtime_Frame_Fractal);
   
   DrawBarFractals(Time_Frame_M2022, 500, velas_verificar_fractal, "5" ); //El parametro 5 es para alartas Modelo 2022  
        
   //DrawBarFractals(PERIOD_CURRENT, 500, 25, "1" );// Fractal para soporte y resistencia del periodo actual  
   //DrawBarFractals(_Period, 500, 4, "5" );
    
    string hora = "08";
    string serverTimeNY = GetServerTimeNY(hora);
    ////Print("Cuando en NY son las " + hora + " en el servidor son las: ", serverTimeNY);
    

      
//    //Dibujar NWOG
//    ObjectsDeleteAll(0,"NW");
//    DrawNWOG();
//    
//    ObjectsDeleteAll(0,"ND");
//    //Dibujar NDOG
//    CalculateNDOG_LastWeekTWT();
    
    //HideObjectsByPrefix("Macro");
     
    // Obtener la hora de Nueva York
    datetime newYorkTime = GetNewYorkTime();

    
    
   //TextToSpeech("Esti es una prueba en "); 
   //CalculateSupportResistance(); 
   GetDailyProfitLoss();
   GetInitialDayBalance();
   informacionCuenta();
   
   
   if (sl_pf_Btn1 == true)
   {
      sl_pf_Btn.ColorBackground(clrBlue);
      sl_pf_Btn.Text("Enable");
   } 
   if (sl_pf_Btn1 == false)
   {
      sl_pf_Btn.ColorBackground(clrRed);
      sl_pf_Btn.Text("Disable");
   } 
   
   double daily_profit = CalculateDailyProfitPercentage();
   //Print("Ganancias del día: ", daily_profit, "%");


   // Crear la etiqueta de texto para contador de segundos candle timer
   ObjectCreate(0, labelNameCandleTimer, OBJ_TEXT, 0, 0, 0);
   ObjectSetInteger(0, labelNameCandleTimer, OBJPROP_COLOR,clrWhite);
   
   // Configurar un temporizador para actualizar cada segundo
   EventSetTimer(1);
   
   //Manejor stop loss
   ManejoStopLoss();
   
   //Dibuja el FVG
   if ( Period() == PERIOD_W1) //comparo si es PERIOD_W1 semanal
   {
     VGTime_Frame_HT = PERIOD_MN1; // FVG mensual
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   if ( Period() == PERIOD_D1) //comparo si es PERIOD_D1
   {
     VGTime_Frame_HT = PERIOD_W1;
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   if ( Period() == PERIOD_H4) //comparo si es PERIOD_D1
   {
     VGTime_Frame_HT = PERIOD_D1;
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   if ( Period() >= PERIOD_H1 &&  Period() < PERIOD_H4)// || Period() == PERIOD_M15) //comparo si es PERIOD_D1
   {
     VGTime_Frame_HT = PERIOD_H4;
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   if ( Period() >= PERIOD_M15 && Period() <  PERIOD_H1 ) //comparo si es PERIOD_D1
   {
     VGTime_Frame_HT = PERIOD_H1;
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   if ( Period() < PERIOD_M15)// || Period() == PERIOD_M1 || Period() == PERIOD_M2 || Period() == PERIOD_M3 || Period() == PERIOD_M5 || Period() == PERIOD_M10 || Period() == PERIOD_M20 ) //comparo si es PERIOD_D1
   {
     VGTime_Frame_HT = PERIOD_M15;
     //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   }
   
   
   VGHTF_Name = TimeframeToString(VGTime_Frame_HT);
   
   ObjectsDeleteAll(0, "FVG_");
   
   ////VGTime_Frame_HT = PERIOD_H4;
   //if ( Period() == PERIOD_H4) //comparo si es PERIOD_D1
   //{
   //  VGTime_Frame_HT = PERIOD_D1;
   //  //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   //}
   //if ( Period() == PERIOD_D1) //comparo si es PERIOD_D1
   //{
   //  VGTime_Frame_HT = PERIOD_W1;
   //  //Print("VGTime_Frame_HT:",VGTime_Frame_HT);
   //}

   VGHTF_Name = TimeframeToString(VGTime_Frame_HT);
   DrawFVG(VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);

   //para detectar zonas de compra y venta
   //VGHTF_Name = TimeframeToString(PERIOD_H4);
   //DrawFVG(PERIOD_H4, Velas_FVG_HTF, VGcolor_zona_compra_venta, VGcolor_zona_compra_venta, 0); //para detectar zonas de compra y venta

   DrawFVG(VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
   
   // Obtener el timeframe del gráfico
   int futureBars = 5;
   ENUM_TIMEFRAMES timeframe = (ENUM_TIMEFRAMES)ChartPeriod(0);
   int periodSeconds = PeriodSeconds(timeframe);
   // Obtener la última barra actual
   datetime lastBarTime = iTime(NULL, 0, 0); // Última barra (actual)
   // Calcular el tiempo futuro
   futureTime = lastBarTime + periodSeconds * futureBars;
   futureTime_previus = lastBarTime + periodSeconds * (futureBars + 5);
   
   
   //ObjectsDeleteAll(0);
   //Dibuja los previus day, week
   ObjectsDeleteAll(0,"Previus_");
   if (mostrar_phpl == true)
      DrawPDHPDL_PWHPWL();

    // Crear la línea de promedio
    CrearLineaPromedio();
    ActualizarLineaPromedio();

    //// Actualizar FVG M15
    //ActualizarFVGM15();
    
    
//   previousCandleTimeM1 = iTime(NULL, PERIOD_M2, 0);
//   
//   if (_Point == 0.00001)
//   {
//       VGmicrolotes = 100000;
//       VGpuntos = 10000;
//   }    
//   if (_Point == 0.0001)
//   {
//       VGmicrolotes = 10000;
//       VGpuntos = 1000;
//   }    
//   if (_Point == 0.001)
//   {
//       VGmicrolotes = 1000;
//       VGpuntos = 100;
//   }    
//   if (_Point == 0.01)
//   {
//       VGmicrolotes = 100;
//       VGpuntos = 10;
//   }    
//   if (_Point == 0.1)
//   {
//       VGmicrolotes = 10; 
//       VGpuntos = 1;
//   }   
   
   //if (_Point == 0.00001 && _Symbol == "EURUSD")
   //{
   //    VGmicrolotes = 100000;
   //    VGpuntos = 10000;
   //}    
   //if (_Point == 0.01 && _Symbol == "XAUUSD")
   //{
   //    VGmicrolotes = 100;
   //    VGpuntos = 10;
   //}    
   //if (_Point == 0.001 && _Symbol == "USDJPY")
   //{
   //    VGmicrolotes = 500;
   //    VGpuntos = 100;
   //}   
   //if (_Point == 0.00001 && (_Symbol == "USDCHF" || _Symbol == "GBPUSD"  || _Symbol == "USDCAD" || _Symbol == "AUDUSD"))
   //{
   //    VGmicrolotes = 100000;
   //    VGpuntos = 10000;
   //}   
   //if (_Point == 0.00001 && _Symbol == "GBPUSD")
   //{
   //    VGmicrolotes = 100000;
   //    VGpuntos = 1000;
   //}     
   //Print(" Puntos : ",Point());
   //ChartOpen("XAUUSD",PERIOD_H4);
   
   //Print("Digitos : ",Digits());
  
//   ObjectsDeleteAll(0,"Valor");
//   ObjectsDeleteAll(0,"Bajo");
//   ObjectsDeleteAll(0,"Alto");
//

   //ObjectsDeleteAll(0,"maximo");
   //ObjectsDeleteAll(0,"minimo");

   ObjectsDeleteAll(0,"Label");
   ObjectsDeleteAll(0,"Linea");

   
  //point = _Point;
  //if((_Digits == 3) || (_Digits == 5))
  //{
  //  point*=10;
  //}
  //else
  //{ 
  //   point*=100;
  //}

//--- prepare trade class to control positions if hedging mode is active
   //ExtHedging=((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE)==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   MiTrade.SetExpertMagicNumber(MA_MAGIC);
   MiTrade.SetMarginMode();
   MiTrade.SetTypeFillingBySymbol(Symbol());
   
//Asigno Magic Numebr
   MiTrade.SetExpertMagicNumber(1234);


//---
//--- enable CHART_EVENT_MOUSE_MOVE messages 
   ChartSetInteger(0,CHART_EVENT_MOUSE_MOVE,1); 
   ChartSetInteger(0,CHART_BRING_TO_TOP,0,true);  
   
   
    // Obtener el tamaño del gráfico
    int chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
    int chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

    // Colocar el panel en la esquina superior derecha
    //int panel_x = chart_width - PANEL_WIDTH;  // 20 píxeles de margen
    int panel_x = chart_width - 200;  // 20 píxeles de margen
    int panel_y = chart_height - PANEL_HIEIGHT;

    //panel.Move(panel_x, panel_y);
   
//--- buy button
   //panel.Create(0, PANEL_NAME, 0, 200, 50, 50+PANEL_WIDTH+80, 200+PANEL_HIEIGHT);
   //panel.Create(0, PANEL_NAME, 0, 0, 0, PANEL_WIDTH, PANEL_HIEIGHT);
   panel.Create(0, PANEL_NAME, 0, panel_x, panel_y, panel_x+PANEL_WIDTH, panel_y+PANEL_HIEIGHT);

//---
   string prefix=panel.Name();
   int total=panel.ControlsTotal();
   for(int i=0;i<total;i++)
     {
      CWnd*obj=panel.Control(i);
      string name=obj.Name();
      //---
      if(name==prefix+"Border")
        {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(ColorToARGB(0,0));
         panel.ColorBorder(ColorToARGB(0,0));
         //ChartRedraw();
        }
      if(name==prefix+"Back")
        {
         CPanel *panel=(CPanel*) obj;
         panel.ColorBackground(ColorToARGB(0,0));
         //color border=(m_panel_flag) ? CONTROLS_DIALOG_COLOR_BG : CONTROLS_DIALOG_COLOR_BORDER_DARK;
         panel.ColorBorder(ColorToARGB(0,0));
         //ChartRedraw();
        }
      if(name==prefix+"Client")
        {
         CWndClient *wndclient=(CWndClient*) obj;
         wndclient.ColorBackground(ColorToARGB(0,0));
         wndclient.ColorBorder(ColorToARGB(0,0));
         //---
         int client_total=wndclient.ControlsTotal();
         for(int j=0;j<client_total;j++)
           {
            CWnd*client_obj=wndclient.Control(j);
            string client_name=client_obj.Name();
            //if(client_name=="Button1")
            //  {
            //   CButton *button=(CButton*) client_obj;
            //   button.ColorBackground(clrBlack);
            //   ChartRedraw();
            //  }
           }
         //ChartRedraw();
        }
     }


   panel.Top();
   
   //panel.BringToTop();

//    // Obtener el tamaño del gráfico
//    int chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
//    int chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
//
//    // Colocar el panel en la esquina superior derecha
//    //int panel_x = chart_width - PANEL_WIDTH;  // 20 píxeles de margen
//    int panel_x = chart_width - 250;  // 20 píxeles de margen
//    int panel_y = chart_height - PANEL_HIEIGHT;

    //panel.Move(panel_x, panel_y);


//--- lotSize
   //porcentajeRiesgo1 = StringToDouble(porcentajeRiesgo.Text());
   double pipValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE) /  SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE) * Point();
   //double tamanoPosicion = (AccountInfoDouble(ACCOUNT_BALANCE) * porcentajeRiesgo1)/pipValue/10000;
   //tamanoPosicion = NormalizeDouble(tamanoPosicion,2);

   double tamanoPosicion = .05;

   //if (_Symbol == "BTCUSD" || _Symbol == "XAUUSD" || _Symbol == "USDJPY")
   //   tamanoPosicion = 0.20;
   
//   if (_Symbol == "BTCUSD" || _Symbol == "XAUUSD" )
//      tamanoPosicion = 1;
//
//   if (_Symbol == "USTEC" || _Symbol == "EURUSD" ||  _Symbol == "USDJPY")
//      tamanoPosicion = 100;

   //if (_Symbol == "USDJPY")
   //   tamanoPosicion = 0.20;

   tamanoPosicion = NormalizeDouble(tamanoPosicion,2);
   
   //lotSizetext.Create(0, LABEL_NAMELOTESIZETEXT, 0, 4, 10, 0, 0);
   //lotSizetext.Width(COL_WIDTH);
   //lotSizetext.Height(ROW_HEIGHT);
   //lotSizetext.Text("LSize");
   //lotSizetext.Font("Arial");
   //lotSizetext.FontSize(FONT_SIZE);
   ////lotSizetext.ColorBackground(clrWhite);
   //lotSizetext.Color(clrBlack);
   ////lotSizetext.ColorBorder(clrBlack);
   //panel.Add(lotSizetext);

   lotSizeBuy.Create(0, EDIT_NAMELOTESIZEBUY, 0, 0, 10, 0, 0);
   ObjectSetString(0, lotSizeBuy.Name(), OBJPROP_TOOLTIP, "Lotes compra"); 
   lotSizeBuy.Width(COL_WIDTH);
   lotSizeBuy.Height(ROW_HEIGHT);
   lotSizeBuy.Text(tamanoPosicion);
   lotSizeBuy.Font("Arial");
   lotSizeBuy.FontSize(FONT_SIZE);
   lotSizeBuy.ColorBackground(clrWhite);
   lotSizeBuy.Color(clrBlack);
   lotSizeBuy.ColorBorder(clrBlack);
   panel.Add(lotSizeBuy);

   lotSizeSell.Create(0, EDIT_NAMELOTESIZESELL, 0, COL_SPACE + COL_WIDTH, 10, 0, 0);
   ObjectSetString(0, lotSizeSell.Name(), OBJPROP_TOOLTIP, "Lotes venta"); 
   lotSizeSell.Width(COL_WIDTH);
   lotSizeSell.Height(ROW_HEIGHT);
   lotSizeSell.Text(tamanoPosicion);
   lotSizeSell.Font("Arial");
   lotSizeSell.FontSize(FONT_SIZE);
   lotSizeSell.ColorBackground(clrWhite);
   lotSizeSell.Color(clrBlack);
   lotSizeSell.ColorBorder(clrBlack);
   panel.Add(lotSizeSell);




//Perdidad
   //porcentajeRiesgoText.Create(0, LABEL_NAMEPORCENTAJERIESGOTEXT, 0, 4, 25, 0, 0);
   //porcentajeRiesgoText.Width(COL_WIDTH);
   //porcentajeRiesgoText.Height(ROW_HEIGHT);
   //porcentajeRiesgoText.Text("% Risk");
   //porcentajeRiesgoText.Font("Arial");
   //porcentajeRiesgoText.FontSize(FONT_SIZE);
   ////porcentajeRiesgoText.ColorBackground(clrWhite);
   //porcentajeRiesgoText.Color(clrBlack);
   //porcentajeRiesgoText.ZOrder(9999);
   ////porcentajeRiesgoText.ColorBorder(clrBlack);
   //panel.Add(porcentajeRiesgoText);

   porcentajeRiesgo.Create(0, EDIT_NAMEPORCENTAJERIESGO, 0, 0, 25, 0, 0);
   ObjectSetString(0, porcentajeRiesgo.Name(), OBJPROP_TOOLTIP, "Porcentaje de riesgo"); 
   porcentajeRiesgo.Width(COL_WIDTH);
   porcentajeRiesgo.Height(ROW_HEIGHT);
   porcentajeRiesgo.Text(inpporcentajeRiesgo); 
   porcentajeRiesgo.Font("Arial");
   porcentajeRiesgo.FontSize(FONT_SIZE);
   porcentajeRiesgo.ColorBackground(clrWhite);
   porcentajeRiesgo.Color(clrBlack);
   porcentajeRiesgo.ColorBorder(clrBlack);
   panel.Add(porcentajeRiesgo);
   
   porcentajeRiesgo1    = StringToDouble(porcentajeRiesgo.Text());

   RiesgoDinero.Create(0, LABEL_RIESGODINERO, 0, COL_SPACE + COL_WIDTH, 25, 0, 0);
   RiesgoDinero.Width(COL_WIDTH);
   RiesgoDinero.Height(ROW_HEIGHT);
   RiesgoDinero.Text("0");
   RiesgoDinero.Font("Arial");
   RiesgoDinero.FontSize(FONT_SIZE);
   //RiesgoDinero.ColorBackground(clrWhite);
   RiesgoDinero.Color(clrBlack);
   //RiesgoDinero.ColorBorder(clrBlack);
   panel.Add(RiesgoDinero);

//Utilidad
   //UtilidadText.Create(0, LABEL_PORCENTAJEUTILIDADTEXT, 0, 4, 40, 0, 0);
   //UtilidadText.Width(COL_WIDTH);
   //UtilidadText.Height(ROW_HEIGHT);
   //UtilidadText.Text("% $$$");
   //UtilidadText.Font("Arial");
   //UtilidadText.FontSize(FONT_SIZE);
   ////porcentajeRiesgoText.ColorBackground(clrWhite);
   //UtilidadText.Color(clrBlack);
   ////porcentajeRiesgoText.ColorBorder(clrBlack);
   //panel.Add(UtilidadText);

   porcentajeUtilidad.Create(0, EDIT_PORCENTAJEUTILIDAD, 0, 0, 40, 0, 0);
   ObjectSetString(0, porcentajeUtilidad.Name(), OBJPROP_TOOLTIP, "Numero de operaciones a abrir");
   porcentajeUtilidad.Width(COL_WIDTH);
   porcentajeUtilidad.Height(ROW_HEIGHT);
   porcentajeUtilidad.Text(1);
   porcentajeUtilidad.Font("Arial");
   porcentajeUtilidad.FontSize(FONT_SIZE);
   porcentajeUtilidad.ColorBackground(clrWhite);
   porcentajeUtilidad.Color(clrBlack);
   porcentajeUtilidad.ColorBorder(clrBlack);
   porcentajeUtilidad.ZOrder(9999);
   panel.Add(porcentajeUtilidad);

   UtilidadDinero.Create(0, LABEL_UTILIDADDINERO, 0, COL_SPACE + COL_WIDTH, 40, 0, 0);
   UtilidadDinero.Width(COL_WIDTH);
   UtilidadDinero.Height(ROW_HEIGHT);
   UtilidadDinero.Text("0");
   UtilidadDinero.Font("Arial");
   UtilidadDinero.FontSize(FONT_SIZE);
   //RiesgoDinero.ColorBackground(clrWhite);
   UtilidadDinero.Color(clrBlack);
   //RiesgoDinero.ColorBorder(clrBlack);
   panel.Add(UtilidadDinero);


//Profit
   //profitText.Create(0, LABEL_PROFITTEXT, 0, 4, 55, 0, 0);
   //profitText.Width(COL_WIDTH);
   //profitText.Height(ROW_HEIGHT);
   //profitText.Text("Profit");
   //profitText.Font("Arial");
   //profitText.FontSize(FONT_SIZE);
   ////porcentajeRiesgoText.ColorBackground(clrWhite);
   //profitText.Color(clrBlack);
   ////porcentajeRiesgoText.ColorBorder(clrBlack);
   //panel.Add(profitText);

   porcentajeProfit.Create(0, EDIT_PORCENTAJEPROFIT, 0, 0, 55, 0, 0);
   ObjectSetString(0, porcentajeProfit.Name(), OBJPROP_TOOLTIP, "Porcentaje ganancia o perdida");
   porcentajeProfit.Width(COL_WIDTH);
   porcentajeProfit.Height(ROW_HEIGHT);
   porcentajeProfit.Text(0);
   porcentajeProfit.Font("Arial");
   porcentajeProfit.FontSize(FONT_SIZE);
   porcentajeProfit.ColorBackground(clrWhite);
   porcentajeProfit.Color(clrBlack);
   porcentajeProfit.ColorBorder(clrBlack);
   panel.Add(porcentajeProfit);

   profitDineroBtn.Create(0, LABEL_PROFITDINERO, 0, COL_SPACE + COL_WIDTH, 55, 0, 0);
   ObjectSetString(0, profitDineroBtn.Name(), OBJPROP_TOOLTIP, "Dinero ganancia o perdida");
   profitDineroBtn.Width(COL_WIDTH + 12);
   profitDineroBtn.Height(ROW_HEIGHT);
   profitDineroBtn.Text("0");
   profitDineroBtn.Font("Arial");
   profitDineroBtn.FontSize(FONT_SIZE);
   //RiesgoDinero.ColorBackground(clrWhite);
   UtilidadDinero.Color(clrBlack);
   //RiesgoDinero.ColorBorder(clrBlack);
   panel.Add(profitDineroBtn);


//Puntos FVG
   //puntosFvgText.Create(0, LABEL_PUNTOSFVGTEXT, 0, 4, 70, 0, 0);
   //puntosFvgText.Width(COL_WIDTH);
   //puntosFvgText.Height(ROW_HEIGHT);
   //puntosFvgText.Text("Puntos FVG");
   //puntosFvgText.Font("Arial");
   //puntosFvgText.FontSize(FONT_SIZE);
   ////puntosFvgText.ColorBackground(clrWhite);
   //puntosFvgText.Color(clrBlack);
   ////puntosFvgText.ColorBorder(clrBlack);
   //panel.Add(puntosFvgText);

//   if (_Symbol == "BTCUSD")
//   {
//      puntosFvg1 = 8000;
//   }
//
//   if (_Symbol == "EURUSD")
//   {
//      puntosFvg1 = 15;
//   }
//
//   if (_Symbol == "NZDUSD")
//   {
//      puntosFvg1 = 15;
//   }
//
//   if (_Symbol == "GBPUSD")
//   {
//      puntosFvg1 = 15;
//   }
//   if (_Symbol == "AUDUSD")
//   {
//      puntosFvg1 = 15;
//   }   
//
//   if (_Symbol == "USDCAD")
//   {
//      puntosFvg1 = 15;
//   }   
//
//
//   if (_Symbol == "USDJPY")
//   {
//      puntosFvg1 = 25;
//   }
//
//   if (_Symbol == "USTEC")
//   {
//      puntosFvg1 = 300;
//   }
//
//   if (_Symbol == "XAUUSD")
//   {
//      puntosFvg1 = 40;
//   }
//   
//
//  if (_Symbol == "XAUUSD")
//  {
//      puntosFvg1 = 100;
//  }    
//
//  if (_Symbol == "USTEC")
//  {
//      puntosFvg1 = 1500;
//  }    
//
//  if (_Symbol == "EURUSD")
//  {
//      puntosFvg1 = 60;
//  }    
//
//  if (_Symbol == "USDJPY")
//  {
//      puntosFvg1 = 100;
//  }    

   
   puntosFvg.Create(0, EDIT_PUNTOSFVG, 0, 0, 70, 0, 0);
   puntosFvg.Width(COL_WIDTH);
   puntosFvg.Height(ROW_HEIGHT);
   puntosFvg.Text(puntosFvg1);
   puntosFvg.Font("Arial");
   puntosFvg.FontSize(FONT_SIZE);
   puntosFvg.ColorBackground(clrWhite);
   puntosFvg.Color(clrBlack);
   puntosFvg.ColorBorder(clrBlack);
   puntosFvg.ZOrder(9999);
   panel.Add(puntosFvg);


   //ratioText.Create(0, LABEL_RATIOTEXT, 0, 4, 85, 0, 0);
   //ratioText.Width(COL_WIDTH);
   //ratioText.Height(ROW_HEIGHT);
   //ratioText.Text("Ratio 1:");
   //ratioText.Font("Arial");
   //ratioText.FontSize(FONT_SIZE);
   ////ratio.ColorBackground(clrWhite);
   //ratioText.Color(clrBlack);
   ////ratio.ColorBorder(clrBlack);
   //panel.Add(ratioText);


   color colorbtn = clrWhite;
   color colorborderbtn    = clrBlack;


   ratioBtn.Create(0, EDIT_RATIO, 0, COL_SPACE + COL_WIDTH, 70, 0, 0);
   ratioBtn.Width(COL_WIDTH);
   ratioBtn.Height(ROW_HEIGHT);
   ratioBtn.Text(0);
   ratioBtn.Font("Arial");
   ratioBtn.FontSize(FONT_SIZE);
   //ratio.ColorBackground(clrWhite);
   ratioBtn.Color(clrBlack);
   //ratio.ColorBorder(clrBlack);
   panel.Add(ratioBtn);

//--- Buy button
   buyBtn.Create(0, BUY_BTN_NAME, 0, 0, 100, 0, 0);
   ObjectSetString(0, buyBtn.Name(), OBJPROP_TOOLTIP, "Buy Market");
   buyBtn.Width(COL_WIDTH);
   buyBtn.Height(ROW_HEIGHT);
   buyBtn.ColorBackground(clrBlue);
   buyBtn.Text("Buy");
   buyBtn.Font("Arial");
   buyBtn.FontSize(FONT_SIZE);
   buyBtn.Color(colorbtn);
   buyBtn.ColorBorder(clrBlack);
   buyBtn.ZOrder(9999);
   panel.Add(buyBtn);

//--- sell button
   sellBtn.Create(0, SELL_BTN_NAME, 0, COL_SPACE + COL_WIDTH, 100, 0, 0);
   ObjectSetString(0, sellBtn.Name(), OBJPROP_TOOLTIP, "Sell Market");
   sellBtn.Width(COL_WIDTH);
   sellBtn.Height(ROW_HEIGHT);
   sellBtn.ColorBackground(clrRed);
   sellBtn.Text("Sell");
   sellBtn.Font("Arial");
   sellBtn.FontSize(FONT_SIZE);
   sellBtn.Color(colorbtn);
   sellBtn.ColorBorder(clrBlack);
   sellBtn.ZOrder(9999);
   panel.Add(sellBtn);

//--- Buy Limit button
   buyLimitBtn.Create(0, BUY_LIMIT_BTN_NAME, 0, 0, 115, 0, 0);
   ObjectSetString(0, buyLimitBtn.Name(), OBJPROP_TOOLTIP, "Buy Limit");
   buyLimitBtn.Width(COL_WIDTH);
   buyLimitBtn.Height(ROW_HEIGHT);
   buyLimitBtn.ColorBackground(clrBlue);
   buyLimitBtn.Text("BuyL");
   buyLimitBtn.Font("Arial");
   buyLimitBtn.FontSize(FONT_SIZE);
   buyLimitBtn.Color(colorbtn);
   buyLimitBtn.ColorBorder(clrBlack);
   buyLimitBtn.ZOrder(9999);
   panel.Add(buyLimitBtn);

//--- Sell Limit button
   sellLimitBtn.Create(0, SELL_LIMIT_BTN_NAME, 0, COL_SPACE + COL_WIDTH, 115, 0, 0);
   ObjectSetString(0, sellLimitBtn.Name(), OBJPROP_TOOLTIP, "Sell  Limit");
   sellLimitBtn.Width(COL_WIDTH);
   sellLimitBtn.Height(ROW_HEIGHT);
   sellLimitBtn.ColorBackground(clrRed);
   sellLimitBtn.Text("SellL");
   sellLimitBtn.Font("Arial");
   sellLimitBtn.FontSize(FONT_SIZE);
   sellLimitBtn.Color(colorbtn);
   sellLimitBtn.ColorBorder(clrBlack);
   sellLimitBtn.ZOrder(99999);
   panel.Add(sellLimitBtn);

//--- Buy Stop button
   buyStopBtn.Create(0, BUY_STOP_BTN_NAME, 0, 0, 130, 0, 0);
   ObjectSetString(0, buyStopBtn.Name(), OBJPROP_TOOLTIP, "Buy Stop");
   buyStopBtn.Width(COL_WIDTH);
   buyStopBtn.Height(ROW_HEIGHT);
   buyStopBtn.ColorBackground(clrBlue);
   buyStopBtn.Text("BuyS");
   buyStopBtn.Font("Arial");
   buyStopBtn.FontSize(FONT_SIZE);
   buyStopBtn.Color(colorbtn);
   buyStopBtn.ColorBorder(clrBlack);
   buyStopBtn.ZOrder(9999);
   panel.Add(buyStopBtn);

//--- Sell Stop button
   sellStopBtn.Create(0, SELL_STOP_BTN_NAME, 0, COL_SPACE + COL_WIDTH, 130, 0, 0);
   ObjectSetString(0, sellStopBtn.Name(), OBJPROP_TOOLTIP, "Sell Stop");
   sellStopBtn.Width(COL_WIDTH);
   sellStopBtn.Height(ROW_HEIGHT);
   sellStopBtn.ColorBackground(clrRed);
   sellStopBtn.Text("SellS");
   sellStopBtn.Font("Arial");
   sellStopBtn.FontSize(FONT_SIZE);
   sellStopBtn.Color(colorbtn);
   sellStopBtn.ColorBorder(clrBlack);
   sellStopBtn.ZOrder(99999);
   panel.Add(sellStopBtn);
   
//--- Enable button
   sl_pf_Btn.Create(0, SL_PF_BTN_NAME, 0, 0, 145, 0, 0);
   ObjectSetString(0, sl_pf_Btn.Name(), OBJPROP_TOOLTIP, "Set Stop Lost y Profit ");
   sl_pf_Btn.Width(COL_WIDTH);
   sl_pf_Btn.Height(ROW_HEIGHT);
   sl_pf_Btn.ColorBackground(clrRed);
   sl_pf_Btn.Text("SL PF");
   sl_pf_Btn.Font("Arial");
   sl_pf_Btn.FontSize(FONT_SIZE);
   sl_pf_Btn.Color(colorbtn);
   sl_pf_Btn.ColorBorder(clrBlack);
   sl_pf_Btn.ZOrder(99999);
   panel.Add(sl_pf_Btn);  
   
//--- Close button
   closeBtn.Create(0, CLOSE_BTN_NAME, 0, COL_SPACE + COL_WIDTH, 145, 0, 0);
   ObjectSetString(0, closeBtn.Name(), OBJPROP_TOOLTIP, "Cierra todas las operaciones");
   closeBtn.Width(COL_WIDTH);
   closeBtn.Height(ROW_HEIGHT);
   closeBtn.ColorBackground(clrBlue);
   closeBtn.Text("Close");
   closeBtn.Font("Arial");
   closeBtn.FontSize(FONT_SIZE);
   closeBtn.Color(colorbtn);
   closeBtn.ColorBorder(clrBlack);
   closeBtn.ZOrder(99999);
   panel.Add(closeBtn);   
   
//--- BE button
   beBtn.Create(0, BE_BTN_NAME, 0, 0, 165, 0, 0);
   ObjectSetString(0, beBtn.Name(), OBJPROP_TOOLTIP, "Break Even");
   beBtn.Width(COL_WIDTH);
   beBtn.Height(ROW_HEIGHT);
   beBtn.ColorBackground(clrBlue);
   beBtn.Text("BE");
   beBtn.Font("Arial");
   beBtn.FontSize(FONT_SIZE);
   beBtn.Color(colorbtn);
   beBtn.ColorBorder(clrBlack);
   beBtn.ZOrder(99999);
   panel.Add(beBtn);   

//--- Show Macros y Killzone button
   showMacrosKillzoneBtn.Create(0, SHOW_MACROS_KILLZOME_BTN_NAME, 0, COL_SPACE + COL_WIDTH, 165, 0, 0);
   ObjectSetString(0, showMacrosKillzoneBtn.Name(), OBJPROP_TOOLTIP, "Muestra u ocualta las Macros y Killzones ");
   showMacrosKillzoneBtn.Width(COL_WIDTH);
   showMacrosKillzoneBtn.Height(ROW_HEIGHT);
   showMacrosKillzoneBtn.ColorBackground(clrBlue);
   showMacrosKillzoneBtn.Text("Hidden");
   showMacrosKillzoneBtn.Font("Arial");
   showMacrosKillzoneBtn.FontSize(FONT_SIZE);
   showMacrosKillzoneBtn.Color(colorbtn);
   showMacrosKillzoneBtn.ColorBorder(clrBlack);
   showMacrosKillzoneBtn.ZOrder(99999);
   panel.Add(showMacrosKillzoneBtn);   

   if (VGShowMacrosKillzone == true)
   {
      showMacrosKillzoneBtn.ColorBackground(clrRed);
      showMacrosKillzoneBtn.Text("Hidden Macros");
   }
   
   else
   {
      showMacrosKillzoneBtn.ColorBackground(clrBlue);
      showMacrosKillzoneBtn.Text("Show Macros");
   }
   
//--- Show Fvg button
   showFvgBtn.Create(0, SHOW_FVG_BTN_NAME, 0, 0 , 185, 0, 0);
   ObjectSetString(0, showFvgBtn.Name(), OBJPROP_TOOLTIP, "Muestra u ocualta FVG ");
   showFvgBtn.Width(COL_WIDTH);
   showFvgBtn.Height(ROW_HEIGHT);
   showFvgBtn.ColorBackground(clrBlue);
   showFvgBtn.Text("Show Fvg");
   showFvgBtn.Font("Arial");
   showFvgBtn.FontSize(FONT_SIZE);
   showFvgBtn.Color(colorbtn);
   showFvgBtn.ColorBorder(clrBlack);
   showFvgBtn.ZOrder(99999);
   panel.Add(showFvgBtn);  
    
   if( VGShowFvg == true)
   {
      showFvgBtn.Text("Hidden Fvg");
      showFvgBtn.ColorBackground(clrRed);
   }
   else
   {
      showFvgBtn.Text("Show Fvg");
   }


   m1Btn.Create(0, M1_BTN_NAME, 0, 0 , 205, 0, 0);
   ObjectSetString(0, m1Btn.Name(), OBJPROP_TOOLTIP, "Tendencia M1 ");
   m1Btn.Width(COL_WIDTH);
   m1Btn.Height(ROW_HEIGHT);
   m1Btn.ColorBackground(clrGray);
   m1Btn.Text("M1");
   m1Btn.Font("Arial");
   m1Btn.FontSize(FONT_SIZE);
   m1Btn.Color(colorbtn);
   m1Btn.ColorBorder(clrBlack);
   m1Btn.ZOrder(99999);
   panel.Add(m1Btn);  


//--- Tendencia M3 - M15 - H1 - H5 - D1
   m3Btn.Create(0, M3_BTN_NAME, 0, 0 , 225, 0, 0);
   ObjectSetString(0, m3Btn.Name(), OBJPROP_TOOLTIP, "Tendencia M3 ");
   m3Btn.Width(COL_WIDTH);
   m3Btn.Height(ROW_HEIGHT);
   m3Btn.ColorBackground(clrGray);
   m3Btn.Text("M3");
   m3Btn.Font("Arial");
   m3Btn.FontSize(FONT_SIZE);
   m3Btn.Color(colorbtn);
   m3Btn.ColorBorder(clrBlack);
   m3Btn.ZOrder(99999);
   panel.Add(m3Btn);  

 
   m15Btn.Create(0, M15_BTN_NAME, 0, 0 , 245, 0, 0);
   ObjectSetString(0, m15Btn.Name(), OBJPROP_TOOLTIP, "Tendencia M15 ");
   m15Btn.Width(COL_WIDTH);
   m15Btn.Height(ROW_HEIGHT);
   m15Btn.ColorBackground(clrGray);
   m15Btn.Text("M15");
   m15Btn.Font("Arial");
   m15Btn.FontSize(FONT_SIZE);
   m15Btn.Color(colorbtn);
   m15Btn.ColorBorder(clrBlack);
   m15Btn.ZOrder(99999);
   panel.Add(m15Btn);  


   h1Btn.Create(0, H1_BTN_NAME, 0, 0 , 265, 0, 0);
   ObjectSetString(0, h1Btn.Name(), OBJPROP_TOOLTIP, "Tendencia H1 ");
   h1Btn.Width(COL_WIDTH);
   h1Btn.Height(ROW_HEIGHT);
   h1Btn.ColorBackground(clrGray);
   h1Btn.Text("H1");
   h1Btn.Font("Arial");
   h1Btn.FontSize(FONT_SIZE);
   h1Btn.Color(colorbtn);
   h1Btn.ColorBorder(clrBlack);
   h1Btn.ZOrder(99999);
   panel.Add(h1Btn);  


   h4Btn.Create(0, H4_BTN_NAME, 0, 0 , 285, 0, 0);
   ObjectSetString(0, h4Btn.Name(), OBJPROP_TOOLTIP, "Tendencia H4 ");
   h4Btn.Width(COL_WIDTH);
   h4Btn.Height(ROW_HEIGHT);
   h4Btn.ColorBackground(clrGray);
   h4Btn.Text("H4");
   h4Btn.Font("Arial");
   h4Btn.FontSize(FONT_SIZE);
   h4Btn.Color(colorbtn);
   h4Btn.ColorBorder(clrBlack);
   h4Btn.ZOrder(99999);
   panel.Add(h4Btn);  


   d1Btn.Create(0, D1_BTN_NAME, 0, 0 , 305, 0, 0);
   ObjectSetString(0, d1Btn.Name(), OBJPROP_TOOLTIP, "Tendencia D1 ");
   d1Btn.Width(COL_WIDTH);
   d1Btn.Height(ROW_HEIGHT);
   d1Btn.ColorBackground(clrGray);
   d1Btn.Text("D1");
   d1Btn.Font("Arial");
   d1Btn.FontSize(FONT_SIZE);
   d1Btn.Color(colorbtn);
   d1Btn.ColorBorder(clrBlack);
   d1Btn.ZOrder(99999);
   panel.Add(d1Btn);  


//run the panel
   panel.Run();

//Sleep(1);   

//---
   //CrearLineas();
   //MaximoMinimo();
   MaximoMinimo();
   //Alarmas();
   //ProgramarCompraVenta();
   
   Promedioaltovelas();
   
   
   DrawBarFractals(PERIOD_M3, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   DrawBarFractals(PERIOD_M15, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   DrawBarFractals(PERIOD_H1, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   DrawBarFractals(PERIOD_H4, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   DrawBarFractals(PERIOD_D1, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 

   Tendencia();

   DrawBarFractals(_Period, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
   
   
//---
   return(INIT_SUCCEEDED);
  }
  
  
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  
   panel.Destroy(reason);
  
   //ObjectsDeleteAll(0, -1, -1);  // Eliminar todos los objetos
      
   //ObjectsDeleteAll(0);

   EventKillTimer();
//---
  }
 
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {


    static datetime lastAlertTime = 0;
        
    VGumbral = inpumbral;
    
    // Verificar cada segundo para evitar alertas repetidas
    if(TimeCurrent() - lastAlertTime >= 1)
    {
        //CheckFVGAlerts();
        lastAlertTime = TimeCurrent();
    }
    //StringFind(_Symbol,"USDJPY")

    // Obtener la hora de Nueva York
    //datetime newYorkTime = GetNewYorkTime();
    //Comment("Hora NY : ",newYorkTime);

      
    // Actualizar la línea de promedio en cada tick
    //ActualizarLineaPromedio();  
    
    

   // Verificar si ha pasado un segundo desde la última ejecución
   if(TimeCurrent() - lastTime >= 1)
   {

//      lastTime = TimeCurrent();
//      //Print("Simulación de OnTimer() ejecutada.");
//      // Calcular tiempo restante para el cierre de la vela actual
//      datetime currentTime = TimeCurrent();
//      datetime candleCloseTime = iTime(Symbol(), Period(), 0) + PeriodSeconds() - 1;
//      int secondsRemaining = (int)(candleCloseTime - currentTime);
//      if(secondsRemaining < 0) secondsRemaining = 0;
//      
//      int hours = secondsRemaining / 3600;
//      int minutes = (secondsRemaining % 3600) / 60;
//      int seconds = secondsRemaining % 60;   
//      
//      string timerText =   minutes + ":" + seconds + " " + DoubleToString(VGPorcentaje,2) + "%";
//      if (hours > 0)
//       timerText =  hours + ":" + minutes + ":" + seconds + DoubleToString(VGPorcentaje,2) + "%" ;
//      
//      // Obtener coordenadas de la vela futura
//      //Print("timerText :",timerText);
//      datetime futureCandleTime = iTime(Symbol(), Period(), 0) + (5 * PeriodSeconds());
//      double bidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Precio Bid actual
//      // Actualizar el texto
//      ObjectSetString(0, labelNameCandleTimer, OBJPROP_TEXT, timerText);
//      ObjectMove(0, labelNameCandleTimer, 0, futureCandleTime, bidPrice);

   }


   if (sl_pf_Btn1 == true)
   {
      sl_pf_Btn.ColorBackground(clrBlue);
      sl_pf_Btn.Text("SL PF");
   } 
   if (sl_pf_Btn1 == false)
   {
      sl_pf_Btn.ColorBackground(clrRed);
      sl_pf_Btn.Text("SL PF");
   } 

   //---    
    VGHoraInicio = TimeCurrent() - 20000; 

   int lvcolor = ObjectGetInteger(0, "maximo_M15", OBJPROP_COLOR);
   
   
   if (lvcolor > -1)
   {
      //Print("German");
      //ObjectSetInteger(0,"Text_Venta",OBJPROP_COLOR,clrWhite);   
      //ObjectSetInteger(0,"Text_Compra",OBJPROP_COLOR,clrWhite);   
      ProgramarCompraVenta();
   }    

    //Crear lineas de compra y venta 
    //CrearLineas();
    //Alarmas();     


    if( ContadorSonido  == 1)
    {
       //Sleep(1000);
       //Print("Prueba sonido ...");
       //PlaySound("news.wav");
       ContadorSonido = 0; 
    }
 
//    // Obtener la hora actual
//   TimeToStruct(TimeCurrent(), MiHoraInicio);
//   
//   string lvsimbolo = _Symbol; 
//   if(MiHoraInicio.hour >= 0 && MiHoraInicio.hour < 1 && lvsimbolo != "BTCUSD") 
//   {
//      //Print(" Hora :",MiHoraInicio.hour);
//      return;
//   }

    //Print("hora :",MiHoraInicio.hour );
    
   //NumeroOperaciones();  
        
   Alarmas();
      
   //if(Bid > ValorAltoM5 || Bid < ValorBajoM5)
   //{
   //    //Calcular numero de operaciones para posibel compra
   //    NumeroOperaciones();  
   //}

   //MaximoMinimo();
   if (VGtotalOrdenesAbiertas > 0 ) //&& sl_pf_Btn1 == true)
      ManejoStopLoss();  //Manejar los stop loss
      
   //Calcular ganacia o perdidad si hay operaciones abiertas
   if (VGtotalOrdenesAbiertas > 0)
      GetOpenPositionsProfitAndPercentage();
   
   //EstrategiaZB();
   //AlarmaaltovelaZB();
   //AlarmavelaZB();
   //AlarmaM15();
   
   // Obtener el tiempo de apertura de la vela actual de 1 minuto
   datetime currentCandleTimeM1 = iTime(NULL, PERIOD_M1, 0);

   // Comparar el tiempo de la vela actual con el tiempo de la vela anterior
   if(currentCandleTimeM1 != previousCandleTimeM1)
     {

//      if ( MQLInfoInteger(MQL_TESTER))
//      {
//         fibo("1");
//         fibo("2");
//   
//         ObjectsDeleteAll(0, "Fractal_"); 
//         VGHTF_Name = TimeframeToString(VGtime_Frame_Fractal);
//         DrawBarFractals(VGtime_Frame_Fractal, 500, 35, "2");// Fractal para el fibo de M15 y 1000 velas y 25 para detectar el fibo 
//           
//         DrawBarFractals(PERIOD_M15, 500, 25, "5" );// Fractal para soporte y resistencia del periodo actual  
//      }
          //DrawBarFractals(PERIOD_CURRENT, 500, 6, "7" );// Parametro 7 es para solo actualizar el fractal
                    
      CheckFVGAlerts(PERIOD_CURRENT);
      
      VGHTF_Name = TimeframeToString(VGTime_Frame_HT);
      
      ObjectsDeleteAll(0, "FVG_");
      
      DrawFVG(VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);

      //para detectar zonas de compra y venta
      //VGHTF_Name = TimeframeToString(PERIOD_H4);
      //DrawFVG(PERIOD_H4, Velas_FVG_HTF, VGcolor_zona_compra_venta, VGcolor_zona_compra_venta, 0); //para detectar zonas de compra y venta


      DrawFVG(VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);


         if (StringFind(_Symbol,"USDJPY") >=0 )
            samurai();
         

         //AlarmaImmediateRebalance_vela_1(PERIOD_M1, "M1");
         //AlarmaImmediateRebalance_vela_1(PERIOD_M3, "M3");
         //AlarmaImmediateRebalance_vela_1(PERIOD_M5, "M5");
         //AlarmaImmediateRebalance_vela_1(PERIOD_M10,"M10");
         //AlarmaImmediateRebalance_vela_1(PERIOD_M15,"M15");
         //AlarmaImmediateRebalance_vela_1(PERIOD_M30,"M30");
         //AlarmaImmediateRebalance_vela_1(PERIOD_H1, "H1");
         //AlarmaImmediateRebalance_vela_1(PERIOD_H2, "H2");
         //AlarmaImmediateRebalance_vela_1(PERIOD_H4, "H4");
         //AlarmaImmediateRebalance_vela_1(PERIOD_H8, "H8");
         //AlarmaImmediateRebalance_vela_1(PERIOD_H12,"H12");
         //AlarmaImmediateRebalance_vela_1(PERIOD_D1,"D1");
         //AlarmaImmediateRebalance_vela_1(PERIOD_W1,"W1");
         //AlarmaImmediateRebalance_vela_1(PERIOD_MN1,"MN1");
         
         
         //DetectImmediateRebalancePattern(PERIOD_M1);
         //DetectImmediateRebalancePattern(PERIOD_M3);
         //DetectImmediateRebalancePattern(PERIOD_M5);
         //DetectImmediateRebalancePattern(PERIOD_M10);
         //DetectImmediateRebalancePattern(PERIOD_M15);
         DetectImmediateRebalancePattern(PERIOD_H1);
         DetectImmediateRebalancePattern(PERIOD_H2);
         DetectImmediateRebalancePattern(PERIOD_H4);
         DetectImmediateRebalancePattern(PERIOD_H6);
         DetectImmediateRebalancePattern(PERIOD_H8);
         DetectImmediateRebalancePattern(PERIOD_H12);
         DetectImmediateRebalancePattern(PERIOD_D1);
         
         //PerfectPriceDelivered esta temporalmente suspenidad
         //PerfectPriceDelivered(PERIOD_M15, "M15");
         //PerfectPriceDelivered(PERIOD_H1, "H1");
         //PerfectPriceDelivered(PERIOD_H4, "H4");
         
         if (mostrar_phpl == true)
            DrawPDHPDL_PWHPWL(); 
         
         ////Actaliza FVG M15
         //ActualizarFVGM15();
         //ObjectsDeleteAll(0, "FVG_");
         //DrawFVG(PERIOD_CURRENT, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M1, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M2, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M3, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M5, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M10, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M15, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M20, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         //DrawFVG(PERIOD_M30, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         
         //Soporte_Resistencia();

         // Ha comenzado una nueva vela de 1 minuto
         //Print("Nueva vela de 1 minuto detectada. Tiempo de apertura: ", TimeToString(currentCandleTimeM1, TIME_DATE | TIME_MINUTES));
         
         AlarmaFVG();
         
         // Aquí puedes agregar cualquier acción que desees realizar cuando cambie la vela
         
         // Actualizar el tiempo de la vela anterior
         
         Promedioaltovelas();
         
         ContadorvelaZB = 0;
         
         previousCandleTimeM1 = currentCandleTimeM1;
         
//         if (Bid < VGResistencia && VGContadorAlertasDiscount == 1)
//             VGContadorAlertasDiscount = 0;
//             
//         if (Bid > VGSoporte && VGContadorAlertasOte == 1)   
//             VGContadorAlertasOte = 0;
         
     }

   // Obtener el tiempo de apertura de la vela actual de 15 minuto
   datetime currentCandleTimeM15 = iTime(NULL, PERIOD_M1, 0);

   // Comparar el tiempo de la vela actual con el tiempo de la vela anterior
   if(currentCandleTimeM15 != previousCandleTimeM15 && mostrar_fvg)
     {
         //ObjectsDeleteAll(0, "FVG_");
         //DrawFVG( VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);
         //DrawFVG( VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         previousCandleTimeM15 = currentCandleTimeM15;
         //Soporte_Resistencia(1);
     }

   
   static datetime dtBarCurrent=WRONG_VALUE;
   datetime dtBarPrevious=dtBarCurrent;

   dtBarCurrent=(datetime) SeriesInfoInteger(_Symbol,_Period,SERIES_LASTBAR_DATE);
   bool NewBarFlag=(dtBarCurrent!=dtBarPrevious);
   if(NewBarFlag)
   {
      //ContadorAlertas = 0;
      //ObjectsDeleteAll(0,"Soporte");
      //ObjectsDeleteAll(0,"Resistencia");
      //ObjectsDeleteAll(0,"Valor");
      //ObjectsDeleteAll(0,"Bajo");
      //ObjectsDeleteAll(0,"Alto");
      //ObjectsDeleteAll(0,"maximo");
      //ObjectsDeleteAll(0,"minimo");
      //ContadorRatio = 0;

   }

//   if (Bid > VGMaximo2 )
//       VGcontadorAlertasBajista = 1;
//
//   if (Bid < VGMinimo2 )
//       VGcontadorAlertasAlcista = 1;
//


   long MiSpread = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
   //Print("Bid :",Bid, "  maximo[0] : ",maximo[0]," minimo[0] : ", minimo[0]);

  }

//+------------------------------------------------------------------+
//| OnStart function                                                   |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Script para mantener margen derecho fijo (50 velas)              |
//| Funciona incluso con Chart Shift activado                       |
//+------------------------------------------------------------------+
//void OnStart()
//  {
////--- Desactivar autoajuste y forzar margen
//   ChartSetInteger(0, CHART_SHIFT, false);    // Desactiva Chart Shift temporalmente
//   ChartSetInteger(0, CHART_SCALEFIX, true);  // Fija la escala
//   ChartSetInteger(0, CHART_AUTOSCROLL, false); // Evita desplazamiento automático
//   
////--- Calcular margen para 10 velas
//   int bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
//   int targetBars = bars + 100;  // Añade 10 velas de margen
//   
////--- Aplicar ajuste
//   ChartNavigate(0, CHART_END, -targetBars); // Desplaza el gráfico
//   
////--- Reactivar Chart Shift si lo necesitas (opcional)
//   ChartSetInteger(0, CHART_SHIFT, true);
//   
//   Comment("Margen derecho fijado a 10 velas \n(Para eliminar, cierre el script)");
//   Print("ger,man");
//  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {


      if(VGHoraNewYork.hour == 0)
      {
         VGtradedia = 0;
      }
      //ProgramarCompraVenta(); 
      string lvtendencia;
      if(inptendencia)
      {
         lvtendencia = "Alcista";
      }
      else
      {
         lvtendencia = "Bajista";
      } 

      // Obtener la hora de Nueva York

      VGnewYorkTime = GetNewYorkTime();
      TimeToStruct(VGnewYorkTime, VGHoraNewYork);
      
      if(VGHoraNewYork.hour == 16 && VGHoraNewYork.min == 50)
         //CloseAllPositions();
      
      
      
      
      
      VGAlarma_modelo2022 = false;
      //DrawBarFractals(Time_Frame_M2022, 500, velas_verificar_fractal, "5" ); //El parametro 5 es para alartas Modelo 2022     
      if (VGHoraNewYork.sec > 0)//  || VGHoraNewYork.sec == 15 || VGHoraNewYork.sec == 30 || VGHoraNewYork.sec == 45)// || VGHoraNewYork.sec == 45 || VGHoraNewYork.sec == 58 )
         DrawBarFractals(Time_Frame_M2022, 50, velas_verificar_fractal, "5" ); //El parametro 5 es para alartas Modelo 2022     

//      {
//         if( VGfecha_noticia_anterior >  100)
//         {
//            int lvminutos = (VGfecha_noticia_anterior - TimeCurrent()) / 60; 
//            //Print( " VGfecha_noticia_anterior : ",VGfecha_noticia_anterior , " lvminutos : ",lvminutos );
//         }  
//
//          DrawBarFractals(Time_Frame_M2022, 500, velas_verificar_fractal, "5" ); //El parametro 5 es para alartas Modelo 2022
//             
//      } 
      
      string lv_tendencia_interna;
      string lv_tendencia_externa;
      if (VGTipo_tendencia_interna == true)
         lv_tendencia_interna = "  !!!DEALING RANGE!!!";
      if (VGTipo_tendencia_externa == true)
         lv_tendencia_externa = "  !!!DEALING RANGE!!!";
         
      Comment(
      "Hora NY : ",VGnewYorkTime, 
      " Tendencia : Interna : ", VGTendencia_interna, 
      " Externa : ", VGTendencia_externa, 
      " HTF : ", VGHTF_Name_Fractal, 
      " VGmodelo2022 : ",VGmodelo2022,
      " Minutos Noticias : ",VGminutos_noticias,
      " Prioridad : ",VGprioridad_noticias , 
      " VGcumplerregla : ",VGcumplerregla, 
      " VGContadorPosible2022   : ", VGContadorPosible2022,
      " VGcontadorAlertasAlcista  : ", VGcontadorAlertasAlcista, 
      " VGcontadorAlertasBajista  : ", VGcontadorAlertasBajista ,
      " VGbag : ",VGbag,
      " VGCompra : ",VGCompra,
      " VGVenta : ",VGVenta);      
        
      datetime now = TimeLocal();

      lastTime = TimeCurrent();
      //Print("Simulación de OnTimer() ejecutada.");
      // Calcular tiempo restante para el cierre de la vela actual
      datetime currentTime = TimeCurrent();
      datetime candleCloseTime = iTime(Symbol(), Period(), 0) + PeriodSeconds() - 1;
      int secondsRemaining = (int)(candleCloseTime - currentTime);
      if(secondsRemaining < 0) secondsRemaining = 0;
      
      int hours = secondsRemaining / 3600;
      int minutes = (secondsRemaining % 3600) / 60;
      int seconds = secondsRemaining % 60;   
      
      string timerText =   minutes + ":" + seconds + " " + DoubleToString(VGPorcentaje,0) + "%"; //  + " " + DoubleToString(VGPorcentaje_externa,0) + "%";
      if (hours > 0)
       timerText =  hours + ":" + minutes + ":" + seconds + " " + DoubleToString(VGPorcentaje,0) + "%"; //  + " " + DoubleToString(VGPorcentaje_externa,0) + "%";
      
      // Obtener coordenadas de la vela futura
      //Print("timerText :",timerText);
      datetime futureCandleTime = iTime(Symbol(), Period(), 0) + (5 * PeriodSeconds());
      double bidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID); // Precio Bid actual
      // Actualizar el texto
      ObjectSetString(0, labelNameCandleTimer, OBJPROP_TEXT, timerText);
      ObjectSetInteger(0, labelNameCandleTimer, OBJPROP_FONTSIZE, 8);
      ObjectMove(0, labelNameCandleTimer, 0, futureCandleTime, bidPrice);

//Print("zbgerman ", TimeCurrent(), "timerText:",timerText);

   if(now - lastActionFvgM15 >= intervalFvgM15) // Cada 900 segundosmo
   {
      lastActionFvgM15 = now;
      
      DrawBarFractals(PERIOD_M15, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      DrawBarFractals(PERIOD_H1, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      DrawBarFractals(PERIOD_H4, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      DrawBarFractals(PERIOD_D1, 1000, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      
      Tendencia();
      ContadorModelo2022 = 0;
      VGContadorPosible2022 = 0;
      VGcumplerregla = false;
      ReglasModelo2022();
      
      Bias(PERIOD_W1);
      Bias(PERIOD_D1);
      Bias(PERIOD_H4);
      Bias(PERIOD_H1);
      
      //DrawBarFractals(PERIOD_M15, 500, 15, "1");// Fractal para el fibo de M15 y 500 velas y 20 para detectar el fibo   
   }

   if(now - lastActionModelo2022 >= intervalModelo2022M5) // Cada 60 segundos
   {
      lastActionModelo2022 = now;
      
      DrawBarFractals(PERIOD_M1, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      DrawBarFractals(PERIOD_M3, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      
      Tendencia();
      
      DrawBarFractals(_Period, 500, 30, "1");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo 
      DrawBarFractals(VGtime_Frame_Fractal, 500, 30, "2");// Fractal para el fibo de M15 y 1000 velas y 30 para detectar el fibo

      double lvnumero_velas_verificar_fvg =  15;
      DrawFVG(PERIOD_M1, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);//para contar fvg dentro del rango de precios

      
      ContadorModelo2022 = 0;
      VGContadorPosible2022 = 0;
      VGcumplerregla = false;
      ReglasModelo2022();
      
   }

   if(now - lastActionNoticias >= NoticiasInterval) // 180 segundos
   {
      noticias();
      lastActionNoticias = now;
      // Posicionar 5 velas en el futuro desde la vela actual
      datetime futureTime = iTime(_Symbol, _Period, 0) + (5 * PeriodSeconds());  
      
      string name_object = "ZONA_VENTAS";
      //ObjectSetInteger(0,name_object,OBJPROP_COLOR,C'95,95,95');
      ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
      ObjectSetInteger(0,name_object,OBJPROP_TIME,1,futureTime);
      ObjectSetInteger(0,name_object,OBJPROP_FILL,false);
      
      name_object = "ZONA_COMPRAS";
      //ObjectSetInteger(0,name_object,OBJPROP_COLOR,C'95,95,95');
      ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
      ObjectSetInteger(0,name_object,OBJPROP_TIME,1,futureTime);
      ObjectSetInteger(0,name_object,OBJPROP_FILL,false);     
   }
   
   if(now - fibolastAction >= fiboInterval) // 60 segundos
   {

//      fibo("1");
//      fibo("2");
//
//      ObjectsDeleteAll(0, "Fractal_"); 
//      DrawBarFractals(VGtime_Frame_Fractal, 1000, 25, "2");// Fractal para el fibo de M15 y 1000 velas y 25 para detectar el fibo   
//      DrawBarFractals(PERIOD_CURRENT, 500, 4, "1" );// Fractal para soporte y resistencia del periodo actual  
//      
//      
//      VGHTF_Name = TimeframeToString(VGTime_Frame_HT);
//      
//      ObjectsDeleteAll(0, "FVG_");
//      
//      DrawFVG(VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);
//      DrawFVG(VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
      
      //Detectar una vela de gran tamano 
      //AlarmavelaZB();

      fibolastAction = now;
   }
   
   if(now - lastActionB >= intervalB && VGShowMacrosKillzone == true) //60 segundos
   {
           
         DrawMacro_Session_Lunch(50); //Para Macros 
         DrawMacro_Session_Lunch(51); //Para Macros 
         DrawMacro_Session_Lunch(52); //Para Macros 
         DrawMacro_Session_Lunch(53); //Para Macros 
         DrawMacro_Session_Lunch(54); //Para Macros 
         DrawMacro_Session_Lunch(55); //Para Macros 
         DrawMacro_Session_Lunch(56); //Para Macros 
         DrawMacro_Session_Lunch(57); //Para Macros 
         DrawMacro_Session_Lunch(58); //Para Macros 
         DrawMacro_Session_Lunch(59); //Para Macros 
         DrawMacro_Session_Lunch(60); //Para Macros 
         DrawMacro_Session_Lunch(61); //Para Macros 
         DrawMacro_Session_Lunch(62); //Para Macros 
         DrawMacro_Session_Lunch(63); //Para Macros 
         DrawMacro_Session_Lunch(64); //Para Macros 
         DrawMacro_Session_Lunch(65); //Para Macros 
         DrawMacro_Session_Lunch(66); //Para Macros 
         DrawMacro_Session_Lunch(67); //Para Macros 
         DrawMacro_Session_Lunch(68); //Para Macros 
         DrawMacro_Session_Lunch(69); //Para Macros 
         DrawMacro_Session_Lunch(70); //Para Macros 
         DrawMacro_Session_Lunch(71); //Para Macros 
         
         DrawMacro_Session_Lunch(2); //Para Lunch
         DrawMacro_Session_Lunch(3); //Asia Session
         DrawMacro_Session_Lunch(4); //Londres Session
         DrawMacro_Session_Lunch(5); //New York Session
         
         DrawMacro_Session_Lunch(10); //Silver Bullet Londres
         DrawMacro_Session_Lunch(11); //Silver Bullet NY AM
         DrawMacro_Session_Lunch(12); //Silver Bullet NY PM
         
         DrawMacro_Session_Lunch(13); //Macro Opening Range

      lastActionB = now;
   }

   //AlarmaImmediateRebalance(PERIOD_M15, "M15");
   //AlarmaImmediateRebalance(PERIOD_H1, "H1");
   //AlarmaImmediateRebalance(PERIOD_H4, "H4");

 
   if(now - lastActionC >= intervalC) //15  Segundos
   {
       //para detectar en cada segundo la posible compra o venta
      //DrawBarFractals(PERIOD_CURRENT, 500, 6, "1" );// Fractal para soporte y resistencia del periodo actual  
           
     VGContadorAlertasOte = 0;
     VGContadorAlertasOte_M1 = 0;
     VGContadorAlertasOte_M3 = 0;
     VGContadorAlertasOte_M15 = 0;
     VGContadorAlertasOte_H1 = 0;
     
     VGContadorAlertasZona = 0;
     VGContadorAlertasZona_M1 = 0;
     VGContadorAlertasZona_M3 = 0;
     VGContadorAlertasZona_M15 = 0;
     VGContadorAlertasZona_H1 = 0;

      lastActionC = now;
   }


   if(now - lastActionD >= RejectionBlockInterval) //  900 segundos
   {
//      IsBullishRejectionBlock(PERIOD_M15, 1);
//      IsBearishRejectionBlock(PERIOD_M15, 1);
//
//      IsBullishRejectionBlock(PERIOD_H1, 1);
//      IsBearishRejectionBlock(PERIOD_H1, 1);
//
//      IsBullishRejectionBlock(PERIOD_H4, 1);
//      IsBearishRejectionBlock(PERIOD_H4, 1);
      lastActionD = now;
   }


  }
  
  
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
      verificar_ordenes_Abiertas();
   
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
    // Filtrar solo transacciones relacionadas con órdenes ejecutadas
    if (trans.type == TRADE_TRANSACTION_ORDER_ADD || 
        trans.type == TRADE_TRANSACTION_ORDER_UPDATE ||
        trans.type == TRADE_TRANSACTION_DEAL_ADD ||
        trans.type == TRADE_TRANSACTION_DEAL_UPDATE ||
        trans.order_state == TRADE_ACTION_PENDING
        )
    {
        //PrintFormat("Nueva transacción detectada: \nTipo: %d\nOrden: %d\nPrecio: %.5f",
        //            trans.type, trans.order, trans.price);
        CrearLineaPromedio();            
        ActualizarLineaPromedio();
        //Manejor stop loss
        VGtotalOrdenesAbiertas = 0;
        ManejoStopLoss();
        //verificar_ordenes_Abiertas();
            
    }         
}

////+------------------------------------------------------------------+
////| Tester function                                                  |
////+------------------------------------------------------------------+
//double OnTester()
//  {
////---
//   double ret=0.0;
////---
//
////---
//   return(ret);
//  }
////+------------------------------------------------------------------+
////| TesterInit function                                              |
////+------------------------------------------------------------------+
//void OnTesterInit()
//  {
////---
//   
//  }
////+------------------------------------------------------------------+
////| TesterPass function                                              |
////+------------------------------------------------------------------+
//void OnTesterPass()
//  {
////---
//   
//  }
////+------------------------------------------------------------------+
////| TesterDeinit function                                            |
////+------------------------------------------------------------------+
//void OnTesterDeinit()
//  {
////---
//   
//  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {


   VGscale = ChartGetInteger(0,CHART_SCALE,0);
   //Print("id :",id, " VGscale :",VGscale);
   
   if (id == 9)//9 es cuando se cambia la Scala del grafico o zoom
   {
      string obj_name_maximo="maximo_M15";
      string obj_name_minimo="minimo_M15";
      // Obtener el tiempo de la primera y última vela visible en el gráfico
      datetime tiempoInicio;// = iTime(_Symbol, _Period, 15);
      datetime tiempoFin = iTime(_Symbol, _Period, 0);
      //Print("id :",id, " VGscale :",VGscale);

      switch (VGscale)
      {
         case 0:   
            tiempoInicio = iTime(_Symbol, _Period, 192);
            break;
         case 1:   
            tiempoInicio = iTime(_Symbol, _Period, 120);
            break;
         case 2:   
            tiempoInicio = iTime(_Symbol, _Period, 60);
            break;
         case 3:   
            tiempoInicio = iTime(_Symbol, _Period, 30);
            break;
         case 4:   
            tiempoInicio = iTime(_Symbol, _Period, 15);
            break;
         case 5:   
            tiempoInicio = iTime(_Symbol, _Period, 8);
            break;
      }
      ObjectSetInteger(0,obj_name_maximo,OBJPROP_TIME,0,tiempoInicio);
      ObjectSetInteger(0,obj_name_maximo,OBJPROP_TIME,1,tiempoFin);
      ObjectSetInteger(0,obj_name_minimo,OBJPROP_TIME,0,tiempoInicio);
      ObjectSetInteger(0,obj_name_minimo,OBJPROP_TIME,1,tiempoFin);
   
   }
   
   int lvnumerocompras = StringToInteger(porcentajeUtilidad.Text());
   //porcentajeUtilidad.Text(lvnumerocompras);

   panel.ChartEvent(id, lparam, dparam, sparam);

//   double lot=StringToDouble(lotSize.Text());
//   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
//
//   if (lot < minLot)
//      lot = minLot;

   if (id == CHARTEVENT_MOUSE_MOVE)

   {
        int lvflag = 0;
        int lvcolor = ObjectGetInteger(0, "maximo_M15", OBJPROP_COLOR);
        
        string rectName = CheckRectHoverPrice("maximo_M15",lparam,dparam);
        
        if(rectName == "maximo_M15" && lvcolor > -1)
        {
           lvflag = 1;       
           ObjectSetInteger(0, rectName, OBJPROP_SELECTED, true);
           ObjectSetInteger(0, "Text_Venta", OBJPROP_COLOR, clrWhite);
           ObjectSetInteger(0, "Text_Compra", OBJPROP_COLOR, clrWhite);
       }

       string rectName1 = CheckRectHoverPrice("minimo_M15",lparam,dparam);
        
        if(rectName1 == "minimo_M15" &&  lvcolor > -1 )
        {
           lvflag = 1;
           ObjectSetInteger(0, rectName1, OBJPROP_SELECTED, true);
           ObjectSetInteger(0, "Text_Venta", OBJPROP_COLOR, clrWhite);
           ObjectSetInteger(0, "Text_Compra", OBJPROP_COLOR, clrWhite);
       }
       if(lvflag == 0)
       {
           //ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED, false);
           //ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED, false);
           ObjectSetInteger(0, "Text_Venta", OBJPROP_COLOR, clrNONE);
           ObjectSetInteger(0, "Text_Compra", OBJPROP_COLOR, clrNONE);
       }        
           
       string lineName1 = IsMouseNearHorizontalLine("Resistencia",lparam,dparam);
       
       //Print("lineName1 : ",lineName1); 
        if(lineName1 == "Resistencia" )
        {
           ObjectSetInteger(0, lineName1, OBJPROP_SELECTED, true);
        }

        if (lineName1 != "Resistencia")
        {
            //ObjectSetInteger(0, "Resistencia", OBJPROP_SELECTED, false);
        }
        string lineName2 = IsMouseNearHorizontalLine("Soporte",lparam,dparam);
       
       //Print("lineName1 : ",lineName1); 
        if(lineName2 == "Soporte" )
        {
           ObjectSetInteger(0, lineName2, OBJPROP_SELECTED, true);
        }
        if (lineName2 != "Soporte")
        {
            //ObjectSetInteger(0, "Soporte", OBJPROP_SELECTED, false);
        }
        //// Obtener coordenadas del mouse
        //int mouse_x = (int)lparam;
        //int mouse_y = (int)dparam;
        //// Verificar objetos basados en precios
        //CheckPriceBasedObjects(mouse_x, mouse_y);

   }
   
   if (id == CHARTEVENT_OBJECT_DRAG)
   {
      string object_name = sparam;
      //Print("id :",id, " object_name: ",object_name);

      if (object_name == "Resistencia")
      {
         //VGResistencia  = ObjectGetDouble(0,object_name,OBJPROP_PRICE);
         //VGSoporte  = ObjectGetDouble(0,object_name,OBJPROP_PRICE);
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGResistencia ); 
         //VGMaximo2 = VGResistencia;  
      }
      if (object_name == "maximo_M15")
      {
         double lvvalor1 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
         double lvvalor2 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,1);
         
         if(lvvalor1 < lvvalor2)
         {
            ObjectSetDouble(0,object_name,OBJPROP_PRICE,0,lvvalor2);
            ObjectSetDouble(0,object_name,OBJPROP_PRICE,1,lvvalor1);
         }
         
         long fecha_1 = ObjectGetInteger(0,object_name,OBJPROP_TIME,0);
         long fecha_2 = ObjectGetInteger(0,object_name,OBJPROP_TIME,1);
         lvvalor2 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,1);
         ObjectSetInteger(0,"minimo_M15",OBJPROP_TIME,0,fecha_1);
         ObjectSetInteger(0,"minimo_M15",OBJPROP_TIME,1,fecha_2);
         ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,lvvalor2 ); 
         
         double lvalto = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
         double lvbajo = ObjectGetDouble(0,object_name,OBJPROP_PRICE,1);
         
         //ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,0, lvalto);    
         //ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,1, lvbajo);
         //VGResistencia = VGMaximo2;  
      }
      
      
      if (object_name == "Soporte")
      {
         //VGResistencia  = ObjectGetDouble(0,object_name,OBJPROP_PRICE);
         //VGSoporte  = ObjectGetDouble(0,object_name,OBJPROP_PRICE);
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGSoporte ); 
         //VGMinimo1 = VGSoporte;  
      }
      if (object_name == "minimo_M15")
      {
         double lvvalor1 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
         double lvvalor2 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,1);
         
         if(lvvalor1 < lvvalor2)
         {
            ObjectSetDouble(0,object_name,OBJPROP_PRICE,0,lvvalor2);
            ObjectSetDouble(0,object_name,OBJPROP_PRICE,1,lvvalor1);
         }
         lvvalor2 = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
         long fecha_1 = ObjectGetInteger(0,object_name,OBJPROP_TIME,0);
         long fecha_2 = ObjectGetInteger(0,object_name,OBJPROP_TIME,1);
         ObjectSetInteger(0,"maximo_M15",OBJPROP_TIME,0,fecha_1);
         ObjectSetInteger(0,"maximo_M15",OBJPROP_TIME,1,fecha_2);
         ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,lvvalor2 ); 

         double lvalto = ObjectGetDouble(0,object_name,OBJPROP_PRICE,0);
         double lvbajo = ObjectGetDouble(0,object_name,OBJPROP_PRICE,1);
         
         //ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,0, lvbajo);    
         //ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,1, lvalto);
         //VGSoporte = VGMinimo1;  
      }
      
      datetime fecha_fibo_3 = TimeCurrent() + (5 * PeriodSeconds()) ;
      ObjectSetInteger(0,"FIBO_3",OBJPROP_TIME,0,fecha_fibo_3);
      ObjectSetInteger(0,"FIBO_3",OBJPROP_TIME,1,fecha_fibo_3);

      
      VGResistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
      VGSoporte  = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
      VGMidPrice = VGResistencia + (VGSoporte - VGResistencia) / 2.0;
      ObjectSetDouble(0, "midPrice", OBJPROP_PRICE,0,VGMidPrice );

      string obj_nombre = "maximo_M15";
      VGMaximo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
      VGMaximo1 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);

      obj_nombre = "minimo_M15";
      VGMinimo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
      VGMinimo1= ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
      
      datetime fecha_inicial = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,0);
      datetime fecha_final   = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,1);
      
      if(VGCompra == 1 && (object_name == "minimo_M15" || object_name == "maximo_M15"))
      {
         double lvalto = ObjectGetDouble(0,"minimo_M15",OBJPROP_PRICE,0);
         double lvbajo = ObjectGetDouble(0,"minimo_M15",OBJPROP_PRICE,1);
         
         double lot=StringToDouble(lotSizeBuy.Text()); 
         
         tp("TP1",lvalto,lvbajo,1,lot);
         
      }
      

      if(VGVenta == 1 && (object_name == "minimo_M15" || object_name == "maximo_M15"))
      {
         double lvalto = ObjectGetDouble(0,"maximo_M15",OBJPROP_PRICE,0);
         double lvbajo = ObjectGetDouble(0,"maximo_M15",OBJPROP_PRICE,1);
         
         double lot=StringToDouble(lotSizeSell.Text()); 
         tp("TP1",lvbajo,lvalto,2,lot);
          
      }
      
      ChartRedraw();
      
      ProgramarCompraVenta();   

   }

   // Detectar el evento de cambio de gráfico
   if (id == CHARTEVENT_CHART_CHANGE)
   {
     // Obtener los valores iniciales del gráfico
      ProgramarCompraVenta();
      int   current_visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);
      bool  scale_changed = false;
      
      // Detectar cambios en el zoom horizontal (número de barras visibles)
      if (current_visible_bars != VGprev_visible_bars)
      {
         //Print("¡Cambio de Zoom Horizontal! Barras visibles: ", VGprev_visible_bars, " -> ", current_visible_bars);
         scale_changed = true;
         VGprev_visible_bars = current_visible_bars;
         fibo("1");
         fibo("2");
      }
   }         

   if(id==CHARTEVENT_OBJECT_ENDEDIT)
     {
         porcentajeRiesgo1    = StringToDouble(porcentajeRiesgo.Text());
         puntosFvg1           = StringToInteger(puntosFvg.Text());
         porcentajeUtilidad1  = StringToInteger(porcentajeUtilidad.Text());
         if (porcentajeUtilidad1 <= 0)
         {
            porcentajeUtilidad1 = 1;
            porcentajeUtilidad.Text(1);
         }
     }
     
    if(id==CHARTEVENT_KEYDOWN)
    {


      Print( " Id :", id, " lparam : " , lparam, " dparam: ",dparam, " sparam : ", sparam);
      VGtecla = sparam;
      if(VGtecla == 2 ) //tecla numero 1 compras
      {
         VGcontadorAlertasAlcista = 0;
         VGcontadorAlertasBajista = 0;
         ObjectsDeleteAll(0,"TP");
         if( VGCompra == 1) //Desaciva el panel
         {
            ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false);
            ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false);

            VGCompra = 0;
            VGVenta  = 0;
            return;
         }

         double lvresistencia = ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE);
         ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,lvresistencia );
         ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_alto_5 );
         ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_alto_5 );
         ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );

         ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
         ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');

        ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,0, VGvalor_fractal_bajo_5);    
        ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,1, VGvalor_fractal_alto_5);  


         VGtecla = 0;     
         VGCompra = 1;
         VGVenta  = 0;
      
      }
            
      if(VGtecla == 3 ) //tecla numero 2 ventas
      {
         VGcontadorAlertasAlcista = 0;
         VGcontadorAlertasBajista = 0;
         ObjectsDeleteAll(0,"TP");
         if( VGVenta == 1)//Desaciva el panel
         {
            ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, clrNONE);
            ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false);
            ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false);
            VGCompra = 0;
            VGVenta  = 0;
            return;
         }

         double lvsoporte = ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
         ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0, VGvalor_fractal_alto_5);
         ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
         ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_bajo_5 );
         ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte );

         ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
         ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');

         ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,0, VGvalor_fractal_alto_5);    
         ObjectSetDouble(0, "FIBO_3", OBJPROP_PRICE,1, VGvalor_fractal_bajo_5);  

         VGtecla = 0;     
         VGCompra = 0;
         VGVenta  = 1;
      
      }
      
      if(VGtecla == 4 ) //Tecla numero 3 para soporte y resistencia
      {
         //Print("tecla : ",VGtecla, " ID ", id, " VGResistencia :",VGResistencia, " VGSoporte :",VGSoporte);
         DrawBarFractals(PERIOD_M3, 500, 30, "1");
         ObjectSetDouble(0,"Resistencia",OBJPROP_PRICE,VGResistencia);  
         ObjectSetDouble(0,"Soporte",OBJPROP_PRICE,VGSoporte);  
         VGtecla = 0;     
      
      }


      if (VGtecla == 8)
          ObjectsDeleteAll(0,"Cuartos");
      
    }     
     

    if (id == CHARTEVENT_CLICK)
    {
      
      //Print( " Id :", id, " lparam : " , lparam, " dparam: ",dparam, " sparam : ", sparam, " VGtecla ",VGtecla);
      // Obtener el estado de las teclas modificadoras
      if (VGtecla == 6 || VGtecla == 7 ||  VGtecla == 8 )// Para ventas
      {
         DetectClickedCandle(lparam,dparam,VGtecla);
         VGtecla = 0;
      }
      if (id == 4)
      {
            static ulong clickTimeMemory;
               ulong clickTime = GetTickCount();
               if(clickTime < clickTimeMemory + 300)
               {
                  //VGResistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
                  //VGSoporte      = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
                  //VGMidPrice     = VGResistencia + (VGSoporte - VGResistencia) / 2.0;
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGResistencia ); 
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice );
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGMidPrice );
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGSoporte ); 
                  //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
                  //ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');

                    int lvcolor = ObjectGetInteger(0, "maximo_M15", OBJPROP_COLOR);
                    
                    if (lvcolor == -1)
                    {
                        double lvresistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
                        double lvsoporte      = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
                        
                        if(VGMaximo2 > lvresistencia)
                           VGMaximo2 = lvresistencia;

                        if(VGMinimo1 < lvsoporte)
                           VGMinimo1 = lvsoporte;
                           
                        double lvMidPrice     = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
                        ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGMaximo2 ); 
                        ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,lvMidPrice );
                        ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,lvMidPrice );
                        ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMinimo1 ); 
                        ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
                        ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');
                        // Ocultar todos los objetos de trading
                        //ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, false);
                        string obj_nombre = "maximo_M15";
                        VGMaximo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
                        VGMaximo1 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
                  
                        obj_nombre = "minimo_M15";
                        VGMinimo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
                        VGMinimo1= ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
                    }
                    else
                    {
                        //ObjectSetInteger(0, "Text_Venta", OBJPROP_COLOR, clrNONE);
                        //ObjectSetInteger(0, "Text_Compra", OBJPROP_COLOR, clrNONE);
                        ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, clrNONE);
                        ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, clrNONE);
                        ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false);
                        ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false);
                        // Ocultar todos los objetos de trading
                        //ChartSetInteger(0, CHART_SHOW_TRADE_LEVELS, true);
                    } 
                  
                    //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, clrNONE);
                    
                    //int prueba1 = ObjectGetInteger(0, "maximo_M15", OBJPROP_COLOR); 
                    //int prueba2 = ObjectGetInteger(0, "minimo_M15", OBJPROP_COLOR); 
                    //Print("prueba1 :",prueba1," prueba2 : ",prueba2);
                   //ObjectSetInteger(0, rectName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                   ChartRedraw(); 

                  //Print("just detected a doubleclick");
                  clickTimeMemory = 0;
               }
               else
                  clickTimeMemory = clickTime;    
      }
      
      if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
      {
         VGMinimo1 = NormalizeDouble(VGMinimo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
         VGMinimo2 = NormalizeDouble(VGMinimo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
         VGMaximo1 = NormalizeDouble(VGMaximo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
         VGMaximo2 = NormalizeDouble(VGMaximo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
      }

      if(buyBtn.MouseX() && buyBtn.IsVisible())
        {
            double lot=StringToDouble(lotSizeBuy.Text()); 
            //if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
            //{
            //   VGMinimo1 = NormalizeDouble(VGMinimo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
            //   VGMinimo2 = NormalizeDouble(VGMinimo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
            //   VGMaximo1 = NormalizeDouble(VGMaximo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
            //   VGMaximo2 = NormalizeDouble(VGMaximo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
            //}
         for (int i=1; i <= lvnumerocompras; i++)
         {
            //MiTrade.BuyLimit(lot,Bid,_Symbol,VGMinimo1,VGMaximo2);
            
            MiTrade.Buy(lot,_Symbol,Bid,VGMinimo1,VGMaximo2,"Buy zb"); //Con Stop Loss
            //MiTrade.Buy(lot,_Symbol,Bid,0,VGMaximo2,"Buy zb"); //Sin stop Loss
         }         
         //MiTrade.SellStop(lot,VGMinimo1);
         
        }
      if(sellBtn.MouseX() && sellBtn.IsVisible())
        {

         double lot=StringToDouble(lotSizeSell.Text()); 

         for (int i=1; i <= lvnumerocompras; i++)
         {
            MiTrade.Sell(lot, _Symbol,Ask,VGMaximo2,VGMinimo1,"Sell zb");//Con Stop Loss
            //MiTrade.Sell(lot, _Symbol,Ask,0,VGMinimo1,"Sell zb");//Sin stop Loss
         }         
         //MiTrade.BuyStop(lot,VGMaximo1);
        }
        
      if(closeBtn.MouseX())
        {
            CloseAllPositions();         
         }
         
      if(beBtn.MouseX())
        {
            sl_pf_Btn1 = false;
            MoveToBreakEven();   
         }

      if(showMacrosKillzoneBtn.MouseX())
        {
            //Print("VGShowMacrosKillzone:",VGShowMacrosKillzone);
            if (VGShowMacrosKillzone == true)
            {
               VGShowMacrosKillzone = false;
               showMacrosKillzoneBtn.ColorBackground(clrBlue);
               showMacrosKillzoneBtn.Text("Show Macros");
            }
            
            else
            {
               VGShowMacrosKillzone = true;
               showMacrosKillzoneBtn.ColorBackground(clrRed);
               showMacrosKillzoneBtn.Text("Hidden Macros");
            }
            //Print("VGShowMacrosKillzone:",VGShowMacrosKillzone);
            HideObjectsByPrefix("ZB_"+ _Symbol + "_Macro");
         }

      if(showFvgBtn.MouseX())
        {
            string lvtemplate = "default";
            Print("VGShowMacrosKillzone:",VGShowMacrosKillzone, " VGShowFvg:",VGShowFvg);
            if (showFvgBtn.Text() == "Show Fvg")
            {
               showFvgBtn.ColorBackground(clrRed);
               VGShowFvg = true;
               DrawFVG( VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);
               DrawFVG( VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);

               ////para detectar zonas de compra y venta
               //VGHTF_Name = TimeframeToString(PERIOD_H4);
               //DrawFVG(PERIOD_H4, Velas_FVG_HTF, VGcolor_zona_compra_venta, VGcolor_zona_compra_venta, 0); //para detectar zonas de compra y venta               //VGShowFvg = false;

               lvtemplate = "zbbot_v5";
            }
            
            if(showFvgBtn.Text() == "Hidden Fvg")
            {
               ObjectsDeleteAll(0, "FVG_");
               showFvgBtn.ColorBackground(clrBlue);
               VGShowFvg = false;
            }
            
            if(VGShowFvg == true)
            {
               showFvgBtn.Text("Hidden Fvg");
            }
            else
            {
               showFvgBtn.Text("Show Fvg");
            }


            //ChartApplyTemplate(0,lvtemplate);
            //ObjectsDeleteAll(0, "FVG_");
            
            //DrawFVG( VGTime_Frame_HT, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 0);
            //DrawFVG( VGTime_Frame_Current, Velas_FVG_Current, Color_Bullish_Current, Color_Bearist_Current,1);
         }


        
      VGloteCompra =  StringToDouble(lotSizeBuy.Text());
      VGloteVenta  =  StringToDouble(lotSizeSell.Text());
      if(buyLimitBtn.MouseX())
        {
            for (int i=1; i <= lvnumerocompras; i++)
            {
               MiTrade.BuyLimit(VGloteCompra,VGMinimo2,_Symbol,VGMinimo1,VGMaximo2,ORDER_TIME_GTC,0,"Buy limit zb");//Con Stop Loss
               //MiTrade.BuyLimit(VGloteCompra,VGMinimo2,_Symbol,0,VGMaximo2);//Sin stop Loss
            }   
            //MiTrade.SellStop(VGloteCompra,VGMinimo1);
        }
      if(sellLimitBtn.MouseX())
        {
            for (int i=1; i <= lvnumerocompras; i++)
            {

               MiTrade.SellLimit(VGloteVenta,VGMaximo1,_Symbol,VGMaximo2,VGMinimo1,ORDER_TIME_GTC,0,"Sell limit zb");//Con Stop Loss
               //MiTrade.SellLimit(VGloteVenta,VGMaximo1,_Symbol,0,VGMinimo1);//Sin stop Loss

            }
            //MiTrade.BuyStop(VGloteVenta,VGMaximo1);
        }

      if(buyStopBtn.MouseX())
        {
            double lvlote =  CalculateLotSize(VGMinimo2, VGMinimo1, porcentajeRiesgo1); //calcular el tamano del lote
            for (int i=1; i <= lvnumerocompras; i++)
            {
               MiTrade.BuyStop(lvlote,VGMinimo2,_Symbol,VGMinimo1,VGMaximo2,ORDER_TIME_GTC,0,"Buy Stop zb");
            }
            //MiTrade.SellStop(VGloteCompra,VGMinimo1);
        }



      if(sellStopBtn.MouseX())
        {
            double lvlote =  CalculateLotSize(VGMaximo2, VGMaximo1, porcentajeRiesgo1); //calcular el tamano del lote
            for (int i=1; i <= lvnumerocompras; i++)
            {
               MiTrade.SellStop(lvlote,VGMaximo1,_Symbol,VGMaximo2,VGMinimo1,ORDER_TIME_GTC,0,"Sell Stop zb");
            }
            //MiTrade.BuyStop(VGloteVenta,VGMaximo1);
        }
        

      if (sl_pf_Btn.MouseX())
        {
            //Print( " sl_pf_Btn1 : ",sl_pf_Btn1);
            if (sl_pf_Btn1 == true)
            {
               sl_pf_Btn1 = false;
               sl_pf_Btn.ColorBackground(clrRed);
               sl_pf_Btn.Text("Disable");
            } 
            else
            {  
               sl_pf_Btn1 = true;
               sl_pf_Btn.ColorBackground(clrBlue);
               sl_pf_Btn.Text("Enable");
            }
            ManejoStopLoss();
        }
        
        if (profitDineroBtn.MouseX())
        { 
            CalculateMovementAndProfit(VGMaximo1, VGMaximo2, 1);
            Print("Botón presionado");
            // Realizar alguna acción
        }
     }
     
     
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      //porcentajeRiesgo1 =StringToDouble(porcentajeRiesgo.Text());
      //puntosFvg1     =StringToInteger(puntosFvg.Text());
      //Print("porcentajeRiesgo1 German :",porcentajeRiesgo1);
      color lvcolor;
      if(sparam=="Resistencia" || sparam=="Soporte" )
        {
            int lvstyle = ObjectGetInteger(0,"Resistencia",OBJPROP_STYLE);
            static ulong clickTimeMemory;
            if(id == CHARTEVENT_OBJECT_CLICK)
            { 
               //Alert("just detected a doubleclick");
               ulong clickTime = GetTickCount();
               //Print(" clickTime ",clickTime);
               
               if(clickTime < clickTimeMemory + 300)
               {
                  if (lvstyle == STYLE_SOLID)
                  {
                     //lvcolor = ObjectGetInteger(0,"Resistencia",OBJPROP_COLOR);
                     ObjectSetInteger(0, "Resistencia", OBJPROP_STYLE, STYLE_DOT);
                     //ObjectSetInteger(0, "Resistencia", OBJPROP_COLOR, clrLightSkyBlue);
                     //ObjectSetInteger(0, "Resistencia", OBJPROP_WIDTH, 1);
                     ObjectSetInteger(0, "Soporte", OBJPROP_COLOR, clrAqua);
                     ObjectSetInteger(0, "Soporte", OBJPROP_STYLE, STYLE_SOLID);
                     //ObjectSetInteger(0, "Soporte", OBJPROP_WIDTH, 1);
                  }
                  else
                  {
                     ObjectSetInteger(0, "Resistencia", OBJPROP_STYLE, STYLE_SOLID);
                     ObjectSetInteger(0, "Resistencia", OBJPROP_COLOR, clrYellow);
                     //ObjectSetInteger(0, "Resistencia", OBJPROP_WIDTH, 1);
                     //ObjectSetInteger(0, "Soporte", OBJPROP_COLOR, clrLightSkyBlue);
                     ObjectSetInteger(0, "Soporte", OBJPROP_STYLE, STYLE_DOT);
                     //ObjectSetInteger(0, "Soporte", OBJPROP_WIDTH, 1);
                  }
                  //Print("just detected a doubleclick");
                  clickTimeMemory = 0;
               }
               else
               {
                  clickTimeMemory = clickTime;
               }       
            }     
         }    
      if(sparam=="maximo_M15" || sparam=="minimo_M15" || sparam=="Resistencia" || sparam=="Soporte")
        {
            static ulong clickTimeMemory;
            if(id == CHARTEVENT_OBJECT_CLICK)
            { 
               //Alert("just detected a doubleclick");
               ulong clickTime = GetTickCount();
               //Print(" clickTime ",clickTime);
               if(clickTime < clickTimeMemory + 300){
//                  
//                  double vlresistencia = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
//                  double vlsoporte     = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
                  
                  //double vlMidPrice = vlresistencia + (vlsoporte - vlresistencia) / 2.0;

                  double vlMidPrice = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
                  
                  ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGMaximo2 ); 
                  ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,vlMidPrice );
                  ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,vlMidPrice );
                  ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMinimo1 ); 
                  ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
                  ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');

                  //Print("just detected a doubleclick");
                  clickTimeMemory = 0;
               }
               else
                  clickTimeMemory = clickTime;    
            }      
      }      

////      if(sparam==buyBtn.Name() && buyBtn.IsEnabled())
////        {
////         string obj_nombre = "minimo_M15";
////         ObjectSetDouble(0,obj_nombre,OBJPROP_PRICE,1,Bid);
////         ProgramarCompraVenta();
////         buyBtn.ColorBackground(clrBlack);
////         Print("German");
////         MiTrade.Buy(lot,_Symbol,Bid,VGMinimo1,VGMaximo2,"Buy zb");
////         
////         for (int i=1; i <= lvnumerocompras; i++)
////         {
////            MiTrade.BuyLimit(lot,Bid,_Symbol,VGMinimo1,VGMaximo2);
////            MiTrade.Buy(lot,_Symbol,Bid,VGMinimo1,VGMaximo2,"Buy zb");
////         }         
////         MiTrade.SellStop(lot,VGMinimo1);
////         
////        }
////      if(sparam==sellBtn.Name() && sellBtn.IsEnabled())
////        {
////         string obj_nombre = "maximo_M15";
////         ObjectSetDouble(0,obj_nombre,OBJPROP_PRICE,0,Bid);
////         ProgramarCompraVenta();
////         Sleep(500);
////         MiTrade.Sell(lot, _Symbol,Ask,VGMaximo1,VGMinimo2,"Sell zb");
////         
////         for (int i=1; i <= lvnumerocompras; i++)
////         {
////            MiTrade.Sell(lot, _Symbol,Ask,VGMaximo1,VGMinimo2,"Sell zb");
////         }         
////         MiTrade.BuyStop(lot,VGMaximo1);
////        }
        
         
//      VGloteCompra =  lot;
//      VGloteVenta  =  lot;
//      if(sparam==buyLimitBtn.Name())
//        {
//            for (int i=1; i <= lvnumerocompras; i++)
//            {
//               MiTrade.BuyLimit(VGloteCompra,VGprecioCompra,_Symbol,VGMinimo1,VGMaximo2);
//            }   
//            //MiTrade.SellStop(VGloteCompra,VGMinimo1);
//        }
//      if(sparam==sellLimitBtn.Name())
//        {
//            for (int i=1; i <= lvnumerocompras; i++)
//            {
//
//               MiTrade.SellLimit(VGloteVenta,VGprecioventa,_Symbol,VGMaximo1,VGMinimo2);
//
//            }
//            //MiTrade.BuyStop(VGloteVenta,VGMaximo1);
//        }
//
//      if(sparam==buyStopBtn.Name())
//        {
//            for (int i=1; i <= lvnumerocompras; i++)
//            {
//               MiTrade.BuyStop(VGloteCompra,VGMinimo2,_Symbol,VGMinimo1,VGMaximo1);
//            }
//            //MiTrade.SellStop(VGloteCompra,VGMinimo1);
//        }
//      if(sparam==sellStopBtn.Name())
//        {
//            for (int i=1; i <= lvnumerocompras; i++)
//            {
//               MiTrade.SellStop(VGloteVenta,VGMaximo2,_Symbol,VGMaximo1,VGMinimo2);
//            }
//            //MiTrade.BuyStop(VGloteVenta,VGMaximo1);
//        }
//        
//
//      if(sparam==sl_pf_Btn.Name())
//        {
//            //Print( " sl_pf_Btn1 : ",sl_pf_Btn1);
//            if (sl_pf_Btn1 == true)
//            {
//               sl_pf_Btn1 = false;
//               sl_pf_Btn.ColorBackground(clrRed);
//               sl_pf_Btn.Text("Disable");
//            } 
//            else
//            {  
//               sl_pf_Btn1 = true;
//               sl_pf_Btn.ColorBackground(clrBlue);
//               sl_pf_Btn.Text("Enable");
//            }
//        }


//      if(sparam==closeBtn.Name())
//        {
//
//         int TotalPosiciones = PositionsTotal(); // Total de posiciones abiertas
//         
//         for(int i=TotalPosiciones-1; i>=0; i--)
//         {
//            ulong    Ticket            = PositionGetTicket(i);
//            string   Symbolo           = PositionGetString(POSITION_SYMBOL);
//            long     Tipo              = PositionGetInteger(POSITION_TYPE);
//            double   Mivolumen         = PositionGetDouble(POSITION_VOLUME);
//
//            Print("TotalPosiciones : ", TotalPosiciones, " Symbolo :",Symbolo, " Ticket : ",Ticket);
//            
//            if (_Symbol == Symbolo)
//            {
//               MiTrade.PositionClose(Ticket);
//            }
//            
//            
//         }
//         
//      }


      
     }
   
  }


//+------------------------------------------------------------------+
//| Función principal para detectar vela clickeada                  |
//+------------------------------------------------------------------+
void DetectClickedCandle(int lparam, int dparam, int lvtecla)
{
    
   // Convertir coordenadas de pantalla a tiempo/precio
   datetime clickTime;
   double clickPrice;
   int window = 0;
   double high = 0;
   double low = 0;
   double open = 0;
   double close = 0;
   int fecha_final = iTime(_Symbol,PERIOD_CURRENT,0) + ( 5 * PeriodSeconds());
   
   string lvnametf = TimeframeToString(_Period);
   
   if(ChartXYToTimePrice(0, lparam, dparam, window, clickTime, clickPrice))
   {
      // Encontrar la vela correspondiente al tiempo clickeado
      int candleIndex = iBarShift(_Symbol, _Period, clickTime);
      
      if(candleIndex >= 0)
      {
         // Obtener datos de la vela
         high = iHigh(_Symbol, _Period, candleIndex);
         low = iLow(_Symbol, _Period, candleIndex);
         open = iOpen(_Symbol, _Period, candleIndex);
         close = iClose(_Symbol, _Period, candleIndex);
         
         // Mostrar información
         //Print("German", " high :",high, " low :",low);
      }
      if (lvtecla == 6)//Ventas tecla numero 5
      {
         string name_object = "ZONA_VENTAS";
         ObjectCreate(0,name_object,OBJ_RECTANGLE,0,fecha_final,fecha_final);
         ObjectSetDouble(0,name_object,OBJPROP_PRICE,high);
         ObjectSetDouble(0,name_object,OBJPROP_PRICE,1,low);
         ObjectSetInteger(0,name_object,OBJPROP_TIME,0,clickTime);
         ObjectSetInteger(0,name_object,OBJPROP_TIME,1,fecha_final);
         ObjectSetString(0,name_object,OBJPROP_TEXT,"ZONA DE VENTAS - " + lvnametf);
         ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
         ObjectSetInteger(0,name_object,OBJPROP_FILL,false);
         ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
         
         Print("VENTAS", " high :",high, " low :",low);
         
      }
      if (lvtecla == 7)//Compras tecla numero 6
      {
         string name_object = "ZONA_COMPRAS";
         ObjectCreate(0,name_object,OBJ_RECTANGLE,0,fecha_final,fecha_final);
         ObjectSetDouble(0,name_object,OBJPROP_PRICE,high);
         ObjectSetDouble(0,name_object,OBJPROP_PRICE,1,low);
         ObjectSetInteger(0,name_object,OBJPROP_TIME,0,clickTime);
         ObjectSetInteger(0,name_object,OBJPROP_TIME,1,fecha_final);
         ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrMediumSlateBlue);
         ObjectSetString(0,name_object,OBJPROP_TEXT,"ZONA DE COMPRAS - " + lvnametf);
         ObjectSetInteger(0,name_object,OBJPROP_FILL,false);
         ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
         Print("COMPRAS", " high :",high, " low :",low);
      }

      if (lvtecla == 8)//Compras tecla numero 7 para cuartos de toda la vela
      {
         if (open > close)
         {
           high = close;
         }
         else
         {
            low = close;
         }
         ObjectsDeleteAll(0,"Cuartos");
         string name_object = "Cuartos_";
       
         // Calcular el rango total de la vela
         double range = high - low;
         // Calcular los niveles de los cuartos

         double levels[];
         ArrayResize(levels, 5);
         
    
         levels[0] = low;                    // Cuarto 0 (mínimo)
         levels[1] = low + (range * 0.25);   // Cuarto 1
         levels[2] = low + (range * 0.5);    // Cuarto 2 (mitad)
         levels[3] = low + (range * 0.75);   // Cuarto 3
         levels[4] = high;                   // Cuarto 4 (máximo)         
               
         for (int i = 0 ; i < 5; i++)
         {
           name_object = name_object + i;
           ObjectCreate(0,name_object,OBJ_TREND,0,clickTime,levels[i],fecha_final,levels[i]);
           ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
           Print( "levels[i] : ",levels[i], " name_object : ",name_object);
         
         }
         Print("Cuartos", " high :",high, " low :",low);
      }   
    }
}




//+------------------------------------------------------------------+
//| Función para verificar si el mouse está sobre un rectángulo     |
//| con márgenes para activar hover antes de salir completamente    |
//+------------------------------------------------------------------+
string CheckRectHoverPrice(string rectName, long lparam, double dparam, 
                          int time_margin_seconds = 300, double price_margin_pips = 10.0)
{
    // Obtener propiedades del rectángulo
    datetime time1 = (datetime)ObjectGetInteger(0, rectName, OBJPROP_TIME);
    datetime time2 = (datetime)ObjectGetInteger(0, rectName, OBJPROP_TIME, 1);
    double price1 = ObjectGetDouble(0, rectName, OBJPROP_PRICE);
    double price2 = ObjectGetDouble(0, rectName, OBJPROP_PRICE, 1);
    
    
    // Convertir coordenadas del mouse a tiempo y precio
    datetime mouse_time;
    double mouse_price;
    int sub_window;
    
    if(ChartXYToTimePrice(0, (int)lparam, (int)dparam, sub_window, mouse_time, mouse_price))
    {
        // Determinar tiempo mínimo y máximo del rectángulo
        datetime min_time = (time1 < time2) ? time1 : time2;
        datetime max_time = (time1 > time2) ? time1 : time2;
        
        // Determinar precio mínimo y máximo del rectángulo
        double min_price = (price1 < price2) ? price1 : price2;
        double max_price = (price1 > price2) ? price1 : price2;
        
        
        // Calcular el punto pip para el margen de precio
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        //double pip_value = point * 10; // Para la mayoría de pares 1 pip = 10 points
       // Calcular margen de precio automáticamente
        double price_margin = price_margin_pips * GetPipValue();        

        //double price_margin = price_margin_pips * pip_value;
        
        // Aplicar márgenes (expandir el área efectiva)
        datetime min_time_margin = min_time - time_margin_seconds;
        datetime max_time_margin = max_time + time_margin_seconds;
        double min_price_margin = min_price - price_margin;
        double max_price_margin = max_price + price_margin;
        
        // Verificar si el mouse está dentro del rectángulo con márgenes
        if(mouse_time >= min_time_margin && mouse_time <= max_time_margin &&
           mouse_price >= min_price_margin && mouse_price <= max_price_margin)
        {
            return rectName;
        }
        
    }
    
    return "";
}


//+------------------------------------------------------------------+
//| Función simplificada para una línea horizontal                  |
//+------------------------------------------------------------------+
string IsMouseNearHorizontalLine(string lineName, long lparam, double dparam, 
                              double price_margin_pips = 30.0)
{
    double line_price = ObjectGetDouble(0, lineName, OBJPROP_PRICE);
    
    datetime mouse_time;
    double mouse_price;
    int sub_window;
    
    if(ChartXYToTimePrice(0, (int)lparam, (int)dparam, sub_window, mouse_time, mouse_price))
    {
        double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        string symbol = Symbol();
        double price_margin;
        
        if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "XBT") >= 0)
        {
            price_margin = price_margin_pips * point;
        }
        else
        {
            price_margin = price_margin_pips * point * 10;
        }
        if(MathAbs(mouse_price - line_price) <= price_margin)
        {
            return lineName;
        }        
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Función universal para calcular el valor de pip correcto         |
//+------------------------------------------------------------------+
double GetPipValue()
{
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    string symbol = Symbol();
    
    // Pares donde 1 pip = 1 point (Bitcoin, índices, etc.)
    if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "XBT") >= 0 || 
       StringFind(symbol, "#") >= 0) // Índices
    {
        return point;
    }
    // Forex tradicional: 1 pip = 10 points
    else
    {
        return point * 10;
    }
}

  
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| BookEvent function                                               |
//+------------------------------------------------------------------+
void OnBookEvent(const string &symbol)
  {
//---
   
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Calcular nuemero de operaciones function                         |
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//| Crear Lineas                                    |
//+------------------------------------------------------------------+
void CrearLineas()
  {
     
//---
     double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
     double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
     double tamano_contrato=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_CONTRACT_SIZE);

     double lvdiferencia1 = VGMaximo1 - Bid;
     double lvdiferencia2 = Bid - VGMinimo1 ; 
     
     double lvratio = StringToDouble(ratioBtn.Text());
     double ValorLinea1    =  0;
     double ValorLinea2    =  0;
     int    lvtendencia    =  0;
     double lvlotes        =  0;

//Indicador SMC
     
     double lvvalor  = 0;
     int    lvvelas  = 0;
     double vlsl     = StringToDouble(puntosFvg.Text()) * Puntos ; 
     double PipsSL   = NormalizeDouble(0,2);
     double PipsTP   = NormalizeDouble(0,2);
     int    vlpuntos = 10;
     if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) == 1)
     {
         vlpuntos = 100;
     }
     if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) == 100)
     {
         vlpuntos = 10;
     }


//Maximos - Minimos
      ValorLinea1 = NormalizeDouble(VGMaximo1,Digits());
      //ValorLinea1 = ValorLinea1 + (vlsl * vlpuntos);

      ValorLinea2 = NormalizeDouble(VGMinimo1,Digits());
      //ValorLinea2 = ValorLinea2 - (vlsl * vlpuntos);




     if (lvdiferencia1 > lvdiferencia2)
     {
        lvtendencia = 1;// Alcista
     }
     else
     {
         lvtendencia = 2;// Bajista
     }

    // Account balance
     double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
     double tamanoPosicion = 0;
     //double riskPercentage = 0.5;
    // Calculate the amount at risk (in account currency)
     //double amountAtRisk = (accountBalance * porcentajeRiesgo1) / 100/10;
         
     ValorMedia = ((ValorLinea1 - ValorLinea2) / 2) / _Point;
     //double DiferenciaValorBajo = NormalizeDouble(Bid - ValorLinea2, Digits());
     //double DiferenciaValorAlto = NormalizeDouble(ValorLinea1 - Bid, Digits());
     double DiferenciaValorBajo = (Bid - ValorLinea2) / _Point;
     double DiferenciaValorAlto = (ValorLinea1 - Bid) / _Point;
     double ValorLabel = 0;
     string TextLabel = "";

//     double lvpuntos = 100;
//     //Print( " Digits : ",Digits());
//
//
//     if (Digits() == 5 || Digits() == 3 )
//     {
//         lvpuntos = 10;
//     }
     
     int lvvelas1 = 50;

      //double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
      //double lots = (porcentajeRiesgo1/100) * accountBalance / (PipValue * PipsSL);

      double lots = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);

      if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) == 0.10)
      {
        lots = NormalizeDouble(lots,1);
      }
      else
      {
        lots = NormalizeDouble(lots,2);
      }
   
     if (DiferenciaValorAlto > ValorMedia)
     {
        PosibleCompra = true;
        PosibleVenta  = false;
        //Print("Compras");
        //int val_index = iLowest(_Symbol,PERIOD_CURRENT,MODE_HIGH,lvvelas1,1);
        ValorLabel = Bid - (4 * Puntos);
          
        if(!ObjectCreate(current_chart_id,"Label1",OBJ_TEXT,0,TimeCurrent() + 400,ValorLabel)) 
        { 
         Print(__FUNCTION__, 
               ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
        } 
        double lvdiferencia = (Bid - VGMinimo1) / _Point;
        PipsSL = NormalizeDouble(lvdiferencia,2) / vlpuntos;
        lvdiferencia = (VGMaximo2 - Bid) / _Point;
        PipsTP = NormalizeDouble(lvdiferencia,2)/ vlpuntos;

        //lots = (porcentajeRiesgo1/100) * accountBalance / (PipValue * PipsSL);

        lots = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);
        if (tamano_contrato > 1)
        {
         lots = lots * 10;
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.5)
        {
               lots = NormalizeDouble(lots,0);
               //if (lots < 0.5)
               //   lots = 0.5;
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.10)
        {
               lots = NormalizeDouble(lots,1);
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.01)
        {
               lots = NormalizeDouble(lots,2);
        }

        //if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) == 0.10)
        //{
        //  lots = NormalizeDouble(lots,1);
        //}
        //else
        //{
        //  lots = NormalizeDouble(lots,2);
        //}
        
        //Compra  
//        lvratio = ((VGMaximo2 - Bid) / (Bid - VGMinimo1)) - 1;
//        
//        lvratio = NormalizeDouble(lvratio,2);
        PipsSL = NormalizeDouble(PipsSL,2);
        PipsTP = NormalizeDouble(PipsTP,2);

        lvratio = PipsTP / PipsSL;
        lvratio = NormalizeDouble(lvratio,2);
        
        TextLabel = "Lote :"+NormalizeDouble(lots,2) + " SL : " + NormalizeDouble(PipsSL,2) + " TP : "+ NormalizeDouble(PipsTP,2) + " Ratio : " + NormalizeDouble(lvratio,2);
        //tamanoPosicion = amountAtRisk / PipsSL;
        //if(Digits() == 2)
        //{
        //    tamanoPosicion = NormalizeDouble(amountAtRisk / PipsSL,1);
        //}    

        ObjectSetString(current_chart_id,"Label1",OBJPROP_TEXT,TextLabel);  
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_COLOR,clrLime);
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_FONTSIZE,8);
        //sellBtn.Hide();
        //buyBtn.Show();    

        //lvratio = (ValorLinea1 - Bid) / (Bid - ValorLinea2);
     }
     else
     {
        PosibleVenta = true;
        PosibleCompra = false; //german

        //int val_index = iHighest(_Symbol,PERIOD_CURRENT,MODE_HIGH,lvvelas1,1);
        //double lvalto = iHigh(_Symbol,PERIOD_CURRENT,val_index) + (vlsl * vlpuntos); 
        
        //Print( "lvalto ",lvalto);
        //double lvalto = Ask;
        ValorLabel = Ask + (4  * Puntos);
        if(!ObjectCreate(current_chart_id,"Label1",OBJ_TEXT,0,TimeCurrent() + 400,ValorLabel)) 
        { 
         Print(__FUNCTION__, 
               ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
        } 
        double lvdiferencia = (VGMaximo1 - Bid) / _Point;
        PipsSL = NormalizeDouble(lvdiferencia,2) / vlpuntos;
        lvdiferencia = (Bid - VGMinimo2) / _Point;
        PipsTP = NormalizeDouble(lvdiferencia,Digits())/vlpuntos;
        lots = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);
        if (tamano_contrato > 1)
        {
         lots = lots * 10;
        }

        //lots = (porcentajeRiesgo1/100) * accountBalance / (PipValue * PipsSL);

        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.5)
        {
               lots = NormalizeDouble(lots,0);
               //if (lots < 0.5)
               //   lots = 0.5;
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.10)
        {
               lots = NormalizeDouble(lots,1);
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.01)
        {
               lots = NormalizeDouble(lots,2);
        }

        //if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) == 0.10)
        //{
        //  lots = NormalizeDouble(lots,1);
        //}
        //else
        //{
        //  lots = NormalizeDouble(lots,2);
        //}

        //Venta 
        //lvratio = ((Bid - VGMinimo2) / (VGMaximo1 - Bid)) - 1;

        //lvratio = NormalizeDouble(lvratio,2);
        PipsSL = NormalizeDouble(PipsSL,2);
        PipsTP = NormalizeDouble(PipsTP,2);
        
        lvratio = PipsTP / PipsSL;
        lvratio = NormalizeDouble(lvratio,2);


        TextLabel = "Lote :"+NormalizeDouble(lots,2) + " SL : " + NormalizeDouble(PipsSL,2) + " TP : "+ NormalizeDouble(PipsTP,2)+ " Ratio : " + NormalizeDouble(lvratio,2);
 
        //tamanoPosicion = amountAtRisk / PipsSL;
        //if(Digits() == 2)
        //{
        //    tamanoPosicion = NormalizeDouble(amountAtRisk / PipsSL,1);
        //}    

        ObjectSetString(current_chart_id,"Label1",OBJPROP_TEXT,TextLabel);  
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_COLOR,clrRed);
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_ANCHOR, ANCHOR_LEFT);
        ObjectSetInteger(current_chart_id,"Label1",OBJPROP_FONTSIZE,8);
        //sellBtn.Show();
        //buyBtn.Hide();     
        //Ratio Compra
        //lvratio = (ValorLinea2 - Bid) / (Bid - ValorLinea1);  
     }
     //Print(" ", ValorLinea1 - Bid);
     //Print(" ",Bid - ValorLinea2);
     //Print("ValorMedia : ",ValorMedia);
     
//     const color lvcolor = clrYellow;
//     const ENUM_LINE_STYLE lvstilo = STYLE_SOLID;
//     
//     if(!ObjectCreate(current_chart_id,"Linea1",OBJ_HLINE,0,0,ValorLinea1)) 
//     { 
//      Print(__FUNCTION__, 
//            ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
//     } 
//     else
//     {
//         ObjectSetInteger(current_chart_id,"Linea1",OBJPROP_COLOR,lvcolor);     
//         ObjectSetInteger(current_chart_id,"Linea1",OBJPROP_STYLE,lvstilo);     
//     }
//     if(!ObjectCreate(current_chart_id,"Linea2",OBJ_HLINE,0,0,ValorLinea2)) 
//     { 
//      Print(__FUNCTION__, 
//            ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
//     } 
//     else
//     {
//         ObjectSetInteger(current_chart_id,"Linea2",OBJPROP_COLOR,lvcolor);     
//         ObjectSetInteger(current_chart_id,"Linea2",OBJPROP_STYLE,lvstilo);     
//     }
   

   
   //double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
   lots = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);
     if (tamano_contrato > 1)
     {
      lots = lots * 10;
     }

   //lots = (porcentajeRiesgo1/100) * accountBalance / (PipValue * PipsSL);

        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.5)
        {
               lots = NormalizeDouble(lots,0);
               //if (lots < 0.5)
               //   lots = 0.5;
               //if (lots > 0.5 && lots < 1)
               //   lots = 1;
               //if (lots > 1 && lots < 1.5)
               //   lots = 1.5;
        }

        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.10)
        {
               lots = NormalizeDouble(lots,1);
        }
        if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.01)
        {
               lots = NormalizeDouble(lots,2);
        }

   //if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) == 0.10)
   //{
   //  lots = NormalizeDouble(lots,1);
   //}
   //else
   //{
   //  lots = NormalizeDouble(lots,2);
   //}

   //lotSize.Text(lots);
   
   VGriesgoDinero = (porcentajeRiesgo1/100) * accountBalance;
   double lvutilidaddinero = (porcentajeUtilidad1/100) * accountBalance;
   
   VGriesgoDinero = NormalizeDouble(VGriesgoDinero,2);
   RiesgoDinero.Text(VGriesgoDinero);
   
   lvutilidaddinero = NormalizeDouble(lvutilidaddinero,2);
   UtilidadDinero.Text(DoubleToString(lvutilidaddinero,2));

   

   string lvratiotext = "Ratio 1 :   "+ DoubleToString(lvratio,2);

   //ratioBtn.Text(DoubleToString(lvratio,2));
   //ratioText.Text(lvratiotext);

  }


//+------------------------------------------------------------------+
//| Programar compras y ventas                                   |
//+------------------------------------------------------------------+
void ProgramarCompraVenta()
  {
      double lvspread = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
      double lvpips =  Pips_sl;

      if (calc_mode == SYMBOL_CALC_MODE_CFD || calc_mode == SYMBOL_CALC_MODE_CFDLEVERAGE) 
      {
         lvpips = lvpips * _Point * 100 ;
         lvspread = lvspread / 100;
         if (StringFind(_Symbol, "XAU") != -1) 
         {
            lvspread = lvspread / 1000;
            lvpips = lvpips * _Point  * 1000;
         }
         
      }
   
   
      if (calc_mode == SYMBOL_CALC_MODE_FOREX) 
      {
         lvspread = 0 ;
         lvpips = lvpips * _Point  ;
         if (StringFind(_Symbol, "XAU") != -1) 
         {
            lvpips = lvpips  * 100;
         }
         else
         {
         
         }

      }   
      
      //lvpips =  lvpips + lvspread;
      
      //Print("VGResistencia: ",VGResistencia,"VGMaximo2 :",VGMaximo2);
      
      datetime VGHoraInicio = iTime(_Symbol, _Period, 30);
      porcentajeUtilidad1  = StringToInteger(porcentajeUtilidad.Text());
      //datetime VGHoraFinal = iTime(_Symbol, _Period,0) + 300;
      
      //VGResistencia  = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
      //VGSoporte      = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);  
          
      //double lvpips = 5 * Puntos;
      //Print( "_Point: ",_Point, " lvpips:",lvpips, " lvpipstexto:",lvpipstexto);
      
      double lvpuntosloss_buy = 0;
      double lvpuntosprofit_buy = 0;
      double lvpuntosloss_sell = 0;
      double lvpuntosprofit_sell = 0;
      
      double loss_money_sell   = 0;
      double profit_money_sell = 0;
      double loss_money_buy    = 0;
      double profit_money_buy  = 0;

      //double distanceFromSupport = 0;
      


      string obj_nombre = "maximo_M15";
      VGMaximo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
      VGMaximo1 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);

      obj_nombre = "minimo_M15";
      VGMinimo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
      VGMinimo1= ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);

       // Calcular el punto medio (50%)
       //VGMidPrice = VGResistencia + (VGSoporte - VGResistencia) / 2.0;
   
       // Calcular la distancia total entre soporte y resistencia
       //double totalDistance = VGResistencia - VGSoporte;

       //double totalDistance = VGvalor_fractal_alto - VGvalor_fractal_bajo;
   
       // Calcular la distancia entre el Bid y el soporte
       //if (Bid > VGMidPrice)
       //{
       //     distanceFromSupport = Bid - VGSoporte;
       //}
       //else
       //{
       //     distanceFromSupport = VGResistencia - Bid;
       //}
       
       //Print(" VGvalor_fractal_alto : ",VGvalor_fractal_alto , " VGvalor_fractal_bajo : ",VGvalor_fractal_bajo);
       
       //if (VGTendencia_interna == "Alcista" || VGTendencia_interna == "Neutra")
       //{
       //   distanceFromSupport = VGResistencia - Bid;
       //}
       //else
       //{
       //  distanceFromSupport = Bid - VGSoporte;
       //}   
       
       // Calcular el porcentaje entre el soporte y la resistencia
       //if(totalDistance > 0)
         //VGPorcentaje = (distanceFromSupport / totalDistance) * 100; //german
       

      string midPriceName = "midPrice";
      // Verificar si la línea  ya existe
      if (ObjectFind(0, midPriceName) == -1) // No existe
      {
        // Crear la línea de tendencia
        ObjectCreate(0, midPriceName, OBJ_HLINE, 0,0,VGMidPrice);
        Print("Línea de tendencia creada.");
      }
      else // Existe, actualizarla
      {
        // Actualizar los puntos de la línea de tendencia
        ObjectSetDouble(0, midPriceName, OBJPROP_PRICE,VGMidPrice);
        ObjectSetInteger(0, midPriceName, OBJPROP_COLOR,LightSkyBlue);
        ObjectSetInteger(0, midPriceName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetString(0, midPriceName, OBJPROP_TEXT,"50%");
      
        //Print("Línea de tendencia actualizada.");
      } 
            


   //Bloque para trabajar con soporte y resistencia    
   
      int lvpuntos_soporte_resistencia = 50;   



      if (Bid > VGMaximo1 && Bid > VGMidPrice)
      {
            //sellBtn.Show();
      } 

      if (Bid < VGMidPrice || Bid < VGMaximo1 && lotaje_automatico)
      {
           if (lotaje_automatico)
           {
               //sellBtn.Hide();
           }  
           else
           {
               //sellBtn.Show();
           }
      }

     if (Bid > VGMidPrice && ContadorZonaPremiunt == 0)
     {
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGMidPrice);
         ContadorZonaPremiunt = 1;
         ContadorZonaDiscount = 0;
         //buyBtn.Hide();
         //sellBtn.Show();
     }
     

      if (Bid <  VGMinimo2 && Bid < VGMidPrice )
      {
            //buyBtn.Show();
      }
      
      if (Bid >  VGMidPrice || Bid > VGMinimo2)
      {
           if (lotaje_automatico)
           {
               //buyBtn.Hide();
           }  
           else
           {
               //buyBtn.Show();
           }
      }
      
     if (Bid < VGMidPrice && ContadorZonaDiscount == 0)
     {
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMidPrice);
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice);
         ContadorZonaPremiunt = 0;
         ContadorZonaDiscount = 1;
         //buyBtn.Show();
         //sellBtn.Hide();
     }

        //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGResistencia  + lvpips );
        //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice);
        //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGSoporte - lvpips);
        //ObjectSetInteger(0, "minimo_M15", OBJPROP_FILL,true);     
           



//      double lvpuntosloss_sell = NormalizeDouble((VGMaximo1 - VGMaximo2) / _Point,2);
//      double lvpuntosprofit_sell = NormalizeDouble((VGMaximo2 - VGMinimo2) / _Point,2);
//
//      if( calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
//      {
//         lvpuntosloss_sell = NormalizeDouble((VGMaximo1 - VGMaximo2) / tick_size,2);
//         lvpuntosprofit_sell = NormalizeDouble((VGMaximo2 - VGMinimo2) / tick_size,2);
//      }


      // Obtener el timeframe del gráfico
      int futureBars = 0;
      ENUM_TIMEFRAMES timeframe = (ENUM_TIMEFRAMES)ChartPeriod(0);
      int periodSeconds = PeriodSeconds(timeframe);
      // Obtener la última barra actual
      datetime lastBarTime = iTime(NULL, 0, 0); // Última barra (actual)
      // Calcular el tiempo futuro
      futureTime = lastBarTime + periodSeconds * futureBars;


//Ojo ver si es necesario
      //if (VGMaximo1 <  VGMaximo2)
      //{
      //   double tempmaximo = VGMaximo1;
      //   VGMaximo1 = VGMaximo2;
      //   VGMaximo2 = tempmaximo;
      //}   
      
      lvpuntosloss_sell = CalculateMovementAndProfit(VGMaximo2, VGMaximo1, 0);
      lvpuntosprofit_sell = CalculateMovementAndProfit(VGMaximo1, VGMinimo1, 0);



      obj_nombre = "maximo_M15";
      //iTime(_Symbol, _Period, 30);
      //ObjectSetInteger(0,obj_nombre,OBJPROP_TIME,0,iTime(_Symbol, _Period, 30));
      //ObjectSetInteger(0,obj_nombre,OBJPROP_TIME,1,futureTime );
      //ObjectSetInteger(0,obj_nombre,OBJPROP_COLOR,C'89,9,24');
      ObjectSetInteger(0,obj_nombre,OBJPROP_SELECTABLE,true);
      //ObjectSetInteger(0,obj_nombre,OBJPROP_SELECTED,true);
      ObjectSetInteger(0,obj_nombre,OBJPROP_FILL,true);
      //ObjectSetInteger(0,obj_nombre,OBJPROP_STYLE, STYLE_DOT);
      //ObjectSetInteger(0,obj_nombre, OBJPROP_BACK, true); // Mueve el objeto detrás de las velas
      ObjectSetInteger(0,obj_nombre,OBJPROP_ZORDER, 0);


      obj_nombre = "minimo_M15";
      //ObjectSetInteger(0,obj_nombre,OBJPROP_TIME,0,VGHoraInicio);
      //futureTime = lastBarTime + periodSeconds * (futureBars) ;
      //ObjectSetInteger(0,obj_nombre,OBJPROP_TIME,1,futureTime);
      //ObjectSetInteger(0,obj_nombre,OBJPROP_COLOR,C'0,105,108');
      ObjectSetInteger(0,obj_nombre,OBJPROP_FILL,true);
      //ObjectSetInteger(0,obj_nombre,OBJPROP_STYLE,STYLE_DASHDOTDOT);
      //ObjectSetInteger(0,obj_nombre, OBJPROP_BACK, true); // Mueve el objeto detrás de las velas
      ObjectSetInteger(0,obj_nombre,OBJPROP_ZORDER, 9999);

   
      //Print("VGMaximo1 : ",VGMaximo1);
      //VGMinimo1= ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
      //VGMinimo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
      
     
      
      
      //Print("VGMinimo2:",VGMinimo2, " VGMinimo1 : ",VGMinimo1);
      
//para fijar la parte superior del cuadro de ventas 
      if(VGMinimo2 != VGMaximo1)
      {
            //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMinimo2);

            //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMinimo2);//Activa german

      }
      
      //else
      //{
      //      ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMinimo2);
      //}
      
//Si la linea de minimo 1 es mayor a minimo2 se deja igual a minimo 1 , para solucionar el problema      

      if(VGMinimo2 < VGSoporte)
      {
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMidPrice);//activar german
      }
      
      if(VGMinimo2 > VGMaximo2)
      {
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMidPrice);//activar german
      }

      //double lvpuntosloss_buy = NormalizeDouble((VGMinimo2 - VGMinimo1) / _Point,2);
      //double lvpuntosprofit_buy = NormalizeDouble((VGMaximo2 - VGMinimo1) / _Point,2);
      //if( calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
      //{
      //   lvpuntosloss_buy = NormalizeDouble((VGMinimo2 - VGMinimo1) / tick_size,2);
      //   lvpuntosprofit_buy = NormalizeDouble((VGMaximo2 - VGMinimo1) / tick_size,2);
      //   //lvpuntosloss_buy = lvpuntosloss_buy / 100;
      //   //lvpuntosprofit_buy = lvpuntosprofit_buy / 100;
      //}

      //if (VGMinimo1 > VGMinimo2)
      //{
      //   double tempminimo = VGMinimo1;
      //   VGMinimo1 = VGMinimo2;
      //   VGMinimo2 = tempminimo;
      //}   

      lvpuntosloss_buy = CalculateMovementAndProfit(VGMinimo1, VGMinimo2, 0);
      lvpuntosprofit_buy = CalculateMovementAndProfit(VGMaximo1, VGMinimo1, 0);

      
     VGprecioCompra  = VGMinimo2;
     VGprecioventa   = VGMaximo2;
     
     double lvlotes        =  0;
     double lvratio        =  0;
     double lotesCompra    =  0;
     double lotesventa     =  0;
     double ValorLabel     =  0;
     string TextLabel;
     
     double vlsl     = StringToDouble(puntosFvg.Text()) * Puntos ; 
     double PipsSL   = NormalizeDouble(0,2);
     double PipsTP   = NormalizeDouble(0,2);
           
      

      double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

      double lvlote = StringToDouble(lotSizeSell.Text());
      
      if (lvlote < volumeMin )
      {
         //lvlote = volumeMin;
         //lotSize.Text(lvlote);
      }

      
      //pointValue = NormalizeDouble(,SYMBOL_TRADE_TICK_VALUE,2);

     //int    vlpuntos = 10;
     //if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) == 1)
     //{
     //    vlpuntos = 100;
     //}
     //if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) == 100)
     //{
     //    vlpuntos = 10;
     //}


    // Account balance
     double lvcapital = AccountInfoDouble(ACCOUNT_EQUITY);
     double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
     double tamanoPosicion = 0;
         
     //double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
     //double TickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
     
        //double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
        //double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
        //double tick_step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

        string vllabel = "Text_Venta";
        DrawText(vllabel,VGMaximo2,"Prueba",futureTime,1);
        
////Inicio +++++++++
//        string vllabel = "LabelTextVenta";
//        
//        //double lvdiferencia = ((VGMaximo1 - VGMaximo2) / _Point)/2;
//        //ValorLabel = VGMaximo2 + (lvdiferencia * Puntos);
//
//        ValorLabel = VGMaximo1 + (lvpipstexto * Puntos);
//
//        if( calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
//        {
//           // Normalizar el precio de entrada
//           double normalizedEntryPrice = VGMaximo1 / tick_size;
//           double lvlabel = normalizedEntryPrice + lvpipstexto;
//
//           ValorLabel =  lvlabel * tick_size;
//        }        
//      
////Habilitar para crear          
//        if(!ObjectCreate(current_chart_id, vllabel, OBJ_TEXT,0,futureTime,ValorLabel)) 
//        { 
//         Print(__FUNCTION__, 
//               ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
//        } 
////// Fin ++++        
        
        //double lvdiferencia = MathAbs(VGMaximo1 - VGMaximo2) * VGpuntos ;

        //double lvdiferencia = VGMaximo1 - VGMaximo2  ;
//        PipsSL = lvdiferencia;
//        
//        lvdiferencia = VGMaximo2 - VGMinimo2 ;
//        PipsTP = lvdiferencia ;
//        lvratio = PipsTP / PipsSL;
        
          //lvratio =  lvpuntosprofit_sell / lvpuntosloss_sell;
           
        //lvratio = (VGMinimo1 - VGMaximo2) / (VGMaximo2 - VGMaximo1);
        //lvratio = ((VGMaximo2 - VGMinimo1) / (VGMaximo1 - VGMaximo2)) - 1;
        //lvratio = PipsTP / PipsSL;
        //lotesventa = (porcentajeRiesgo1 / (ac / (VGMaximo2/TickValue))/100)/minLot*minLot;



//        lotesventa = (lvcapital * porcentajeRiesgo1/100) / (VGMaximo1 - VGMaximo2) * _Point;
//
//        //lotesventa = (lvcapital * (porcentajeRiesgo1/100)) / ((VGMaximo1 - VGMaximo2)*VGmicrolotes);
//
//        if (calc_mode == SYMBOL_CALC_MODE_CFD) 
//        {
//       
//           lotesventa = (lvcapital * porcentajeRiesgo1) / (VGMaximo1 - VGMaximo2) * _Point;
//   
//        } 
//
//        if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
//        {
//           //Print("Futuros....");
//           //Revisar la forma que usa los futuros
//       
//           //lotesventa = (lvcapital * porcentajeRiesgo1) / (VGMaximo1 - VGMaximo2) * _Point;
//   
//        } 



        //Print(" Capital : ",lvcapital, " porcentajeRiesgo1 ",porcentajeRiesgo1, "  ",porcentajeRiesgo1/100, " lvdiferencia :",(VGMaximo1 - VGMaximo2), " Point :",_Point, " VGmicrolotes :",VGmicrolotes, " VGpuntos :", VGpuntos);
        // Sleep(1000);

        //lotesventa = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);
        //if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) > 1)
        //{
        //   lotesCompra = lotesCompra * 10;
        //   lotesventa = lotesventa * 10;
        //}        
        
        //lvratio = DoubleToString(lvratio,2);
        //PipsSL = DoubleToString(PipsSL,2);
        //PipsTP = DoubleToString(PipsTP,2);

//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.5)
//         {
//           lotesCompra = DoubleToString(lotesCompra,0);
//           lotesventa = DoubleToString(lotesventa,0);
//         }
//      
//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.10)
//         {
//           lotesCompra = DoubleToString(lotesCompra,1);
//           lotesventa = DoubleToString(lotesventa,1);
//         }
//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.01)
//         {
//           lotesCompra = DoubleToString(lotesCompra,2);
//           lotesventa = DoubleToString(lotesventa,2);
//         }
         
         //double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
         //double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
         
//         double loss_money_sell=DoubleToString(tick_value*lvlote*(tick_size/_Point)*lvpuntosloss_sell,2);
//         double profit_money_sell=DoubleToString(tick_value*lvlote*(tick_size/_Point)*lvpuntosprofit_sell,2);
//
//         if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
//         {
//             loss_money_sell=DoubleToString(tick_value * lvlote * lvpuntosloss_sell,2);
//             //loss_money_sell = loss_money_sell /100;
//             profit_money_sell=DoubleToString(tick_value * lvlote * lvpuntosprofit_sell,2);
//             //profit_money_sell = profit_money_sell / 100;
//         }   
           
         lvlote = CalculateLotSize(VGMaximo1, VGMaximo2, porcentajeRiesgo1); //calcular el tamano del lote  
         lotSizeSell.Text(lvlote);
         if (Bid >  VGMaximo1) // && Bid > VGMidPrice)
         {
             //Print("VGMaximo1:",VGMaximo1);
             //VGMaximo1 =  Bid;
             //lvlote = CalculateLotSize(VGMaximo1, VGMaximo2, porcentajeRiesgo1); //calcular el tamano del lote
             if (lotaje_automatico)
             {
                VGMaximo1 =  Bid;
                lvlote = CalculateLotSize(VGMaximo1, VGMaximo2, porcentajeRiesgo1); //calcular el tamano del lote
                lotSizeSell.Text(lvlote);
             }  
             else
             {
                lvlote =  lotSizeSell.Text();
             }   
         }  
         //else
         //{
         //    if (lotaje_automatico)
         //    {
         //       VGMaximo1 =  Bid;
         //       lvlote = CalculateLotSize(VGMaximo1, VGMaximo2, porcentajeRiesgo1); //calcular el tamano del lote
         //       lotSizeSell.Text(lvlote);
         //    }   
         //    else
         //    {
         //      lvlote =  lotSizeSell.Text();
         //    }   
         //}  
         

         //Print("VGMaximo1 : ",VGMaximo1," VGMaximo2 : ",VGMaximo2, "VGMinimo1 : ",VGMinimo1," VGMinimo2 : ",VGMinimo2);

         lvpuntosloss_sell = CalculateMovementAndProfit(VGMaximo2, VGMaximo1, 0);
         lvpuntosprofit_sell = CalculateMovementAndProfit(VGMaximo1, VGMinimo1, 0);
               
         loss_money_sell   = CalculateMovementAndProfit(VGMaximo1, VGMaximo2, lvlote);
         profit_money_sell = CalculateMovementAndProfit(VGMaximo1, VGMinimo1, lvlote);

         loss_money_sell = loss_money_sell * porcentajeUtilidad1;
         profit_money_sell = profit_money_sell * porcentajeUtilidad1;
         
         lvlote = lvlote * porcentajeUtilidad1;
         
         //Print("lvpuntosprofit_sell : ",lvpuntosprofit_sell);
         if ( lvpuntosloss_sell != 0 )
            lvratio =  (lvpuntosprofit_sell / lvpuntosloss_sell);
         
        //Print("lvpuntosloss_sell : ",DoubleToString(lvpuntosloss_sell,2), " lvpuntosprofit_sell : ",DoubleToString(lvpuntosprofit_sell,2)," lvratio : ",DoubleToString(lvratio,2)); 

        TextLabel = "RR:" + DoubleToString(lvratio,2) + " PF:" + DoubleToString(profit_money_sell,2) + " Loss:" + DoubleToString(loss_money_sell,2)  + " Lots:" + DoubleToString(lvlote,2) ;// +  " P" + DoubleToString(lvpuntosprofit_sell,1) + " L" + DoubleToString(lvpuntosloss_sell,1) ; 

        VGloteVenta    =  lotesventa;

        ObjectSetString(current_chart_id, vllabel,OBJPROP_TEXT,TextLabel); 
        ObjectSetString(current_chart_id, vllabel,OBJPROP_TOOLTIP,TextLabel); 
        //ObjectSetInteger(current_chart_id, vllabel,OBJPROP_COLOR,clrWhite);
        ObjectSetInteger(current_chart_id,vllabel,OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
        ObjectSetInteger(current_chart_id, vllabel,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(current_chart_id, vllabel, OBJPROP_BACK, false);
        ObjectSetInteger(current_chart_id, vllabel,OBJPROP_ZORDER,9999);
        ChartRedraw();
        //ObjectSetInteger(current_chart_id, vllabel,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M5|OBJ_PERIOD_M15);
        
//++Fin Ventas        

 
 
//++ Inicio Compras 


            
        lvlote = StringToDouble(lotSizeBuy.Text()); 

        vllabel = "Text_Compra";
        DrawText(vllabel,VGMinimo1,"Prueba",futureTime,0);


        //vllabel = "LabelTextCompra";

        //lvdiferencia = ((VGMinimo2 - VGMinimo1) / _Point)/2;
        //ValorLabel = VGMinimo1 + (lvdiferencia * Puntos);
        //if(!ObjectCreate(current_chart_id,vllabel,OBJ_TEXT,0,TimeCurrent() + 400,ValorLabel)) 
        
//         // Obtener el tamaño mínimo de movimiento del activo
//         double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
//         if (tickSize <= 0) tickSize = _Point; // En caso de error, usa _Point como fallback
//
//
//        //ValorLabel = VGMinimo1 - (50 * tickSize);
//        
//
//        if( calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
//        {
//           // Normalizar el precio de entrada
//           double normalizedEntryPrice = VGMinimo1 / tick_size;
//           double lvlabel = normalizedEntryPrice - lvpipstexto;
//
//           ValorLabel =  lvlabel * tick_size;
//        }        
        
        
        
//Habilitar para crear
//   
//       if(!ObjectCreate(current_chart_id,vllabel,OBJ_TEXT,0,futureTime, ValorLabel)) 
//        { 
//         Print(__FUNCTION__, 
//               ": ¡Fallo al crear la línea horizontal! Código del error = ",GetLastError()); 
//        } 
//        
                
        //lvdiferencia = (VGMinimo2 - VGMinimo1) * VGpuntos;
        //PipsSL = DoubleToString(lvdiferencia,2);
        //lvdiferencia = (VGMaximo2 - VGMinimo2) * VGpuntos;
        //PipsTP = DoubleToString(lvdiferencia,Digits());
        //lvratio = (VGMaximo1 - VGMinimo2) / (VGMinimo2 - VGMinimo1);  
        //lvratio = ((VGMaximo2 - VGMinimo2) / (VGMinimo2 - VGMinimo1)) - 1; 
        //lvratio = DoubleToString(PipsTP / PipsSL,2); 
        //lotesventa = (lvcapital * (porcentajeRiesgo1/100)) / ((VGMaximo1 - VGMaximo2)*lvmicrolotes);
 
        //lotesCompra = (lvcapital * (porcentajeRiesgo1 / 100)) / ((VGMinimo2 - VGMinimo1)*VGmicrolotes);

//       lotesCompra = (lvcapital * (porcentajeRiesgo1 / 100)) / (VGMinimo2 - VGMinimo1) * _Point ;
//
//        if (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE) == SYMBOL_CALC_MODE_CFD) 
//        {
//       
//           lotesCompra = (lvcapital * porcentajeRiesgo1) / (VGMinimo2 - VGMinimo1) * _Point;
//   
//        } 
        
        
        //Print(" Capital : ",lvcapital, " porcentajeRiesgo1 ",porcentajeRiesgo1, "  ",porcentajeRiesgo1/100, " lvdiferencia :",(VGMinimo2 - VGMinimo1), " Point :",_Point, " VGmicrolotes :",VGmicrolotes, " VGpuntos :", VGpuntos);
        // Sleep(1000);

        // Sleep(1000);        //lotesCompra = porcentajeRiesgo1/(tick_value*(tick_size/_Point)*PipsSL);


        //if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) > 1)
        //{
        //   lotesCompra = lotesCompra * 10;
        //   lotesventa = lotesventa * 10;
        //}        
        
//        lvratio = DoubleToString(lvratio,2);
//        PipsSL = DoubleToString(PipsSL,2);
//        PipsTP = DoubleToString(PipsTP,2);
//        
        //if (SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) > 1)
        //{
        //   lotesCompra = lotesCompra * 10;
        //   lotesventa = lotesventa * 10;
        //}        

//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.5)
//         {
//           lotesCompra = DoubleToString(lotesCompra,0);
//           lotesventa = DoubleToString(lotesventa,0);
//         }
//      
//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.10)
//         {
//           lotesCompra = DoubleToString(lotesCompra,1);
//           lotesventa = DoubleToString(lotesventa,1);
//         }
//         if (SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP) == 0.01)
//         {
//           lotesCompra = DoubleToString(lotesCompra,2);
//           lotesventa = DoubleToString(lotesventa,2);
//         }

//         double loss_money_buy=DoubleToString(tick_value*lvlote*(tick_size/_Point)*lvpuntosloss_buy,2);
//         double profit_money_buy=DoubleToString(tick_value*lvlote*(tick_size/_Point)*lvpuntosprofit_buy,2);
//         
//         if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
//         {
//               loss_money_buy=DoubleToString(tick_value * lvlote * lvpuntosloss_buy,2);
//               //loss_money_buy = loss_money_buy /100;
//               profit_money_buy=DoubleToString(tick_value * lvlote * lvpuntosprofit_buy,2);
//               //profit_money_buy = profit_money_buy / 100;
//         }

         
         //Print("VGMaximo2:",VGMaximo2," VGMaximo1",VGMaximo1);

         //lotSizeBuy.Text(0);
         lvlote = CalculateLotSize(VGMinimo2, VGMinimo1, porcentajeRiesgo1); //calcular el tamano del lote
         lotSizeBuy.Text(lvlote);
         
         if (Bid < VGMinimo2)// && Bid < VGMidPrice)
         {
             //VGMinimo2 =  Bid;
             //lvlote = CalculateLotSize(VGMinimo1, VGMinimo2, porcentajeRiesgo1); //calcular el tamano del lote
             if (lotaje_automatico)
             {
                VGMinimo2 =  Bid;
                lvlote = CalculateLotSize(VGMinimo2, VGMinimo1, porcentajeRiesgo1); //calcular el tamano del lote
                lotSizeBuy.Text(lvlote);
             }   
             else
             {
               lvlote =  lotSizeSell.Text();
             }   
         } 
         //else
         //{
         //    if (lotaje_automatico)
         //    {
         //       VGMinimo2 =  Bid;
         //       lvlote = CalculateLotSize(VGMinimo2, VGMinimo1, porcentajeRiesgo1); //calcular el tamano del lote
         //       lotSizeBuy.Text(lvlote);
         //    }   
         //    else
         //    {
         //      lvlote =  lotSizeSell.Text();
         //    }   
         //    //Sleep(2000);
         //    //Print("lvlote: ",lvlote);
         //}   

         lvpuntosloss_buy = CalculateMovementAndProfit(VGMinimo2, VGMinimo1, 0);
         lvpuntosprofit_buy = CalculateMovementAndProfit(VGMaximo2, VGMinimo2, 0);
             
         loss_money_buy   = CalculateMovementAndProfit(VGMinimo2, VGMinimo1, lvlote);
         profit_money_buy = CalculateMovementAndProfit(VGMaximo2, VGMinimo2, lvlote);
         
         
         
         loss_money_buy = loss_money_buy * porcentajeUtilidad1;
         profit_money_buy = profit_money_buy * porcentajeUtilidad1;
         
         lvlote = lvlote * porcentajeUtilidad1;

         if (lvpuntosloss_buy != 0 )
            lvratio =  lvpuntosprofit_buy / lvpuntosloss_buy ;
         
         TextLabel = "RR:" + DoubleToString(lvratio,2) + " PF:" + DoubleToString(profit_money_buy,2) + " Loss:" + DoubleToString(loss_money_buy,2) + " Lots:" + DoubleToString(lvlote,2);//  +  " P:" + DoubleToString(lvpuntosprofit_buy,2) + " L:" + DoubleToString(lvpuntosloss_buy,2) ; //+ "  SL : " + NormalizeDouble(PipsSL,2) + " TP : " + NormalizeDouble(PipsTP,2) ;

      
//        loss_money=DoubleToString(tick_value*lvlote*(tick_size/_Point)*lvpuntoscompra,2);
//        loss_money = loss_money * porcentajeUtilidad1;
//
//         
//        TextLabel =  " $Loss: " + DoubleToString(loss_money,2) + " Lots: " + DoubleToString(lvlote,2) +   " RR: " + DoubleToString(lvratio,2) + " Puntos:" + lvpuntoscompra   ; //+ " SL : " + NormalizeDouble(PipsSL,2) + " TP : "+ NormalizeDouble(PipsTP,2)  ;

        VGloteCompra   =  lotesCompra;
        
        ObjectSetString(current_chart_id, vllabel,OBJPROP_TEXT,TextLabel);  
        ObjectSetString(current_chart_id, vllabel,OBJPROP_TOOLTIP,TextLabel); 
        ObjectSetInteger(current_chart_id, vllabel,OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
        ObjectSetInteger(current_chart_id, vllabel,OBJPROP_SELECTABLE,false);
        ObjectSetInteger(current_chart_id, vllabel,OBJPROP_ZORDER,9999);
        
        //ObjectSetInteger(current_chart_id, vllabel,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M5|OBJ_PERIOD_M15);
   

   //double PipValue = (((SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE))*point)/(SymbolInfoDouble(Symbol(),SYMBOL_TRADE_TICK_SIZE)));
   //lots = (porcentajeRiesgo1/100) * accountBalance / (PipValue * PipsSL);
      
     //Print("VGloteCompra :",VGloteCompra," VGloteVenta :",VGloteVenta);

//   lotSize.Text(lots);
//   double lvriesgodinero = (porcentajeRiesgo1/100) * accountBalance;
//   double lvutilidaddinero = (porcentajeUtilidad1/100) * accountBalance;
//   
//   lvriesgodinero = NormalizeDouble(lvriesgodinero,2);
//   RiesgoDinero.Text(lvriesgodinero);
//   
//   lvutilidaddinero = NormalizeDouble(lvutilidaddinero,2);

//   UtilidadDinero.Text(DoubleToString(lvutilidaddinero,2));


   obj_nombre = "maximo_M15";
   VGMaximo1 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
   VGMaximo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);
   
   obj_nombre = "minimo_M15";
   VGMinimo1= ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,1);
   VGMinimo2 = ObjectGetDouble (0,obj_nombre,OBJPROP_PRICE,0);

   double lvDifereciaCompra = Bid - VGMinimo2; 
   double lvDifereciaVenta = VGMaximo2 - Bid; 
   //Print("lvDifereciaCompra : ",lvDifereciaCompra," lvDifereciaVenta : ",lvDifereciaVenta);
   //if( lvDifereciaCompra > lvDifereciaVenta)
   if(Bid > VGMaximo1  )
   {
      sellBtn.Show();
      buyBtn.Hide();
      
//      sellBtn.Enable();
//      sellBtn.Text("Sell");
//      buyBtn.Disable();
//      buyBtn.Text("Desactivado");
//      
      
      //lotSize.Text(lotesventa);
   }
   else
   {
      buyBtn.Show();
      sellBtn.Hide();


      //buyBtn.Enable();
      //buyBtn.Text("Buy");
      //sellBtn.Disable();
      //sellBtn.Text("Desactivado");

      
      //lotSize.Text(lotesCompra);
   }
   string lvratiotext = "Ratio 1 :   "+ DoubleToString(lvratio,2);
   //ratioBtn.Text(DoubleToString(lvratio,2));
   //ratioText.Text(lvratiotext);
  }





void Alarmas()
{

   //return;
   
    string LVPosibleTrade;
    string LVSimbolo = ChartSymbol(0);

    double lvratio = StringToDouble(ratioBtn.Text());
    double lvlote = StringToDouble(lotSizeSell.Text());
    double lvporcentaje;
    double lvalto = ObjectGetDouble(0, "maximo_M15", OBJPROP_PRICE,0);  
    double lvbajo = ObjectGetDouble(0, "minimo_M15", OBJPROP_PRICE,1);  
 
   //double lvresistencia = ObjectGetDouble (0,"Resistencia",OBJPROP_PRICE);
   //double lvsoporte = ObjectGetDouble (0,"Soporte",OBJPROP_PRICE);
   
   
   //Print( " VGvalor_fractal_alto :",VGvalor_fractal_alto, " VGvalor_fractal_bajo : ",VGvalor_fractal_bajo);
   lvalto = iHigh(Symbol(), PERIOD_M1, iHighest(Symbol(), PERIOD_M1, MODE_HIGH, 5, 0));
   lvbajo = iLow(Symbol(), PERIOD_M1, iLowest(Symbol(), PERIOD_M1, MODE_HIGH, 5, 0));

   double lvresistencia = ObjectGetDouble (0,"Resistencia",OBJPROP_PRICE);
   double lvsoporte = ObjectGetDouble (0,"Soporte",OBJPROP_PRICE);
   
   string object_name = "ZONA_VENTAS";
   double lvzona_ventas = ObjectGetDouble (0,object_name,OBJPROP_PRICE,1);
   
          object_name = "ZONA_COMPRAS";
   double lvzona_compras = ObjectGetDouble (0,object_name,OBJPROP_PRICE);
   


   if ((Bid > lvresistencia ) && VGContadorAlertasZona == 0)
   {
      int lvstyle = ObjectGetInteger(0,"Resistencia",OBJPROP_STYLE);
      //if(lvstyle == STYLE_SOLID)
      //{
         //VGVenta = 1;
         //VGCompra = 0;
         textohablado("\"Precio Mayor a BSL o Resistencia "+ _Symbol +\"", true);
         VGContadorAlertasZona++;
      //}
   
   }

   if (( Bid > lvzona_ventas) && VGContadorAlertasZona == 0)
   {
      int lvstyle = ObjectGetInteger(0,"Resistencia",OBJPROP_STYLE);
      //if(lvstyle == STYLE_SOLID)
      //{
         //VGVenta = 1;
         //VGCompra = 0;
         textohablado("\"Zona de Ventas "+ _Symbol +\"", true);
         VGContadorAlertasZona++;
      //}
   
   }

   if ((Bid < lvsoporte) && VGContadorAlertasZona == 0)
   {
      int lvstyle = ObjectGetInteger(0,"Soporte",OBJPROP_STYLE);
      //Print("g ", lvstyle,  STYLE_SOLID);
      //if(lvstyle == STYLE_SOLID)
      //{
         //VGVenta = 0;
         //VGCompra = 1;
         textohablado("\" Precio menor a SSL o Soporte "+ _Symbol +\"", true);
         VGContadorAlertasZona++;
      //}
   
   }

   if (( Bid < lvzona_compras) && VGContadorAlertasZona == 0)
   {
      int lvstyle = ObjectGetInteger(0,"Soporte",OBJPROP_STYLE);
      //Print("g ", lvstyle,  STYLE_SOLID);
      //if(lvstyle == STYLE_SOLID)
      //{
         //VGVenta = 0;
         //VGCompra = 1;
         textohablado("\"Zona de Compras "+ _Symbol +\"", true);
         VGContadorAlertasZona++;
      //}
   
   }

   if(VGCompra == 1 ) //  compras
   {
   
      //double lvresistencia = ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE);
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,lvresistencia );
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_alto_5 );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_alto_5 );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
   
   }
         
   if(VGVenta == 1 ) // ventas
   {
      //double lvsoporte = ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0, VGvalor_fractal_alto_5);
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_bajo_5 );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte );
   
   }

   
   if (Bid > VGvalor_fractal_alto_5 && VGvalor_fractal_alto_5 > 0 )
   {
     //Print("German 1");
      //VGvalor_fractal_alto_5 = iHigh(_Symbol,Time_Frame_M2022,0);
      //   VGcontadorAlertasAlcista = 1;
      //   VGcontadorAlertasBajista = 0;
      //   VGMaximo2 = lvalto;
      //   double lvsoporte = ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
      //   double lvMidPrice     = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
      //   ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGMaximo2 );
      //   ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
      //   ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_bajo_5 );
      //   ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte );
   }

   if (Bid < VGvalor_fractal_bajo_5 &&  VGvalor_fractal_bajo_5 > 0)
   {
     //Print("German 2");
      //VGvalor_fractal_bajo_5 = iLow(_Symbol,Time_Frame_M2022,0);
      //   VGcontadorAlertasBajista = 1;
      //   VGcontadorAlertasAlcista = 0;
      //   VGMinimo1 = lvbajo;
      //   double lvresistencia = ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE);
      //   double lvMidPrice     = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
      //   ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMinimo1 );
      //   ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1, VGvalor_fractal_alto_5 );
      //   ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0, VGvalor_fractal_alto_5 );
      //   ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1, lvresistencia );
   
   }
   
   //Print("VGvalor_fractal_alto_5 : ",VGvalor_fractal_alto_5," VGvalor_fractal_bajo_5 : ",VGvalor_fractal_bajo_5);

   if(VGcontadorAlertasAlcista > 0 )
   {
      //VGMidPrice = (VGvalor_fractal_alto_5 - Bid) / (VGvalor_fractal_alto_5 - VGvalor_fractal_bajo_5) * 100;
   }
   
   if(VGcontadorAlertasBajista > 0 )
   {
      //VGMidPrice = (Bid - VGvalor_fractal_bajo_5 ) / (VGvalor_fractal_alto_5 - VGvalor_fractal_bajo_5) * 100;
   }
   //Print("VGPorcentaje : ",VGPorcentaje);

   
   if (lvalto > VGMaximo2) 
   {
         //VGcontadorAlertasAlcista = 1;
         //VGcontadorAlertasBajista = 0;
         //VGMaximo2 = lvalto;
         //double lvsoporte = ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
         //double lvMidPrice     = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGMaximo2 );
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_bajo_5 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte );
         ////ObjectSetDouble(0,"Resistencia",OBJPROP_PRICE,lvalto);
         ////textohablado("\"Precio Mayor a resistencia "+ _Symbol +\"", true);
   }   
   
   if (VGcontadorAlertasAlcista > 0)
   {
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGvalor_fractal_bajo_5 );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGvalor_fractal_bajo_5 );
   }   
   
   if (lvbajo < VGMinimo1 )
   {

         //VGcontadorAlertasBajista = 1;
         //VGcontadorAlertasAlcista = 0;
         //VGMinimo1 = lvbajo;
         //double lvresistencia = ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE);
         //double lvMidPrice     = VGMaximo2 + (VGMinimo1 - VGMaximo2) / 2.0;
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,VGMinimo1 );
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1, VGvalor_fractal_alto_5 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0, VGvalor_fractal_alto_5 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1, lvresistencia );
         ////ObjectSetDouble(0,"Soporte",OBJPROP_PRICE,lvbajo);
         ////textohablado("\"Precio Menor a Soporte "+ _Symbol +\"", true);
   }   

   if (VGcontadorAlertasBajista > 0)
   {
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1, VGvalor_fractal_alto_5 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0, VGvalor_fractal_alto_5 );
   }

//   if(Bid > VGvalor_fractal_alto)
//   {
//      VGContadorAlertasZona = 0;
//      VGContadorAlertasOte  = 0;
//      lvalto = iHigh(_Symbol,Time_Frame_M2022,0);
//      //ObjectSetDouble(0,"Resistencia",OBJPROP_PRICE,lvalto);
//   }   
//   
//   if(Bid < VGvalor_fractal_bajo )
//   {
//      lvbajo = iLow(_Symbol,Time_Frame_M2022,0);
//      VGContadorAlertasZona = 0;
//      VGContadorAlertasOte  = 0;
//      //ObjectSetDouble(0,"Soporte",OBJPROP_PRICE,lvbajo);
//   }   
//   
//   if ( VGvalor_fractal_alto < lvalto )
//      VGvalor_fractal_alto =  lvalto;
//
//   if ( VGvalor_fractal_bajo > lvbajo )
//      VGvalor_fractal_bajo =  lvbajo;



   //VGMidPrice = lvalto + (lvbajo - lvalto) / 2.0;
   
   
   if(VGcontadorAlertasAlcista >= 1)//  && VGTendencia_interna_H4 == "Alcista" && VGTendencia_interna_H1 == "Alcista" )
   {

      if (VGmodelo2022 == false  && MQLInfoInteger(MQL_TESTER) && VGtradedia <= 2)// && VGPorcentaje > inpporcentajeRetroceso )
      {
         //double lot = CalculateLotSize(Bid, lvalto, inpporcentajeRiesgo );
         VGtradedia++;
         double lot = CalculateLotSize(Bid, VGvalor_fractal_bajo_5, inpporcentajeRiesgo );
         //Print(" lot : ",lot, " VGPorcentaje : ",VGPorcentaje, " VGvalor_fractal_bajo_5 : ",VGvalor_fractal_bajo_5);
         VGcontadorAlertasAlcista = 0;
         MiTrade.Buy(lot,_Symbol, Bid, VGvalor_fractal_bajo_5,0,"Modelo 2022_Sin_TP " );
         VGmovetobreakeven = false;
      }
      
      //if ( VGPorcentaje > 100 )
      //{
      //   VGcontadorAlertasAlcista = 0;
      //}

   }
   
   if(VGcontadorAlertasBajista >= 1)//  && VGTendencia_interna_H4 == "Bajista" && VGTendencia_interna_H1 == "Bajista" )
   {

      if ( VGmodelo2022 == false && MQLInfoInteger(MQL_TESTER) && VGtradedia <= 2)// && VGPorcentaje > inpporcentajeRetroceso)
      
      {
         VGtradedia++;
         double lot = CalculateLotSize(Bid, VGvalor_fractal_alto_5, inpporcentajeRiesgo );
         //Print(" lot : ",lot, " VGPorcentaje : ",VGPorcentaje, " VGvalor_fractal_alto_5 : ",VGvalor_fractal_alto_5);
         VGcontadorAlertasBajista = 0;
         MiTrade.Sell(lot,_Symbol, Bid, VGvalor_fractal_alto_5,0,"Modelo 2022_Sin_TP " );
         VGmovetobreakeven = false;
      }

      //if ( VGPorcentaje > 100 )
      //{
      //   VGcontadorAlertasBajista = 0;
      //}
   }
      //Print( " CambioAlcista:",CambioAlcista," CambioBajista:",CambioBajista);
 

   if( Bid < lvbajo && VGcontadorAlertasBajista > 0)
   {

      lvbajo = iLow(_Symbol,Time_Frame_M2022,0);
      
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,lvalto ); 
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice ); 
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGMidPrice );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvbajo ); 
      //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
      //ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');
      //ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false); 
      //ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false); 
   }

   //if( (_Period == PERIOD_M15 || _Period == PERIOD_H1 || _Period == PERIOD_H4) && Bid < VGMinimo2 && ContadorAlertas == 0)
   
   if(  Bid > lvalto && VGcontadorAlertasAlcista > 0)
   {

      lvalto = iHigh(_Symbol,Time_Frame_M2022,0);
      
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,lvalto ); 
      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,VGMidPrice ); 
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGMidPrice );
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvbajo ); 
      //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
      //ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');
      //ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false); 
      //ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false); 

      if (CambioAlcista == 0)
      {
         CambioAlcista = 1;
         CambioBajista = 0;

      }

   }

   double lvmiDprice = ObjectGetDouble(0,"midPrice",OBJPROP_PRICE); 

   if(VGTendencia_interna_M15 == "Bajista")// && VGTendencia_interna_M3 == "Bajista")//VGcontadorAlertasBajista > 1 )//&& VGHoraNewYork.hour >= 09 && VGHoraNewYork.hour <= 10)// && Bid > VGMidPrice && VGContadorAlertasZona == 0) //&&  VGTendencia_interna == "Bajista" && VGContadorAlertasZona == 0)
   {

      //VGPorcentaje = (Bid - VGSoporte ) / (VGResistencia - VGSoporte) * 100; 
      //double lot = CalculateLotSize(Bid, lvalto, inpporcentajeRiesgo );

      //ObjectSetDouble(0,"minimo_M15",OBJPROP_PRICE,1,VGMidPrice);
      LVPosibleTrade = _Symbol + " :Zona Premiun !!!" + DoubleToString(VGSoporte,2) + " Server : " + TimeCurrent() + " Local : " + TimeLocal() ;//  " Lote " + NormalizeDouble(lvlote,2) + " - " +  " Ratio : " + NormalizeDouble(lvratio,2);  
      
      //VGPorcentaje = (Bid - VGvalor_fractal_bajo_5 ) / (VGvalor_fractal_alto_5 - VGvalor_fractal_bajo_5) * 100;
      if(Bid > lvmiDprice && VGContadorAlertasZona == 0)
      {
         //textohablado("\"Zona Premiun "+ _Symbol +\"", true);
         VGContadorAlertasZona++;
      }
   }


   
   if(VGTendencia_interna_M15 == "Alcista")// && VGTendencia_interna_M3 == "Alcista")// VGcontadorAlertasAlcista > 1)// && VGHoraNewYork.hour >= 09 && VGHoraNewYork.hour <= 10) //&& Bid < VGMidPrice && VGContadorAlertasZona == 0) //&& VGTendencia_interna == "Alcista" 
   {
      //VGSoporte = ObjectGetDouble (0,"Soporte",OBJPROP_PRICE);
      //VGPorcentaje = (VGResistencia - Bid) / (VGResistencia - VGSoporte) * 100;
      //double lot = CalculateLotSize(Bid, lvbajo, inpporcentajeRiesgo );
      LVPosibleTrade = _Symbol + " :Zona Discount !!!" + DoubleToString(VGSoporte,2) + " Server : " + TimeCurrent() + " Local : " + TimeLocal() ;//  " Lote " + NormalizeDouble(lvlote,2) + " - " +  " Ratio : " + NormalizeDouble(lvratio,2);  
      if(Bid < lvmiDprice && VGContadorAlertasZona == 0)
      {
         //textohablado("\"Zona de descuento " + _Symbol +\"",true);
         VGContadorAlertasZona++;
      }   
   }


}

void ManejoStopLoss()
{
   ContadorZB = 0;
   double lvtotalotes = 0;
   string   Symbolo;

   double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tick_step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   double lvtp1 = ObjectGetDouble(0,"TP1",OBJPROP_PRICE);
   
   

   //Print(" Ema :", ma200[0],  ma20[0], ma50[0]," Resistencia ", MiResistencia_1, " MiSoporte : ",MiSoporte_1 );
   //if (ma200[0] <= 0)
   //   return;
   //StopLoss = MiMedia;
   double   MiGanancia = 0;   
   double lvprofit = 0;
   int LvposicionesAbiertasCompras = 0;
   int LvposicionesAbiertasVentas = 0;
   double LvVolumenAnteriorCompras       = 0;
   double LvVolumenAnteriorVentas       = 0;
   
   double initialVolume = 0;

   double LvPorcentajeStopLoss = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*2/100,0);
   
   double LvGananaciaUno = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*porcentajeUtilidad1/100,0);
   double LvGananaciaDos = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*porcentajeUtilidad1/100,0);
   double LvGananaciaTres = 400; // NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*2/100,0);
   double LvGananaciaCuatro = 500;
   double LvPerdidaUno = NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*porcentajeRiesgo1/100,0);
   //double LvPerdidaDos =  NormalizeDouble(AccountInfoDouble(ACCOUNT_BALANCE)*1/100,0);
   //Print("LvPerdidaDos :",LvPerdidaDos);
   TotalMiGanancia = 0;
   
   BoolGananciaUno = true;
   BoolGananciaDos = false;

   long MiSpread = SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
   if(MiSpread < 1)
   {
     MiSpread = 1;
   }


    string symbol = _Symbol; // El símbolo actual del gráfico
    int total_ordenes_pendientes = 0; // Inicializamos el contador de órdenes pendientes

    // Iteramos sobre todas las órdenes activas
    for(int i = 0; i < OrdersTotal(); i++)
    {
        // Seleccionamos la orden por su índice
        ulong ticket = OrderGetTicket(i);

        // Seleccionamos la orden usando su ticket
        if(OrderSelect(ticket))
        {
            // Verificamos si la orden pertenece al símbolo deseado y es pendiente
            if(OrderGetString(ORDER_SYMBOL) == symbol)
            {
                int order_type = OrderGetInteger(ORDER_TYPE);
                if(order_type == ORDER_TYPE_BUY_LIMIT || 
                   order_type == ORDER_TYPE_SELL_LIMIT || 
                   order_type == ORDER_TYPE_BUY_STOP || 
                   order_type == ORDER_TYPE_SELL_STOP)
                {
                    VGtotalOrdenesAbiertas++;
                    total_ordenes_pendientes++; // Incrementamos el contador
                    double lvsl = OrderGetDouble(ORDER_SL);
                    double lvtp = OrderGetDouble(ORDER_TP);
                    if ( (Bid > lvsl || Bid < lvtp) && ( order_type == ORDER_TYPE_SELL_STOP || order_type == ORDER_TYPE_SELL_LIMIT) &&  lvsl > 0 && lvtp > 0)
                    {
                        MiTrade.OrderDelete(ticket);
                    
                    }
                    if ( (Bid < lvsl || Bid > lvtp) && (order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY_LIMIT) &&  lvsl > 0 && lvtp > 0)
                    {
                        MiTrade.OrderDelete(ticket);
                    
                    }
                    //Print("total_ordenes_pendientes :",total_ordenes_pendientes, " lvls : ",lvls);
                    ContadorZB++;
                }
            }
        }
    }



   int TotalPosiciones = PositionsTotal();
   
   //Print( " TotalPosiciones: ",TotalPosiciones);
   
   if(TotalPosiciones > 0)
   {

      for(int i=TotalPosiciones-1; i>=0; i--)
      {
         ulong    Ticket            = PositionGetTicket(i);
         string   Symbolo           = PositionGetString(POSITION_SYMBOL);
         long     Tipo              = PositionGetInteger(POSITION_TYPE);
         double   Mivolumen         = PositionGetDouble(POSITION_VOLUME);

         if(Symbolo == Symbol() && Tipo == POSITION_TYPE_BUY)
         {
            LvposicionesAbiertasCompras++;
            LvVolumenAnteriorCompras = Mivolumen;
            ContadorZB++;
            //Print("LvposicionesAbiertas  : ",LvposicionesAbiertas);
         }
      }

      for(int i=TotalPosiciones-1; i>=0; i--)
      {
         ulong    Ticket            = PositionGetTicket(i);
         string   Symbolo           = PositionGetString(POSITION_SYMBOL);
         long     Tipo              = PositionGetInteger(POSITION_TYPE);
         double   Mivolumen         = PositionGetDouble(POSITION_VOLUME);
         if(Symbolo == Symbol() && Tipo == POSITION_TYPE_SELL)
         {
            LvposicionesAbiertasVentas++;
            LvVolumenAnteriorVentas = Mivolumen;
            ContadorZB++;
            //Print("LvposicionesAbiertas  : ",LvposicionesAbiertas);
         }
         
      }

      //if((LvposicionesAbiertasCompras == LvposicionesAbiertasVentas))
      //{
      //   return;
      //}      


      // Mostrar información sobre cada una de las órdenes abiertas

      Ganancia = 0;
      for(int i=TotalPosiciones-1; i>=0; i--)
      {
         ulong    Ticket            = PositionGetTicket(i);
         Symbolo                    = PositionGetString(POSITION_SYMBOL);
         double   PrecioApertura    = PositionGetDouble(POSITION_PRICE_OPEN);
         double   StopLossAnterior  = PositionGetDouble(POSITION_SL);
                  MiGanancia        = PositionGetDouble(POSITION_PROFIT);
         long     Tipo              = PositionGetInteger(POSITION_TYPE);
         long     NumeroMagico      = PositionGetInteger(POSITION_MAGIC);
         double   Mivolumen         = PositionGetDouble(POSITION_VOLUME);
         double   MiTakeProfi       = PositionGetDouble(POSITION_TP);
         string   Comentario        = PositionGetString(POSITION_COMMENT);
         double   StopLossActual    = 0;
         int      StopLossVela      = 1;
         double   MiPerdida         = 0;

         ulong     Position          = PositionGetInteger(POSITION_IDENTIFIER);
         
         if (HistoryOrderSelect(Position));
         {
            ulong ticket=HistoryOrderGetTicket(0);
            initialVolume = HistoryOrderGetDouble(ticket,ORDER_VOLUME_INITIAL);
             //Print("initialVolume : ",initialVolume, "  TimePosition ",TimePosition);
         }         
         //Print("Position : ",Position);
         if (HistorySelectByPosition(Position));
         {
            // Iterar a través de las transacciones históricas
            BoolGananciaUno = true;
            for (int i = 0; i < HistoryDealsTotal(); i++)
            {
               if(i == 1)
               {
                  BoolGananciaUno = false;
                  BoolGananciaDos = true;
               }
               if(i >= 2)
               {
                  BoolGananciaDos = true;
               }
               //Print(" i : ",i, " BoolGananciaUno :",BoolGananciaUno, " BoolGananciaDos :",BoolGananciaDos);
               // Obtener detalles de la transacción histórica
               ulong historyTicket = HistoryDealGetTicket(i);
               //double historyPriceOpen = HistoryDealGetDouble(i, DEAL_PRICE_ENTRY);
               //double historyPriceClose = HistoryDealGetDouble(i, DEAL_PRICE_EXIT);
               datetime historyTimeOpen = HistoryDealGetInteger(historyTicket, DEAL_TIME);
               double historyVolume = HistoryDealGetDouble(historyTicket, DEAL_VOLUME);
               TimePosition = HistoryDealGetInteger(historyTicket, DEAL_TIME);
      
               //// Imprimir la información en el diario
               //Print("Historial de la posición ", Position);
               //Print("Transacción histórica #", i);
               //Print("Ticket histórico: ", historyTicket);
               //Print("Precio de apertura histórico: ", historyPriceOpen);
               ////Print("Precio de cierre histórico: ", historyPriceClose);
               //Print("Tiempo de apertura histórico: ", TimeToString(historyTimeOpen, TIME_DATE | TIME_MINUTES));
               ////Print("Tiempo de cierre histórico: ", TimeToString(historyTimeClose, TIME_DATE | TIME_MINUTES));
               //Print("Volumen histórico: ", historyVolume);
            }
      
            // Restablecer la selección histórica
            HistorySelectByPosition(0);
         }
         
         if (Symbol() == Symbolo)
         {
         
            VGtotalOrdenesAbiertas++;
            
            Ganancia = Ganancia + MiGanancia ;
            
            lvtotalotes = lvtotalotes + Mivolumen;
            //Print( "Mivolumen : " ,Mivolumen);
                         
            lvprofit =  MiGanancia / AccountInfoDouble(ACCOUNT_BALANCE) * 100;

            //lvprofit = NormalizeDouble(lvprofit,2);
            //porcentajeProfit.Text(lvprofit);
            //profitDineroBtn.Text(MiGanancia);

            if(lvprofit >= 3 && StopLossAnterior  < PrecioApertura && Tipo == POSITION_TYPE_BUY)
            {
               //MiTrade.PositionModify(Ticket,PrecioApertura,MiTakeProfi);
            }
            if(lvprofit >= 3 && StopLossAnterior > PrecioApertura && Tipo == POSITION_TYPE_SELL)
            {
               //MiTrade.PositionModify(Ticket,PrecioApertura,MiTakeProfi);
            }
 
            if(lvprofit >= 5) //Porcentaje utilidad
            {
               //MiTrade.PositionClose(Ticket);
            }

             //Print("lvprofit :",lvprofit," VGsamurai :", VGsamurai);
             
            if(lvprofit >= inpporcentajeGanancia && VGsamurai == true) 
            {
               MiTrade.PositionClose(Ticket);
               VGsamurai == false;
            }

            //VGmodelo2022 == false;
            //Print("Comentario: ",Comentario);
            //if (Comentario == "Modelo 2022")
            //    VGmodelo2022 == true;
                
            if (VGHoraNewYork.hour > 19 && VGHoraNewYork.hour < 23 && lvprofit >= 1.5  && StringFind(Comentario, "Modelo",0) >= 0)
            {
               MiTrade.PositionClose(Ticket);
            }              
            if(lvprofit >= inpporcentajeGanancia && StringFind(Comentario, "Modelo",0) >= 0) 
            {
               MiTrade.PositionClose(Ticket);
            }
            
            if(inpporcentajeGanancia >= 1 &&  lvprofit >= 1 && VGmodelo2022 == true && VGmovetobreakeven == false)
            {
               MoveToBreakEven(); 
               VGmovetobreakeven = true;    
            }


            if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.1)
            {
               Mivolumen = NormalizeDouble(Mivolumen * VGporcentaje_venta_lote,1);
            }
            if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.01)
            {
               Mivolumen = NormalizeDouble(Mivolumen * VGporcentaje_venta_lote,2);
            }

            if(lvprofit >= porcentajeUtilidad1)//Tomar parcial
            {
                  //MiTrade.PositionClosePartial(Ticket,Mivolumen);
                  //MiTrade.PositionModify(Ticket,PrecioApertura,MiTakeProfi);
            }            

            if(Tipo == POSITION_TYPE_SELL && BoolGananciaUno && Bid < VGMinimo2 ) //Tomar parcial
            {
                  //MiTrade.PositionClosePartial(Ticket,Mivolumen);
                  //MiTrade.PositionModify(Ticket,PrecioApertura,MiTakeProfi);
            }
            

            if(Tipo == POSITION_TYPE_BUY && BoolGananciaUno && Bid > VGMaximo2 ) //Tomar parcial
            {
                  //MiTrade.PositionClosePartial(Ticket,Mivolumen);
                  //MiTrade.PositionModify(Ticket,PrecioApertura,MiTakeProfi);
            }
         }
         
        
          
         //Ganancia = Ganancia + MiGanancia ;

          
         //if((MiHoraInicio.hour == 23 || MiHoraInicio.hour == 00 ) && (MiHoraInicio.min > 55 || MiHoraInicio.min < 30) && StopLossAnterior > 0)
         //{   
         //    if (StopLossAnterior > 0 && Symbol() == Symbolo)
         //    {
         //       //MiTrade.PositionModify(Ticket,0,MiTakeProfi);
         //    }
         //    return;
         //}

         if(Symbol() == Symbolo) 
         { 
            string name_object = "TP1";
            int ObjectExiste1 = ObjectFind(0,name_object);
            
            //Print(" ObjectExiste1 : ",ObjectExiste1);
            datetime fecha_inicial = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,0);
            datetime fecha_final   = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,1);
            
            double lvresistencia = ObjectGetDouble(0,"Resistencia",OBJPROP_PRICE);
            double lvsoporte = ObjectGetDouble(0,"Soporte",OBJPROP_PRICE);
            
            if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.1)
            {
               Mivolumen = NormalizeDouble(Mivolumen * VGporcentaje_venta_lote,1);
            }
            if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.01)
            {
               Mivolumen = NormalizeDouble(Mivolumen * VGporcentaje_venta_lote,2);
            }
            //Print("Mivolumen :",Mivolumen);

            double profit_money = CalculateMovementAndProfit(PrecioApertura, lvtp1, Mivolumen);
            
            if (profit_money < 0)
               profit_money = profit_money * -1;


            if((Tipo == POSITION_TYPE_BUY))
            {
               //double lvalto = ObjectGetDouble(0,"minimo_M15",OBJPROP_PRICE,0);
               //double lvbajo = ObjectGetDouble(0,"minimo_M15",OBJPROP_PRICE,1);
               
               double tp1 = PrecioApertura + ((PrecioApertura - StopLossAnterior ) *  2.5);
               //Print(" tp1 : ",tp1, " lvalto : ",lvalto , " lvbajo : ",lvbajo );
               
               if ( ObjectExiste1 < 0 && StopLossAnterior > 0) // No existe 
               {
                  ObjectCreate(0,name_object,OBJ_TREND,0,fecha_inicial,tp1,fecha_final,tp1);
               
               }
               if(  Bid >=  lvtp1 && lvtp1 > 0)
               {
                  MiTrade.PositionClosePartial(Ticket,Mivolumen);
                  ObjectSetDouble(0,name_object,OBJPROP_PRICE,0,lvresistencia);
                  ObjectSetDouble(0,name_object,OBJPROP_PRICE,1,lvresistencia);
                  MoveToBreakEven();
                  Print(" lvtp1 : ", lvtp1 );
               }  
            }
            if((Tipo == POSITION_TYPE_SELL))
            {
               
               //double lvalto = ObjectGetDouble(0,"maximo_M15",OBJPROP_PRICE,0);
               //double lvbajo = ObjectGetDouble(0,"maximo_M15",OBJPROP_PRICE,1);
               
               double tp1 = PrecioApertura - ((StopLossAnterior - PrecioApertura)  *  2.5);
               //Print(" tp1 : ",tp1, " lvalto : ",lvalto , " lvbajo : ",lvbajo );

               if ( ObjectExiste1 < 0 && StopLossAnterior > 0) // No existe 
               {
                  ObjectCreate(0,name_object,OBJ_TREND,0,fecha_inicial,tp1,fecha_final,tp1);
               
               }
               if(  Bid <=  lvtp1 && lvtp1 > 0)
               {
                  MiTrade.PositionClosePartial(Ticket,Mivolumen);
                  ObjectSetDouble(0,name_object,OBJPROP_PRICE,0,lvsoporte);
                  ObjectSetDouble(0,name_object,OBJPROP_PRICE,1,lvsoporte);
                  MoveToBreakEven();
                  Print(" lvtp1 : ", lvtp1 );
               }  
            }
            ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
            ObjectSetInteger(0,name_object,OBJPROP_SELECTED,true);
            ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrWhite);
            ObjectSetInteger(0,name_object,OBJPROP_TIME,0,fecha_inicial);
            ObjectSetInteger(0,name_object,OBJPROP_TIME,1,fecha_final);
            ObjectSetString(0,name_object,OBJPROP_TEXT,name_object + " Porcentaje : " + VGporcentaje_venta_lote + " Volumen : " + DoubleToString(Mivolumen,2) +   " Profit : "  + DoubleToString(profit_money,2));
         }

         if(Symbol() == Symbolo && sl_pf_Btn1 == true ) 
         {
               //Print("PrecioApertura :",PrecioApertura, " StopLossAnterior :",StopLossAnterior);
               VGMaximo2 = ObjectGetDouble(0,"maximo_M15",OBJPROP_PRICE,0);
               VGMinimo1 = ObjectGetDouble(0,"minimo_M15",OBJPROP_PRICE,1);
               if((Tipo == POSITION_TYPE_BUY))
               {
                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
                  {
                     VGMinimo1 = NormalizeDouble(VGMinimo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
                     VGMaximo2 = NormalizeDouble(VGMaximo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
                  }

                  VGMinimo1 = NormalizeDouble(VGMinimo1,Digits());
                  VGMaximo2 = NormalizeDouble(VGMaximo2, Digits());

                  if( VGMinimo1 != StopLossAnterior || VGMaximo2 != MiTakeProfi)
                  {
                      MiTrade.PositionModify(Ticket,VGMinimo1,VGMaximo2);
                      Print("VGMinimo1: ",VGMinimo1," StopLossAnterior :",StopLossAnterior, " Digits:",Digits());
                  }
//                  if( VGMinimo2 != StopLossAnterior)
//                  {
//                     MiTrade.PositionModify(Ticket,VGMinimo2,MiTakeProfi);
//                     
//                     //Print("VGMinimo1 :",VGMinimo1, " StopLossAnterior :",StopLossAnterior);
//                  }  
//                  if( VGMaximo1 != MiTakeProfi)
//                  {
//                     MiTrade.PositionModify(Ticket,VGMinimo1,VGMaximo1);
//                     //Print("VGMinimo1 :",VGMinimo1, " MiTakeProfi :",MiTakeProfi);
//                  }  

               }
               if((Tipo == POSITION_TYPE_SELL))
               {
                     //Print("VGMaximo1 :",VGMaximo1, " StopLossAnterior :",StopLossAnterior);
                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
                  {
                     VGMaximo2 = NormalizeDouble(VGMaximo1, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));  
                     VGMinimo1 = NormalizeDouble(VGMinimo2, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));
                  }
                  VGMaximo2 = NormalizeDouble(VGMaximo2, Digits());   
                  VGMinimo1 = NormalizeDouble(VGMinimo1, Digits());
                  if( VGMaximo2 != StopLossAnterior  || VGMinimo1 != MiTakeProfi )
                  {
                     MiTrade.PositionModify(Ticket,VGMaximo2,VGMinimo1);
                     Print("VGMaximo2: ",VGMaximo2," StopLossAnterior :",StopLossAnterior, " Digits:",Digits());
                  }
                  //if( VGMaximo1 != StopLossAnterior)
                  //{
                  //   MiTrade.PositionModify(Ticket,VGMaximo2,MiTakeProfi);
                  //   //Print("VGMaximo1 :",VGMaximo1, " StopLossAnterior :",StopLossAnterior);
                  //}  
                  //if( VGMinimo2 != MiTakeProfi)
                  //{
                  //   MiTrade.PositionModify(Ticket,VGMaximo1,VGMinimo1);
                  //   //Print("VGMinimo1 :",VGMinimo1, " MiTakeProfi :",MiTakeProfi);
                  //}  
               }

         }



         if(StopLossAnterior == 0  && Symbol() == Symbolo) //&& MiGanancia >= LvPorcentajeStopLoss)
         {
//               if(Tipo == POSITION_TYPE_BUY)
//               {
//                 StopLossActual = VGMinimo1 - 5 * Puntos;
//                 if (MiTakeProfi == 0)
//                 {
//                     MiTakeProfi = VGMaximo1;
//                 }
//               }
//               if(Tipo == POSITION_TYPE_SELL)
//               {
//                 if (MiTakeProfi == 0)
//                 {
//                     MiTakeProfi = VGMinimo1;
//                 }
//                 StopLossActual = VGMaximo1 + 5 * Puntos;
//               }
//               //StopLossAnterior = StopLossActual;
//               
//               MiTrade.PositionModify(Ticket,StopLossActual,MiTakeProfi);
         }
         
         //if(Symbol() == Symbolo)
         //{
         //   lvprofit =  Ganancia / AccountInfoDouble(ACCOUNT_BALANCE) * 100;
         //   lvprofit = NormalizeDouble(lvprofit,2);
         //   porcentajeProfit.Text(lvprofit);
         //   Ganancia = NormalizeDouble(Ganancia,2);
         //   profitDineroBtn.Text(Ganancia);
         //   //ratioBtn.Text(lvtotalotes);
         //}

         TotalMiGanancia = TotalMiGanancia + MiGanancia;
         if(TotalMiGanancia > 50000)
         {
            for(int i=TotalPosiciones-1; i>=0; i--)
            {
               ulong    Ticket            = PositionGetTicket(i);
               //MiTrade.PositionClose(Ticket);
            }            
         }
          //Print( "NumeroMagico :",NumeroMagico);
         if (MiGanancia < 0 && Symbol() == Symbolo)// && NumeroMagico == EntMagicNumber)
         {
            MiPerdida = MiGanancia * -1;
            if (lvprofit < -1 &&  PrecioApertura != MiTakeProfi ) 
            {
                  //MiTrade.PositionModify(Ticket,StopLossActual,PrecioApertura);
                 //MiTrade.PositionClosePartial(Ticket,Mivolumen);

                  //if(Tipo == POSITION_TYPE_BUY)
                  //{
                  //   MiTrade.Sell(Mivolumen);                  
                  //}
                  //else
                  //{
                  //   MiTrade.Buy(Mivolumen);                  
                  //}  
            }
            if (lvprofit < -2 ) 
            {
               //MiTrade.PositionClose(Ticket);
            }
            
         }
         //if (Mivolumen == 1 && Symbol() == Symbolo)// 
         //{
         //  BoolGananciaUno = false;
         //}
         //else
         //{
         //   BoolGananciaUno = true;
         //}

         if (MiGanancia >= LvGananaciaUno && Symbol() == Symbolo && BoolGananciaUno)
         {
            //porcentajeRiesgo1 = 0;
            porcentajeRiesgo.Text(porcentajeRiesgo1);
            double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
            VGriesgoDinero = (porcentajeRiesgo1/100) * accountBalance;
            VGriesgoDinero = NormalizeDouble(VGriesgoDinero,2);
            RiesgoDinero.Text(VGriesgoDinero);
            
         }      
         if (MiGanancia > VGriesgoDinero && (Bid <= VGMinimo2 || Bid >= VGMaximo2)   && Symbol() == Symbolo && BoolGananciaUno )
         {
                  if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.5)
                  {
                     Mivolumen = NormalizeDouble(initialVolume*VGporcentaje_venta_lote,0);
                     if (Mivolumen <= 1)
                         Mivolumen = 1; 
                     if (Mivolumen > 1 && Mivolumen < 2)
                         Mivolumen = 2; 
                     if (Mivolumen > 2 && Mivolumen < 3)
                         Mivolumen = 3; 
                     if (Mivolumen > 3 && Mivolumen < 4)
                         Mivolumen = 4; 
                     if (Mivolumen > 4 && Mivolumen < 5)
                         Mivolumen = 5; 
                  }

                  if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.1)
                  {
                     Mivolumen = NormalizeDouble(initialVolume*VGporcentaje_venta_lote,1);
                  }
                  if (SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP) == 0.01)
                  {
                     Mivolumen = NormalizeDouble(initialVolume*VGporcentaje_venta_lote,2);
                  }

         }

         if(Tipo == POSITION_TYPE_BUY && Symbol() == Symbolo)// && EntMagicNumber == NumeroMagico)
         {
         }

         if(Tipo == POSITION_TYPE_SELL && Symbol() == Symbolo)// && EntMagicNumber == NumeroMagico)
         {
         }
      }
   }

      sl_pf_Btn1 = false;

}


void tp(string tp_name, double entrada, double stoploss, int tipo, double lotes)
{
   string name_object = tp_name;
   int ObjectExiste1 = ObjectFind(0,name_object);

   datetime fecha_inicial = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,0);
   datetime fecha_final   = ObjectGetInteger(0,"maximo_M15",OBJPROP_TIME,1);

   double tp1;
   
   if (tipo == 1)//Compras
   {
      tp1 = entrada + ((entrada - stoploss ) *  2.5);
   }

   if (tipo == 2)//Ventas
   {
      tp1 = entrada - ((stoploss - entrada ) *  2.5);
   }
   
   if ( ObjectExiste1 < 0 ) // No existe 
   {
      ObjectCreate(0,name_object,OBJ_TREND,0,fecha_inicial,tp1,fecha_final,tp1);
   
   }

   double profit_money = CalculateMovementAndProfit(entrada, tp1, lotes);
   
   if (profit_money < 0)
      profit_money = profit_money * -1;

   ObjectSetDouble(0,name_object,OBJPROP_PRICE,0,tp1);
   ObjectSetDouble(0,name_object,OBJPROP_PRICE,1,tp1);
   ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,name_object,OBJPROP_SELECTED,true);
   ObjectSetInteger(0,name_object,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,name_object,OBJPROP_TIME,0,fecha_inicial);
   ObjectSetInteger(0,name_object,OBJPROP_TIME,1,fecha_final);
   ObjectSetString(0,name_object,OBJPROP_TEXT,name_object + " Porcentaje : " + VGporcentaje_venta_lote + " Lotes : " + DoubleToString(lotes,2) +   " Profit : "  + DoubleToString(profit_money,2));

}

void verificar_ordenes_Abiertas()
{

   int TotalPosiciones = PositionsTotal();
   int lvcontador = 0;
   //Print( " TotalPosiciones: ",TotalPosiciones);
   
//   if(TotalPosiciones > 0)
//   {
//
//      for(int i=TotalPosiciones-1; i>=0; i--)
//      {
//         ulong    Ticket  = PositionGetTicket(i);
//         string   Symbolo = PositionGetString(POSITION_SYMBOL);
//         if(Symbolo == Symbol() )
//         {
//            return;
//         }
//      }
//      if (lvcontador <=0)
//         ObjectsDeleteAll(0,"TP");
//   }
//   else
//   {
//      ObjectsDeleteAll(0,"TP");
//   }

   VGmodelo2022 = false ;

   for (int i=0; i < PositionsTotal(); i++)
   {
      ulong  position_ticket  =  PositionGetTicket(i); 
      string position_symbol  =  PositionGetString(POSITION_SYMBOL);
      string position_lvcomentario =      PositionGetString(POSITION_COMMENT);  
      //Print (" position_symbol : ",position_symbol, " VGmodelo2022 : ",VGmodelo2022, " position_lvcomentario : ",position_lvcomentario, " _Symbol :",_Symbol , " German ", " Positions : ",PositionsTotal(), " i:",i);                                       

//StringFind(_Symbol, "JPY") != -1 

     //Print(StringFind(position_lvcomentario, "Modelo 20"));

     if(_Symbol == position_symbol && StringFind(position_lvcomentario, "Modelo 20") >= 0)
     {
         VGmodelo2022 = true ;
         //Print (" position_symbol : ",position_symbol, " VGmodelo2022 : ",VGmodelo2022, " position_lvcomentario : ",position_lvcomentario, " _Symbol :",_Symbol , " German ", " Positions : ",PositionsTotal(), " i:",i);                                       
         //Print (" lvsimbolo : ",lvsimbolo, " VGmodelo2022 : ",VGmodelo2022, " lvcomentario : ",lvcomentario, " _Symbol :",_Symbol , " German ", " orders : ",total, " i:",i); 
         return;
     }      
   }
   
   int total=OrdersTotal();
   //Print("Total ordenes abiertas ",total);
   if (total <=0)
   {
      VGmodelo2022 = false ;
      return;
   }   

   for (int i=0; i < total; i++)
   {
   
      ulong ticket=OrderGetTicket(i);; 

     string lvsimbolo = OrderGetString(ORDER_SYMBOL);
     string lvcomentario  = OrderGetString(ORDER_COMMENT);
     if(_Symbol == lvsimbolo && StringFind(lvcomentario, "Modelo 20") >= 0)
     {
         VGmodelo2022 = true ;
         //Print (" lvsimbolo : ",lvsimbolo, " VGmodelo2022 : ",VGmodelo2022, " lvcomentario : ",lvcomentario, " _Symbol :",_Symbol , " German ", " orders : ",total, " i:",i); 
         break;
     }
     else
     {
         VGmodelo2022 = false ;
     }
   }

}



void MaximoMinimo()
{

   int ObjectExiste1 = ObjectFind(0,"maximo_M15");    
   int ObjectExiste2 = ObjectFind(0,"minimo_M15");    
   //Print("ObjectExiste : ",ObjectExiste);  
   if (ObjectExiste1 > 0 || ObjectExiste2 > 0 )
   {
      return;
      //ObjectsDeleteAll(0,"maximo");
      //ObjectsDeleteAll(0,"minimo");
   }
   double lvpips =  50;
   double lvmenospips = 10;

   if (calc_mode == SYMBOL_CALC_MODE_CFD || calc_mode == SYMBOL_CALC_MODE_CFDLEVERAGE) 
   {
      lvpips = lvpips * _Point * 100 ;
      lvmenospips = lvmenospips * _Point * 100;
      if(_Symbol == "BTCUSD")
      {
         lvpips = lvpips * _Point  * 1000;
         lvmenospips = lvmenospips * _Point * 1000 ;
      }
      
   }


   if (calc_mode == SYMBOL_CALC_MODE_FOREX) 
   {
      //lvpips = lvpips * _Point ;
      //lvmenospips = lvmenospips * _Point;
      
      //if (_Symbol == "XAUUSD" || _Symbol == "USDJPY")
      //{
         lvpips = lvpips * _Point  ;
         lvmenospips = lvmenospips * _Point ;
      //}
   }   
   
      double vlalto = Bid + lvpips;
      double vlbajo = Bid + lvpips - lvmenospips ;

      double normalizedEntryPrice =  (Bid / tick_size);

      if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
      { 
            // Calcular el stop loss y take profit en la escala normalizada
            double alto = normalizedEntryPrice + lvpips; // lvpips ticks por debajo
            double bajo = normalizedEntryPrice + lvpips - lvmenospips; // 100 ticks por arriba
            
            vlalto = alto * tick_size;
            vlbajo = bajo * tick_size ;
      }      
      
      string obj_name_maximo="maximo_M15";
      
      // Obtener el tiempo de la primera y última vela visible en el gráfico
      //datetime tiempoInicio = iTime(_Symbol, _Period, 30);
      //datetime tiempoFin = iTime(_Symbol, _Period, -30);
      

      ObjectExiste = ObjectFind(0,obj_name_maximo);      
      if (ObjectExiste < 0)
      {    
         ObjectCreate(current_chart_id,obj_name_maximo,OBJ_RECTANGLE,0, 0, vlalto, 0, vlbajo);
         ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_COLOR,C'89,9,24');
         ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_SELECTABLE,true);
         //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_SELECTED,true); 
         ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_ZORDER,29999); 
      }
      
   
      vlbajo = Bid - lvpips;
      vlalto = Bid - lvpips + lvmenospips  ;

      if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
      { 
            // Calcular el stop loss y take profit en la escala normalizada
            double alto = normalizedEntryPrice - lvpips; // lvpips ticks por debajo
            double bajo = normalizedEntryPrice - lvpips + lvmenospips; //  ticks por arriba
             
             vlalto = alto * tick_size;
             vlbajo = bajo * tick_size ;
      }      



      string obj_name_minimo="minimo_M15";

      ObjectExiste = ObjectFind(0,obj_name_minimo);      
      if (ObjectExiste < 0)
      {    
         ObjectCreate(current_chart_id,obj_name_minimo,OBJ_RECTANGLE,0,0 , vlalto, 0, vlbajo);
         
         ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_COLOR,clrAqua); 
         ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_COLOR,C'0,105,108');
         ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_SELECTABLE,true);
         //ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_SELECTED,true);     
         ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_ZORDER,29000); 
      }
}

void AlarmaaltovelaZB()
{
  datetime hora = TimeCurrent();
  double lotezb = 1;
  double lvalto = iHigh(_Symbol,PERIOD_M1,1);
  double lvbajo = iLow(_Symbol,PERIOD_M1,1);
  double lvpuntosvelaanterior = MathAbs(lvalto  - lvbajo ) / Puntos;
  double lvpuntos = StringToDouble(puntosFvg.Text());
  string lvmensaje = _Symbol + " - " + NormalizeDouble(lvpuntosvelaanterior,2) + " Hora " + hora;
  if(iClose(_Symbol,PERIOD_M1,0) > iOpen(_Symbol,PERIOD_M1,0))
  {
      lvmensaje = lvmensaje + " alcista";
  }
  else
  {
      lvmensaje = lvmensaje + " bajista";
  }

}

void AlarmavelaZB()
{
  datetime hora = TimeCurrent();
  double lvalto = iOpen(_Symbol,PERIOD_M1,1);
  double lvbajo = iClose(_Symbol,PERIOD_M1,1);
  double lvpuntosvelaanterior = MathAbs(lvalto  - lvbajo ) / Puntos;
  double lvpuntosvela = 10000;
  string lvsymbol = "";
  VGvelasamurai = false;
  
  lvpuntosvela = StringToDouble(puntosFvg.Text());
  
  //Print("velas samurai : "," lvpuntosvelaanterior : ",lvpuntosvelaanterior, " lvpuntosvela : ",lvpuntosvela);
  
  if (lvpuntosvelaanterior > lvpuntosvela)// && ContadorvelaZB == 0)
  {
      if( lvpuntosvelaanterior < (lvpuntosvela * 2))
      { 
         VGvelasamurai = true;
         Print("VGvelasamurai: ",VGvelasamurai, " lvpuntosvelaanterior :", lvpuntosvelaanterior);
      } 
      // Identificador único del objeto
      string arrow_name = "ZB_ArrowCurrentCandle-"+TimeCurrent();
      
      
      // Obtener el tiempo de la vela actual
      datetime time = iTime(_Symbol,PERIOD_M1,1);
      double price = iHigh(_Symbol,PERIOD_M1,1);

   // Eliminar el objeto si ya existe
      if (ObjectFind(0, arrow_name) != -1)
         ObjectDelete(0, arrow_name);

      if (!ObjectCreate(0, arrow_name, OBJ_ARROW, 0, time, price))
      {
         Print("Error al crear el objeto de flecha: ", GetLastError());
         return;
      }
  
         //ObjectSetDouble(0, arrow_name, OBJPROP_ANGLE,90);               
         //ObjectSetInteger(0, arrow_name, OBJPROP_FONTSIZE,7); 
         ObjectSetInteger(0, arrow_name, OBJPROP_TIMEFRAMES,OBJ_PERIOD_M1);                  
         ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrWhite);                   
         ObjectSetInteger(0, arrow_name, OBJPROP_SELECTABLE, false);                   
         ObjectSetInteger(0, arrow_name, OBJPROP_SELECTED, false);
         //ObjectSetString(0, arrow_name, OBJPROP_TEXT, DoubleToString(lvpuntosvelaanterior,0)); 
         ObjectSetInteger(0, arrow_name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);  
         ObjectSetString(0,arrow_name, OBJPROP_TOOLTIP, "Puntos:" +DoubleToString(lvpuntosvelaanterior,2) + " inpumbral: " +  inpumbral);           
                          


      //Print("lvpuntosvelaanterior :",lvpuntosvelaanterior);
      string lvmensaje = "";
      if(iOpen(_Symbol,PERIOD_M1,1) < iClose(_Symbol,PERIOD_M1,1))
      {
         lvmensaje = _Symbol + " Alcista : "  + hora +  " Puntos : " + DoubleToString(lvpuntosvelaanterior,2) + " inpumbral: " +  inpumbral ;
         price = iHigh(_Symbol,PERIOD_M1,1);
         ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE,241);
         ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrGreenYellow);                   
      }
      else
      {
          lvmensaje = _Symbol +  " Bajista : " +  hora +  " Puntos : " + DoubleToString(lvpuntosvelaanterior,2) + " inpumbral: " +  inpumbral ;
          price = iLow(_Symbol,PERIOD_M1,1);
          ObjectSetDouble(0, arrow_name, OBJPROP_PRICE, price);
          ObjectSetInteger(0, arrow_name, OBJPROP_ARROWCODE,242);
          ObjectSetInteger(0, arrow_name, OBJPROP_COLOR, clrRed);                   
          ObjectSetInteger(0, arrow_name, OBJPROP_ANCHOR, ANCHOR_TOP);             
      }      

      //SendNotification(lvmensaje);
      Alert(lvmensaje);
      ContadorvelaZB++;

  }

}

void AlarmaFVG()
{

   
}


void Promedioaltovelas()
{
   int numVelas = 14;      // Número de velas a analizar
   double totalAltura = 0; // Acumulador de alturas
   for (int i = 1; i <= numVelas; i++) // Recorre las últimas 20 velasarrow
   {
      double high = iHigh(_Symbol, PERIOD_M1, i); // Alto de la vela
      double low  = iLow(_Symbol, PERIOD_M1, i);  // Bajo de la vela
      double altura = (high - low) / Puntos;            // Altura en puntos
      totalAltura += altura;
   }


   int promedio = totalAltura / numVelas; // Calcula el promedio
   
   //Print("Promedio de altura de las últimas ", numVelas, " velas: ", promedio, " puntos");

   //double lvumbral = 2.5;
   //if (_Symbol == "BTCUSD")
   //{
   //      lvumbral = 3;
   //      //lvumbral = 1;
   //}
 
   promedio =  promedio * VGumbral;
   puntosFvg.Text(promedio);

   //Print("nuevo Promedio de altura de las últimas ", numVelas, " velas: ", promedio, " puntos");

}


//+------------------------------------------------------------------+
//| Crear la línea de tendencia del promedio                         |
//+------------------------------------------------------------------+
void CrearLineaPromedio()
{

    if(!ObjectCreate(0, NombreLineaPromedio, OBJ_TREND, 0, 0, 0))
    {
        Print("Error al crear la línea de tendencia: ", GetLastError());
        return;
    }
    ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_COLOR, ColorLineaPromedio);
    ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_WIDTH, GrosorLineaPromedio);
    ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_STYLE, EstiloLineaPromedio);
    ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_RAY, false); // Línea finita (no infinita)
    ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_SELECTABLE, false); 

}

//+------------------------------------------------------------------+
//| Actualizar la línea de tendencia del promedio                    |
//+------------------------------------------------------------------+
void ActualizarLineaPromedio()
{

   // Obtener el timeframe del gráfico
   int futureBars = 5;
   ENUM_TIMEFRAMES timeframe = (ENUM_TIMEFRAMES)ChartPeriod(0);
   int periodSeconds = PeriodSeconds(timeframe);
   // Obtener la última barra actual
   datetime lastBarTime = iTime(NULL, 0, 0); // Última barra (actual)
   // Calcular el tiempo futuro
   futureTime = lastBarTime + periodSeconds * futureBars;

    VGsumaTotal = 0.0;
    double VGprecioPromedio = CalcularPrecioPromedio();
    if(VGprecioPromedio >= 0)
    {

        // Obtener el tiempo de la primera y última vela visible en el gráfico
        datetime tiempoInicio = iTime(_Symbol, _Period, 30);
        //datetime tiempoFin = iTime(_Symbol, _Period, 30);

        // Mover los puntos de la línea de tendencia
        ObjectMove(0, NombreLineaPromedio, 0, tiempoInicio, VGprecioPromedio);
        ObjectMove(0, NombreLineaPromedio, 1, futureTime, VGprecioPromedio);

        // Actualizar la etiqueta de la línea
        ObjectSetString(0, NombreLineaPromedio, OBJPROP_TEXT, "BE: " + DoubleToString(VGprecioPromedio, _Digits));//+ " Ganancia: " + DoubleToString(VGsumaTotal, _Digits) );
        //ObjectSetInteger(0, NombreLineaPromedio, OBJPROP_ANCHOR, ANCHOR_CENTER);
        //ObjectSetDouble(0, NombreLineaPromedio, OBJPROP_ANGLE, 0);
    }

}

//+------------------------------------------------------------------+
//| Calcular el precio promedio de las órdenes abiertas              |
//+------------------------------------------------------------------+
double CalcularPrecioPromedio()
{
    double sumaPrecios = 0.0;
    double sumaLotes = 0.0;
    int totalOrdenes = 0;

    // Recorrer todas las órdenes abiertas
    for(int i = 0; i < PositionsTotal(); i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            // Verificar si la orden pertenece al símbolo y timeframe del gráfico actual
            if(PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                sumaPrecios += PositionGetDouble(POSITION_PRICE_OPEN) * PositionGetDouble(POSITION_VOLUME); ;
                sumaLotes   += PositionGetDouble(POSITION_VOLUME);
                //VGsumaTotal += PositionGetDouble(POSITION_PROFIT);
                totalOrdenes++;
            }
        }
    }

    if(totalOrdenes < 1)
    {
        return 0.0; // No hay órdenes abiertas en el gráfico actual
    }

    //return sumaPrecios / totalOrdenes;
    //Print("sumaLotes :",sumaLotes, " Promedio :",sumaPrecios / sumaLotes);
    return sumaPrecios / sumaLotes;
}



//+------------------------------------------------------------------+
//| Función para dibujar FVG                                         |
//+------------------------------------------------------------------+
void DrawFVG(ENUM_TIMEFRAMES timeframe, int candlesToCheck, color colorBullis, color colorBearish, int fvgwidh  )
{
  
   if (VGShowFvg == false)
       return;
       
   //int candlesToCheck = 1000; // Velas a analizar
   datetime currentTime = TimeCurrent();
   datetime endTime = iTime(NULL, PERIOD_M1, 1);
   int contadorFVGbullish = 0;
   int contadorFVGbearish = 0;

   string name ="";
   string name1 ="";
   string namece = "";
   double high0;
   double low0 ;
   double high2 ;
   double low2;

   //ChartRedraw();
   VGcontadorFVG   = 0;

   double lvpuntosfvg = StringToDouble(puntosFvg.Text());
   int lvcontadorfvg = 0;
   
   for(int i = candlesToCheck; i >= 1; i--) // Comenzar desde atrás
   {
      // Precios de las velas i (actual), i+1, i+2
      high0 = iHigh(NULL, timeframe, i);
      low0 = iLow(NULL, timeframe, i);
      high2 = iHigh(NULL, timeframe, i+2);
      low2 = iLow(NULL, timeframe, i+2);
      
      // Bullish FVG: Low de la vela i > High de la vela i+2
      if(low0 > high2 && IsFVGReplenished_Bullish(timeframe, i, low0, high2))
        {
        
            contadorFVGbullish++;
            if( fvgwidh == 5)//Para verificar si el precio esta actualmente en un FVG
            {
              //Print("german : contadorFVGbullish = ",contadorFVGbullish,  " low : ", low0, " high2 :",high2, " VGlowestLow : ",VGlowestLow);
                  //Print("VGvalor_fractal_alto :",VGvalor_fractal_alto, " VGvalor_fractal_bajo :",VGvalor_fractal_bajo ," low2 : ",low2, " high0 :",high0 );
              if(VGcontadorAlertasAlcista > 0 ) // && (timeframe == Time_Frame_M2022)
              {
                  VGcontadorFVG++;
                  //Print("VGvalor_fractal_alto_5 :",VGvalor_fractal_alto_5, " VGvalor_fractal_bajo_5 :",VGvalor_fractal_bajo_5 ," low2 : ",low2, " high0 :",high0 );
                  if (VGvalor_fractal_alto_5 > low0 && VGvalor_fractal_alto_5 < high2)
                  {
                     VGbag = true;
                     name1 =  TimeframeToString(timeframe);
                     string lvmensaje = "\"Breakaway Gap en " +  _Symbol + "  " + name1 + \"";
                     //textohablado(lvmensaje,true);
                     //VGcontadorAlertasAlcista = 3;
                  }   
                  //ObjectSetDouble(0,"Soporte",OBJPROP_PRICE,high2);
                  continue;
                  //Print("contador_fvg alcista : ",VGcontadorFVG);
              }
              
              double lvpuntos = MathAbs(high2  - low0 ) / Puntos;
              lvpuntosfvg = lvpuntosfvg * 1.5;
              if (lvpuntos  > lvpuntosfvg && lvpuntosfvg > 0  )
              {
                  //Print(" lvpuntos : ",lvpuntos , " lvpuntosfvg : ",lvpuntosfvg);
                  lvcontadorfvg++;
              }    
              if(lvcontadorfvg >= 1)
              {
                     name1 =  TimeframeToString(timeframe);
                     string lvmensaje = "\"Displacement leg " + contadorFVGbullish + " " + _Symbol + "  " + name1 + \"";
                     //textohablado(lvmensaje,true);
                     break;
              }
                continue;
            }

            if( fvgwidh == 9)//Para verificar si el precio esta actualmente en un FVG
            {
               double vlbajo = 0;
               int vlbag = 1;
               for ( int j = i ; j >= 1; j--)
               {

                  vlbajo = iLow(_Symbol, timeframe, j);
                  
                  // Verificar si es vela bajista
                  if(vlbajo < low0)
                  {
                        //Print(" IOFED ALCISTA : ",j);
                        vlbag = 0;
                        break;
                  }
               }
               
              if(vlbag ==  1 && i >= 3)// && VGTendencia_interna_H4 ==  "Alcista")
              {
                  //Print("BAG ALCISTA !!! : ", " i : ",i);
                  string lvmensaje = "\"BAG ALCISTA !!! : " + " " + _Symbol + "  " + name1 + \"";
                  //textohablado(lvmensaje,true);
                  VGcumplerregla = true;
                  break;
                  //Print("german : contadorFVGbullish = ",contadorFVGbullish,  " low : ", low0, " high2 :",high2, " vlbajo : ",vlbajo, " i : ",i);
              }            
            }
            name = "FVG_" + VGHTF_Name + "_Bullish_" + IntegerToString(contadorFVGbullish);
            namece = "FVG_" + VGHTF_Name + "_CE_Bullish_" + IntegerToString(contadorFVGbullish);
            datetime startTime = iTime(NULL, timeframe, i+2);
           if (fvgwidh > 0)
            {
              //if ( i < 3)
              //   fvgwidh = 0;
              endTime = iTime(NULL, timeframe, i - fvgwidh);
              name1 =  TimeframeToString(timeframe);
              name = "FVG_" + name1 + "_Bullish_" + IntegerToString(contadorFVGbullish);
              namece = "FVG_"+ name1 + "_CE_Bullish_" + IntegerToString(contadorFVGbullish);
            }  
            //datetime endTime = iTime(NULL, timeframe, 0);

            if(fvgwidh == 9)
               continue;

            CreateFVGRectangle(name, startTime, high2, endTime, low0, colorBullis, fvgwidh, 0);
            double ce = (high2 - low0) /2;
            ce = high2 - ce;
            if (timeframe == _Period)
            {
               CreateFVGLine_CE(namece, startTime, ce , endTime,  Color_Bullish_Current_CE, fvgwidh);
            }
            else
            {
               CreateFVGLine_CE(namece, startTime, ce , endTime,  Color_Bullish_HTF_CE, fvgwidh);
            }   
            //Sleep(1000);
        }
        

      // Bearish FVG: High de la vela i < Low de la vela i+2
      if(high0 < low2 && IsFVGReplenished_Bearish(timeframe, i,low2, high0))
        {

            contadorFVGbearish++;

            if( fvgwidh == 5)//Para verificar si el precio esta actualmente en un FVG
            {
              if(VGcontadorAlertasBajista > 0)// && timeframe == Time_Frame_M2022)
              {
                  //ObjectSetDouble(0,"Resistencia",OBJPROP_PRICE,low2);
                  VGcontadorFVG++;
                  //Print("VGvalor_fractal_alto :",VGvalor_fractal_alto, " VGvalor_fractal_bajo :",VGvalor_fractal_bajo ," low2 : ",low2, " high0 :",high0 );
                  if (VGvalor_fractal_bajo_5 < low2  && VGvalor_fractal_bajo_5 > high0)
                  {
                     VGbag = true;
                     name1 =  TimeframeToString(timeframe);
                     string lvmensaje = "\"Breakaway Gap en " +  _Symbol + "  " + name1 + \"";
                     //textohablado(lvmensaje,true);
                     //VGcontadorAlertasBajista = 3;

                  }
                  continue;
                  //Print("contador_fvg bajista : ",VGcontadorFVG);
              }

              double lvpuntos = MathAbs(low2  - high0 ) / Puntos;
              lvpuntosfvg = lvpuntosfvg * 1.5;
              if (lvpuntos  > lvpuntosfvg && lvpuntosfvg > 0 )
              {
                  //Print(" lvpuntos : ",lvpuntos , " lvpuntosfvg : ",lvpuntosfvg);
                  lvcontadorfvg++;
              }    
              if(lvcontadorfvg >= 1)
              {
                     name1 =  TimeframeToString(timeframe);
                     string lvmensaje = "\"Displacement leg " + contadorFVGbearish + " " + _Symbol + "  " + name1 + \"";
                     //textohablado(lvmensaje,true);
                     break;
              }
                continue;
            }
            
            if( fvgwidh == 9)//Para verificar si el precio esta actualmente en un FVG
            {
            
               double vlalto = 0;
               int vlbag = 1;
               for ( int j = i ; j >= 1; j--)
               {

                  vlalto = iHigh(_Symbol, timeframe, j);
                  
                  // Verificar si es vela bajista
                  if(vlalto > high0)
                  {
                        //Print(" IOFED BAJISTA : ",j);
                        vlbag = 0;
                        break;
                  }
               }
               
              if(vlbag ==  1 && i >= 3)// && VGTendencia_interna_H4 ==  "Alcista")
              {
                     //Print("BAG BAJISTA !!! : ", " i : ",i);
                  string lvmensaje = "\"BAG BAJISTA !!! : " + " " + _Symbol + "  " + name1 + \"";
                  //textohablado(lvmensaje,true);
                  VGcumplerregla = true;
                  break;
                  //Print("german : contadorFVGbullish = ",contadorFVGbullish,  " low : ", low0, " high2 :",high2, " vlbajo : ",vlbajo, " i : ",i);
              }            
            
            }
                        

         name = "FVG_" + VGHTF_Name + "_Bearish_" + IntegerToString(contadorFVGbearish);
         namece = "FVG_" + VGHTF_Name + "_CE_Bearish_" + IntegerToString(contadorFVGbearish);
         datetime startTime = iTime(NULL, timeframe, i+2);
         if (fvgwidh > 0)
         {
           //if ( i < 3)
           //   fvgwidh = 0;
            endTime = iTime(NULL, timeframe, i - fvgwidh);
            name1 =  TimeframeToString(timeframe);
            name = "FVG_" + name1 + "_Bearish_" + IntegerToString(contadorFVGbearish);
            namece = "FVG_" + name1 + "_CE_Bearish_" + IntegerToString(contadorFVGbearish);
         }   
         //datetime endTime = iTime(NULL, timeframe, 0);

         if(fvgwidh == 9)
            continue;

         CreateFVGRectangle(name, startTime, low2, endTime, high0, colorBearish, fvgwidh, 0);
         double ce = (high0 - low2) /2;
         ce = high0 - ce;
         if (timeframe == _Period)
         {
            CreateFVGLine_CE(namece, startTime, ce , endTime,  Color_Bearist_Current_CE, fvgwidh );
         }
         else
         {
            CreateFVGLine_CE(namece, startTime, ce , endTime,  Color_Bearist_HTF_CE, fvgwidh );
         }   
         //Sleep(500);
        }
   }
   
//Para analizar si se compra o se vende
   

   
   if (timeframe == PERIOD_M15 || timeframe == PERIOD_H1 || timeframe == PERIOD_H4)
   {


      name = "FVG_" + VGHTF_Name + "_Bearish_" + IntegerToString(contadorFVGbearish);
      double lvalto =  ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      double lvbajo =  ObjectGetDouble(0,name,OBJPROP_PRICE,0);


      //Print( "timeframe:",timeframe," PERIOD_H4 :",PERIOD_H4, " contadorFVGbearish: ",contadorFVGbearish, " contadorFVGbullish : ",contadorFVGbullish, " name : ",name);

      
      if ( lvalto < lvbajo)
      {
          lvalto =  ObjectGetDouble(0,name,OBJPROP_PRICE,0);
          lvbajo =  ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      }
      
      
      if (Bid <= lvalto && Bid >= lvbajo)
      {
         VGzona_venta = true;
         //Print(_Symbol," ZONA DE VENTAS lvalto : ", lvalto, " lvbajo : ",lvbajo, " VGzona_venta : " ,VGzona_venta, " timeframe :",timeframe , " Bid :",Bid);
      }

      name = "FVG_" + VGHTF_Name + "_Bullish_" + IntegerToString(contadorFVGbullish);
      lvalto =  ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      lvbajo =  ObjectGetDouble(0,name,OBJPROP_PRICE,0);
      
      if ( lvalto < lvbajo)
      {
          lvalto =  ObjectGetDouble(0,name,OBJPROP_PRICE,0);
          lvbajo =  ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      }
      
      
      if (Bid <= lvalto && Bid >= lvbajo)
      {
         VGzona_compra = true;
         //Print(_Symbol," ZONA DE COMPRAS lvalto : ", lvalto, " lvbajo : ",lvbajo, " VGzona_compra : " ,VGzona_compra, " timeframe :",timeframe , " Bid :",Bid);
      }


   }



   if (timeframe == PERIOD_M1 )// && (VGzona_venta == true || VGzona_compra == true) )
   {
      double lvalto =  ObjectGetDouble(0,name,OBJPROP_PRICE,1);
      double lvbajo =  ObjectGetDouble(0,name,OBJPROP_PRICE,0);
      
      double lvpips = CalculateMovementAndProfit(lvalto,lvbajo,0);
      double lvpromediopuntosvela = StringToDouble(puntosFvg.Text());
      
      if (lvpips < 0)
         lvpips = lvpips * -1;
         //Print(" name :",name , " namece :", namece, " lvpips : ", lvpips, " lvpromediopuntosvela : ",lvpromediopuntosvela );
      if ( lvpips > lvpromediopuntosvela &&  lvpromediopuntosvela > 0)
      {
           //Print(" name :",name , " namece :", namece, " lvpips : ", DoubleToString(lvpips,0), " lvpromediopuntosvela : ",lvpromediopuntosvela );
           //TextToSpeech("\"Comprar o vender " + _Symbol +\"");
           //Print ("comprar o vender.... "+_Symbol); 
      }
   } 
     
}

//+------------------------------------------------------------------+
//| Verifica si el FVG ha sido rellenado                             |
//+------------------------------------------------------------------+
bool IsFVGReplenished_Bullish(ENUM_TIMEFRAMES timeframe, int startIndex, double top, double bottom)
  {
   for(int j = startIndex ; j >= 1; j--)
     {
      double candleClose = iClose(NULL, timeframe, j);
      if(candleClose < bottom)
        {
          //Print( " candleClose:",candleClose, " bottom:",bottom, " Top: ", top, " Index: ",j);
         return false;
        }
     }
   return true;
  }


bool IsFVGReplenished_Bearish(ENUM_TIMEFRAMES timeframe, int startIndex, double top, double bottom)
  {
   for(int j = startIndex ; j >=1; j--)
     {
      double candleClose = iClose(NULL, timeframe, j);
      if(candleClose > top)
        {
         return false;
        }
     }
   return true;
  }
 
//+------------------------------------------------------------------+
//| Crea un rectángulo para el FVG                                   |
//+------------------------------------------------------------------+
void CreateFVGRectangle(string name, datetime startTime, double startPrice, 
                        datetime endTime, double endPrice, color clr, int fvgwidt, int type)
  {
   int periodSeconds = PeriodSeconds(PERIOD_M1) * 2;
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, startTime, startPrice, endTime + periodSeconds, endPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   //ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   
   periodSeconds = PeriodSeconds(PERIOD_CURRENT) ;
   if (type == 1)//para NWOG
   {
      ObjectSetInteger(0, name, OBJPROP_TIME,0,iTime(_Symbol,PERIOD_CURRENT,0) + 10 * periodSeconds);
      ObjectSetInteger(0, name, OBJPROP_TIME,1,iTime(_Symbol,PERIOD_CURRENT,0) + 20 * periodSeconds);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_FILL, false);
      ObjectSetInteger(0, name, OBJPROP_STYLE,STYLE_DOT);
      ObjectSetString(0, name, OBJPROP_TEXT, "NWOG");
   }
   if (type == 2)//para NDOG
   {
      ObjectSetInteger(0, name, OBJPROP_TIME,0,iTime(_Symbol,PERIOD_CURRENT,0) + 10 * periodSeconds);
      ObjectSetInteger(0, name, OBJPROP_TIME,1,iTime(_Symbol,PERIOD_CURRENT,0) + 20 * periodSeconds);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_FILL, false);
      ObjectSetInteger(0, name, OBJPROP_STYLE,STYLE_DOT);      
      ObjectSetString(0, name, OBJPROP_TEXT, "NDOG");
   }
   //ObjectSetInteger(0, "name", OBJPROP_BORDER_TYPE, BORDER_FLAT); // Sin bordes latera
  }
  
//+------------------------------------------------------------------+
//| Crea la linea para CE en el  FVG, NWOG, NDOG, ORG                |
//+------------------------------------------------------------------+
void CreateFVGLine_CE(string name, datetime startTime, double startPrice, 
                        datetime endTime, color clr, int fvgwidt)
  {
      int periodSeconds = PeriodSeconds(PERIOD_M1) * 2;
      ObjectCreate(0, name, OBJ_TREND,0, startTime, startPrice);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      //ObjectSetInteger(0, name, OBJPROP_BACK, true);
      //ObjectSetInteger(0, name, OBJPROP_FILL, true);
      
      // Mover los puntos de la línea de tendencia
      ObjectMove(0, name, 0, startTime, startPrice);
      ObjectMove(0, name, 1, endTime + periodSeconds, startPrice);   
   if (fvgwidt > 0)
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
  }  
  
  
double CalculateMovementAndProfit(double entry_price, double exit_price, double lot_size)
{
    // Obtener información del símbolo
    double tick_size   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tick_value  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double point_size  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    int    digits      = SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

    ENUM_SYMBOL_CALC_MODE calc_mode = (ENUM_SYMBOL_CALC_MODE) SymbolInfoInteger(_Symbol, SYMBOL_TRADE_CALC_MODE);

    double movement_points = 0;
    double profit = 0;
    double pointValue = 0;
    
   // --- Lógica de conversión de puntos a pips basada en el modo de cálculo ---
   movement_points = (entry_price - exit_price) / point_size ;
   profit = movement_points * tick_value * lot_size ;
   switch ((ENUM_SYMBOL_CALC_MODE)calc_mode)
   {
      case SYMBOL_CALC_MODE_FOREX:
        //movement_points = (entry_price - exit_price) / point_size ;;

         if (digits == 5 || digits == 3) // EURUSD (5), USDJPY (3)
         {
             // Para símbolos con 5 o 3 dígitos, 1 pip = 10 puntos.
             // Ej: EURUSD: 0.00001 (punto), 0.00010 (pip).
             // Ej: USDJPY: 0.001 (punto), 0.010 (pip).
             if (StringFind(_Symbol,"XAU") >= 0 )
             {
                  VGcomodin = 100;
             }  
             else
             {     
                  VGcomodin = 10;
             }  
         }
         else if (digits == 4 || digits == 2) // GBPUSD (4 en algunos brókers), XAUUSD (2 en algunos brókers)
         {
             // Para símbolos con 4 o 2 dígitos, 1 pip = 1 punto.
             // Ej: GBPUSD: 0.0001 (punto), 0.0001 (pip).
             // Ej: XAUUSD: 0.01 (punto), 0.01 (pip).
             //movement_points = movement_points / 100.0;
         }
         else
         {
             // Para otros casos, asumimos 1 pip = 10 puntos como medida de seguridad,
             // o puedes decidir devolver `diff_in_points` si el bróker usa punto=pip.
             // Lo más seguro es que para la mayoría de los pares de divisas comunes,
             // la relación sea 10 puntos = 1 pip.
             //Print("Advertencia: Número de dígitos inusual (", digits, ") para ", current_symbol, ". Asumiendo 1 pip = 10 puntos.");
              movement_points = movement_points / 10.0;
         }        

        //movement_points = ((entry_price - exit_price) / point_size) * VGcomodin;
        break;
        //profit = movement_points * tick_value * lot_size * 10;
        //Print("Activo: FOREX - Movimiento: ", movement_points, " pips - Ganancia/Pérdida: ", profit, " USD");
      
      

      // Para CFDs, Metales (como XAUUSD), Índices, Futuros, Acciones, etc.
      // Generalmente, 1 punto (tick size) se considera 1 pip para los cálculos de movimiento.
      case SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE:
          if (StringFind(_Symbol,"BTC") >= 0 )
          {
               VGcomodin = 10000;
          }  
          else
          {     
               VGcomodin = 1000;
          }  
        break;

      case SYMBOL_CALC_MODE_CFD:
        VGcomodin = 100;
        break;
      case SYMBOL_CALC_MODE_CFDINDEX:
      case SYMBOL_CALC_MODE_CFDLEVERAGE:

         VGcomodin = 1;
 
         if(contractSize == 1000) // Lote estándar
            pointValue =  10;
         if(contractSize == 100) // Lote estándar
            pointValue =  1;
         if(contractSize == 10) // Mini lote
            pointValue = 0.1;
         if(contractSize == 1) // Micro lote
            pointValue = 0.01;     

   
         profit = movement_points * pointValue * lot_size ;
   
         break;

        
      case SYMBOL_CALC_MODE_FUTURES:
      case SYMBOL_CALC_MODE_EXCH_STOCKS:
      case SYMBOL_CALC_MODE_EXCH_STOCKS_MOEX:
      case SYMBOL_CALC_MODE_EXCH_FUTURES:
        VGcomodin = 100;
        break;
      case SYMBOL_CALC_MODE_EXCH_FUTURES_FORTS:
      case SYMBOL_CALC_MODE_EXCH_BONDS:

      default:
         Print("Modo de cálculo no soportado para este activo.");
         break;
   }

    if ( lot_size > 0)
    {
       return profit;
    }  
    else    
    {
       return movement_points / VGcomodin;
    }      
   
  

//    // Determinar el tipo de activo
//    if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES)
//    {
//        // Futuros con cálculo de bolsa (EXCH_FUTURES)
//        movement_points = (entry_price - exit_price) / tick_size;
//        profit = movement_points * tick_value * lot_size;
//        //Print("Activo: FUTURO (EXCH_FUTURES) - Movimiento: ", movement_points, " ticks - Ganancia/Pérdida: ", profit, " USD");
//    }
//    else if (calc_mode == SYMBOL_CALC_MODE_FOREX )
//    {
//        // Forex
//        //movement_points = (exit_price - entry_price) / point_size / 10; //Antes
//
//        movement_points = (entry_price - exit_price) / point_size ;;
//
//         if (digits == 5 || digits == 3) // EURUSD (5), USDJPY (3)
//         {
//             // Para símbolos con 5 o 3 dígitos, 1 pip = 10 puntos.
//             // Ej: EURUSD: 0.00001 (punto), 0.00010 (pip).
//             // Ej: USDJPY: 0.001 (punto), 0.010 (pip).
//             if (StringFind(_Symbol,"XAU") >= 0)
//             {
//                  movement_points = movement_points / 1000.0;
//                  profit = movement_points * tick_value * lot_size * 1000;
//                  VGcomodin = 1000;
//             }  
//             else
//             {     
//                  movement_points = movement_points / 10.0;
//                  VGcomodin = 10;
//             }  
//         }
//         else if (digits == 4 || digits == 2) // GBPUSD (4 en algunos brókers), XAUUSD (2 en algunos brókers)
//         {
//             // Para símbolos con 4 o 2 dígitos, 1 pip = 1 punto.
//             // Ej: GBPUSD: 0.0001 (punto), 0.0001 (pip).
//             // Ej: XAUUSD: 0.01 (punto), 0.01 (pip).
//             //movement_points = movement_points / 100.0;
//         }
//         else
//         {
//             // Para otros casos, asumimos 1 pip = 10 puntos como medida de seguridad,
//             // o puedes decidir devolver `diff_in_points` si el bróker usa punto=pip.
//             // Lo más seguro es que para la mayoría de los pares de divisas comunes,
//             // la relación sea 10 puntos = 1 pip.
//             //Print("Advertencia: Número de dígitos inusual (", digits, ") para ", current_symbol, ". Asumiendo 1 pip = 10 puntos.");
//              movement_points = movement_points / 10.0;
//         }        
//
//        movement_points = ((entry_price - exit_price) / point_size / 10) * VGcomodin;
//        //profit = movement_points * tick_value * lot_size * 10;
//        //Print("Activo: FOREX - Movimiento: ", movement_points, " pips - Ganancia/Pérdida: ", profit, " USD");
//    }
//    else if (calc_mode == SYMBOL_CALC_MODE_CFD || calc_mode == SYMBOL_CALC_MODE_CFDLEVERAGE )
//    {
//        // CFDs
//        movement_points = ((entry_price - exit_price) / point_size) / 100 ;
//        profit = (movement_points * tick_value * lot_size) * 100 ;
//        //Print("Activo: CFD - Movimiento: ", movement_points, " puntos - Ganancia/Pérdida: ", profit, " USD");
//    }
//    else if (calc_mode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE)
//    {
//        // Forex no leverage
//        //movement_points = (exit_price - entry_price) / point_size / 10; //Antes
//        //movement_points = ((entry_price - exit_price) / point_size / 10) * 10;
//        //profit = movement_points * tick_value * lot_size;
//        //Print("Activo: FOREX - Movimiento: ", movement_points, " pips - Ganancia/Pérdida: ", profit, " USD");
//    }
//    else
//    {
//        Print("Modo de cálculo no soportado para este activo.");
//    }
//    
//    if ( lot_size > 0)
//    {
//       return profit;
//    }  
//    else    
//    {
//       return movement_points;
//    }      
//    //Print(" tick_size: ",tick_size, " tick_value: ",tick_value," point_size: ",point_size, " digits: ",digits);
}
 

void DrawText(string textName, double price1, string text, datetime time1, int lvtype) // lvtype = 1 Ventas diferente Compras
{
   // Obtener información del activo
   double tickSize = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double pointSize = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   if (tickSize <= 0) tickSize = pointSize; // Si no hay TickSize, usar PointSize


   // Calcular posición del texto
   double priceText = price1;
   
   double lvpips = 1; // Puntos de distancias del texto de la linea 
   
   time1 = iTime(_Symbol,PERIOD_M1,0);
   
   if (calc_mode == SYMBOL_CALC_MODE_CFD) 
   {
      if (lvtype == 1)// 1 = Ventas
      {      
            priceText = price1 +  (lvpips * _Point * 100) ;
      }   
      else //Compras
      { 
            priceText = price1 -  (lvpips * _Point * 100) ;
      }   
      if(_Symbol == "BTCUSD")
      {
         if (lvtype == 1) // 1 = Ventas
         {      
            priceText = price1 +  (lvpips * _Point * 1000) ;
         }   
         else //Compras
         { 
            priceText = price1 -  (lvpips * _Point * 1000) ; 
         }   
      }
      
   }


   if (calc_mode == SYMBOL_CALC_MODE_FOREX) 
   {
      if (lvtype == 1)// 1 = Ventas
      {      
            priceText = price1 +  (lvpips * _Point * 10) ;
         }   
      else
         { 
            priceText = price1 -  (lvpips * _Point * 10) ;
      }   
   }   
   


   if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) 
   { 
      if (lvtype == 1)// 1 = Ventas
      {      
            priceText = price1 + (lvpips * tick_size) ;
         }   
      else
         { 
            priceText = price1 - (lvpips * tick_size) ;
      }   
   }      
   

   //// Mostrar datos en consola para depuración
   //Print("Symbol: ", Symbol(), 
   //      " | TickSize: ", tickSize, 
   //      " | PointSize: ", pointSize, 
   //      " | Precio texto: ", priceText);

   // Crear el texto encima de la línea
   //string textName = name + "_text";
   if(!ObjectCreate(0, textName, OBJ_TEXT, 0, time1, priceText))
   {
      Print("Error al crear texto: ", GetLastError());
      return;
   }
   //ObjectSetInteger(0, textName, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 8);
}


void DrawPDHPDL_PWHPWL()
{
   // Obtener los valores del día anterior
   double pdh = iHigh(_Symbol, PERIOD_D1, 1);
   double pdl = iLow(_Symbol, PERIOD_D1, 1);
   datetime prevDayStart = iTime(_Symbol, PERIOD_D1, 1);
   
   // Obtener los valores de la semana anterior
   double pwh = iHigh(_Symbol, PERIOD_W1, 1);
   double pwl = iLow(_Symbol, PERIOD_W1, 1);
   datetime prevWeekStart = iTime(_Symbol, PERIOD_W1, 1);
   
   // Obtener los valores del mes anterior
   double pmh = iHigh(_Symbol, PERIOD_MN1, 1);
   double pml = iLow(_Symbol, PERIOD_MN1, 1);
   datetime prevMonthStart = iTime(_Symbol, PERIOD_W1, 1);
   
   // Dibujar líneas de tendencia
   DrawTrendLine("PDH", pdh, clrMagenta, prevDayStart);
   DrawTrendLine("PDL", pdl, clrMagenta, prevDayStart);
   DrawTrendLine("PWH", pwh, clrMagenta, prevWeekStart);
   DrawTrendLine("PWL", pwl, clrMagenta, prevWeekStart);
   DrawTrendLine("PMH", pmh, clrMagenta, prevMonthStart);
   DrawTrendLine("PML", pml, clrMagenta, prevMonthStart);
}

void DrawTrendLine(string name, double price, color lineColor, datetime startTime)
{

      // Obtener el timeframe del gráfico
      int futureBars = 5;
      ENUM_TIMEFRAMES timeframe = (ENUM_TIMEFRAMES)ChartPeriod(0);
      int periodSeconds = PeriodSeconds(timeframe);
      // Obtener la última barra actual
      datetime lastBarTime = iTime(NULL, 0, 0); // Última barra (actual)
      // Calcular el tiempo futuro
      futureTime = lastBarTime + periodSeconds * futureBars;
      futureTime_previus = lastBarTime + periodSeconds * (futureBars + 5);


   if(ObjectFind(0,name) != 0)
   {
      string name1 = "Previus_" + name;
      ObjectCreate(0, name1, OBJ_TREND, 0, startTime, price, futureTime, price);
      ObjectSetInteger(0, name1, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, name1, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name1, OBJPROP_STYLE, STYLE_SOLID);
      
      string label = name1;
      string labelName = name1 + "_LABEL";

      
      ObjectCreate(0, labelName, OBJ_TEXT, 0, futureTime_previus, price);
      ObjectSetString(0, labelName, OBJPROP_TEXT, name);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   }
   else
   {
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }
}


void GetOpenPositionsProfitAndPercentage()
{
   double totalProfit = 0; 
   double totalLots = 0;
   double profitPercent = 0;
   string symbol = Symbol();  // Obtiene el símbolo del gráfico actual
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);  // Balance de la cuenta

   for (int i = 0; i < PositionsTotal(); i++)
   {
      if (PositionGetSymbol(i) == symbol)  // Filtra posiciones del símbolo actual
      {
         double profit = PositionGetDouble(POSITION_PROFIT);
         totalProfit += profit;
         double lot = PositionGetDouble(POSITION_VOLUME);
         totalLots += lot;
      }
   }

   // Cálculo del porcentaje de ganancia/pérdida
   if (balance > 0)
      profitPercent = (totalProfit / balance) * 100;
   else
      profitPercent = 0;
   if (totalProfit > 0)
   {
      profitDineroBtn.Color(clrWhite);
      profitDineroBtn.ColorBackground(clrBlue);
   }
   else
   {
      profitDineroBtn.Color(clrWhite);
      profitDineroBtn.ColorBackground(clrRed);
   }
   profitDineroBtn.Text(DoubleToString(totalProfit,2));
   porcentajeProfit.Text(DoubleToString(profitPercent,2)); 
   ratioBtn.Text(DoubleToString(totalLots,2)); 

   //Cerrar todas las posiciones si la perdida es mayor al 2%
   if (profitPercent < -100)
      CloseAllPositions();
      
   if (profitPercent >= 5 || profitPercent <= -5)
   {
      //MoveToBreakEven();
   }
      
   //Move To BreakEven todas las posiciones si la perdida es mayor al 1% o la utilidad en mayor al 2%
   //if (profitPercent < -1 ) //|| profitPercent >2 )
      //MoveToBreakEven();

}

void CloseAllPositions()
{
   string symbol = Symbol();  // Obtiene el símbolo del gráfico actual
   MqlTradeRequest request;
   MqlTradeResult result;
   
   for (int i = PositionsTotal() - 1; i >= 0; i--)  // Recorrer en orden inverso
   {
      if (PositionGetSymbol(i) == symbol)  // Filtra posiciones del símbolo actual
      {
         ulong ticket = PositionGetInteger(POSITION_TICKET);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double price = SymbolInfoDouble(symbol, (type == POSITION_TYPE_BUY) ? SYMBOL_BID : SYMBOL_ASK);

         ZeroMemory(request);
         request.action = TRADE_ACTION_DEAL;
         request.position = ticket;
         request.symbol = symbol;
         request.volume = volume;
         request.price = price;
         request.magic = PositionGetInteger(POSITION_MAGIC);
         request.deviation = 50;  // Aumenta el margen para evitar rechazos
         request.type_filling = ORDER_FILLING_FOK;
         request.type = (type == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;

         // Cerrar posición rápidamente
         if (!OrderSend(request, result))
         {
            Print("❌ Error al cerrar la posición ", ticket, " - Código: ", result.retcode);
         }
         else
         {
            Print("✅ Posición cerrada: ", ticket);
         }
      }
   }
}


//void MoveToBreakEven(double pips_buffer = 1.0)
//{
//   string symbol = Symbol();  // Obtiene el símbolo del gráfico actual
//   for(int i = PositionsTotal() - 1; i >= 0; i--)
//   {
//      ulong ticket = PositionGetTicket(i);
//      if(PositionSelectByTicket(ticket))
//      {
//         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
//         double open_price = PositionGetDouble(POSITION_PRICE_OPEN);
//         double stop_loss = PositionGetDouble(POSITION_SL);
//         double profit = PositionGetDouble(POSITION_PROFIT);
//         double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
//         double buffer = pips_buffer * point * 10; // Convertimos pips a puntos
//
//         // Solo mover a BE si la posición está en ganancias
//         Print("profit :",profit, " symbol:",symbol);
//         if(PositionGetSymbol(i) == symbol)
//         {
//            if (profit > 0 )
//            { 
//               // Modificar la orden con el nuevo SL en BE
//               if(!MiTrade.PositionModify(ticket, VGprecioPromedio, PositionGetDouble(POSITION_TP)))
//               {
//                  Print("Error al modificar la posición ", ticket, ": ", GetLastError());
//               }
//            }
//            if (profit < 0 )
//            { 
//               // Modificar la orden con el nuevo SL en BE
//               if(!MiTrade.PositionModify(ticket, VGprecioPromedio, PositionGetDouble(POSITION_SL)))
//               {
//                  Print("Error al modificar la posición ", ticket, ": ", GetLastError());
//               }
//            }
//         }
//      }
//   }
//}


void MoveToBreakEven(double pips_buffer = 1.0)
{
   double total_lots = 0.0;
   double sum_price = 0.0;
   int positions_count = 0;
   double lot = 0;
   double open_price = 0;
   // Recorrer todas las posiciones abiertas en el mismo símbolo
   for(int i = 0; i < PositionsTotal(); i++)
   {
         if(PositionGetSymbol(i) == _Symbol) // Solo operar en el activo actual
         {
            lot = PositionGetDouble(POSITION_VOLUME);
            open_price = PositionGetDouble(POSITION_PRICE_OPEN);
            
            sum_price += open_price * lot;
            total_lots += lot;
            positions_count++;
         }
   }
   // Si hay posiciones abiertas, calcular el precio promedio de entrada
   if(positions_count > 0 && total_lots > 0)
   {
      double avg_price = sum_price / total_lots; // Precio promedio ponderado
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double buffer = pips_buffer * point * 10; // Convertir pips a puntos
      // Recorrer todas las posiciones y modificar SL/TP
      double VGprecioPromedio = CalcularPrecioPromedio();
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
            if(PositionGetSymbol(i) == _Symbol)
            {
               ulong ticket = PositionGetInteger(POSITION_TICKET);
               Print("ticket: ",ticket, " open_price: ",open_price, " lot :",lot);
               ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
               double stop_loss = 0.0;
               double take_profit = 0.0;


               if(type == POSITION_TYPE_BUY && VGprecioPromedio > Ask )
               {
                  //take_profit = avg_price - buffer; // SL debajo del promedio
                  take_profit = VGprecioPromedio ; // SL debajo del promedio
                  stop_loss = PositionGetDouble(POSITION_SL);
                  
                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) // Para futuros
                      take_profit = open_price; 

               }
               if(type == POSITION_TYPE_BUY && VGprecioPromedio < Bid )
               {
                  stop_loss = VGprecioPromedio ; // SL debajo del promedio
                  take_profit = PositionGetDouble(POSITION_TP); // Mantener TP actual

                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) // Para futuros
                      stop_loss = open_price; 

               }


               if(type == POSITION_TYPE_SELL && VGprecioPromedio < Bid )
               {
                  take_profit = VGprecioPromedio ; // SL encima del promedio
                  stop_loss = PositionGetDouble(POSITION_SL); // Mantener TP actual

                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) // Para futuros
                      take_profit = open_price; 
                  
               }

               if(type == POSITION_TYPE_SELL && VGprecioPromedio > Ask)
               {
                  stop_loss = VGprecioPromedio ; // SL encima del promedio
                  take_profit = PositionGetDouble(POSITION_TP); // Mantener TP actual

                  if (calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) // Para futuros
                      stop_loss = open_price; 

               }
               // Modificar la orden con el nuevo SL basado en el precio promedio
               double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
               stop_loss = NormalizeDouble(stop_loss / tickSize, 0) * tickSize;
               if(!MiTrade.PositionModify(ticket, stop_loss, take_profit))
               {
                  Print("Error al modificar la posición ", ticket, ": ", GetLastError());
               }
            }
      }
   }
}


string TimeframeToString(ENUM_TIMEFRAMES timeframe)
{
   //Print("_Period : ",_Period, "  timeframe: ",timeframe, " PERIOD_CURRENT: ", PERIOD_CURRENT );
   switch (timeframe)
   {
      case PERIOD_M1:   return "M1";
      case PERIOD_M2:   return "M2";
      case PERIOD_M3:   return "M3";
      case PERIOD_M4:   return "M4";
      case PERIOD_M5:   return "M5";
      case PERIOD_M6:   return "M6";
      case PERIOD_M10:  return "M10";
      case PERIOD_M12:  return "M12";
      case PERIOD_M15:  return "M15";
      case PERIOD_M20:  return "M20";
      case PERIOD_M30:  return "M30";
      case PERIOD_H1:   return "H1";
      case PERIOD_H2:   return "H2";
      case PERIOD_H3:   return "H3";
      case PERIOD_H4:   return "H4";
      case PERIOD_H6:   return "H6";
      case PERIOD_H8:   return "H8";
      case PERIOD_H12:  return "H12";
      case PERIOD_D1:   return "D1";
      case PERIOD_W1:   return "W1";
      case PERIOD_MN1:  return "MN1";
      default:          return "Desconocido";
   }
}


double CalculateLotSize(double entry_price, double stop_loss, double risk_percent )
{
   //Informacion de la cuenta
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
   
   //Informacion del simbolo
   
   double tick_value = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_SIZE);
   double contract_size = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_CONTRACT_SIZE); // Para futuros y CFDs
   double pointSize   = SymbolInfoDouble(Symbol(), SYMBOL_POINT);
   double pointValue   = tick_value * (Point() / tick_size);    
   double marginRequired = SymbolInfoDouble(Symbol(), SYMBOL_MARGIN_INITIAL);                      


    // Lotes mínimos y máximos
    double minLot = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    double maxLotAllowed = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    
//    // Calcular margen por lote
//    double marginPerLot = contract_size / leverage;    
//
   //Calcular el riesgo
   double risk_amount = account_balance * (risk_percent / 100.0);
//   
//
//    // Calcular lote basado en margen (apalancamiento 1:30)
//    double lotByMargin = freeMargin / marginRequired;
//    
//    
//    // 4. Lote máximo = Margen Libre / Margen por lote
//    double maxLot = freeMargin / marginPerLot;    
    
   //Print("lotByMargin : ",lotByMargin, " freeMargin :",freeMargin," marginRequired :",marginRequired, " leverage : ",leverage, " marginPerLot : ",marginPerLot, " maxLot : ",maxLot);

   if (tick_value == 0 || tick_size == 0 || contract_size == 0) return 0.0; // Evita errores

   double stop_loss_pips = MathAbs(entry_price - stop_loss) / tick_size; // SL en pips o puntos
   if (stop_loss_pips == 0) return 0.0; // Evita división por cero

   // Ajustar para diferentes mercados
   double lot_size;
   if (calc_mode == SYMBOL_CALC_MODE_CFD  || calc_mode == SYMBOL_CALC_MODE_EXCH_FUTURES) // Si es CFD o Futuro, se usa contract_size
   { 
      lot_size = risk_amount / (stop_loss_pips * tick_value * contract_size);
   }   
   //if ( calc_mode == SYMBOL_CALC_MODE_CFDLEVERAGE ) // Si es CFD o Futuro, se usa contract_size
   //{ 
   //   double stopLossValue = (MathAbs(entry_price - stop_loss) / Puntos) ;
   //   lot_size = risk_amount / (stopLossValue *  tick_value);
   //}   
   
   if (calc_mode == SYMBOL_CALC_MODE_FOREX || calc_mode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE )
   {
      double stopLossValue = (MathAbs(entry_price - stop_loss) / Puntos) ;
      lot_size = (risk_amount / (stopLossValue * tick_value));
      
      //Print(" risk_amount: ",risk_amount, "lot_size: german : ",lot_size);
   }

   if ( calc_mode == SYMBOL_CALC_MODE_CFDLEVERAGE)
   {

      if(contract_size == 1000) // Lote estándar
         pointValue =  10;
      if(contract_size == 100) // Lote estándar
         pointValue =  1;
      if(contract_size == 10) // Mini lote
         pointValue = 0.1;
      if(contract_size == 1) // Micro lote
         pointValue = 0.01;     
      
      // 3. Calcular pérdida potencial por lote
      stop_loss_pips = MathAbs(entry_price - stop_loss) / Puntos;
      //double lossPerLot   = stop_loss_pips * pointValue;   
      lot_size = (risk_amount / (stop_loss_pips * pointValue ));

   }

     
   
   double lot_min = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
   double lot_max = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);

   // Ajustar lote al mínimo, máximo y paso permitido
   lot_size = MathMax(lot_min, MathMin(lot_max, NormalizeDouble(lot_size, (int)MathLog10(1.0 / lot_step))));

   return lot_size;
}

double CalculateDailyProfitPercentage()
{
   double total_profit = 0.0;
   double balance_inicio = 0.0;
   
   datetime today = iTime(Symbol(), PERIOD_H8, 0); // Inicio del día actual
   //--- request trade history 
   HistorySelect(today,TimeCurrent()); 
   //Print("today:",today, " HistoryOrdersTotal:",HistoryOrdersTotal(), " HistoryDealsTotal:",HistoryDealsTotal() );
   // Buscar el balance más reciente antes del inicio del día
   for (int i = HistoryOrdersTotal() - 1; i >= 0; i--)
   {
      ulong order_ticket = HistoryOrderGetTicket(i);
      if (order_ticket > 0)
      {
         datetime order_time = HistoryOrderGetInteger(order_ticket, ORDER_TIME_SETUP);
         if (order_time < today) // Última orden antes de hoy
         {
            balance_inicio = AccountInfoDouble(ACCOUNT_BALANCE) - total_profit;
            //Print("balance_inicio:",balance_inicio);
            break;
         }
      }
   }

   // Calcular ganancias del día
   for (int i = HistoryDealsTotal() - 1; i >= 0; i--)
   {
      ulong deal_ticket = HistoryDealGetTicket(i);
      if (deal_ticket > 0)
      {
         datetime deal_time = HistoryDealGetInteger(deal_ticket, DEAL_TIME);
         if (deal_time >= today) // Solo operaciones de hoy
         {
            double profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
            total_profit += profit;
         }
      }
   }

   double percentage = (total_profit / 5000) * 100.0;
   //Print( " total_profit:",total_profit, " percentage:",percentage);
   if (balance_inicio == 0.0) return 0.0; // Evita división por cero

   //double percentage = (total_profit / balance_inicio) * 100.0;
   return percentage;
}


void Soporte_Resistencia(int lv_flag)
{

   return;

   if (lv_flag == 1)//Rompio Resistencia recrear Soporte
   {
      ObjectsDeleteAll(0,"Soporte");
   }
   else
   {
      ObjectsDeleteAll(0,"Resistencia");
   }
   //ObjectsDeleteAll(0,"Soporte");
   //ObjectsDeleteAll(0,"Resistencia");
   //int ObjectExiste1 = ObjectFind(0,"Soporte");    
   //int ObjectExiste2 = ObjectFind(0,"Resistencia");    
   ////Print("ObjectExiste : ",ObjectExiste);  
   //if (ObjectExiste1 > 0  || ObjectExiste2 > 0 )
   //{
   //   return;
   //   //ObjectsDeleteAll(0,"maximo");
   //   //ObjectsDeleteAll(0,"minimo");
   //}
   
   //else
   //{
   //   return;
   //}

   //ObjectsDeleteAll(0,"maximo");
   //ObjectsDeleteAll(0,"minimo");

   int velas_encontrar_estructura = 1;
   int velas = 1;;
   int val_index = 0; 
   double vlresistencia = 0;
   double vlsoporte = 0; 
   double vlalto = 0;
   double vlbajo = 0;
   ENUM_TIMEFRAMES lvtimeFrame = PERIOD_H4;
   
   //if (_Period == PERIOD_M1)// && VGShowMacrosKillzone == false)
   //{
   //  velas_encontrar_estructura = 2;
   //  velas = 2;
   //}
   
   val_index = iHighest(_Symbol,lvtimeFrame,MODE_HIGH,velas,1);
   //Print("Resistencia  val_index:",val_index," velas:",velas);
   if(val_index!=-1) 
   { 
     vlresistencia = iHigh(_Symbol,lvtimeFrame,val_index); 
     //vlhoraInicio = iTime(_Symbol,lvtimeFrame,val_index);
     //Print("vlhoraInicio :",vlhoraInicio, " vlresistencia :",vlresistencia, " val_index ",val_index);
   }  
   else  
      PrintFormat("Error de llamada de iHighest(). Código de error=%d",GetLastError());
      
//   //Print("highest=",highest," val_index =",val_index);      
//
   int val_index1  = val_index;
   
   if (val_index1 < velas)
   {

         for (int i = velas; i < velas_encontrar_estructura; i++) 
         {
            vlalto = iHigh(_Symbol,lvtimeFrame,i);
            
            if (vlalto < vlresistencia)
            {
                 //i = 1;
                 continue;
            }
            else
            {
               val_index = iHighest(_Symbol,lvtimeFrame,MODE_HIGH, velas * 2 , i  );
               vlresistencia = iHigh(_Symbol,lvtimeFrame,val_index);
               vlalto = iHigh(_Symbol,lvtimeFrame,i);
               if (vlalto < vlresistencia)
               {
                    //i = 1;
                    continue;
               }
               break;
            }
      
         }
    }
    
      
      string obj_name_maximo="Resistencia";

      vlresistencia = iHigh(_Symbol,PERIOD_H4,1);

      ObjectExiste = ObjectFind(0,obj_name_maximo);      
      if (ObjectExiste < 0)
      {    
         ObjectCreate(current_chart_id,obj_name_maximo,OBJ_HLINE,0, TimeCurrent(),vlresistencia);
         VGResistencia = vlresistencia;
      }   
      //else
      //{
      //  VGMaximo1 = ObjectGetDouble (0,obj_name_maximo,OBJPROP_PRICE);
      //}
      ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_COLOR,clrYellow); 
      ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_STYLE,STYLE_DOT); 
      ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_WIDTH,1); 
      ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_SELECTED,true); 
      ObjectSetString(current_chart_id,obj_name_maximo,OBJPROP_TEXT, "BSL");
      //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_ZORDER,100);  
      
//+++Fin Resistencia   



//Inicio Soporte
   val_index = iLowest(_Symbol,lvtimeFrame,MODE_LOW,velas,1);
   if(val_index!=-1)  
   {
     vlsoporte = iLow(_Symbol,lvtimeFrame,val_index);
     
     //vlhoraInicio = iTime(_Symbol,lvtimeFrame,val_index);
     //Print("vlhoraInicio :",vlhoraInicio, " vlsoporte :",vlsoporte, " val_index ",val_index);
   }
   else  
      PrintFormat("Error de llamada de iHighest(). Código de error=%d",GetLastError());
//
//   Print("Soporte val_index:",val_index," velas:",velas, " vlsoporte:",vlsoporte);
//
//   //Print("lowest=",lowest, " val_index =",val_index, " Velas ", velas);      
//
   val_index1  = val_index;
   if (val_index1 < velas)
   {
       //Print("Soporte 1 val_index:",val_index," velas:",velas);
      for (int i = velas; i < velas_encontrar_estructura; i++) {
         vlbajo = iLow(_Symbol,lvtimeFrame,i);  
 
        //Print("Soporte val_index:",val_index," velas:",velas, " vlsoporte:",vlsoporte, " vlbajo:",vlbajo, " i:",i );
   
         if (vlbajo > vlsoporte )
         {
            //i = 1;
            continue;
         }
         else
         {
            val_index = iLowest(_Symbol,lvtimeFrame,MODE_LOW, velas * 2, i  );
            vlsoporte = iLow(_Symbol,lvtimeFrame,val_index);  
            vlbajo = iLow(_Symbol,lvtimeFrame,i);  
            if (vlbajo > vlsoporte )
            {
               //i = 1; 
               continue;
            }
            break;
         }   
      }
   }
      string obj_name_minimo="Soporte";

      vlsoporte= iLow(_Symbol,PERIOD_H4,1);

      ObjectExiste = ObjectFind(0,obj_name_minimo);      
      if (ObjectExiste < 0)
      {    
         ObjectCreate(current_chart_id,obj_name_minimo,OBJ_HLINE,0,TimeCurrent(),vlsoporte);
         VGSoporte = vlsoporte;
      }   
      //else
      //{
      //  VGMinimo1 = ObjectGetDouble (0,obj_name_minimo,OBJPROP_PRICE);
      //}
      ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_COLOR,clrAqua); 
      ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_STYLE,STYLE_DOT); 
      ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_WIDTH,1); 
      ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_SELECTED,true);     
      ObjectSetString(current_chart_id,obj_name_minimo,OBJPROP_TEXT, "SSL");
      //ObjectSetInteger(current_chart_id,obj_name_minimo,OBJPROP_ZORDER,100); 

      //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,VGResistencia);
      //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,VGSoporte);

}
  
 
// Función para obtener el alto y bajo de la Kill Zone
double GetHigh(datetime start_time, datetime end_time)
{
   double high = iHigh(Symbol(), PERIOD_M5, 0);
   for(int i = 1; i < 100; i++) // Buscar en últimas 100 velas
   {
      datetime time = iTime(Symbol(), PERIOD_M5, i);
      if(time < start_time) break;
      high = MathMax(high, iHigh(Symbol(), PERIOD_M5, i));
   }
   return high;
}

double GetLow(datetime start_time, datetime end_time)
{
   double low = iLow(Symbol(), PERIOD_M5, 0);
   for(int i = 1; i < 100; i++) // Buscar en últimas 100 velas
   {
      datetime time = iTime(Symbol(), PERIOD_M5, i);
      if(time < start_time) break;
      low = MathMin(low, iLow(Symbol(), PERIOD_M5, i));
   }
   return low;
} 



void GetDailyProfitLoss()
{
    double profit = 0;
    double commision = 0;
    datetime date_start = iTime(Symbol(), PERIOD_D1, 0); // Hora de apertura del día actual
    datetime date_end = iTime(Symbol(), PERIOD_M1, 0); // Hora de apertura del día actual

//--- solicitamos toda la historia disponible en la cuenta 
   if(!HistorySelect(date_start,date_end)) 
     { 
      Print("HistorySelect() failed. Error ", GetLastError()); 
      return; 
     } 
         
    for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = HistoryDealGetTicket(i);
        if(ticket > 0)
        {
            datetime close_time = HistoryDealGetInteger(ticket, DEAL_TIME);
            if(close_time >= date_start) // Solo operaciones cerradas hoy
            {
                int deal_reason        = HistoryDealGetInteger(ticket, DEAL_REASON);
                double deal_profit     = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                double deal_commision  = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                datetime time_deal     = HistoryDealGetInteger(ticket, DEAL_TIME);
                //Print("deal_reason:",deal_reason," i:",i, " ticket: ",ticket, " time_deal: ",time_deal, " deal_profit :",deal_profit);
                profit += deal_profit;
                commision += deal_commision ;
            }
        }
    }
    //Print("profit del dia:",DoubleToString(profit,2), " commision:",DoubleToString(commision,2), " Net profit:",  DoubleToString(profit + commision,2), " HistoryDealsTotal :",HistoryDealsTotal());
    //return profit;
}


void GetInitialDayBalance()
{


//    // Obtener la hora de inicio del día actual
//    datetime startOfDay = iTime(_Symbol, PERIOD_D1, 0);
//    
//    // Obtener el historial de operaciones
//    HistorySelect(startOfDay, TimeCurrent());
//    
//    // Obtener el número total de órdenes en el historial
//    int totalOrders = HistoryOrdersTotal();
//    
//    // Recorrer las órdenes para encontrar el balance inicial
//    double initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
//    
//    for(int i = 0; i < totalOrders; i++)
//    {
//        ulong orderTicket = HistoryOrderGetTicket(i);
//        if(orderTicket > 0)
//        {
//            datetime orderTime = (datetime)HistoryOrderGetInteger(orderTicket, ORDER_TIME_DONE);
//            if(orderTime >= startOfDay)
//            {
//                double orderProfit = HistoryOrderGetDouble(orderTicket, ORDER_);
//                initialBalance -= orderProfit;
//            }
//        }
//    }
//    
//    Print("initialBalance:", initialBalance);

}
void informacionCuenta()
{
//--- Show all the information available from the function AccountInfoDouble() 
   //printf("ACCOUNT_BALANCE =  %G",AccountInfoDouble(ACCOUNT_BALANCE)); 
   //printf("ACCOUNT_CREDIT =  %G",AccountInfoDouble(ACCOUNT_CREDIT)); 
   //printf("ACCOUNT_PROFIT =  %G",AccountInfoDouble(ACCOUNT_PROFIT)); 
   //printf("ACCOUNT_EQUITY =  %G",AccountInfoDouble(ACCOUNT_EQUITY)); 
   //printf("ACCOUNT_MARGIN =  %G",AccountInfoDouble(ACCOUNT_MARGIN)); 
   //printf("ACCOUNT_MARGIN_FREE =  %G",AccountInfoDouble(ACCOUNT_MARGIN_FREE)); 
   //printf("ACCOUNT_MARGIN_LEVEL =  %G",AccountInfoDouble(ACCOUNT_MARGIN_LEVEL)); 
   //printf("ACCOUNT_MARGIN_SO_CALL = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_CALL)); 
   //printf("ACCOUNT_MARGIN_SO_SO = %G",AccountInfoDouble(ACCOUNT_MARGIN_SO_SO)); 

}


//+------------------------------------------------------------------+
//| Función para calcular niveles de soporte y resistencia          |
//+------------------------------------------------------------------+
void CalculateSupportResistance()
{
    int period = 14; // Período para calcular los máximos y mínimos
    double high = iHigh(NULL, 0, iHighest(NULL, 0, MODE_HIGH, period, 0));
    double low = iLow(NULL, 0, iLowest(NULL, 0, MODE_LOW, period, 0));
    
    // Calcular el 75% del rango entre el máximo y el mínimo
    double range = high - low;
    double support = low + (range * 0.25); // 25% del rango desde el mínimo
    double resistance = high - (range * 0.25); // 25% del rango desde el máximo
    
    // Imprimir los niveles en el log
    Print("Soporte: ", support);
    Print("Resistencia: ", resistance);
    
    // Dibujar los niveles en el gráfico
    ObjectCreate(0, "SupportLine", OBJ_HLINE, 0, 0, support);
    ObjectSetInteger(0, "SupportLine", OBJPROP_COLOR, clrRed);
    ObjectSetInteger(0, "SupportLine", OBJPROP_WIDTH, 2);
    
    ObjectCreate(0, "ResistanceLine", OBJ_HLINE, 0, 0, resistance);
    ObjectSetInteger(0, "ResistanceLine", OBJPROP_COLOR, clrBlue);
    ObjectSetInteger(0, "ResistanceLine", OBJPROP_WIDTH, 2);
}



void TextToSpeech(string text)
{
    // Ruta a python.exe (ajusta según tu instalación)
    string pythonPath = "py.exe"; // Si está en PATH, solo usa "python.exe"
    // string pythonPath = "C:\\Python39\\python.exe"; // Ruta completa si no está en PATH

    // Ruta al script de Python
    string scriptPath = "C:\\zbbot\\gtts_speak.py " + text;

    // Ejecutar el script
    int result = ShellExecuteW(
        NULL,           // Handle de la ventana (NULL para no usar ventana)
        "open",        // Verbo ("open" para ejecutar)
        pythonPath,    // Archivo a ejecutar (python.exe)
        scriptPath,    // Parámetros (ruta del script)
        NULL,          // Directorio de trabajo (NULL para usar el actual)
        SW_HIDE        // Ocultar la ventana de comandos
    );

    // Manejo de errores
    if (result <= 32) {
        Print("Error al ejecutar el script. Código de error: ", result);
    } 
    //else {de
    //    Print("Script de Python ejecutado correctamente.");
    //}
}


void DrawMacro_Session_Lunch(int lv_flag)
{

      //if( VGShowMacrosKillzone ==  true)
      //{
      //   //Print( "VGShowMacrosKillzone = false");
      //   return;
      //}
//Dibujar las macros

//ObjectsDeleteAll(0,"Macro");

      //Print("Flag:",lv_flag, " Symbol :",_Symbol);
         
      MqlDateTime MiHoraNewYork;
      MqlDateTime MiHoraActual;

       // Obtener la hora de Nueva York
      datetime newYorkTime = GetNewYorkTime();
      
      //TimeToStruct(newYorkTime, MiHoraNewYork);

      TimeToStruct(TimeCurrent(), MiHoraActual);
      
      TimeToStruct(newYorkTime, MiHoraNewYork);
      
      datetime HoraInicio;
      string macro_text ;

      int futureBars = 0;
         if( lv_flag >= 50)
            macro_text = "M"; 

         if  ( lv_flag == 50  && MiHoraNewYork.hour >= 02 ) //|| (MiHoraNewYork.hour == 18 && MiHoraNewYork.min <= 10)
         {

            string horaserver = GetServerTimeNY("02");
            
            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  " " + horaserver +":33:00";// + 2023.10.25 14:30';
            //Print("originalTime:",originalTime);
            HoraInicio = StringToTime(originalTime);
            futureBars = 27;
            macro_text = macro_text + horaserver + ":33"; // - 10:00";
         }    
         
         if ( lv_flag == 51 && MiHoraNewYork.hour >= 04)// && MiHoraNewYork.min >=  03 && MiHoraNewYork.hour <= 11)
         {

            string horaserver = GetServerTimeNY("04");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver + ":03:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 27;
            macro_text = macro_text  + horaserver + ":03 "; // - 11:30";
         }    
         
         if ( lv_flag == 52 && MiHoraNewYork.hour >= 07)// && MiHoraNewYork.min >=  50 && MiHoraNewYork.hour < 16)
         {

            string horaserver = GetServerTimeNY("07");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    
         
         if ( lv_flag == 53 && MiHoraNewYork.hour >= 08)//  && MiHoraNewYork.hour < 17)
         {

            string horaserver = GetServerTimeNY("08");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    

         if ( lv_flag == 54 && MiHoraNewYork.hour >= 09)
         {

            string horaserver = GetServerTimeNY("09");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    

         if ( lv_flag == 55 && MiHoraNewYork.hour >= 10)//  && MiHoraNewYork.hour < 19)
         {
            string horaserver = GetServerTimeNY("10");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    


         if ( lv_flag == 56 && MiHoraNewYork.hour >= 11)//  && MiHoraNewYork.hour < 19)
         {
            string horaserver = GetServerTimeNY("11");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    
         

         if ( lv_flag == 57 && MiHoraNewYork.hour >= 14)//  && MiHoraNewYork.hour < 19)
         {
            string horaserver = GetServerTimeNY("14");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
         }    
         


         if ( lv_flag == 58 && MiHoraNewYork.hour >= 13)
         {

            string horaserver = GetServerTimeNY("13");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":10:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 30;
            macro_text = macro_text + horaserver +  ":10";// - 16:10";
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 20:10:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 20:10 - 20:40";
         }    



         
         //MOC Macro = Market On Close Macro
         
         if ( lv_flag == 59 && MiHoraNewYork.hour >= 15) //MOC Macro = Market On Close Macro
         {

            string horaserver = GetServerTimeNY("15");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  "  " + horaserver +  ":15:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 30;
            macro_text = macro_text + horaserver +  ":15";// - 16:10";


            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }    
                  
                  
         if ( lv_flag == 60 && MiHoraNewYork.hour >= 19)
         {
            string horaserver = GetServerTimeNY("19");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      
           

         if ( lv_flag == 61 && MiHoraNewYork.hour >= 20)
         {
            string horaserver = GetServerTimeNY("20");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime, " lv_flag: ",lv_flag );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      

         if ( lv_flag == 62 && MiHoraNewYork.hour >= 21)
         {
            string horaserver = GetServerTimeNY("21");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime, " lv_flag: ",lv_flag );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      

         if ( lv_flag == 63 && MiHoraNewYork.hour >= 22)
         {
            string horaserver = GetServerTimeNY("22");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime, " lv_flag: ",lv_flag );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      


         if ( lv_flag == 64 && MiHoraNewYork.hour >= 23)
         {
            string horaserver = GetServerTimeNY("23");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime, " lv_flag: ",lv_flag );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      

         if ( lv_flag == 65 && MiHoraNewYork.hour >= 01)
         {
            string horaserver = GetServerTimeNY("01");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 20;
            macro_text = macro_text + horaserver +  ":50";// - 16:10";
            
            //Print("macro_text: ",macro_text, " originalTime: ",originalTime, " lv_flag: ",lv_flag );
            
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 22:15:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 30;
            //macro_text = "Macro 22:15 - 22:45";
         }                      



         //NY LUNCH HOUR MACRO RUNS ON LIQUIDITY
         if ( lv_flag == 2 && MiHoraNewYork.hour >= 12)// && MiHoraNewYork.min >= 11) || (MiHoraNewYork.hour == 19 && MiHoraNewYork.min <= 30)))//  && MiHoraNewYork.hour < 19)
         {
            string horaserver = GetServerTimeNY("12");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 90;
            macro_text = "M" + horaserver ;//  ":50";// - 16:10";
         }    


         //Asia Session
         if (lv_flag == 3 && MiHoraNewYork.hour >= 01 )//  && MiHoraNewYork.hour < 19)
         {

            string horaserver = GetServerTimeNY("20");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 240;
            macro_text = "Asia " + horaserver ;//  ":50";// - 16:10";

            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 02:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 240;
            //macro_text = "Asia 02:00 - 06:00 AM";
         }    

         //Londres Session
         if (lv_flag == 4 && MiHoraNewYork.hour >= 03 )//  && MiHoraNewYork.hour < 19)
         {

            string horaserver = GetServerTimeNY("02");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 240;
            macro_text = "Londres " + horaserver ;//  ":50";// - 16:10";


            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 08:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 180;
            //macro_text = "Londres 08:00 - 11:00 AM";
         }    

         //New York Session
         if (lv_flag == 5 && MiHoraNewYork.hour >= 08)//  && MiHoraNewYork.hour < 19)
         {

            string horaserver = GetServerTimeNY("08");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 180;
            macro_text = "NY " + horaserver ;//  ":50";// - 16:10";
         
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 15:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 180;
            //macro_text = "New York 14:00 - 17:00 PM";
         }    

         //Silver Bullet Londres
         if (lv_flag == 10 && MiHoraNewYork.hour >= 03)//  && MiHoraNewYork.hour < 19)
         {

            string horaserver = GetServerTimeNY("03");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 60;
            macro_text = "SL" + horaserver ;//  ":50";// - 16:10";


            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 08:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 60;
            //macro_text = "Silver 08:00 - 09:00 AM";
         }    

         //Silver Bullet New York Session AM
         if (lv_flag == 11 && MiHoraNewYork.hour >= 10)//  && MiHoraNewYork.hour < 19)
         {
         
            string horaserver = GetServerTimeNY("10");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 60;
            macro_text = "SNY " + horaserver ;//  ":50";// - 16:10";
         
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 17:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 60;
            //macro_text = "Silver 17:00 - 18:00 PM";
         }    

         //Silver Bullet New  York Session PM
         if (lv_flag == 12 && MiHoraNewYork.hour >= 14)//  && MiHoraNewYork.hour < 19)
         {
         
            string horaserver = GetServerTimeNY("14");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver;// +  ":50:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 60;
            macro_text = "SNY " + horaserver ;//  ":50";// - 16:10";

            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 21:00:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 60;
            //macro_text = "Silver  21:00 - 22:00 PM";
         }    

         //Macro OPENING RANGE
         if (  lv_flag == 13 && MiHoraNewYork.hour >= 09)//  && MiHoraNewYork.hour < 19)
         {
         
            string horaserver = GetServerTimeNY("09");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":30:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            futureBars = 60;
            macro_text = "OR" + horaserver +  ":30";// - 16:10";
         
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 16:30:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 60;
            //macro_text = "Opening 16:30 - 17:30 PM";
         }    

         //Samurai
         if (  lv_flag == 90 && MiHoraNewYork.hour >= 08)//  && MiHoraNewYork.hour < 19)
         {
         
            string horaserver = GetServerTimeNY("08");

            string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraActual.day + " "  "  " + horaserver +  ":00:00";// + 2023.10.25 14:30';
            HoraInicio = StringToTime(originalTime);
            //Print("Samurai - HoraInicio : ",HoraInicio);
            futureBars = 10;
            macro_text = "Samurai: " + horaserver +  ":00";// - 16:10";
         
            //string originalTime =  MiHoraNewYork.year + "." + MiHoraNewYork.mon + "." + MiHoraNewYork.day + " "  " 16:30:00";// + 2023.10.25 14:30';
            //HoraInicio = StringToTime(originalTime);
            //futureBars = 60;
            //macro_text = "Opening 16:30 - 17:30 PM";
         }    



         if (futureBars == 0)
            return;
            
         string obj_name_rectagle = "ZB_" + _Symbol + "_Macro_Rectangle"  + MiHoraNewYork.year + MiHoraNewYork.day + macro_text ;
         string obj_name_text = "ZB_" + _Symbol + "_Macro_Text"  + MiHoraNewYork.year + MiHoraNewYork.day + macro_text ;
         //string macro_text = " Macro " +  MiHoraNewYork.hour + " - " + MiHoraNewYork.min;
         int periodSeconds = PeriodSeconds(PERIOD_M1);
            //datetime HoraInicio = iTime(NULL,PERIOD_M1, 0); // Última barra (actual)
            datetime lvHoraFinal = HoraInicio + (periodSeconds * futureBars);
            //Print("lvHoraFinal:",lvHoraFinal);
            string ObjectExiste = ObjectFind(0,obj_name_rectagle);      
            if (ObjectExiste < 0)
            {    
               ObjectCreate(0,obj_name_rectagle,OBJ_RECTANGLE,0,HoraInicio, 0, lvHoraFinal, 0);//futureTime_1
               ObjectCreate(0,obj_name_text,OBJ_TEXT,0,HoraInicio,0);
            }   
         
         

         FindHighLowInTimeRange(ObjectGetInteger(0,obj_name_rectagle,OBJPROP_TIME,0),ObjectGetInteger(0,obj_name_rectagle,OBJPROP_TIME,1));
         
//          double high = iHigh(_Symbol, PERIOD_M10, iHighest(_Symbol, PERIOD_M10, MODE_HIGH, 2, 0));
//          double low  = iLow(_Symbol, PERIOD_M10, iHighest(_Symbol, PERIOD_M10, MODE_HIGH, 2, 0));
//          
//          if (high == low)
//             return;

         //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_COLOR,clrPink);
         if (lv_flag > 5) 
            ObjectSetInteger(0,obj_name_rectagle,OBJPROP_STYLE,STYLE_DOT);
          
         //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_WIDTH,2); 
         ObjectSetInteger(0,obj_name_rectagle,OBJPROP_COLOR,clrWhite);
         ObjectSetInteger(0,obj_name_rectagle,OBJPROP_SELECTABLE,false);
         //ObjectSetInteger(0,obj_name,OBJPROP_TIME,0,HoraInicio );
         //ObjectSetInteger(0,obj_name,OBJPROP_TIME,1,lvHoraFinal );
         //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_FILL,clrPink);
         //ObjectSetInteger(0,obj_name_rectagle,OBJPROP_SELECTED,true); 
         ObjectSetInteger(0,obj_name_rectagle,OBJPROP_BACK,true); 
         //ObjectSetString(0,obj_name_rectagle,OBJPROP_TEXT,macro_text);
         //ObjectSetInteger(0,obj_name,OBJPROP_ZORDER,9999); 
         ObjectSetDouble(0,obj_name_rectagle,OBJPROP_PRICE,0,MacroHigh);
         ObjectSetDouble(0,obj_name_rectagle,OBJPROP_PRICE,1,MacroLow);
         //ObjectSetInteger(0, obj_name_rectagle,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M15);
         
         ObjectSetString(0,obj_name_text,OBJPROP_TEXT,macro_text);
         
         //ObjectSetInteger(0,obj_name_text,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M15);
         ObjectSetDouble(0,obj_name_text,OBJPROP_PRICE,0,MacroHigh);
         ObjectSetInteger(0,obj_name_text,OBJPROP_COLOR,clrWhite);
         ObjectSetInteger(0,obj_name_text,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,obj_name_text,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0,obj_name_text,OBJPROP_FONTSIZE,7);
         


         if (lv_flag == 90) //Samurai
         {
         
            //Print("Samurai Flag:",lv_flag, " Symbol :",_Symbol);
            int periodSeconds = PeriodSeconds(PERIOD_M1);
            datetime lvHoraFinal = HoraInicio + (periodSeconds * 10);
            ObjectSetInteger(0,obj_name_rectagle,OBJPROP_STYLE,STYLE_SOLID);
          
            //ObjectSetInteger(current_chart_id,obj_name_maximo,OBJPROP_WIDTH,2); 
            ObjectSetInteger(0,obj_name_rectagle,OBJPROP_COLOR,clrBlue);
            ObjectSetInteger(0,obj_name_rectagle,OBJPROP_TIME,1,lvHoraFinal);
            
            
         }


         double lvpips = CalculateMovementAndProfit(MacroHigh,MacroLow,0);
         macro_text = macro_text + " P:" +  DoubleToString(lvpips,0);
         ObjectSetString(0,obj_name_text,OBJPROP_TEXT,macro_text);

         if (lv_flag < 50)
         {
            ObjectSetInteger(0,obj_name_rectagle,OBJPROP_COLOR,clrYellow);
            //ObjectSetInteger(0, obj_name_rectagle,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M10|OBJ_PERIOD_M15|OBJ_PERIOD_M20|OBJ_PERIOD_M30|OBJ_PERIOD_H1);
            //ObjectSetInteger(0,obj_name_text,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M10|OBJ_PERIOD_M15|OBJ_PERIOD_M20|OBJ_PERIOD_M30|OBJ_PERIOD_H1);
         }
         
}

void FindHighLowInTimeRange(datetime startTime, datetime endTime)
{
    // Inicializar las variables para almacenar el alto y el bajo
    MacroHigh = 0.0;
    MacroLow = DBL_MAX;

    // Obtener el número total de velas en el gráfico actual
    int totalBars = iBars(_Symbol, _Period);
    // Recorrer las velas desde la más reciente hasta la más antigua
    for (int i = 0; i < totalBars; i++)
    {
        // Obtener el tiempo de la vela actual
        datetime barTime = iTime(_Symbol, _Period, i);

        // Verificar si la vela está dentro del rango de tiempo especificado
        if (barTime >= startTime && barTime <= endTime)
        {
            // Obtener el precio alto y bajo de la vela actual
            double high = iHigh(_Symbol, _Period, i);
            double low = iLow(_Symbol, _Period, i);

            // Actualizar el alto y el bajo si es necesario
            if (high > MacroHigh)
                MacroHigh = high;

            if (low < MacroLow)
                MacroLow = low;
        }
    }

    // Si no se encontraron velas en el rango de tiempo, establecer los valores a 0
    if (MacroHigh == 0.0 && MacroLow == DBL_MAX)
    {
        MacroHigh = 0.0;
        MacroLow = 0.0;
    }
}



// Función para obtener el día de la semana
int GetDayOfWeek(datetime time)
{
    MqlDateTime timeStruct;
    TimeToStruct(time, timeStruct);
    return timeStruct.day_of_week;
}

// Función para verificar si está en horario de verano (DST) en Nueva York
bool IsNewYorkDST(datetime time)
{
    // Convertir datetime a MqlDateTime
    MqlDateTime timeStruct;
    TimeToStruct(time, timeStruct);

    // Reglas del horario de verano en Nueva York:
    // Comienza el segundo domingo de marzo a las 2:00 AM.
    // Termina el primer domingo de noviembre a las 2:00 AM.
    datetime dstStart = StringToTime(string(timeStruct.year) + ".03.08 02:00"); // Segundo domingo de marzo
    datetime dstEnd = StringToTime(string(timeStruct.year) + ".11.01 02:00");   // Primer domingo de noviembre

    // Ajustar el inicio y fin del DST
    while (GetDayOfWeek(dstStart) != 0) dstStart += 86400; // Avanzar hasta el domingo
    while (GetDayOfWeek(dstEnd) != 0) dstEnd += 86400;     // Avanzar hasta el domingo

    // Verificar si está dentro del rango de DST
    return (time >= dstStart && time < dstEnd);
}

// Función para obtener la hora de Nueva York
datetime GetNewYorkTime()
{
    // Obtener la hora GMT
    datetime serverTime = TimeGMT();

    // Obtener la hora actual del servido
    datetime horaActualServer = TimeCurrent();
    

    // Calcular la diferencia horaria con respecto a Nueva York
    int offset = -5 * 3600; // EST (UTC-5)
    if (IsNewYorkDST(serverTime))
        offset = -4 * 3600; // EDT (UTC-4) durante el horario de verano

    // Aplicar la diferencia horaria
    datetime newYorkTime = serverTime + offset;
    
    
    // Mostrar la hora de Nueva York
    //Print(" horaActualServer : ",horaActualServer, " Hora server TimeGTM :",serverTime," Hora de Nueva York: ", TimeToString(newYorkTime, TIME_MINUTES));

    return newYorkTime;
}


void HideObjectsByPrefix(string prefix) 
{
 
   //Print(" VGShowMacrosKillzone:",VGShowMacrosKillzone, " German");
   
   if( VGShowMacrosKillzone ==  false)
   { 
      ObjectsDeleteAll(0,"NW"); //Borra NWOG
      ObjectsDeleteAll(0,"ND"); // Borra NDOG

      ObjectsDeleteAll(0,"ZB_Arr");
      ObjectsDeleteAll(0,"ZB_Im");
      ObjectsDeleteAll(0,"Perfec");
      ObjectsDeleteAll(0,"Buy_");
      ObjectsDeleteAll(0,"Sell_");  
      ObjectsDeleteAll(0,"Samurai_");    
      ObjectsDeleteAll(0,"ZB_"+ _Symbol + "_Macro");
      //ObjectsDeleteAll(0,prefix);
   }   
   else
   {

          //Dibujar NWOG
          DrawNWOG();
          
          //Dibujar NDOG
          DrawNDOG();


//  Dibuja macros y sanurai
 
         DrawMacro_Session_Lunch(50); //Para Macros 
         DrawMacro_Session_Lunch(51); //Para Macros 
         DrawMacro_Session_Lunch(52); //Para Macros 
         DrawMacro_Session_Lunch(53); //Para Macros 
         DrawMacro_Session_Lunch(54); //Para Macros 
         DrawMacro_Session_Lunch(55); //Para Macros 
         DrawMacro_Session_Lunch(56); //Para Macros 
         DrawMacro_Session_Lunch(57); //Para Macros 
         DrawMacro_Session_Lunch(58); //Para Macros 
         DrawMacro_Session_Lunch(59); //Para Macros 
         DrawMacro_Session_Lunch(60); //Para Macros 
         DrawMacro_Session_Lunch(61); //Para Macros 
         DrawMacro_Session_Lunch(62); //Para Macros 
         DrawMacro_Session_Lunch(63); //Para Macros 
         DrawMacro_Session_Lunch(64); //Para Macros 
         DrawMacro_Session_Lunch(65); //Para Macros 
         DrawMacro_Session_Lunch(66); //Para Macros 
         DrawMacro_Session_Lunch(67); //Para Macros 
         DrawMacro_Session_Lunch(68); //Para Macros 
         DrawMacro_Session_Lunch(69); //Para Macros 
         DrawMacro_Session_Lunch(70); //Para Macros 
         DrawMacro_Session_Lunch(71); //Para Macros 
         
         DrawMacro_Session_Lunch(2); //Para Lunch
         DrawMacro_Session_Lunch(3); //Asia Session
         DrawMacro_Session_Lunch(4); //Londres Session
         DrawMacro_Session_Lunch(5); //New York Session
         
         DrawMacro_Session_Lunch(10); //Silver Bullet Londres
         DrawMacro_Session_Lunch(11); //Silver Bullet NY AM
         DrawMacro_Session_Lunch(12); //Silver Bullet NY PM
         
         DrawMacro_Session_Lunch(13); //Macro Opening Range
         
         DrawMacro_Session_Lunch(90); //Samurai
   
   }

//   int total = ObjectsTotal(0);
//   for (int i = total - 1; i >= 0; i--) {
//      string name = ObjectName(0, i);
//      //Print(" name : ",name);
//
//
//      if (StringFind(name, prefix) == 0 ) 
//      { // Si el nombre empieza con el prefijo
//         //Print(" name : ",name);
//         ObjectSetInteger(0, name, OBJPROP_HIDDEN, true); // No funciona para rectangulos es un problema de MT5
//         //ObjectSetInteger(0, name,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M15|OBJ_PERIOD_M20|OBJ_PERIOD_M30|OBJ_PERIOD_H1);
//         if ( VGShowMacrosKillzone == false)
//            ObjectSetInteger(0, name,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M15|OBJ_PERIOD_M20|OBJ_PERIOD_M30|OBJ_PERIOD_H1);
//
//         if ( VGShowMacrosKillzone == true)
//            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
//         // ObjectDelete(0, name); // Opción: Borrar en vez de ocultar
//      }

   //}
}



//+------------------------------------------------------------------+
//| Script para analizar gaps semanales (NWOG) últimos 60 días        |
//+------------------------------------------------------------------+
void DrawNWOG()
  {
  
   ObjectsDeleteAll(0,"NWOG_");
   int weeksToCheck = 8; // Máximo 8 semanas (~60 días)
   string gapInfo = "";

   for(int i=1; i<=weeksToCheck; i++)
     {
      double fridayClose = iClose(NULL, PERIOD_W1, i);
      double mondayOpen  = iOpen(NULL, PERIOD_W1, i-1);

      datetime startTime = iTime(NULL, PERIOD_W1, i-1);
      datetime endTime = iTime(NULL, PERIOD_M1, 0);

      double low2, high0;
      
      double gapSize     = (mondayOpen - fridayClose) / _Point;
      
      if ( fridayClose > mondayOpen )
      {
         low2 = mondayOpen;
         high0 = fridayClose;
      }
      else
      {
         low2 = fridayClose;
         high0 = mondayOpen;
      }
      string name = "NWOG_" + startTime;
      CreateFVGRectangle(name, startTime, low2, endTime, high0, clrMagenta, 0, 1);// 0 es para que se estienda hasta la vela actual y 1 es para NWOG y definir el estilo

      //if(MathAbs(gapSize) >= 10) // Filtro: gaps >10 pips
      //  {
      //   string direction = (gapSize > 0) ? "ALCISTA" : "BAJISTA";
      //   gapInfo += StringFormat("Semana %d: Gap %s (%.1f pips)\n", 
      //                          i, direction, MathAbs(gapSize));
      //  }
     }
//   if(gapInfo == "")
//      gapInfo = "No se encontraron gaps significativos en las últimas " + string(weeksToCheck) + " semanas.";
//   
//   Comment(gapInfo); // Muestra resultados en el gráfico
//   Print(gapInfo);   // Envía a la pestaña "Expertos"
  }

void DrawNDOG()
  {

   VGprev_visible_bars = (int)ChartGetInteger(0, CHART_VISIBLE_BARS);


    static datetime last_check_time = 0;

    last_check_time = TimeCurrent();

    DailyPriceRange ny_ranges[];


    // Call the function for the last 3 days
    if (GetNY5to6PMRanges(3, PERIOD_M15, _Symbol, ny_ranges)) // Using M15 for granularity
    {
        //Print("\n--- NY 5-6 PM Price Ranges for Last 3 Days ---");
        for (int i = 0; i < ArraySize(ny_ranges); i++)
        {
                  datetime startTime = ny_ranges[i].Date; 
                  datetime endTime = TimeCurrent() + 5 * 60; 
                  string name = "NDOG_" + startTime;
                  
                  Print( "startTime :",startTime," endTime : ",endTime);
                  double low2 = ny_ranges[i].LowestPrice;
                  double high0 = ny_ranges[i].HighestPrice; 
                  CreateFVGRectangle(name, startTime, low2, endTime, high0, clrMagenta, 0, 2);// 0 es para que se estienda hasta la vela actual y 2 es para NDOG y definir el estilo

            //Print("Fecha: ", TimeToString(ny_ranges[i].Date, TIME_DATE),
            //      " | High (5-6 PM NY): ", DoubleToString(ny_ranges[i].HighestPrice, _Digits),
            //      " | Low (5-6 PM NY): ", DoubleToString(ny_ranges[i].LowestPrice, _Digits));
        }
        Print("----------------------------------------------");
    }
    else
    {
        //Print("No se pudieron obtener los rangos de precio para NY 5-6 PM.");
    }
  }

//+------------------------------------------------------------------+ 
//| Script para noticias                                    | 
//+------------------------------------------------------------------+ 
void noticias() 
  { 
   MqlCalendarValue values[];

   MqlCalendarEvent event; 
   
   // Obtener noticias de la última semana
   MqlDateTime fecha_noticia;
   MqlDateTime fecha_actual;
   datetime start = TimeCurrent() - 5 * 60;
   //datetime end = start +  2*24*60*60;
   datetime end = start +  120*60;
   
   int count = CalendarValueHistory(values, start, end);
   
   TimeToStruct(TimeCurrent(),fecha_actual);
   
   if(StringFind(_Symbol, "EURUSD") == 0 )
   {
 
      if(( VGHoraNewYork.hour >= 07 && VGHoraNewYork.hour <= 11 && VGHoraNewYork.min == 47))
          //TextToSpeech("\"Macro en 3 minutos"  \"");
          textohablado("\"Macro en 3 minutos"  \"", false);
      if(( VGHoraNewYork.hour >= 07 && VGHoraNewYork.hour <= 11 && VGHoraNewYork.min == 48))
          //TextToSpeech("\"Macro en 2 minutos"  \"");
          textohablado("\"Macro en 2 minutos"  \"", false);
      if(( VGHoraNewYork.hour >= 07 && VGHoraNewYork.hour <= 11 && VGHoraNewYork.min == 49))
          //TextToSpeech("\"Macro en 1 minuto"  \"");
          textohablado("\"Macro en 1 minuto"  \"", false);
   }  
   
   if(count > 0)
   {
      //Print("Se encontraron ", count, " eventos importantes ");
      for(int i = 0; i < count; i++)
      {
         if(CalendarEventById(values[i].event_id,event)) 
           { 
            // Ordenar directamente por importancia (descendente)
            if (event.importance >= 3 ) //CALENDAR_IMPORTANCE_HIGH
            {
               //Print("Se encontraron ", count, " eventos importantes ");
               TimeToStruct(values[i].time,fecha_noticia);
               
               TimeToStruct(TimeCurrent(),fecha_actual);
               
                // Calcular la diferencia en segundos y convertir a minutos
                int secondsDiff = (values[i].time - TimeCurrent());
                int lvminutos =  secondsDiff / 60;
               
//               if (lvminutos > 0)
//               {
//                  if (lvminutos <= 6)
//                  {
//                     VGfecha_noticia_anterior = values[i].time;
//                     
//                     Print(" VGfecha_noticia_anterior :",VGfecha_noticia_anterior);
//                  }    
//                  VGminutos_noticias = lvminutos;
//                  VGprioridad_noticias = event.importance;
//                  
//                  //Print( "VGminutos_noticias : ",VGminutos_noticias, " Prioridad " , event.importance);
//               }
               
               VGminutos_noticias = lvminutos;
               VGprioridad_noticias = event.importance;

               //Print("ID:", values[i].id, " event_id:",values[i].event_id, " Day: ",fecha_noticia.day, " Hora: ", fecha_noticia.hour, " Minutos:", fecha_noticia.min, " lvminutos: ",lvminutos, " VGminutos_noticias:",VGminutos_noticias);
               
               MqlCalendarCountry country;  
               CalendarCountryById(event.country_id, country); 

               if (lvminutos <= 5 && event.importance == 3 &&  lvminutos >= 0 )
               {
                  //CloseAllPositions();
               }

               if (lvminutos <= 20 &&  lvminutos >= 0 && StringFind(_Symbol, "USDJPY") == 0)
               {
                  //int minutos = fecha_noticia.min - fecha_actual.min; 
                  //if (minutos < 20 && minutos > 0)
                  //Print("ID:", values[i].id, " event_id:",values[i].event_id, " Day: ",fecha_noticia.day, " Hora: ", fecha_noticia.hour, " Minutos:", fecha_noticia.min, " lvminutos: ",lvminutos, " VGminutos_noticias:",VGminutos_noticias);
                  //TextToSpeech("\"Noticia en " +  lvminutos + " Minutos " + " Prioridad " + event.importance +"  \"" );
                  if (event.importance == 3 && country.currency == "USD")
                  {
                     textohablado("\"Noticia en " +  lvminutos + " Minutos " + " Prioridad " + event.importance + " Name : " + event.name + " currency: " + country.currency + \"", true);
                  }
                  else
                  {
                     textohablado("\"Noticia en " +  lvminutos + " Minutos " + " Prioridad " + event.importance + " Name : " + event.name + " currency: " + country.currency +   \"", false);
                  }
                  //Print("Noticia en " +  lvminutos + " Minutos " + " Prioridad " + event.importance + " currency: " + country.currency);
               }
               //Print("event.id:",event.id, " importance :",event.importance, " country.name : ",country.name, " currency: ",country.currency);
               
               //PrintFormat("Event description with event_id=%d received",event.id); 
               //PrintFormat("Country: %s (country code = %d)",country.name,event.country_id); 
               //PrintFormat("Event name: %s",event.name); 
               //PrintFormat("Event code: %s",event.event_code); 
               //PrintFormat("Event importance: %s",EnumToString((ENUM_CALENDAR_EVENT_IMPORTANCE)event.importance)); 
               //PrintFormat("Event type: %s",EnumToString((ENUM_CALENDAR_EVENT_TYPE)event.type)); 
               //PrintFormat("Event sector: %s",EnumToString((ENUM_CALENDAR_EVENT_SECTOR)event.sector)); 
               //PrintFormat("Event frequency: %s",EnumToString((ENUM_CALENDAR_EVENT_FREQUENCY)event.frequency)); 
               //PrintFormat("Event release mode: %s",EnumToString((ENUM_CALENDAR_EVENT_TIMEMODE)event.time_mode)); 
               //PrintFormat("Event measurement unit: %s",EnumToString((ENUM_CALENDAR_EVENT_UNIT)event.unit)); 
               //PrintFormat("Number of decimal places: %d",event.digits); 
               //PrintFormat("Event multiplier: %s",EnumToString((ENUM_CALENDAR_EVENT_MULTIPLIER)event.multiplier)); 
               //PrintFormat("Source URL: %s",event.source_url);
               break;
            } 
           } 


//         TimeToStruct(values[i].time,fecha_noticia);
//         
//         TimeToStruct(TimeCurrent(),fecha_actual);
//         Print("ID:", values[i].id, " event_id:",values[i].event_id, " Day: ",fecha_noticia.day, " Hora: ", fecha_noticia.hour, " Minutos:", fecha_noticia.min);
//         
//         if (fecha_actual.hour == fecha_noticia.hour  )
//         {
//            int minutos = fecha_noticia.min - fecha_actual.min; 
//            if (minutos < 20 && minutos > 0)
//                TextToSpeech("\"Noticia  en " +  minutos + " Minutos " + \"");
//         }
         //Print(values[i].time, " ", values[i].event_id, 
         //      " Actual: ", values[i].actual_value,
         //      " Prev: ", values[i].prev_value,
         //      " Forecast: ", values[i].forecast_value);
      }
   }
   
  } 
 
 
 
 
 
 
//+------------------------------------------------------------------+
//| Función que calcula la hora del servidor cuando NY es 2:00 AM    |
//+------------------------------------------------------------------+
string GetServerTimeNY(string horaNY)
{
    // 1. Obtener la hora actual del servidor y GMT
    datetime gmtTime = TimeGMT(); // Hora actual en UTC+0
    datetime serverTime = TimeCurrent(); // Hora del servidor
    
    // 2. Calcular el UTC offset del servidor (ej: -5, -4, +2, etc.)
    int serverOffset = (serverTime - gmtTime) / 3599; // Diferencia en horas se cambia 3600 por 3599 por que por un segundo me daba una diferencia
    
    //double serverGMTOffset = (int)(serverTime - gmtTime) / 3599;
    
    // 3. Calcular la hora UTC equivalente a 2:00 AM NY (considerando EDT/EST)
    datetime nyTime;
    MqlDateTime nyTimeStruct;
    
    // Establecer hora en Nueva York
    TimeToStruct(gmtTime, nyTimeStruct); // Usamos GMT como base
    nyTimeStruct.hour = horaNY; // 2 AM
    nyTimeStruct.min = 0;
    nyTimeStruct.sec = 0;
    
    // Ajustar según horario de verano (EDT: UTC-4, EST: UTC-5)
    bool isDST = IsNewYorkDST(nyTimeStruct); // Verifica si NY está en horario de verano
    
    
    
    int nyOffset = isDST ? -4 : -5; // UTC-4 (EDT) o UTC-5 (EST)
    
    //Print("isDST: ", isDST, " nyOffset: ",nyOffset);
    
    // Convertir NY a UTC
    nyTime = StructToTime(nyTimeStruct) - (nyOffset * 3600);
    
    // 4. Convertir UTC a hora del servidor
    datetime serverTimeNY = nyTime + (serverOffset * 3600);

    MqlDateTime mifecha;
    TimeToStruct(serverTimeNY, mifecha);    

    if(horaNY == "08")
      {
         //Print("mifecha.hour :",mifecha.hour," serverOffset : ",serverOffset, " gmtTime : ",gmtTime, " serverTime : ",serverTime, " serverGMTOffset : ",serverGMTOffset);
      }    

    // 5. Devolver resultado formateado
    //Print(" mifecha.hour : ",mifecha.hour, " nyOffset : ",nyOffset);

    return mifecha.hour;
}

//+------------------------------------------------------------------+
//| Función auxiliar: Verifica si NY está en horario de verano (EDT) |
//+------------------------------------------------------------------+
bool IsNewYorkDST(const MqlDateTime &timeStruct)
{
    // Reglas del horario de verano en NY:
    // - Comienza 2do domingo de marzo a las 2:00 AM.
    // - Termina 1er domingo de noviembre a las 2:00 AM.
    
    if(timeStruct.mon > 3 && timeStruct.mon < 11) return true; // Abril a Octubre (EDT)
    
    // Marzo: Desde el 2do domingo
    if(timeStruct.mon == 3)
    {
        if(timeStruct.day >= 8 && timeStruct.day - timeStruct.day_of_week >= 8) 
            return true;
    }
    
    // Noviembre: Hasta el 1er domingo
    if(timeStruct.mon == 11)
    {
        if(timeStruct.day <= 7 && timeStruct.day_of_week > 0) 
            return false;
        if(timeStruct.day - timeStruct.day_of_week < 1) 
            return true;
    }
    
    return false; // Por defecto (EST)
} 
 
 
void fibo(string lvflag) // flag: 1 = internal swing estructue 2 = Swing estructure
{

   //ENUM_TIMEFRAMES timeframe

   string name = "ZB_FIBO_" + lvflag;
   if (mostrar_fibo == false)
   {
      ObjectsDeleteAll(0,name);
      return;
   }   
   
   int mas_velas = 50;
   
   int lvvelas1 = 7;
   int lvvelas2 = 12;
   
   //Print( "Scala : ",lvscale);
   
   if (VGscale == 0)
   {
      lvvelas1 = 128;
      lvvelas2 = 300;
   }   

   if (VGscale == 1)
   {
      lvvelas1 = 64;
      lvvelas2 = 150;
   }   

   if (VGscale == 2)
   {
      lvvelas1 = 32;
      lvvelas2 = 75;
   }   


   if (VGscale == 3)
   {
      lvvelas1 = 16;
      lvvelas2 = 37;
   }   


   if (VGscale == 4)
   {
      lvvelas1 = 8;
      lvvelas2 = 18;
   }   

   if (VGscale == 5)
   {
      lvvelas1 = 4;
      lvvelas2 = 10;
   }   

   int      periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lvHoraInicio = TimeCurrent() + (periodSeconds * lvvelas1);
   datetime lvHoraFinal = lvHoraInicio;// + (periodSeconds * lvvelas2);
   
   //datetime lvHoraFinal = lvHoraInicio + (periodSeconds * lvvelas2);
   
   if (lvflag == "2")
   {
      //periodSeconds  =  (lvvelas1 + 10 * lvscale ) *  periodSeconds;
      lvHoraInicio = TimeCurrent() + (periodSeconds * lvvelas2 ) ;
      lvHoraFinal = lvHoraInicio;
   }
   
   double lvsoporte, lvresistencia;


   //Print("lvscale:",lvscale);
   
   int lvfiboexiste = ObjectFind(0, name);
   if (ObjectFind(0, name) < 0)
   {
   
    ObjectCreate(0, name, OBJ_FIBO, 0, lvHoraInicio, 0, lvHoraFinal, 0);
        
    // Set visual properties
    ObjectSetDouble(0, name, OBJPROP_PRICE,0, VGvalor_fractal_alto);    
    ObjectSetDouble(0, name, OBJPROP_PRICE,1, VGvalor_fractal_bajo);    
    ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_BACK, true);
    //ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true); 
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);  
    ObjectSetInteger(0, name, OBJPROP_SELECTED, true);  
   
   }
   else
   {
    lvsoporte = ObjectGetDouble(0, name, OBJPROP_PRICE,0);    
    lvresistencia = ObjectGetDouble(0, name, OBJPROP_PRICE,1);    
   }
       
    //ObjectSetDouble(0, name, OBJPROP_PRICE,0, VGSoporte);    
    //ObjectSetDouble(0, name, OBJPROP_PRICE,1, VGResistencia);    


   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false); 
   ObjectSetInteger(0, name, OBJPROP_TIME,0, lvHoraInicio);
   ObjectSetInteger(0, name, OBJPROP_TIME,1, lvHoraFinal);
   ObjectSetInteger(0, name, OBJPROP_LEVELS, 13);
   
   if(lvflag == "2")
       ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true); 

   double range, lvporcentaje, lvvalor; 
   
   //Print("VGTendencia_interna:",VGTendencia_interna,"   german");

   //if (inptendencia == false) //Bajista
   //{
   //   ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvsoporte);    
   //   ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvresistencia);    
   //   range =   lvresistencia - lvsoporte;
   //   lvvalor = lvresistencia;
   //}
   //else
   //{
   //   ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvsoporte);    
   //   ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvresistencia);    
   //   range = lvsoporte - lvresistencia;
   //   lvvalor = lvsoporte;
   //}
   
   
   lvporcentaje = lvvalor - (range * 0.0); 
      
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 0, 0.0);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 0, "0.0 Profit ");// + DoubleToString(lvporcentaje,Digits())); 
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,0, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,0, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,0, 1);
   
   lvporcentaje = lvvalor - (range * 0.23);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 1, 0.23 );
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 1, "0.23 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,1, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,1, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,1, 1);

   lvporcentaje = lvvalor - (range * 0.50);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 2, 0.50);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 2, "0.50 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,2, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,2, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,2, 1);

   lvporcentaje = lvvalor - (range * 0.50);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 3, 0.618);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 3, "0.618 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,3, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,3, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,3, 1);
   
   
   lvporcentaje = lvvalor - (range * 0.705);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 4, 0.705);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 4, "OTE 0.705 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,4, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,4, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,4, 1);
   
   
   lvporcentaje = lvvalor - (range * 0.79);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 5, 0.79);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 5, "0.79 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,5, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,5, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,5, 1);

   lvporcentaje = lvvalor - (range * 0.90);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 6, 0.90);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 6, "0.90 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,6, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,6, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,6, 1);

   lvporcentaje = lvvalor - (range * 1);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 7, 1);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 7, "1 SL ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,7, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,7, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,7, 1);


   lvporcentaje = lvvalor - (range * -0.27);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 8, -0.27);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 8, "-0.27 T 1 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,8, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,8, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,8, 1);

   lvporcentaje = lvvalor - (range * -0.62);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 9, -0.62);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 9, "-0.62 T 2 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR,9, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE,9, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH,9, 1);

   lvporcentaje = lvvalor - (range * -1);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 10, -1);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 10 , "-1 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 10, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE, 10, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 10, 1);

   lvporcentaje = lvvalor - (range * -2);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 11, -2);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 11 , "-2 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 11, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE, 11, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 11, 1);

   lvporcentaje = lvvalor - (range * -2.5);
   ObjectSetDouble(0, name, OBJPROP_LEVELVALUE, 12, -2.5);
   ObjectSetString(0, name, OBJPROP_LEVELTEXT, 12 , "-2.5 ");// + DoubleToString(lvporcentaje,Digits()));
   ObjectSetInteger(0, name, OBJPROP_LEVELCOLOR, 12, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_LEVELSTYLE, 12, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_LEVELWIDTH, 12, 1);
   
} 


//+------------------------------------------------------------------+
//| Función para dibujar fractales con confirmación de 10 velas      |
//| (5 velas antes y 5 velas después del punto fractal)              |
//+------------------------------------------------------------------+
void DrawBarFractals(ENUM_TIMEFRAMES timeframe, int total_velas_fractal, int velas_verificar_fractal_1, string lvflag) // // flag: 1 = internal swing estructue 2 = Swing estructure
{
    //int velas_verificar_fractal = 25;
    
    // Limpiar objetos anteriores
    
    //Print("timeframe: ",timeframe);
    
    double lvsoporte = 0;
    double lvresistencia = 0;
    int contador_fractal_alto = 0;
    int contador_fractal_bajo = 0;
    
    string name;
    
    datetime hora_inicio;
    datetime hora_final;
    
    double fractal_alto[];
    double fractal_bajo[];
    ArrayResize (fractal_alto,200);
    ArrayResize (fractal_bajo,200);
    
    double valor_fractal_alto_1 = 0;
    double valor_fractal_alto_2 = 0; //para hallar la tendencia
    double valor_fractal_alto_3 = 0;
    double valor_fractal_bajo_1 = 0;
    double valor_fractal_bajo_2 = 0; //para hallar la tendencia
    double valor_fractal_bajo_3 = 0;
    

    //no mostrar
    if (mostrar_fractal == false)
    {
       ObjectsDeleteAll(0, "Fractal_");
       return;
    }
    
    ObjectsDeleteAll(0, "Fractal_L_"+lvflag);
    ObjectsDeleteAll(0, "Fractal_H_"+lvflag);
    
    // Obtener suficientes velas históricas (150 para margen de análisis)
    MqlRates rates[];
    ArraySetAsSeries(rates, true);
    int totalBars = total_velas_fractal;
    if(CopyRates(_Symbol, timeframe, 0, totalBars, rates) < totalBars) return;
    
    // Buscar fractales con confirmación de 10 velas (5+5)
    for(int i = velas_verificar_fractal_1; i < totalBars - velas_verificar_fractal_1; i++) // Margen de 5 velas en cada extremo
    {
        bool isBullishFractal = true;
        bool isBearishFractal = true;
        
        // Verificar  velas anteriores y  posteriores
        for(int j = 1; j <= velas_verificar_fractal_1; j++)
        {
            // Fractal alcista debe ser mayor que las  velas anteriores y posteriores
            if(rates[i].high <= rates[i-j].high || rates[i].high <= rates[i+j].high)
                isBullishFractal = false;
            
            // Fractal bajista debe ser menor que las  velas anteriores y posteriores
            if(rates[i].low >= rates[i-j].low || rates[i].low >= rates[i+j].low)
                isBearishFractal = false;
            
            // Si ya no cumple, salir del bucle para optimizar
            if(!isBullishFractal && !isBearishFractal)
             break;
        }
        
        // Dibujar fractal alcista confirmado
        if(isBullishFractal)
        {

             double highs[]; // Array para almacenar los precios High
             
             // Copiar los datos históricos de High (precios máximos de cada vela)
             int copied = CopyHigh(_Symbol, timeframe, 0, velas_verificar_fractal_1 * 2, highs);
             
             // Encontrar el valor máximo en el array
             int maxIndex = ArrayMaximum(highs);
             double lvmasalto = highs[maxIndex]; // Retorna el precio más alto 
             
            
            contador_fractal_alto++; 
                 
            if (contador_fractal_alto == 1)
            {
                valor_fractal_alto_1 = rates[i].high;
                hora_inicio = rates[i].time;

                lvresistencia = rates[i].high;
                if (lvresistencia < lvmasalto )
                {
                     lvresistencia = lvmasalto;
                     //rates[i].high = lvmasalto;
                }     
            }
            
            fractal_alto[contador_fractal_alto] = rates[i].high;    


            if (contador_fractal_alto == 2)
            {
                  valor_fractal_alto_2 = rates[i].high;            
            }
            
            if (contador_fractal_alto == 3)
                valor_fractal_alto_3 = rates[i].high;            
            
            //Print("VGTendencia_interna : ",VGTendencia_interna);                 
                  
             name = "Fractal_H_" + lvflag + "_" + IntegerToString(contador_fractal_alto);
            
            ////ObjectCreate(0, name, OBJ_ARROW, 0, rates[i].time, rates[i].high);
            //// Configurar el estilo del punto (código 160 es un círculo sólido)
            //ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 162);
            //ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
            //ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            //ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);

            ObjectCreate(0, name, OBJ_TEXT, 0, rates[i].time, rates[i].high);
            ObjectSetString(0, name, OBJPROP_TEXT, ".");
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrDodgerBlue);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 20);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);

            if(lvflag == "5")
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER);
            
            if (lvflag == "1" )
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
        }
        
        // Dibujar fractal bajista confirmado
        if(isBearishFractal)
        {

             double lows[]; // Array para almacenar los precios Low
             
             int copied = CopyLow(_Symbol, timeframe, 0, velas_verificar_fractal_1 * 2, lows);
             
             // Encontrar el valor minimo en el array
             int minIndex = ArrayMinimum(lows);
             double lvmasbajo = lows[minIndex]; // Retorna el precio más bajo        

            contador_fractal_bajo++;
            
            if (contador_fractal_bajo == 1)
            {
               lvsoporte = rates[i].low;
               hora_final = rates[i].time;
               
                valor_fractal_bajo_1 = rates[i].low;
                if (lvsoporte > lvmasbajo )
                {
                     lvsoporte = lvmasbajo;
                     //rates[i].low = lvmasbajo;
                }     
            }

            fractal_bajo[contador_fractal_bajo] = rates[i].low;    
            
            if (contador_fractal_bajo == 2)
                valor_fractal_bajo_2 = rates[i].low;

            if (contador_fractal_bajo == 3)
                valor_fractal_bajo_3 = rates[i].low;
            
            name = "Fractal_L_"+ lvflag + "_" + IntegerToString(contador_fractal_bajo);

            //ObjectCreate(0, name, OBJ_ARROW, 0, rates[i].time, rates[i].low);
            //// Configurar el estilo del punto (código 160 es un círculo sólido)
            //ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 162);
            //ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
            //ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            //ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_TOP);

            ObjectCreate(0, name, OBJ_TEXT, 0, rates[i].time, rates[i].low);
            ObjectSetString(0, name, OBJPROP_TEXT, ".");
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrOrangeRed);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 20);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_CENTER);
            
            if(lvflag == "5")
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
            if (lvflag == "1" )
               ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
        }

         if (lvflag == "1" )
         {
           ObjectSetInteger(0, name, OBJPROP_COLOR, clrYellow);
           ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 30);
         }    

         if(lvflag == "2")
         {
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrGreen); 
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 30);
         }  

        if (contador_fractal_bajo >= 5 && contador_fractal_alto >=  5 && lvflag == "5")
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 1);
            //break; //cuando encuentra el segundo fractal finaliza 
    }
    
//Fin fractales
    
    
    name = "Fractal_H_"+lvflag+"_1"; 
    datetime fecha_fractal_alto = ObjectGetInteger(0,name,OBJPROP_TIME);
    name = "Fractal_L_"+lvflag+"_1";
    datetime fecha_fractal_bajo = ObjectGetInteger(0,name,OBJPROP_TIME);
    
    //Print("fecha_fractal_alto : ",fecha_fractal_alto," fecha_fractal_bajo : ",fecha_fractal_bajo);
    
//Detectar Alcista fractal interno  y externo temporalidades altas  
             
//Hallar la tendencia con array

   double highestHigh = iHigh(Symbol(), timeframe, iHighest(Symbol(), timeframe, MODE_HIGH, 30, 0));
   double lowestLow = iLow(Symbol(), timeframe, iLowest(Symbol(), timeframe, MODE_LOW, 30, 0));
   string lvcaso;

   int numerofractales = 6;
   int lvcontador_alto = 0;
   int lvcontador_bajo = 0;

   int lvcontador_alto_bajo = 0;
   int lvcontador_bajo_bajo = 0;
   
   string lvtendencia ="Neutra";
   

   if(lvflag == "1" || lvflag == "2")
   {

         while(lvtendencia == "Neutra")
         {


//Segunda version

               for(int i = 1; i < numerofractales; i++)
               {

                  if(fractal_alto[i] > fractal_alto[i+1])
                     lvcontador_alto++;
                     
                  if (fractal_bajo[i] > fractal_bajo[i+1])
                     lvcontador_alto_bajo++;

                  if(fractal_alto[i] < fractal_alto[i+1])
                     lvcontador_bajo++;
                     
                  if (fractal_bajo[i] < fractal_bajo[i+1])
                     lvcontador_bajo_bajo++;
               }                  
               bool lvtendencia_alcista = false;
               bool lvtendencia_bajista = false;
               
               
               if (lvcontador_alto >= 3)// || lvcontador_alto_bajo >= 3)
               {
                  if ((fractal_bajo[1] < fractal_bajo[2] && fecha_fractal_alto < fecha_fractal_bajo && highestHigh < fractal_alto[1] && fractal_alto[1] < fractal_alto[2]) || lowestLow < fractal_bajo[1] )
                  {
                     lvtendencia_bajista = true;
                  }
                  else
                  {
                     if(fractal_alto[1] > fractal_alto[2] && highestHigh > fractal_alto[1])
                        lvtendencia_alcista = true;
                  }
                  //Print("lvtendencia_bajista :",lvtendencia_bajista);
               }
               if (lvcontador_bajo >= 3)// || lvcontador_bajo_bajo >=3)
               {
                  if ((fractal_alto[1] > fractal_alto[2] && fecha_fractal_bajo > fecha_fractal_alto && lowestLow > fractal_bajo[1] && fractal_bajo[1] > fractal_bajo[2]) || highestHigh > fractal_alto[1]  )
                  {
                     lvtendencia_alcista = true;
                  }      
                  else
                  {
                     if(fractal_bajo[1] < fractal_bajo[2] && lowestLow < fractal_bajo[1])
                        lvtendencia_bajista = true;
                  }
                  //Print(" lvtendencia_alcista : ",lvtendencia_alcista);
               }
               
               if (lvtendencia_alcista == lvtendencia_bajista)
               {
                  if(fecha_fractal_bajo > fecha_fractal_alto )
                  {
                     if (lowestLow < fractal_bajo[1])
                     {
                        lvtendencia = "Bajista";
                        break;
                     }   
                     if (highestHigh > fractal_alto[1])
                     {
                        lvtendencia = "Alcista";
                        break;
                     }   
                     if (fractal_bajo[1] < fractal_bajo[2])
                     {
                        lvtendencia = "Bajista";
                        break;
                     }   
                     if (fractal_alto[1] > fractal_alto[2])
                     {
                        lvtendencia = "Alcista";
                        break;
                     }   
                     if( fractal_bajo[2] < fractal_bajo[3] )
                     {
                        lvtendencia = "Bajista";
                        lvsoporte = fractal_bajo[2];
                        break;
                     }
                     if (fractal_bajo[1] > fractal_bajo[2])
                     {
                        lvtendencia = "Alcista";
                        break;                     
                     }
                     if (fractal_alto[1] < fractal_alto[2])
                     {
                        lvtendencia = "Bajista";
                        break;
                     }
                  }   
                  
                  if(fecha_fractal_bajo < fecha_fractal_alto )
                  {
                     if (lowestLow < fractal_bajo[1])
                     {
                        lvtendencia = "Bajista";
                        break;
                     }   
                     if (highestHigh > fractal_alto[1])
                     {
                        lvtendencia = "Alcista";
                        break;
                     }   
                     if (fractal_bajo[1] < fractal_bajo[2] && fractal_alto[1] < fractal_alto[2])
                     {
                        lvtendencia = "Bajista";
                        break;
                     }   

                     if (fractal_alto[1] > fractal_alto[2])
                     {
                        lvtendencia = "Alcista";
                        break;
                     }
                        
                     if( fractal_alto[2] > fractal_alto[3] )
                     {
                        lvtendencia = "Alcista";
                        lvresistencia = fractal_alto[2];
                        break;
                     }
                        
                     if (fractal_bajo[1] > fractal_bajo[2])
                     {
                        lvtendencia = "Alcista";
                        break;
                     }
                  }   

                  lvtendencia = "Neutra";
                  break;
               }   
               
               if(lvtendencia_alcista == true)
               {
                  lvtendencia = "Alcista";
                  break;
               }       
               if(lvtendencia_bajista == true)
               {
                  lvtendencia = "Bajista";
                  break;
               }       

                  lvcaso = " 9 Lateral : ";
                  break;
         }
         //Print("Caso lvflag 1 : ", lvcaso, " timeframe : ",  TimeframeToString(timeframe), " highestHigh : ",highestHigh ," lowestLow :",lowestLow);
         //if(VGTendencia_interna == "Alcista" || VGTendencia_interna == "Bajista" )
            //Print("VGTendencia_interna : ",VGTendencia_interna," alto : ",lvcontador_alto," alto_bajo : " ,lvcontador_alto_bajo," bajo : ", lvcontador_bajo, " bajo_bajo : ", lvcontador_bajo_bajo);
            string lvtimeframe = TimeframeToString(timeframe);
            //Print("lvtendencia : ",lvtendencia," alto : ",lvcontador_alto," bajo : ", lvcontador_bajo, " lvtimeframe : ",lvtimeframe);

         if(lvflag == "1")
           VGTendencia_interna = lvtendencia;
         if(lvflag == "2")
           VGTendencia_externa = lvtendencia;

         int vlvelas = 1; 
         int vlvelasparadetectarfibo = 1;
         if(lvflag == "1")
         {
              if (lvtendencia == "Alcista" )
              {
                  if(fractal_alto[1] > lvresistencia)
                  {
                     vlvelas = iBarShift(_Symbol,timeframe,fecha_fractal_alto) + 1;
                     for (int i = 1; i < vlvelas; i++ )
                     {
                       double alto = iHigh(_Symbol,timeframe,i);
                       //Print( " i : ",i, " alto :",alto, " fractal_alto[1] : ",fractal_alto[1]);
                       if ( alto < fractal_alto[1])
                       {
                           vlvelasparadetectarfibo++;
                       }
                     }
                  }
                  else
                  {
                     for(int j = 0; j < 500; j++)
                     {
                        double alto = iHigh(_Symbol,timeframe,j);
                        if (alto == lvresistencia )
                        {
                           break;
                        }
                        else
                        {
                           vlvelasparadetectarfibo++;
                           continue;
                        }
                     }
                  }
              }
              if (lvtendencia == "Bajista" )
              {
                  if(fractal_bajo[1] < lvsoporte)
                  {
                     vlvelas = iBarShift(_Symbol,timeframe,fecha_fractal_bajo) + 1;
                  
                     for (int i = 1; i < vlvelas; i++ )
                     {
                       double bajo = iHigh(_Symbol,timeframe,i);
                       if ( bajo > fractal_bajo[1])
                       {
                           vlvelasparadetectarfibo++;
                       }
                     }  
                  }
                  else
                  {
                     for(int j = 0; j < 500; j++)
                     {
                        double bajo = iLow(_Symbol,timeframe,j);
                        if (bajo == lvsoporte )
                        {
                           break;
                        }
                        else
                        {
                           vlvelasparadetectarfibo++;
                           continue;
                        }
                     }
                  
                  }
              }
              
              //Print("vlvelas : ",vlvelas, " timeframe : ",timeframe, " vlvelasparadetectarfibo : ",vlvelasparadetectarfibo );

              double     vlhighestHigh = iHigh(Symbol(), timeframe, iHighest(Symbol(), timeframe, MODE_HIGH, vlvelasparadetectarfibo, 0));
              double     vllowestLow = iLow(Symbol(), timeframe, iLowest(Symbol(), timeframe, MODE_LOW, vlvelasparadetectarfibo, 0));
              
              
              if (lvtendencia == "Alcista" )
              {
                  //VGPorcentaje_fibo = (lvresistencia - Bid) / (lvresistencia - lvsoporte) * 100;
                  VGPorcentaje_fibo = (lvresistencia - vllowestLow) / (lvresistencia - lvsoporte) * 100;
              }
              else
              {
                  VGPorcentaje_fibo = (vlhighestHigh - lvsoporte ) / (lvresistencia - lvsoporte) * 100;        
              }

            if(timeframe == PERIOD_M1)
            {
              VGTendencia_interna_M1 = lvtendencia; 
              m1Btn.Text("M1: "+ DoubleToString(VGPorcentaje_fibo,0)+"%"); 
              VGPorcentaje_fibo_M1 = VGPorcentaje_fibo;
              

              if (VGPorcentaje_fibo_M1 > 50 && VGTendencia_interna_M1 == "Alcista" && VGContadorAlertasZona_M1 <= 0)
              {
                  //textohablado("\"Zona de descuento M1 " + _Symbol +\"",true);
                  VGContadorAlertasZona_M1++;  
              }
              if (VGPorcentaje_fibo_M1 > 50 && VGTendencia_interna_M1 == "Bajista" && VGContadorAlertasZona_M1 <= 0)
              {
                  //textohablado("\"Zona Premiun M1 " + _Symbol +\"",true);
                  VGContadorAlertasZona_M1++;  
              }
              if (VGPorcentaje_fibo_M1 > 70 && VGContadorAlertasOte_M1 <= 0)
              {
                  //textohablado("\"Zona OTE M1 " + _Symbol +\"",true);
                  VGContadorAlertasOte_M1++;  
              }

            }
            if(timeframe == PERIOD_M3)
            {
              VGTendencia_interna_M3 = lvtendencia; 
              m3Btn.Text("M3: "+ DoubleToString(VGPorcentaje_fibo,0)+"%"); 
              VGPorcentaje_fibo_M3 = VGPorcentaje_fibo;

              if (VGPorcentaje_fibo_M3 > 50 && VGTendencia_interna_M3 == "Alcista" && VGContadorAlertasZona_M3 <= 0)
              {
                  //textohablado("\"Zona de descuento M3 " + _Symbol +\"",true);
                  VGContadorAlertasZona_M3++;  
              }
              if (VGPorcentaje_fibo_M3 > 50 && VGTendencia_interna_M3 == "Bajista" && VGContadorAlertasZona_M3 <= 0)
              {
                  //textohablado("\"Zona Premiun M3 " + _Symbol +\"",true);
                  VGContadorAlertasZona_M3++;  
              }
              if (VGPorcentaje_fibo_M3 > 70 && VGContadorAlertasOte_M3 <= 0)
              {
                  //textohablado("\"Zona OTE M3 " + _Symbol +\"",true);
                  VGContadorAlertasOte_M3++;  
              }

            }
            if(timeframe == PERIOD_M15)
            {
              VGTendencia_interna_M15 = lvtendencia;
              m15Btn.Text("M15: "+ DoubleToString(VGPorcentaje_fibo,0)+"%");
              VGPorcentaje_fibo_M15 = VGPorcentaje_fibo;
            }
            if(timeframe == PERIOD_H1)
            {
              VGTendencia_interna_H1 = lvtendencia;
              h1Btn.Text("H1: "+ DoubleToString(VGPorcentaje_fibo,0)+"%");
              VGPorcentaje_fibo_H1 = VGPorcentaje_fibo;
              
            }
            if(timeframe == PERIOD_H4)
            {
              VGTendencia_interna_H4 = lvtendencia;
              h4Btn.Text("H4: "+ DoubleToString(VGPorcentaje_fibo,0)+"%");
              VGPorcentaje_fibo_H4 = VGPorcentaje_fibo;
              
            }  
            if(timeframe == PERIOD_D1)
            {
              VGTendencia_interna_D1 = lvtendencia;
              d1Btn.Text("D1: "+ DoubleToString(VGPorcentaje_fibo,0)+"%");
              VGPorcentaje_fibo_D1 = VGPorcentaje_fibo;
              
            }  
         }    
   }
   

      
   double tolerance_value = DoubleToString(puntosFvg.Text(),2);
    
   double lvpuntos_rompe_resistencia  = MathAbs(lvresistencia - valor_fractal_alto_1) / Puntos;
   double lvpuntos_rompe_soporte  = MathAbs(valor_fractal_bajo_1 - lvsoporte) / Puntos;
   
   double lvpuntos_vela =MathAbs(iHigh(_Symbol,PERIOD_M1,0) - iLow(_Symbol,PERIOD_M1,0)) / Puntos ;
    
   //if(lvsoporte < valor_fractal_bajo_1 && lvflag == "1" )
   //   Print("Posible patron de venta MODELO 2022 ... lvpuntos_rompe_soporte :", lvpuntos_rompe_soporte , " tolerance_value : ",tolerance_value );
   //if(lvresistencia > valor_fractal_alto_1 && lvflag == "1" )
   //   Print("Posible patron de compra MODELO 2022 ... lvpuntos_rompe_resistencia :", lvpuntos_rompe_resistencia,  " tolerance_value : ",tolerance_value );     



   datetime fecha_caducidad_order = TimeCurrent() + 300 ;// minimo acepta 2 minutos 120 segundos
   //Print("fecha_caducidad_order :",fecha_caducidad_order);

   string lv_timeframe = TimeframeToString(timeframe);
   
   //verificar_ordenes_Abiertas();
   
//Inicio Modelo 2022   

   if (lvflag ==  "7")
   {
      VGvalor_fractal_alto = valor_fractal_alto_1;
      VGvalor_fractal_bajo = valor_fractal_bajo_1;
      return;
   }


   if (lvflag ==  "5")
   {
         VGvalor_fractal_alto_5 = valor_fractal_alto_1;
         VGvalor_fractal_bajo_5 = valor_fractal_bajo_1;

         //VGvalor_fractal_alto = lvresistencia;
         //VGvalor_fractal_bajo = lvsoporte;
         //ObjectSetDouble(0, "Resistencia", OBJPROP_PRICE,VGvalor_fractal_alto); 
         //ObjectSetDouble(0, "Soporte", OBJPROP_PRICE,VGvalor_fractal_bajo); 
   }

   if (lvflag ==  "1")
   {  
         //ObjectSetDouble(0, "Resistencia", OBJPROP_PRICE,VGvalor_fractal_alto); 
         //ObjectSetDouble(0, "Soporte", OBJPROP_PRICE,VGvalor_fractal_bajo); 

         if (VGTendencia_interna == "Bajista")
         {
            VGfibo_nivel_value_interna = valor_fractal_bajo_1 + (valor_fractal_alto_1 - valor_fractal_bajo_1) * 0.5;
            CambioBajista = 1;
            CambioAlcista = 0;
            //Print("Bajista : VGfibo_nivel_value ", VGfibo_nivel_value);
         }
         //if (VGTendencia_interna == "Bajista")
         //{
         if (VGTendencia_interna == "Alcista")
         {
            VGfibo_nivel_value_interna = valor_fractal_bajo_1 - (valor_fractal_alto_1 - valor_fractal_bajo_1) * -0.5;
            CambioAlcista = 1;
            CambioBajista = 0;
            //Print("Alcista : VGfibo_nivel_value ", VGfibo_nivel_value);
         }
    }

   if (lvflag == "2" )
   {

         //VGResistencia = lvresistencia;
         //VGSoporte = lvsoporte;
         

         //lvsoporte =  ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,valor_fractal_alto_1 ); 
         //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,valor_fractal_bajo_1 ); 
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,valor_fractal_bajo_1 );
         //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte ); 

         if (VGTendencia_externa == "Bajista")
         {
            VGfibo_nivel_value_externa = valor_fractal_bajo_1 + (valor_fractal_alto_1 - valor_fractal_bajo_1) * 0.5;
            //Print("Bajista : VGfibo_nivel_value ", VGfibo_nivel_value);
         }
         if (VGTendencia_externa == "Alcista")
         {
            VGfibo_nivel_value_externa = valor_fractal_bajo_1 - (valor_fractal_alto_1 - valor_fractal_bajo_1) * -0.5;
            //Print("Alcista : VGfibo_nivel_value ", VGfibo_nivel_value);
         }
    }
   
   //if (VGHoraNewYork.hour >= 02 &&  VGHoraNewYork.hour <= 08 || VGHoraNewYork.hour >= 09 && VGHoraNewYork.hour <= 12 || VGHoraNewYork.hour == 14 
   //   || VGHoraNewYork.hour >= 20 && VGHoraNewYork.hour <= 22  )
   double lvclose;
   string lvmensaje;
   
    
    // Convertir horas y minutos a minutos totales
    int current_minutes = VGHoraNewYork.hour * 60 + VGHoraNewYork.min;
    int start_minutes = inphorainicial * 60 + inpminutoinicial;
    int end_minutes = inphorafinal * 60 + inpminutofinal;
    
    //Print(" current_minutes : ", current_minutes, " start_minutes : ",start_minutes," end_minutes : ",end_minutes);

   
   int lvnumero_velas_verificar_fvg = 5;
   
   if (current_minutes >= start_minutes && current_minutes <= end_minutes)
   {
   }
   else
   {
     //VGcontadorAlertasAlcista = 0;
     //VGcontadorAlertasBajista = 0;
   }
   if( lvflag == "5" &&  (current_minutes >= start_minutes && current_minutes <= end_minutes)  )// && VGHoraNewYork.min <= inpminutofinal)// ||  VGHoraNewYork.hour >= 17 &&  VGHoraNewYork.hour <= 23 ) )// &&  VGHoraNewYork.hour == inphora el parametro 7 es solo para alertas
   {  
   
      if(VGmodelo2022 == true)
      {
        //VGcontadorAlertasBajista = 0;
        //VGcontadorAlertasAlcista = 0;
        //return;
      }

     double  lvpuntosvela = StringToDouble(puntosFvg.Text());
     double lvpuntosvelaanterior = 0;
     for (int i = 1; i<6; i++)
     {
        //double lvopen = iOpen(_Symbol,PERIOD_M1,i);
        //double lvclose = iClose(_Symbol,PERIOD_M1,i);
        double lvhigh = iHigh(_Symbol,PERIOD_M1,i);
        double lvlow = iLow(_Symbol,PERIOD_M1,i);
        lvpuntosvelaanterior = MathAbs(lvhigh  - lvlow ) / Puntos;

        //if ( lvopen > lvclose)
        //{
        //    lvpuntosvelaanterior = MathAbs(lvhigh  - lvlow ) / Puntos;
        //}
        //else
        //{
        //    lvpuntosvelaanterior = MathAbs(lvclose - lvopen ) / Puntos;
        //}

        if (lvpuntosvelaanterior > lvpuntosvela * inpumbral )
        {
            VGContadorPosible2022 = 1;
            break;
        }
        if (lvpuntosvelaanterior > lvpuntosvela)
        {
            VGContadorPosible2022 = 2;
            break;
        }
     }
     
     //Print( "VGContadorPosible2022 : ",VGContadorPosible2022, " lvpuntosvelaanterior : ",lvpuntosvelaanterior , " lvpuntosvela : ",lvpuntosvela);
     
      lvclose = iClose(_Symbol,PERIOD_M1,0);
      
      //VGHTF_Name = TimeframeToString(Time_Frame_M2022);
      //DrawFVG(Time_Frame_M2022, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 5);//para contar fvg dentro del rango de precios
   
   
      //double lot = CalculateLotSize(valor_fractal_bajo_1, lvresistencia, 1 ); // porcentajeRiesgo1); //calcular el tamano del lote  con 1% de riesgo    
      //if(VGTendencia_interna_D1 == "Bajista" )
      //{                 
         //Print("German verificando si funciona:");
         int lvalcista  = 1;
         int lvbajista  = 1;

         string  name_objet = "Sell_" + valor_fractal_bajo_1;  
         
         if(ObjectFind(0, name_objet) < 0 )// || ObjectFind(0, name_alto) < 0)
         {
            //VGcontadorAlertasBajista = 0;
            VGbag = false;
            lvbajista = 0;
         }   

//         if(VGcontadorAlertasBajista == 1)
//         {
             //name_alto = "Sell_" + valor_fractal_alto_1;  
            
//            
//            if(ObjectFind(0, name_alto) < 0 && VGcontadorAlertasBajista >= 1)// || ObjectFind(0, name_alto) < 0)
//            {
//               VGcontadorAlertasBajista = 0;
//               VGbag = false;
//            }   
//            else
//            {
//               VGcontadorAlertasBajista = 1;
//            }
//         }
         
            name_objet = "Buy_" + valor_fractal_alto_1;  
            if(ObjectFind(0, name_objet) < 0  )// || ObjectFind(0, name_alto) < 0)
            {
               //VGcontadorAlertasAlcista = 0;
               VGbag = false;
               lvalcista = 0;
            } 

         //if(VGcontadorAlertasAlcista == 1)
         //{
            //name_alto = "Buy_" + valor_fractal_alto_1;  
            //if(ObjectFind(0, name_alto) < 0 && VGcontadorAlertasAlcista >= 1)// || ObjectFind(0, name_alto) < 0)
            //{
            //   VGcontadorAlertasAlcista = 0;
            //   VGbag = false;
            //} 
            //else
            //{
            //   VGcontadorAlertasAlcista = 1;
            //}  
         //}
         
         //VGvalor_fractal_alto = valor_fractal_alto_1;
         //VGvalor_fractal_bajo = valor_fractal_bajo_1;

         if(VGcontadorAlertasBajista >= 1)
         {
            //VGHTF_Name = TimeframeToString(Time_Frame_M2022);
            //DrawFVG(Time_Frame_M2022, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);//para contar fvg dentro del rango de pecios
            //DrawFVG(PERIOD_M3, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);
            //DrawFVG(PERIOD_M5, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);
            if (VGcontadorFVG >= inpnumerofvg && VGcontadorAlertasBajista == 1)
            {
               //lvmensaje = "\"Oportunidad de Venta con " + VGcontadorFVG + " FVG " +  _Symbol + \"";
               //textohablado(lvmensaje,true);
               //VGcontadorAlertasBajista = 2;
            }   
            //return;
         }

         if(VGcontadorAlertasAlcista >= 1)
         {
            //VGHTF_Name = TimeframeToString(Time_Frame_M2022);
            //DrawFVG(Time_Frame_M2022, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);//para contar fvg dentro del rango de pecios
            //DrawFVG(PERIOD_M3, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);
            //DrawFVG(PERIOD_M5, lvnumero_velas_verificar_fvg, Color_Bullish_HTF, Color_Bearist_HTF, 9);

            if(VGcontadorFVG >= inpnumerofvg && VGcontadorAlertasAlcista == 1)
            {
               lvmensaje = "\"Oportunidad de compra con  " + VGcontadorFVG  + " FVG " +  _Symbol + \"";
               //textohablado(lvmensaje,true);
               //VGcontadorAlertasAlcista = 2;
            }
            //return;
         }

//         if(iOpen(_Symbol,Time_Frame_M2022,1) > iClose(_Symbol,Time_Frame_M2022,1) && VGcontadorAlertasBajista <= 0)
//         {
//              lvclose = iClose(_Symbol,Time_Frame_M2022,1);
//
//              double  lvpuntosvela = StringToDouble(puntosFvg.Text());
//              lvclose = iClose(_Symbol,Time_Frame_M2022,1);
//              double lvopen = iOpen(_Symbol,PERIOD_M1,1);
//              double lvclose = iClose(_Symbol,PERIOD_M1,1);
//              double lvpuntosvelaanterior = MathAbs(lvopen  - lvclose ) / Puntos;
//              if (lvpuntosvelaanterior > lvpuntosvela * inpumbral )
//              {
//                  VGContadorPosible2022 = 1;
//              }
//         } 
          if(lvclose < valor_fractal_bajo_1 && lvbajista == 0 )// && VGcontadorAlertasAlcista == 1)// && VGContadorPosible2022 >= )// && VGTendencia_interna_M1 == "Bajista"  && VGTendencia_interna_M3 == "Bajista" || VGPorcentaje_fibo_M3 < 30 ))// && VGcontadorAlertasBajista <= 0)// && VGcontadorAlertasBajista == 0) // && VGTendencia_interna_M3 == "Alcista" && VGPorcentaje_fibo_M3 < 50 &&  VGPorcentaje_fibo_M3 > 30)// && lvpuntos_vela > tolerance_value )// && VGTendencia_interna == "Bajista")// && valor_fractal_alto_1 > valor_fractal_alto_2)
          {

               
               //if (Bid > VGbias_H4 && Bid > VGbias_D1 && Bid > VGbias_W1 )
               //{
               //  lvmensaje = "\"Exelente oportunidad de Venta con el Bias " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //}
               //if (Bid > VGbias_H4 && Bid > VGbias_D1)
               //{
               //  lvmensaje = "\"Buena oportunidad de Venta con el Diario + H4  " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //}
               //if (Bid > VGbias_H4 )
               //{
               //  lvmensaje = "\"Oportunidad de Venta con el Bias H4 " +  _Symbol + " " + lv_timeframe +  \"";
               //  VGContadorPosible2022++;
               //  //VGvalor_fractal_bajo = VGbias_H4;
               //}
               //if (Bid > VGbias_D1 )
               //{
               //  lvmensaje = "\"Oportunidad de Venta con el Bias Diario " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //  VGvalor_fractal_bajo = VGbias_D1;
               //}

               //if (VGcontadorAlertasAlcista >= 0)
               //{
               //   VGContadorPosible2022++;
               //}


               //VGvalor_fractal_alto_5 = lvresistencia;
               //VGvalor_fractal_bajo_5 = lvsoporte;
               
               VGcontadorAlertasBajista++ ;
               VGcontadorAlertasAlcista = 0;
               
               if( VGContadorPosible2022 == 1)// && VGContadorAlertasZona_M1 > 0 && VGcontadorAlertasBajista == 0)
               {
                  lvmensaje = "\"Oportunidad de Venta con vela grande : " +  _Symbol + " " + lv_timeframe +  " Contador : " + VGcontadorAlertasBajista +\"";
                  textohablado(lvmensaje, true);
               }

               if ( VGVenta == 1)//VGTendencia_interna_M15 == "Bajista" && VGPorcentaje_fibo_M15 > 50 || VGVenta == 1)
               { 
                     lvmensaje = "\"Oportunidad de Venta " +  _Symbol + " " + lv_timeframe + " Contador : " + VGcontadorAlertasBajista + \"";
                     textohablado(lvmensaje, false);
               }
               
               
               //if(VGcumplerregla == true)
               // &&  VGTendencia_interna_H4 == "Bajista" || VGTendencia_interna_H1 == "Bajista" || VGTendencia_interna_M15 == "Bajista" )// && VGTendencia_interna_M3 == "Bajista" ))
               //{
                  //if(VGTendencia_interna_H4 == "Bajista" && VGPorcentaje_fibo_H4 > 50)// && timeframe == PERIOD_H4)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Venta H4 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //}   
                  //if(VGTendencia_interna_M3 == "Bajista" && VGPorcentaje_fibo_M3 > 50)// && timeframe == PERIOD_M3)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Venta M3 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //}   
                  //if(VGTendencia_interna_M15 == "Bajista" && VGPorcentaje_fibo_M15 > 50)// && timeframe == PERIOD_M15)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Venta M15 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //}   
                  //if(VGTendencia_interna_H1 == "Bajista" && VGPorcentaje_fibo_H1 > 50)// && timeframe == PERIOD_H1)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Venta H1 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //}   
                  
                  //VGContadorAlertasOte = 0;
                  //VGContadorAlertasZona = 0; 

                  DrawBuySell(valor_fractal_alto_1,valor_fractal_bajo_1,"Sell_",clrWhite, STYLE_SOLID);//,C'89,9,24');
                  
                  double lvmidprice = lvresistencia + (lvsoporte - lvresistencia) / 2.0;

                  //ObjectSetDouble(0, "Resistencia", OBJPROP_PRICE,lvresistencia);
                  //ObjectSetDouble(0, "Soporte", OBJPROP_PRICE,lvsoporte);
                  
                  VGMaximo2 = lvresistencia;
                  VGMinimo1 = lvsoporte;
                  
                  //lvsoporte =  ObjectGetDouble(0, "Soporte", OBJPROP_PRICE);
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,valor_fractal_alto_1 ); 
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,valor_fractal_bajo_1 ); 
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,valor_fractal_bajo_1 );
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,lvsoporte ); 
                  
                  
                  //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
                  //ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');
                  //ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false); 
                  //ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false); 

            }    

         
         
// COMPRAS         

         //if(VGTendencia_interna_D1 == "Alcista" )
         //{
//            if(iOpen(_Symbol,Time_Frame_M2022,1) < iClose(_Symbol,Time_Frame_M2022,1) && VGcontadorAlertasAlcista <= 0)
//            {
//               lvclose = iClose(_Symbol,Time_Frame_M2022,1);
//
//
//              double  lvpuntosvela = StringToDouble(puntosFvg.Text());
//              lvclose = iClose(_Symbol,Time_Frame_M2022,1);
//              double lvopen = iOpen(_Symbol,PERIOD_M1,1);
//              double lvclose = iClose(_Symbol,PERIOD_M1,1);
//              double lvpuntosvelaanterior = MathAbs(lvclose - lvopen  ) / Puntos;
//              if (lvpuntosvelaanterior > lvpuntosvela * inpumbral )
//              {
//                  VGContadorPosible2022 = 1;
//              }
//            }  
            if( lvclose > valor_fractal_alto_1   && lvalcista == 0 )// && VGcontadorAlertasBajista == 1 && VGContadorPosible2022 >= 1)// && VGTendencia_interna_M1 == "Alcista"  && VGTendencia_interna_M3 == "Alcista" || VGPorcentaje_fibo_M3 < 30 ))//&& VGcontadorAlertasAlcista <= 0 )// && VGTendencia_interna_M3 == "Bajista" && VGPorcentaje_fibo_M3 < 50 &&  VGPorcentaje_fibo_M3 > 30)// && lvpuntos_vela > tolerance_value ) //&& valor_fractal_bajo_1 < valor_fractal_bajo_2
            {

               //if (Bid < VGbias_H4 && Bid < VGbias_D1 && Bid < VGbias_W1 )
               //{
               //  lvmensaje = "\"Exelente oportunidad de compras con el Bias " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //}
               //if (Bid < VGbias_H4 && Bid < VGbias_D1 )
               //{
               //  lvmensaje = "\"Buena oportunidad de compras con el Bias Diario + H4 " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //}
               //if (Bid < VGbias_H4 )
               //{
               //  lvmensaje = "\"Oportunidad de compras con el Bias H4 " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //  VGvalor_fractal_alto = VGbias_H4;
               //}
               //if (Bid < VGbias_D1 )
               //{
               //  lvmensaje = "\"Oportunidad de compras con el Bias Diario " +  _Symbol + " " + lv_timeframe +  \"";
               //  //VGContadorPosible2022++;
               //  VGvalor_fractal_alto = VGbias_D1;
               //}
               
               //if (VGcontadorAlertasBajista >= 0)
               //{
               //   VGContadorPosible2022++;
               //}
               
               VGcontadorAlertasAlcista++;
               VGcontadorAlertasBajista = 0;
               //VGContadorAlertasOte = 0;
               //VGContadorAlertasZona = 0; 

               if( VGContadorPosible2022 == 1)// && VGContadorAlertasZona_M1 > 0 && VGcontadorAlertasAlcista == 0)
               {
                  lvmensaje = "\"Oportunidad de compra con vela grande : " +  _Symbol + " " + lv_timeframe + " Contador : " + VGcontadorAlertasAlcista + \"";
                  textohablado(lvmensaje, true);
               }

               if( VGCompra == 1)//VGTendencia_interna_M15 == "Alcista" && VGPorcentaje_fibo_M15 > 50 || VGCompra == 1)
               {
                     lvmensaje = "\"Oportunidad de compra  : " +  _Symbol + " " + lv_timeframe + " Contador : " + VGcontadorAlertasAlcista + \"";
                     textohablado(lvmensaje, false);
               }


               //if(VGcumplerregla == true)
//                 && VGTendencia_interna_H4 == "Alcista" || VGTendencia_interna_H1 == "Alcista" || VGTendencia_interna_M15 == "Alcista" )// && VGTendencia_interna_M3 == "Alcista"  )))
               //{



                  //if(VGTendencia_interna_H4 == "Alcista" && VGPorcentaje_fibo_H4 > 50)// && timeframe == PERIOD_H4)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Compra H4 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //} 
                  //if(VGTendencia_interna_M3 == "Alcista" && VGPorcentaje_fibo_M3 > 50)// && timeframe == PERIOD_M3)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Compra M3 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //} 
                  //if(VGTendencia_interna_M15 == "Alcista" && VGPorcentaje_fibo_M15 > 50)// && timeframe == PERIOD_M15)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Compra M15 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //} 
                  //if(VGTendencia_interna_H1 == "Alcista" && VGPorcentaje_fibo_H1 > 50)// && timeframe == PERIOD_H1)
                  //{
                  //   VGContadorPosible2022++;
                  //   textohablado("\"Alta probabilidad Compra H1 " +  _Symbol + " " + lv_timeframe +  \"", true);
                  //} 


                  DrawBuySell(valor_fractal_alto_1,valor_fractal_bajo_1,"Buy_",clrWhite, STYLE_SOLID);//C'0,105,108');
                  
                  double lvmidprice = lvresistencia + (lvsoporte - lvresistencia) / 2.0;
                  
                  //ObjectSetDouble(0, "Resistencia", OBJPROP_PRICE,lvresistencia);
                  //ObjectSetDouble(0, "Soporte", OBJPROP_PRICE,lvsoporte);
                  
                  VGMaximo2 = lvresistencia;
                  VGMinimo1 = lvsoporte;
                  
                  //lvresistencia =   ObjectGetDouble(0, "Resistencia", OBJPROP_PRICE);
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,0,lvresistencia ); 
                  //ObjectSetDouble(0, "maximo_M15", OBJPROP_PRICE,1,valor_fractal_alto_1 ); 
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,0,valor_fractal_alto_1 );
                  //ObjectSetDouble(0, "minimo_M15", OBJPROP_PRICE,1,valor_fractal_bajo_1 );
                  
                  
                  
                   
                  //ObjectSetInteger(0, "maximo_M15", OBJPROP_COLOR, C'89,9,24');
                  //ObjectSetInteger(0, "minimo_M15", OBJPROP_COLOR, C'0,105,108');
                  //ObjectSetInteger(0, "maximo_M15", OBJPROP_SELECTED,false); 
                  //ObjectSetInteger(0, "minimo_M15", OBJPROP_SELECTED,false); 

               }
   }


   if(lvflag == "5")// 5 es solo para programar compras o ventas 7 Solo para alertas
   {
   
//       double lvalto = valor_fractal_alto_1;
//       double lvbajo = valor_fractal_bajo_1;
//      string name = "FIBO_3";
//      if(VGCompra == 1 && Bid > lvbajo)
//      {
//          ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvbajo);    
//          ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvalto);  
//          //VGcontadorAlertasAlcista++;
//      }
//      
//      if(VGVenta == 1 && Bid < lvalto)
//      {
//          ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvalto);    
//          ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvbajo);
//          //VGcontadorAlertasBajista++;       
//      }
//       datetime fecha_fibo_3 = TimeCurrent() + (5 * PeriodSeconds());
//       ObjectSetInteger(0, name, OBJPROP_TIME,0, fecha_fibo_3);
//       ObjectSetInteger(0, name, OBJPROP_TIME,1, fecha_fibo_3);
//       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);

      //if(timeframe == PERIOD_M1)
      //{
      //   VGvalor_fractal_alto = valor_fractal_alto_1; 
      //   VGvalor_fractal_bajo = valor_fractal_bajo_1;
      //}

         //VGMidPrice = valor_fractal_alto_1 + (valor_fractal_bajo_1 - valor_fractal_alto_1) / 2.0;

      CISD();
      
//      if(VGContadorPosible2022 > 0)
//      {
//         VGMidPrice_M1 = lvresistencia + (lvsoporte - lvresistencia) / 2.0;
//   
//      }
      
      return;
   }



   
   if(lvflag == "1")
   {

      //VGSoporte = lvsoporte;
      //VGResistencia = lvresistencia;
  
      if(timeframe == PERIOD_M1)
      {
         //VGMidPrice = lvresistencia + (lvsoporte - lvresistencia) / 2.0;
         
         //VGResistencia = fractal_alto[1];
         //VGSoporte = fractal_bajo[1];
         VGvalor_fractal_alto = fractal_alto[1];;
         VGvalor_fractal_bajo = fractal_bajo[1];;
         //Print(" VGResistencia :",VGResistencia, " VGSoporte :",VGSoporte);
         
         //ObjectSetDouble(0, "midPrice", OBJPROP_PRICE,VGMidPrice);
      }   



      if(timeframe == PERIOD_M3)
      {

         VGResistencia = lvresistencia;
         VGSoporte = lvsoporte;
      }

      if(VGTendencia_interna_M1 == "Bajista" && timeframe == PERIOD_M1)
      {
         //VGPorcentaje = (iHigh(_Symbol,PERIOD_M15,1) - lvsoporte ) / (lvresistencia - lvsoporte) * 100;
         //Print(" VGPorcentaje :",VGPorcentaje);
      }
      //Print(" VGPorcentaje :",VGPorcentaje);
   }

   if(lvflag == "2")
   {  
      //ObjectSetDouble(0,"Resistencia",OBJPROP_PRICE,lvresistencia);
      //ObjectSetDouble(0,"Soporte",OBJPROP_PRICE,lvsoporte);
      if(VGTendencia_externa == "Alcista")
      {
         VGPorcentaje_externa = (lvresistencia - Bid) / (lvresistencia - lvsoporte) * 100;
      }
      else
      {
         VGPorcentaje_externa = (Bid - lvsoporte ) / (lvresistencia - lvsoporte) * 100;
      }

   }
   
   
   //VGvalor_fractal_alto = lvresistencia;
   //VGvalor_fractal_bajo = lvsoporte;
   
    name = "ZB_FIBO_"  + lvflag;
     
    // Set visual properties
    //Print("lvsoporte:",lvsoporte,"lvresistencia:",lvresistencia, " lvflag : ",lvflag);

    //Print("VGTendencia_interna: ",VGTendencia_interna, " lvflag : ",lvflag );
    if (VGTendencia_interna == "Alcista" && lvflag == "1" )
    {
       //Print("VGTendencia_interna: ",VGTendencia_interna);
       ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvsoporte);    
       ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvresistencia); 
    }
    
    if (VGTendencia_interna == "Bajista" && lvflag == "1" )
    {
       ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvresistencia);    
       ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvsoporte);    
    }
    

    if (VGTendencia_externa == "Alcista" && lvflag == "2" )
    {
       ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvsoporte);    
       ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvresistencia);    
    }
    
    //Print("VGTendencia_externa: ",VGTendencia_externa, " lvflag : ",lvflag, " name : ", name );
    if (VGTendencia_externa == "Bajista" && lvflag == "2")
    {
       //Print("VGTendencia_externa: ",VGTendencia_externa, " lvflag : ",lvflag, " name : ", name );
       ObjectSetDouble(0, name, OBJPROP_PRICE,0, lvresistencia);    
       ObjectSetDouble(0, name, OBJPROP_PRICE,1, lvsoporte);    
    }

    
    ObjectSetInteger(0, name, OBJPROP_TIME,0, hora_inicio);
    ObjectSetInteger(0, name, OBJPROP_TIME,1, hora_final);
    
    fibo(lvflag);
    
    // Añadir etiqueta informativa
    //ObjectCreate(0, "Fractal_Label", OBJ_LABEL, 0, 0, 0);
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_XDISTANCE, 10);
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_YDISTANCE, 20);
    //ObjectSetString(0, "Fractal_Label", OBJPROP_TEXT, "Fractales 10 velas (5+5)");
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_COLOR, clrWhite);
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_FONTSIZE, 10);
    //ObjectSetInteger(0, "Fractal_Label", OBJPROP_BACK, false);
}


//+------------------------------------------------------------------+
//| Función para monitorear rectángulos FVG y alertar cuando el      |
//| precio alcanza sus bordes                                        |
//+------------------------------------------------------------------+
void CheckFVGAlerts(ENUM_TIMEFRAMES lv_timeframe)
{
 
    double high1 = iHigh(_Symbol, lv_timeframe, 1 + 2); // Vela 1 (más antigua)
    double low1  = iLow(_Symbol,  lv_timeframe, 1 + 2);
    double high3 = iHigh(_Symbol, lv_timeframe, 1);    // Vela 3 (más reciente)
    double low3  = iLow(_Symbol,  lv_timeframe, 1);
    
    datetime fecha_caducidad_order = TimeCurrent() + 30 * 60 ;//  30 son los minutos - minimo acepta 2 minutos 120 segundos
    
           // Calcular el punto medio (50%)
    //VGMidPrice = VGResistencia + (VGSoporte - VGResistencia) / 2.0;

   if ((VGHoraNewYork.hour >= 19 &&  VGHoraNewYork.hour <= 23) || (VGHoraNewYork.hour >= 01 && VGHoraNewYork.hour <= 10)) //|| VGHoraNewYork.hour == 14 
      //|| VGHoraNewYork.hour >= 20 && VGHoraNewYork.hour <= 22 )

  {  
      if (VGmodelo2022 == false)
      {
          //if (VGTendencia_interna == "Alcista" && Bid < VGMidPrice )
          //   Print("Posible compra...!!!", " VGfibo_nivel_value_interna :",VGfibo_nivel_value_interna );
          if (high1 < low3 && VGTendencia_interna == "Alcista" && high1 < VGMidPrice)// && VGvalor_fractal_alto > high1)// && VGTendencia_externa == "Alcista")// && VGTendencia_interna == "Bajista") //Alcista 
          {
            //Print( " FVG Alcista : ", " VGvalor_fractal_alto :", VGvalor_fractal_alto );
            //double lot = CalculateLotSize(VGResistencia, VGSoporte , 1 ); // porcentajeRiesgo1); //calcular el tamano del lote  con 1% de riesgo
            //MiTrade.Buy(lot,_Symbol, Bid, VGvalor_fractal_bajo,0,"Modelo 2022_ " + lv_timeframe);//Con Stop Loss
            //MiTrade.BuyLimit(lot,VGvalor_fractal_alto,_Symbol, VGvalor_fractal_bajo,0,ORDER_TIME_SPECIFIED,fecha_caducidad_order,"Modelo 2022_ " + lv_timeframe);//Con Stop Loss
                
            //MiTrade.BuyLimit(lot,low3,_Symbol, VGSoporte,VGResistencia,ORDER_TIME_SPECIFIED,fecha_caducidad_order,"Modelo 2022_ " + lv_timeframe);//Con Stop Loss
          }
          if (low1 > high3 && VGTendencia_interna == "Bajista" && low1 > VGMidPrice)// &&  VGvalor_fractal_bajo < low1)// && VGTendencia_externa == "Bajista")// && VGTendencia_interna == "Alcista") //bajista 
          {
            //Print( " FVG Bajista : ", " VGvalor_fractal_bajo :", VGvalor_fractal_bajo );
            //double lot = CalculateLotSize(VGResistencia, VGSoporte, 1 ); // porcentajeRiesgo1); //calcular el tamano del lote  con 1% de riesgo
            //MiTrade.Sell(lot,_Symbol,Bid,VGvalor_fractal_alto,0,"Modelo 2022_" + lv_timeframe);
            //MiTrade.SellLimit(lot,VGvalor_fractal_bajo,_Symbol,VGvalor_fractal_alto,0,ORDER_TIME_SPECIFIED,fecha_caducidad_order,"Modelo 2022_" + lv_timeframe);
            //MiTrade.SellLimit(lot,high3,_Symbol,VGResistencia,VGSoporte,ORDER_TIME_SPECIFIED,fecha_caducidad_order,"Modelo 2022_" + lv_timeframe);
          }
     }  
   } 
}


void samurai()
{

   //DrawMacro_Session_Lunch(90);

   datetime newYorkTime = GetNewYorkTime();
   MqlDateTime horaNewYork;
   TimeToStruct (newYorkTime,horaNewYork);

    // Configuración de parámetros
    string rectName = "Samurai_rectangulo_" + horaNewYork.year + horaNewYork.mon + horaNewYork.day + horaNewYork.hour;
    datetime startTime; 
    datetime endTime;
    double high, low;
    color textColor = clrWhite; // Puedes cambiar el color
    int rectWidth = 1; // Grosor de la línea
    
    //Print("VGminutos_noticias samurai : ",VGminutos_noticias);
    
    //if(VGminutos_noticias > 0 && VGminutos_noticias < 60)
    //   rectColor = clrRed;

   
    if(ObjectFind(0, rectName) >= 0)// Si existe inicia el proceso para ejecutar la estrategia
    {
       double valor_alto_samurai = ObjectGetDouble(0, rectName, OBJPROP_PRICE,1);
       double valor_bajo_samurai = ObjectGetDouble(0, rectName, OBJPROP_PRICE,0);
       endTime = ObjectGetInteger(0, rectName, OBJPROP_TIME,1);
       double valor_alto_vela_anterior = iHigh(_Symbol,PERIOD_M1,1);
       double valor_bajo_vela_anterior = iLow(_Symbol,PERIOD_M1,1);
       color lvcolor = ObjectGetInteger(0, rectName, OBJPROP_COLOR);

       double lot = CalculateLotSize(VGMinimo1, VGMaximo2, 100 ); // porcentajeRiesgo1); //calcular el tamano del lote  con 1% de riesgo

       // 1. Verifico noticias u otro motivo
       //Print("endTime:",endTime, " TimeCurren : ",TimeCurrent());
       if ( endTime < TimeCurrent() )
       {
          //Print(" se cancela por que ya termino el tiempo endTime:",endTime, " TimeCurren : ",TimeCurrent());
          return; //se cancela por que ya pasaron mas de 45 minutos
       }   
       //2- Verifico si ya se activo la compra o venta
       if (VGsamurai == true)
           return;
           
       //3. Verifico el inpumbral de la ultima vela   
       if( Bid >  valor_alto_samurai || Bid < valor_bajo_samurai)
       {
          VGumbral = 0.8;
          AlarmavelaZB();
       }    
       if (VGvelasamurai == false)
           return;
 
        //4 verifico que no estemos muy distantes de los extremos 
        double lvpips = CalculateMovementAndProfit(valor_alto_samurai,Bid,0);
        Print("lvpips: ",lvpips);
        if (lvpips > 50 || lvpips < -50)
           return;
               
       //5- Verifico si el precio de apertura  es mayor o menor al rango
       if(iOpen(_Symbol,PERIOD_M1,1) > valor_alto_samurai && valor_alto_vela_anterior > valor_alto_samurai ) // Inicio compra
       {
            //MiTrade.Buy(lot,_Symbol,Bid,valor_bajo_vela_anterior,0,"Samurai"); //Con Stop Loss
            VGsamurai = true;
       }  
       
       if(iOpen(_Symbol,PERIOD_M1,1) < valor_bajo_samurai && valor_bajo_vela_anterior < valor_bajo_samurai ) // Inicio venta
       {
            //MiTrade.Sell(lot, _Symbol,Ask,valor_alto_vela_anterior,0,"Samurai");//Con Stop Loss
            VGsamurai = true;
       }
       
      return;
    }


   //VGsamurai = false;
   
   if (horaNewYork.hour == 08 && horaNewYork.min == 11 )
   {

      if(VGminutos_noticias > 0 && VGminutos_noticias < 60)
          textColor = clrRed;
      
      high = iHigh(_Symbol, PERIOD_M10, 1);
      low = iLow(_Symbol, PERIOD_M10, 1);
      
       
      double lvpips = CalculateMovementAndProfit(high,low,0);
      string samurai_pips  =  DoubleToString(lvpips,0) +" Pips" ;
      
       samurai_pips  =   "Samurai : " + DoubleToString(lvpips,0) + " Pips";
       
       // Crear el rectángulo
       //Print("Inicia samuray : ", " Con mecha : ",samurai_pips " samurai_pips_cuerpo :",samurai_pips_cuerpo);
       
       startTime = iTime(_Symbol,PERIOD_M10,1);
       endTime = startTime + 45*60;
       
       ObjectCreate(0, rectName, OBJ_RECTANGLE, 0, startTime, low, endTime, high);
       ObjectSetInteger(0, rectName, OBJPROP_COLOR, clrGray);
       ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
       ObjectSetInteger(0, rectName, OBJPROP_FILL, false); // Rectángulo sin relleno
       //ObjectSetInteger(0, rectName, OBJPROP_BACK, true); // Se queda en el fondo del gráfico
       ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, true); // Se queda en el fondo del gráfico

       //if(rectColor == clrRed)
       //{
       //  ObjectSetString(0, rectName, OBJPROP_TEXT, "Se cancela por noticias");
       //}
       ////ObjectSetString(0,rectName,OBJPROP_TEXT, samurei_pips);       
       
       string textName = "Samurai_text_" + horaNewYork.year + horaNewYork.mon + horaNewYork.day + horaNewYork.hour;
       int lvfontsize = 8 ;
       if (textColor == clrRed)
       {
         lvfontsize = 6;
         samurai_pips = samurai_pips + " HOY HAY NOTICIAS "; 
       }
       ObjectCreate(0, textName, OBJ_TEXT, 0, endTime, high);
       ObjectSetInteger(0, textName, OBJPROP_COLOR, clrWhite);
       ObjectSetString(0, textName, OBJPROP_TEXT, samurai_pips);
       ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, true); // Se queda en el fondo del gráfico
       ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, lvfontsize); // Tamano fuente
       ObjectSetInteger(0, textName, OBJPROP_ANCHOR, ANCHOR_RIGHT_LOWER); 
       Print("Rectángulo dibujado en la vela de 10m de las 8:00 AM", "startTime :",startTime, "endTime :",endTime, " Minutos noticia :", VGminutos_noticias);

       VGsamurai = false;
 
   }    
}


//+------------------------------------------------------------------+
//| Función para verificar si una vela es un Rejection Block Alcista (Bullish)
//+------------------------------------------------------------------+
// Parameters:
//   symbol_name: Símbolo a analizar (ej. _Symbol)
//   timeframe: Timeframe a analizar (ej. _Period)
//   shift: Índice de la vela a analizar (0 para la actual, 1 para la anterior, etc.)
//   min_wick_body_ratio: Relación mínima entre la mecha y el cuerpo para considerar un Rejection Block.
// Returns:
//   true si es un Rejection Block Alcista, false en caso contrario.
//+------------------------------------------------------------------+
void IsBullishRejectionBlock(ENUM_TIMEFRAMES timeframe, int shift, double min_wick_body_ratio = WICK_BODY_RATIO_THRESHOLD)
{


    // Obtener precios de la vela
    double open  = iOpen(_Symbol, timeframe, shift);
    double high  = iHigh(_Symbol, timeframe, shift);
    double low   = iLow(_Symbol, timeframe, shift);
    double close = iClose(_Symbol, timeframe, shift);

    // Calcular longitud del cuerpo
    double body = MathAbs(open - close);

    // Calcular longitud de la mecha inferior
    double lowerWick = MathMin(open, close) - low;

    // Calcular longitud de la mecha superior
    double upperWick = high - MathMax(open, close);

    // Condición para un Rejection Block Alcista:
    // 1. La vela debe ser alcista (cierre > apertura) O un doji/muy pequeño cuerpo bajista.
    // 2. La mecha inferior debe ser significativamente más larga que el cuerpo.
    // 3. La mecha inferior debe ser considerablemente más larga que la mecha superior.
    
    // Un pequeño cuerpo no necesariamente significa un doji exacto, puede ser una vela alcista con cuerpo pequeño.
    bool isBullishBody = (close >= open); 
    
    // Usamos el tamaño en puntos para comparar con el cuerpo
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Si el cuerpo es muy pequeño (casi un doji), lo tratamos de forma especial
    // Este valor de 10 pips es un ejemplo, ajústalo.
    double dojiThreshold = 10 * point; 
    string mensaje ;
    
    if (body < dojiThreshold) // Si es un doji o un cuerpo muy pequeño
    {
        // Para dojis, la mecha inferior debe ser claramente dominante
        if (lowerWick > upperWick * 2 && lowerWick > min_wick_body_ratio * dojiThreshold) 
        {
            if (timeframe == PERIOD_M15)
            {
                //Print(" Se detecto Bullish rejection block  en 15 minutos");
                mensaje = " Se detecto Bullish rejection block  en 15 minutos";
            }
            if (timeframe == PERIOD_H1)
            {
                //Print(" Se detecto Bullish rejection block  en una hora");
                mensaje = " Se detecto Bullish rejection block  en una hora";
            }
            if (timeframe == PERIOD_H4)
            {
                //Print(" Se detecto Bullish rejection block  en 4 horas");
                mensaje = " Se detecto Bullish rejection block  en 4 horas";
            }
            Print(mensaje);
        }
    }
    else // Para velas con cuerpo discernible
    {
        if (isBullishBody &&          // Si la vela es alcista o un doji (cierre >= apertura)
            lowerWick > min_wick_body_ratio * body && // Mecha inferior >> cuerpo
            lowerWick > upperWick * 2)                 // Mecha inferior >> mecha superior
        {
            if (timeframe == PERIOD_M15)
            {
                //Print(" Se detecto Bullish rejection block  en 15 minutos");
                mensaje = " Se detecto Bullish rejection block  en 15 minutos";
            }
            if (timeframe == PERIOD_H1)
            {
                //Print(" Se detecto Bullish rejection block  en una hora");
                mensaje = " Se detecto Bullish rejection block  en una hora";
            }
            if (timeframe == PERIOD_H4)
            {
                //Print(" Se detecto Bullish rejection block  en 4 horas");
                mensaje = " Se detecto Bullish rejection block  en 4 horas";
            }
            Print(mensaje);
        }
    }

}

//+------------------------------------------------------------------+
//| Función para verificar si una vela es un Rejection Block Bajista (Bearish)
//+------------------------------------------------------------------+
void IsBearishRejectionBlock(ENUM_TIMEFRAMES timeframe, int shift, double min_wick_body_ratio = WICK_BODY_RATIO_THRESHOLD)
{

    // Obtener precios de la vela
    double open  = iOpen(_Symbol, timeframe, shift);
    double high  = iHigh(_Symbol, timeframe, shift);
    double low   = iLow(_Symbol, timeframe, shift);
    double close = iClose(_Symbol, timeframe, shift);

    // Calcular longitud del cuerpo
    double body = MathAbs(open - close);

    // Calcular longitud de la mecha inferior
    double lowerWick = MathMin(open, close) - low;

    // Calcular longitud de la mecha superior
    double upperWick = high - MathMax(open, close);

    // Condición para un Rejection Block Bajista:
    // 1. La vela debe ser bajista (cierre < apertura) O un doji/muy pequeño cuerpo alcista.
    // 2. La mecha superior debe ser significativamente más larga que el cuerpo.
    // 3. La mecha superior debe ser considerablemente más larga que la mecha inferior.

    bool isBearishBody = (close <= open); 
    
    double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    double dojiThreshold = 10 * point; 
    
    string mensaje;

    //Print(" dojiThreshold :", dojiThreshold, " body :",body);
    
    if (body < dojiThreshold) // Si es un doji o un cuerpo muy pequeño
    {
        // Para dojis, la mecha superior debe ser claramente dominante
        if (upperWick > lowerWick * 2 && upperWick > min_wick_body_ratio * dojiThreshold)
        {
            if (timeframe == PERIOD_CURRENT)
            {
                //Print(" Se detecto Bearish rejection block  en ", _Period);
                mensaje = " Se detecto Bearish rejection block  en " + _Period;
            }
            if (timeframe == PERIOD_M15)
            {
                //Print(" Se detecto Bearish rejection block  en 15 minutos");
                mensaje = " Se detecto Bearish rejection block  en 15 minutos";
            }
            if (timeframe == PERIOD_H1)
            {
                //Print(" Se detecto Bearish rejection block  en una hora");
                mensaje = " Se detecto Bearish rejection block  en una hora";
            }
            if (timeframe == PERIOD_H4)
            {
                //Print(" Se detecto Bearish rejection block  en 4 horas");
                mensaje = " Se detecto Bearish rejection block  en 4 horas";
            }
            Print(mensaje);
        }
    }
    else // Para velas con cuerpo discernible
    {
        if (isBearishBody &&          // Si la vela es bajista o un doji (cierre <= apertura)
            upperWick > min_wick_body_ratio * body && // Mecha superior >> cuerpo
            upperWick > lowerWick * 2)                 // Mecha superior >> mecha inferior
        {
            if (timeframe == PERIOD_CURRENT)
            {
                //Print(" Se detecto Bearish rejection block  en ", _Period);
                mensaje = " Se detecto Bearish rejection block  en " + _Period;
            }
            if (timeframe == PERIOD_M15)
            {
                //Print(" Se detecto Bearish rejection block  en 15 minutos");
                mensaje = " Se detecto Bearish rejection block  en 15 minutos";
            }
            if (timeframe == PERIOD_H1)
            {
                //Print(" Se detecto Bearish rejection block  en una hora");
                mensaje = " Se detecto Bearish rejection block  en una hora";
            }
            if (timeframe == PERIOD_H4)
            {
                //Print(" Se detecto Bearish rejection block  en 4 horas");
                mensaje = "Se detecto Bearish rejection block  en 4 horas";
            }
            Print(mensaje);
        }
    }
}

//+------------------------------------------------------------------+
//|                                              GetPricesNY5PM.mq5  |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "Your Website"
#property version   "1.00"

// Estructura para almacenar los resultados (High y Low) por cada día
struct DailyPriceRange
{
    datetime Date;
    double   HighestPrice;
    double   LowestPrice;
};

//+------------------------------------------------------------------+
//| Helper function to determine New York's UTC offset for a given time
//| Simplified DST check: Assumes EDT from April to October inclusive.
//| This is a simplification and may not be 100% accurate for all DST transitions.
//+------------------------------------------------------------------+
int GetNewYorkUTCOffset(datetime checkTime)
{
    MqlDateTime dt_struct;
    TimeToStruct(checkTime, dt_struct);

    // New York DST (EDT, UTC-4) typically runs from second Sunday in March
    // to first Sunday in November.
    // Simplified assumption: April (month 4) to October (month 10) inclusive is EDT.
    if (dt_struct.mon >= 4 && dt_struct.mon <= 10)
    {
        return -4 * 3600; // EDT (UTC-4) in seconds
    }
    else
    {
        return -5 * 3600; // EST (UTC-5) in seconds
    }
}

//+------------------------------------------------------------------+
//| ALTERNATIVA: Función para calcular el offset UTC del bróker si MQL_TIME_ZONE_OFFSET falla.
//| (Menos precisa que MQLInfoInteger(MQL_TIME_ZONE_OFFSET) pero funcional como fallback)
//+------------------------------------------------------------------+
long GetBrokerUTCOffsetAlternative()
{
    // Este método asume que TimeCurrent() devuelve la hora UTC del servidor.
    // Compara TimeCurrent() con la hora de apertura de la última barra (rates[0].time),
    // que está en la zona horaria local del bróker.
    
    MqlRates last_bar_rates[];
    // Intentamos copiar la última barra del timeframe M1 para mayor granularidad.
    if (CopyRates(_Symbol, PERIOD_M1, 0, 1, last_bar_rates) == 1)
    {
        datetime server_utc_time = TimeCurrent(); // Hora actual del servidor (generalmente UTC)
        datetime last_bar_broker_time = last_bar_rates[0].time; // Hora de apertura de la última barra (hora del bróker)

        // Calcula la diferencia en segundos
        long diff_seconds = last_bar_broker_time - server_utc_time;
        
        // Redondea la diferencia a la hora más cercana, ya que los offsets son en horas completas.
        // Esto ayuda a mitigar pequeñas discrepancias debido a latencia o la forma en que se actualizan los tiempos.
        long offset_hours = MathRound((double)diff_seconds / 3600.0);
        return offset_hours * 3600; // Devuelve el offset en segundos
    }
    
    Print("ERROR: No se pudo determinar el offset UTC del bróker con el método alternativo. Asumiendo 0 (UTC).");
    return 0; // Si no se puede determinar, asume UTC (offset 0) como fallback
}


//+------------------------------------------------------------------+
//| Function to get the highest and lowest prices within 5 PM to 6 PM NY time
//| for the last N days.
//+------------------------------------------------------------------+
// Parameters:
//   days_back_count: Number of past days to look back (e.g., 3).
//   timeframe_to_use: Timeframe for the price data (e.g., PERIOD_M5, PERIOD_M15).
//                     It's crucial to use a timeframe small enough to capture the 1-hour range effectively.
//   symbol_name: The symbol to get prices for (e.g., _Symbol).
//   results: An array to store the DailyPriceRange results.
// Returns:
//   true if data was successfully retrieved for at least one day, false otherwise.
//+------------------------------------------------------------------+
bool GetNY5to6PMRanges(int days_back_count, ENUM_TIMEFRAMES timeframe_to_use, string symbol_name, DailyPriceRange &results[])
{
    ArrayResize(results, 0); // Clear previous results

    // OBTENIENDO EL OFFSET DEL BRÓKER:
    // Preferimos MQLInfoInteger(MQL_TIME_ZONE_OFFSET), pero usamos la alternativa si ese da error.
    // Si estás recibiendo "undeclared identifier", esta es la sección que necesitas modificar.
    // Opción 1 (Estándar MQL5 - recomendado si tu MT5 lo soporta):
    // long broker_utc_offset_sec = MQLInfoInteger(MQL_TIME_ZONE_OFFSET); 
    
    // Opción 2 (Alternativa si MQL_TIME_ZONE_OFFSET no funciona en tu MT5):
    long broker_utc_offset_sec = GetBrokerUTCOffsetAlternative(); // Usa esta línea en su lugar
    
    Print("Offset UTC del bróker (en segundos): ", broker_utc_offset_sec);


    // Get current server time
    datetime current_server_time = TimeCurrent();

    // Rates array to store historical data
    MqlRates rates[];

    for (int i = 0; i < days_back_count; i++)
    {
        // 1. Calculate the target date for the current day in the loop
        datetime current_day_start = current_server_time - i * 24 * 3600; // Start of the current day being processed
        
        MqlDateTime dt_struct_day;
        TimeToStruct(current_day_start, dt_struct_day);
        
        // Ensure we are working with the start of the day (00:00:00) for consistent date calculations
        dt_struct_day.hour = 0;
        dt_struct_day.min = 0;
        dt_struct_day.sec = 0;
        datetime normalized_day_start = StructToTime(dt_struct_day);

        // 2. Determine New York's UTC offset for this specific date (considering DST)
        int ny_utc_offset_sec = GetNewYorkUTCOffset(normalized_day_start); // Pass the normalized date for DST check

        // 3. Calculate 5 PM NY Local Time (in Broker's Server Time)
        // Convert NY 5 PM Local Time to UTC first, then to Broker's Server Time
        datetime ny_5pm_utc = normalized_day_start + (17 * 3600) - ny_utc_offset_sec; // NY Local 17:00 -> UTC
        datetime ny_5pm_broker_time = ny_5pm_utc + broker_utc_offset_sec; // UTC -> Broker Time

        // 4. Calculate 6 PM NY Local Time (in Broker's Server Time)
        datetime ny_6pm_utc = normalized_day_start + (18 * 3600) - ny_utc_offset_sec; // NY Local 18:00 -> UTC
        datetime ny_6pm_broker_time = ny_6pm_utc + broker_utc_offset_sec; // UTC -> Broker Time
        
        // Ensure that the target time range has passed
        if (ny_5pm_broker_time >= current_server_time)
        {
             Print("Skipping future 5-6 PM NY range for day ", i, ": ", TimeToString(ny_5pm_broker_time, TIME_DATE|TIME_SECONDS));
             continue; 
        }

        // 5. Calculate the total number of bars needed to cover the range
        int total_bars = Bars(symbol_name, timeframe_to_use);
        if (total_bars <= 0)
        {
            Print("No bars available for ", symbol_name, " on ", EnumToString(timeframe_to_use));
            continue;
        }

        // Find the bar index for the start time of the range (5 PM NY Broker Time)
        // We look for the bar *at or after* the start time
        int start_idx = iBarShift(symbol_name, timeframe_to_use, ny_5pm_broker_time, true);

        // Find the bar index for the end time of the range (6 PM NY Broker Time)
        // We look for the bar *at or before* the end time.
        int end_idx = iBarShift(symbol_name, timeframe_to_use, ny_6pm_broker_time, false);
        
        // Validation of indices
        if (start_idx == -1 || end_idx == -1) // One or both times not found in history
        {
            Print("Could not find start or end bar for day ", i, " (NY 5-6PM). Start time: ", TimeToString(ny_5pm_broker_time, TIME_DATE|TIME_SECONDS), ", End time: ", TimeToString(ny_6pm_broker_time, TIME_DATE|TIME_SECONDS));
            continue;
        }
        
        // Make sure start_idx is always less than or equal to end_idx for CopyRates,
        // and adjust to cover the desired range.
        // CopyRates takes (start_index, count), where start_index is the older bar.
        // So we need to copy from end_idx up to start_idx.
        int count_to_copy = start_idx - end_idx + 1;

        if (count_to_copy <= 0)
        {
            Print("No valid bars in 5-6 PM NY range for day ", i, ". Calculated count: ", count_to_copy);
            continue;
        }

        // 6. Copy rates for the identified range
        int copied_bars = CopyRates(symbol_name, timeframe_to_use, end_idx, count_to_copy, rates);
        
        if (copied_bars != count_to_copy)
        {
            Print("Warning: Could not copy all expected bars for day ", i, ". Expected: ", count_to_copy, ", Copied: ", copied_bars, ". Error: ", GetLastError());
            if (copied_bars <= 0) continue; // Skip if nothing was copied
        }

        // 7. Find the highest high and lowest low within the copied rates
        double highest = -DBL_MAX; // Initialize with lowest possible double value
        double lowest  = DBL_MAX;  // Initialize with highest possible double value

        for (int k = 0; k < copied_bars; k++)
        {
            if (rates[k].high > highest)
            {
                highest = rates[k].high;
            }
            if (rates[k].low < lowest)
            {
                lowest = rates[k].low;
            }
        }
        
        // 8. Store the results
        int current_results_size = ArraySize(results);
        ArrayResize(results, current_results_size + 1);
        results[current_results_size].Date = normalized_day_start; // Store the date of the day
        results[current_results_size].HighestPrice = highest;
        results[current_results_size].LowestPrice = lowest;
    }

    return ArraySize(results) > 0; // Return true if any results were collected
}

void strategiajpyh20()
{
   datetime newYorkTime = GetNewYorkTime();
   MqlDateTime horaNewYork;
   TimeToStruct (newYorkTime,horaNewYork);
   
   if(horaNewYork.hour == 20)
   {
      //Print( "inicia la estrategia...");
   }

}


//+------------------------------------------------------------------+
//| Función: DetectImmediateRebalancePattern                         |
//| Descripción: Verifica si se cumple el patrón "immediate rebalance"|
//|              en un conjunto de 3 velas:                           |
//|              "el bajo de la vela 3 debe apenas sobrepasar        |
//|              el alto de la vela 1".                               |
//| Parámetros:                                                      |
//|   index      - Índice de la vela más reciente del patrón (Vela 3). |
//|                (0 es la barra actual, 1 es la barra anterior).    |
//| Retorna: true si se detecta el patrón, false en caso contrario.  |
//+------------------------------------------------------------------+
void DetectImmediateRebalancePattern(ENUM_TIMEFRAMES lv_timeframes)
{
   // Necesitamos al menos 3 barras para este patrón:
   // Vela 1: index + 2
   // Vela 2: index + 1
   // Vela 3: index
   
   return; //para desactivar
   
   double ImmediateRebalanceTolerancePoints = 0; // Valor por defecto: 5 puntos. AJUSTA ESTO.

   //// --- Obtenemos los precios de las velas relevantes --- despues de terminar la vela
   //double high_vela1 = iHigh(_Symbol, lv_timeframes, 1); // Alto de la Vela 1
   //double high_vela3 = iHigh(_Symbol, lv_timeframes, 3); // Alto de la Vela 1
   //double low_vela1  = iLow(_Symbol, lv_timeframes, 1);     // Bajo de la Vela 3
   //double low_vela3  = iLow(_Symbol, lv_timeframes, 3);     // Bajo de la Vela 3
   

   // --- Obtenemos los precios de las velas relevantes --- en la vela actual
   double high_vela1 = iHigh(_Symbol, lv_timeframes, 0); // Alto de la Vela 1
   double high_vela3 = iHigh(_Symbol, lv_timeframes, 2); // Alto de la Vela 1
   double low_vela1  = iLow(_Symbol, lv_timeframes, 0);     // Bajo de la Vela 3
   double low_vela3  = iLow(_Symbol, lv_timeframes, 2);     // Bajo de la Vela 3

   
   // --- Convertir la tolerancia de puntos a valor de precio ---
   // _Point es el tamaño de un punto para el símbolo actual (ej. 0.00001 para EURUSD)

   string lv_nametf = TimeframeToString(lv_timeframes);
   
   string ir_name = "ZB_ImmediateRebalance " + lv_nametf + " " + iTime(_Symbol,lv_timeframes,3);
   
   if(ObjectFind(0,ir_name) == 0)
     return;
   string lv_mensaje;
   
   //if (lv_timeframes == PERIOD_M1)
   //   ImmediateRebalanceTolerancePoints = 0;
      
    //Print (" VGcomodin : ",VGcomodin , " 0.8 * VGcomodin :  ",VGcomodin * 0.8);  
   if (lv_timeframes > PERIOD_M1 && lv_timeframes <= PERIOD_M3)
      ImmediateRebalanceTolerancePoints = 0 * VGcomodin;
      
   if (lv_timeframes > PERIOD_M3 && lv_timeframes <= PERIOD_M10)
      ImmediateRebalanceTolerancePoints = 0.3 * VGcomodin ;
      
   if (lv_timeframes >  PERIOD_M10 && lv_timeframes <= PERIOD_H1)
      ImmediateRebalanceTolerancePoints = 1 * VGcomodin;
      

   if (lv_timeframes >  PERIOD_H1 && lv_timeframes <= PERIOD_H4)
      ImmediateRebalanceTolerancePoints = 1.5 * VGcomodin ;

   if (lv_timeframes >  PERIOD_H4 && lv_timeframes <= PERIOD_H12)
      ImmediateRebalanceTolerancePoints = 5.0 * VGcomodin;

   if (lv_timeframes >  OBJ_PERIOD_H12 )
      ImmediateRebalanceTolerancePoints = 8.0 * VGcomodin;
      

   double tolerance_value = ImmediateRebalanceTolerancePoints * _Point;


   //Print("ImmediateRebalanceTolerancePoints :",ImmediateRebalanceTolerancePoints);
   
   //Print(" high_vela1 :",high_vela1," low_vela3 :",low_vela3, " tolerance_value :",tolerance_value);
   
   //Print("   Diferencia Bajista : ", DoubleToString(high_vela1 - low_vela3, _Digits), " (Tolerancia: ", DoubleToString(tolerance_value, _Digits), ") "+ lv_tf);
   //Print("   Diferencia Alcista : ", DoubleToString(high_vela3 - low_vela1, _Digits), " (Tolerancia: ", DoubleToString(tolerance_value, _Digits), ")"+ lv_tf);

   // --- Aplicar la condición: "bajo de la vela 3 debe apenas sobrepasar el alto de la vela 1" ---
   // 1. "debe sobrepasar": low_vela3 > high_vela1
   // 2. "apenas": la diferencia (low_vela3 - high_vela1) debe ser menor o igual a nuestra tolerancia.
   if (low_vela3 < high_vela1 && (high_vela1 - low_vela3) <= tolerance_value)
   {
       if(!ObjectCreate(0, ir_name, OBJ_TREND, 0, iTime(_Symbol,lv_timeframes,3) , high_vela1))
       {
           Print("Error al crear la línea de tendencia: ", GetLastError());
           return;
       }
       ObjectSetInteger(0, ir_name, OBJPROP_COLOR, clrRed);
       ObjectSetInteger(0, ir_name, OBJPROP_WIDTH, 1);
       ObjectSetInteger(0, ir_name, OBJPROP_STYLE, STYLE_DOT);
       ObjectSetInteger(0, ir_name, OBJPROP_RAY, false); // Línea finita (no infinita)
       ObjectSetInteger(0, ir_name, OBJPROP_SELECTABLE, true); 
       ObjectSetInteger(0, ir_name, OBJPROP_TIME,1,iTime(_Symbol,lv_timeframes,0)); 
       //ObjectSetInteger(0, ir_name ,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M5|OBJ_PERIOD_M15);
       
      if ( (high_vela1 - low_vela3) == 0 )
      {
         lv_mensaje = ""\" Perfect Price Bajista !!! " + _Symbol + " " + lv_nametf +  \"";
         //ObjectSetString(0, ir_name, OBJPROP_TEXT, "PPD "+ lv_nametf);
      }
      else
      {
         lv_mensaje =  ""\" Immediate Rebalance Bajista !!! "  + _Symbol + " " + lv_nametf + " " + DoubleToString( (high_vela1 - low_vela3),2) + \"";
         //ObjectSetString(0, ir_name, OBJPROP_TEXT, "IR "+ lv_nametf);
      }

      //SendNotification(LVPosibleTrade);
      //Alert(LVPosibleTrade);
      //TextToSpeech("\"Immediate Rebalance Bajista " +  _Symbol + lv_tf +\"");
      //textohablado(lv_mensaje,false);
      ContadorSonido = 1;
      //Print("Patrón 'Immediate Rebalance Bajista ' detectado en : ",lv_tf);
      //Print("   Vela 1 (Alto): ", DoubleToString(high_vela1, _Digits));
      //Print("   Vela 3 (Bajo): ", DoubleToString(low_vela3, _Digits));
      //Print("   Diferencia: ", DoubleToString(high_vela1 - low_vela3, _Digits), " (Tolerancia: ", DoubleToString(tolerance_value, _Digits), ")");
   }
         
   if (high_vela3  > low_vela1 && (high_vela3 - low_vela1) <= tolerance_value)
   {
       if(!ObjectCreate(0, ir_name, OBJ_TREND, 0, iTime(_Symbol,lv_timeframes,2) , low_vela1))
       {
           Print("Error al crear la línea de tendencia: ", GetLastError());
           return;
       }
       ObjectSetInteger(0, ir_name, OBJPROP_COLOR, clrBlue);
       ObjectSetInteger(0, ir_name, OBJPROP_WIDTH, 1);
       ObjectSetInteger(0, ir_name, OBJPROP_STYLE, STYLE_DOT);
       ObjectSetInteger(0, ir_name, OBJPROP_RAY, false); // Línea finita (no infinita)
       ObjectSetInteger(0, ir_name, OBJPROP_SELECTABLE, true); 
       ObjectSetInteger(0, ir_name, OBJPROP_TIME,1,iTime(_Symbol,lv_timeframes,0)); 
       //ObjectSetInteger(0, ir_name ,OBJPROP_TIMEFRAMES, OBJ_PERIOD_M1|OBJ_PERIOD_M2|OBJ_PERIOD_M3|OBJ_PERIOD_M5|OBJ_PERIOD_M10|OBJ_PERIOD_M5|OBJ_PERIOD_M15);

      if ( (low_vela1 - high_vela3) == 0 )
      {
         //lv_mensaje = ""\" Perfect Price Alcista !!! " + _Symbol + " " + lv_nametf + \"";
         //ObjectSetString(0, ir_name, OBJPROP_TEXT, "PPD "+ lv_nametf);
      }
      else
      {
         //lv_mensaje = ""\" Immediate Rebalance Alcista !!! " + _Symbol + " " + lv_nametf + " " + DoubleToString( (high_vela3 - low_vela1),2) + \"";
         //ObjectSetString(0, ir_name, OBJPROP_TEXT, "IR "+ lv_nametf);
      }
      //SendNotification(LVPosibleTrade);
      //Alert(LVPosibleTrade);
      //TextToSpeech("\"Immediate Rebalance Bajista una Vela" +  _Symbol + lv_tf +\"");
      //textohablado(lv_mensaje, false);
      ContadorSonido = 1;

      //Print("Patrón 'Immediate Rebalance Alcista ' detectado en : ",lv_tf);
      //Print("   Vela 1 (Bajo): ", DoubleToString(low_vela1, _Digits));
      //Print("   Vela 3 (Bajo): ", DoubleToString(high_vela3, _Digits));
      //Print("   Diferencia: ", DoubleToString(high_vela3 - low_vela1, _Digits), " (Tolerancia: ", DoubleToString(tolerance_value, _Digits), ")");
   }

}

void textohablado(string  mensaje, bool hablar)

{
   Alert(mensaje); 
   SendNotification(mensaje);
   Print("mensaje :",mensaje);
   //SendNotification(mensaje);   
   if ( MQLInfoInteger(MQL_TESTER))
       return;   
   if (hablar == true)
   {    
      //TextToSpeech(mensaje);
      //SendNotification(mensaje);
   }   
}



//+------------------------------------------------------------------+
//| Detecta CISD (Change In State of Delivery) en la barra 'index'.  |
//| Retorna: 0 (No CISD), 1 (Bullish CISD), 2 (Bearish CISD).        |
//| Asume que la "entrega de precios" es la vela inmediatamente      |
//| anterior (index + 1).                                            |
//+------------------------------------------------------------------+
void CISD()
{
   ObjectsDeleteAll(0,"CISD");   
   return; //quitar para activar
   
   
   
   string object_name;
   datetime object_time;
   int bar_index ;
   for (int j = 1; j < 200; j++)
   {
      object_name = "Fractal_H_5_" + j;
      object_time = ObjectGetInteger(0,object_name,OBJPROP_TIME); // Obtenemos el tiempo del primer punto del objeto
      bar_index = iBarShift(_Symbol, _Period, object_time, true);
      
      //Print("bar_index : ",bar_index, " object_name : ",object_name, " object_time : ",object_time);
      
      for(int i = bar_index; i >= 0; i-- )
      {
         // --- 4. Determinar si la vela es alcista o bajista ---
         double open_price  = iOpen(_Symbol, _Period, i);
         double close_price = iClose(_Symbol, _Period, i);
         
         //Print("i : " ,i);
      
         if (close_price > open_price)
         {
            //Print("La vela en la posición del objeto es ALCISTA.");
            continue;
         }
         if (close_price < open_price)
         {
            //Print("La vela en la posición del objeto es BAJISTA.");
            double price = iOpen(_Symbol,PERIOD_CURRENT,i);
            if (iHigh(_Symbol,PERIOD_CURRENT,1) > price || iHigh(_Symbol,PERIOD_CURRENT,2) > price ||  Bid > price)
               break;
            string name = "CISD_ALTO";
            
            ObjectDelete(0,name);
            
            ObjectCreate(0, name, OBJ_TREND, 0, object_time, price, object_time + 10000 * 60, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASHDOTDOT);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);

            //Print("CISD :", lvcisd);
            j = 200;
            break;
         }
         else
         {
            //Print("La vela en la posición del objeto es DOJI (indecisa) o su precio de apertura y cierre son iguales.");
            continue;
         }  
      }     
   
   }
   
   
   for (int j = 1; j < 200; j++)
   {
      object_name = "Fractal_L_5_" + j;
      object_time = ObjectGetInteger(0,object_name,OBJPROP_TIME); // Obtenemos el tiempo del primer punto del objeto
      bar_index = iBarShift(_Symbol, _Period, object_time, true);
      for(int i = bar_index; i >= 0; i-- )
      {
         // --- 4. Determinar si la vela es alcista o bajista ---
         double open_price  = iOpen(_Symbol, _Period, i);
         double close_price = iClose(_Symbol, _Period, i);
         
         //Print("i : " ,i);
      
         if (close_price < open_price)
         {
            //Print("La vela en la posición del objeto es BAJISTA");
            continue;
         }
         if (close_price > open_price)
         {
            //Print("La vela en la posición del objeto es BAJISTA.");
            double price = iOpen(_Symbol,PERIOD_CURRENT,i);
            if (iLow(_Symbol,PERIOD_CURRENT,1) < price || iLow(_Symbol,PERIOD_CURRENT,2) < price || Bid < price)
               break;
            string name = "CISD_BAJO";
            
            ObjectDelete(0,name);
            
            ObjectCreate(0, name, OBJ_TREND, 0, object_time, price, object_time + 10000 * 60, price);
            ObjectSetInteger(0, name, OBJPROP_COLOR, clrMagenta);
            ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASHDOTDOT);
            ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true);

            //Print("CISD :", lvcisd);
            j = 200;
            break;
         }
         else
         {
            //Print("La vela en la posición del objeto es DOJI (indecisa) o su precio de apertura y cierre son iguales.");
            continue;
         }  
      }     
   }
   
}



//+------------------------------------------------------------------+
//| Función: CalculateDailyLosses                                    |
//| Descripción: Calcula el total de pérdidas realizadas en el día   |
//|              actual para el símbolo del gráfico.                 |
//| Retorna: La suma de todas las pérdidas (un valor negativo).      |
//+------------------------------------------------------------------+
double CalculateDailyLosses()
{
    double total_losses = 0.0; // Variable para acumular las pérdidas
    double total_won = 0.0; // Variable para acumular las pérdidas
    
    // Obtener la hora de inicio del día actual (00:00 del servidor)
    // iTime(NULL, PERIOD_D1, 0) devuelve la hora de apertura de la barra diaria actual.
    datetime today_start_time = iTime(NULL, PERIOD_D1, 0);

    // Seleccionar el historial de operaciones (deals) desde el inicio del día hasta ahora.
    // HistorySelect(from, to) devuelve true si la selección fue exitosa.
    if (!HistorySelect(today_start_time, TimeCurrent()))
    {
        Print("Error al seleccionar el historial de operaciones: ", GetLastError());
        return 0.0; // Devolver 0.0 si hay un error en la selección
    }

    // Obtener el número total de operaciones (deals) en el historial seleccionado
    int deals_count = HistoryDealsTotal();
    
    // Iterar a través de todas las operaciones en el historial seleccionado
    for (int i = 0; i < deals_count; i++)
    {
        // Obtener el ticket (ID) de la operación actual
        ulong deal_ticket = HistoryDealGetTicket(i);
        
        // Obtener el tipo de operación (compra, venta, depósito, etc.)
        long deal_type = HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
        
        // Obtener la ganancia/pérdida de la operación
        double deal_profit = HistoryDealGetDouble(deal_ticket, DEAL_PROFIT);
        
        // Obtener el símbolo de la operación
        string deal_symbol = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);

        // Filtrar las operaciones:
        // 1. Debe ser una operación de compra o venta (no depósitos, retiros, comisiones, etc.).
        // 2. La ganancia/pérdida debe ser negativa (indica una pérdida).
        // 3. El símbolo de la operación debe coincidir con el símbolo del gráfico actual.
        if ((deal_type == DEAL_TYPE_BUY || deal_type == DEAL_TYPE_SELL) && 
            deal_profit < 0 && 
            deal_symbol == _Symbol)
        {
            // Sumar la pérdida al total. deal_profit ya es negativo.
            total_losses += deal_profit;
        }
        else
        {
            total_won += deal_profit;
        }
    }
    double net_profits = total_won - total_losses;
    
    //Print ( "today_start_time : ",today_start_time," total_won : ",DoubleToString(total_won,2)," total_losses :" , DoubleToString(total_losses,2));
    //Print ( "Net Profits : ", DoubleToString(net_profits,2) ); // Devolver el total de pérdidas (será un valor negativo o cero)
    return total_losses;
}


void DrawBuySell(double lvalto, double lvbajo, string namebuysell, color lvcolor, int lvstyle)
{

   //string name_object = namebuysell + VGHoraNewYork.year + VGHoraNewYork.mon + VGHoraNewYork.day + VGHoraNewYork.hour + VGHoraNewYork;
   string name_object;// = namebuysell + lvalto;

   int ObjectExiste = ObjectFind(0,name_object);
   
   double lvprice = 0;      
   int i = 0;   
   if (ObjectExiste < 0)
   {    
      for (i = 1; i < 20; i++)
      {
         if (namebuysell == "Buy_")
         {
            lvprice = lvalto;
            if(lvalto == iHigh(_Symbol,PERIOD_M1,i))
            {
               break;
            }
            else
            {
               continue;
            }
         }
         if (namebuysell == "Sell_")
         {
            lvprice = lvbajo;
            if(lvbajo == iLow(_Symbol,PERIOD_M1,i))
            {
               break;
            }
            else
            {
               continue;
            }
         }
      }
      name_object = namebuysell + lvprice;
      //ObjectCreate(0,name_object,OBJ_RECTANGLE,0,iTime(_Symbol,PERIOD_M1,2),lvalto,iTime(_Symbol,PERIOD_M1,1),lvbajo);
      ObjectCreate(0,name_object,OBJ_TREND,0,iTime(_Symbol,PERIOD_M1,i),lvprice,iTime(_Symbol,PERIOD_M1,1),lvprice);
      ObjectSetInteger(0,name_object,OBJPROP_COLOR,lvcolor);
      ObjectSetInteger(0,name_object,OBJPROP_STYLE,lvstyle);
      ObjectSetInteger(0,name_object,OBJPROP_FILL,false);
      ObjectSetInteger(0,name_object,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,name_object,OBJPROP_TIMEFRAMES,OBJ_PERIOD_M1|OBJ_PERIOD_M3|OBJ_PERIOD_M5);
      //ObjectSetInteger(0,name_object,OBJPROP_SELECTED,true);
   }

}

int CountObjet(string name_objeto)
 {
   int count = 0;
   for(int i = 0; i < ObjectsTotal(0, 0, -1); i++) 
   {
      string name = ObjectName(0, i, 0, -1);
      if(ObjectGetInteger(0, name, OBJPROP_TYPE) == OBJ_RECTANGLE && StringFind(name, name_objeto) == 0) 
        count++;
   }
   return count;
}


void ReglasModelo2022()
{
   //return;

   VGcumplerregla = false;
   if(VGminutos_noticias < 5 && VGminutos_noticias > -5 && VGminutos_noticias != 0 && VGprioridad_noticias == 3)
   {
      VGcumplerregla = false;
      return;
   }
   
   
   
   //VGhighestHigh = iHigh(Symbol(), Time_Frame_M2022, iHighest(Symbol(), Time_Frame_M2022, MODE_HIGH, 90, 0));
   //VGlowestLow = iLow(Symbol(), Time_Frame_M2022, iLowest(Symbol(), Time_Frame_M2022, MODE_LOW, 90, 0));

//1.- Verificar si esta liquidando un PDH o PDL

//2.- Verificar si el precio llego a un FVG

//   VGHTF_Name = TimeframeToString(PERIOD_M15);
//   DrawFVG(PERIOD_M15, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 9);
//
//   VGHTF_Name = TimeframeToString(PERIOD_H1);
//   DrawFVG(PERIOD_H1, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 9);
//
//   VGHTF_Name = TimeframeToString(PERIOD_H4);
//   DrawFVG(PERIOD_H4, Velas_FVG_HTF, Color_Bullish_HTF, Color_Bearist_HTF, 9);
   
   //Print("VGcumplerregla : ",VGcumplerregla);

}

void Bias(ENUM_TIMEFRAMES biastimeframe)
{

   //ENUM_TIMEFRAMES biastimeframe = PERIOD_H4;
   //if (_Period > PERIOD_H4)
   //    biastimeframe = _Period;
   

   double lvhigh              = iHigh(_Symbol,biastimeframe,2);
   double lvlow               = iLow(_Symbol,biastimeframe,2);
   double lvpreviusclose      = iClose(_Symbol,biastimeframe,1);
   double lvpreviushigh       = iHigh(_Symbol,biastimeframe,1);  
   double lvpreviuslow        = iLow(_Symbol,biastimeframe,1);  
   long   lvtime              = iTime(_Symbol,biastimeframe,2);
   double lvbiashigh          = iHigh(_Symbol,biastimeframe,1);
   double lvbiaslow           = iLow(_Symbol,biastimeframe,1);
   
   double vlbias = 0;
   
   color vlcolor = clrGray;
   
   string nametimeframe = TimeframeToString(biastimeframe);
   string name = "Bias : "+ nametimeframe;

   ObjectDelete(0,name);
   
   return; //Para desactivar

   if( lvpreviusclose > lvhigh)
   {
      ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiashigh);
      vlbias = lvbiashigh;
      vlcolor = clrWhite;
   }
   else
   {
      if(lvpreviuslow < lvlow && iOpen(_Symbol,biastimeframe,1) > iClose(_Symbol,biastimeframe,1))
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiaslow);
         vlbias = lvbiaslow;
         vlcolor = clrWhite;
      }   
      else
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiashigh);
         vlbias = lvbiashigh;
         vlcolor = clrWhite;
      
      }
   }
   
   if( lvpreviusclose < lvlow)
   {
      ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiaslow);
      vlbias = lvbiaslow;
   }
   else
   {
      if(lvpreviushigh > lvhigh && iOpen(_Symbol,biastimeframe,1) < iClose(_Symbol,biastimeframe,1) )
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiashigh);
         vlbias = lvbiashigh;
         vlcolor = clrWhite;
      } 
      else
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiaslow);
         vlbias = lvbiaslow;
         vlcolor = clrWhite;
       
      }
      
        
   }
   
   if(vlbias == 0)
   {
      double lvopen  = iOpen(_Symbol,biastimeframe,1);
      double lvclose = iClose(_Symbol,biastimeframe,1);
      
      if(lvopen > lvclose )
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiaslow);
         vlbias = lvbiaslow;
      }
      else
      {
         ObjectCreate(0, name, OBJ_HLINE,0,0,lvbiashigh);
         vlbias = lvbiashigh;
         vlcolor = clrWhite;
      }
   }
   
   if(biastimeframe == PERIOD_W1)
   {
      VGbias_W1 = vlbias;
      VGbias_W1_color = vlcolor;
   }   
   if(biastimeframe == PERIOD_D1)
   {
      VGbias_D1 = vlbias;
      VGbias_D1_color = vlcolor;
   }
   if(biastimeframe == PERIOD_H4)
   {
      VGbias_H4 = vlbias;
      VGbias_H4_color = vlcolor;
   }
   if(biastimeframe == PERIOD_H1)
   {
      VGbias_H4 = vlbias;
      VGbias_H4_color = vlcolor;
   }
   ObjectSetInteger(0, name, OBJPROP_COLOR, vlcolor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DASHDOTDOT);
   ObjectSetString(0, name, OBJPROP_TEXT,name);

}


void Tendencia()
{

   if( VGTendencia_interna_M1 == "Bajista")
   {
      m1Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_M1 == "Alcista")
   {
      m1Btn.ColorBackground(clrBlue);
   }

   if( VGTendencia_interna_M3 == "Bajista")
   {
      m3Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_M3 == "Alcista")
   {
      m3Btn.ColorBackground(clrBlue);
   }


   if( VGTendencia_interna_M15 == "Bajista")
   {
      m15Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_M15 == "Alcista")
   {
      m15Btn.ColorBackground(clrBlue);
   }

   if( VGTendencia_interna_H1 == "Bajista")
   {
      h1Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_H1 == "Alcista")
   {
      h1Btn.ColorBackground(clrBlue);
   }

   if( VGTendencia_interna_H4 == "Bajista")
   {
      h4Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_H4 == "Alcista")
   {
      h4Btn.ColorBackground(clrBlue);
   }


   if( VGTendencia_interna_D1 == "Bajista")
   {
      d1Btn.ColorBackground(clrRed);
   }
   if( VGTendencia_interna_D1 == "Alcista")
   {
      d1Btn.ColorBackground(clrBlue);
   }

}

//+------------------------------------------------------------------+

// Fin de Programa zbbot
//+------------------------------------------------------------------+