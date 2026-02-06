# NexusLend - Complete Technical Documentation

> A fully functional DeFi lending protocol on Ethereum Sepolia testnet

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Smart Contracts Deep Dive](#smart-contracts-deep-dive)
4. [Frontend Architecture](#frontend-architecture)
5. [Data Flow](#data-flow)
6. [Features & How They Work](#features--how-they-work)
7. [Contract Addresses](#contract-addresses)
8. [Key Formulas](#key-formulas)

---

## 🎯 Project Overview

NexusLend is a **decentralized lending protocol** similar to Aave/Compound. Users can:

- **Supply** assets to earn interest
- **Borrow** assets using collateral
- **Earn** dynamic APY based on utilization
- **Monitor** health factor to avoid liquidation

### Tech Stack

| Layer           | Technology               |
| --------------- | ------------------------ |
| Blockchain      | Ethereum Sepolia Testnet |
| Smart Contracts | Solidity 0.8.20, Foundry |
| Frontend        | React + Vite             |
| Web3            | wagmi, viem              |
| Styling         | Vanilla CSS              |
| Wallet          | MetaMask (RainbowKit)    |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        FRONTEND                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Dashboard  │  │   Markets   │  │   Transaction Modal │  │
│  │  - Stats    │  │  - TVL      │  │   - Supply          │  │
│  │  - Assets   │  │  - APY      │  │   - Borrow          │  │
│  │  - Health   │  │  - Prices   │  │   - Approve         │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │             │
│         └────────────────┼─────────────────────┘             │
│                          │                                   │
│                    ┌─────▼─────┐                            │
│                    │   wagmi   │  (React Hooks)             │
│                    │   viem    │  (Contract Calls)          │
│                    └─────┬─────┘                            │
└──────────────────────────┼──────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   Sepolia   │
                    │   Testnet   │
                    └──────┬──────┘
                           │
┌──────────────────────────┼──────────────────────────────────┐
│                    SMART CONTRACTS                           │
│                          │                                   │
│  ┌───────────────────────▼───────────────────────────────┐  │
│  │                    NexusPool                           │  │
│  │  - supply(asset, amount)                               │  │
│  │  - withdraw(asset, amount)                             │  │
│  │  - borrow(asset, amount)                               │  │
│  │  - repay(asset, amount)                                │  │
│  │  - userPositions[user][asset]                          │  │
│  │  - totalLiquidity[asset]                               │  │
│  │  - totalBorrows[asset]                                 │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│         ┌────────────────┼────────────────┐                 │
│         │                │                │                 │
│  ┌──────▼──────┐  ┌──────▼──────┐  ┌──────▼──────┐         │
│  │ PriceOracle │  │InterestRate │  │   NToken    │         │
│  │             │  │   Model     │  │  (Receipt)  │         │
│  │ getPrice()  │  │getBorrowRate│  │  nWETH      │         │
│  │ (18 dec)    │  │getSupplyRate│  │  nUSDC      │         │
│  └─────────────┘  │ (RAY=1e27)  │  │  nDAI       │         │
│                   └─────────────┘  └─────────────┘         │
│                                                              │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                    Mock Tokens                          ││
│  │     mWETH (18 dec)  │  mUSDC (6 dec)  │  mDAI (18 dec)  ││
│  └─────────────────────────────────────────────────────────┘│
└──────────────────────────────────────────────────────────────┘
```

---

## 📜 Smart Contracts Deep Dive

### 1. NexusPool.sol - The Heart of the Protocol

**Purpose:** Main lending pool that handles all user interactions

**Key State Variables:**

```solidity
mapping(address => mapping(address => UserPosition)) public userPositions;
// userPositions[user][asset] = { deposited, borrowed, borrowIndex, lastUpdateTime }

mapping(address => uint256) public totalLiquidity;  // Available tokens in pool
mapping(address => uint256) public totalBorrows;    // Total borrowed per asset
mapping(address => AssetConfig) public assetConfigs; // LTV, thresholds, etc.
```

**Key Functions:**

| Function                  | What It Does                                             |
| ------------------------- | -------------------------------------------------------- |
| `supply(asset, amount)`   | Deposit tokens → Receive nTokens → Earn interest         |
| `withdraw(asset, amount)` | Burn nTokens → Get tokens back → Check health factor     |
| `borrow(asset, amount)`   | Take loan → Must have collateral → Health factor > 1     |
| `repay(asset, amount)`    | Pay back loan + interest → Reduce borrowed amount        |
| `getHealthFactor(user)`   | Calculate position safety (>1 = safe, <1 = liquidatable) |

**How Supply Works:**

```
1. User approves NexusPool to spend their tokens
2. User calls supply(mWETH, 1e18)  // 1 WETH
3. Pool transfers 1 WETH from user
4. Pool mints 1 nWETH to user (receipt token)
5. userPositions[user][mWETH].deposited += 1e18
6. totalLiquidity[mWETH] += 1e18
```

**How Borrow Works:**

```
1. User must have collateral deposited first
2. User calls borrow(mUSDC, 1000e6)  // 1000 USDC
3. Pool checks: will health factor stay > 1?
4. If yes: transfer 1000 USDC to user
5. userPositions[user][mUSDC].borrowed += 1000e6
6. totalBorrows[mUSDC] += 1000e6
7. totalLiquidity[mUSDC] -= 1000e6  // Leaves the pool!
```

---

### 2. MockPriceOracle.sol - Asset Prices

**Purpose:** Provides USD prices for all assets (in production: Chainlink)

**Format:** Prices in 18 decimals

```solidity
// Example prices set:
prices[mWETH] = 3000e18  // 1 ETH = $3000
prices[mUSDC] = 1e18     // 1 USDC = $1
prices[mDAI] = 1e18      // 1 DAI = $1
```

**Usage:**

```solidity
uint256 price = priceOracle.getPrice(mWETH);  // Returns 3000e18
```

---

### 3. InterestRateModel.sol - Dynamic APY

**Purpose:** Calculates borrow/supply rates based on utilization

**The Two-Slope Model:**

```
Rate
  │
  │                    ╱ Slope2 (steep!)
  │                   ╱
  │          ────────╱ ← Kink at 80% utilization
  │         ╱ Slope1
  │        ╱
  │───────╱
  └─────────────────────── Utilization %
       0%     80%    100%
```

**Key Parameters:**

```solidity
uint256 public baseRatePerYear;      // 2% base rate
uint256 public slope1;                // 10% increase below optimal
uint256 public slope2;                // 100% increase above optimal (steep!)
uint256 public optimalUtilization;    // 80% kink point
```

**Formulas:**

```solidity
// Utilization Rate
utilization = totalBorrows / (totalBorrows + totalLiquidity)

// Borrow Rate (below optimal)
borrowRate = baseRate + (utilization / optimal) * slope1

// Borrow Rate (above optimal - STEEP!)
borrowRate = baseRate + slope1 + ((utilization - optimal) / (1 - optimal)) * slope2

// Supply Rate
supplyRate = borrowRate * utilization * (1 - reserveFactor)
```

**Format:** All rates in RAY (1e27 = 100%)

---

### 4. NToken.sol - Receipt Tokens

**Purpose:** ERC20 tokens representing deposits (like Aave's aTokens)

| Deposit | Receive |
| ------- | ------- |
| mWETH   | nWETH   |
| mUSDC   | nUSDC   |
| mDAI    | nDAI    |

**Why?**

- Proves you deposited
- Can be transferred/traded
- Burns when you withdraw

---

### 5. MockToken.sol - Test Tokens

**Purpose:** ERC20 tokens for testing on Sepolia

| Token | Decimals | Purpose          |
| ----- | -------- | ---------------- |
| mWETH | 18       | Mock Wrapped ETH |
| mUSDC | 6        | Mock USD Coin    |
| mDAI  | 18       | Mock DAI         |

**Features:**

- Anyone can mint (for testing)
- Standard ERC20 functions

---

## 🖥️ Frontend Architecture

### Component Structure

```
src/
├── App.jsx              # Main app component
├── main.jsx             # React entry + wagmi config
├── index.css            # All styles
├── components/
│   ├── index.js         # Exports all components
│   ├── Header.jsx       # Navbar + wallet connect
│   ├── Footer.jsx       # Footer
│   ├── StatsCard.jsx    # Dashboard stat cards
│   ├── AssetRow.jsx     # Asset table row
│   ├── TransactionModal.jsx  # Supply/Borrow modal
│   ├── EmptyState.jsx   # Not connected state
│   ├── MarketsPage.jsx  # Markets tab content
│   └── StakePage.jsx    # Stake tab content
└── lib/
    └── contracts.js     # Contract addresses + ABIs
```

### Key Data Reads (wagmi hooks)

**From NexusPool:**

```javascript
// User positions
useReadContract({
  address: CONTRACTS.NexusPool,
  abi: NEXUS_POOL_ABI,
  functionName: "userPositions",
  args: [userAddress, tokenAddress],
});
// Returns: [deposited, borrowed, borrowIndex, lastUpdateTime]

// Total liquidity
useReadContract({
  functionName: "totalLiquidity",
  args: [tokenAddress],
});

// Total borrows
useReadContract({
  functionName: "totalBorrows",
  args: [tokenAddress],
});
```

**From PriceOracle:**

```javascript
useReadContract({
  address: CONTRACTS.PriceOracle,
  abi: PRICE_ORACLE_ABI,
  functionName: "getPrice",
  args: [tokenAddress],
});
// Returns: price in 18 decimals (e.g., 3000e18 for ETH)
```

**From InterestRateModel:**

```javascript
// Borrow Rate
useReadContract({
  address: CONTRACTS.InterestRateModel,
  abi: INTEREST_RATE_MODEL_ABI,
  functionName: "getBorrowRate",
  args: [totalBorrows, totalLiquidity],
});
// Returns: rate in RAY (1e27 = 100%)

// Supply Rate
useReadContract({
  functionName: "getSupplyRate",
  args: [totalBorrows, totalLiquidity, reserveFactor],
});
```

### Transaction Flow

**Supply Flow:**

```
1. User clicks "Supply" button
2. Modal opens → User enters amount
3. Check allowance → If insufficient, call approve()
4. Wait for approval confirmation
5. Call supply(asset, amount) on NexusPool
6. Wait for transaction confirmation
7. Refetch all balances and positions
8. Close modal with success message
```

**Borrow Flow:**

```
1. User clicks "Borrow" button
2. Modal opens → User enters amount
3. No approval needed (borrowing, not depositing)
4. Call borrow(asset, amount) on NexusPool
5. Contract checks health factor
6. If health factor stays > 1 → Success
7. Tokens transferred to user
8. Refetch all data
```

---

## 🔄 Data Flow

### How Values are Calculated

**1. Net Worth (Wallet Balance)**

```javascript
netWorth = (wethBalance × wethPrice) + (usdcBalance × usdcPrice) + (daiBalance × daiPrice)
```

**2. Total Supplied**

```javascript
totalSupplied =
  (userPositions[mWETH].deposited × wethPrice) +
  (userPositions[mUSDC].deposited × usdcPrice) +
  (userPositions[mDAI].deposited × daiPrice)
```

**3. Total Borrowed**

```javascript
totalBorrowed =
  (userPositions[mWETH].borrowed × wethPrice) +
  (userPositions[mUSDC].borrowed × usdcPrice) +
  (userPositions[mDAI].borrowed × daiPrice)
```

**4. Health Factor**

```javascript
healthFactor = (totalSupplied × LTV) / totalBorrowed
// LTV = 0.75 (75%)
// Example: ($471,000 × 0.75) / $63,110 = 5.60
```

**5. APY Conversion**

```javascript
// Contract returns RAY format (1e27 = 100%)
apyPercent = (rateFromContract / 1e27) × 100
// Example: 2.1e25 / 1e27 × 100 = 2.1%
```

**6. Total Value Locked (TVL)**

```javascript
tvl = totalLiquidity[mWETH] + totalLiquidity[mUSDC] + totalLiquidity[mDAI];
// Note: TVL = Deposits - Borrows (available liquidity)
```

---

## ⚙️ Features & How They Work

### Feature 1: Supply Assets

**User Story:** "I want to deposit my tokens to earn interest"

**Flow:**

```
User Wallet → approve() → supply() → nToken minted → Start earning
    │              │           │            │
    │              │           │            └─ Receipt token
    │              │           └─ Tokens transferred to pool
    │              └─ Allow pool to spend tokens
    └─ Has tokens to deposit
```

**What Happens On-Chain:**

1. `ERC20.approve(NexusPool, amount)`
2. `NexusPool.supply(asset, amount)`
3. Pool calls `ERC20.transferFrom(user, pool, amount)`
4. Pool calls `NToken.mint(user, amount)`
5. `userPositions[user][asset].deposited += amount`
6. `totalLiquidity[asset] += amount`

---

### Feature 2: Borrow Assets

**User Story:** "I want to borrow tokens against my collateral"

**Requirements:**

- Must have collateral deposited
- Health factor must stay > 1 after borrow
- Pool must have sufficient liquidity

**Flow:**

```
Check Collateral → Check Health → Transfer Tokens
       │                │               │
       │                │               └─ Tokens sent to user
       │                └─ Must stay > 1
       └─ userPositions[user].deposited > 0
```

**Example:**

```
Collateral: 1 ETH ($3000)
LTV: 75%
Max Borrow: $3000 × 0.75 = $2250

User borrows 1000 USDC ✅ (within limit)
User borrows 3000 USDC ❌ (would make health < 1)
```

---

### Feature 3: Dynamic Interest Rates

**Why Dynamic?**

- Low utilization → Low rates (attract borrowers)
- High utilization → High rates (attract suppliers, discourage borrowers)

**Current Settings:**

```
Base Rate: 2% APY
Optimal Utilization: 80%
Below Optimal: Gentle slope (up to 12%)
Above Optimal: Steep slope (up to 100%+)
```

**Example Calculation:**

```
Pool has: $1,000,000 liquidity
Borrowed: $500,000
Utilization: 50%

Since 50% < 80% (below optimal):
BorrowRate = 2% + (50/80) × 10% = 2% + 6.25% = 8.25%
SupplyRate = 8.25% × 50% × 90% = 3.71%
```

---

### Feature 4: Health Factor Monitoring

**What is Health Factor?**

- Ratio of collateral value to borrowed value
- HF > 1 = Safe
- HF < 1 = Can be liquidated

**Formula:**

```
Health Factor = (Collateral Value × Liquidation Threshold) / Borrowed Value
```

**Example:**

```
Supplied: $100,000 (WETH)
Borrowed: $50,000 (USDC)
Liquidation Threshold: 80%

HF = ($100,000 × 0.80) / $50,000 = 1.6 ✅ Safe!
```

**Risk Levels:**
| Health Factor | Status |
|---------------|--------|
| > 2.0 | 🟢 Very Safe |
| 1.5 - 2.0 | 🟡 Safe |
| 1.0 - 1.5 | 🟠 Risky |
| < 1.0 | 🔴 Liquidatable! |

---

## 📍 Contract Addresses (Sepolia)

| Contract          | Address                                      |
| ----------------- | -------------------------------------------- |
| NexusPool         | `0x087bd3cef36b00d2db4cd381fc76adee4a1b2357` |
| PriceOracle       | `0xa6d224d5744d9bae8c5a71020a5ba82a29b215e4` |
| InterestRateModel | `0xe19e505290e1c4b35a2057798363b0ab8fe70224` |
| mWETH             | `0x27d5315e5f6febe82ee7a4a6fa00e11095c5a70f` |
| mUSDC             | `0x5f2821f166947717187759e205144def4442814a` |
| mDAI              | `0x297c736918352f0f46225ec98cb4a4b0c0a5e16e` |
| nWETH             | `0x684867c6a776fe7c1f66dfea12afe36fab226b2b` |
| nUSDC             | `0x5e9b8ee37a143ed65e307c260af49c1409df4d4c` |
| nDAI              | `0x50369cd07941232651bbcf2d592299b69ba70789` |

---

## 📐 Key Formulas

### Decimal Conversions

| Source         | Format      | Conversion                       |
| -------------- | ----------- | -------------------------------- |
| Token Balance  | Raw BigInt  | `formatUnits(balance, decimals)` |
| Price Oracle   | 18 decimals | `price / 1e18`                   |
| Interest Rates | RAY (1e27)  | `(rate / 1e27) × 100` for %      |
| Health Factor  | RAY (1e27)  | `hf / 1e27`                      |

### USD Value Calculation

```javascript
usdValue = tokenAmount × price
// Example: 10 WETH × $3000 = $30,000
```

### Utilization Rate

```javascript
utilization = totalBorrows / (totalBorrows + totalLiquidity);
// Example: $500K / ($500K + $500K) = 50%
```

### Health Factor

```javascript
healthFactor = (collateralValue × ltv) / borrowedValue
// Example: ($100K × 0.75) / $50K = 1.5
```

---

## 🤖 AI Features (Planned/Future)

NexusLend integrates AI capabilities to enhance user experience and risk management.

### AI Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     AI LAYER                                 │
│                                                              │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐  │
│  │  AI Risk        │  │  AI Yield       │  │  AI Chat    │  │
│  │  Advisor        │  │  Optimizer      │  │  Assistant  │  │
│  └────────┬────────┘  └────────┬────────┘  └──────┬──────┘  │
│           │                    │                   │         │
│           └────────────────────┼───────────────────┘         │
│                                │                             │
│                    ┌───────────▼───────────┐                │
│                    │   AI Processing       │                │
│                    │   (LLM + Analytics)   │                │
│                    └───────────┬───────────┘                │
│                                │                             │
└────────────────────────────────┼─────────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   Blockchain Data       │
                    │   - User Positions      │
                    │   - Market Rates        │
                    │   - Price History       │
                    └─────────────────────────┘
```

### AI Feature 1: Risk Advisor

**Purpose:** Analyzes user position and warns about liquidation risk

**How It Works:**
```
1. Reads user's collateral and borrowed amounts
2. Fetches current asset prices from oracle
3. Calculates real-time health factor
4. Predicts future health based on price volatility
5. Generates personalized risk warnings
```

**AI Output Examples:**
```
🟢 "Your position is healthy. Health factor: 2.5"

🟡 "Warning: Your health factor dropped to 1.3. Consider adding 
    more collateral or repaying some debt."

🔴 "CRITICAL: Health factor at 1.05! If ETH drops 5%, you will 
    be liquidated. Immediate action recommended."
```

**Risk Factors Analyzed:**
| Factor | Weight | Description |
|--------|--------|-------------|
| Health Factor | 40% | Current HF value |
| Price Volatility | 25% | 24h price movement |
| Utilization Rate | 15% | Pool utilization affects rates |
| Collateral Type | 20% | ETH more volatile than stables |

---

### AI Feature 2: Yield Optimizer

**Purpose:** Recommends best supply/borrow strategies for maximum returns

**How It Works:**
```
1. Analyzes current APY rates across all pools
2. Considers user's risk tolerance
3. Evaluates gas costs vs. potential gains
4. Suggests optimal allocation strategy
```

**AI Recommendations:**
```
📈 "Move 30% of your mUSDC to mDAI pool for 1.2% higher APY"

💡 "Current WETH supply APY is low (0.5%). Consider borrowing 
    against it to maximize capital efficiency."

⚡ "High utilization detected in USDC pool. Supply now to 
    capture 8.5% APY before rates normalize."
```

**Optimization Strategies:**
| Strategy | Risk Level | Description |
|----------|------------|-------------|
| Conservative | Low | Maximize stable coin yields |
| Balanced | Medium | Mix of ETH and stable yields |
| Aggressive | High | Leverage positions for max returns |

---

### AI Feature 3: Portfolio Analyzer

**Purpose:** Summarizes DeFi position in plain English

**Input:** Raw blockchain data
```javascript
{
  supplied: { mWETH: 157n * 10n**18n, mUSDC: 0n, mDAI: 0n },
  borrowed: { mWETH: 0n, mUSDC: 63110n * 10n**6n, mDAI: 0n },
  prices: { mWETH: 3000, mUSDC: 1, mDAI: 1 }
}
```

**AI Output:**
```
📊 Portfolio Summary:

You have supplied 157 ETH worth $471,000 as collateral.
You borrowed $63,110 in USDC stablecoins.

Your borrowing power used: 17.8%
Available to borrow: $290,640 more

Current health: SAFE (HF: 5.60)
You can safely borrow an additional $200K before reaching 
moderate risk levels.

💰 Earnings: You're earning 0.59% APY on your ETH supply
📤 Costs: You're paying 2.10% APY on your USDC borrow
```

---

### AI Feature 4: Chat Assistant

**Purpose:** Natural language interface for DeFi interactions

**Supported Commands:**
| User Says | AI Action |
|-----------|-----------|
| "What's my health factor?" | Fetches and explains HF |
| "Supply 10 ETH" | Opens supply modal with 10 ETH |
| "How much can I borrow?" | Calculates max borrow amount |
| "Am I at risk?" | Runs risk analysis |
| "Best APY right now?" | Compares all pool rates |
| "Explain liquidation" | Educational response |

**Example Conversation:**
```
User: "How much USDC can I safely borrow?"

AI: "Based on your 157 ETH collateral worth $471,000:
     
     💰 Maximum borrow: $353,250 (75% LTV)
     ⚠️ Safe borrow: $235,500 (keeps HF > 1.5)
     ✅ Current borrowed: $63,110
     
     You can safely borrow $172,390 more USDC 
     while maintaining a healthy position.
     
     Would you like me to prepare a borrow transaction?"
```

---

### AI Feature 5: Price Prediction & Alerts

**Purpose:** Predicts price movements and sends alerts

**How It Works:**
```
1. Analyzes historical price data
2. Uses ML models to predict short-term movements
3. Sends alerts when action is needed
```

**Alert Types:**
```
📉 PRICE ALERT: ETH dropped 8% in 1 hour. 
   Your health factor is now 1.8. Monitor closely.

📈 OPPORTUNITY: DAI supply APY spiked to 12%! 
   Consider reallocating funds.

⏰ RATE CHANGE: USDC borrow rate increased from 2% to 5%.
   Your daily interest cost increased by $4.20.
```

---

### AI Implementation Architecture

**Backend Stack:**
```
┌─────────────────────────────────────────┐
│           AI Backend Service             │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │         LLM Integration            │ │
│  │  - OpenAI GPT-4 / Claude API      │ │
│  │  - Custom prompts for DeFi        │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │       Analytics Engine             │ │
│  │  - Risk calculations               │ │
│  │  - Yield optimization              │ │
│  │  - Price predictions               │ │
│  └──────────────┬─────────────────────┘ │
│                 │                        │
│  ┌──────────────▼─────────────────────┐ │
│  │       Data Aggregator              │ │
│  │  - User positions (on-chain)       │ │
│  │  - Price feeds (Chainlink)         │ │
│  │  - Historical data (The Graph)     │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

**API Endpoints:**
```
POST /api/ai/risk-analysis
  → Analyzes user position, returns risk assessment

POST /api/ai/yield-optimize  
  → Returns optimal allocation strategy

POST /api/ai/chat
  → Natural language queries

GET /api/ai/alerts/:address
  → Returns active alerts for user
```

**Frontend Integration:**
```javascript
// AI Risk Advisor Hook
const { risk, loading } = useAIRiskAnalysis(userAddress)

// AI Chat
const { response } = useAIChat("How much can I borrow?")

// AI Yield Suggestions
const { suggestions } = useAIYieldOptimizer(userPositions)
```

---

### AI Safety & Limitations

**Guardrails:**
- AI cannot execute transactions without user approval
- All suggestions require user confirmation
- Risk warnings are conservative (better safe than sorry)
- AI disclaims it's not financial advice

**Limitations:**
- Cannot predict black swan events
- Price predictions are estimates, not guarantees
- Recommendations based on historical data
- Always DYOR (Do Your Own Research)

---

## 🧠 AI Credit Score System (Core Innovation)

> **What makes NexusLend different from Aave/Compound**

| Feature | Aave/Compound | NexusLend AI |
|---------|---------------|--------------|
| Collateral Required | 150%+ always | 80-150% based on trust score |
| Liquidation Warning | None | AI predicts & alerts |
| Auto-Protection | None | AI auto-manages position |
| Liquidation Style | Instant 100% | Gradual with grace period |

### CreditScorer.sol - On-Chain Reputation

**Purpose:** Calculates trust score (0-100) to adjust collateral requirements

**Score Calculation:**
```
┌─────────────────────────────────────────────────────────────┐
│                 AI CREDIT SCORE (0-100)                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Wallet Age ────────────────────────────── 0-20 pts         │
│  (> 1 year = 20 pts, < 1 month = 0 pts)                     │
│                                                              │
│  Transaction History ───────────────────── 0-15 pts         │
│  (1000+ txs = 15 pts, 0-10 txs = 0 pts)                     │
│                                                              │
│  Loan Repayment History ────────────────── 0-30 pts ⭐       │
│  (Always repaid on time = 30 pts, defaults = 0 pts)         │
│                                                              │
│  Asset Diversity ───────────────────────── 0-10 pts         │
│  (10+ different tokens = 10 pts)                             │
│                                                              │
│  DeFi Activity ─────────────────────────── 0-15 pts         │
│  (Active on Aave, Compound, Uniswap = 15 pts)               │
│                                                              │
│  Social Verification ───────────────────── 0-10 pts         │
│  (ENS name, Twitter verified = 10 pts)                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
           ┌───────────────────────────────┐
           │    COLLATERAL REQUIREMENTS    │
           ├───────────────────────────────┤
           │ Score 90+  → Only 80% needed  │
           │ Score 50-89 → 120% needed     │
           │ Score <50  → 150% needed      │
           └───────────────────────────────┘
```

**Contract Functions:**
```solidity
function getCreditScore(address user) public view returns (uint256);
function getCollateralFactor(address user) public view returns (uint256);
function updateScore(address user) external; // Called after loan events
```

---

## ⚡ LiquidationEngine.sol (Gradual Liquidation)

### The Problem with Traditional DeFi Liquidation

```
Traditional (Aave/Compound):
┌───────────────────────────────────────────────┐
│ Health Factor drops below 1.0                  │
│           ↓                                    │
│ MEV bot liquidates 100% instantly              │
│           ↓                                    │
│ User loses 10%+ penalty                        │
│           ↓                                    │
│ Position gone in seconds 😢                    │
└───────────────────────────────────────────────┘
```

### NexusLend's Gradual Liquidation

```
NexusLend AI:
┌───────────────────────────────────────────────┐
│ Health Factor drops below 1.0                  │
│           ↓                                    │
│ Alert sent to user                             │
│           ↓                                    │
│ 1-hour grace period starts ⏰                  │
│           ↓                                    │
│ User can self-rescue (add collateral/repay)   │
│           ↓                                    │
│ If not rescued: Only 25% liquidated            │
│           ↓                                    │
│ Another grace period before next 25%           │
│           ↓                                    │
│ Lower penalty (5% vs 10%)                      │
└───────────────────────────────────────────────┘
```

**Key Parameters:**
```solidity
uint256 public gracePeriod = 1 hours;        // Time to self-rescue
uint256 public liquidationPortion = 25;       // % per liquidation
uint256 public liquidationPenalty = 5;        // % penalty (vs 10% on Aave)
```

**Functions:**
```solidity
function isLiquidatable(address user) public view returns (bool);
function startLiquidation(address user) external;
function executeLiquidation(address user, address asset) external;
function selfRescue(address user) external; // User adds collateral
```

---

## 🛡️ InsurancePool.sol (Protection)

**Purpose:** Optional insurance against liquidation losses

**How It Works:**
```
┌─────────────────────────────────────────────────────────────┐
│                    INSURANCE FLOW                            │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User opts in        ──────────────► Pays 0.5% premium   │
│                                                              │
│  2. User gets liquidated ─────────────► Insurance triggers  │
│                                                              │
│  3. Insurance pays      ──────────────► Up to 50% of loss   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

**Coverage Tiers:**
| Tier | Premium | Coverage |
|------|---------|----------|
| Basic | 0.5% | 25% of loss |
| Standard | 1.0% | 50% of loss |
| Premium | 2.0% | 80% of loss |

---

## 🤖 AI Backend Services

### Complete AI Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NexusLend AI Stack                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    FRONTEND (React + Vite)                   │   │
│  │  • Dashboard with AI insights                                │   │
│  │  • Credit score display                                      │   │
│  │  • Health factor visualization                               │   │
│  │  • Alert notifications                                       │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                  AI BACKEND (Node.js + Python)               │   │
│  │  • Credit Score API                                          │   │
│  │  • Liquidation Predictor                                     │   │
│  │  • Alert Service                                             │   │
│  │  • Auto-Manager Bot                                          │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │               SMART CONTRACTS (Solidity + Foundry)           │   │
│  │  • NexusPool.sol (Main lending pool)                         │   │
│  │  • NToken.sol (Interest-bearing tokens)                      │   │
│  │  • InterestRateModel.sol (Dynamic rates)                     │   │
│  │  • LiquidationEngine.sol (Gradual liquidation)               │   │
│  │  • PriceOracle.sol (Chainlink feeds)                         │   │
│  │  • CreditScorer.sol (On-chain reputation)                    │   │
│  │  • InsurancePool.sol (Protection)                            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    BLOCKCHAIN (Sepolia → Mainnet)            │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Backend Service 1: Credit Score API

**Endpoint:** `POST /api/credit-score/:address`

**Response:**
```json
{
  "address": "0x123...abc",
  "score": 78,
  "breakdown": {
    "walletAge": 18,
    "transactionHistory": 12,
    "loanRepayment": 25,
    "assetDiversity": 8,
    "defiActivity": 10,
    "socialVerification": 5
  },
  "collateralFactor": 110,
  "tier": "trusted"
}
```

### Backend Service 2: Liquidation Predictor

**ML Model Input:**
```json
{
  "healthFactor": 1.2,
  "collateralVolatility": 0.15,
  "borrowAmount": 50000,
  "marketTrend": "bearish"
}
```

**Output:**
```json
{
  "liquidationProbability": 0.35,
  "estimatedTimeToLiquidation": "4 hours",
  "recommendation": "Add $5,000 collateral or repay $10,000"
}
```

### Backend Service 3: Auto-Manager Bot

**When Enabled:**
```
Health Factor < 1.3:
  └─ Option 1: Auto-add collateral from reserve
  └─ Option 2: Auto-repay partial loan
  └─ Option 3: Auto-swap to less volatile asset
```

---

## 📁 Complete Folder Structure

```
nexuslend/
├── contracts/                    # Solidity smart contracts
│   ├── src/
│   │   ├── core/
│   │   │   ├── NexusPool.sol        ✅ Deployed
│   │   │   ├── NToken.sol           ✅ Deployed
│   │   │   └── InterestRateModel.sol ✅ Deployed
│   │   ├── liquidation/
│   │   │   └── LiquidationEngine.sol # Gradual liquidation
│   │   ├── oracle/
│   │   │   └── PriceOracle.sol      ✅ Deployed
│   │   ├── credit/
│   │   │   └── CreditScorer.sol     # AI credit scoring
│   │   └── insurance/
│   │       └── InsurancePool.sol    # Liquidation insurance
│   ├── test/
│   └── foundry.toml
│
├── backend/                      # AI & API services
│   ├── src/
│   │   ├── credit-score/        # Credit score calculation
│   │   ├── predictor/           # Liquidation ML model
│   │   ├── alerts/              # Alert service
│   │   └── auto-manager/        # Position auto-management
│   └── package.json
│
├── frontend/                     # React frontend
│   ├── src/
│   │   ├── App.jsx              ✅ Complete
│   │   ├── components/          ✅ Complete
│   │   └── lib/contracts.js     ✅ Complete
│   └── package.json
│
└── docs/
    ├── NEXUSLEND_COMPLETE_DOCUMENTATION.md
    └── PROJECT_STATUS.md
```

---

## 🎓 Summary

NexusLend AI is a **next-generation DeFi lending protocol** that protects users from liquidation:

### Core Features (Implemented)
1. **Smart Contracts** - Solidity contracts handling all lending logic
2. **Dynamic Rates** - Interest rates adjust based on utilization
3. **Collateralization** - Users must maintain healthy positions
4. **Price Oracles** - Real-time asset pricing
5. **Receipt Tokens** - nTokens prove deposits
6. **React Frontend** - Modern UI reading all data from chain

### AI Innovations (Planned)
7. **Credit Score System** - Lower collateral for trusted users
8. **Gradual Liquidation** - 25% at a time with grace period
9. **Insurance Pool** - Protection against liquidation losses
10. **Liquidation Predictor** - AI warns before liquidation
11. **Auto-Manager Bot** - Automatic position protection

### What Makes NexusLend Different

```
Traditional DeFi:     "Pay 150% collateral or get liquidated instantly"
NexusLend AI:         "Build trust → Lower collateral → Get warned → Get protected"
```

---

_Built with ❤️ for the future of DeFi_

