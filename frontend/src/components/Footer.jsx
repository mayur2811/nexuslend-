import { Hexagon } from 'lucide-react'

export default function Footer() {
  const currentYear = new Date().getFullYear()

  return (
    <footer className="footer">
      <div className="footer-inner">
        {/* Left - Logo & Description */}
        <div className="footer-brand">
          <a href="/" className="logo">
            <div className="logo-mark"><Hexagon size={20} fill="currentColor" /></div>
            <span className="logo-text">NexusLend</span>
          </a>
          <p className="footer-description">
            Decentralized lending protocol built on Ethereum. 
            Supply assets to earn yield or borrow against your collateral.
          </p>
        </div>

        {/* Links */}
        <div className="footer-links">
          <div className="footer-column">
            <h4 className="footer-heading">Protocol</h4>
            <a href="#" className="footer-link">Markets</a>
            <a href="#" className="footer-link">Governance</a>
            <a href="#" className="footer-link">Security</a>
            <a href="#" className="footer-link">Bug Bounty</a>
          </div>
          <div className="footer-column">
            <h4 className="footer-heading">Resources</h4>
            <a href="#" className="footer-link">Documentation</a>
            <a href="#" className="footer-link">Whitepaper</a>
            <a href="#" className="footer-link">FAQ</a>
            <a href="#" className="footer-link">Brand Kit</a>
          </div>
          <div className="footer-column">
            <h4 className="footer-heading">Community</h4>
            <a href="https://twitter.com/nexuslend" target="_blank" rel="noreferrer" className="footer-link">Twitter</a>
            <a href="https://discord.gg/nexuslend" target="_blank" rel="noreferrer" className="footer-link">Discord</a>
            <a href="https://github.com/nexuslend" target="_blank" rel="noreferrer" className="footer-link">GitHub</a>
            <a href="https://medium.com/@nexuslend" target="_blank" rel="noreferrer" className="footer-link">Blog</a>
          </div>
        </div>
      </div>

      {/* Bottom Bar */}
      <div className="footer-bottom">
        <p className="footer-copyright">
          © {currentYear} NexusLend. All rights reserved.
        </p>
        <div className="footer-legal">
          <a href="#" className="footer-link">Terms of Service</a>
          <a href="#" className="footer-link">Privacy Policy</a>
        </div>
      </div>
    </footer>
  )
}
