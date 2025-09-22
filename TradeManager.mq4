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

// Using built-in MQL4 chart event constants:
// CHARTEVENT_CHART_CHANGE, CHARTEVENT_OBJECT_CLICK, CHARTEVENT_OBJECT_ENDEDIT

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
input int Panel_X = 10; // Panel X Position
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
double g_LotSizes[5] = {0.02, 0.04, 0.06, 0.08, 0.1};

// Global variables for button states
    bool g_BuySelected = true;
    bool g_SellSelected = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
    int OnInit()
    {
        // Initialize lot sizes with starting values
        for(int i = 0; i < 5; i++) {
            g_LotSizes[i] = 0.01;
        }
        
        // Enable chart events for button clicks and other interactions
        ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);     // Enable chart events
        ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);  // Enable object creation events
        
        Print("Trade Manager EA initialized - chart events enabled");
        
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
        // Debug print to see what events are being received
        Print("Chart event received: ID=", id, ", sparam=", sparam);
        
        // Handle chart resize event
        if(id == CHARTEVENT_CHART_CHANGE) {
            // Recreate the panel when chart is resized
            Print("Chart resized - recreating panel");
            ObjectsDeleteAll(0, "TM_");
            CreateTradePanel();
            return;
        }

        // Handle button clicks
        if(id == CHARTEVENT_CLICK) {
            Print("Chart clicked");
        }
        
        // Handle object clicks (buttons)
        if(id == CHARTEVENT_OBJECT_CLICK) {
            string clickedObject = sparam;
            
            // Check if a button was clicked
            if(StringSubstr(clickedObject, 0, 3) == "TM_") {
                // Handle row-specific buttons (B1, S1, X1, P1, etc.)
                if(StringLen(clickedObject) > 4) {
                    string buttonType = StringSubstr(clickedObject, 3, 1); // B, S, X, or P
                    string rowStr = StringSubstr(clickedObject, 4, 1);    // Row number as string
                    int rowIndex = (int)StringToInteger(rowStr) - 1;      // Convert to 0-based index
                    
                    // Get the hardcoded lot size for this row
                    double lotSize = 0.0;
                    if(rowIndex == 0) lotSize = 0.02;
                    else if(rowIndex == 1) lotSize = 0.04;
                    else if(rowIndex == 2) lotSize = 0.06;
                    else if(rowIndex == 3) lotSize = 0.08;
                    else if(rowIndex == 4) lotSize = 0.10;
                    
                    // Execute the appropriate action based on button type
                    if(buttonType == "B") {
                        // Buy button clicked - use the hardcoded lot size
                        int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, 0, 0, "Buy Order", 0, 0, Button_Color);
                        if(ticket > 0) {
                            Print("Buy order executed with lot size: ", lotSize, ", ticket: ", ticket);
                        } else {
                            Print("Buy order failed. Error: ", GetLastError());
                        }
                    }
                    else if(buttonType == "S") {
                        // Sell button clicked - use the hardcoded lot size
                        int ticket = OrderSend(Symbol(), OP_SELL, lotSize, Bid, 3, 0, 0, "Sell Order", 0, 0, clrRed);
                        if(ticket > 0) {
                            Print("Sell order executed with lot size: ", lotSize, ", ticket: ", ticket);
                        } else {
                            Print("Sell order failed. Error: ", GetLastError());
                        }
                    }
                    else if(buttonType == "X") {
                        // Close only orders with this specific lot size
                        CloseOrdersByLotSize(lotSize);
                        Print("Closed orders with lot size: ", lotSize);
                    }
                    else if(buttonType == "P") {
                        // Partial close (50%) of positions with this specific lot size
                        PartialCloseByLotSize(lotSize, 50.0);
                        Print("Partially closed (50%) positions with lot size: ", lotSize);
                    }
                }
                // Handle special action buttons
                else if(clickedObject == "TM_CA") {
                    // Close all orders (both buy and sell)
                    CloseAllPositions();
                    Print("CA: Closed all positions");
                }
                else if(clickedObject == "TM_CB") {
                    // Close only buy orders
                    CloseBuyPositions(100);
                    Print("CB: Closed all buy positions");
                }
                else if(clickedObject == "TM_CS") {
                    // Close only sell orders
                    CloseSellPositions(100);
                    Print("CS: Closed all sell positions");
                }
            }
        }
        else if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
            // Handle edit controls
            // Check if the edit control is one of our lot size edits (TM_LotEdit1-TM_LotEdit5)
            if(StringSubstr(sparam, 0, 10) == "TM_LotEdit")
            {
                string rowSuffix = StringSubstr(sparam, 10, StringLen(sparam) - 10);
                int rowIndex = -1;
                if(StringLen(rowSuffix) > 0) {
                    int rowNum = (int)StringToInteger(rowSuffix);
                    if(rowNum > 0) {
                        rowIndex = rowNum - 1; // Convert to zero-based index
                    }
                }
                
                if(rowIndex >= 0 && rowIndex < 5) {
                    // Update the lot size for this row
                    double lotSize = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                    if(lotSize < 0.01) lotSize = 0.01;
                    
                    // Store the lot size in the global array
                    g_LotSizes[rowIndex] = lotSize;
                    
                    // Update the text in the edit control
                    ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(lotSize, 2));
                }
            }
        }
    }

//+------------------------------------------------------------------+
//| Create Trade Panel                                               |
//+------------------------------------------------------------------+
    void CreateTradePanel()
    {
        // Get chart dimensions for adaptive sizing
        int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
        int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        
        // Calculate panel size with appropriate minimum width to fit all elements
        int panelWidth = MathMax(320, MathMin(450, (int)(chartWidth * 0.25)));
        // Calculate panel height with sufficient height for all elements
        int panelHeight = MathMax(500, MathMin(450, (int)(chartHeight * 0.95)));
        
        // No panel background - removed white panel
        string panelName = "TM_Panel";
        
        // We'll still define panel dimensions for positioning calculations
        // but we won't create the actual panel object

    // Calculate button and field sizes with more appropriate proportions
        int adaptiveButtonWidth = MathMax(Button_Width, (int)(panelWidth * 0.5));
        int adaptiveFieldWidth = MathMax(Field_Width, (int)(panelWidth * 0.18));
        // Set reasonable button and field heights
        int adaptiveButtonHeight = MathMax(18, (int)(panelHeight * 0.08));
        int adaptiveFieldHeight = MathMax(18, (int)(panelHeight * 0.08));
        
    // Initialize position variables
        int x = Panel_X;
        int y = Panel_Y;
    
    // Title with proper positioning and spacing - white text
        CreateLabel("TM_Title", EA_Name, x + 10, y + 10, clrWhite, 10, "Arial Bold");
        y += 80; // Significant spacing after title to prevent any overlap

    // Trade action buttons (reduced width)
        int smallerWidth = adaptiveButtonWidth / 3; // Reduce button width by 1/3
        int buttonGap = (int)(panelWidth * 0.02); // Adaptive gap between buttons (2% of panel width)
        int startX = x + adaptiveFieldWidth + (int)(panelWidth * 0.05); // Adaptive starting position
        // Adjust row spacing to be more compact
        int rowSpacing = adaptiveFieldHeight + (int)(panelHeight * 0.04);
    
    // Create 5 rows of lot size inputs and trade action buttons
        for(int row = 0; row < 5; row++)
        {
            string rowSuffix = IntegerToString(row + 1);
            // Position rows with clear separation from title
            int rowY = y + (row * rowSpacing);
            
            // Lot Size for this row with hardcoded values
            string lotEditName = "TM_LotEdit" + rowSuffix;
            // Hardcoded values: 0.02, 0.04, 0.06, 0.08, 0.1 from top to bottom
            double hardcodedValue = 0.0;
            if(row == 0) hardcodedValue = 0.02;
            else if(row == 1) hardcodedValue = 0.04;
            else if(row == 2) hardcodedValue = 0.06;
            else if(row == 3) hardcodedValue = 0.08;
            else if(row == 4) hardcodedValue = 0.10;
            CreateEdit(lotEditName, DoubleToString(hardcodedValue, 2), x + (int)(panelWidth * 0.03), rowY, adaptiveFieldWidth, adaptiveFieldHeight);
            
            // Create buttons with equal width and equal spacing, each with a distinct color
            // Use smaller fixed font size for buttons
            int adaptiveFontSize = 8; // Fixed smaller font size for buttons
            
            CreateButton("TM_B" + rowSuffix, "B", startX, rowY, smallerWidth, adaptiveButtonHeight, clrDodgerBlue, adaptiveFontSize);
            CreateButton("TM_S" + rowSuffix, "S", startX + smallerWidth + buttonGap, rowY, smallerWidth, adaptiveButtonHeight, clrCrimson, adaptiveFontSize);
            CreateButton("TM_X" + rowSuffix, "X", startX + 2 * (smallerWidth + buttonGap), rowY, smallerWidth, adaptiveButtonHeight, clrBrown, adaptiveFontSize);
            CreateButton("TM_P" + rowSuffix, "P", startX + 3 * (smallerWidth + buttonGap), rowY, smallerWidth, adaptiveButtonHeight, clrIndigo, adaptiveFontSize);
        }
        
        // Adjust y position after all rows with moderate spacing
        y += (5 * rowSpacing) + (int)(panelHeight * 0.01);

    // Special action buttons - compact positioning and sizing
        int specialButtonSpacing = (int)(panelWidth * 0.02);
        int adaptiveFontSize = 8; // Fixed smaller font size
        CreateButton("TM_CA", "CA", x + (int)(panelWidth * 0.03), y, adaptiveFieldWidth, adaptiveButtonHeight, clrGreen, adaptiveFontSize);
        CreateButton("TM_CB", "CB", x + adaptiveFieldWidth + specialButtonSpacing, y, adaptiveFieldWidth, adaptiveButtonHeight, clrMidnightBlue, adaptiveFontSize);
        CreateButton("TM_CS", "CS", x + 2 * adaptiveFieldWidth + 2 * specialButtonSpacing, y, adaptiveFieldWidth, adaptiveButtonHeight, clrFireBrick, adaptiveFontSize);
        // Moderate spacing after special action buttons
        y += adaptiveButtonHeight + (int)(panelHeight * 0.03);

    // Adaptive label width and position
        int labelWidth = (int)(panelWidth * 0.5);
        int editX = x + labelWidth + (int)(panelWidth * 0.03);
        int editWidth = (int)(adaptiveFieldWidth * 0.7);
        
    // Stop Loss (pips from entry) - with smaller font and white text
        int labelFontSize = 8; // Fixed smaller font size
        CreateLabel("TM_SLLabel", "Stop loss (pips):", x + (int)(panelWidth * 0.03), y, clrWhite, labelFontSize);  
        CreateLabel(g_SLEdit, "0.0", editX, y, clrWhite, labelFontSize);
        y += adaptiveFieldHeight + (int)(panelHeight * 0.02); // Reduced spacing

    // Combined Stop Loss (price level) - white text
        CreateLabel("TM_CSLLabel", "Combined SL (price):", x + (int)(panelWidth * 0.03), y, clrWhite, labelFontSize);
        CreateLabel(g_CSLEdit, "0.0", editX, y, clrWhite, labelFontSize);
        y += adaptiveFieldHeight + (int)(panelHeight * 0.02); // Reduced spacing

    // Break-Even Point - white text
        CreateLabel("TM_BEPLabel", "Break-even (pips):", x + (int)(panelWidth * 0.03), y, clrWhite, labelFontSize);
        CreateLabel(g_BEPEdit, DoubleToString(g_BreakEven, 1), editX, y, clrWhite, labelFontSize);
        y += adaptiveFieldHeight + (int)(panelHeight * 0.02); // Reduced spacing

    // Trailing Stop - white text
        CreateLabel("TM_TSLabel", "Trailing stop (pips):", x + (int)(panelWidth * 0.03), y, clrWhite, labelFontSize);
        CreateLabel(g_TSEdit, DoubleToString(g_TrailingStop, 1), editX, y, clrWhite, labelFontSize);
        
        // No need to add chart event handler here as it's already set in OnInit
    }

//+------------------------------------------------------------------+
//| Create a button                                                  |
//+------------------------------------------------------------------+
    void CreateButton(string name, string text, int x, int y, int width, int height, color clr, int fontSize = 10, int id = 0)
    {
        // Delete button if it already exists
        if(ObjectFind(0, name) >= 0) {
            ObjectDelete(0, name);
        }
        
        // Create the button
        if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0)) {
            Print("Failed to create button: ", name, ". Error: ", GetLastError());
            return;
        }
        
        // Set button properties
        ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
        ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_STATE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); // Changed to false to make buttons visible and clickable
        ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrWhite);
        
        // Debug print
        Print("Button created: ", name, " at position ", x, ",", y);
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

// This function has been removed to avoid duplication
// The functionality is merged into the other CreateButton function

//+------------------------------------------------------------------+
//| Create a label                                                   |
//+------------------------------------------------------------------+
    void CreateLabel(string name, string text, int x, int y, color clr, int fontSize = 10, string font = "Arial")
    {
        // Delete label if it already exists
        if(ObjectFind(0, name) >= 0) {
            ObjectDelete(0, name);
        }
        
        // Get chart dimensions for adaptive font sizing if not specified
        if(fontSize == 10) { // Default value, use adaptive sizing
            int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
            fontSize = MathMax(8, MathMin(14, (int)(chartHeight * 0.015))); // 1.5% of chart height
        }
        
        // Create the label
        if(!ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
            Print("Failed to create label: ", name, ". Error: ", GetLastError());
            return;
        }
        
        // Set label properties
        ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clr);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetString(0, name, OBJPROP_FONT, font);
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); // Changed to false to make labels visible
    }

//+------------------------------------------------------------------+
//| Create an edit control                                           |
//+------------------------------------------------------------------+
    void CreateEdit(string name, string text, int x, int y, int width, int height)
    {
        // Delete edit control if it already exists
        if(ObjectFind(0, name) >= 0) {
            ObjectDelete(0, name);
        }
        
        // Calculate adaptive font size based on edit control height
        int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);
        int fontSize = MathMax(8, MathMin(12, (int)(height * 0.6)));
        
        // Create the edit control
        if(!ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0)) {
            Print("Failed to create edit control: ", name, ". Error: ", GetLastError());
            return;
        }
        
        // Set edit control properties
        ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, (int)clrWhite);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
        ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, false); // Changed to false to make edit controls visible
        ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrBlack);
        ObjectSetInteger(0, name, OBJPROP_READONLY, false);
        ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_RIGHT);
    }

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
        int totalClosed = 0;
        
        // First close all buy positions
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol() && OrderType() == OP_BUY)
                {
                    bool result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrBlue);
                    if(result) totalClosed++;
                }
            }
        }
        
        // Then close all sell positions
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol() && OrderType() == OP_SELL)
                {
                    bool result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrRed);
                    if(result) totalClosed++;
                }
            }
        }
        
        Print("CloseAllPositions: Closed ", totalClosed, " positions");
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
        double closePercent = 50.0; // Close 50 % by default
    
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
        CreateButton(g_B, "BUY", buttonX1, buttonY, Button_Width, Button_Height, Button_Color, 10, BUTTON_BUY);
        CreateButton(g_S, "SELL", buttonX2, buttonY, Button_Width, Button_Height, clrRed, 10, BUTTON_SELL);
    
    // Close buttons
        buttonY += Button_Height + 5;
        CreateButton(g_X, "X", buttonX1, buttonY, Button_Width, Button_Height, clrOrange, 10, BUTTON_CLOSE_X);
        CreateButton(g_P, "P", buttonX2, buttonY, Button_Width, Button_Height, clrOrange, 10, BUTTON_CLOSE_P);
    
    // Close All/Buy/Sell buttons
        buttonY += Button_Height + 5;
        CreateButton(g_CA, "CA", buttonX1, buttonY, Button_Width, Button_Height, clrOrange, 10, BUTTON_CLOSE_ALL);
    
        buttonY += Button_Height + 5;
        CreateButton(g_CB, "CB", buttonX1, buttonY, Button_Width, Button_Height, clrOrange, 10, BUTTON_CLOSE_BUY);
        CreateButton(g_CS, "CS", buttonX2, buttonY, Button_Width, Button_Height, clrOrange, 10, BUTTON_CLOSE_SELL);
    }

//+------------------------------------------------------------------+
//| Close buy positions                                              |
//+------------------------------------------------------------------+
    void CloseBuyPositions(double percent)
    {
        int totalClosed = 0;
        double totalLots = 0.0;
        
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol() && OrderType() == OP_BUY)
                {
                    double lotToClose = OrderLots();
                    
                    // If partial close
                    if(percent < 100)
                    {
                        lotToClose = NormalizeDouble(OrderLots() * percent / 100.0, 2);
                        
                        // Check minimum lot size
                        double minLot = MarketInfo(Symbol(), MODE_MINLOT);
                        if(lotToClose < minLot)
                            lotToClose = minLot;
                            
                        // Check if remaining lot would be less than minimum
                        if(OrderLots() - lotToClose < minLot)
                            lotToClose = OrderLots();
                    }
                
                    bool result = OrderClose(OrderTicket(), lotToClose, Bid, 3, clrBlue);
                    if(result) {
                        totalClosed++;
                        totalLots += lotToClose;
                    } else {
                        Print("CB: Failed to close Buy order #", OrderTicket(), ". Error: ", GetLastError());
                    }
                }
            }
        }
        
        if(totalClosed > 0)
            Print("CB: Closed ", totalClosed, " buy positions totaling ", DoubleToString(totalLots, 2), " lots");
    }

//+------------------------------------------------------------------+
//| Close sell positions                                             |
//+------------------------------------------------------------------+
    void CloseSellPositions(double percent)
    {
        int totalClosed = 0;
        double totalLots = 0.0;
        
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
                    if(result) {
                        totalClosed++;
                        totalLots += lotToClose;
                    } else {
                        Print("CS: Failed to close Sell order #", OrderTicket(), ". Error: ", GetLastError());
                    }
                }
            }
        }
        
        if(totalClosed > 0)
            Print("CS: Closed ", totalClosed, " sell positions totaling ", DoubleToString(totalLots, 2), " lots");
    }
    
//+------------------------------------------------------------------+
//| Close orders with specific lot size                              |
//+------------------------------------------------------------------+
    void CloseOrdersByLotSize(double targetLotSize)
    {
        // Use a small epsilon for floating point comparison
        double epsilon = 0.001;
        
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))  
            {
                if(OrderSymbol() == Symbol())
                {
                    // Check if this order has the target lot size (with epsilon tolerance)
                    if(MathAbs(OrderLots() - targetLotSize) < epsilon)
                    {
                        if(OrderType() == OP_BUY)
                        {
                            bool result = OrderClose(OrderTicket(), OrderLots(), Bid, 3, clrBlue);
                            if(!result)
                                Print("Failed to close Buy order with lot size ", targetLotSize, ". Error: ", GetLastError());
                            else
                                Print("Closed Buy order #", OrderTicket(), " with lot size ", OrderLots());
                        }
                        else if(OrderType() == OP_SELL)
                        {
                            bool result = OrderClose(OrderTicket(), OrderLots(), Ask, 3, clrRed);
                            if(!result)
                                Print("Failed to close Sell order with lot size ", targetLotSize, ". Error: ", GetLastError());
                            else
                                Print("Closed Sell order #", OrderTicket(), " with lot size ", OrderLots());
                        }
                    }
                }
            }
        }
    }

//+------------------------------------------------------------------+
//| Partially close orders with specific lot size                     |
//+------------------------------------------------------------------+
    void PartialCloseByLotSize(double targetLotSize, double percent)
    {
        // Use a small epsilon for floating point comparison
        double epsilon = 0.001;
        
        for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol())
                {
                    // Check if this order has the target lot size (with epsilon tolerance)
                    if(MathAbs(OrderLots() - targetLotSize) < epsilon)
                    {
                        double lotToClose = NormalizeDouble(OrderLots() * percent / 100.0, 2);
                        double minLot = MarketInfo(Symbol(), MODE_MINLOT);
                        
                        // Check minimum lot size
                        if(lotToClose < minLot) 
                            lotToClose = minLot;
                            
                        // Check if remaining lot would be less than minimum
                        if(OrderLots() - lotToClose < minLot)
                            lotToClose = OrderLots(); // Close the entire position
                        
                        if(OrderType() == OP_BUY)
                        {
                            bool result = OrderClose(OrderTicket(), lotToClose, Bid, 3, clrBlue);
                            if(!result)
                                Print("Failed to partially close Buy order with lot size ", targetLotSize, ". Error: ", GetLastError());
                            else
                                Print("Partially closed Buy order #", OrderTicket(), ", closed ", lotToClose, " lots out of ", OrderLots());
                        }
                        else if(OrderType() == OP_SELL)
                        {
                            bool result = OrderClose(OrderTicket(), lotToClose, Ask, 3, clrRed);
                            if(!result)
                                Print("Failed to partially close Sell order with lot size ", targetLotSize, ". Error: ", GetLastError());
                            else
                                Print("Partially closed Sell order #", OrderTicket(), ", closed ", lotToClose, " lots out of ", OrderLots());
                        }
                    }
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