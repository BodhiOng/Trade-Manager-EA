# Trade Manager Expert Advisor

This is a custom MetaTrader 4 (MT4) Trade Manager Expert Advisor (EA) developed using MQL4. The project provides a graphical trading panel that allows traders to manage buy and sell positions directly from the chart interface with advanced trade management utilities such as combined stop loss control, trailing stops, partial close operations, and multi-lot execution support. 

## Project Overview

The Trade Manager EA is designed to simplify manual trade execution and position management within MetaTrader 4. The system creates a fully interactive on-chart trading interface with customizable lot sizes and trade management tools.

The EA supports:

* Multiple configurable lot size rows
* One-click buy and sell execution
* Position closing utilities
* Partial close functionality
* Combined stop loss management
* Trailing stop automation
* No-trail zone configuration
* Interactive chart-based UI controls

## Features

### Trading Panel Interface

The EA dynamically creates an adaptive on-chart control panel with:

* Buy buttons
* Sell buttons
* Close position buttons
* Partial close buttons
* Editable lot size fields
* Combined stop loss controls
* Trailing stop configuration fields

### Trade Execution

The system supports:

* Instant buy order execution
* Instant sell order execution
* Multiple lot size presets
* Symbol-specific order handling

### Position Management

The EA includes advanced position management features:

* Close all positions
* Close buy-only positions
* Close sell-only positions
* Partial close by percentage
* Close positions by matching lot size

### Risk Management

Risk management utilities include:

* Combined stop loss application
* Automatic trailing stop updates
* No-trail profit zone support
* Dynamic stop loss modification

## User Interface Components

### Main Action Buttons

| Button | Function             |
| ------ | -------------------- |
| B      | Open Buy Order       |
| S      | Open Sell Order      |
| X      | Close Orders         |
| P      | Partial Close Orders |
| CA     | Close All Positions  |
| CB     | Close Buy Positions  |
| CS     | Close Sell Positions |

### Input Fields

The interface includes editable fields for:

* Lot size configuration
* Combined stop loss price
* No-trail zone distance
* Trailing stop distance

## Technical Features

### Event-Driven Architecture

The EA uses:

* `OnInit()` for initialization
* `OnTick()` for trade management
* `OnChartEvent()` for UI interaction handling

### Dynamic UI System

The project dynamically generates:

* Labels
* Buttons
* Edit fields
* Chart objects

### Order Management Functions

Implemented trading utilities include:

* `OpenBuyOrder()`
* `OpenSellOrder()`
* `CloseAllPositions()`
* `CloseBuyPositions()`
* `CloseSellPositions()`
* `PartialCloseByLotSize()`
* `ManageTrailingStop()`
* `ApplyCombinedStopLoss()`

## Project Structure

```text
├── TradeManager.mq4          # Main Expert Advisor source file
├── Include/                  # Standard MQL4 include dependencies
│   ├── stdlib.mqh
│   ├── stderror.mqh
│   └── WinUser32.mqh
└── README.md
```

## Requirements

Before running the EA, ensure the following are installed:

* MetaTrader 4 (MT4)
* MetaEditor
* Windows operating system
* MQL4 compiler support

## Installation

### 1. Copy the EA File

Place the `TradeManager.mq4` file into:

```text
MetaTrader 4/MQL4/Experts/
```

### 2. Compile the EA

Open MetaEditor and compile the EA:

```text
TradeManager.mq4
```

### 3. Launch MetaTrader 4

* Open MetaTrader 4
* Navigate to the Navigator panel
* Locate the Expert Advisor
* Drag the EA onto a chart

### 4. Enable Auto Trading

Ensure:

* AutoTrading is enabled
* DLL imports are allowed if required
* Expert Advisors are permitted in MT4 settings

## Usage

### Opening Trades

1. Enter or adjust the desired lot size
2. Click:

   * `B` for Buy
   * `S` for Sell

### Closing Trades

Use:

* `X` to close positions by lot size
* `CA` to close all positions
* `CB` to close buy positions
* `CS` to close sell positions

### Partial Close

Click `P` to partially close matching positions using predefined percentages.

### Combined Stop Loss

1. Enter a stop loss price
2. Press `SET`
3. The EA applies the stop loss to all active positions

### Trailing Stop

1. Enter:

   * No-trail zone
   * Trailing stop distance
2. Press `SET`
3. The EA automatically manages trailing stops on active trades

## Implementation Details

### Adaptive Panel Design

The trading panel automatically scales based on chart dimensions to maintain usability across different screen sizes.

### Multi-Lot Trading Rows

The EA supports five independent trading rows with configurable lot sizes:

```text
0.02
0.04
0.06
0.08
0.10
```

### Combined Stop Loss Logic

The EA continuously monitors market price movement and automatically closes positions once the combined stop loss level is reached.

### Trailing Stop Logic

The trailing stop system:

* Activates only after exceeding the no-trail zone
* Dynamically adjusts stop loss levels
* Separately handles buy and sell orders

## Key Technologies

* MQL4
* MetaTrader 4
* Event-driven programming
* Chart object UI system
* Automated trade management

## License

This project is licensed under the MIT License.
