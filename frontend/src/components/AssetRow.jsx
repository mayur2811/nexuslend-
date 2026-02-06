import { Coins, DollarSign, BadgeDollarSign } from 'lucide-react'

// Token icons using lucide-react as fallback
const TokenIconComponent = ({ symbol }) => {
  switch(symbol) {
    case 'mWETH': 
      return <Coins size={22} />
    case 'mUSDC': 
      return <DollarSign size={22} />
    case 'mDAI': 
      return <BadgeDollarSign size={22} />
    default: 
      return <Coins size={22} />
  }
}

export default function AssetRow({ 
  token, 
  balance, 
  usdValue, 
  supplyAPY, 
  borrowAPY, 
  supplied,
  borrowed,
  onSupply, 
  onBorrow,
  onWithdraw,
  onRepay
}) {
  const iconClass = token.symbol === 'mWETH' ? 'eth' : token.symbol === 'mUSDC' ? 'usdc' : 'dai'
  const hasSupplied = supplied && Number(supplied) > 0
  const hasBorrowed = borrowed && Number(borrowed) > 0

  return (
    <tr>
      <td>
        <div className="asset-cell">
          <div className={`asset-icon ${iconClass}`}>
            <TokenIconComponent symbol={token.symbol} />
          </div>
          <div>
            <div className="asset-name">{token.name}</div>
            <div className="asset-symbol">{token.symbol}</div>
          </div>
        </div>
      </td>
      <td>{balance}</td>
      <td>{usdValue}</td>
      <td><span className="apy-positive">{Number(supplyAPY).toFixed(2)}%</span></td>
      <td><span className="apy-negative">{Number(borrowAPY).toFixed(2)}%</span></td>
      <td>
        <div className="btn-group">
          <button 
            className="btn btn-primary btn-sm"
            onClick={onSupply}
          >
            Supply
          </button>
          <button 
            className="btn btn-secondary btn-sm"
            onClick={onBorrow}
          >
            Borrow
          </button>
          {hasSupplied && (
            <button 
              className="btn btn-outline btn-sm"
              onClick={onWithdraw}
            >
              Withdraw
            </button>
          )}
          {hasBorrowed && (
            <button 
              className="btn btn-outline btn-sm"
              onClick={onRepay}
            >
              Repay
            </button>
          )}
        </div>
      </td>
    </tr>
  )
}
