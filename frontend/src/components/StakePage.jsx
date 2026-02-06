import { motion } from 'framer-motion'
import { Coins, Shield, Lock, Gift } from 'lucide-react'

export default function StakePage() {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.4 }}
    >
      {/* Page Header */}
      <div className="page-header">
        <h1 className="page-title">Stake</h1>
        <p className="page-subtitle">Stake your NEXUS tokens to earn rewards and participate in governance</p>
      </div>

      {/* Staking Stats */}
      <div className="stats-row">
        <div className="market-stat">
          <div className="market-stat-icon"><Coins size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">NEXUS Price</span>
            <span className="market-stat-value">$0.00</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><Shield size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Total Staked</span>
            <span className="market-stat-value">Coming Soon</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><Gift size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Staking APR</span>
            <span className="market-stat-value">--</span>
          </div>
        </div>
        <div className="market-stat">
          <div className="market-stat-icon"><Lock size={20} /></div>
          <div className="market-stat-content">
            <span className="market-stat-label">Lock Period</span>
            <span className="market-stat-value">--</span>
          </div>
        </div>
      </div>

      {/* Coming Soon Card */}
      <motion.div 
        className="card"
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.2 }}
      >
        <div className="card-body" style={{ textAlign: 'center', padding: '4rem 2rem' }}>
          <div style={{ 
            width: '80px', 
            height: '80px', 
            background: 'var(--primary)', 
            borderRadius: '50%', 
            display: 'flex', 
            alignItems: 'center', 
            justifyContent: 'center',
            margin: '0 auto 1.5rem',
            opacity: 0.8
          }}>
            <Lock size={36} color="white" />
          </div>
          <h3 style={{ fontSize: '1.5rem', marginBottom: '0.75rem', color: 'var(--text-primary)' }}>
            Staking Coming Soon
          </h3>
          <p style={{ color: 'var(--text-secondary)', maxWidth: '400px', margin: '0 auto' }}>
            The NEXUS token and staking mechanism will be launched in a future update. 
            Stay tuned for governance and reward opportunities!
          </p>
        </div>
      </motion.div>
    </motion.div>
  )
}
