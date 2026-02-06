import { motion } from 'framer-motion'
import { Wallet } from 'lucide-react'

export default function EmptyState({ title, description }) {
  return (
    <motion.div 
      className="empty-state"
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
    >
      <div className="empty-icon">
        <Wallet size={48} strokeWidth={1.5} />
      </div>
      <h3 className="empty-title">{title}</h3>
      <p className="empty-text">{description}</p>
    </motion.div>
  )
}
