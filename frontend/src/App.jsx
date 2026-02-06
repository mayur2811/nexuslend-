import { useState, useEffect } from 'react'
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi'
import { motion, AnimatePresence } from 'framer-motion'
import { formatUnits, parseUnits } from 'viem'
import { Infinity } from 'lucide-react'

// Components
import { Header, Footer, StatsCard, AssetRow, TransactionModal, EmptyState, MarketsPage, StakePage } from './components'

// Config
import { CONTRACTS, TOKENS, ERC20_ABI, NEXUS_POOL_ABI, PRICE_ORACLE_ABI, INTEREST_RATE_MODEL_ABI } from './lib/contracts'

const tokenList = Object.values(TOKENS)

// Reserve factor for supply rate calculation (10% = 0.1e27)
const RESERVE_FACTOR = BigInt('100000000000000000000000000') // 10% in RAY

function App() {
  const { address, isConnected } = useAccount()
  const [activeTab, setActiveTab] = useState('dashboard')
  const [selectedToken, setSelectedToken] = useState(null)
  const [modalType, setModalType] = useState(null)
  const [amount, setAmount] = useState('')
  const [txStatus, setTxStatus] = useState(null)

  // Contract writes - with error tracking
  const { 
    writeContract: approve, 
    data: approveHash, 
    isPending: isApproving,
    error: approveError,
    reset: resetApprove
  } = useWriteContract()
  
  const { 
    writeContract: supply, 
    data: supplyHash, 
    isPending: isSupplying,
    error: supplyError,
    reset: resetSupply
  } = useWriteContract()
  
  const { 
    writeContract: borrow, 
    data: borrowHash, 
    isPending: isBorrowing,
    error: borrowError,
    reset: resetBorrow
  } = useWriteContract()

  const { 
    writeContract: withdraw, 
    data: withdrawHash, 
    isPending: isWithdrawing,
    error: withdrawError,
    reset: resetWithdraw
  } = useWriteContract()

  const { 
    writeContract: repay, 
    data: repayHash, 
    isPending: isRepaying,
    error: repayError,
    reset: resetRepay
  } = useWriteContract()

  // Wait for txs - with error tracking
  const { 
    isLoading: isApproveLoading, 
    isSuccess: isApproveSuccess,
    isError: isApproveError 
  } = useWaitForTransactionReceipt({ hash: approveHash })
  
  const { 
    isLoading: isSupplyLoading, 
    isSuccess: isSupplySuccess,
    isError: isSupplyError 
  } = useWaitForTransactionReceipt({ hash: supplyHash })
  
  const { 
    isLoading: isBorrowLoading, 
    isSuccess: isBorrowSuccess,
    isError: isBorrowError 
  } = useWaitForTransactionReceipt({ hash: borrowHash })

  const { 
    isLoading: isWithdrawLoading, 
    isSuccess: isWithdrawSuccess,
    isError: isWithdrawError 
  } = useWaitForTransactionReceipt({ hash: withdrawHash })

  const { 
    isLoading: isRepayLoading, 
    isSuccess: isRepaySuccess,
    isError: isRepayError 
  } = useWaitForTransactionReceipt({ hash: repayHash })

  // Read balances
  const { data: wethBalance, refetch: refetchWeth } = useReadContract({
    address: TOKENS.mWETH.address,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    enabled: !!address,
  })

  const { data: usdcBalance, refetch: refetchUsdc } = useReadContract({
    address: TOKENS.mUSDC.address,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    enabled: !!address,
  })

  const { data: daiBalance, refetch: refetchDai } = useReadContract({
    address: TOKENS.mDAI.address,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    enabled: !!address,
  })

  // Allowance
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: selectedToken?.address,
    abi: ERC20_ABI,
    functionName: 'allowance',
    args: [address, CONTRACTS.NexusPool],
    enabled: !!address && !!selectedToken,
  })

  // Read user positions from NexusPool
  const { data: wethPosition, refetch: refetchWethPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mWETH.address],
    enabled: !!address,
  })

  const { data: usdcPosition, refetch: refetchUsdcPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mUSDC.address],
    enabled: !!address,
  })

  const { data: daiPosition, refetch: refetchDaiPosition } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'userPositions',
    args: [address, TOKENS.mDAI.address],
    enabled: !!address,
  })

  // Read health factor from contract
  const { data: contractHealthFactor, refetch: refetchHealthFactor } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'getHealthFactor',
    args: [address],
    enabled: !!address,
  })

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

  // Read totalBorrows for each token (for interest rate calculation)
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

  // Read totalLiquidity for each token
  const { data: wethTotalLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mWETH.address],
  })

  const { data: usdcTotalLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mUSDC.address],
  })

  const { data: daiTotalLiquidity } = useReadContract({
    address: CONTRACTS.NexusPool,
    abi: NEXUS_POOL_ABI,
    functionName: 'totalLiquidity',
    args: [TOKENS.mDAI.address],
  })

  // Read borrow rates from InterestRateModel
  const { data: wethBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [wethTotalBorrows || 0n, wethTotalLiquidity || 0n],
    enabled: wethTotalBorrows !== undefined && wethTotalLiquidity !== undefined,
  })

  const { data: usdcBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [usdcTotalBorrows || 0n, usdcTotalLiquidity || 0n],
    enabled: usdcTotalBorrows !== undefined && usdcTotalLiquidity !== undefined,
  })

  const { data: daiBorrowRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getBorrowRate',
    args: [daiTotalBorrows || 0n, daiTotalLiquidity || 0n],
    enabled: daiTotalBorrows !== undefined && daiTotalLiquidity !== undefined,
  })

  // Read supply rates from InterestRateModel
  const { data: wethSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [wethTotalBorrows || 0n, wethTotalLiquidity || 0n, RESERVE_FACTOR],
    enabled: wethTotalBorrows !== undefined && wethTotalLiquidity !== undefined,
  })

  const { data: usdcSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [usdcTotalBorrows || 0n, usdcTotalLiquidity || 0n, RESERVE_FACTOR],
    enabled: usdcTotalBorrows !== undefined && usdcTotalLiquidity !== undefined,
  })

  const { data: daiSupplyRate } = useReadContract({
    address: CONTRACTS.InterestRateModel,
    abi: INTEREST_RATE_MODEL_ABI,
    functionName: 'getSupplyRate',
    args: [daiTotalBorrows || 0n, daiTotalLiquidity || 0n, RESERVE_FACTOR],
    enabled: daiTotalBorrows !== undefined && daiTotalLiquidity !== undefined,
  })

  // Convert oracle prices (they're in 18 decimals - see MockPriceOracle.sol)
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
  
  console.log('Prices from oracle:', PRICES)
  console.log('APY rates from contract:', APY_RATES)

  // ============================================
  // ERROR HANDLERS
  // ============================================
  useEffect(() => {
    if (approveError) {
      console.error('Approve error:', approveError)
      setTxStatus('error')
    }
  }, [approveError])

  useEffect(() => {
    if (supplyError) {
      console.error('Supply error:', supplyError)
      setTxStatus('error')
    }
  }, [supplyError])

  useEffect(() => {
    if (borrowError) {
      console.error('Borrow error:', borrowError)
      setTxStatus('error')
    }
  }, [borrowError])

  useEffect(() => {
    if (withdrawError) {
      console.error('Withdraw error:', withdrawError)
      setTxStatus('error')
    }
  }, [withdrawError])

  useEffect(() => {
    if (repayError) {
      console.error('Repay error:', repayError)
      setTxStatus('error')
    }
  }, [repayError])

  useEffect(() => {
    if (isApproveError || isSupplyError || isBorrowError || isWithdrawError || isRepayError) {
      console.error('Transaction reverted on-chain')
      setTxStatus('error')
    }
  }, [isApproveError, isSupplyError, isBorrowError, isWithdrawError, isRepayError])

  // ============================================
  // SUCCESS HANDLERS
  // ============================================
  useEffect(() => {
    if (isSupplySuccess || isBorrowSuccess || isWithdrawSuccess || isRepaySuccess) {
      console.log('Transaction successful!')
      setTxStatus('success')
      // Refetch all data
      refetchWeth()
      refetchUsdc()
      refetchDai()
      refetchWethPosition()
      refetchUsdcPosition()
      refetchDaiPosition()
      refetchHealthFactor()
      setTimeout(closeModal, 2000)
    }
  }, [isSupplySuccess, isBorrowSuccess, isWithdrawSuccess, isRepaySuccess])

  useEffect(() => {
    if (isApproveSuccess && selectedToken && amount) {
      console.log('Approval successful, now executing...')
      setTxStatus('pending')
      refetchAllowance()
      // Small delay to ensure allowance is updated
      setTimeout(() => {
        if (modalType === 'supply') {
          executeSupply()
        } else if (modalType === 'repay') {
          executeRepay()
        }
      }, 500)
    }
  }, [isApproveSuccess])

  // Helpers
  const getBalance = (token) => {
    if (token.symbol === 'mWETH') return wethBalance
    if (token.symbol === 'mUSDC') return usdcBalance
    if (token.symbol === 'mDAI') return daiBalance
    return 0n
  }

  const formatBalance = (balance, decimals) => {
    if (!balance) return '0.00'
    return Number(formatUnits(balance, decimals)).toLocaleString('en-US', { 
      minimumFractionDigits: 2,
      maximumFractionDigits: 4 
    })
  }

  const getUSDValue = (balance, decimals, priceUSD) => {
    if (!balance) return 0
    return Number(formatUnits(balance, decimals)) * priceUSD
  }

  const formatUSD = (value) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
    }).format(value || 0)
  }

  const totalValue = 
    getUSDValue(wethBalance, 18, PRICES.mWETH) +
    getUSDValue(usdcBalance, 6, PRICES.mUSDC) +
    getUSDValue(daiBalance, 18, PRICES.mDAI)

  // Calculate total supplied and borrowed from positions
  const totalSupplied = 
    getUSDValue(wethPosition?.[0] || 0n, 18, PRICES.mWETH) +
    getUSDValue(usdcPosition?.[0] || 0n, 6, PRICES.mUSDC) +
    getUSDValue(daiPosition?.[0] || 0n, 18, PRICES.mDAI)

  const totalBorrowed = 
    getUSDValue(wethPosition?.[1] || 0n, 18, PRICES.mWETH) +
    getUSDValue(usdcPosition?.[1] || 0n, 6, PRICES.mUSDC) +
    getUSDValue(daiPosition?.[1] || 0n, 18, PRICES.mDAI)

  // Calculate health factor on frontend
  // Formula: (Collateral Value × LTV) / Borrowed Value
  // LTV is 75% (0.75)
  const formatHealthFactor = () => {
    // If no borrows, health factor is infinite
    if (totalBorrowed === 0 || totalBorrowed < 0.01) {
      return <Infinity size={24} />
    }
    
    // Calculate on frontend: (totalSupplied * 0.75) / totalBorrowed
    const collateralValue = totalSupplied * 0.75 // 75% LTV
    const hf = collateralValue / totalBorrowed
    
    console.log('Health factor:', { totalSupplied, totalBorrowed, collateralValue, hf })
    
    if (hf > 999) return <Infinity size={24} />
    if (hf < 0.01) return '< 0.01'
    return hf.toFixed(2)
  }

  // Modal handlers
  const openModal = (token, type) => {
    setSelectedToken(token)
    setModalType(type)
    setAmount('')
    setTxStatus(null)
    resetApprove()
    resetSupply()
    resetBorrow()
  }

  const closeModal = () => {
    setSelectedToken(null)
    setModalType(null)
    setAmount('')
    setTxStatus(null)
  }

  const executeSupply = () => {
    if (!selectedToken || !amount) return
    console.log('Executing supply...', {
      pool: CONTRACTS.NexusPool,
      token: selectedToken.address,
      amount: parseUnits(amount, selectedToken.decimals).toString()
    })
    supply({
      address: CONTRACTS.NexusPool,
      abi: NEXUS_POOL_ABI,
      functionName: 'supply',
      args: [selectedToken.address, parseUnits(amount, selectedToken.decimals)],
    })
  }

  const executeRepay = () => {
    if (!selectedToken || !amount) return
    console.log('Executing repay...', {
      pool: CONTRACTS.NexusPool,
      token: selectedToken.address,
      amount: parseUnits(amount, selectedToken.decimals).toString()
    })
    repay({
      address: CONTRACTS.NexusPool,
      abi: NEXUS_POOL_ABI,
      functionName: 'repay',
      args: [selectedToken.address, parseUnits(amount, selectedToken.decimals)],
    })
  }

  // ============================================
  // TRANSACTION HANDLER
  // ============================================
  const handleTransaction = async () => {
    if (!selectedToken || !amount || Number(amount) <= 0) return
    
    const parsedAmount = parseUnits(amount, selectedToken.decimals)
    console.log('Starting transaction...', { type: modalType, amount: parsedAmount.toString() })
    
    // SUPPLY - requires approval
    if (modalType === 'supply') {
      const currentAllowance = allowance || 0n
      console.log('Current allowance:', currentAllowance.toString())
      
      if (currentAllowance < parsedAmount) {
        console.log('Need approval first')
        setTxStatus('approving')
        approve({
          address: selectedToken.address,
          abi: ERC20_ABI,
          functionName: 'approve',
          args: [CONTRACTS.NexusPool, parsedAmount * 2n],
        })
      } else {
        console.log('Allowance sufficient, supplying directly')
        setTxStatus('pending')
        executeSupply()
      }
    } 
    // BORROW - no approval needed
    else if (modalType === 'borrow') {
      setTxStatus('pending')
      borrow({
        address: CONTRACTS.NexusPool,
        abi: NEXUS_POOL_ABI,
        functionName: 'borrow',
        args: [selectedToken.address, parsedAmount],
      })
    }
    // WITHDRAW - no approval needed (withdrawing your own funds)
    else if (modalType === 'withdraw') {
      setTxStatus('pending')
      withdraw({
        address: CONTRACTS.NexusPool,
        abi: NEXUS_POOL_ABI,
        functionName: 'withdraw',
        args: [selectedToken.address, parsedAmount],
      })
    }
    // REPAY - requires approval (sending tokens back)
    else if (modalType === 'repay') {
      const currentAllowance = allowance || 0n
      console.log('Current allowance:', currentAllowance.toString())
      
      if (currentAllowance < parsedAmount) {
        console.log('Need approval first')
        setTxStatus('approving')
        approve({
          address: selectedToken.address,
          abi: ERC20_ABI,
          functionName: 'approve',
          args: [CONTRACTS.NexusPool, parsedAmount * 2n],
        })
      } else {
        console.log('Allowance sufficient, repaying directly')
        setTxStatus('pending')
        executeRepay()
      }
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================
  const getButtonText = () => {
    if (txStatus === 'error') return 'Failed - Try Again'
    if (txStatus === 'approving' || isApproving || isApproveLoading) return 'Approving...'
    if (txStatus === 'pending' || isSupplying || isBorrowing || isWithdrawing || isRepaying || isSupplyLoading || isBorrowLoading || isWithdrawLoading || isRepayLoading) return 'Confirming...'
    if (txStatus === 'success') return 'Success'
    if (!amount || Number(amount) <= 0) return 'Enter amount'
    return modalType?.charAt(0).toUpperCase() + modalType?.slice(1)
  }

  const isButtonDisabled = 
    !amount || Number(amount) <= 0 || 
    isApproving || isSupplying || isBorrowing || 
    isApproveLoading || isSupplyLoading || isBorrowLoading ||
    txStatus === 'success'

  return (
    <div className="app">
      <Header activeTab={activeTab} setActiveTab={setActiveTab} />

      <main className="main">
        {!isConnected ? (
          <EmptyState 
            title="Connect Your Wallet"
            description="Connect your wallet to view your positions and start earning"
          />
        ) : activeTab === 'markets' ? (
          <MarketsPage />
        ) : activeTab === 'stake' ? (
          <StakePage />
        ) : activeTab === 'docs' ? (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4 }}
          >
            <div className="page-header">
              <h1 className="page-title">Documentation</h1>
              <p className="page-subtitle">Learn how to use NexusLend</p>
            </div>
            <motion.div 
              className="card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <div className="card-body" style={{ padding: '2rem' }}>
                <h3 style={{ marginBottom: '1rem' }}>Getting Started</h3>
                <ul style={{ color: 'var(--text-secondary)', lineHeight: 1.8 }}>
                  <li><strong>Supply:</strong> Deposit tokens to earn interest</li>
                  <li><strong>Borrow:</strong> Use your deposits as collateral to borrow</li>
                  <li><strong>Health Factor:</strong> Keep above 1.0 to avoid liquidation</li>
                  <li><strong>LTV:</strong> You can borrow up to 75% of your collateral value</li>
                </ul>
                <h3 style={{ marginTop: '2rem', marginBottom: '1rem' }}>Smart Contracts</h3>
                <p style={{ color: 'var(--text-secondary)' }}>
                  NexusPool: <code style={{ background: 'var(--bg-hover)', padding: '0.25rem 0.5rem', borderRadius: '4px' }}>0x087bd3cef36b00d2db4cd381fc76adee4a1b2357</code>
                </p>
              </div>
            </motion.div>
          </motion.div>
        ) : (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4 }}
          >
            {/* Page Header */}
            <div className="page-header">
              <h1 className="page-title">Dashboard</h1>
              <p className="page-subtitle">Manage your positions and track your earnings</p>
            </div>

            {/* Stats */}
            <div className="stats-row">
              <StatsCard 
                label="Net Worth" 
                value={formatUSD(totalValue)} 
                subtext="Across all assets"
                variant="gradient"
              />
              <StatsCard 
                label="Total Supplied" 
                value={formatUSD(totalSupplied)} 
                subtext="Earning interest"
              />
              <StatsCard 
                label="Total Borrowed" 
                value={formatUSD(totalBorrowed)} 
                subtext="Outstanding debt"
              />
              <StatsCard 
                label="Health Factor" 
                value={formatHealthFactor()}
                subtext={totalBorrowed > 0 ? "Monitor your position" : "Position is safe"}
                variant={totalBorrowed > 0 ? "default" : "success"}
              />
            </div>

            {/* Assets Table */}
            <motion.div 
              className="card"
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
            >
              <div className="card-header">
                <h2 className="card-title">Your Assets</h2>
              </div>
              <div className="card-body">
                <table className="asset-table">
                  <thead>
                    <tr>
                      <th>Asset</th>
                      <th>Wallet Balance</th>
                      <th>USD Value</th>
                      <th>Supply APY</th>
                      <th>Borrow APY</th>
                      <th></th>
                    </tr>
                  </thead>
                  <tbody>
                    {tokenList.map((token) => {
                      // Get user position for this token
                      const position = token.symbol === 'mWETH' ? wethPosition 
                        : token.symbol === 'mUSDC' ? usdcPosition 
                        : daiPosition
                      const supplied = position?.[0] || 0n
                      const borrowed = position?.[1] || 0n
                      
                      return (
                        <AssetRow
                          key={token.symbol}
                          token={token}
                          balance={formatBalance(getBalance(token), token.decimals)}
                          usdValue={formatUSD(getUSDValue(getBalance(token), token.decimals, PRICES[token.symbol]))}
                          supplyAPY={APY_RATES[token.symbol].supply}
                          borrowAPY={APY_RATES[token.symbol].borrow}
                          supplied={formatUnits(supplied, token.decimals)}
                          borrowed={formatUnits(borrowed, token.decimals)}
                          onSupply={() => openModal(token, 'supply')}
                          onBorrow={() => openModal(token, 'borrow')}
                          onWithdraw={() => openModal(token, 'withdraw')}
                          onRepay={() => openModal(token, 'repay')}
                        />
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </motion.div>
          </motion.div>
        )}
      </main>

      <Footer />

      {/* Transaction Modal */}
      <AnimatePresence>
        {modalType && selectedToken && (
          <TransactionModal
            isOpen={!!modalType}
            onClose={closeModal}
            token={selectedToken}
            type={modalType}
            amount={amount}
            setAmount={setAmount}
            balance={getBalance(selectedToken)}
            txStatus={txStatus}
            onSubmit={handleTransaction}
            isDisabled={isButtonDisabled}
            buttonText={getButtonText()}
          />
        )}
      </AnimatePresence>
    </div>
  )
}

export default App
