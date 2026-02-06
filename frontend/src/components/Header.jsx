import { ConnectButton } from '@rainbow-me/rainbowkit'
import { useAccount } from 'wagmi'
import { LayoutDashboard, TrendingUp, Landmark, FileText, Hexagon } from 'lucide-react'

export default function Header({ activeTab, setActiveTab }) {
  const { isConnected } = useAccount()

  return (
    <header className="header">
      <div className="header-inner">
        {/* Logo */}
        <a href="/" className="logo">
          <div className="logo-mark"><Hexagon size={20} fill="currentColor" /></div>
          <span className="logo-text">NexusLend</span>
        </a>

        {/* Navigation */}
        <nav className="nav">
          <a 
            className={`nav-link ${activeTab === 'dashboard' ? 'active' : ''}`}
            onClick={() => setActiveTab('dashboard')}
          >
            <LayoutDashboard size={16} />
            <span>Dashboard</span>
          </a>
          <a 
            className={`nav-link ${activeTab === 'markets' ? 'active' : ''}`}
            onClick={() => setActiveTab('markets')}
          >
            <TrendingUp size={16} />
            <span>Markets</span>
          </a>
          <a 
            className={`nav-link ${activeTab === 'stake' ? 'active' : ''}`}
            onClick={() => setActiveTab('stake')}
          >
            <Landmark size={16} />
            <span>Stake</span>
          </a>
          <a 
            className="nav-link"
            href="https://github.com/nexuslend"
            target="_blank"
            rel="noreferrer"
          >
            <FileText size={16} />
            <span>Docs</span>
          </a>
        </nav>

        {/* Right Side */}
        <div className="header-right">
          {isConnected && (
            <div className="network-badge">
              <span className="network-dot"></span>
              Sepolia
            </div>
          )}
          <ConnectButton 
            showBalance={false}
            chainStatus="icon"
            accountStatus="address"
          />
        </div>
      </div>
    </header>
  )
}
