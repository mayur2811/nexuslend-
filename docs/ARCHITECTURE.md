# NexusLend AI - Architecture

> **The First AI-Powered DeFi Lending Protocol That Protects Users From Liquidation**

## What Makes NexusLend Different?

| Feature             | Aave/Compound | NexusLend AI                 |
| ------------------- | ------------- | ---------------------------- |
| Collateral Required | 150%+ always  | 80-150% based on trust score |
| Liquidation Warning | None          | AI predicts & alerts         |
| Auto-Protection     | None          | AI auto-manages position     |
| Liquidation Style   | Instant 100%  | Gradual with grace period    |

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NexusLend AI Stack                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    FRONTEND (React + Vite)                   │   │
│  │  • Dashboard with AI insights                                │   │
│  │  • Supply/Borrow interface                                   │   │
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

---

## Smart Contracts

### 1. NexusPool.sol (Core Lending Pool)

Main contract users interact with:

- `supply(asset, amount)` - Deposit assets to earn interest
- `withdraw(asset, amount)` - Withdraw supplied assets
- `borrow(asset, amount)` - Borrow against collateral
- `repay(asset, amount)` - Repay borrowed amount
- `getHealthFactor(user)` - Check position health

### 2. NToken.sol (Interest-Bearing Tokens)

Receipt tokens for suppliers (like Aave's aTokens):

- Deposit 100 DAI → Get 100 nDAI
- nDAI balance grows as you earn interest
- Redeem nDAI for DAI + interest

### 3. InterestRateModel.sol (Dynamic Rates)

```
Utilization = Total Borrowed / Total Supplied

If Utilization < 80%:
  Borrow Rate = Base Rate + (Utilization × Slope1)

If Utilization >= 80%:
  Borrow Rate = Base Rate + 80% × Slope1 + (Utilization - 80%) × Slope2
```

### 4. LiquidationEngine.sol ⭐ (Our Innovation!)

**Gradual liquidation with grace period:**

- Only 25% liquidated at a time (not 100%)
- 1-hour grace period to self-rescue
- MEV-protected auctions
- Lower penalty (5% vs 10% on Aave)

### 5. PriceOracle.sol (Chainlink Integration)

- Wraps Chainlink price feeds
- Fallback for stale data
- Price smoothing

### 6. CreditScorer.sol ⭐ (AI Integration Point)

On-chain credit scoring:

- Score 90+ → Need only 80% collateral
- Score 50-89 → Need 120% collateral
- Score <50 → Need 150% collateral

### 7. InsurancePool.sol (Protection)

- Users pay small premium
- If liquidated, get compensated

---

## AI Backend Components

### 1. Credit Score API

Analyzes wallet to compute trust score (0-100):

- Wallet age (0-20 pts)
- Transaction history (0-15 pts)
- Loan repayment history (0-30 pts)
- Asset diversity (0-10 pts)
- DeFi activity (0-15 pts)
- Social verification (0-10 pts)

### 2. Liquidation Predictor

ML model that predicts:

- Probability of liquidation in next N hours
- Estimated time until liquidation
- Sends alerts when risk is high

### 3. Alert Service

- Real-time position monitoring
- Notifications via webhook/email
- In-app alerts

### 4. Auto-Manager Bot

When enabled:

- Auto-adds collateral when health drops
- Auto-repays partial loans
- Auto-swaps to less volatile assets

---

## Folder Structure

```
nexuslend/
├── contracts/                    # Solidity smart contracts
│   ├── src/
│   │   ├── core/
│   │   │   ├── NexusPool.sol
│   │   │   ├── NToken.sol
│   │   │   └── InterestRateModel.sol
│   │   ├── liquidation/
│   │   │   └── LiquidationEngine.sol
│   │   ├── oracle/
│   │   │   └── PriceOracle.sol
│   │   ├── credit/
│   │   │   └── CreditScorer.sol
│   │   └── insurance/
│   │       └── InsurancePool.sol
│   ├── test/
│   └── foundry.toml
│
├── backend/                      # AI & API services
│   ├── src/
│   │   ├── credit-score/
│   │   ├── predictor/
│   │   ├── alerts/
│   │   └── auto-manager/
│   └── package.json
│
├── frontend/                     # React frontend
│   ├── src/
│   └── package.json
│
└── docs/
    ├── ARCHITECTURE.md           # This file
    └── IMPLEMENTATION_PLAN.md
```
