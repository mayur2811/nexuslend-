import { motion } from 'framer-motion'
import { formatUnits } from 'viem'
import { Lock, Loader2, CheckCircle2, XCircle, X } from 'lucide-react'

export default function TransactionModal({
  isOpen,
  onClose,
  token,
  type,
  amount,
  setAmount,
  balance,
  txStatus,
  onSubmit,
  isDisabled,
  buttonText
}) {
  if (!isOpen || !token) return null

  const formatBalance = (bal, decimals) => {
    if (!bal) return '0.00'
    return Number(formatUnits(bal, decimals)).toLocaleString('en-US', { 
      minimumFractionDigits: 2,
      maximumFractionDigits: 4 
    })
  }

  const getStatusDisplay = () => {
    switch(txStatus) {
      case 'approving':
        return { 
          icon: <Lock size={16} />, 
          text: 'Approving token spend...', 
          className: 'approving' 
        }
      case 'pending':
        return { 
          icon: <Loader2 size={16} className="spin" />, 
          text: 'Confirming transaction...', 
          className: 'pending' 
        }
      case 'success':
        return { 
          icon: <CheckCircle2 size={16} />, 
          text: 'Transaction successful', 
          className: 'success' 
        }
      case 'error':
        return { 
          icon: <XCircle size={16} />, 
          text: 'Transaction failed', 
          className: 'error' 
        }
      default:
        return null
    }
  }

  const status = getStatusDisplay()

  return (
    <motion.div 
      className="modal-backdrop"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
    >
      <motion.div 
        className="modal"
        initial={{ opacity: 0, scale: 0.95, y: 20 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        exit={{ opacity: 0, scale: 0.95, y: 20 }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="modal-header">
          <h3 className="modal-title">
            {type.charAt(0).toUpperCase() + type.slice(1)} {token.symbol}
          </h3>
          <button className="modal-close" onClick={onClose}><X size={18} /></button>
        </div>
        
        <div className="modal-body">
          {/* Amount Input */}
          <div className="input-group">
            <div className="input-header">
              <label className="input-label">Amount</label>
              <span className="input-balance">
                Balance: {formatBalance(balance, token.decimals)}
              </span>
            </div>
            <div className="input-wrapper">
              <input
                type="number"
                className="input-field"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                disabled={txStatus === 'success'}
              />
              <button 
                className="input-max"
                onClick={() => {
                  if (balance) setAmount(formatUnits(balance, token.decimals))
                }}
                disabled={txStatus === 'success'}
              >
                MAX
              </button>
              <div className="input-token">
                <span>{token.symbol}</span>
              </div>
            </div>
          </div>

          {/* Transaction Status */}
          {status && (
            <div className={`tx-status ${status.className}`}>
              <span className="tx-status-icon">{status.icon}</span>
              <span>{status.text}</span>
            </div>
          )}

          {/* Submit Button */}
          <button 
            className="btn btn-primary btn-full"
            onClick={onSubmit}
            disabled={isDisabled}
          >
            {buttonText}
          </button>

          {/* Info - Dynamic based on transaction type */}
          <div className="modal-info">
            {type === 'supply' && (
              <>
                <div className="info-row">
                  <span>You will receive</span>
                  <span>n{token.symbol.replace('m', '')} tokens</span>
                </div>
                <div className="info-row">
                  <span>Collateral Factor</span>
                  <span>75%</span>
                </div>
              </>
            )}
            {type === 'borrow' && (
              <>
                <div className="info-row">
                  <span>Collateral required</span>
                  <span>133% of borrow value</span>
                </div>
                <div className="info-row">
                  <span>Liquidation threshold</span>
                  <span>Health factor &lt; 1.0</span>
                </div>
              </>
            )}
            {type === 'withdraw' && (
              <>
                <div className="info-row">
                  <span>You will burn</span>
                  <span>n{token.symbol.replace('m', '')} tokens</span>
                </div>
                <div className="info-row">
                  <span>Check your health factor</span>
                  <span className="apy-negative">May decrease</span>
                </div>
              </>
            )}
            {type === 'repay' && (
              <>
                <div className="info-row">
                  <span>Reduces your debt</span>
                  <span>+ Interest owed</span>
                </div>
                <div className="info-row">
                  <span>Health factor</span>
                  <span className="apy-positive">Will increase</span>
                </div>
              </>
            )}
          </div>
        </div>
      </motion.div>
    </motion.div>
  )
}
