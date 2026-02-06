// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/Interfaces.sol";

/**
 * @title MockPriceOracle
 * @notice A simple price oracle for testing
 *
 * IN PRODUCTION:
 * We would use Chainlink price feeds!
 * This is just for testing purposes.
 *
 * HOW PRICE ORACLES WORK:
 * - External nodes (like Chainlink) get prices from exchanges
 * - They submit prices on-chain
 * - Our contracts read these prices
 * - We use them for collateral value calculations
 */
contract MockPriceOracle is IPriceOracle {
    /// @notice Owner who can set prices
    address public owner;

    /// @notice Mapping: asset => price in USD (18 decimals)
    /// @dev Example: ETH = 3000e18 means 1 ETH = $3000
    mapping(address => uint256) public prices;

    event PriceUpdated(
        address indexed asset,
        uint256 oldPrice,
        uint256 newPrice
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "MockPriceOracle: not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Set price for an asset
     * @param asset Token address
     * @param price Price in USD with 18 decimals
     *
     * EXAMPLE:
     * setPrice(WETH, 3000e18) // 1 ETH = $3000
     * setPrice(DAI, 1e18)     // 1 DAI = $1
     * setPrice(USDC, 1e18)    // 1 USDC = $1
     */
    function setPrice(address asset, uint256 price) external onlyOwner {
        uint256 oldPrice = prices[asset];
        prices[asset] = price;
        emit PriceUpdated(asset, oldPrice, price);
    }

    /**
     * @notice Get price for an asset
     * @param asset Token address
     * @return Price in USD with 18 decimals
     */
    function getPrice(address asset) external view override returns (uint256) {
        uint256 price = prices[asset];
        require(price > 0, "MockPriceOracle: price not set");
        return price;
    }

    /**
     * @notice Batch set prices for multiple assets
     * @param assets Array of token addresses
     * @param _prices Array of prices
     */
    function batchSetPrices(
        address[] calldata assets,
        uint256[] calldata _prices
    ) external onlyOwner {
        require(assets.length == _prices.length, "Length mismatch");

        for (uint256 i = 0; i < assets.length; i++) {
            uint256 oldPrice = prices[assets[i]];
            prices[assets[i]] = _prices[i];
            emit PriceUpdated(assets[i], oldPrice, _prices[i]);
        }
    }
}
