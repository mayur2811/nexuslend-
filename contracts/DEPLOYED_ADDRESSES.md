# NexusLend Deployed Contracts (Sepolia Testnet)

**Network:** Sepolia (Chain ID: 11155111)
**Deployed:** February 5, 2026

## Core Contracts

| Contract | Address | Etherscan |
|----------|---------|-----------|
| **InterestRateModel** | `0xc4d0cc1e0e527e23395dfa1d82b27b4f314c2b03` | [View](https://sepolia.etherscan.io/address/0xc4d0cc1e0e527e23395dfa1d82b27b4f314c2b03) |
| **MockPriceOracle** | `0x0e6bb20362f5f382534528a02aa9ce9b69c4ff86` | [View](https://sepolia.etherscan.io/address/0x0e6bb20362f5f382534528a02aa9ce9b69c4ff86) |
| **NexusAccessControl** | `0x30592b2e6a0fa55ec2d866d07d0381e5e9851759` | [View](https://sepolia.etherscan.io/address/0x30592b2e6a0fa55ec2d866d07d0381e5e9851759) |
| **NexusPool** | `0x108d8f153fcd367293ea61dbdc8eb2fa204f2276` | [View](https://sepolia.etherscan.io/address/0x108d8f153fcd367293ea61dbdc8eb2fa204f2276) |
| **LiquidationEngine** | `0x3749873054360bc3ab55a599bbbf9da5df368226` | [View](https://sepolia.etherscan.io/address/0x3749873054360bc3ab55a599bbbf9da5df368226) |
| **FlashLoan** | `0x0b773942de613442bbc68f53345d37921faeb76c` | [View](https://sepolia.etherscan.io/address/0x0b773942de613442bbc68f53345d37921faeb76c) |
| **PoolDataProvider** | `0x1612583a085589939529f96d1d5ea88b01033bcf` | [View](https://sepolia.etherscan.io/address/0x1612583a085589939529f96d1d5ea88b01033bcf) |

## Test Tokens (For Testing)

| Token | Symbol | Decimals | Address | Your Balance |
|-------|--------|----------|---------|--------------|
| **Mock WETH** | mWETH | 18 | `0xb45c96f0dd1eb039d01cc526fbde62f836d8e8ba` | 100 ($300,000) |
| **Mock USDC** | mUSDC | 6 | `0xcf5caa95b2f013e8347fe8fa703f51aca6f47682` | 100,000 |
| **Mock DAI** | mDAI | 18 | `0xc06dac5ec0c88cd3a74f896a8cea13bc4221806d` | 100,000 |

## Prices Set in Oracle

| Token | Price |
|-------|-------|
| WETH | $3,000 |
| USDC | $1 |
| DAI | $1 |

## How to Add Tokens to MetaMask

1. Open MetaMask → Add Token → Custom Token
2. Paste token address from above
3. Symbol and decimals will auto-fill
4. Click "Add Token"

## Total Deployment Cost

- **Core Contracts**: 0.00567 ETH
- **Test Tokens**: 0.00215 ETH
- **Total**: ~0.00782 ETH (~$23)
