# NexusLend Deployment Guide

## Prerequisites

1. **Get Sepolia ETH** (for gas fees):
   - Go to https://www.alchemy.com/faucets/ethereum-sepolia
   - Or https://sepoliafaucet.com/
   - Paste your wallet address
   - Get ~0.1 ETH

2. **Get Sepolia RPC URL**:
   - Sign up at https://www.alchemy.com/
   - Create a new app (select Sepolia network)
   - Copy the API key

## Setup

### 1. Create `.env` file

Create a `.env` file in the `contracts` folder:

```env
# Your wallet private key (NEVER share this!)
PRIVATE_KEY=your_private_key_here

# Alchemy or Infura RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Etherscan API Key (for verification)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

### 2. Export Private Key

**MetaMask:**

1. Open MetaMask
2. Click three dots → Account details
3. Click "Show private key"
4. Enter password
5. Copy the key

⚠️ **NEVER share your private key!**

## Deploy Commands

### Deploy to Sepolia

```bash
# Navigate to contracts folder
cd contracts

# Load environment variables
source .env

# Deploy (dry run first)
forge script script/DeployNexusLend.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast --verify -vvvv
```

### Verify on Etherscan

```bash
forge verify-contract <CONTRACT_ADDRESS> src/core/NexusPool.sol:NexusPool --chain sepolia --etherscan-api-key $ETHERSCAN_API_KEY
```

## Expected Output

```
Deploying NexusLend Contracts...
Deployer: 0x...

1. Deploying InterestRateModel...
   InterestRateModel: 0x...
2. Deploying MockPriceOracle...
   MockPriceOracle: 0x...
3. Deploying NexusAccessControl...
   NexusAccessControl: 0x...
4. Deploying NexusPool...
   NexusPool: 0x...
5. Deploying LiquidationEngine...
   LiquidationEngine: 0x...
6. Deploying FlashLoan...
   FlashLoan: 0x...
7. Deploying PoolDataProvider...
   PoolDataProvider: 0x...

========================================
NexusLend Deployment Complete!
========================================
```

## After Deployment

1. **Save the contract addresses** - You'll need them for frontend
2. **Verify all contracts on Etherscan**
3. **Set up test assets** in MockPriceOracle

## Troubleshooting

| Error                 | Solution                         |
| --------------------- | -------------------------------- |
| "Insufficient funds"  | Get more Sepolia ETH from faucet |
| "Invalid private key" | Check .env file format           |
| "RPC error"           | Check your Alchemy API key       |
