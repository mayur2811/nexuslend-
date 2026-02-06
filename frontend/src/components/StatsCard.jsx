import { motion } from 'framer-motion'

export default function StatsCard({ label, value, subtext, variant = 'default' }) {
  const valueClass = variant === 'gradient' ? 'stat-value gradient' : 'stat-value'
  
  return (
    <motion.div 
      className="stat-card"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      whileHover={{ y: -2 }}
      transition={{ duration: 0.2 }}
    >
      <div className="stat-label">{label}</div>
      <div className={valueClass} style={variant === 'success' ? { color: 'var(--success)' } : {}}>
        {value}
      </div>
      {subtext && <div className="stat-subtext">{subtext}</div>}
    </motion.div>
  )
}
