# NexusLend AI 🏦

> **The First AI-Powered DeFi Lending Protocol That Protects Users From Liquidation**

![Solidity](https://img.shields.io/badge/Solidity-0.8.20-blue)
![React](https://img.shields.io/badge/React-18-61dafb)
![Vite](https://img.shields.io/badge/Vite-7-646cff)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 🌟 What Makes NexusLend Different?

| Feature             | Aave/Compound | NexusLend AI                 |
| ------------------- | ------------- | ---------------------------- |
| Collateral Required | 150%+ always  | 80-150% based on trust score |
| Liquidation Warning | None          | AI predicts & alerts         |
| Auto-Protection     | None          | AI auto-manages position     |
| Liquidation Style   | Instant 100%  | Gradual with grace period    |

---

## 🚀 Live Demo

**Frontend:** [Coming Soon - Deploy to Vercel]

**Contracts:** Deployed on Sepolia Testnet

---

## 📸 Screenshots

### Dashboard

- Net Worth, Total Supplied, Total Borrowed
- Health Factor visualization
- Assets table with Supply/Borrow/Withdraw/Repay actions

### Markets

- Total Value Locked (TVL)
- Supply/Borrow APY rates
- Utilization visualization

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         NexusLend AI Stack                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    FRONTEND (React + Vite)                   │   │
│  │  • Dashboard with real-time data                             │   │
│  │  • Supply/Borrow/Withdraw/Repay                              │   │
│  │  • Health factor monitoring                                  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │               SMART CONTRACTS (Solidity + Foundry)           │   │
│  │  • NexusPool.sol (Main lending pool)                         │   │
│  │  • NToken.sol (Interest-bearing tokens)                      │   │
│  │  • InterestRateModel.sol (Dynamic rates)                     │   │
│  │  • PriceOracle.sol (Price feeds)                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    BLOCKCHAIN (Sepolia Testnet)              │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

| Layer           | Technology               |
| --------------- | ------------------------ |
| Blockchain      | Ethereum Sepolia Testnet |
| Smart Contracts | Solidity 0.8.20, Foundry |
| Frontend        | React 18, Vite 7         |
| Web3            | wagmi, viem              |
| Wallet          | RainbowKit               |
| Styling         | Vanilla CSS              |

---

## 📦 Installation

### Prerequisites

- Node.js 18+
- Foundry (for contracts)

### Frontend

```bash
cd frontend
npm install
npm run dev
```

### Contracts

```bash
cd contracts
forge install
forge build
forge test
```

---

## 🔑 Contract Addresses (Sepolia)

| Contract          | Address                                      |
| ----------------- | -------------------------------------------- |
| NexusPool         | `0x087bd3cef36b00d2db4cd381fc76adee4a1b2357` |
| PriceOracle       | `0xa6d224d5744d9bae8c5a71020a5ba82a29b215e4` |
| InterestRateModel | `0xe19e505290e1c4b35a2057798363b0ab8fe70224` |
| mWETH             | `0x27d5315e5f6febe82ee7a4a6fa00e11095c5a70f` |
| mUSDC             | `0x5f2821f166947717187759e205144def4442814a` |
| mDAI              | `0x297c736918352f0f46225ec98cb4a4b0c0a5e16e` |

---

## ✨ Features

### Core (Implemented)

- ✅ **Supply Assets** - Deposit tokens to earn interest
- ✅ **Borrow Assets** - Borrow against collateral
- ✅ **Withdraw** - Withdraw supplied tokens
- ✅ **Repay** - Repay borrowed tokens
- ✅ **Dynamic APY** - Rates adjust based on utilization
- ✅ **Health Factor** - Position health monitoring
- ✅ **Receipt Tokens** - nTokens for deposits

### AI Features (Planned)

- 🔮 **AI Credit Score** - Lower collateral for trusted users
- 🔮 **Gradual Liquidation** - 25% at a time with grace period
- 🔮 **Insurance Pool** - Protection against liquidation
- 🔮 **Liquidation Predictor** - AI warns before liquidation
- 🔮 **Auto-Manager Bot** - Automatic position protection

---

## 📐 Key Formulas

### Health Factor

```
Health Factor = (Collateral Value × LTV) / Borrowed Value
```

### Interest Rate (Two-Slope Model)

```
If Utilization < 80%:
  Rate = Base + (Utilization / 80%) × Slope1

If Utilization >= 80%:
  Rate = Base + Slope1 + ((Utilization - 80%) / 20%) × Slope2
```

---

## 📁 Project Structure

```
nexuslend/
├── contracts/                    # Smart Contracts
│   ├── src/core/
│   │   ├── NexusPool.sol        # Main lending pool
│   │   ├── InterestRateModel.sol # Dynamic rates
│   │   ├── MockPriceOracle.sol  # Price feeds
│   │   └── NToken.sol           # Receipt tokens
│   └── test/
│
├── frontend/                     # React Frontend
│   ├── src/
│   │   ├── App.jsx              # Main app
│   │   ├── components/          # UI components
│   │   └── lib/contracts.js     # Contract config
│   └── package.json
│
├── NEXUSLEND_COMPLETE_DOCUMENTATION.md
├── PROJECT_STATUS.md
└── README.md
```

---

## 📄 Documentation

See [NEXUSLEND_COMPLETE_DOCUMENTATION.md](./NEXUSLEND_COMPLETE_DOCUMENTATION.md) for:

- Complete architecture
- Smart contract deep dive
- Frontend architecture
- AI features (planned)
- All formulas explained

---

## 🤝 Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## 📜 License

MIT License - feel free to use for your own projects!

---

## 👤 Author

**Your Name**

- Portfolio: [your-portfolio.com]
- Twitter: [@yourhandle]
- LinkedIn: [your-linkedin]

---

_Built with ❤️ for the future of DeFi_
