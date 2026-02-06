// NexusLend Contract Addresses (Sepolia) - Deployed Feb 6, 2026
export const CONTRACTS = {
  NexusPool: '0x087bd3cef36b00d2db4cd381fc76adee4a1b2357',
  PriceOracle: '0xa6d224d5744d9bae8c5a71020a5ba82a29b215e4',
  InterestRateModel: '0xe19e505290e1c4b35a2057798363b0ab8fe70224',
}

// Test Token Addresses (order: mWETH, mUSDC, mDAI)
export const TOKENS = {
  mWETH: {
    address: '0x27d5315e5f6febe82ee7a4a6fa00e11095c5a70f',
    symbol: 'mWETH',
    name: 'Mock Wrapped ETH',
    decimals: 18,
    icon: '⟠',
  },
  mUSDC: {
    address: '0x5f2821f166947717187759e205144def4442814a',
    symbol: 'mUSDC',
    name: 'Mock USD Coin',
    decimals: 6,
    icon: '$',
  },
  mDAI: {
    address: '0x297c736918352f0f46225ec98cb4a4b0c0a5e16e',
    symbol: 'mDAI',
    name: 'Mock DAI',
    decimals: 18,
    icon: '◈',
  },
}

// NToken Addresses (receipt tokens)
export const NTOKENS = {
  nWETH: '0x684867c6a776fe7c1f66dfea12afe36fab226b2b',
  nUSDC: '0x5e9b8ee37a143ed65e307c260af49c1409df4d4c',
  nDAI: '0x50369cd07941232651bbcf2d592299b69ba70789',
}

// ERC20 ABI (minimal for balanceOf, approve, transfer)
export const ERC20_ABI = [
  {
    name: 'balanceOf',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'account', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'approve',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'spender', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'bool' }],
  },
  {
    name: 'allowance',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'owner', type: 'address' },
      { name: 'spender', type: 'address' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'decimals',
    type: 'function',
    stateMutability: 'view',
    inputs: [],
    outputs: [{ name: '', type: 'uint8' }],
  },
  {
    name: 'mint',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'to', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [],
  },
]

// NexusPool ABI (core functions)
export const NEXUS_POOL_ABI = [
  {
    name: 'supply',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'asset', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'withdraw',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'asset', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'borrow',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'asset', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'repay',
    type: 'function',
    stateMutability: 'nonpayable',
    inputs: [
      { name: 'asset', type: 'address' },
      { name: 'amount', type: 'uint256' },
    ],
    outputs: [],
  },
  {
    name: 'getHealthFactor',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'user', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'userPositions',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'user', type: 'address' },
      { name: 'asset', type: 'address' },
    ],
    outputs: [
      { name: 'deposited', type: 'uint256' },
      { name: 'borrowed', type: 'uint256' },
      { name: 'borrowIndex', type: 'uint256' },
      { name: 'lastUpdateTime', type: 'uint256' },
    ],
  },
  {
    name: 'totalLiquidity',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'asset', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'totalBorrows',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'asset', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
]

// Price Oracle ABI
export const PRICE_ORACLE_ABI = [
  {
    name: 'getPrice',
    type: 'function',
    stateMutability: 'view',
    inputs: [{ name: 'asset', type: 'address' }],
    outputs: [{ name: '', type: 'uint256' }],
  },
]

// Interest Rate Model ABI
export const INTEREST_RATE_MODEL_ABI = [
  {
    name: 'getBorrowRate',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'totalBorrows', type: 'uint256' },
      { name: 'totalLiquidity', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
  {
    name: 'getSupplyRate',
    type: 'function',
    stateMutability: 'view',
    inputs: [
      { name: 'totalBorrows', type: 'uint256' },
      { name: 'totalLiquidity', type: 'uint256' },
      { name: 'reserveFactor', type: 'uint256' },
    ],
    outputs: [{ name: '', type: 'uint256' }],
  },
]
