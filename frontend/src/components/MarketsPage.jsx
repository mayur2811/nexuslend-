import { motion } from 'framer-motion'
import { TrendingUp, TrendingDown, Activity, BarChart3, Coins, DollarSign, BadgeDollarSign } from 'lucide-react'
import { useAccount, useReadContract } from 'wagmi'
import { formatUnits } from 'viem'
import { CONTRACTS, TOKENS, NEXUS_POOL_ABI, PRICE_ORACLE_ABI, INTEREST_RATE_MODEL_ABI } from '../lib/contracts'

// Token icons
const TokenIconComponent = ({ symbol }) => {
  switch(symbol) {
    case 'mWETH': return <Coins size={20} />
    case 'mUSDC': return <DollarSign size={20} />
    case 'mDAI': return <BadgeDollarSign size={20} />
    default: return <Coins size={20} />
  }
}

// Reserve factor for supply rate calculation (10% = 0.1e27)
const RESERVE_FACTOR = BigInt('100000000000000000000000000')

export default function MarketsPage() {
  const { address } = useAccount()
  
  // Read prices from oracle
  const { data: wethPrice } = useReadContract({
    address: CONTRACTS.PriceOracle,
    abi: PRICE_ORACLE_ABI,
    functionName: 'getPrice',
    args: [TOKENS.mWETH.address],
  })

  const { data: usdcPrice } = useReadContract({
    address: CONTRACTS.PriceOracle,
    abi: PRICE_ORACLE_ABI,
    functionName: 'getPrice',
    args: [TOKENS.mUSDC.address],
  })

  const { data: daiPrice } = useReadContract({
    address: CONTRACTS.PriceOracle,
    abi: PRICE_ORACLE_ABI,
    functionName: 'getPrice',
    args: [TOKENS.mDAI.address],
  })

  // Read total liquidity for each token
  const { data: wethLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mWETH.address],
  })

  const { data: usdcLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mUSDC.address],
  })

  const { data: daiLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mDAI.address],
  })

  // Read user positions to get borrowed amounts
  const { data: wethPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mWETH.address],
    enabled: !!address,
  })
  
  const { data: usdcPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mUSDC.address],
    enabled: !!address,
  })
  
  const { data: daiPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mDAI.address],
    enabled: !!address,
  })

  // Read totalBorrows for each token
  const { data: wethTotalBorrows } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalBorrows',
    args: [TOKENS.mWETH.address],
  })

  const { data: usdcTotalBorrows } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalBorrows',
    args: [TOKENS.mUSDC.address],
  })

  const { data: daiTotalBorrows } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalBorrows',
    args: [TOKENS.mDAI.address],
  })

  // Read borrow rates from InterestRateModel
  const { data: wethBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [wethTotalBorrows || 0n, wethLiquidity || 0n],
    enabled: wethTotalBorrows !== undefined && wethLiquidity !== undefined,
  })

  const { data: usdcBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [usdcTotalBorrows || 0n, usdcLiquidity || 0n],
    enabled: usdcTotalBorrows !== undefined && usdcLiquidity !== undefined,
  })

  const { data: daiBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [daiTotalBorrows || 0n, daiLiquidity || 0n],
    enabled: daiTotalBorrows !== undefined && daiLiquidity !== undefined,
  })

  // Read supply rates from InterestRateModel
  const { data: wethSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [wethTotalBorrows || 0n, wethLiquidity || 0n, RESERVE_FACTOR],
    enabled: wethTotalBorrows !== undefined && wethLiquidity !== undefined,
  })

  const { data: usdcSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [usdcTotalBorrows || 0n, usdcLiquidity || 0n, RESERVE_FACTOR],
    enabled: usdcTotalBorrows !== undefined && usdcLiquidity !== undefined,
  })

  const { data: daiSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [daiTotalBorrows || 0n, daiLiquidity || 0n, RESERVE_FACTOR],
    enabled: daiTotalBorrows !== undefined && daiLiquidity !== undefined,
  })

  // Convert prices from oracle (18 decimals - see MockPriceOracle.sol)
  const PRICES = {
    mWETH: wethPrice ? Number(wethPrice) / 1e18 : 3000,
    mUSDC: usdcPrice ? Number(usdcPrice) / 1e18 : 1,
    mDAI: daiPrice ? Number(daiPrice) / 1e18 : 1,
  }

  // Convert interest rates from RAY (1e27) to percentage
  const rayToPercent = (rate) => rate ? (Number(rate) / 1e27) * 100 : 0
  
  const APY_RATES = {
    mWETH: { 
      supply: rayToPercent(wethSupplyRate) || 2.1, 
      borrow: rayToPercent(wethBorrowRate) || 3.8 
    },
    mUSDC: { 
      supply: rayToPercent(usdcSupplyRate) || 4.5, 
      borrow: rayToPercent(usdcBorrowRate) || 6.2 
    },
    mDAI: { 
      supply: rayToPercent(daiSupplyRate) || 3.8, 
      borrow: rayToPercent(daiBorrowRate) || 5.5 
    },
  }
  
  // Calculate market data
  const getMarketData = (liquidity, position, decimals, price, symbol) => {
    const totalSupplyRaw = liquidity || 0n
    const totalSupplyUSD = Number(formatUnits(totalSupplyRaw, decimals)) * price
    
    const borrowedRaw = position?.[1] || 0n
    const borrowedUSD = Number(formatUnits(borrowedRaw, decimals)) * price
    
    const utilization = totalSupplyUSD > 0 ? (borrowedUSD / totalSupplyUSD) * 100 : 0
    
    return {
      symbol,
      totalSupplyUSD,
      borrowedUSD,
      utilization: Math.min(Math.round(utilization), 100),
      price,
    }
  }
  
  const wethData = getMarketData(wethLiquidity, wethPosition, 18, PRICES.mWETH, 'mWETH')
  const usdcData = getMarketData(usdcLiquidity, usdcPosition, 6, PRICES.mUSDC, 'mUSDC')
  const daiData = getMarketData(daiLiquidity, daiPosition, 18, PRICES.mDAI, 'mDAI')
  
  const totalSupply = wethData.totalSupplyUSD + usdcData.totalSupplyUSD + daiData.totalSupplyUSD
  const totalBorrow = wethData.borrowedUSD + usdcData.borrowedUSD + daiData.borrowedUSD
  const avgUtilization = totalSupply > 0 ? (totalBorrow / totalSupply) * 100 : 0
  
  const formatUSD = (value) => {
    if (value >= 1000000) return `$${(value / 1000000).toFixed(2)}M`
    if (value >= 1000) return `$${(value / 1000).toFixed(1)}K`
    return `$${value.toFixed(2)}`
  }
  
  const formatPrice = (price) => {
    if (price >= 1000) return `$${price.toLocaleString()}`
    return `$${price.toFixed(2)}`
  }
  
  const marketData = [
    {
      symbol: 'mWETH',
      name: 'Mock Wrapped ETH',
      price: formatPrice(PRICES.mWETH),
      totalSupply: formatUSD(wethData.totalSupplyUSD),
      totalBorrow: formatUSD(wethData.borrowedUSD),
      utilization: wethData.utilization,
      ...APY_RATES.mWETH
    },
    {
      symbol: 'mUSDC',
      name: 'Mock USD Coin',
      price: formatPrice(PRICES.mUSDC),
      totalSupply: formatUSD(usdcData.totalSupplyUSD),
      totalBorrow: formatUSD(usdcData.borrowedUSD),
      utilization: usdcData.utilization,
      ...APY_RATES.mUSDC
    },
    {
      symbol: 'mDAI',
      name: 'Mock DAI',
      price: formatPrice(PRICES.mDAI),
      totalSupply: formatUSD(daiData.totalSupplyUSD),
      totalBorrow: formatUSD(daiData.borrowedUSD),
      utilization: daiData.utilization,
      ...APY_RATES.mDAI
    },
  ]

  console.log('Markets data:', { PRICES, totalSupply, totalBorrow, wethData, usdcData, daiData })

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4 }}
    >
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">Markets</h1>
        <p className="page-subtitle">Explore all available lending markets</p>
      </div>

      {/* Market Stats */}
      <div className="stats-row">
        <div className="market-stat">
          <div className="market-stat-icon"><Activity size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Total Value Locked</span>
            <span className="market-stat-value">{formatUSD(totalSupply)}</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><TrendingUp size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Total Supply</span>
            <span className="market-stat-value">{formatUSD(totalSupply)}</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><TrendingDown size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Total Borrow</span>
            <span className="market-stat-value">{formatUSD(totalBorrow)}</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><BarChart3 size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Avg Utilization</span>
            <span className="market-stat-value">{avgUtilization.toFixed(0)}%</span>
          </div>
        </div>
      </div>

      {/* Markets Table */}
      <motion.div 
        className="card"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <div className="card-header">
          <h2 className="card-title">All Markets</h2>
        </div>
        <div className="card-body">
          <table className="asset-table">
            <thead>
              <tr>
                <th>Asset</th>
                <th>Price</th>
                <th>Total Supply</th>
                <th>Total Borrow</th>
                <th>Utilization</th>
                <th>Supply APY</th>
                <th>Borrow APY</th>
              </tr>
            </thead>
            <tbody>
              {marketData.map((market) => (
                <tr key={market.symbol}>
                  <td>
                    <div className="asset-cell">
                      <div className={`asset-icon ${market.symbol === 'mWETH' ? 'eth' : market.symbol === 'mUSDC' ? 'usdc' : 'dai'}`}>
                        <TokenIconComponent symbol={market.symbol} />
                      </div>
                      <div>
                        <div className="asset-name">{market.name}</div>
                        <div className="asset-symbol">{market.symbol}</div>
                      </div>
                    </div>
                  </td>
                  <td>{market.price}</td>
                  <td>{market.totalSupply}</td>
                  <td>{market.totalBorrow}</td>
                  <td>
                    <div className="utilization-bar">
                      <div 
                        className="utilization-fill" 
                        style={{ width: `${Math.min(market.utilization, 100)}%` }}
                      ></div>
                      <span className="utilization-text">{market.utilization}%</span>
                    </div>
                  </td>
                  <td><span className="apy-positive">{Number(market.supply).toFixed(2)}%</span></td>
                  <td><span className="apy-negative">{Number(market.borrow).toFixed(2)}%</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </motion.div>
    </motion.div>
  )
}
