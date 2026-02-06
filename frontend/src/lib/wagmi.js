import { http, createConfig } from 'wagmi'
import { sepolia } from 'wagmi/chains'
import { getDefaultConfig } from '@rainbow-me/rainbowkit'

export const config = getDefaultConfig({
  appName: 'NexusLend',
  projectId: 'nexuslend-defi', // WalletConnect project ID (can be any string for testing)
  chains: [sepolia],
  transports: {
    [sepolia.id]: http(),
  },
})
