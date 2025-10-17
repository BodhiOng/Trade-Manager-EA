//+----------------------------------------------------------------------+
//|                                              TradeManager.mq4     |
//|                                      Copyright 2023, MetaQuotes |
//|                                       https://www.metaquotes.net |
//+----------------------------------------------------------------------+
#property copyright "bodhidharma202@gmail.com"
#property version   "1.00"
#property strict

// Include standard libraries
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

// Using built-in MQL4 chart event constants:
// CHARTEVENT_CHART_CHANGE, CHARTEVENT_OBJECT_CLICK, CHARTEVENT_OBJECT_ENDEDIT

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
string g_CSLLabel = "CSLLabel";
string g_CSLSetButton = "CSLSetButton";
string g_NoTrailZoneLabel = "NoTrailZoneLabel";
string g_NoTrailZoneSetButton = "NoTrailZoneSetButton";
string g_TrailingStopLabel = "TrailingStopLabel";
string g_TrailingStopSetButton = "TrailingStopSetButton";
string g_CTPLabel = "CTPLabel";
string g_CTPSetButton = "CTPSetButton";
string g_LotSizeEdit = "LotSizeEdit";
string g_CSLEdit = "CSLEdit";
string g_NoTrailZoneEdit = "NoTrailZoneEdit";
string g_TrailingStopEdit = "TrailingStopEdit";
string g_CTPEdit = "CTPEdit";
string g_HideButton = "TM_HideButton";
string g_ShowButton = "TM_ShowButton";
string g_BuyPLLabel = "TM_BuyPLLabel";
string g_SellPLLabel = "TM_SellPLLabel";

int Panel_Corner = 0; // Panel Corner
int Panel_X = 10; // Panel X Position
int Panel_Y = 20; // Panel Y Position
color Panel_Color = clrWhite; // Panel Color
color Button_Color = clrDodgerBlue; // Button Color
color Text_Color = clrBlack; // Text Color
int Button_Width = 80; // Button Width
int Button_Height = 20; // Button Height
int Field_Width = 60; // Field Width
int Field_Height = 20; // Field Height
int Label_Width = 60; // Label Width
int Label_Height = 20; // Label Height

// Risk Management Settings
input double Max_Loss = 0.00; // Max Loss Threshold (account balance)
// Cooling Down Duration options
enum ENUM_COOLING_DOWN_DURATION {
   MINUTES_15 = 15,  // 15 minutes
   MINUTES_30 = 30,  // 30 minutes
   MINUTES_45 = 45,  // 45 minutes
   MINUTES_60 = 60   // 60 minutes
};
input ENUM_COOLING_DOWN_DURATION Cooling_Down_Duration = MINUTES_15; // Cooling Down Duration

// Global variables
double g_LotSize = 0.01;
double g_CombinedSL = 0.0;
double g_NoTrailZone = 0.0;
double g_TrailingStop = 0.0;
double g_CombinedTP = 0.0;
bool g_IsPanelHidden = false; // Track if panel is hidden or visible

// Max loss and cooling down variables
bool g_MaxLossTriggered = false;   // Whether max loss has been triggered
datetime g_CoolingDownEndTime = 0; // When the cooling down period ends
int g_CoolingDownMinutes = 15;     // Default cooling down minutes
int g_CoolingDownSeconds = 0;      // Default cooling down seconds
string g_MaxLossOverlayName = "TM_MaxLossOverlay";
string g_MaxLossMessageName = "TM_MaxLossMessage";
string g_MaxLossCountdownName = "TM_MaxLossCountdown";

// Timer variables for smooth countdown
datetime g_LastSecondUpdate = 0;   // Last time the second was updated
int g_DisplayedSeconds = 0;        // Currently displayed seconds
int g_DisplayedMinutes = 0;        // Currently displayed minutes

// Arrays to store multiple lot sizes
double g_LotSizes[5] = {0.02, 0.04, 0.06, 0.08, 0.1};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
    int OnInit()
    {
        // Ensure the lot sizes array is properly initialized
        if(ArraySize(g_LotSizes) != 5) {
                Print("WARNING: g_LotSizes array size is not 5, resizing...");
                ArrayResize(g_LotSizes, 5);
            g_LotSizes[0] = 0.02;
            g_LotSizes[1] = 0.04;
            g_LotSizes[2] = 0.06;
            g_LotSizes[3] = 0.08;
            g_LotSizes[4] = 0.10;
        }
        
        // Print the array values for debugging
        Print("g_LotSizes initialized with: ", 
              g_LotSizes[0], ", ",
              g_LotSizes[1], ", ",
              g_LotSizes[2], ", ",
              g_LotSizes[3], ", ",
              g_LotSizes[4]);
              
        // Set cooling down duration from input parameter
        g_CoolingDownMinutes = Cooling_Down_Duration;
        g_CoolingDownSeconds = 0;
        Print("Cooling down duration set to: ", g_CoolingDownMinutes, " minutes");
        
        // Enable chart events for button clicks and other interactions
        ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);     // Enable chart events
        ChartSetInteger(0, CHART_EVENT_OBJECT_CREATE, true);  // Enable object creation events
        
        // Set up a 1-second timer for smooth countdown
        EventSetTimer(1); // 1-second timer
        Print("1-second timer set for smooth countdown");
        
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
        // Kill the timer
        EventKillTimer();
        Print("Timer killed");
        
        // Remove UI elements
        ObjectsDeleteAll(0, "TM_");
        
        // Explicitly remove max loss overlay objects to ensure they're gone
        ObjectDelete(0, g_MaxLossOverlayName);
        ObjectDelete(0, g_MaxLossMessageName);
        ObjectDelete(0, g_MaxLossCountdownName);
    }
    
//+------------------------------------------------------------------+
//| Timer event function                                              |
//+------------------------------------------------------------------+
    void OnTimer()
    {
        // Only process timer events if max loss is triggered
        if(g_MaxLossTriggered)
        {
            // Get current time
            datetime currentTime = TimeCurrent();
            
            // Calculate remaining time
            int remainingSeconds = (int)(g_CoolingDownEndTime - currentTime);
            
            // Ensure we don't show negative time
            if(remainingSeconds < 0) remainingSeconds = 0;
            
            // Calculate minutes and seconds for display
            g_DisplayedMinutes = remainingSeconds / 60;
            g_DisplayedSeconds = remainingSeconds % 60;
            
            // Format the countdown text
            string countdownText = StringFormat("%02d:%02d", g_DisplayedMinutes, g_DisplayedSeconds);
            
            // Update the countdown text
            if(ObjectFind(0, g_MaxLossCountdownName) >= 0)
            {
                ObjectSetString(0, g_MaxLossCountdownName, OBJPROP_TEXT, countdownText);
            }
            
            // Debug output every 5 seconds
            static datetime lastDebugTime = 0;
            if(currentTime - lastDebugTime >= 5)
            {
                Print("[TIMER] Countdown: ", countdownText, 
                      ", Remaining seconds: ", remainingSeconds,
                      ", Current time: ", TimeToString(currentTime, TIME_DATE|TIME_SECONDS), 
                      ", End time: ", TimeToString(g_CoolingDownEndTime, TIME_DATE|TIME_SECONDS));
                lastDebugTime = currentTime;
            }
            
            // Check if cooling down period has ended
            if(remainingSeconds <= 0)
            {
                // Cooling down period is over, allow trading again
                g_MaxLossTriggered = false;
                g_CoolingDownEndTime = 0;
                
                // Remove overlay objects
                ObjectDelete(0, g_MaxLossOverlayName);
                ObjectDelete(0, g_MaxLossMessageName);
                ObjectDelete(0, g_MaxLossCountdownName);
                
                Print("Cooling down period ended. Trading enabled again.");
            }
            
            // Force chart redraw to ensure smooth countdown display
            ChartRedraw(0);
        }
    }

//+------------------------------------------------------------------+
//| Direct button action function that can be called manually         |
//+------------------------------------------------------------------+
    void ProcessButtonAction(string buttonName)
    {
        Print("Manual button action: ", buttonName);
        
        if(buttonName == "TM_CA") {
            Print("Processing CA button action");
            CloseAllPositions();
        }
        else if(buttonName == "TM_CB") {
            Print("Processing CB button action");
            CloseBuyPositions(100);
        }
        else if(buttonName == "TM_CS") {
            Print("Processing CS button action");
            CloseSellPositions(100);
        }
    }
    
//+------------------------------------------------------------------+
//| Direct button click functions that can be called from the chart   |
//+------------------------------------------------------------------+
    // These functions can be called directly from the chart
    void CloseAllButton() { ProcessButtonAction("TM_CA"); }
    void CloseBuyButton() { ProcessButtonAction("TM_CB"); }
    void CloseSellButton() { ProcessButtonAction("TM_CS"); }

//+------------------------------------------------------------------+
//| Check if max loss has been triggered                              |
//+------------------------------------------------------------------+
    bool CheckMaxLossCondition()
    {
        // Get current account balance
        double currentBalance = AccountBalance();
        static double previousBalance = currentBalance;
        static bool wasAboveThreshold = (currentBalance >= Max_Loss);
        bool result = false;
        
        // Only trigger max loss if balance drops below threshold from above threshold
        // or if this is the first check and balance is already below threshold
        if(currentBalance < Max_Loss)
        {
            if(wasAboveThreshold || previousBalance == 0)
            {
                result = true;
                wasAboveThreshold = false;
            }
        }
        else
        {
            // Balance is above threshold, reset the flag
            wasAboveThreshold = true;
        }
        
        // Store current balance for next check
        previousBalance = currentBalance;
        
        return result;
    }

//+------------------------------------------------------------------+
//| Create blue screen overlay with countdown message                  |
//+------------------------------------------------------------------+
    void ShowMaxLossOverlay()
    {
        // Set the cooling down end time if not already set
        if(g_CoolingDownEndTime == 0)
        {
            g_CoolingDownEndTime = TimeCurrent() + g_CoolingDownMinutes * 60; // Convert minutes to seconds
            
            // Initialize display values
            g_DisplayedMinutes = g_CoolingDownMinutes;
            g_DisplayedSeconds = g_CoolingDownSeconds;
            
            Print("Cooling down period set to end at: ", TimeToString(g_CoolingDownEndTime, TIME_DATE|TIME_SECONDS));
            Print("Initial countdown: ", g_DisplayedMinutes, ":", g_DisplayedSeconds);
        }
        
        // Initial countdown text - will be updated by OnTimer
        string countdownText = StringFormat("%02d:%02d", g_DisplayedMinutes, g_DisplayedSeconds);
        
        // Create or update overlay rectangle covering the entire chart
        if(ObjectFind(0, g_MaxLossOverlayName) < 0)
        {
            ObjectCreate(0, g_MaxLossOverlayName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_XDISTANCE, 0);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_YDISTANCE, 0);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_XSIZE, ChartGetInteger(0, CHART_WIDTH_IN_PIXELS));
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_YSIZE, ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS));
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_BGCOLOR, clrBlue);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_STYLE, STYLE_SOLID);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_BACK, false);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_SELECTED, false);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_HIDDEN, false);
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_ZORDER, 1000); // Top layer
        }
        else
        {
            // Update size in case chart was resized
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_XSIZE, ChartGetInteger(0, CHART_WIDTH_IN_PIXELS));
            ObjectSetInteger(0, g_MaxLossOverlayName, OBJPROP_YSIZE, ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS));
        }
        
        // Create or update message text
        if(ObjectFind(0, g_MaxLossMessageName) < 0)
        {
            ObjectCreate(0, g_MaxLossMessageName, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(0, g_MaxLossMessageName, OBJPROP_XDISTANCE, 50);
            ObjectSetInteger(0, g_MaxLossMessageName, OBJPROP_YDISTANCE, ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) / 2 - 30);
            ObjectSetInteger(0, g_MaxLossMessageName, OBJPROP_COLOR, clrWhite);
            ObjectSetString(0, g_MaxLossMessageName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, g_MaxLossMessageName, OBJPROP_FONTSIZE, 16);
            ObjectSetInteger(0, g_MaxLossMessageName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
            ObjectSetString(0, g_MaxLossMessageName, OBJPROP_TEXT, "Max loss had been triggered. Cooling down for");
        }
        
        // Create or update countdown text
        if(ObjectFind(0, g_MaxLossCountdownName) < 0)
        {
            ObjectCreate(0, g_MaxLossCountdownName, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(0, g_MaxLossCountdownName, OBJPROP_XDISTANCE, 50);
            ObjectSetInteger(0, g_MaxLossCountdownName, OBJPROP_YDISTANCE, ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS) / 2);
            ObjectSetInteger(0, g_MaxLossCountdownName, OBJPROP_COLOR, clrWhite);
            ObjectSetString(0, g_MaxLossCountdownName, OBJPROP_FONT, "Arial Bold");
            ObjectSetInteger(0, g_MaxLossCountdownName, OBJPROP_FONTSIZE, 24);
            ObjectSetInteger(0, g_MaxLossCountdownName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        }
        
        // Update countdown text
        ObjectSetString(0, g_MaxLossCountdownName, OBJPROP_TEXT, countdownText);
        
        // Force chart redraw
        ChartRedraw(0);
    }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
    void OnTick()
    {
        // Check if CA, CB, CS buttons exist and are clickable
        static int tickCount = 0;
        static double lastCombinedSL = 0;
        
        // Check for max loss condition
        if(g_MaxLossTriggered)
        {
            // Skip normal processing while in cooling down period
            // The OnTimer function will handle the countdown and overlay updates
            return;
        }
        else if(CheckMaxLossCondition())
        {
            // Max loss just triggered
            g_MaxLossTriggered = true;
            g_CoolingDownEndTime = 0; // Reset so it will be set in ShowMaxLossOverlay
            ShowMaxLossOverlay();
            Print("Max loss triggered at balance: ", AccountBalance(), ", threshold: ", Max_Loss);
            return; // Skip normal processing
        }
        
        // Normal processing continues if max loss not triggered
        
        // Check combined stop loss, combined take profit and trailing stop on every tick
        ManageCombinedStopLoss();
        ManageCombinedTakeProfit();
        ManageTrailingStop();
        
        // Update the profit/loss display
        UpdateProfitLossDisplay();
        
        // Every 10 ticks, check the buttons (more frequent checking)
        if(tickCount % 10 == 0) {
            // Check CA button
            if(ObjectFind(0, "TM_CA") >= 0) {
                // Make sure it's not hidden
                ObjectSetInteger(0, "TM_CA", OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, "TM_CA", OBJPROP_SELECTABLE, true);
                
                // Check if button is pressed
                if(ObjectGetInteger(0, "TM_CA", OBJPROP_STATE)) {
                    // Reset button state
                    ObjectSetInteger(0, "TM_CA", OBJPROP_STATE, false);
                    // Execute action
                    ProcessButtonAction("TM_CA");
                }
            }
            
            // Check CB button
            if(ObjectFind(0, "TM_CB") >= 0) {
                // Make sure it's not hidden
                ObjectSetInteger(0, "TM_CB", OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, "TM_CB", OBJPROP_SELECTABLE, true);
                
                // Check if button is pressed
                if(ObjectGetInteger(0, "TM_CB", OBJPROP_STATE)) {
                    // Reset button state
                    ObjectSetInteger(0, "TM_CB", OBJPROP_STATE, false);
                    // Execute action
                    ProcessButtonAction("TM_CB");
                }
            }
            
            // Check CS button
            if(ObjectFind(0, "TM_CS") >= 0) {
                // Make sure it's not hidden
                ObjectSetInteger(0, "TM_CS", OBJPROP_HIDDEN, false);
                ObjectSetInteger(0, "TM_CS", OBJPROP_SELECTABLE, true);
                
                // Check if button is pressed
                if(ObjectGetInteger(0, "TM_CS", OBJPROP_STATE)) {
                    // Reset button state
                    ObjectSetInteger(0, "TM_CS", OBJPROP_STATE, false);
                    // Execute action
                    ProcessButtonAction("TM_CS");
                }
            }
        }
        
        tickCount++;
    }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        // Always print the event for debugging
        Print("Chart event: ID=", id, ", object=", sparam);
        
        // No keyboard shortcuts - removed due to MQL4 limitations
        
        // Block all button interactions during cooling down period
        if(g_MaxLossTriggered) {
            Print("All interactions disabled during cooling down period");
            return;
        }
        
        // Handle button clicks - this is the main event we care about
        if(id == CHARTEVENT_OBJECT_CLICK) {
            // Handle Hide button
            if(sparam == g_HideButton) {
                Print("Hide button clicked");
                HideTradePanel();
                return;
            }
            
            // Handle Show button
            if(sparam == g_ShowButton) {
                Print("Show button clicked");
                ShowTradePanel();
                return;
            }
            
            // Direct handling of special buttons
            if(sparam == "TM_CA" || sparam == "TM_CB" || sparam == "TM_CS") {
                Print("Special button clicked: ", sparam);
                ProcessButtonAction(sparam);
                return;
            }
            
            // Handle Combined SL Set button
            if(sparam == g_CSLSetButton) {
                // Get the value from the CSL edit field
                double cslValue = StringToDouble(ObjectGetString(0, g_CSLEdit, OBJPROP_TEXT));
                // Allow 0.0 to remove stop loss, but not negative values
                if(cslValue >= 0) {
                    g_CombinedSL = cslValue;
                    if(cslValue == 0.0) {
                        Print("Combined SL set to 0.0 - removing stop loss from all orders");
                    } else {
                        Print("Combined SL set to: ", g_CombinedSL);
                    }
                    
                    // Apply the stop loss to all active orders
                    ApplyCombinedStopLoss(g_CombinedSL);
                }
                return;
            }
            
            // Handle No-trail zone Set button
            if(sparam == g_NoTrailZoneSetButton) {
                // Get the value from the No-trail zone edit field
                double ntzValue = StringToDouble(ObjectGetString(0, g_NoTrailZoneEdit, OBJPROP_TEXT));
                // Allow 0.0 or positive values
                if(ntzValue >= 0) {
                    g_NoTrailZone = ntzValue;
                    Print("No-trail zone set to: ", g_NoTrailZone, " pips");
                }
                return;
            }
            
            // Handle Trailing stop Set button
            if(sparam == g_TrailingStopSetButton) {
                // Get the value from the Trailing stop edit field
                double tsValue = StringToDouble(ObjectGetString(0, g_TrailingStopEdit, OBJPROP_TEXT));
                // Allow 0.0 or positive values
                if(tsValue >= 0) {
                    g_TrailingStop = tsValue;
                    Print("Trailing stop set to: ", g_TrailingStop, " pips");
                    
                    // If trailing stop is activated, disable combined TP
                    if(tsValue > 0.0) {
                        g_CombinedTP = 0.0;
                        if(ObjectFind(0, g_CTPEdit) >= 0) {
                            ObjectSetString(0, g_CTPEdit, OBJPROP_TEXT, "0.0");
                        }
                    }
                }
                return;
            }
            
            // Handle Combined TP Set button
            if(sparam == g_CTPSetButton) {
                // Get the value from the Combined TP edit field
                double ctpValue = StringToDouble(ObjectGetString(0, g_CTPEdit, OBJPROP_TEXT));
                // Allow 0.0 to remove take profit, but not negative values
                if(ctpValue >= 0) {
                    g_CombinedTP = ctpValue;
                    if(ctpValue == 0.0) {
                        Print("Combined TP set to 0.0 - removing take profit from all orders");
                    } else {
                        Print("Combined TP set to: ", g_CombinedTP);
                        
                        // If combined TP is activated, disable trailing stop and no-trail zone
                        g_TrailingStop = 0.0;
                        g_NoTrailZone = 0.0;
                        
                        // Update the edit fields
                        if(ObjectFind(0, g_TrailingStopEdit) >= 0) {
                            ObjectSetString(0, g_TrailingStopEdit, OBJPROP_TEXT, "0.0");
                        }
                        if(ObjectFind(0, g_NoTrailZoneEdit) >= 0) {
                            ObjectSetString(0, g_NoTrailZoneEdit, OBJPROP_TEXT, "0.0");
                        }
                    }
                    
                    // Apply the take profit to all active orders
                    ApplyCombinedTakeProfit(g_CombinedTP);
                }
                return;
            }
            
            // Handle row-specific buttons
            string clickedObject = sparam;
            
            // Check if a button was clicked
            if(StringSubstr(clickedObject, 0, 3) == "TM_") {
                // Handle row-specific buttons (B1, S1, X1, P1, etc.)
                if(StringLen(clickedObject) > 4) {
                    string buttonType = StringSubstr(clickedObject, 3, 1); // B, S, X, or P
                    string rowStr = StringSubstr(clickedObject, 4, 1);    // Row number as string
                    int rowIndex = (int)StringToInteger(rowStr) - 1;      // Convert to 0-based index
                    
                    // Get the current lot size from the global array with safety check
                    double lotSize = 0.01; // Default safe value
                    if(rowIndex >= 0 && rowIndex < ArraySize(g_LotSizes)) {
                        lotSize = g_LotSizes[rowIndex];
                        Print("Using lot size: ", lotSize, " for row index: ", rowIndex);
                    } else {
                        Print("WARNING: Invalid row index: ", rowIndex, ", using default lot size: ", lotSize);
                    }
                    
                    // Execute the appropriate action based on button type
                    if(buttonType == "B") {
                        // Buy button clicked - use the editable lot size
                        int ticket = OrderSend(Symbol(), OP_BUY, lotSize, Ask, 3, 0, 0, "Buy Order", 0, 0, Button_Color);
                        if(ticket > 0) {
                            Print("Buy order executed with lot size: ", lotSize, ", ticket: ", ticket);
                        } else {
                            Print("Buy order failed. Error: ", GetLastError());
                        }
                    }
                    else if(buttonType == "S") {
                        // Sell button clicked - use the editable lot size
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
                else if(StringCompare(clickedObject, "TM_CA") == 0) {
                    // Close all orders (both buy and sell)
                    Print("CA button clicked - closing all positions");
                    CloseAllPositions();
                }
                else if(StringCompare(clickedObject, "TM_CB") == 0) {
                    // Close only buy orders
                    Print("CB button clicked - closing all buy positions");
                    CloseBuyPositions(100);
                }
                else if(StringCompare(clickedObject, "TM_CS") == 0) {
                    // Close only sell orders
                    Print("CS button clicked - closing all sell positions");
                    CloseSellPositions(100);
                }
            }
        }
        else if(id == CHARTEVENT_OBJECT_ENDEDIT)
        {
            // Handle edit controls
            // Handle Combined SL edit field
            if(sparam == g_CSLEdit)
            {
                double cslValue = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                // Store the value but don't apply it yet (wait for Set button)
                ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(cslValue, 5));
            }
            // Handle No-trail zone edit field
            else if(sparam == g_NoTrailZoneEdit)
            {
                double ntzValue = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                if(ntzValue >= 0) {
                    g_NoTrailZone = ntzValue;
                    ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(ntzValue, 1));
                }
            }
            // Handle Trailing stop edit field
            else if(sparam == g_TrailingStopEdit)
            {
                double tsValue = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                if(tsValue >= 0) {
                    g_TrailingStop = tsValue;
                    ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(tsValue, 1));
                }
            }
            // Handle Combined TP edit field
            else if(sparam == g_CTPEdit)
            {
                double ctpValue = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                // Store the value but don't apply it yet (wait for Set button)
                ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(ctpValue, 5));
            }
            // Direct handling of lot size edit fields by exact name matching
            else if(sparam == "TM_LotEdit1" || sparam == "TM_LotEdit2" || sparam == "TM_LotEdit3" || 
                    sparam == "TM_LotEdit4" || sparam == "TM_LotEdit5")
            {
                // Debug print
                Print("Lot size edit detected: ", sparam);
                
                // Determine which row this is (1-5)
                int rowIndex = -1;
                
                if(sparam == "TM_LotEdit1") rowIndex = 0;
                else if(sparam == "TM_LotEdit2") rowIndex = 1;
                else if(sparam == "TM_LotEdit3") rowIndex = 2;
                else if(sparam == "TM_LotEdit4") rowIndex = 3;
                else if(sparam == "TM_LotEdit5") rowIndex = 4;
                
                Print("Direct row index: ", rowIndex);
                
                // Safety check
                if(rowIndex >= 0 && rowIndex < 5) {
                    // Update the lot size for this row
                    double lotSize = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
                    if(lotSize < 0.01) lotSize = 0.01;
                    
                    Print("Setting lot size for row ", rowIndex, " to ", lotSize);
                    
                    // Store the lot size in the global array
                    g_LotSizes[rowIndex] = lotSize;
                    
                    // Update the text in the edit control
                    ObjectSetString(0, sparam, OBJPROP_TEXT, DoubleToString(lotSize, 2));
                } else {
                    Print("ERROR: Invalid row index: ", rowIndex);
                }
            }
        }
    }

//+------------------------------------------------------------------+
//| Create Trade Panel                                               |
//+------------------------------------------------------------------+
    void CreateTradePanel()
    {
        // Fixed panel dimensions
        int panelWidth = 350;  // Fixed panel width
        int panelHeight = 450; // Fixed panel height
        
        // No panel background - removed white panel
        string panelName = "TM_Panel";
        
        // Fixed button and field sizes
        int fixedButtonWidth = 80;   // Fixed button width
        int fixedFieldWidth = 60;    // Fixed field width
        int fixedButtonHeight = 20;  // Fixed button height
        int fixedFieldHeight = 20;   // Fixed field height
        
        // Initialize position variables
        int x = Panel_X;
        int y = Panel_Y;
    
        // Title with proper positioning and spacing - white text
        CreateLabel("TM_Title", "Trade Manager", x + 10, y + 10, clrWhite, 12, "Arial Bold");
        
        // Show button next to title - initially hidden
        int showButtonWidth = 50;
        int showButtonHeight = 20;
        CreateFixedButton(g_ShowButton, "SHOW", x + 160, y + 15, showButtonWidth, showButtonHeight, clrGreen, 9);
        // Initially hide the show button since panel starts visible
        ObjectSetInteger(0, g_ShowButton, OBJPROP_HIDDEN, true);
        
        y += 40; // Significant spacing after title to prevent any overlap

        // Trade action buttons with fixed width
        int smallerWidth = 38;      // Fixed smaller button width
        int buttonGap = 5;          // Fixed gap between buttons
        int startX = x + fixedFieldWidth + 15; // Fixed starting position
        // Fixed row spacing
        int rowSpacing = 25;        // Fixed row spacing
    
    // Create 5 rows of lot size inputs and trade action buttons
        for(int row = 0; row < 5; row++)
        {
            string rowSuffix = IntegerToString(row + 1);
            // Position rows with clear separation from title
            int rowY = y + (row * rowSpacing);
            
            // Lot Size for this row from the global array - use exact names that match our checks
            string lotEditName = "TM_LotEdit" + rowSuffix;
            
            // Safety check for array access
            double lotValue = 0.01; // Default safe value
            if(row >= 0 && row < ArraySize(g_LotSizes)) {
                lotValue = g_LotSizes[row];
            } else {
                Print("WARNING: Invalid row index when creating edit field: ", row);
            }
            
            // Debug print
            Print("Creating lot edit field: ", lotEditName, " for row ", row, " with value ", lotValue);
            
            // Use the values from the g_LotSizes array with safety
            CreateEdit(lotEditName, DoubleToString(lotValue, 2), x + 10, rowY, fixedFieldWidth, fixedFieldHeight);
            
            // Create buttons with equal width and equal spacing, each with a distinct color
            // Use fixed font size for buttons
            int fixedFontSize = 8; // Fixed font size for buttons
            
            CreateButton("TM_B" + rowSuffix, "B", startX, rowY, smallerWidth, fixedButtonHeight, clrDodgerBlue, fixedFontSize);
            CreateButton("TM_S" + rowSuffix, "S", startX + smallerWidth + buttonGap, rowY, smallerWidth, fixedButtonHeight, clrCrimson, fixedFontSize);
            CreateButton("TM_X" + rowSuffix, "X", startX + 2 * (smallerWidth + buttonGap), rowY, smallerWidth, fixedButtonHeight, clrBrown, fixedFontSize);
            CreateButton("TM_P" + rowSuffix, "P", startX + 3 * (smallerWidth + buttonGap), rowY, smallerWidth, fixedButtonHeight, clrIndigo, fixedFontSize);
        }
        
        // Adjust y position after all rows with fixed spacing
        y += (5 * rowSpacing) + 5;

        // Special action buttons - fixed sizes
        int specialButtonSpacing = 10; // Fixed spacing
        int specialButtonWidth = 75;   // Fixed width for special buttons
        int specialButtonHeight = 25;  // Fixed height for special buttons
        int specialFontSize = 10;      // Fixed font size
                
        // Close All button (CA)
        string caName = "TM_CA";
        CreateButton(caName, "CA", x + 10, y, specialButtonWidth, specialButtonHeight, clrGreen, specialFontSize);
        Print("Created CA button: ", caName);
        
        // Close Buy button (CB)
        string cbName = "TM_CB";
        CreateButton(cbName, "CB", x + 5 + specialButtonWidth + specialButtonSpacing, y, specialButtonWidth, specialButtonHeight, clrMidnightBlue, specialFontSize);
        Print("Created CB button: ", cbName);
        
        // Close Sell button (CS)
        string csName = "TM_CS";
        CreateButton(csName, "CS", x + 2 * (specialButtonWidth + specialButtonSpacing), y, specialButtonWidth, specialButtonHeight, clrFireBrick, specialFontSize);
        Print("Created CS button: ", csName);
                
        // Force chart redraw to make sure buttons appear
        ChartRedraw(0);
        // Fixed spacing after special action buttons
        y += specialButtonHeight + 10;

        // Fixed label width and position
        int labelWidth = 120;          // Fixed label width
        int editX = x + labelWidth + 30; // Fixed edit position
        int editWidth = 50;            // Fixed edit width
        int setButtonWidth = 40;       // Fixed set button width
        int setButtonX = editX + editWidth + 5; // Fixed set button position
        
        // Combined Stop Loss (price level) - white text with input field and Set button
        int labelFontSize = 9;         // Fixed font size
        CreateLabel("TM_CSLLabel", "Combined SL (price):", x + 10, y + 5, clrWhite, labelFontSize, "Arial");
        CreateEdit(g_CSLEdit, "0.0", editX, y, editWidth, fixedFieldHeight);
        CreateFixedButton(g_CSLSetButton, "SET", setButtonX, y, setButtonWidth, fixedFieldHeight, clrGreen, labelFontSize);
        
        y += fixedFieldHeight + 10;    // Fixed spacing

        // No-trail zone - white text with input field and Set button
        CreateLabel("TM_NoTrailZoneLabel", "No-trail zone (pips):", x + 10, y, clrWhite, labelFontSize, "Arial");
        CreateEdit(g_NoTrailZoneEdit, DoubleToString(g_NoTrailZone, 1), editX, y, editWidth, fixedFieldHeight);
        CreateFixedButton(g_NoTrailZoneSetButton, "SET", setButtonX, y, setButtonWidth, fixedFieldHeight, clrGreen, labelFontSize);
        
        y += fixedFieldHeight + 10;    // Fixed spacing
        
        // Trailing stop - white text with input field and Set button
        CreateLabel("TM_TrailingStopLabel", "Trailing stop (pips):", x + 10, y, clrWhite, labelFontSize, "Arial");
        CreateEdit(g_TrailingStopEdit, DoubleToString(g_TrailingStop, 1), editX, y, editWidth, fixedFieldHeight);
        CreateFixedButton(g_TrailingStopSetButton, "SET", setButtonX, y, setButtonWidth, fixedFieldHeight, clrGreen, labelFontSize);
        
        y += fixedFieldHeight + 10;    // Fixed spacing
        
        // Combined Take Profit - white text with input field and Set button
        CreateLabel("TM_CTPLabel", "Combined TP (price):", x + 10, y, clrWhite, labelFontSize, "Arial");
        CreateEdit(g_CTPEdit, DoubleToString(g_CombinedTP, 5), editX, y, editWidth, fixedFieldHeight);
        CreateFixedButton(g_CTPSetButton, "SET", setButtonX, y, setButtonWidth, fixedFieldHeight, clrGreen, labelFontSize);
        
        y += fixedFieldHeight + 10;    // Add spacing after Combined TP
        
        // Add profit/loss labels on separate rows between Combined TP and Hide Panel
        // Buy P/L label - first row
        CreateLabel(g_BuyPLLabel, "Buy P/L: +0.00", x + 10, y, clrLime, 10, "Arial Bold");
        
        y += 30;    // Add spacing between P/L rows
        
        // Sell P/L label - second row
        CreateLabel(g_SellPLLabel, "Sell P/L: +0.00", x + 10, y, clrLime, 10, "Arial Bold");
        
        y += 30;    // Add spacing before hide button
        
        // Hide button - wider button that spans most of the panel width
        int hideButtonWidth = 230;  // Make it wider
        CreateFixedButton(g_HideButton, "HIDE PANEL", x + 10, y, hideButtonWidth, fixedFieldHeight, clrOrange, labelFontSize);
        // Set text color to black
        ObjectSetInteger(0, g_HideButton, OBJPROP_COLOR, clrBlack);
        
        // No need to add chart event handler here as it's already set in OnInit
        
        // Initialize the profit/loss display
        UpdateProfitLossDisplay();
    }

//+------------------------------------------------------------------+
//| Create a special non-draggable button (for Set button)           |
//+------------------------------------------------------------------+
    void CreateFixedButton(string name, string text, int x, int y, int width, int height, color clr, int fontSize = 10)
    {
        // Delete button if it already exists
        if(ObjectFind(0, name) >= 0) {
            ObjectDelete(0, name);
        }
        
        // Create the button
        if(!ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0)) {
            Print("Failed to create fixed button: ", name, ". Error: ", GetLastError());
            return;
        }
        
        // Set button properties
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
        ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_STATE, false);
        
        // Critical settings to prevent dragging
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);  // Not selectable
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);    // Not selected
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);      // Visible
        ObjectSetInteger(0, name, OBJPROP_ZORDER, 200);        // Highest Z-order
        
        // Text properties
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrWhite);
        
        // Debug print
        Print("Fixed button created: ", name, " at position ", x, ",", y, " - width: ", width, ", height: ", height);
        
        // Force chart redraw to make sure button appears
        ChartRedraw(0);
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
        ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
        ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clr);
        ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, (int)clrBlack);
        ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_CORNER, Panel_Corner);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, name, OBJPROP_BACK, false);
        ObjectSetInteger(0, name, OBJPROP_STATE, false);
        
        // Critical settings for clickability
        ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false); // Make not selectable for dragging
        ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);     // Make visible
        ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);      // Bring to front
        
        // These settings help prevent dragging
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER); // Anchor firmly
        ObjectSetInteger(0, name, OBJPROP_READONLY, true);   // Make not editable
        
        // Text properties
        ObjectSetString(0, name, OBJPROP_TEXT, text);
        ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetInteger(0, name, OBJPROP_COLOR, (int)clrWhite);
        
        // Debug print
        Print("Button created: ", name, " at position ", x, ",", y, " - width: ", width, ", height: ", height);
        
        // Force chart redraw to make sure button appears
        ChartRedraw(0);
    }

//+------------------------------------------------------------------+
//| Create a label                                                   |
//+------------------------------------------------------------------+
    void CreateLabel(string name, string text, int x, int y, color clr, int fontSize = 10, string font = "Arial")
    {
        // Delete label if it already exists
        if(ObjectFind(0, name) >= 0) {
            ObjectDelete(0, name);
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
        
        // Use fixed font size
        int fontSize = 8;
        
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
//| Manage trailing stop with no-trail zone                         |
//+------------------------------------------------------------------+
    void ManageTrailingStop()
    {
        // If trailing stop is not set or combined TP is active, don't do anything
        if(g_TrailingStop <= 0 || g_CombinedTP > 0.0) return;
        
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
                
                    // Only trail if profit exceeds no-trail zone
                        if(currentProfit >= g_NoTrailZone)
                        {
                            // Calculate new stop loss level
                            double newSL = NormalizeDouble(Bid - g_TrailingStop * Point * 10, Digits);
                            
                            // Only modify if the new SL is higher than the current one (or no SL is set)
                            if(newSL > OrderStopLoss() || OrderStopLoss() == 0)
                            {
                                bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrGreen);
                                if(!result)
                                    Print("OrderModify error(Trailing Stop): ", GetLastError());
                                else
                                    Print("Trailing stop updated for Buy order #", OrderTicket(), ", new SL: ", newSL);
                            }
                        }
                    }
                // Sell orders
                    else if(OrderType() == OP_SELL)
                    {
                        double currentProfit = (OrderOpenPrice() - Ask) / Point / 10;
                
                    // Only trail if profit exceeds no-trail zone
                        if(currentProfit >= g_NoTrailZone)
                        {
                            // Calculate new stop loss level
                            double newSL = NormalizeDouble(Ask + g_TrailingStop * Point * 10, Digits);
                            
                            // Only modify if the new SL is lower than the current one (or no SL is set)
                            if(newSL < OrderStopLoss() || OrderStopLoss() == 0)
                            {
                                bool result = OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), 0, clrRed);
                                if(!result)
                                    Print("OrderModify error(Trailing Stop): ", GetLastError());
                                else
                                    Print("Trailing stop updated for Sell order #", OrderTicket(), ", new SL: ", newSL);
                            }
                        }
                    }
                }
            }
        }
    }
    
//+------------------------------------------------------------------+
//| Manage combined take profit                                      |
//+------------------------------------------------------------------+
    void ManageCombinedTakeProfit()
    {
        // Get the current combined TP value from the global variable
        // This value is updated when the Set button is clicked
        if(g_CombinedTP < 0) return; // Only return if negative, allow 0.0
        
        // Update the display in the edit field to show the current value
        if(ObjectFind(0, g_CTPEdit) >= 0) {
            ObjectSetString(0, g_CTPEdit, OBJPROP_TEXT, DoubleToString(g_CombinedTP, 5));
        }
        
        // If g_CombinedTP is 0.0, there's no take profit to check, so return
        if(g_CombinedTP == 0.0) return;

        // For buy orders
        bool hasBuyOrders = false;
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol() && OrderType() == OP_BUY)
                {
                    hasBuyOrders = true;
                    if(Bid >= g_CombinedTP)
                    {
                        Print("Combined TP triggered for BUY orders at price: ", Bid, ", TP level: ", g_CombinedTP);
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
                    if(Ask <= g_CombinedTP && g_CombinedTP > 0)
                    {
                        Print("Combined TP triggered for SELL orders at price: ", Ask, ", TP level: ", g_CombinedTP);
                        CloseSellPositions(100);
                        break;
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
        // Get the current combined SL value from the global variable
        // This value is updated when the Set button is clicked
        if(g_CombinedSL < 0) return; // Only return if negative, allow 0.0
        
        // Update the display in the edit field to show the current value
        if(ObjectFind(0, g_CSLEdit) >= 0) {
            ObjectSetString(0, g_CSLEdit, OBJPROP_TEXT, DoubleToString(g_CombinedSL, 5));
        }
        
        // If g_CombinedSL is 0.0, there's no stop loss to check, so return
        if(g_CombinedSL == 0.0) return;

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
                        Print("Combined SL triggered for BUY orders at price: ", Bid, ", SL level: ", g_CombinedSL);
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
                        Print("Combined SL triggered for SELL orders at price: ", Ask, ", SL level: ", g_CombinedSL);
                        CloseSellPositions(100);
                        break;
                    }
                }
            }
        }
    }
    
//+------------------------------------------------------------------+
//| Hide all panel elements except the title                         |
//+------------------------------------------------------------------+
    void HideTradePanel()
    {
        Print("Hiding trade panel elements");
        g_IsPanelHidden = true;
        
        // Store all objects we need to hide
        int totalObjects = ObjectsTotal(0, -1, -1);
        string objectsToHide[150]; // Array to store objects to hide
        int hideCount = 0;
        
        // First pass: collect all objects to hide
        for(int i = 0; i < totalObjects; i++)
        {
            string objName = ObjectName(0, i);
            
            // Skip the title
            if(objName == "TM_Title")
                continue;
                
            // Skip the show button
            if(objName == g_ShowButton)
                continue;
                
            // Skip max loss overlay objects
            if(objName == g_MaxLossOverlayName || objName == g_MaxLossMessageName || objName == g_MaxLossCountdownName)
                continue;
            
            // Process Trade Manager objects (starting with TM_)
            if(StringSubstr(objName, 0, 3) == "TM_")
            {
                objectsToHide[hideCount++] = objName;
                Print("Will hide TM_ object: ", objName);
            }
            
            // Also collect specific edit fields and set buttons that don't have TM_ prefix
            if(objName == g_CSLEdit || objName == g_CSLSetButton ||
               objName == g_NoTrailZoneEdit || objName == g_NoTrailZoneSetButton ||
               objName == g_TrailingStopEdit || objName == g_TrailingStopSetButton ||
               objName == g_CTPEdit || objName == g_CTPSetButton ||
               objName == "CSLLabel" || objName == "NoTrailZoneLabel" || objName == "TrailingStopLabel" ||
               objName == "TM_CTPLabel" || objName == g_BuyPLLabel || objName == g_SellPLLabel)
            {
                objectsToHide[hideCount++] = objName;
                Print("Will hide specific object: ", objName);
            }
        }
        
        // Make sure the show button is visible
        ObjectSetInteger(0, g_ShowButton, OBJPROP_HIDDEN, false);
        
        // Second pass: hide all collected objects
        for(int i = 0; i < hideCount; i++)
        {
            // Try different ways to hide the object
            ObjectSetInteger(0, objectsToHide[i], OBJPROP_HIDDEN, true); // Standard hiding
            ObjectSetInteger(0, objectsToHide[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS); // Hide in all timeframes
            ObjectSetInteger(0, objectsToHide[i], OBJPROP_BACK, true); // Send to background
            ObjectSetInteger(0, objectsToHide[i], OBJPROP_SELECTED, false); // Unselect
            ObjectSetInteger(0, objectsToHide[i], OBJPROP_SELECTABLE, false); // Make unselectable
            
            // Move the object far away as a fallback
            long x = 0, y = 0;
            if(ObjectGetInteger(0, objectsToHide[i], OBJPROP_XDISTANCE, 0, x) && 
               ObjectGetInteger(0, objectsToHide[i], OBJPROP_YDISTANCE, 0, y))
            {
                ObjectSetInteger(0, objectsToHide[i], OBJPROP_XDISTANCE, 5000); // Move far off screen
                ObjectSetInteger(0, objectsToHide[i], OBJPROP_YDISTANCE, 5000); // Move far off screen
            }
            
            Print("Applied multiple hide methods to: ", objectsToHide[i]);
        }
        
        // Force chart redraw
        ChartRedraw(0);
    }

//+------------------------------------------------------------------+
//| Show all panel elements                                          |
//+------------------------------------------------------------------+
    void ShowTradePanel()
    {
        Print("Showing trade panel elements");
        g_IsPanelHidden = false;
        
        // Hide the show button
        ObjectSetInteger(0, g_ShowButton, OBJPROP_HIDDEN, true);
        
        // The simplest solution is to recreate the entire panel
        // This ensures all elements are properly visible
        CreateTradePanel();
        
        // If max loss is triggered, make sure the overlay is still visible
        if(g_MaxLossTriggered) {
            ShowMaxLossOverlay();
        }
        
        Print("Recreated trade panel to ensure all elements are visible");
        
        // Force chart redraw
        ChartRedraw(0);
    }

//+------------------------------------------------------------------+
//| Apply combined stop loss to all active orders                     |
//+------------------------------------------------------------------+
    void ApplyCombinedStopLoss(double stopLossPrice)
    {
        // Allow stopLossPrice to be 0.0 to remove stop loss
        // Only return if it's negative
        if(stopLossPrice < 0) return;
        
        int totalModified = 0;
        int totalOrders = 0;
        
        // Loop through all orders
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol())
                {
                    totalOrders++;
                    double currentSL = OrderStopLoss();
                    bool needModify = false;
                    
                    // Special case: if stopLossPrice is 0.0, we're removing the stop loss
                    if(stopLossPrice == 0.0 && currentSL != 0.0)
                    {
                        needModify = true; // Remove existing stop loss
                    }
                    // Normal case: setting a non-zero stop loss
                    else if(stopLossPrice > 0.0)
                    {
                        // For buy orders, stop loss should be below current price
                        if(OrderType() == OP_BUY)
                        {
                            // Only modify if the new SL is different from the current one
                            // and the new SL is below the current price (valid SL for buy)
                            if(stopLossPrice < Bid && (MathAbs(currentSL - stopLossPrice) > Point || currentSL == 0))
                            {
                                needModify = true;
                            }
                        }
                        // For sell orders, stop loss should be above current price
                        else if(OrderType() == OP_SELL)
                        {
                            // Only modify if the new SL is different from the current one
                            // and the new SL is above the current price (valid SL for sell)
                            if(stopLossPrice > Ask && (MathAbs(currentSL - stopLossPrice) > Point || currentSL == 0))
                            {
                                needModify = true;
                            }
                        }
                    }
                    
                    // Modify the order if needed
                    if(needModify)
                    {
                        bool result = OrderModify(
                            OrderTicket(),
                            OrderOpenPrice(),
                            stopLossPrice,
                            OrderTakeProfit(),
                            0,
                            OrderType() == OP_BUY ? clrBlue : clrRed
                        );
                        
                        if(result)
                        {
                            totalModified++;
                            Print("Modified ", OrderType() == OP_BUY ? "Buy" : "Sell", " order #", OrderTicket(), ", SL set to ", stopLossPrice);
                        }
                        else
                        {
                            Print("Failed to modify order #", OrderTicket(), ", Error: ", GetLastError());
                        }
                    }
                }
            }
        }
        
        Print("Combined SL applied: Modified ", totalModified, " of ", totalOrders, " orders");
    }
    
//+------------------------------------------------------------------+
//| Apply combined take profit to all active orders                    |
//+------------------------------------------------------------------+
    void ApplyCombinedTakeProfit(double takeProfitPrice)
    {
        // Allow takeProfitPrice to be 0.0 to remove take profit
        // Only return if it's negative
        if(takeProfitPrice < 0) return;
        
        int totalModified = 0;
        int totalOrders = 0;
        
        // If combined TP is active, disable trailing stop and no-trail zone
        if(takeProfitPrice > 0.0) {
            g_TrailingStop = 0.0;
            g_NoTrailZone = 0.0;
            
            // Update the edit fields
            if(ObjectFind(0, g_TrailingStopEdit) >= 0) {
                ObjectSetString(0, g_TrailingStopEdit, OBJPROP_TEXT, "0.0");
            }
            if(ObjectFind(0, g_NoTrailZoneEdit) >= 0) {
                ObjectSetString(0, g_NoTrailZoneEdit, OBJPROP_TEXT, "0.0");
            }
        }
        
        // Loop through all orders
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol())
                {
                    totalOrders++;
                    double currentTP = OrderTakeProfit();
                    bool needModify = false;
                    
                    // Special case: if takeProfitPrice is 0.0, we're removing the take profit
                    if(takeProfitPrice == 0.0 && currentTP != 0.0)
                    {
                        needModify = true; // Remove existing take profit
                    }
                    // Normal case: setting a non-zero take profit
                    else if(takeProfitPrice > 0.0)
                    {
                        // For buy orders, take profit should be above current price
                        if(OrderType() == OP_BUY)
                        {
                            // Only modify if the new TP is different from the current one
                            // and the new TP is above the current price (valid TP for buy)
                            if(takeProfitPrice > Bid && (MathAbs(currentTP - takeProfitPrice) > Point || currentTP == 0))
                            {
                                needModify = true;
                            }
                        }
                        // For sell orders, take profit should be below current price
                        else if(OrderType() == OP_SELL)
                        {
                            // Only modify if the new TP is different from the current one
                            // and the new TP is below the current price (valid TP for sell)
                            if(takeProfitPrice < Ask && (MathAbs(currentTP - takeProfitPrice) > Point || currentTP == 0))
                            {
                                needModify = true;
                            }
                        }
                    }
                    
                    // Modify the order if needed
                    if(needModify)
                    {
                        bool result = OrderModify(
                            OrderTicket(),
                            OrderOpenPrice(),
                            OrderStopLoss(),
                            takeProfitPrice,
                            0,
                            OrderType() == OP_BUY ? clrBlue : clrRed
                        );
                        
                        if(result)
                        {
                            totalModified++;
                            Print("Modified ", OrderType() == OP_BUY ? "Buy" : "Sell", " order #", OrderTicket(), ", TP set to ", takeProfitPrice);
                        }
                        else
                        {
                            Print("Failed to modify order #", OrderTicket(), ", Error: ", GetLastError());
                        }
                    }
                }
            }
        }
        
        Print("Combined TP applied: Modified ", totalModified, " of ", totalOrders, " orders");
    }
    
//+------------------------------------------------------------------+
//| Calculate and update the total profit/loss for Buy and Sell orders |
//+------------------------------------------------------------------+
    void UpdateProfitLossDisplay()
    {
        double buyPL = 0.0;
        double sellPL = 0.0;
        
        // Loop through all orders to calculate total profit/loss
        for(int i = 0; i < OrdersTotal(); i++)
        {
            if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
            {
                if(OrderSymbol() == Symbol())
                {
                    // Add profit/loss to the appropriate total
                    if(OrderType() == OP_BUY)
                    {
                        buyPL += OrderProfit();
                    }
                    else if(OrderType() == OP_SELL)
                    {
                        sellPL += OrderProfit();
                    }
                }
            }
        }
        
        // Format the profit/loss strings with + or - sign and 2 decimal places
        string buyPLText = "Buy P/L: ";
        if(buyPL > 0)
            buyPLText += "+" + DoubleToString(buyPL, 2);
        else
            buyPLText += DoubleToString(buyPL, 2);
            
        string sellPLText = "Sell P/L: ";
        if(sellPL > 0)
            sellPLText += "+" + DoubleToString(sellPL, 2);
        else
            sellPLText += DoubleToString(sellPL, 2);
        
        // Update the labels
        if(ObjectFind(0, g_BuyPLLabel) >= 0)
        {
            ObjectSetString(0, g_BuyPLLabel, OBJPROP_TEXT, buyPLText);
            // Set color based on profit/loss
            ObjectSetInteger(0, g_BuyPLLabel, OBJPROP_COLOR, buyPL >= 0 ? clrLime : clrRed);
        }
        
        if(ObjectFind(0, g_SellPLLabel) >= 0)
        {
            ObjectSetString(0, g_SellPLLabel, OBJPROP_TEXT, sellPLText);
            // Set color based on profit/loss
            ObjectSetInteger(0, g_SellPLLabel, OBJPROP_COLOR, sellPL >= 0 ? clrLime : clrRed);
        }
    }