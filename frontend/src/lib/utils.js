// Format large numbers with commas
export function formatNumber(num, decimals = 2) {
  if (!num) return '0'
  const value = Number(num)
  if (value === 0) return '0'
  if (value < 0.01) return '<0.01'
  return value.toLocaleString('en-US', {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  })
}

// Format token balance from wei
export function formatTokenBalance(balance, decimals = 18, displayDecimals = 4) {
  if (!balance) return '0'
  const value = Number(balance) / Math.pow(10, decimals)
  return formatNumber(value, displayDecimals)
}

// Format USD value
export function formatUSD(value) {
  if (!value) return '$0.00'
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value)
}

// Format health factor
export function formatHealthFactor(healthFactor) {
  if (!healthFactor) return '∞'
  const value = Number(healthFactor) / 1e27 // RAY precision
  if (value > 100) return '∞'
  return value.toFixed(2)
}

// Get health factor color
export function getHealthFactorColor(healthFactor) {
  if (!healthFactor) return 'text-green-400'
  const value = Number(healthFactor) / 1e27
  if (value >= 2) return 'text-green-400'
  if (value >= 1.5) return 'text-yellow-400'
  if (value >= 1) return 'text-orange-400'
  return 'text-red-400'
}

// Shorten address
export function shortenAddress(address) {
  if (!address) return ''
  return `${address.slice(0, 6)}...${address.slice(-4)}`
}

// Parse token amount to wei
export function parseTokenAmount(amount, decimals = 18) {
  if (!amount || isNaN(amount)) return BigInt(0)
  return BigInt(Math.floor(Number(amount) * Math.pow(10, decimals)))
}
