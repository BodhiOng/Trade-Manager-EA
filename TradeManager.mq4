//+----------------------------------------------------------------------+
//|                                              TradeManager.mq4     |
//|                                      Copyright 2023, MetaQuotes |
//|                                       https://www.metaquotes.net |
//+----------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes"
#property link      "https://www.metaquotes.net"
#property version   "1.00"
#property strict

// Include standard libraries
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

// Define constants for UI elements
#define BUTTON_BUY      1
#define BUTTON_SELL     2
#define BUTTON_CLOSE_X  3
#define BUTTON_CLOSE_P  4
#define BUTTON_CLOSE_ALL 5
#define BUTTON_CLOSE_BUY 6
#define BUTTON_CLOSE_SELL 7

// UI Element Names
#define EA_Name "Trade Manager"
#define TM_TITLE "Trade Manager"
#define TM_LotSizeLabel "LotSizeLabel"
#define TM_B "TM_B"
#define TM_S "TM_S"
#define TM_X "TM_X"
#define TM_P "TM_P"
#define TM_CA "TM_CA"
#define TM_CB "TM_CB"
#define TM_CS "TM_CS"
#define TM_SLLabel "SLLabel"
#define TM_CSLLabel "CSLLabel"
#define TM_BEPLabel "BEPLabel"
#define TM_TSLabel "TSLabel"
#define TM_LotSizeEdit "LotSizeEdit"
#define TM_SLEdit "SLEdit"
#define TM_CSLEdit "CSLEdit"
#define TM_BEPEdit "BEPEdit"
#define TM_TSEdit "TSEdit"

// UI Element Names as strings for easier use
string g_Title = "Trade Manager";
string g_LotSizeLabel = "LotSizeLabel";
string g_B = "TM_B";
string g_S = "TM_S";
string g_X = "TM_X";
string g_P = "TM_P";
string g_CA = "TM_CA";
string g_CB = "TM_CB";
string g_CS = "TM_CS";
string g_SLLabel = "SLLabel";
string g_CSLLabel = "CSLLabel";
string g_BEPLabel = "BEPLabel";
string g_TSLabel = "TSLabel";
string g_LotSizeEdit = "LotSizeEdit";
string g_SLEdit = "SLEdit";
string g_CSLEdit = "CSLEdit";
string g_BEPEdit = "BEPEdit";
string g_TSEdit = "TSEdit";

// UI Element Text
#define B "BUY"
#define S "SELL"
#define X "X"
#define P "P"
#define CA "CA"
#define CB "CB"
#define CS "CS"
#define SL "SL"
#define CSL "CSL"
#define BEP "BEP"
#define TS "TS"

// Input parameters
input string EA_Settings = "===== EA Settings ====="; // EA Settings
input int Panel_Corner = 0; // Panel Corner
input int Panel_X = 20; // Panel X Position
input int Panel_Y = 20; // Panel Y Position
input color Panel_Color = clrWhite; // Panel Color
input color Button_Color = clrDodgerBlue; // Button Color
input color Text_Color = clrBlack; // Text Color
input int Button_Width = 80; // Button Width
input int Button_Height = 20; // Button Height
input int Field_Width = 60; // Field Width
input int Field_Height = 20; // Field Height
input int Label_Width = 60; // Label Width
input int Label_Height = 20; // Label Height

// Global variables
double g_LotSize = 0.01;
double g_StopLoss = 0.0;
double g_CombinedSL = 0.0;
double g_BreakEven = 0.0;
double g_TrailingStop = 0.0;

// Arrays to store multiple lot sizes
double g_LotSizes[4] = {0.01, 0.01, 0.01, 0.01};

// Global variables for button states
bool g_BuySelected = true;
bool g_SellSelected = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Create UI elements
   CreateTradePanel();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Remove UI elements
   ObjectsDeleteAll(0, "TM_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update UI if needed
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Handle UI events
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // Handle button clicks
      if(sparam == g_B) // Buy button
      {
         double lotSize = StringToDouble(ObjectGetString(0, g_LotSizeEdit, OBJPROP_TEXT));
         OpenBuyOrder(lotSize);
         UpdateButtonColors();
      }
      else if(sparam == g_S) // Sell button
      {
         double lotSize = StringToDouble(ObjectGetString(0, g_LotSizeEdit, OBJPROP_TEXT));
         OpenSellOrder(lotSize);
         UpdateButtonColors();
      }
      else if(sparam == g_X) // Close button
      {
         CloseAllPositions();
      }
      else if(sparam == g_P) // Partial close button (previously %)
      {
         // Partial close positions at 50%
         PartialClosePositions();
         UpdateButtonColors();
      }
      else if(sparam == g_CA) // Close all button
      {
         CloseAllPositions();
      }
      else if(sparam == g_CB) // Close buy button
      {
         CloseBuyPositions(100);
      }
      else if(sparam == g_CS) // Close sell button
      {
         CloseSellPositions(100);
      }
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT)
   {
      // Handle edit controls
      if(sparam == g_LotSizeEdit)
      {
         g_LotSize = StringToDouble(ObjectGetString(0, g_LotSizeEdit, OBJPROP_TEXT));
         if(g_LotSize < 0.01) g_LotSize = 0.01;
         ObjectSetString(0, g_LotSizeEdit, OBJPROP_TEXT, DoubleToString(g_LotSize, 2));
      }
      else if(sparam == g_SLEdit)
      {
         g_StopLoss = StringToDouble(ObjectGetString(0, g_SLEdit, OBJPROP_TEXT));
         if(g_StopLoss < 0) g_StopLoss = 0;
         ObjectSetString(0, g_SLEdit, OBJPROP_TEXT, DoubleToString(g_StopLoss, 1));
      }
   }
}

//+------------------------------------------------------------------+
//| Function to update button colors based on selection              |
//+------------------------------------------------------------------+
void UpdateButtonColors()
{
   if(g_BuySelected)
   {
      ObjectSetInteger(0, g_B, OBJPROP_BGCOLOR, clrDarkBlue);
      ObjectSetInteger(0, g_S, OBJPROP_BGCOLOR, Button_Color);
   }
   else if(g_SellSelected)
   {
      ObjectSetInteger(0, g_B, OBJPROP_BGCOLOR, Button_Color);
      ObjectSetInteger(0, g_S, OBJPROP_BGCOLOR, clrDarkRed);
   }
   else
   {
      ObjectSetInteger(0, g_B, OBJPROP_BGCOLOR, Button_Color);
      ObjectSetInteger(0, g_S, OBJPROP_BGCOLOR, Button_Color);
   }
}

//+------------------------------------------------------------------+
//| Create Trade Panel                                               |
//+------------------------------------------------------------------+
void CreateTradePanel()
{
   // Create panel background
   string panelName = "TM_Panel";
   int panelWidth = 200;
   int panelHeight = 300;

    ObjectCreate(0, panelName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, panelName, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, panelName, OBJPROP_XDISTANCE, Panel_X);
    ObjectSetInteger(0, panelName, OBJPROP_YDISTANCE, Panel_Y);
    ObjectSetInteger(0, panelName, OBJPROP_XSIZE, panelWidth);
    ObjectSetInteger(0, panelName, OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, panelName, OBJPROP_BGCOLOR, (int)Panel_Color);
    ObjectSetInteger(0, panelName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, panelName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, panelName, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, panelName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, panelName, OBJPROP_BACK, false);
    ObjectSetInteger(0, panelName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, panelName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, panelName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, panelName, OBJPROP_ZORDER, 0);

    // Initialize position variables
    int x = Panel_X;
    int y = Panel_Y;
    
    // Title
    CreateLabel("TM_Title", EA_Name, x + panelWidth/2 - 40, y + 10, Text_Color, 12, "Arial Bold");
    y += 30;

    // Create 4 rows of trade buttons with lot size inputs
    for(int i = 0; i < 4; i++)
    {
        string suffix = IntegerToString(i+1);
        
        // Lot Size (label removed)
        CreateEdit(g_LotSizeEdit+suffix, DoubleToString(g_LotSize, 2), x + 10, y + 25, Field_Width, Field_Height);
        
        // Trade action buttons (reduced width)
        int smallerWidth = Button_Width / 2; // Reduce button width by 1/2
        int buttonGap = 5; // Equal gap between buttons
        int startX = x + Field_Width + 20;
        
        // Create buttons with equal width and equal spacing, each with a distinct color
        CreateButton("TM_B"+suffix, "B", startX, y + 25, smallerWidth, Button_Height, clrDodgerBlue);      // Blue for Buy
        CreateButton("TM_S"+suffix, "S", startX + smallerWidth + buttonGap, y + 25, smallerWidth, Button_Height, clrCrimson);      // Red for Sell
        CreateButton("TM_X"+suffix, "X", startX + 2 * (smallerWidth + buttonGap), y + 25, smallerWidth, Button_Height, clrDarkOrange);   // Orange for Close
        CreateButton("TM_P"+suffix, "P", startX + 3 * (smallerWidth + buttonGap), y + 25, smallerWidth, Button_Height, clrMediumSeaGreen); // Green for Partial
        
        y += Field_Height + 30;
    }
    
    // Special action buttons
    CreateButton("TM_CA", "CA", x + 10, y, Field_Width, Button_Height, Button_Color);
    CreateButton("TM_CB", "CB", x + Field_Width + 20, y, Field_Width, Button_Height, Button_Color);
    CreateButton("TM_CS", "CS", x + 2 * Field_Width + 30, y, Field_Width, Button_Height, Button_Color);
    y += Button_Height + 20;

    // Stop Loss
    CreateLabel("TM_SLLabel", "Stop loss: ...", x + 10, y, Text_Color);
    CreateEdit(g_SLEdit, "0.0", x + 120, y, Field_Width/2, Field_Height);
    y += Field_Height;

    // Combined Stop Loss
    CreateLabel("TM_CSLLabel", "Combined stop loss: ...", x + 10, y, Text_Color);
    CreateEdit(g_CSLEdit, "0.0", x + 120, y, Field_Width/2, Field_Height);
    y += Field_Height;

    // Break-Even Point
    CreateLabel("TM_BEPLabel", "Break even point: ...", x + 10, y, Text_Color);
    CreateEdit(g_BEPEdit, "0.0", x + 120, y, Field_Width/2, Field_Height);
    y += Field_Height;

    // Trailing Stop
    CreateLabel("TM_TSLabel", "Trailing stop: ...", x + 10, y, Text_Color);
    CreateEdit(g_TSEdit, "0.0", x + 120, y, Field_Width/2, Field_Height);

    // Update button colors based on initial selection
    UpdateButtonColors();
}

//+------------------------------------------------------------------+
//| Create a button                                                  |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color clr)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (int)clr);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_STATE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrWhite);
}

//+------------------------------------------------------------------+
//| Create a panel                                                   |
//+------------------------------------------------------------------+
void CreatePanel(string name, int x, int y, int width, int height, color clr)
{
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (int)clr);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Create a button                                                  |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color clr, int id)
{
    ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (int)clr);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrWhite);
}

//+------------------------------------------------------------------+
//| Create a label                                                   |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize = 10, string font = "Arial")
{
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clr);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, font);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Create an edit control                                           |
//+------------------------------------------------------------------+
void CreateEdit(string name, string text, int x, int y, int width, int height)
{
    ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (int)clrWhite);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetString(0, name, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrBlack);
    ObjectSetInteger(0, name, OBJPROP_READONLY, false);
    ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_RIGHT);
}

// UpdateButtonColors function moved to avoid duplication

//+------------------------------------------------------------------+
//| Open a buy order                                                 |
//+------------------------------------------------------------------+
void OpenBuyOrder(double lotSize, double stopLoss = 0)
{
    double sl = 0;
    if(stopLoss > 0)
    {
        sl = Bid - stopLoss * Point;
    }
    
    int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, sl, 0, "Trade Manager Buy", 0, 0, clrBlue);
    if(ticket < 0)
    {
        int error = GetLastError();
        Print("OrderSend error: ", error);
    }
    else
    {
        Print("Buy order opened with lot size ", lotSize);
    }
}

//+------------------------------------------------------------------+
//| Open a sell order                                                |
//+------------------------------------------------------------------+
void OpenSellOrder(double lotSize, double stopLoss = 0)
{
    double sl = 0;
    if(stopLoss > 0)
    {
        sl = Ask + stopLoss * Point;
    }
    
    int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, sl, 0, "Trade Manager Sell", 0, 0, clrRed);
    if(ticket < 0)
    {
        int error = GetLastError();
        Print("OrderSend error: ", error);
    }
    else
    {
        Print("Sell order opened with lot size ", lotSize);
    }
}

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
{
    CloseBuyPositions(100);
    CloseSellPositions(100);
}

//+------------------------------------------------------------------+
//| Helper function to close positions based on selection             |
//+------------------------------------------------------------------+
void CloseSelectedPositions()
{
    if(g_BuySelected)
    {
        CloseBuyPositions(100);
    }
    else if(g_SellSelected)
    {
        CloseSellPositions(100);
    }
}

//+------------------------------------------------------------------+
//| Helper function for partial closing of positions                  |
//+------------------------------------------------------------------+
void PartialClosePositions()
{
    double closePercent = 50.0; // Close 50% by default
    
    if(g_BuySelected)
    {
        CloseBuyPositions(closePercent);
    }
    else if(g_SellSelected)
    {
        CloseSellPositions(closePercent);
    }
}

//+------------------------------------------------------------------+
//| Create the complete UI                                           |
//+------------------------------------------------------------------+
void CreateUI()
{
    // Calculate panel size based on components
    int panelWidth = Button_Width * 2 + 20; // Width for 2 buttons side by side + padding
    int panelHeight = 300; // Enough height for all components with spacing
    
    // Create main panel
    string panelName = "TM_Panel";
    CreatePanel(panelName, Panel_X, Panel_Y, panelWidth, panelHeight, Panel_Color);
    
    // Title
    CreateLabel(g_Title, EA_Name, Panel_X + 10, Panel_Y + 10, Text_Color, 12, "Arial Bold");
    
    // Create labels
    int labelX = Panel_X + 10;
    int labelY = Panel_Y + 40;
    int spacing = 30;
    
    CreateLabel(g_LotSizeLabel, "Lot Size:", labelX, labelY, Text_Color);
    CreateLabel(g_SLLabel, "Stop Loss:", labelX, labelY + spacing, Text_Color);
    CreateLabel(g_CSLLabel, "Combined SL:", labelX, labelY + spacing * 2, Text_Color);
    CreateLabel(g_BEPLabel, "Break Even:", labelX, labelY + spacing * 3, Text_Color);
    CreateLabel(g_TSLabel, "Trailing Stop:", labelX, labelY + spacing * 4, Text_Color);
    
    // Create edit boxes
    int editX = Panel_X + panelWidth - Field_Width - 10;
    int editY = labelY;
    
    CreateEdit(g_LotSizeEdit, DoubleToString(g_LotSize, 2), editX, editY, Field_Width, Field_Height);
    CreateEdit(g_SLEdit, DoubleToString(g_StopLoss, 1), editX, editY + spacing, Field_Width, Field_Height);
    CreateEdit(g_CSLEdit, DoubleToString(g_CombinedSL, 1), editX, editY + spacing * 2, Field_Width, Field_Height);
    CreateEdit(g_BEPEdit, DoubleToString(g_BreakEven, 1), editX, editY + spacing * 3, Field_Width, Field_Height);
    CreateEdit(g_TSEdit, DoubleToString(g_TrailingStop, 1), editX, editY + spacing * 4, Field_Width, Field_Height);
    
    // Create buttons
    int buttonY = editY + spacing * 5 + 10;
    int buttonX1 = Panel_X + 10;
    int buttonX2 = Panel_X + Button_Width + 10;
    
    // Buy and Sell buttons
    CreateButton(g_B, "BUY", buttonX1, buttonY, Button_Width, Button_Height, Button_Color, BUTTON_BUY);
    CreateButton(g_S, "SELL", buttonX2, buttonY, Button_Width, Button_Height, clrRed, BUTTON_SELL);
    
    // Close buttons
    buttonY += Button_Height + 5;
    CreateButton(g_X, "X", buttonX1, buttonY, Button_Width, Button_Height, clrDarkOrange, BUTTON_CLOSE_X);
    CreateButton(g_P, "P", buttonX2, buttonY, Button_Width, Button_Height, clrDarkOrange, BUTTON_CLOSE_P);
    
    // Close All/Buy/Sell buttons
    buttonY += Button_Height + 5;
    CreateButton(g_CA, "CA", buttonX1, buttonY, Button_Width, Button_Height, clrDarkOrange, BUTTON_CLOSE_ALL);
    
    buttonY += Button_Height + 5;
    CreateButton(g_CB, "CB", buttonX1, buttonY, Button_Width, Button_Height, clrDarkOrange, BUTTON_CLOSE_BUY);
    CreateButton(g_CS, "CS", buttonX2, buttonY, Button_Width, Button_Height, clrDarkOrange, BUTTON_CLOSE_SELL);
    
    // Update button colors based on selected state
    UpdateButtonColors();
}

//+------------------------------------------------------------------+
//| Close buy positions                                              |
//+------------------------------------------------------------------+
void CloseBuyPositions(double percent)
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
                double lotToClose = OrderLots();
                if(percent < 100)
                    lotToClose = NormalizeDouble(OrderLots() * percent / 100.0, 2);
                
                bool result = OrderClose(OrderTicket(), lotToClose, Bid, 3, clrBlue);
                if(!result)
                    Print("OrderClose error: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close sell positions                                             |
//+------------------------------------------------------------------+
void CloseSellPositions(double percent)
{
    for(int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderType() == OP_SELL)
            {
                double lotToClose = OrderLots();
                
                // If partial close
                if(percent < 100)
                {
                    lotToClose = NormalizeDouble(OrderLots() * percent / 100, 2);
                    
                    // Check minimum lot size
                    double minLot = MarketInfo(Symbol(), MODE_MINLOT);
                    if(lotToClose < minLot)
                        lotToClose = minLot;
                        
                    // Check if remaining lot would be less than minimum
                    if(OrderLots() - lotToClose < minLot)
                        lotToClose = OrderLots();
                }
                
                bool result = OrderClose(OrderTicket(), lotToClose, Ask, 3, clrRed);
                if(!result)
                    Print("OrderClose error: ", GetLastError());
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage trailing stop and break-even                              |
//+------------------------------------------------------------------+
void ManageTrailingStopAndBreakEven()
{
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol())
            {
                // Buy orders
                if(OrderType() == OP_BUY)
                {
                    double currentProfit = (Bid - OrderOpenPrice()) / Point / 10;
                
                    // Break-even
                    if(g_BreakEven > 0 && currentProfit >= g_BreakEven && OrderStopLoss() < OrderOpenPrice())
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrGreen);
                        if(!result)
                        Print("OrderModify error(Break - even): ", GetLastError());
                    }
                
                    // Trailing stop
                    if(g_TrailingStop > 0 && currentProfit >= g_TrailingStop)
                    {
                        double newSL = Bid - g_TrailingStop * Point * 10;
                        if(newSL > OrderStopLoss() + Point)
                        {
                            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrGreen);
                            if(!result)
                            Print("OrderModify error(Trailing Stop): ", GetLastError());
                        }
                    }
                }
                // Sell orders
                else if(OrderType() == OP_SELL)
                {
                    double currentProfit = (OrderOpenPrice() - Ask) / Point / 10;
                
                    // Break-even
                    if(g_BreakEven > 0 && currentProfit >= g_BreakEven && (OrderStopLoss() > OrderOpenPrice() || OrderStopLoss() == 0))
                    {
                        bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrRed);
                        if(!result)
                        Print("OrderModify error(Break - even): ", GetLastError());
                    }
                    
                    // Trailing stop
                    if(g_TrailingStop > 0 && currentProfit >= g_TrailingStop)
                    {
                        double newSL = Ask + g_TrailingStop * Point * 10;
                        if(newSL < OrderStopLoss() - Point || OrderStopLoss() == 0)
                        {
                            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed);
                            if(!result)
                            Print("OrderModify error(Trailing Stop): ", GetLastError());
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Manage combined stop loss                                        |
//+------------------------------------------------------------------+
void ManageCombinedStopLoss()
{
    if(g_CombinedSL <= 0) return;

    // For buy orders
    bool hasBuyOrders = false;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderType() == OP_BUY)
            {
                hasBuyOrders = true;
                if(Bid <= g_CombinedSL)
                {
                    CloseBuyPositions(100);
                    break;
                }
            }
        }
    }

    // For sell orders
    bool hasSellOrders = false;
    for(int i = 0; i < OrdersTotal(); i++)
    {
        if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
        {
            if(OrderSymbol() == Symbol() && OrderType() == OP_SELL)
            {
                hasSellOrders = true;
                if(Ask >= g_CombinedSL && g_CombinedSL > 0)
                {
                    CloseSellPositions(100);
                    break;
                }
            }
        }
    }
}